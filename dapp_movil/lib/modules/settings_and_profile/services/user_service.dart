import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class UserService {
  final AuthCoreService authCore;

  UserService(this.authCore);

  // --- ANALÍTICAS Y LÍMITES ---

  Future<Map<String, dynamic>?> getAnalyticsData() async {
    if (authCore.publicAddress.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAnalytics.replaceAll("{address}", authCore.publicAddress.toLowerCase())),
        headers: authCore.authHeaders
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Future<bool> updateDailyLimit(double newLimit) async {
  //   if (authCore.publicAddress.isEmpty) return false;
  //   try {
  //     final res = await http.put(
  //       Uri.parse(ApiConfig.updateDailyLimit.replaceAll("{address}", authCore.publicAddress.toLowerCase())),
  //       headers: authCore.authHeaders, 
  //       body: jsonEncode({"limit": newLimit.toString()}),
  //     ).timeout(const Duration(seconds: 10));

  //     return res.statusCode == 200;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // --- SEGURIDAD AVANZADA ---

  Future<String> toggleAccountFreeze(bool freeze, String totpCode) async {
    try {
      String endpoint = ApiConfig.toggleFreeze.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.put(
        Uri.parse(endpoint),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "isFrozen": freeze,
          "totpCode": totpCode
        })
      );

      if (res.statusCode == 200) return "SUCCESS";
      final data = jsonDecode(res.body);
      return data['error'] ?? "Error desconocido en el servidor";
    } catch (e) {
      return "Error de red al contactar al servidor";
    }
  }

  Future<bool> checkIfFrozen() async {
    try {
      String endpoint = ApiConfig.toggleFreeze.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['isFrozen'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getActiveDevices() async {
    try {
      String endpoint = ApiConfig.getDevices.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<String> revokeOtherSessions(String totpCode) async {
    try {
      String endpoint = ApiConfig.revokeDevices.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.post(
        Uri.parse(endpoint), 
        headers: authCore.authHeaders,
        body: jsonEncode({
          "currentDeviceName": "Dispositivo Móvil (Android/iOS)", 
          "totpCode": totpCode
        })
      );
      
      if (res.statusCode == 200) return "SUCCESS";
      final data = jsonDecode(res.body);
      return data['error'] ?? "Error desconocido en el servidor";
    } catch (e) { 
      return "Error de red"; 
    }
  }

  // --- CONTACTOS Y OTP ---

  Future<List<dynamic>> getUserContacts() async {
    try {
      String endpoint = ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>?> fetchPayeeInfo(String identifier) async {
    try {
      String endpoint = ApiConfig.getPayeeInfo.replaceAll("{identifier}", identifier);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendOtp(String email) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.sendOtp), headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": email}));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.verifyOtp), headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": email, "otp": otp}));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

 /// Obtiene el Alias y datos de una Wallet (Ideal para Dashboard, Settings, Chat)
  Future<Map<String, dynamic>?> getUserByWallet(String walletAddress) async {
    try {
      final url = Uri.parse(ApiConfig.getAliasWallet.replaceAll("{address}", walletAddress.toLowerCase()));
      final response = await http.get(url, headers: authCore.authHeaders).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error UserService.getUserByWallet: $e");
    }
    return null;
  }

  /// Verifica si un Alias está disponible (Para el RegisterScreen)
  Future<bool> checkAliasAvailability(String alias) async {
    try {
      final url = Uri.parse(ApiConfig.getAlias.replaceAll("{alias}", alias.toLowerCase()));
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Error UserService.checkAliasAvailability: $e");
    }
    return false;
  }

  /// Busca a un usuario por su Alias exacto
  Future<Map<String, dynamic>?> searchByAlias(String alias) async {
    try {
      final query = alias.replaceAll("@", "").trim();
      final url = Uri.parse(ApiConfig.searchAlias.replaceAll("{alias}", query));
      final response = await http.get(url, headers: authCore.authHeaders);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) return decoded.first;
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (e) {
      print("Error UserService.searchByAlias: $e");
    }
    return null;
  }

  // 🔥 Guardar la configuración encriptada de PayPal
  // Future<bool> savePayPalConfig(bool enabled, String email) async {
  //   try {
  //     final res = await http.post(
  //       Uri.parse(ApiConfig.paypalConfig),
  //       headers: authCore.authHeaders,
  //       body: jsonEncode({
  //         "walletAddress": authCore.publicAddress.toLowerCase(),
  //         "paypalEnabled": enabled,
  //         "paypalEmail": email.trim()
  //       }),
  //     );
  //     return res.statusCode == 200;
  //   } catch (e) {
  //     print("Error savePayPalConfig: $e");
  //     return false;
  //   }
  // }

  // 🔥 Verificar si el destinatario acepta pagos con PayPal
  Future<Map<String, dynamic>?> checkPayeePayPal(String identifier) async {
    print("📝 [LOG PayPal] Consultando estado de PayPal para: $identifier");
    try {
      final url = ApiConfig.paypalCheckPayee.replaceAll("{identifier}", identifier.trim().toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      
      print("📝 [LOG PayPal] Respuesta checkPayeePayPal (${res.statusCode}): ${res.body}");
      
      // Aceptamos el 400 porque el backend nos manda un JSON con el mensaje "error" que queremos mostrar
      if (res.statusCode == 200 || res.statusCode == 400) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("📝 [ERROR PayPal] checkPayeePayPal: $e");
    }
    return null;
  }

  // 🔥 Crear una Orden P2P Directa en PayPal
  Future<Map<String, dynamic>?> createPayPalP2POrder(String targetIdentifier, double amount, String reason) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.paypalCreateOrder),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "targetIdentifier": targetIdentifier.trim(),
          "amount": amount,
          "reason": reason.isEmpty ? "Transferencia Fiat DApp" : reason
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Error createPayPalP2POrder: $e");
    }
    return null;
  }

  // 🔥 Capturar la orden liquidada e insertarla en el Historial Off-chain
  Future<bool> capturePayPalP2POrder(String orderId, String receiverWallet, double amount) async {
    try {
      final url = ApiConfig.paypalCaptureOrder.replaceAll("{orderId}", orderId);
      final res = await http.post(
        Uri.parse(url),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "senderWallet": authCore.publicAddress.toLowerCase(),
          "receiverWallet": receiverWallet.toLowerCase(),
          "amount": amount.toString()
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'SUCCESS';
      }
    } catch (e) {
      print("Error capturePayPalP2POrder: $e");
    }
    return false;
  }
  // 🔥 NUEVO: Método PATCH ultra-flexible para actualizar datos del perfil
  Future<bool> updateUserProfile({
    String? alias,
    String? email,
    String? phoneNumber,
    String? cedula,
    bool? is2faEnabled,
  }) async {
    if (authCore.publicAddress.isEmpty) return false;
    
    // Armamos el JSON SOLO con los campos que nos enviaron, ignorando los nulos
    Map<String, dynamic> body = {};
    if (alias != null) body["alias"] = alias;
    if (email != null) body["email"] = email;
    if (phoneNumber != null) body["phoneNumber"] = phoneNumber;
    if (cedula != null) body["cedula"] = cedula;
    if (is2faEnabled != null) body["is2faEnabled"] = is2faEnabled;

    if (body.isEmpty) return true; // No hay nada que enviar

    try {
      // Apuntamos al endpoint unificado PATCH /api/users/{walletAddress}
      final url = Uri.parse("${ApiConfig.baseUrl}/users/${authCore.publicAddress.toLowerCase()}");
      
      final res = await http.patch(
        url,
        headers: authCore.authHeaders, // Reutilizamos tus headers
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        print("✅ [PERFIL] Perfil actualizado exitosamente vía PATCH");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ [PERFIL] Error actualizando: $e");
      return false;
    }
  }
}