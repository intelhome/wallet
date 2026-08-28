import 'dart:convert';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import '../../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class CallService {
  final AuthCoreService authCore;
  final UserService userService; 
  IOWebSocketChannel? _channel;
  bool isConnected = false;
  String? _myPhoneNumber;

  CallService(this.authCore, this.userService);

  /// Conecta el celular al Servidor de Señalización WebRTC (Spring Boot)
  Future<void> connectToSignalingServer() async {
    if (isConnected || authCore.publicAddress.isEmpty) return;

    try {
      // 1. Obtenemos nuestro propio número de teléfono
      if (_myPhoneNumber == null) {
        final userData = await userService.getUserByWallet(authCore.publicAddress);
        if (userData != null && userData['phoneNumber'] != null) {
          _myPhoneNumber = userData['phoneNumber'];
        } else {
          print("❌ [WEBRTC] No tienes número de teléfono registrado.");
          return; 
        }
      }
      
      // 2. Nos conectamos usando nuestro número de teléfono 
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = "$baseWsUrl/ws/calls/$_myPhoneNumber";
      
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen((message) {
        _handleIncomingSignal(jsonDecode(message));
      }, onDone: () {
        isConnected = false;
      });

      isConnected = true;
      print("📞 [WEBRTC] Conectado al servidor de llamadas con teléfono: $_myPhoneNumber");
    } catch (e) {
      print("❌ [WEBRTC] Error al conectar: $e");
    }
  }

  void _handleIncomingSignal(Map<String, dynamic> data) {
    String type = data['type'] ?? 'UNKNOWN';
    String senderPhone = data['senderPhone'] ?? 'Desconocido';
    
    // Aquí es donde en un futuro le pasaremos el 'payload' (SDP o ICE) al paquete flutter_webrtc
    print("📡 [WEBRTC] Señal $type recibida de $senderPhone");

    if (type == "USER_OFFLINE") {
      print("⚠️ El usuario no tiene la app abierta. Esperando a que el Push Notification lo despierte...");
    }
  }

  // Llama a Ariana (O a otro TTC Wallet)
  Future<void> initiateCall(String targetPhone) async {
    if (!isConnected) await connectToSignalingServer();

    // 1. Enviamos la señal inicial P2P
    if (_myPhoneNumber != null) {
      _channel?.sink.add(jsonEncode({
        "type": "CALL_REQUEST",
        "senderPhone": _myPhoneNumber,
        "targetPhone": targetPhone,
        "payload": "Llamada entrante de TTC Wallet"
      }));
    }

    // 2. Opcional: También golpeamos el REST por si Ariana necesita ser despertada por webhook
    try {
      final url = Uri.parse(ApiConfig.wakeUpCall);
      await http.post(url, headers: authCore.authHeaders, body: jsonEncode({
        "senderPhone": _myPhoneNumber ?? authCore.publicAddress,
        "targetPhone": targetPhone
      }));
    } catch (_) {}
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
    _myPhoneNumber = null;
  }
}