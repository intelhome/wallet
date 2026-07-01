import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class BurnerService {
  final AuthCoreService authCore;

  BurnerService(this.authCore);

  // 🔥 HELPER LOCAL DE ERRORES 🔥
  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

/// Obtiene todas las billeteras desechables activas (Por defecto del usuario actual, o de un target)
  // Future<List<dynamic>> getActiveBurners([String? targetAddress]) async {
  //   String addressToQuery = targetAddress ?? authCore.publicAddress;
  //   if (addressToQuery.isEmpty) return [];
    
  //   try {
  //     final url = ApiConfig.getBurners.replaceAll("{address}", addressToQuery.toLowerCase());
  //     print("📱 [FRONT-BURNER] Solicitando lista de tarjetas a: $url");
      
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      
  //     if (res.statusCode == 200) {
  //       return jsonDecode(res.body);
  //     }
  //     return [];
  //   } catch (e) {
  //     print("❌ [FRONT-BURNER] Error obteniendo Burner Wallets: $e");
  //     return [];
  //   }
  // }

   Future<List<dynamic>> getActiveBurners([String? targetAddress]) async {
    String addressToQuery = targetAddress ?? authCore.publicAddress;
    if (addressToQuery.isEmpty) return [];
    
    try {
      final url = ApiConfig.getBurners.replaceAll("{address}", addressToQuery.toLowerCase());
      print("📱 [FRONT-BURNER] Solicitando lista de tarjetas a: $url");
      
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print("❌ [FRONT-BURNER] Error obteniendo Burner Wallets: $e");
      return [];
    }
  }
  
  /// Crea una nueva billetera efímera y le transfiere fondos iniciales
  Future<String> createBurnerWallet(String label, double amount) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera principal no conectada";

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createBurner),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "mainWalletAddress": authCore.publicAddress.toLowerCase(),
          "label": label,
          "initialAmount": amount
        })
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) return "Exito";
      return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
    } catch (e) {
      return "Error de red al crear burner: $e";
    }
  }

  /// Quema la billetera, rescata los fondos sobrantes y destruye la llave privada
//   Future<String> burnWallet(String burnerAddress) async {
//     if (authCore.publicAddress.isEmpty) return "Error: Billetera principal no conectada";

//     try {
//       final res = await http.post(
//         Uri.parse(ApiConfig.burnWallet),
//         headers: authCore.authHeaders,
//         body: jsonEncode({
//           "mainWalletAddress": authCore.publicAddress.toLowerCase(),
//           "burnerAddress": burnerAddress.toLowerCase()
//         })
//       ).timeout(const Duration(seconds: 20));

//       if (res.statusCode == 200) return "Exito";
//       return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
//     } catch (e) {
//       return "Error de red al quemar billetera";
//     }
//   }

//   /// Envía fondos de forma anónima desde la billetera desechable
//   Future<String> sendFromBurnerWallet(String burnerAddress, String toAddress, double amount) async {
//     if (authCore.publicAddress.isEmpty) return "Error: Billetera principal no conectada";

//     try {
//       final res = await http.post(
//         Uri.parse(ApiConfig.sendFromBurner),
//         headers: authCore.authHeaders,
//         body: jsonEncode({
//           "mainWalletAddress": authCore.publicAddress.toLowerCase(),
//           "burnerAddress": burnerAddress.toLowerCase(),
//           "toAddress": toAddress.toLowerCase(),
//           "amount": amount
//         })
//       ).timeout(const Duration(seconds: 20));

//      if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         return data['message'] ?? "Exito"; // 🔥 NUEVO: Retorna "Exito: 0xHash..."
//       }
//       return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
//     } catch (e) {
//       return "Error de red al enviar desde la burner";
//     }
//   }
// }

Future<double> burnWallet(String burnerAddress) async {
    if (authCore.publicAddress.isEmpty) throw Exception("Billetera no conectada");
    try {
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
         return double.tryParse(data['refunded']?.toString() ?? '0.0') ?? 0.0;
      }
      throw Exception(_extractErrorMessage(res.body, res.statusCode));
    } catch (e) {
      throw Exception("Error al quemar: $e");
    }
  }

  // 🔥 ACTUALIZADO: Recibe el parámetro "reason" y devuelve el Hash ("Exito: 0x...")
  Future<String> sendFromBurnerWallet(String burnerAddress, String toAddress, double amount, String reason) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera principal no conectada";
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sendFromBurner),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "mainWalletAddress": authCore.publicAddress.toLowerCase(),
          "burnerAddress": burnerAddress.toLowerCase(),
          "toAddress": toAddress.toLowerCase(),
          "amount": amount,
          "reason": reason // 🔥 Enviamos el motivo al backend
        })
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message'] ?? "Exito"; 
      }
      return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
    } catch (e) {
      return "Error de red al enviar desde la burner";
    }
  }

  // 🔥 NUEVO: Obtiene el historial corporativo
  // Future<List<dynamic>> getBurnerTransactionsHistory([String? targetAddress]) async {
  //   String addressToQuery = targetAddress ?? authCore.publicAddress;
  //   if (addressToQuery.isEmpty) return [];
  //   try {
  //     final url = ApiConfig.getBurnerTransactionsHistory.replaceAll("{address}", addressToQuery.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     if (res.statusCode == 200) return jsonDecode(res.body);
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getBurnerTransactionsHistory([String? targetAddress]) async {
    String addressToQuery = targetAddress ?? authCore.publicAddress;
    if (addressToQuery.isEmpty) return [];
    
    final cacheService = LocalCacheService();
    final walletStr = addressToQuery.toLowerCase();

    try {
      final url = ApiConfig.getBurnerTransactionsHistory.replaceAll("{address}", walletStr);
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveBurnerHistory(walletStr, data);
        return data;
      }
    } catch (e) { print("❌ Error obteniendo Historial Burner: $e"); }
    
    return cacheService.getCachedBurnerHistory(walletStr); // 🔥 FALLBACK
  }
  
}