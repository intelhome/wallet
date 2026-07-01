import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../wallet_and_tx/services/transaction_service.dart';

class DebtService {
  final AuthCoreService authCore;
  final TransactionService txService; // Inyectamos el servicio de transacciones

  DebtService(this.authCore, this.txService);

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

  Future<String> _postRequest(String urlStr, Map<String, dynamic> bodyData) async {
    try {
      final response = await http.post(
        Uri.parse(urlStr),
        headers: authCore.authHeaders,
        body: jsonEncode(bodyData)
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) return "Exito";
      return "Error: ${_extractErrorMessage(response.body, response.statusCode)}";
    } catch (e) {
      return "Error crítico de red";
    }
  }

  // --- DEUDAS PERSONALES ---

  // Future<List<dynamic>> getUserDebts() async {
  //   if (authCore.publicAddress.isEmpty) return [];
  //   try {
  //     final res = await http.get(
  //       Uri.parse(ApiConfig.getUserDebts.replaceAll("{walletAddress}", authCore.publicAddress.toLowerCase())),
  //       headers: authCore.authHeaders
  //     );
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { 
  //     return []; 
  //   }
  // }

  Future<List<dynamic>> getUserDebts() async {
    if (authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      final res = await http.get(Uri.parse(ApiConfig.getUserDebts.replaceAll("{walletAddress}", wallet)), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveUserDebts(wallet, data);
        return data;
      }
    } catch (e) { print("Error get debts: $e"); }
    return cacheService.getCachedUserDebts(wallet);
  }

  Future<String> createDebtRequest(String debtorAddress, double amount, String reason) async {
    return await _postRequest(ApiConfig.createDebt, {
      "creditorAddress": authCore.publicAddress.toLowerCase(),
      "debtorAddress": debtorAddress.toLowerCase(),
      "amount": amount,
      "reason": reason
    });
  }

  Future<String> respondDebtRequest(String debtId, bool accept) async {
    return await _postRequest(ApiConfig.respondDebt.replaceAll("{debtId}", debtId), {
      "debtorAddress": authCore.publicAddress.toLowerCase(),
      "accept": accept
    });
  }

  /// Paga una deuda usando el TransactionService para mover el dinero
  // Future<String> payPersonalDebt(String debtId, double amount, String creditorAddress) async {
  //   try {
  //     // 1. Delegamos el envío de dinero al TransactionService
  //     String txResult = await txService.sendTokensL2(creditorAddress, amount);
  Future<String> payPersonalDebt(String debtId, double amount, String creditorAddress) async {
    try {
      BigInt amountWei = BigInt.from(amount * 1e18);
      String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: creditorAddress, amountWei: amountWei);
      if (signature == null) return "Error: Firma cancelada por el usuario";

      String txResult = await txService.sendTokensL2(creditorAddress, amount, signature);
      if (!txResult.startsWith("Exito")) return txResult; 

      // 2. Registramos el pago en el Backend de Deudas
      return await _postRequest(ApiConfig.payDebt.replaceAll("{debtId}", debtId), {
        "amountPaid": amount,
        "txHash": "TX_CONFIRMED" 
      });
    } catch (e) { 
      return "Error crítico al pagar deuda"; 
    }
  }

  // --- DEUDAS SOCIALIZADAS (LA VACA) ---

  Future<String> shareDebtToGroup(String originalDebtId, String groupId, String reason) async {
    return await _postRequest(ApiConfig.shareDebtGroup, {
      "originalDebtId": originalDebtId,
      "groupId": groupId,
      "debtorAddress": authCore.publicAddress.toLowerCase(),
      "reason": reason 
    });
  }

  // Future<List<dynamic>> getGroupSharedDebts(String groupId) async {
  //   try {
  //     final res = await http.get(
  //       Uri.parse(ApiConfig.getGroupSharedDebts.replaceAll("{groupId}", groupId)), 
  //       headers: authCore.authHeaders
  //     );
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { 
  //     return []; 
  //   }
  // }

  Future<List<dynamic>> getGroupSharedDebts(String groupId) async {
    final cacheService = LocalCacheService();
    try {
      final res = await http.get(Uri.parse(ApiConfig.getGroupSharedDebts.replaceAll("{groupId}", groupId)), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveGroupSharedDebts(groupId, data);
        return data;
      }
    } catch (e) { print("Error get shared debts: $e"); }
    return cacheService.getCachedGroupSharedDebts(groupId);
  }

  Future<String> voteToHelpSharedDebt(String sharedId) async {
    return await _postRequest(ApiConfig.voteSharedDebt.replaceAll("{sharedId}", sharedId), {
      "memberAddress": authCore.publicAddress.toLowerCase()
    });
  }

  // Future<String> contributeToSharedDebt(String sharedId, double amount, String vaultAddress) async {
  //   try {
  //     // 1. Enviamos el dinero a la BÓVEDA del grupo (Escrow)
  //     String txResult = await txService.sendTokensL2(vaultAddress, amount);
  Future<String> contributeToSharedDebt(String sharedId, double amount, String vaultAddress) async {
    try {
      BigInt amountWei = BigInt.from(amount * 1e18);
      String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: vaultAddress, amountWei: amountWei);
      if (signature == null) return "Error: Firma cancelada por el usuario";

      // 1. Enviamos el dinero a la BÓVEDA del grupo (Escrow)
      String txResult = await txService.sendTokensL2(vaultAddress, amount, signature);
      if (!txResult.startsWith("Exito")) return txResult;

      // 2. Avisamos al backend
      return await _postRequest(ApiConfig.contributeSharedDebt.replaceAll("{sharedId}", sharedId), {
        "amountPaid": amount,
        "txHash": "TX_CONFIRMED"
      });
    } catch (e) { 
      return "Error crítico en el aporte"; 
    }
  }

  Future<String> notifySharedDebtContribution(String sharedDebtId, double amount) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.contributeSharedDebt.replaceAll("{sharedId}", sharedDebtId)),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "amount": amount,
          "contributorAddress": authCore.publicAddress.toLowerCase()
        })
      );
      
      // Si el backend devuelve 200, fue un éxito
      if (res.statusCode == 200) {
        return "Exito";
      }
      return "Error al notificar contribución";
    } catch (e) {
      return "Error de conexión";
    }
  }
}