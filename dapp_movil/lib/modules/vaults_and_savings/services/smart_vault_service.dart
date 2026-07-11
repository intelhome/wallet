import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class SmartVaultService {
  final AuthCoreService authCore;

  SmartVaultService(this.authCore);

  // =========================================================================
  // HELPER INTERNO: PETICIONES POST Y MANEJO DE ERRORES
  // =========================================================================

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

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return "Exito";
      }
      if (response.statusCode == 403 || response.statusCode == 401) {
        return "Error: Sesión no autorizada o Token inválido (403).";
      }
      return "Error: ${_extractErrorMessage(response.body, response.statusCode)}";

    } on TimeoutException {
      return "Error: La red está congestionada. Operación en proceso.";
    } on SocketException {
      return "Error: Sin conexión al servidor central.";
    } catch (e) {
      return "Error crítico: $e";
    }
  }

  BigInt _convertToWei(double amount) {
    List<String> parts = amount.toString().split('.');
    BigInt enteros = BigInt.parse(parts[0]) * BigInt.from(10).pow(18);
    BigInt decimales = parts.length > 1 ? BigInt.parse(parts[1].padRight(18, '0').substring(0, 18)) : BigInt.zero;
    return enteros + decimales;
  }

  // =========================================================================
  // 1. SISTEMA DE STAKING (APARTADO DE INVERSIONES)
  // =========================================================================

  Future<String> getStakedBalance() async {
    if (authCore.myAddress == null) {
      print("🛑 [FRONT-STAKE] Error: _myAddress es null.");
      return "0.00";
    }
    try {
      print("🔍 [FRONT-STAKE] Consultando Stake en crudo para la wallet: ${authCore.publicAddress}");
      
      final function = authCore.ecosystemContract.function("stakedBalances");
      final result = await authCore.client.call(
        contract: authCore.ecosystemContract, 
        function: function, 
        params: [authCore.myAddress!]
      );
      
      if (result.isEmpty) return "0.00";
      return ((result[0] as BigInt) / BigInt.from(10).pow(18)).toStringAsFixed(2);
    } catch (e) {
      print("❌ [FRONT-STAKE] Error leyendo la blockchain: $e");
      return "0.00";
    }
  }

  Future<String> getAnyStakedBalance(String addressHex) async {
    if (addressHex.isEmpty) return "0.00";
    try {
      final EthereumAddress targetAddress = EthereumAddress.fromHex(addressHex);
      final function = authCore.ecosystemContract.function("stakedBalances");
      
      final result = await authCore.client.call(
        contract: authCore.ecosystemContract, 
        function: function, 
        params: [targetAddress]
      );
      return ((result[0] as BigInt) / BigInt.from(10).pow(18)).toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  Future<String> estimateStakeGas(double amountTTC) async {
    try {
      BigInt amountInWei = _convertToWei(amountTTC);
      BigInt gasLimit = await authCore.client.estimateGas(
        sender: authCore.myAddress,
        to: authCore.testCoinContract.address,
        data: Transaction.callContract(
          contract: authCore.testCoinContract, 
          function: authCore.testCoinContract.function("approve"), 
          parameters: [authCore.ecosystemContract.address, amountInWei]
        ).data,
      );
      EtherAmount gasPrice = await authCore.client.getGasPrice();
      // Incrementamos un 25% extra como margen de seguridad para el Staking
      return (((gasLimit * gasPrice.getInWei) * BigInt.from(25) ~/ BigInt.from(10)).toDouble() / 1e18).toStringAsFixed(6);
    } catch (e) {
      return "ERROR_GAS: Falló al calcular el gas";
    }
  }

  // Future<String> stakeTokensL2(double amountTTC) async {
  //   return await _postRequest(ApiConfig.stakeTokens, {
  //     "userAddress": authCore.publicAddress.toLowerCase(),
  //     "amountTTC": amountTTC.toString(),
  //   });
  // }

  Future<String> stakeTokensL2(double amountTTC, String signature) async {
    return await _postRequest(ApiConfig.stakeTokens, {
      "userAddress": authCore.publicAddress.toLowerCase(),
      "amountTTC": amountTTC.toString(),
      "signature": signature, // 🔥 NUEVO: Enviamos la firma al backend
    });
  }

  // Future<String> unstakeTokensL2() async {
  //   return await _postRequest(ApiConfig.unstakeTokens, {
  //     "userAddress": authCore.publicAddress.toLowerCase()
  //   });
  // }

  // Future<String> withdrawTokensL2() async {
  //   return await _postRequest(ApiConfig.withdrawTokens, {
  //     "userAddress": authCore.publicAddress.toLowerCase()
  //   });
  // }

  Future<String> unstakeTokensL2(String signature) async {
    return await _postRequest(ApiConfig.unstakeTokens, {
      "userAddress": authCore.publicAddress.toLowerCase(),
      "signature": signature, // 🔥 NUEVO: Enviamos la firma al backend
    });
  }

  Future<String> withdrawTokensL2(String signature) async {
    return await _postRequest(ApiConfig.withdrawTokens, {
      "userAddress": authCore.publicAddress.toLowerCase(),
      "signature": signature, // 🔥 NUEVO: Enviamos la firma al backend
    });
  }

  Future<Map<String, dynamic>> getPendingWithdrawal() async {
    if (authCore.publicAddress.isEmpty) return {'amount': 0, 'unlockTime': 0};
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = "${ApiConfig.getPendingWithdrawal.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?t=$timestamp";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...authCore.authHeaders,
          "Cache-Control": "no-cache", 
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'amount': 0, 'unlockTime': 0};
    } catch (e) {
      return {'amount': 0, 'unlockTime': 0};
    }
  }

  Future<Map<String, dynamic>> getAnyPendingWithdrawal(String address) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = "${ApiConfig.getPendingWithdrawal.replaceAll("{address}", address)}?t=$timestamp";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...authCore.authHeaders,
          "Cache-Control": "no-cache",
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'amount': 0, 'unlockTime': 0};
    } catch (e) {
      return {'amount': 0, 'unlockTime': 0};
    }
  }

  // =========================================================================
  // 2. BOLSILLOS INTELIGENTES (SMART VAULTS)
  // =========================================================================

  Future<String> createFlexibleVault({
    required String goalName,
    required double initialAmount,
    required double targetAmount,
    required double autoSaveAmount,
    required String autoSaveFrequency, 
  }) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";
    
    return await _postRequest(ApiConfig.createVault, {
      "walletAddress": authCore.publicAddress.toLowerCase(),
      "vaultType": "FLEXIBLE",
      "goalName": goalName,
      "initialAmount": initialAmount,
      "targetAmount": targetAmount,
      "autoSaveAmount": autoSaveAmount,
      "autoSaveFrequency": autoSaveFrequency,
    });
  }

  Future<String> createRestrictiveVault({
    required String goalName,
    required double initialAmount,
    required double targetAmount,
    required int lockDurationInSeconds, 
    required double autoSaveAmount,
    required String autoSaveFrequency,
  }) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";
    
    return await _postRequest(ApiConfig.createVault, {
      "walletAddress": authCore.publicAddress.toLowerCase(),
      "vaultType": "RESTRICTIVE",
      "goalName": goalName,
      "initialAmount": initialAmount,
      "targetAmount": targetAmount,
      "autoSaveAmount": autoSaveAmount,
      "autoSaveFrequency": autoSaveFrequency,
      "lockDurationInSeconds": lockDurationInSeconds,
    });
  }

  Future<String> depositToFlexibleVault(String vaultId, double amount) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

    try {
      String endpoint = ApiConfig.depositVault.replaceAll("{vaultId}", vaultId);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase(),
          "amount": amount
        })
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return "Exito"; 
      }
      return "Error: ${_extractErrorMessage(response.body, response.statusCode)}";
    } on TimeoutException {
      return "Error: La red está congestionada. Operación en proceso.";
    } on SocketException {
      return "Error: Sin conexión al servidor central.";
    } catch (e) {
      return "Error crítico: $e";
    }
  }

  // Future<String> withdrawVault(String vaultId) async {
  //   if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

  //   try {
  //     String endpoint = "${ApiConfig.withdrawVault.replaceAll("{vaultId}", vaultId)}?walletAddress=${authCore.publicAddress.toLowerCase()}";

  //     final response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: authCore.authHeaders,
  //     ).timeout(const Duration(seconds: 20));

  //     if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
  //       return "Exito";
  //     }
  //     return "Error: ${_extractErrorMessage(response.body, response.statusCode)}";
  //   } on TimeoutException {
  //     return "Error: La red está congestionada. Operación en proceso.";
  //   } on SocketException {
  //     return "Error: Sin conexión al servidor central.";
  //   } catch (e) {
  //     return "Error crítico: $e";
  //   }
  // }

  Future<String> withdrawVault(String vaultId) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

    try {
      String endpoint = ApiConfig.withdrawVault.replaceAll("{vaultId}", vaultId);

      final response = await http.post(
        Uri.parse(endpoint),
        headers: authCore.authHeaders,
        // 🔥 FIX: Enviamos la dirección por el Body en formato JSON
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase()
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        return "Exito";
      }
      return "Error: ${_extractErrorMessage(response.body, response.statusCode)}";
    } on TimeoutException {
      return "Error: La red está congestionada. Operación en proceso.";
    } on SocketException {
      return "Error: Sin conexión al servidor central.";
    } catch (e) {
      return "Error crítico: $e";
    }
  }

  // Future<List<dynamic>> getUserVaults() async {
  //   if (authCore.publicAddress.isEmpty) return [];
  //   try {
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     String endpoint = "${ApiConfig.getUserVaults.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?t=$timestamp";
      
  //     final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders)
  //         .timeout(const Duration(seconds: 10));
          
  //     if (res.statusCode == 200) {
  //       return jsonDecode(res.body);
  //     }
  //     return [];
  //   } catch (e) {
  //     print("Error obteniendo bóvedas: $e");
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getUserVaults() async {
    if (authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String endpoint = "${ApiConfig.getUserVaults.replaceAll("{address}", wallet)}?t=$timestamp";
      
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
          
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveUserVaults(wallet, data);
        return data;
      }
    } catch (e) { print("Error get vaults: $e"); }
    return cacheService.getCachedUserVaults(wallet);
  }
}