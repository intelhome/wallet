import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class TransactionService {
  final AuthCoreService authCore;
  StreamSubscription? _transferSubscription;

  TransactionService(this.authCore);
  final LocalCacheService _cacheService = LocalCacheService();

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

  // =========================================================================
  // 1. CONSULTA DE SALDOS
  // =========================================================================

  Future<String> getBalance() async {
    if (authCore.publicAddress.isEmpty) return "0.00";
    try {
      // Consultamos al Backend (Shadow Ledger) para reconciliación exacta
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/transactions/balance/${authCore.publicAddress.toLowerCase()}"),
        headers: authCore.authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.parse(data['effectiveBalance'].toString()).toStringAsFixed(2);
      }
      return "0.00";
    } catch (e) {
      print("Error obteniendo saldo reconciliado: $e");
      return "0.00"; 
    }
  }

  Future<String> getEthBalance() async {
    if (authCore.myAddress == null) return "0.0000";
    try {
      EtherAmount balance = await authCore.client.getBalance(authCore.myAddress!);
      return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
    } catch (e) {
      return "0.0000";
    }
  }

  Future<String> getEthPriceInUsd() async {
    try {
      final function = authCore.ecosystemContract.function("getLatestEthPrice");
      final result = await authCore.client.call(
        contract: authCore.ecosystemContract, 
        function: function, 
        params: []
      );
      return ((result[0] as BigInt).toDouble() / 100000000).toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  // =========================================================================
  // 2. CÁLCULOS Y ESTIMACIONES DE GAS
  // =========================================================================

  BigInt _convertToWei(double amount) {
    List<String> parts = amount.toString().split('.');
    BigInt enteros = BigInt.parse(parts[0]) * BigInt.from(10).pow(18);
    BigInt decimales = parts.length > 1 ? BigInt.parse(parts[1].padRight(18, '0').substring(0, 18)) : BigInt.zero;
    return enteros + decimales;
  }

  Future<String> estimateBuyGas(double ethAmount) async {
    if (authCore.myAddress == null) return "ERROR_GAS";
    try {
      BigInt amountInWei = _convertToWei(ethAmount);
      BigInt gasLimit = await authCore.client.estimateGas(
        sender: authCore.myAddress,
        to: authCore.ecosystemContract.address,
        data: Transaction.callContract(
          contract: authCore.ecosystemContract, 
          function: authCore.ecosystemContract.function("buyTokensFor"), 
          parameters: [authCore.myAddress]
        ).data,
        value: EtherAmount.inWei(amountInWei),
      );
      EtherAmount gasPrice = await authCore.client.getGasPrice();
      return ((gasLimit * gasPrice.getInWei).toDouble() / 1e18).toStringAsFixed(6);
    } catch (e) {
      return "ERROR_GAS: Saldo insuficiente o bloqueado";
    }
  }

  Future<String> estimateSendGas(String recipient, double amountTTC) async {
    if (authCore.myAddress == null) return "ERROR_GAS";
    try {
      BigInt amountInWei = _convertToWei(amountTTC);
      BigInt gasLimit = await authCore.client.estimateGas(
        sender: authCore.myAddress,
        to: authCore.testCoinContract.address,
        data: Transaction.callContract(
          contract: authCore.testCoinContract, 
          function: authCore.testCoinContract.function("transfer"), 
          parameters: [EthereumAddress.fromHex(recipient), amountInWei]
        ).data,
      );
      EtherAmount gasPrice = await authCore.client.getGasPrice();
      return ((gasLimit * gasPrice.getInWei).toDouble() / 1e18).toStringAsFixed(6);
    } catch (e) {
      return "ERROR_GAS: Dirección inválida o sin saldo";
    }
  }

  // =========================================================================
  // 3. TRANSACCIONES L2 (TESTCOIN / TTC)
  // =========================================================================

  // Future<String> buyTokensL2(double ethAmount) async {
  //   return await _postRequest(ApiConfig.buyTokens, {
  //     "userAddress": authCore.publicAddress.toLowerCase(),
  //     "amountEth": ethAmount.toString(),
  //     "txType": "BUY",
  //   });
  // }

  Future<String> buyTokensL2(double ethAmount, String signature) async {
    return await _postRequest(ApiConfig.buyTokens, {
      "userAddress": authCore.publicAddress.toLowerCase(),
      "amountEth": ethAmount.toString(),
      "txType": "BUY",
      "signature": signature, // 🔥 NUEVO
    });
  }

  // Future<String> sendTokensL2(String toAddress, double amountTTC) async {
  //   return await _postRequest(ApiConfig.sendTokens, {
  //     "fromAddress": authCore.publicAddress.toLowerCase(),
  //     "toAddress": toAddress,
  //     "amountTTC": amountTTC.toString(),
  //   });
  // }

  Future<String> sendTokensL2(String toAddress, double amountTTC, String signature) async {
    return await _postRequest(ApiConfig.sendTokens, {
      "fromAddress": authCore.publicAddress.toLowerCase(),
      "toAddress": toAddress,
      "amountTTC": amountTTC.toString(),
      "signature": signature, // 🔥 NUEVO
    });
  }

  /// Enviar fondos instantáneamente usando un Alias off-chain
  Future<String> sendOffChainAlias(String alias, double amountTTC) async {
    return await _postRequest(ApiConfig.sendOfChain, { 
      "senderAddress": authCore.publicAddress.toLowerCase(),
      "receiverAlias": alias,
      "amountTTC": amountTTC.toString(),
    });
  }

  // =========================================================================
  // 4. PASARELA FIAT (ON-RAMP / OFF-RAMP)
  // =========================================================================

  Future<String> buyTokensFiat(String orderId, double amountUSD) async {
    return await _postRequest(ApiConfig.buyFiat, {
      "userAddress": authCore.publicAddress.toLowerCase(),
      "orderId": orderId,
      "amountUSD": amountUSD.toString(),
    });
  }

  Future<String> sendTokensFiat(String toAddress, String orderId, double amountUSD) async {
    return await _postRequest(ApiConfig.sendFiat, {
      "senderAddress": authCore.publicAddress.toLowerCase(),
      "recipientAddress": toAddress,
      "orderId": orderId,
      "amountUSD": amountUSD.toString(),
    });
  }

  Future<String> withdrawToBank(double amountTTC, String bankName, String accountNumber) async {
    try {
      String saldoStr = await getBalance();
      double saldoActual = double.tryParse(saldoStr) ?? 0.0;
      
      if (amountTTC > saldoActual) {
        return "Error: Fondos insuficientes.";
      }

      final res = await _postRequest(ApiConfig.withdrawTokens, {
        "userAddress": authCore.publicAddress.toLowerCase(),
        "amount": amountTTC.toString(),
        "bank": bankName,
        "account": accountNumber
      });

      // Simulamos el tiempo de procesamiento de la red interbancaria (SPI)
      await Future.delayed(const Duration(seconds: 3));

      return res.startsWith("Error") ? res : "SUCCESS";
    } catch (e) {
      return "Error crítico de conexión bancaria.";
    }
  }

  // =========================================================================
  // 5. HISTORIAL Y EXPLORADOR DE BLOQUES
  // =========================================================================

  // Future<List<dynamic>> getTransactionHistory() async {
  //   if (authCore.publicAddress.isEmpty) return [];
  //   try {
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final url = "${ApiConfig.getHistory.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?t=$timestamp";
      
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         ...authCore.authHeaders,
  //         "Cache-Control": "no-cache",
  //         "Pragma": "no-cache"
  //       }
  //     ).timeout(const Duration(seconds: 10));
      
  //     if (response.statusCode == 200) return jsonDecode(response.body);
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getTransactionHistory({Function(List<dynamic>)? onNetworkSync}) async {
    if (authCore.publicAddress.isEmpty) return [];

    // 1. Leemos la memoria RAM (Hive) al instante
    List<dynamic> cachedData = _cacheService.getCachedTransactions();

    // 2. Disparamos la petición a AWS en segundo plano (sin detener el flujo)
    _fetchHistoryFromNetwork().then((freshData) {
      // Si AWS nos devolvió datos y la pantalla nos pasó un callback, le avisamos
      if (freshData.isNotEmpty && onNetworkSync != null) {
        onNetworkSync(freshData); 
      }
    }).catchError((e) {
      print("Error sincronizando historial en fondo: $e");
    });

    // 3. Si la caché está totalmente vacía (primera vez que entra), 
    // esperamos a AWS para no mostrarle una pantalla en blanco al usuario.
    if (cachedData.isEmpty) {
      return await _fetchHistoryFromNetwork();
    }

    // 4. Devolvemos la caché inmediatamente
    return cachedData;
  }

  Future<List<dynamic>> _fetchHistoryFromNetwork() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = "${ApiConfig.getHistory.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?t=$timestamp";
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...authCore.authHeaders,
          "Cache-Control": "no-cache",
          "Pragma": "no-cache"
        }
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final freshData = jsonDecode(response.body);
        // 🔥 Guardamos los datos nuevos en la bóveda de Hive automáticamente
        await _cacheService.saveTransactions(freshData);
        return freshData;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTransactionByHash(String hash) async {
    try {
      String endpoint = ApiConfig.getTransactionByHash.replaceAll("{hash}", hash.trim());
      
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null; 
    } catch (e) {
      print("Error buscando hash: $e");
      return null;
    }
  }

  // =========================================================================
  // 6. LISTENER DE EVENTOS WEB3 (TIEMPO REAL)
  // =========================================================================

 Timer? _pollingTimer;
  int _lastBlockChecked = 0;

  void listenToTransfers(Function(bool isReceiver, String fromAddress) onUpdate) {
    _startListening(onUpdate);
  }

  Future<void> _startListening(Function(bool isReceiver, String fromAddress) onUpdate) async {
    if (authCore.myAddress == null) return; 

    _pollingTimer?.cancel();

    try {
      // Obtenemos el número del bloque actual para no leer el historial desde 0
      _lastBlockChecked = await authCore.client.getBlockNumber();
    } catch (e) {
      print("No se pudo obtener el bloque inicial: $e");
      // Si hay un fallo de internet al abrir la app, reintenta en 5 segundos
      Future.delayed(const Duration(seconds: 5), () => _startListening(onUpdate));
      return;
    }

    final transferEvent = authCore.testCoinContract.event('Transfer');

    // Hacemos polling cada 5 segundos. ¡Es 100% inmune al error -32000!
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        int currentBlock = await authCore.client.getBlockNumber();
        
        if (currentBlock <= _lastBlockChecked) return; // No hay bloques nuevos, ignoramos

        final filter = FilterOptions.events(
          contract: authCore.testCoinContract,
          event: transferEvent,
          fromBlock: BlockNum.exact(_lastBlockChecked + 1),
          toBlock: BlockNum.exact(currentBlock),
        );

        // Usamos getLogs en lugar de events (esto no usa filtros en memoria del nodo)
        final logs = await authCore.client.getLogs(filter);

        for (var event in logs) {
          if (event.topics == null || event.topics!.length < 3) continue;

          final topic1 = event.topics![1];
          final topic2 = event.topics![2];

          if (topic1 == null || topic2 == null) continue;

          bool iAmReceiver = false;
          String fromAddress = "";
          String myAddressClean = authCore.myAddress!.hex.toLowerCase().replaceFirst('0x', '');
          
          if (topic2.toLowerCase().endsWith(myAddressClean)) {
            iAmReceiver = true;
          }

          if (topic1.length >= 40) {
            fromAddress = "0x${topic1.substring(topic1.length - 40)}";
          }
          
          onUpdate(iAmReceiver, fromAddress.toLowerCase());
        }

        _lastBlockChecked = currentBlock; // Avanzamos nuestro contador

      } catch (e) {
        // Cualquier error de red aquí es tragado silenciosamente, no crashea la App
        print("Error silencioso en polling Web3: $e");
      }
    });
  }

  void stopListening() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}