import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class AiService {
  final AuthCoreService authCore;

  AiService(this.authCore);


  Future<String> sendMessageToAi(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");
      
      final Map<String, dynamic> body = {
        "message": message,
        "walletAddress": authCore.publicAddress.toLowerCase(),
      };

      // Si nos pasan el historial, lo inyectamos para que el backend lo reciba
      if (history != null && history.isNotEmpty) {
        body["history"] = history;
      }
      
      final response = await http.post(
        url,
        headers: authCore.authHeaders, 
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "Sin respuesta del servidor.";
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return "Sesión expirada. Por favor, reinicia la aplicación.";
      } else if (response.statusCode == 402) {
        final data = jsonDecode(response.body);
        return "ERROR_QUOTA: ${data['message']}"; // Manejo interno para cuotas
      } else {
        return "Error del servidor al consultar la IA.";
      }
    } catch (e) {
      print("Error AiService: $e");
      return "Error de red. Verifica tu conexión.";
    }
  }
  

  // Future<String> sendMessageToAi(String message) async {
  //   try {
  //     final url = Uri.parse("${ApiConfig.baseUrl}/ai/chat");
      
  //     final response = await http.post(
  //       url,
  //       headers: authCore.authHeaders, 
  //       body: jsonEncode({"message": message}),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return data['response'] ?? "Sin respuesta del servidor.";
  //     } else if (response.statusCode == 401 || response.statusCode == 403) {
  //       return "Sesión expirada. Por favor, reinicia la aplicación.";
  //     } else {
  //       return "Error del servidor al consultar la IA.";
  //     }
  //   } catch (e) {
  //     print("Error AiService: $e");
  //     return "Error de red. Verifica tu conexión.";
  //   }
  // }
}