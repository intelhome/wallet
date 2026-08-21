import 'dart:convert' hide Codec;
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_memory_service.dart';
import 'package:dapp_movil/modules/business/modals/create_task_modal.dart';
import 'package:dapp_movil/modules/business/services/business_service.dart';
import 'package:dapp_movil/modules/chat_and_social/modals/chat_profile_modal.dart';
import 'package:dapp_movil/modules/chat_and_social/services/chat_media_service.dart';
import 'package:dapp_movil/modules/chat_and_social/services/secure_chat_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../widgets/message_bubble.dart';
import '../modals/chat_send_money_modal.dart';

class ChatRoomScreen extends StatefulWidget {
  final String alias;
  final String address;
  final String? initialMessage;

  const ChatRoomScreen({super.key, required this.alias, required this.address, this.initialMessage});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  
  List<Map<String, dynamic>> _messages = [];
  //MockChatService? _chatService;
  StreamSubscription? _msgSub;
  bool _isLoading = true;
  late SecureChatService _chatService;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  final ScrollController _scrollController = ScrollController();
 
  String? _audioPath;
  bool _isEphemeral = false;

  bool _isRecording = false;
  bool _hasText = false;
  bool _isSending = false;
  bool _isAiTyping = false;
  
  // 🔥 NUEVOS ESTADOS PARA EL INPUT REFACTORIZADO
  bool _showAttachmentMenu = false;
  bool _showMicTutorial = true;
  bool _isSwipingLeftForAi = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<SecureChatService>(context, listen: false);
    _chatService.currentActiveChat = widget.address.toLowerCase();

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _msgController.text = widget.initialMessage!;
      _hasText = true;
    }
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showMicTutorial = false);
    });
    
    _initChat();
    _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
   // _msgSub?.cancel();
   _chatService.currentActiveChat = null;
   _chatService.removeListener(_actualizarMensajes);
    _msgController.dispose();
    _scrollController.dispose();
    _audioRecorder.closeRecorder();
    super.dispose();
  }


  // Future<void> _initChat() async {
  //   _chatService.addListener(_actualizarMensajes);
    
  //   // 1. Descargamos de la Base de Datos SOLO UNA VEZ al abrir el chat
  //   await _chatService.getMessages(widget.address); 
    
  //   if (mounted) {
  //     _actualizarMensajes();
  //     setState(() => _isLoading = false);
  //   }
  // }

  
  Future<void> _initChat() async {
    _chatService.addListener(_actualizarMensajes);
    
    // 1. Descargamos de la Base de Datos SOLO UNA VEZ al abrir el chat
    await _chatService.getMessages(widget.address); 
    
    if (mounted) {
      _actualizarMensajes();
      setState(() => _isLoading = false);
    }
  }

  // void _actualizarMensajes() {
  //   // 2. Para el tiempo real, SOLO leemos la memoria local
  //   final msgs = _chatService.getLocalMessages(widget.address);
  //   if (mounted) {
  //     setState(() {
  //       _messages = List.from(msgs);
  //     });
  //   }
  // }

  void _actualizarMensajes() {
    final msgs = _chatService.getLocalMessages(widget.address);
    if (mounted) {
      setState(() {
        _messages = List.from(msgs);
      });
      // 🔥 FIX: Animación de Scroll Auto al recibir / enviar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // Al usar `reverse: true` en ListView, el 0 es el fondo
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  
 void _enviarMensajeTexto() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    _msgController.clear();
    setState(() => _hasText = false); // 🔥 Volvemos a mostrar el icono del micrófono
    
    final payload = jsonEncode({
      "type": "TEXT",
      "content": text
    });
    
    await _chatService.sendMessage(widget.address.toLowerCase(), payload, ttlInSeconds: _isEphemeral ? 60 : null);
  }

  bool _isAiTaskLoading = false;

  // 🔥 NUEVO: Función para que la empresa dicte tareas en el chat
  Future<void> _crearTareaConIA() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAiTaskLoading = true);

    try {
      final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
      final bService = Provider.of<BusinessService>(context, listen: false);

      String prompt = """
      Eres un asistente corporativo. Convierte este texto en una tarea estructurada para el empleado '@${widget.alias}'.
      Texto del jefe: "$text"
      Extrae: 'task_type' (STANDARD, GPS, MEET, FORM, OPINION), 'title', 'description', 'budget', 'estimated_hours', 'urgency' (LOW, MEDIUM, HIGH, URGENT).
      *Si es GPS: 'gps_lat' y 'gps_lon'. *Si es MEET: 'meet_url'. 
      *Si pide fotos, evidencias o comprobantes: Pon 'task_type' en 'STANDARD' y agrega "Subir foto de evidencia" dentro del array de 'subtasks'.
      Responde SOLO en JSON con formato: {"action_data": {"tx_type": "CREATE_TASK", ...}}
      """;

      final response = await aiMemoryService.sendMessageWithMemory(text, prompt);
      
      if (response != null && response['response'] != null) {
        final String cleanJsonStr = response['response'].toString().replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> aiData = jsonDecode(cleanJsonStr);
        
        if (aiData['action_data'] != null) {
          Map<String, dynamic> action = Map<String, dynamic>.from(aiData['action_data']);
          
          String title = action['title'] ?? "Nueva Tarea Asignada";
          String taskType = (action['task_type'] ?? "STANDARD").toString().toUpperCase();
          double budget = double.tryParse(action['budget']?.toString() ?? "0") ?? 0.0;
          String desc = action['description'] ?? text;
          final bService = Provider.of<BusinessService>(context, listen: false);
          final userService = Provider.of<UserService>(context, listen: false); // 🔥 DECLARACIÓN OBLIGATORIA AQUÍ
          List<dynamic> activeTeam = []; 
          List<dynamic> departments = [];
         // try { activeTeam = await bService.getTeamMembers(); departments = await bService.getDepartments(); } catch(e) {}

       try { 
        activeTeam = (await bService.getTeamMembers()).map((e) => Map<String, dynamic>.from(e)).toList();
        departments = (await bService.getDepartments()).map((e) => Map<String, dynamic>.from(e)).toList();

        for (int i = 0; i < activeTeam.length; i++) {
          String? w = activeTeam[i]['identifier']?.toString() ?? activeTeam[i]['wallet']?.toString();
          if (w != null) {
            var userData = await userService.getUserByWallet(w);
            if (userData != null && userData['alias'] != null) {
              activeTeam[i]['alias'] = userData['alias'];
            }
          }
        }
      } catch(e) {}
          
          if (!mounted) return;
          
          _msgController.clear();
          setState(() => _hasText = false);

          CreateTaskModal.show(
            context, activeTeam, departments, 
            () {
              // 🔥 EL MENSAJE NOTIFICACIÓN DE ÉXITO EN EL CHAT
              String msg = "📋 *NUEVA TAREA ASIGNADA*\n\n📌 *Título:* $title\n📝 *Descripción:* $desc\n💰 *Presupuesto:* $budget TTC\n\nPor favor, revisa tu panel para aceptarla.";
              _chatService.sendMessage(widget.address.toLowerCase(), msg);
            }, 
            initialTitle: title, 
            initialDescription: desc, 
            initialAssigneeAlias: widget.alias, 
            initialTaskType: taskType, 
            initialBudget: budget, 
            initialHours: action['estimated_hours']?.toString() ?? "", 
            initialUrgency: (action['urgency'] ?? "MEDIUM").toString().toUpperCase(),
            initialSubtasks: (action['subtasks'] as List?)?.map((e) => e.toString()).toList() ?? [],
          );
        }
      }
    } catch (e) {
      UIHelper.showCustomSnackbar("No se pudo interpretar la tarea", isError: true);
    } finally {
      if (mounted) setState(() => _isAiTaskLoading = false);
    }
  }
  // Desencriptador de JSON para el MessageBubble
  Map<String, dynamic> _parseMessageContent(String rawContent) {
    try {
      return jsonDecode(rawContent);
    } catch (e) {
      // Si el mensaje es texto viejo que no es JSON, lo forzamos a formato texto
      return { "type": "TEXT", "content": rawContent };
    }
  }
