import 'dart:async';
import 'dart:convert';
import 'package:dapp_movil/core/helpers/crypto_chat_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_avatar_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
class SecureChatService extends ChangeNotifier {
  final AuthCoreService _authCore;
  
  WebSocketChannel? _channel;
  bool isConnected = false;
  bool isConnecting = false;
  String? typingUser;
  Timer? _typingTimer;
  String? currentActiveChat;
  // Memoria temporal local (Actúa como caché)
  final Map<String, List<Map<String, dynamic>>> _chatRooms = {};

  SecureChatService(this._authCore);
  final LocalCacheService _cacheService = LocalCacheService();

  /// 1. CONECTAR AL WEBSOCKET DE SPRING BOOT
  Future<void> initClient() async {
    if (isConnected || isConnecting || _authCore.publicAddress.isEmpty) return;

    try {
      isConnecting = true;
      notifyListeners();

      print("⏳ [SECURE CHAT] Conectando a nodos propios...");

      // Conexión WS pasando el JWT por cabecera (o por URL si tu backend lo exige)
      final wsUrl = Uri.parse(ApiConfig.chatWebSocket);
      _channel = WebSocketChannel.connect(wsUrl);

      // Enviamos un primer mensaje de autenticación al WS para registrar la sesión en Spring Boot
      _channel!.sink.add(jsonEncode({
        "type": "AUTH", 
        "token": _authCore.jwtToken,
        "wallet": _authCore.publicAddress.toLowerCase() 
      }));

      isConnected = true;
      isConnecting = false;
      print("✅ [SECURE CHAT] Conexión E2EE Establecida.");
      notifyListeners();

      _listenToMessages();

    } catch (e) {
      isConnecting = false;
      isConnected = false;
      notifyListeners();
      print("🚨 [SECURE CHAT] Error conectando: $e");
    }
  }

