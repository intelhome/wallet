import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

// class UserConfigService {
//   final AuthCoreService authCore;

//   UserConfigService(this.authCore);

//   // 🔥 1. HEADER BLINDADO: Obligamos al servidor a entender que es un JSON y enviamos el Token
//   Map<String, String> get _headers {
//     return {
//       "Content-Type": "application/json",
//       if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//     };
//   }

//   Future<Map<String, dynamic>?> getConfig() async {
//     if (authCore.publicAddress.isEmpty) return null;
//     try {
//       final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
//       final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      
//       if (response.statusCode == 200) return jsonDecode(response.body);
//     } catch (e) {
//       print("❌ [Flutter] Error obteniendo configuraciones: $e");
//     }
//     return null;
//   }

//   Future<bool> savePayPalConfig(bool enabled, String email) async {
//     try {
//       print("🚀 [Flutter] Enviando petición a: ${ApiConfig.paypalConfig}");
      
//       final res = await http.post(
//         Uri.parse(ApiConfig.paypalConfig),
//         headers: _headers,
//         body: jsonEncode({
//           "walletAddress": authCore.publicAddress.toLowerCase(),
//           "paypalEnabled": enabled,
//           "paypalEmail": email.trim()
//         }),
//       );
      
//       // 🔥 LOG CRÍTICO PARA DEBUG: Nos dirá si es 403 (Seguridad), 415 (Tipo de dato) o 200 (OK)
//       print("🎯 [Flutter] Respuesta del Servidor (PayPal): HTTP ${res.statusCode} | Body: ${res.body}");
//       return res.statusCode == 200;
//     } catch (e) {
//       print("❌ [Flutter] Error fatal en petición PayPal: $e");
//       return false;
//     }
//   }

//   Future<bool> updateNotificationPreferences(bool email, bool whatsapp, bool push) async {
//     try {
//       final url = Uri.parse(ApiConfig.updateNotifications.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
//       final res = await http.put(url, headers: _headers, body: jsonEncode({"email": email, "whatsapp": whatsapp, "push": push}));
      
//       print("🎯 [Flutter] Respuesta del Servidor (Notificaciones): HTTP ${res.statusCode}");
//       return res.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<bool> updateDailyLimit(double newLimit) async {
//     try {
//       final url = Uri.parse(ApiConfig.updateDailyLimitSetting.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
//       final res = await http.put(url, headers: _headers, body: jsonEncode({"limit": newLimit.toString()}));
//       return res.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<bool> updateCrowdfundingVisibility(bool showCrowdfunding) async {
//     try {
//       final url = Uri.parse(ApiConfig.updateCrowdfundingSetting.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
//       final res = await http.put(url, headers: _headers, body: jsonEncode({"showCrowdfunding": showCrowdfunding}));
//       return res.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }
// }

class UserConfigService {
  final AuthCoreService authCore;

  UserConfigService(this.authCore);

  Map<String, String> get _headers {
    return {
      "Content-Type": "application/json",
      if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
    };
  }

  // 1. Obtener la configuración al inicio (Se mantiene igual, GET)
  Future<Map<String, dynamic>?> getConfig() async {
    if (authCore.publicAddress.isEmpty) return null;
    try {
      final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("❌ [Flutter] Error obteniendo configuraciones: $e");
    }
    return null;
  }

  // 🔥 2. MAGIA PATCH: Desde aquí, todos apuntan a la misma URL, enviando solo su pedacito de JSON

  Future<bool> savePayPalConfig(bool enabled, String email) async {
    try {
      final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final res = await http.patch(url, headers: _headers, body: jsonEncode({
        "paypalEnabled": enabled,
        "encryptedPaypalEmail": email // El backend lo ignorará si viene vacío
      }));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateNotificationPreferences(bool email, bool whatsapp, bool push) async {
    try {
      final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final res = await http.patch(url, headers: _headers, body: jsonEncode({
        "notifyEmail": email, 
        "notifyWhatsapp": whatsapp, 
        "notifyPush": push
      }));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDailyLimit(double newLimit) async {
    try {
      final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final res = await http.patch(url, headers: _headers, body: jsonEncode({
        "dailyFiatLimit": newLimit
      }));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCrowdfundingVisibility(bool showCrowdfunding) async {
    try {
      final url = Uri.parse(ApiConfig.getUserConfig.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
      final res = await http.patch(url, headers: _headers, body: jsonEncode({
        "showCrowdfunding": showCrowdfunding
      }));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}