Future<void> _iniciarGrabacion() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      UIHelper.showCustomSnackbar("Permiso de micrófono denegado", isError: true);
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _audioPath = "${dir.path}/audio_sent_${DateTime.now().millisecondsSinceEpoch}.aac";

    // 🔥 Usamos la sintaxis correcta de Dart 3 (CamelCase)
    await _audioRecorder.startRecorder(
      toFile: _audioPath,
      //codec: Codec.aacAdts, 
    );
    
    setState(() => _isRecording = true);
  }

 void _extraerConocimiento(BuildContext context) async {
    final aiService = Provider.of<AiMemoryService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    if (_messages.isEmpty) return;

    // Tomamos máximo los últimos 20 mensajes de la conversación
    int limit = _messages.length < 20 ? _messages.length : 20;
    List<String> mensajesPlanos = [];
    
    for (int i = 0; i < limit; i++) {
      var msg = _messages[i]; 
      
      // 🔥 FIX 1: Validamos correctamente usando el sender y la billetera actual
      String senderWallet = msg['sender']?.toString().toLowerCase() ?? '';
      bool isMe = senderWallet == authCore.publicAddress.toLowerCase();
      String remitente = isMe ? "Yo" : widget.alias; 
      
      String rawTexto = msg['content']?.toString() ?? '';
      String textoLimpio = rawTexto;

      if (rawTexto.startsWith('{')) {
        try {
          var decoded = jsonDecode(rawTexto);
          if (decoded['type'] == 'TEXT') {
            textoLimpio = decoded['content'] ?? '';
          } else {
            textoLimpio = '[Multimedia omitido]';
          }
        } catch (_) {}
      }

      if (textoLimpio.isNotEmpty && textoLimpio != '[Multimedia omitido]') {
        mensajesPlanos.add("$remitente: $textoLimpio");
      }
    }

    mensajesPlanos = mensajesPlanos.reversed.toList();

    // 🔥 FIX 2: UI adaptada al procesamiento asíncrono del backend
    UIHelper.showCustomSnackbar("✨ Iniciando análisis cognitivo en segundo plano...", isError: false);

    bool exito = await aiService.extractPreferencesFromChat(mensajesPlanos);

    if (!exito) {
      UIHelper.showCustomSnackbar("❌ Hubo un error de conexión con la IA.", isError: true);
    } else {
      print("✅ [UI] Petición de compresión enviada. El backend notificará cuando termine.");
    }
  }

  Future<void> _detenerYEnviarAudio() async {
    if (!_isRecording) return; // Por si acaso
    
    final path = await _audioRecorder.stopRecorder();
    setState(() => _isRecording = false);

    if (path != null) {
      File audioFile = File(path);
      UIHelper.showCustomSnackbar("Cifrando y subiendo nota de voz...");
      
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      final uploadData = await ChatMediaService.encryptAndUpload(audioFile, authCore.jwtToken ?? "");

      if (uploadData != null) {
        final payload = jsonEncode({
          "type": "AUDIO",
          "remoteUrl": uploadData['remoteUrl'],
          "localPath": audioFile.path,
          "mediaKey": uploadData['mediaKey'],
          "mediaIv": uploadData['mediaIv'],
        });

        await _chatService.sendMessage(widget.address.toLowerCase(), payload, ttlInSeconds: _isEphemeral ? 60 : null);
      } else {
        UIHelper.showCustomSnackbar("Error al enviar el audio", isError: true);
      }
    }
  }

  
  void _mostrarMenuAdjuntos() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cerrar",
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80, right: 16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _botonPildora("Imagen", Icons.image_rounded, () async {
                    Navigator.pop(ctx);
                    _enviarImagen();
                  }),
                  const SizedBox(height: 10),
                 _botonPildora("Audio", Icons.mic_rounded, () async {
                    Navigator.pop(ctx); // Cierra el menú
                    await _iniciarGrabacion(); // Inicia el micrófono
                  }),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    backgroundColor: theme.cardColor,
                    onPressed: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, color: colorScheme.onSurface),
                  )
                ],
              ),
            ),
          )
          );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _botonPildora(String texto, IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5A4A42), // El color marrón de tu captura
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: Colors.white70),
            const SizedBox(width: 12),
            Text(texto, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

 Future<void> _enviarImagen() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    
    File? compressedImage = await ChatMediaService.pickAndCompressImage();
    if (compressedImage == null) return;

    UIHelper.showCustomSnackbar("Cifrando y subiendo imagen...");

    final uploadData = await ChatMediaService.encryptAndUpload(compressedImage, authCore.jwtToken ?? "");
    
    if (uploadData != null) {
      final payload = jsonEncode({
        "type": "IMAGE",
        "remoteUrl": uploadData['remoteUrl'],
        "localPath": compressedImage.path, 
        "mediaKey": uploadData['mediaKey'],
        "mediaIv": uploadData['mediaIv'],
        "caption": ""
      });

      // El tipo "IMAGE" ya va dentro del JSON, tu SecureChatService modificado lo extraerá para el backend
      await _chatService.sendMessage(widget.address.toLowerCase(), payload, ttlInSeconds: _isEphemeral ? 60 : null);
    } else {
      UIHelper.showCustomSnackbar("Error al subir la imagen", isError: true);
    }
  }
  
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//      appBar: AppBar(
//         backgroundColor: theme.cardColor,
//         elevation: 1,
//         titleSpacing: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
//             tooltip: 'Aprender de este chat',
//             onPressed: () => _extraerConocimiento(context),
//           ),
//         ],
//         title: GestureDetector(
//           onTap: () => ChatProfileModal.show(context, widget.address), // 🔥 MAGIA: Abre el modal al tocar
//           child: Row(
//             children: [
//               SmartAvatar(address: widget.address, size: 36),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(widget.alias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  
//                   // 🔥 Animación de "Escribiendo..."
//                 Consumer<SecureChatService>(
//                       builder: (context, chatService, child) {
//                         if (chatService.typingUser == widget.address.toLowerCase()) {
//                           return Text("escribiendo...", style: TextStyle(color: colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic));
//                         }
//                         return Text(
//                           "${widget.address.substring(0,6)}...${widget.address.substring(widget.address.length - 4)}", 
//                           style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5), fontFamily: 'monospace')
//                         );
//                       },
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: _isLoading 
//         ? const Center(child: CircularProgressIndicator())
//         : Stack(
//             children: [
//               // 1. EL CONTENIDO PRINCIPAL (LISTA DE CHAT Y BARRA)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: ListView.builder(
//                       controller: _scrollController, // 🔥 AQUÍ LO AGREGAS
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       reverse: true, // Empieza desde abajo
//                       itemCount: _messages.length,
//                       itemBuilder: (context, index) {
//                         final rawMsg = _messages[index];
//                         final parsedMap = _parseMessageContent(rawMsg['content'].toString());
                        
