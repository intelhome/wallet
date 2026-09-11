import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class AdminService {
  final AuthCoreService authCore;

  AdminService(this.authCore);

  String _extractError(String body) {
    try {
      return jsonDecode(body)['error'] ?? "Error desconocido";
    } catch (_) {
      return "Error del servidor";
    }
  }


Future<List<dynamic>> getPlans() async {
    final cacheService = LocalCacheService();
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/plans/config");
      final res = await http.get(url, headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveAdminPlans(data);
        return data;
      }
    } catch (e) { print("🚨 Error de red: $e"); }
    return cacheService.getCachedAdminPlans(); // 🔥 FALLBACK
  }

  Future<String> updatePlan(Map<String, dynamic> plan) async {
    try {
      print("📡 [ADMIN UPDATE] Intentando actualizar plan: ${plan['tier']} | Datos: $plan");
      
      Map<String, String> headersSeguros = Map.from(authCore.authHeaders);
      headersSeguros["Content-Type"] = "application/json"; 

      final res = await http.put(
        Uri.parse("${ApiConfig.adminPlans}/${plan['tier']}"),
        headers: headersSeguros,
        body: jsonEncode({
          "price": plan['price'],
          "allowedFeatures": plan['allowedFeatures']
        }),
      );
      
      print("📡 [ADMIN UPDATE] HTTP ${res.statusCode} | Respuesta: ${res.body}");
      
      if (res.statusCode == 200) return "Exito";
      return _extractError(res.body);
    } catch (e) {
      print("🚨 [ADMIN UPDATE] Excepción capturada en Flutter: $e");
      return "Error de red: $e";
    }
  }
  // ==========================================
  // GESTIÓN DE EMPRESAS PENDIENTES
  // ==========================================
  // Future<List<dynamic>> getPendingBusinesses() async {
  //   try {
  //     final res = await http.get(Uri.parse(ApiConfig.getPendingBusinesses), headers: authCore.authHeaders);
  //     if (res.statusCode == 200) return jsonDecode(res.body);
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getPendingBusinesses() async {
    final cacheService = LocalCacheService();
    try {
      final res = await http.get(Uri.parse(ApiConfig.getPendingBusinesses), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.savePendingBusinesses(data);
        return data;
      }
    } catch (e) { print("🚨 Error de red: $e"); }
    return cacheService.getCachedPendingBusinesses(); 
  }

  Future<String> reviewBusiness(String walletAddress, bool isApproved) async {
    try {
      final endpoint = ApiConfig.reviewBusiness.replaceAll("{address}", walletAddress);
      final res = await http.put(
        Uri.parse(endpoint),
        headers: authCore.authHeaders,
        body: jsonEncode({"isApproved": isApproved}),
      );
      
      if (res.statusCode == 200) return "Exito";
      return _extractError(res.body);
    } catch (e) {
      return "Error crítico de conexión";
    }
  }

//  Future<Map<String, dynamic>?> getSubscriptionAnalytics() async {
//     try {
//       final url = Uri.parse(ApiConfig.adminSubscriptionAnalytics);
//       print("📡 [ADMIN ANALYTICS] Petición a: $url");
      
//       final res = await http.get(url, headers: authCore.authHeaders);
      
//       print("📡 [ADMIN ANALYTICS] HTTP ${res.statusCode} | Respuesta: ${res.body}");

//       if (res.statusCode == 200) {
//         return jsonDecode(res.body);
//       }
//       return null;
//     } catch (e) {
//     
//       return null;
//     }
//   }

Future<Map<String, dynamic>?> getSubscriptionAnalytics() async {
    final cacheService = LocalCacheService();
    try {
      final url = Uri.parse(ApiConfig.adminSubscriptionAnalytics);
      final res = await http.get(url, headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveAdminAnalytics(data);
        return data;
      }
    } catch (e) { print("🚨 Error de red: $e"); }
    return cacheService.getCachedAdminAnalytics(); 
  }
  

  Future<String> updateUserTier(String walletAddress, String newTier) async {
    try {
      final res = await http.put(
        Uri.parse(ApiConfig.adminUpdateUserTier(walletAddress)),
        headers: authCore.authHeaders,
        body: jsonEncode({"tier": newTier}),
      );
      if (res.statusCode == 200) return "Exito";
      return _extractError(res.body);
    } catch (e) {
      return "Error de red: $e";
    }
  }

  // Future<List<dynamic>> getUsersByTier(String tier) async {
  //   try {
  //     final res = await http.get(Uri.parse(ApiConfig.adminUsersByTier(tier)), headers: authCore.authHeaders);
  //     if (res.statusCode == 200) {
  //       return jsonDecode(res.body);
  //     }
  //     return [];
  //   } catch (e) {
  //     
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getUsersByTier(String tier) async {
    final cacheService = LocalCacheService();
    try {
      final res = await http.get(Uri.parse(ApiConfig.adminUsersByTier(tier)), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveUsersByTier(tier, data);
        return data;
      }
    } catch (e) { print("🚨 Error de red: $e"); }
    return cacheService.getCachedUsersByTier(tier); 
  }
  
Future<Map<String, dynamic>> getWhaleTransactions(double minAmount, {int page = 0, int size = 20}) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.adminWhaleTransactions}?minAmount=$minAmount&page=$page&size=$size"),
        headers: authCore.authHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("🚨 Error en getWhaleTransactions: $e");
    }
    return {"content": [], "last": true};
  }

  Future<Map<String, dynamic>> getFailedTransactions({int page = 0, int size = 20}) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.adminFailedTransactions}?page=$page&size=$size"),
        headers: authCore.authHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("🚨 Error en getFailedTransactions: $e");
    }
    return {"content": [], "last": true};
  }

  // ==========================================
  // SOPORTE Y REEMBOLSOS FORZADOS (Crowdfunding)
  // ==========================================
  Future<Map<String, dynamic>> getStuckCampaigns({int page = 0, int size = 20}) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.adminStuckCampaigns}?page=$page&size=$size"),
        headers: authCore.authHeaders,
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("🚨 Error en getStuckCampaigns: $e");
    }
    return {"content": [], "last": true};
  }

  Future<String> forceRefundCampaign(String campaignId, String reason) async {
    try {
      final res = await http.put(
        Uri.parse(ApiConfig.adminForceRefundCampaign(campaignId)),
        headers: authCore.authHeaders,
        body: jsonEncode({"reason": reason}),
      ).timeout(const Duration(seconds: 20)); // Damos tiempo porque interactúa con Smart Contract

      if (res.statusCode == 200) return "Exito";
      return _extractError(res.body);
    } catch (e) {
      return "Error de red al forzar reembolso: $e";
    }
  }
  
}