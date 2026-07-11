import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class BurnerService {
  final AuthCoreService authCore;

  BurnerService(this.authCore);

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

  Future<List<dynamic>> getActiveBurners([String? targetAddress]) async {
    String addressToQuery = targetAddress ?? authCore.publicAddress;
    if (addressToQuery.isEmpty) return [];
    
    try {
      final url = ApiConfig.getBurners.replaceAll("{address}", addressToQuery.toLowerCase());
      print("🔍 [FRONT-BURNER] Consultando tarjetas activas: $url");
      
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("✅ [FRONT-BURNER] Tarjetas encontradas: ${data.length}");
        return data;
      }
      print("❌ [FRONT-BURNER] Error listando tarjetas HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      print("❌ [FRONT-BURNER] Excepción listando tarjetas: $e");
      return [];
    }
  }
  
 Future<Map<String, dynamic>> createBurnerWallet(String label, double amount) async {
    if (authCore.publicAddress.isEmpty) return {"success": false, "error": "Billetera principal no conectada"};

    try {
      print("🚀 [FRONT-BURNER] Creando tarjeta '$label' con $amount TTC...");
      final res = await http.post(
        Uri.parse(ApiConfig.createBurner),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "mainWalletAddress": authCore.publicAddress.toLowerCase(),
          "label": label,
          "initialAmount": amount
        })
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("✅ [FRONT-BURNER] Tarjeta creada en BD exitosamente.");
        return {"success": true, "data": jsonDecode(res.body)};
      }
      
      String error = _extractErrorMessage(res.body, res.statusCode);
      print("❌ [FRONT-BURNER] Error en creación: $error");
      return {"success": false, "error": error};
    } catch (e) {
      print("❌ [FRONT-BURNER] Excepción creando tarjeta: $e");
      return {"success": false, "error": "Error de red al crear burner: $e"};
    }
  }

  Future<double> burnWallet(String burnerAddress) async {
    if (authCore.publicAddress.isEmpty) throw Exception("Billetera no conectada");
    try {
      print("🔥 [FRONT-BURNER] Quemando tarjeta $burnerAddress...");
      final res = await http.post(
        Uri.parse(ApiConfig.burnWallet),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "mainWalletAddress": authCore.publicAddress.toLowerCase(),
          "burnerAddress": burnerAddress.toLowerCase()
        })
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
         final data = jsonDecode(res.body);
         double refunded = double.tryParse(data['refunded']?.toString() ?? '0.0') ?? 0.0;
         print("✅ [FRONT-BURNER] Tarjeta quemada con éxito. Rescatados $refunded TTC.");
         return refunded;
      }
      String error = _extractErrorMessage(res.body, res.statusCode);
      print("❌ [FRONT-BURNER] Error quemando tarjeta: $error");
      throw Exception(error);
    } catch (e) {
      print("❌ [FRONT-BURNER] Excepción al quemar: $e");
      throw Exception("Error al quemar: $e");
    }
  }

  Future<String> sendFromBurnerWallet(String burnerAddress, String toAddress, double amount, String reason) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera principal no conectada";
    try {
      print("💸 [FRONT-BURNER] Pagando $amount TTC desde $burnerAddress hacia $toAddress...");
      final res = await http.post(
        Uri.parse(ApiConfig.sendFromBurner),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "mainWalletAddress": authCore.publicAddress.toLowerCase(),
          "burnerAddress": burnerAddress.toLowerCase(),
          "toAddress": toAddress.toLowerCase(),
          "amount": amount,
          "reason": reason
        })
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("✅ [FRONT-BURNER] Pago enviado. Hash: ${data['message']}");
        return data['message'] ?? "Exito"; 
      }
      String error = _extractErrorMessage(res.body, res.statusCode);
      print("❌ [FRONT-BURNER] Error en pago delegado: $error");
      return "Error: $error";
    } catch (e) {
      print("❌ [FRONT-BURNER] Excepción enviando pago: $e");
      return "Error de red al enviar desde la burner";
    }
  }

  Future<List<dynamic>> getBurnerTransactionsHistory([String? targetAddress]) async {
    String addressToQuery = targetAddress ?? authCore.publicAddress;
    if (addressToQuery.isEmpty) return [];
    
    final cacheService = LocalCacheService();
    final walletStr = addressToQuery.toLowerCase();

    try {
      print("🧾 [FRONT-BURNER] Obteniendo historial corporativo...");
      final url = ApiConfig.getBurnerTransactionsHistory.replaceAll("{address}", walletStr);
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveBurnerHistory(walletStr, data);
        print("✅ [FRONT-BURNER] Historial cargado (${data.length} txs).");
        return data;
      }
    } catch (e) { 
      print("❌ [FRONT-BURNER] Error obteniendo Historial Burner: $e"); 
    }
    
    return cacheService.getCachedBurnerHistory(walletStr);
  }
}