//                         final miBilletera = authCore.publicAddress.toLowerCase();
//                         final senderWallet = rawMsg['sender'].toString().toLowerCase();
//                         final isMe = (senderWallet == miBilletera) || (senderWallet == 'me');
                        
//                         return MessageBubble(message: parsedMap, isMe: isMe, peerAddress: widget.address);
//                       },
//                     ),
//                   ),
                  
//                   // 🔥 INDICADOR DE "ESCRIBIENDO..."
//                   Consumer<SecureChatService>(
//                     builder: (context, chatService, child) {
//                       if (chatService.typingUser == widget.address.toLowerCase()) {
//                         return Padding(
//                           padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 "${widget.alias} está escribiendo", 
//                                 style: TextStyle(color: colorScheme.primary, fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)
//                               ),
//                               Text("...", style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
//                             ],
//                           ),
//                         );
//                       }
//                       return const SizedBox.shrink();
//                     },
//                   ),

//                   // 🔥 BARRA DE ENTRADA DE CHAT EXTRÍDA
//                   _buildInputArea(),
//                 ],
//               ),

//               // 🔥 2. EL MENÚ DESPLEGABLE DEL CLIP (AHORA ES CLICKEABLE)
//               if (_showAttachmentMenu)
//                 Positioned(
//                   bottom: 75, // Justo encima de la barra
//                   left: 5,
//                   child: _buildAttachmentMenu(),
//                 ),