  /// 2. ESCUCHAR MENSAJES EN TIEMPO REAL
void _listenToMessages() {
    _channel?.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        
        // 🔥 FIX: 1. PRIMERO ATRAPAMOS EL EVENTO TYPING (Que no tiene encryptedPayload)
        if (data['type'] == 'TYPING') {
          typingUser = data['senderWallet'].toString().toLowerCase();
          notifyListeners();
          
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            typingUser = null;
            notifyListeners();
          });
          return; // 🔥 SALIMOS AQUÍ para no procesar el resto
        }

        // 🔥 FIX: 2. AHORA SÍ LEEMOS LOS MENSAJES REALES
        String sender = data['senderWallet']?.toString().toLowerCase() ?? "";
        String receiver = data['receiverWallet']?.toString().toLowerCase() ?? "";
        
        // Usamos ?? "" para proteger contra nulos por si llega algún JSON raro
        String encryptedPayload = data['encryptedPayload'] ?? ""; 
        if (encryptedPayload.isEmpty) return; 
        
        // Identificamos con quién es la conversación
        String peerWallet = sender == _authCore.publicAddress.toLowerCase() ? receiver : sender;

        // Desencriptamos el mensaje
        String decryptedJson = CryptoChatHelper.decryptPayload(_authCore.publicAddress, peerWallet, encryptedPayload);

        // 🔥 NUEVO: NOTIFICACIÓN IN-APP (ESTILO WHATSAPP)
        // Si la app está abierta pero NO estamos dentro de ESTE chat específico
        if (currentActiveChat != peerWallet && sender != _authCore.publicAddress.toLowerCase()) {
          // Extraemos el texto si es posible, o ponemos un genérico
          String preview = "Nuevo mensaje cifrado";
          try {
             final parsed = jsonDecode(decryptedJson);
             if (parsed['type'] == 'TEXT') preview = parsed['content'];
             if (parsed['type'] == 'IMAGE') preview = "📷 Imagen recibida";
             if (parsed['type'] == 'AUDIO') preview = "🎤 Nota de voz";
             if (parsed['type'] == 'TRANSFER') preview = "💸 Transferencia recibida";
          } catch(e) {}
          
          // Mostramos la alerta tipo WhatsApp arriba
          UIHelper.showCustomSnackbar("Mensaje nuevo: $preview", isError: false);
        }

       final String msgId = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        final newMsg = {
          "id": msgId,
          "sender": sender,
          "content": decryptedJson,
          "timestamp": DateTime.now(),
        };

       if (!_chatRooms.containsKey(peerWallet)) _chatRooms[peerWallet] = [];
        _chatRooms[peerWallet]!.insert(0, newMsg); 
        
        print("🔔 [SECURE CHAT] Nuevo mensaje desencriptado de $sender");
        notifyListeners();

        // ====================================================================
        // 🔥 NUEVO: DISPARADOR DEL AVATAR AUTÓNOMO IA (AGENTIC AI) 🔥
        // ====================================================================
        // Verificamos que el mensaje sea entrante (no enviado por nosotros mismos)
        if (sender != _authCore.publicAddress.toLowerCase()) {
           
           // 2. Extraemos el mensaje desencriptado para ver si tiene la firma de la IA
           bool isAiMessage = false;
           try {
             final Map<String, dynamic> parsedDecrypted = jsonDecode(decryptedJson);
             if (parsedDecrypted['isAi'] == true) isAiMessage = true;
           } catch(e) {}

           // 3. Si el mensaje es humano, despertamos al Avatar. Si es de otra IA, lo ignoramos.
           if (!isAiMessage) {
             print("🤖 [SISTEMA] Mensaje Humano recibido. Despertando al Avatar Autónomo...");
             
             AiAvatarResponse().evaluarEventoConIA(
               authCore: _authCore,
               chatService: this, 
               evento: {
                 "type": "CHAT_MESSAGE",
                 "data": {
                   "senderWallet": sender,
                   "message": decryptedJson 
                 }
               }
             );
           } else {
             print("🛑 [SISTEMA] Mensaje recibido de otra IA. Avatar bloqueado para evitar bucle infinito.");
           }
        }
        // ====================================================================

        // 🔥 AUTO-DESTRUCCIÓN VISUAL (Para el que recibe)
        int? ttl = data['ttlInSeconds'];
        if (ttl != null && ttl > 0) {
          Future.delayed(Duration(seconds: ttl), () {
            _chatRooms[peerWallet]?.removeWhere((m) => m["id"] == msgId);
            notifyListeners();
          });
        }

      } catch (e) {
        print("❌ [SECURE CHAT] Error procesando mensaje entrante: $e");
      }
    }, onDone: () {
      isConnected = false;
      notifyListeners();
    });
  }
  /// 3. DESCARGAR HISTORIAL DESDE SPRING BOOT
  // Future<List<Map<String, dynamic>>> getMessages(String peerAddress) async {
    
  //   peerAddress = peerAddress.toLowerCase();
    
  //   try {
  //     final url = Uri.parse(ApiConfig.chatHistory.replaceAll("{peerWallet}", peerAddress));
  //     final response = await http.get(url, headers: _authCore.authHeaders);

  //     if (response.statusCode == 200) {
  //       List<dynamic> history = jsonDecode(response.body);
  //       List<Map<String, dynamic>> parsedHistory = [];

  //       for (var msg in history) {
  //         String sender = msg['senderWallet'].toLowerCase();
  //         String encrypted = msg['encryptedPayload'];
          
  //         String decryptedJson = CryptoChatHelper.decryptPayload(_authCore.publicAddress, peerAddress, encrypted);

  //         parsedHistory.add({
  //           "id": msg['id'],
  //           "sender": sender,
  //           "content": decryptedJson,
  //           "timestamp": DateTime.parse(msg['timestamp']), // Asegúrate de parsear bien la fecha de Spring
  //         });
  //       }

  //       // Ordenar para el ListView reversed (el más nuevo primero)
  //       parsedHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
  //       _chatRooms[peerAddress] = parsedHistory;
        
  //       return parsedHistory;
  //     }
  //   } catch (e) {
  //     print("Error obteniendo historial: $e");
  //   }
  //   return _chatRooms[peerAddress] ?? [];
  // }

  Future<List<Map<String, dynamic>>> getMessages(String peerAddress) async {
    peerAddress = peerAddress.toLowerCase();
    
    // 🔥 1. Cargar caché inmediatamente en memoria
    if (!_chatRooms.containsKey(peerAddress) || _chatRooms[peerAddress]!.isEmpty) {
      _chatRooms[peerAddress] = _cacheService.getCachedChat(peerAddress);
      notifyListeners(); // La pantalla pinta los mensajes guardados al instante
    }

    try {
      final url = Uri.parse(ApiConfig.chatHistory.replaceAll("{peerWallet}", peerAddress));
      final response = await http.get(url, headers: _authCore.authHeaders).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> history = jsonDecode(response.body);
        List<Map<String, dynamic>> parsedHistory = [];

        for (var msg in history) {
          String sender = msg['senderWallet'].toLowerCase();
          String encrypted = msg['encryptedPayload'];
          String decryptedJson = CryptoChatHelper.decryptPayload(_authCore.publicAddress, peerAddress, encrypted);

          parsedHistory.add({
            "id": msg['id'],
            "sender": sender,
            "content": decryptedJson,
            "timestamp": DateTime.parse(msg['timestamp']), 
          });
        }

        // Ordenar para el ListView reversed (el más nuevo primero)
        parsedHistory.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        _chatRooms[peerAddress] = parsedHistory;
        
        // 🔥 2. Guardar en caché el historial fresco
        await _cacheService.saveChatHistory(peerAddress, parsedHistory);
        
        notifyListeners(); // Actualiza si hubo cambios de red
        return parsedHistory;
      }
    } catch (e) {
      print("Error obteniendo historial: $e");
    }
    return _chatRooms[peerAddress] ?? [];
  }

  List<Map<String, dynamic>> getLocalMessages(String peerAddress) {
    return _chatRooms[peerAddress.toLowerCase()] ?? [];
  }

  /// 4. ENVIAR UN MENSAJE (ENCRIPTADO)
  Future<bool> sendMessage(String destinationAddress, String contentJson, {int? ttlInSeconds}) async {
    if (_channel == null) return false;
    destinationAddress = destinationAddress.toLowerCase();

    try {
      // 1. Encriptamos
      String encryptedPayload = CryptoChatHelper.encryptPayload(_authCore.publicAddress, destinationAddress, contentJson);

      // 2. Preparamos el DTO para Spring Boot incluyendo el TTL
      final payload = jsonEncode({
        "senderWallet": _authCore.publicAddress.toLowerCase(),
        "receiverWallet": destinationAddress,
        "encryptedPayload": encryptedPayload,
        "ttlInSeconds": ttlInSeconds // 🔥 Le decimos a Spring Boot en cuánto tiempo borrarlo
      });

      // 3. Enviamos por WebSocket
      _channel!.sink.add(payload);

      // 4. Guardado local
      final String msgId = DateTime.now().millisecondsSinceEpoch.toString();
      final localMsg = {
        "id": msgId,
        "sender": _authCore.publicAddress.toLowerCase(),
        "content": contentJson,
        "timestamp": DateTime.now(),
      };

      if (!_chatRooms.containsKey(destinationAddress)) _chatRooms[destinationAddress] = [];
      _chatRooms[destinationAddress]!.insert(0, localMsg);
      
      notifyListeners();

      // 🔥 5. AUTO-DESTRUCCIÓN VISUAL (Para el que envía)
      if (ttlInSeconds != null && ttlInSeconds > 0) {
        Future.delayed(Duration(seconds: ttlInSeconds), () {
          _chatRooms[destinationAddress]?.removeWhere((m) => m["id"] == msgId);
          notifyListeners();
        });
      }

      return true;

    } catch (e) {
      print("🚨 Error enviando mensaje cifrado: $e");
      return false;
    }
  }

  /// 5. OBTENER TODAS LAS CONVERSACIONES (INBOX)
  // Future<List<Map<String, dynamic>>> getConversations() async {
  //   if (_authCore.publicAddress.isEmpty) return [];

  //   try {
  //     final url = Uri.parse(ApiConfig.getChatInbox);
  //     final response = await http.get(url, headers: _authCore.authHeaders);

  //     if (response.statusCode == 200) {
  //       List<dynamic> data = jsonDecode(response.body);
  //       List<Map<String, dynamic>> inbox = [];

  //       for (var item in data) {
  //         String peerWallet = item['peerWallet'].toString().toLowerCase();
          
  //         // La IA o el backend nos manda el último mensaje, lo desencriptamos
  //         String encryptedPayload = item['lastMessage']['encryptedPayload'];
  //         String decryptedJson = CryptoChatHelper.decryptPayload(_authCore.publicAddress, peerWallet, encryptedPayload);
          
  //         String preview = "Mensaje cifrado";
  //         try {
  //           final parsedMap = jsonDecode(decryptedJson);
  //           // Si es un pago, mostramos un preview bonito
  //           preview = parsedMap['type'] == 'TRANSFER' 
  //               ? "💸 Pago de ${parsedMap['amount']} TTC" 
  //               : parsedMap['content'] ?? "Mensaje";
  //         } catch (e) {
  //           preview = decryptedJson;
  //         }

  //         inbox.add({
  //           "peerAddress": peerWallet,
  //           "alias": "Usuario Web3", // Lo cruzaremos con el alias real después
  //           "lastMessage": preview,
  //           "time": "Reciente",
  //           "unread": 0
  //         });
  //       }
  //       return inbox;
  //     }
  //   } catch (e) {
  //     print("🚨 Error obteniendo Inbox: $e");
  //   }
  //   return [];
  // }

  Future<List<Map<String, dynamic>>> getConversations() async {
    if (_authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();

    try {
      final url = Uri.parse(ApiConfig.getChatInbox);
      final response = await http.get(url, headers: _authCore.authHeaders).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> inbox = [];

        for (var item in data) {
          String peerWallet = item['peerWallet'].toString().toLowerCase();
          
          String encryptedPayload = item['lastMessage']['encryptedPayload'];
          String decryptedJson = CryptoChatHelper.decryptPayload(_authCore.publicAddress, peerWallet, encryptedPayload);
          
          // 🔥 Aquí está la variable preview correctamente declarada
          String preview = "Mensaje cifrado";
          try {
            final parsedMap = jsonDecode(decryptedJson);
            preview = parsedMap['type'] == 'TRANSFER' 
                ? "💸 Pago de \${parsedMap['amount']} TTC" 
                : parsedMap['content'] ?? "Mensaje";
          } catch (e) {
            preview = decryptedJson;
          }

          inbox.add({
            "peerAddress": peerWallet,
            "alias": "Usuario Web3",
            "lastMessage": preview,
            "time": "Reciente",
            "unread": 0
          });
        }
        
        await cacheService.saveInbox(inbox); // Guardamos en caché
        return inbox;
      }
    } catch (e) {
      print("🚨 Error obteniendo Inbox de red. Usando caché...");
    }
    
    // Fallback si la red falla
    return cacheService.getCachedInbox();
  }

  Future<void> deleteConversation(String peerWallet) async {
    peerWallet = peerWallet.toLowerCase();
    if (_chatRooms.containsKey(peerWallet)) {
      _chatRooms.remove(peerWallet);
      notifyListeners();
    }
    // 🔥 Borrado real en el Backend
    try {
      final url = Uri.parse(ApiConfig.deleteChatHistory.replaceAll("{peerWallet}", peerWallet));
      await http.delete(url, headers: _authCore.authHeaders);
    } catch (e) {
      print("Error borrando chat en backend: $e");
    }
  }

void sendTypingEvent(String destinationAddress) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(jsonEncode({
        "type": "TYPING",
        "senderWallet": _authCore.publicAddress.toLowerCase(),
        "receiverWallet": destinationAddress.toLowerCase()
      }));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
    _chatRooms.clear();
    notifyListeners();
  }
}