//               // 🔥 3. TOOLTIP TEMPORAL DE ENSEÑANZA
//               if (_showMicTutorial)
//                 Positioned(
//                   bottom: 80,
//                   right: 15,
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                       decoration: BoxDecoration(
//                         color: colorScheme.primary,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
//                       ),
//                       child: const Text(
//                         "Mantén presionado para Audio 🎤\n¡O arrastra a la izquierda para IA! ✨",
//                         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//     );
//   }

// Widget _buildAttachmentMenu() {
//     final theme = Theme.of(context);
//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10, left: 10),
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         decoration: BoxDecoration(
//           color: theme.cardColor,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.attach_money_rounded, color: Colors.green),
//               tooltip: "Enviar TTC",
//               onPressed: () async {
//                 setState(() => _showAttachmentMenu = false);
//                 String saldo = await Provider.of<TransactionService>(context, listen: false).getBalance();
//                 if (!mounted) return;
//                 SendModal.show(context: context, balanceTTC: saldo, initialAddress: "@${widget.alias}", onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.timer_rounded, color: _isEphemeral ? Colors.redAccent : Colors.grey),
//               tooltip: "Chat Efímero",
//               onPressed: () {
//                 setState(() { _isEphemeral = !_isEphemeral; _showAttachmentMenu = false; });
//                 UIHelper.showCustomSnackbar(_isEphemeral ? "Modo Efímero Activado (10 min)" : "Modo Efímero Desactivado");
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.image_rounded, color: Colors.blueAccent),
//               tooltip: "Enviar Imagen",
//               onPressed: () {
//                 setState(() => _showAttachmentMenu = false);
//                _enviarImagen();
//               },
//             ),
//           IconButton(
//               icon: const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent),
//               tooltip: "Redactar Tarea IA",
//               onPressed: () {
//                 setState(() => _showAttachmentMenu = false);
//                 if (_hasText) _crearTareaConIA(); // 🔥 CORREGIDO
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔥 NUEVO MÉTODO CON LA BARRA DE CHAT SEPARADA Y ORDENADA 🔥
// Widget _buildInputArea() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     // 🔥 BARRA DE ESCRITURA PRINCIPAL (Sin Stack, pura UI de texto)
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//       decoration: BoxDecoration(
//         color: theme.scaffoldBackgroundColor,
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, -4))],
//       ),
//       child: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             // BOTÓN DEL CLIP (Muestra/Oculta el Menú)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 2),
//               child: IconButton(
//                 icon: AnimatedRotation(
//                   turns: _showAttachmentMenu ? 0.125 : 0, // Gira 45° al abrir (efecto X)
//                   duration: const Duration(milliseconds: 200),
//                   child: Icon(Icons.attach_file_rounded, color: colorScheme.primary, size: 28),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _showAttachmentMenu = !_showAttachmentMenu;
//                     _showMicTutorial = false; // Ocultar tooltip si interactúa
//                   });
//                 },
//               ),
//             ),

//             // TEXTFIELD LIMPIO (GIGANTE)
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: theme.cardColor,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: _isEphemeral ? Colors.redAccent.withOpacity(0.5) : colorScheme.onSurface.withOpacity(0.1)),
//                 ),
//                 child: TextField(
//                   controller: _msgController,
//                   focusNode: _focusNode,
//                   maxLines: 5,
//                   minLines: 1,
//                   textCapitalization: TextCapitalization.sentences,
//                   style: TextStyle(color: colorScheme.onSurface),
//                   onChanged: (val) {
//                     if (val.isNotEmpty && !_hasText) setState(() => _hasText = true);
//                     else if (val.isEmpty && _hasText) setState(() => _hasText = false);
//                     if (_showMicTutorial) setState(() => _showMicTutorial = false); // Ocultar tooltip al teclear
//                   },
//                   decoration: InputDecoration(
//                     hintText: _isEphemeral ? "Mensaje efímero..." : "Escribe un mensaje...",
//                     hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
//                     border: InputBorder.none,
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),

//             // 🚀 BOTÓN MÁGICO 3 EN 1: Enviar / Grabar / IA (Swipe Left)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 2),
//               child: GestureDetector(
//                 onTap: _hasText ? () {
//                   _enviarMensajeTexto();
//                   setState(() => _showAttachmentMenu = false);
//                 } : null,
                
//                 onLongPress: () async {
//                   setState(() => _showMicTutorial = false);
//                   if (!_hasText) {
//                     HapticFeedback.heavyImpact();
//                     await _iniciarGrabacion();
//                   }
//                 },
                
//                 onLongPressMoveUpdate: _hasText ? (details) {
//                   if (details.offsetFromOrigin.dx < -40 && !_isSwipingLeftForAi) {
//                     setState(() => _isSwipingLeftForAi = true);
//                     HapticFeedback.mediumImpact(); 
//                   } else if (details.offsetFromOrigin.dx >= -40 && _isSwipingLeftForAi) {
//                     setState(() => _isSwipingLeftForAi = false);
//                   }
//                 } : null,
                
//                 onLongPressEnd: (details) async {
//                   if (!_hasText) {
//                     await _detenerYEnviarAudio();
//                   } else {
//                     if (_isSwipingLeftForAi) {
//                       setState(() => _isSwipingLeftForAi = false);
//                       HapticFeedback.heavyImpact();
//                       _crearTareaConIA(); 
//                     } else {
//                       _enviarMensajeTexto();
//                     }
//                   }
//                 },
                
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   padding: EdgeInsets.all(_isRecording ? 16 : 14),
//                   decoration: BoxDecoration(
//                     color: _isSwipingLeftForAi 
//                       ? Colors.deepPurpleAccent 
//                       : (_hasText ? colorScheme.primary : (_isRecording ? Colors.redAccent : colorScheme.primary)),
//                     shape: BoxShape.circle,
//                     boxShadow: _isSwipingLeftForAi ? [const BoxShadow(color: Colors.deepPurpleAccent, blurRadius: 12)] : [],
//                   ),
//                   child: Icon(
//                     _isSwipingLeftForAi
//                         ? Icons.auto_awesome_rounded 
//                         : (_hasText ? Icons.send_rounded : (_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded)),
//                     color: Colors.white,
//                     size: _isRecording || _isSwipingLeftForAi ? 26 : 22,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded), 
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          //  BOTÓN IA RESTAURADO ARRIBA A LA DERECHA
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent),
            tooltip: 'Aprender de este chat',
            onPressed: () => _extraerConocimiento(context),
          ),
        ],
        title: GestureDetector(
          onTap: () => ChatProfileModal.show(context, widget.address),
          child: Row(
            children: [
              SmartAvatar(address: widget.address, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.alias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                    
                    // Estado de "escribiendo" o última vez visto
                    Consumer<SecureChatService>(
                      builder: (context, chatService, child) {
                        if (chatService.typingUser == widget.address.toLowerCase()) {
                          return Text("escribiendo...", style: TextStyle(color: colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic));
                        }
                        return Text(
                          "últ. vez hoy a las 10:30", 
                          style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // 🔥 NUEVO: FONDO DE CUADRÍCULA ESTILO MOCKUP
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(color: onSurface.withOpacity(0.04)),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController, 
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      reverse: true, 
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final rawMsg = _messages[index];
                        final parsedMap = _parseMessageContent(rawMsg['content'].toString());
                        
                        final miBilletera = authCore.publicAddress.toLowerCase();
                        final senderWallet = rawMsg['sender'].toString().toLowerCase();
                        final isMe = (senderWallet == miBilletera) || (senderWallet == 'me');
                        
                        return MessageBubble(message: parsedMap, isMe: isMe, peerAddress: widget.address);
                      },
                    ),
                  ),

                  // BARRA DE ENTRADA DE CHAT TIPO PÍLDORA
                  _buildInputArea(),
                ],
              ),

              // MENÚ DESPLEGABLE DE ADJUNTOS
              if (_showAttachmentMenu)
                Positioned(
                  bottom: 80, 
                  left: 16,
                  child: _buildAttachmentMenu(),
                ),

              if (_showMicTutorial)
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Text(
                        "Mantén presionado para Audio 🎤\n¡O arrastra a la izquierda para IA! ✨",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }
  


  Widget _buildAttachmentMenu() {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_money_rounded, color: Colors.amber),
              tooltip: "Enviar TTC",
              onPressed: () async {
                setState(() => _showAttachmentMenu = false);
                String saldo = await Provider.of<TransactionService>(context, listen: false).getBalance();
                if (!mounted) return;
                SendModal.show(context: context, balanceTTC: saldo, initialAddress: "@${widget.alias}", onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
              },
            ),
            IconButton(
              icon: Icon(Icons.timer_rounded, color: _isEphemeral ? Colors.redAccent : Colors.grey),
              tooltip: "Chat Efímero",
              onPressed: () {
                setState(() { _isEphemeral = !_isEphemeral; _showAttachmentMenu = false; });
                UIHelper.showCustomSnackbar(_isEphemeral ? "Modo Efímero Activado (10 min)" : "Modo Efímero Desactivado");
              },
            ),
            IconButton(
              icon: const Icon(Icons.image_rounded, color: Colors.white),
              tooltip: "Enviar Imagen",
              onPressed: () {
                setState(() => _showAttachmentMenu = false);
                _enviarImagen();
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent),
              tooltip: "Redactar Tarea IA",
              onPressed: () {
                setState(() => _showAttachmentMenu = false);
                if (_hasText) _crearTareaConIA(); 
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 20),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // BOTÓN DEL CLIP
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: IconButton(
                  icon: AnimatedRotation(
                    turns: _showAttachmentMenu ? 0.125 : 0, 
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.attach_file_rounded, color: onSurface.withOpacity(0.6), size: 24),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachmentMenu = !_showAttachmentMenu;
                      _showMicTutorial = false; 
                    });
                  },
                ),
              ),

              // TEXTFIELD
              Expanded(
                child: TextField(
                  controller: _msgController,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: onSurface),
                  onChanged: (val) {
                    if (val.isNotEmpty && !_hasText) setState(() => _hasText = true);
                    else if (val.isEmpty && _hasText) setState(() => _hasText = false);
                    if (_showMicTutorial) setState(() => _showMicTutorial = false);
                  },
                  decoration: InputDecoration(
                    hintText: _isEphemeral ? "Mensaje efímero..." : "Mensaje",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // BOTÓN MAGICO DE ENVIAR/GRABAR (Integrado en la píldora)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 6),
                child: GestureDetector(
                  onTap: _hasText ? () {
                    _enviarMensajeTexto();
                    setState(() => _showAttachmentMenu = false);
                  } : null,
                  onLongPress: () async {
                    setState(() => _showMicTutorial = false);
                    if (!_hasText) {
                      HapticFeedback.heavyImpact();
                      await _iniciarGrabacion();
                    }
                  },
                  onLongPressMoveUpdate: _hasText ? (details) {
                    if (details.offsetFromOrigin.dx < -40 && !_isSwipingLeftForAi) {
                      setState(() => _isSwipingLeftForAi = true);
                      HapticFeedback.mediumImpact(); 
                    } else if (details.offsetFromOrigin.dx >= -40 && _isSwipingLeftForAi) {
                      setState(() => _isSwipingLeftForAi = false);
                    }
                  } : null,
                  onLongPressEnd: (details) async {
                    if (!_hasText) {
                      await _detenerYEnviarAudio();
                    } else {
                      if (_isSwipingLeftForAi) {
                        setState(() => _isSwipingLeftForAi = false);
                        HapticFeedback.heavyImpact();
                        _crearTareaConIA(); 
                      } else {
                        _enviarMensajeTexto();
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_isRecording ? 12 : 10),
                    decoration: BoxDecoration(
                      color: _isSwipingLeftForAi ? Colors.deepPurpleAccent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSwipingLeftForAi
                          ? Icons.auto_awesome_rounded 
                          : (_hasText ? Icons.send_rounded : (_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded)),
                      color: _hasText || _isRecording || _isSwipingLeftForAi ? colorScheme.primary : onSurface.withOpacity(0.6),
                      size: _isRecording || _isSwipingLeftForAi ? 26 : 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double spacing = 30.0; // Espaciado de los cuadros

    // Líneas verticales
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Líneas horizontales
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
