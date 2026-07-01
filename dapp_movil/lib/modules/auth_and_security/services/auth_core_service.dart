import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:web3dart/crypto.dart';
import '../../../config/api_config.dart';
import '../../../config/blockchain_config.dart'; // Archivo creado en el paso anterior

// class AuthCoreService {
//   // --- INFRAESTRUCTURA CORE ---
//   late Web3Client client;
//   final FlutterSecureStorage vault = const FlutterSecureStorage();
//   final LocalAuthentication localAuth = LocalAuthentication();
//   String currentTier = "FREE";
//   String role = "ROLE_USER";
  
//   // 🔥 NUEVO: IDENTIFICADOR DE TIPO DE CUENTA
//   String accountType = "PERSONAL"; 

//   // --- ESTADO DE SESIÓN (SÍMBOLO DE VERDAD) ---
//   EthPrivateKey? credentials;
//   EthereumAddress? myAddress;
//   String? _jwtToken;

//   // --- CONTRATOS CENTRALES ---
//   late DeployedContract testCoinContract;
//   late DeployedContract ecosystemContract;

//   // --- GETTERS ---
//   String get publicAddress => myAddress?.hexEip55 ?? "";
//   String? get jwtToken => _jwtToken;

//   Map<String, String> get authHeaders => {
//     "Content-Type": "application/json",
//     if (_jwtToken != null) "Authorization": "Bearer $_jwtToken"
//   };

//   // --- INICIALIZACIÓN ---
//   Future<void> init() async {
//     client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
//     await _loadCoreContracts();
//   }

//   Future<void> _loadCoreContracts() async {
//     final abiTestCoin = await rootBundle.loadString("assets/TestCoinABI.json");
//     final abiEcosystem = await rootBundle.loadString("assets/EcosystemABI.json");

//     testCoinContract = DeployedContract(
//       ContractAbi.fromJson(abiTestCoin, "TestCoin"),
//       EthereumAddress.fromHex(BlockchainConfig.testCoinAddress),
//     );

//     ecosystemContract = DeployedContract(
//       ContractAbi.fromJson(abiEcosystem, "Ecosystem"),
//       EthereumAddress.fromHex(BlockchainConfig.ecosystemAddress),
//     );
//   }

//   // --- GESTIÓN DE CREDENCIALES ---
//   Future<String> unlockWallet(String pin, {String? twoFactorCode}) async {
//     try {
//       final encryptedBase64 = await vault.read(key: 'encrypted_pk');
//       final ivBase64 = await vault.read(key: 'encryption_iv');

//       if (encryptedBase64 == null || ivBase64 == null) return "ERROR_NO_WALLET";

//       final bytes = utf8.encode("${pin}SaltSeguroTTC123");
//       final digest = sha256.convert(bytes);
//       final key = encrypt.Key.fromBase16(digest.toString().substring(0, 64));
//       final iv = encrypt.IV.fromBase64(ivBase64);

//       final encrypter = encrypt.Encrypter(encrypt.AES(key));
//       final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
//      final decryptedPrivateKey = encrypter.decrypt(encrypted, iv: iv);

//       // 🔥 FIX 1: Forzar los 64 caracteres (32 bytes)
//       credentials = EthPrivateKey.fromHex(decryptedPrivateKey.padLeft(64, '0'));
//       myAddress = credentials!.address;

//       return await requestJwtToken(pin, twoFactorCode: twoFactorCode);
//     } catch (e) {
//       return "ERROR_PIN";
//     }
//   }

//   Map<String, dynamic> _decodeJwt(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length != 3) return {};
//       final payload = base64Url.normalize(parts[1]);
//       final String decoded = utf8.decode(base64Url.decode(payload));
//       return jsonDecode(decoded);
//     } catch (e) {
//       return {};
//     }
//   }

//   Future<String> requestJwtToken(String pin, {String? twoFactorCode}) async {
//     try {
//       final trustedToken = await vault.read(key: 'trusted_device_token');
//       String? fcmToken = await FirebaseMessaging.instance.getToken();

//       final res = await http.post(
//         Uri.parse("${ApiConfig.baseUrl}/auth/login"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "walletAddress": myAddress!.hex.toLowerCase(),
//           "password": pin,
//           if (twoFactorCode != null) "twoFactorCode": twoFactorCode,
//           if (trustedToken != null) "trustedDeviceToken": trustedToken,
//           if (fcmToken != null) "fcmToken": fcmToken
//         })
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         _jwtToken = data['token'];

//         final jwtData = _decodeJwt(_jwtToken!);
//         role = jwtData['role'] ?? "ROLE_USER";
//         currentTier = jwtData['tier'] ?? "FREE";
        
//         // 🔥 NUEVO: LEEMOS EL TIPO DE CUENTA DIRECTAMENTE DEL JWT
//         accountType = jwtData['accountType'] ?? "PERSONAL"; 

//         print("🔐 [LOGIN JWT] Sesión iniciada. Rol: $role | Plan: $currentTier | Tipo: $accountType");

//         if (data.containsKey('trustedDeviceToken')) {
//           await vault.write(key: 'trusted_device_token', value: data['trustedDeviceToken']);
//         }
//         await vault.write(key: 'current_tier', value: currentTier);
//         return "SUCCESS";
//       } else if (res.statusCode == 428) {
//         return "2FA_REQUIRED";
//       } else if (res.statusCode == 403 || res.statusCode == 401) {
//         try {
//           final errData = jsonDecode(res.body);
//           return errData['error'] ?? "Acceso denegado.";
//         } catch (_) {
//           return "Cuenta bloqueada o en revisión.";
//         }
//       }
//       return "ERROR_CREDENTIALS";
//     } catch (e) {
//       return "ERROR_NETWORK";
//     }
//   }

//   Future<bool> refreshTokenAndTier() async {
//     try {
//       final res = await http.post(
//         Uri.parse("${ApiConfig.baseUrl}/auth/refresh-token"), 
//         headers: authHeaders,
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         _jwtToken = data['token']; 
//         currentTier = data['membershipTier'] ?? "FREE"; 
        
//         final jwtData = _decodeJwt(_jwtToken!);
//         accountType = jwtData['accountType'] ?? "PERSONAL"; // 🔥 Actualizamos por si cambió

//         await vault.write(key: 'current_tier', value: currentTier);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print("Error refrescando token: $e");
//       return false;
//     }
//   }

//   // ... (El resto de tus métodos de biometría, Bip39, llaves y modo pánico quedan exactamente igual) ...
//   Future<String> loginWithBiometrics() async {
//     try {
//       final isAuth = await authenticateUser();
//       if (!isAuth) return "ERROR_CANCELLED";

//       final savedPassword = await vault.read(key: 'secure_password');
//       if (savedPassword == null) return "ERROR_NO_PASSWORD";

//       return await unlockWallet(savedPassword);
//     } catch (e) {
//       return "ERROR_BIOMETRICS";
//     }
//   }

//   Future<bool> authenticateUser() async {
//     try {
//       final canCheck = await localAuth.canCheckBiometrics;
//       if (!canCheck) return true;

//       return await localAuth.authenticate(
//         localizedReason: 'Verifica tu identidad para acceder a tu bóveda',
//         options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
//       );
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> deleteWallet() async {
//     await vault.deleteAll();
//     credentials = null;
//     myAddress = null;
//     _jwtToken = null;
//   }

//   Future<void> createWalletFromMnemonic(String mnemonic) async {
//     String fullSeed = bip39.mnemonicToSeedHex(mnemonic);
//    String ethSeed = fullSeed.substring(0, 64);

//     // 🔥 FIX 2: Blindaje preventivo al crear
//     credentials = EthPrivateKey.fromHex(ethSeed.padLeft(64, '0'));
//     myAddress = credentials!.address;

//     await vault.write(key: 'private_key', value: bytesToHex(credentials!.privateKey).padLeft(64, '0'));
//     print("NUEVA CARTERA CREADA DESDE SEMILLA: ${myAddress!.hex}");
//   }

//   Future<void> savePin(String pin) async {
//     String? plainPrivateKey = await vault.read(key: 'private_key');
//     if (plainPrivateKey == null) throw Exception("No hay llave para encriptar");

//     var bytes = utf8.encode("${pin}SaltSeguroTTC123");
//     var digest = sha256.convert(bytes);
//     final key = encrypt.Key.fromBase16(digest.toString().substring(0, 64));
//     final iv = encrypt.IV.fromLength(16);

//     final encrypter = encrypt.Encrypter(encrypt.AES(key));
//     final encrypted = encrypter.encrypt(plainPrivateKey, iv: iv);

//     await vault.write(key: 'encrypted_pk', value: encrypted.base64);
//     await vault.write(key: 'encryption_iv', value: iv.base64);
//     await vault.delete(key: 'private_key'); 
//     await vault.write(key: 'secure_password', value: pin);

//     print("Billetera asegurada con constraseña exitosamente.");
//   }

//   Future<bool> hasSavedWallet() async {
//     String? encryptedKey = await vault.read(key: 'encrypted_pk');
//     return encryptedKey != null;
//   }

//   Future<String?> exportPrivateKey() async {
//     bool isAuth = await authenticateUser();
//     if (!isAuth) return null;

//     if (credentials != null) {
//       // 🔥 FIX 3: Exportar con todos los ceros
//       return bytesToHex(credentials!.privateKey).padLeft(64, '0');
//     }
//     return null;
//   }

//   Future<String?> signPlainTextMessage(String message) async {
//     bool isAuth = await authenticateUser();
//     if (!isAuth) return null;
//     if (credentials == null) return null;

//     try {
//       final messageBytes = Uint8List.fromList(utf8.encode(message));
//       final signature = await credentials!.signPersonalMessage(messageBytes);
//       return bytesToHex(signature, include0x: true);
//     } catch (e) {
//       return null;
//     }
//   }

//    void activatePanicMode(String decoyAddress, String privateKeyHex) {
//     myAddress = EthereumAddress.fromHex(decoyAddress);
//     // 🔥 FIX 4: Blindaje preventivo al activar señuelo
//     credentials = EthPrivateKey.fromHex(privateKeyHex.padLeft(64, '0')); 
//     print("🚨 [ALERTA] BÓVEDA SEÑUELO CARGADA LOCALMENTE: $decoyAddress");
//   }

//   // =========================================================================
//   // 🔥 MOTOR CRIPTOGRÁFICO DE META-TRANSACCIONES (GASLESS) 🔥
//   // =========================================================================
  
//   /// Genera una firma ECDSA válida simulando el comportamiento de `abi.encodePacked` de Solidity.
//   /// Protegido con biometría (Huella dactilar/Rostro).
//   Future<String?> generateDelegatedSignature(String actionType, {String? toAddress, BigInt? amountWei}) async {
//     // 1. Validamos la huella del usuario
//     bool isAuth = await authenticateUser();
//     if (!isAuth) return null;
    
//     // 2. Nos aseguramos de tener la llave privada desencriptada en memoria
//     if (credentials == null || myAddress == null) {
//       print("Error: Llave privada no cargada en memoria.");
//       return null;
//     }

//     try {
//       // 3. Obtenemos el Chain ID para evitar ataques de repetición cruzada
//       final chainIdBigInt = await client.getChainId();

//       // 4. Obtenemos el Nonce actual del usuario desde el Smart Contract Ecosystem
//       final nonceFunc = ecosystemContract.function('nonces');
//       final nonceResult = await client.call(
//         contract: ecosystemContract,
//         function: nonceFunc,
//         params: [myAddress],
//       );
//       final nonce = nonceResult.first as BigInt;

//       // 5. Empaquetamos los datos (Simulación estricta de abi.encodePacked)
//       final bb = BytesBuilder();

//       // Convertimos los parámetros principales a bytes
//       final userBytes = hexToBytes(myAddress!.hexEip55.replaceFirst('0x', '').padLeft(40, '0'));
//       final nonceBytes = hexToBytes(nonce.toRadixString(16).padLeft(64, '0'));
//       final chainIdBytes = hexToBytes(chainIdBigInt.toRadixString(16).padLeft(64, '0'));

//       if (actionType == "SEND") {
//         // Solidity: abi.encodePacked(from, to, amount, nonce, chainId)
//         final toBytes = hexToBytes(toAddress!.replaceFirst('0x', '').padLeft(40, '0'));
//         final amountBytes = hexToBytes(amountWei!.toRadixString(16).padLeft(64, '0'));
//         bb.add(userBytes);
//         bb.add(toBytes);
//         bb.add(amountBytes);
//         bb.add(nonceBytes);
//         bb.add(chainIdBytes);
//       } 
//       else if (actionType == "STAKE") {
//         // Solidity: abi.encodePacked(user, amount, nonce, chainId)
//         final amountBytes = hexToBytes(amountWei!.toRadixString(16).padLeft(64, '0'));
//         bb.add(userBytes);
//         bb.add(amountBytes);
//         bb.add(nonceBytes);
//         bb.add(chainIdBytes);
//       } 
//       else if (actionType == "UNSTAKE") {
//         // Solidity: abi.encodePacked(user, nonce, chainId)
//         bb.add(userBytes);
//         bb.add(nonceBytes);
//         bb.add(chainIdBytes);
//       } 
//       else if (actionType == "WITHDRAW") {
//         // Solidity: abi.encodePacked("withdraw", user, nonce, chainId)
//         final stringBytes = utf8.encode("withdraw");
//         bb.add(stringBytes);
//         bb.add(userBytes);
//         bb.add(nonceBytes);
//         bb.add(chainIdBytes);
//       } 
//       else if (actionType == "BUY") {
//         final stringBytes = utf8.encode("buy");
//         bb.add(stringBytes);
//         bb.add(userBytes);
//         bb.add(nonceBytes);
//       }

//       // 6. Aplicamos el hash Keccak256 a todos los bytes empaquetados
//       final packedBytes = bb.toBytes();
//       final messageHash = keccak256(packedBytes); 

//       // 7. Firmamos el hash final. 
//       // NOTA: signPersonalMessage automáticamente agrega el prefijo "\x19Ethereum Signed Message:\n32" 
//       final signature = await credentials!.signPersonalMessage(messageHash);
      
//       return bytesToHex(signature, include0x: true);
//     } catch (e) {
//       print("Error críptico generando firma delegada: $e");
//       return null;
//     }
//   }
// }

class AuthCoreService {
  late Web3Client client;
  final FlutterSecureStorage vault = const FlutterSecureStorage();
  final LocalAuthentication localAuth = LocalAuthentication();
  String currentTier = "FREE";
  String role = "ROLE_USER";
  String accountType = "PERSONAL";

  EthPrivateKey? credentials;
  EthereumAddress? myAddress;
  String? _jwtToken;

  late DeployedContract testCoinContract;
  late DeployedContract ecosystemContract;

  String get publicAddress => myAddress?.hexEip55 ?? "";
  String? get jwtToken => _jwtToken;

  Map<String, String> get authHeaders => {
    "Content-Type": "application/json",
    if (_jwtToken != null) "Authorization": "Bearer $_jwtToken"
  };

  Future<void> init() async {
    client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
    await _loadCoreContracts();
  }

  Future<void> _loadCoreContracts() async {
    final abiTestCoin = await rootBundle.loadString("assets/TestCoinABI.json");
    final abiEcosystem = await rootBundle.loadString("assets/EcosystemABI.json");
    testCoinContract = DeployedContract(ContractAbi.fromJson(abiTestCoin, "TestCoin"), EthereumAddress.fromHex(BlockchainConfig.testCoinAddress));
    ecosystemContract = DeployedContract(ContractAbi.fromJson(abiEcosystem, "Ecosystem"), EthereumAddress.fromHex(BlockchainConfig.ecosystemAddress));
  }

  Future<String> unlockWallet(String pin, {String? twoFactorCode}) async {
    try {
      final encryptedBase64 = await vault.read(key: 'encrypted_pk');
      final ivBase64 = await vault.read(key: 'encryption_iv');
      if (encryptedBase64 == null || ivBase64 == null) return "ERROR_NO_WALLET";

      final bytes = utf8.encode("${pin}SaltSeguroTTC123");
      final key = encrypt.Key.fromBase16(sha256.convert(bytes).toString().substring(0, 64));
      final iv = encrypt.IV.fromBase64(ivBase64);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decryptedPrivateKey = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedBase64), iv: iv);

      // Limpieza absoluta para cargar en RAM
     String cleanHex = decryptedPrivateKey.toLowerCase().replaceAll('0x', '').trim();
      if (cleanHex.length > 64) cleanHex = cleanHex.substring(cleanHex.length - 64);
      cleanHex = cleanHex.padLeft(64, '0');
      
      credentials = EthPrivateKey.fromHex(cleanHex);
      myAddress = credentials!.address;

      return await requestJwtToken(pin, twoFactorCode: twoFactorCode);
    } catch (e) {
      return "ERROR_PIN";
    }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(payload)));
    } catch (e) { return {}; }
  }

  Future<String> requestJwtToken(String pin, {String? twoFactorCode}) async {
    try {
      final trustedToken = await vault.read(key: 'trusted_device_token');
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "walletAddress": myAddress!.hex.toLowerCase(),
          "password": pin,
          if (twoFactorCode != null) "twoFactorCode": twoFactorCode,
          if (trustedToken != null) "trustedDeviceToken": trustedToken,
          if (fcmToken != null) "fcmToken": fcmToken
        })
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _jwtToken = data['token'];
        final jwtData = _decodeJwt(_jwtToken!);
        role = jwtData['role'] ?? "ROLE_USER";
        currentTier = jwtData['tier'] ?? "FREE";
        accountType = jwtData['accountType'] ?? "PERSONAL";

        if (data.containsKey('trustedDeviceToken')) await vault.write(key: 'trusted_device_token', value: data['trustedDeviceToken']);
        await vault.write(key: 'current_tier', value: currentTier);
        return "SUCCESS";
      } else if (res.statusCode == 428) {
        return "2FA_REQUIRED";
      } else if (res.statusCode == 403 || res.statusCode == 401) {
        try { return jsonDecode(res.body)['error'] ?? "Acceso denegado."; } catch (_) { return "Cuenta bloqueada o en revisión."; }
      }
      return "ERROR_CREDENTIALS";
    } catch (e) {
      return "ERROR_NETWORK";
    }
  }

  Future<bool> refreshTokenAndTier() async {
    try {
      final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/auth/refresh-token"), headers: authHeaders);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _jwtToken = data['token'];
        currentTier = data['membershipTier'] ?? "FREE";
        accountType = _decodeJwt(_jwtToken!)['accountType'] ?? "PERSONAL";
        await vault.write(key: 'current_tier', value: currentTier);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  Future<String> loginWithBiometrics() async {
    try {
      final isAuth = await authenticateUser();
      if (!isAuth) return "ERROR_CANCELLED";
      final savedPassword = await vault.read(key: 'secure_password');
      if (savedPassword == null) return "ERROR_NO_PASSWORD";
      return await unlockWallet(savedPassword);
    } catch (e) { return "ERROR_BIOMETRICS"; }
  }

  Future<bool> authenticateUser() async {
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) return true;
      return await localAuth.authenticate(
        localizedReason: 'Verifica tu identidad para acceder a tu bóveda',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } catch (e) { return false; }
  }

  Future<void> deleteWallet() async {
    await vault.deleteAll();
    credentials = null;
    myAddress = null;
    _jwtToken = null;

    final cacheService = LocalCacheService();
    await cacheService.clearAllCache();
    
  }

  Future<void> createWalletFromMnemonic(String mnemonic) async {
    String ethSeed = bip39.mnemonicToSeedHex(mnemonic).substring(0, 64);
    credentials = EthPrivateKey.fromHex(ethSeed.padLeft(64, '0'));
    myAddress = credentials!.address;
    await vault.write(key: 'private_key', value: bytesToHex(credentials!.privateKey).padLeft(64, '0'));
  }

  Future<void> savePin(String pin) async {
    String? plainPrivateKey = await vault.read(key: 'private_key');
    if (plainPrivateKey == null) throw Exception("No hay llave para encriptar");

    var bytes = utf8.encode("${pin}SaltSeguroTTC123");
    final key = encrypt.Key.fromBase16(sha256.convert(bytes).toString().substring(0, 64));
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypt.Encrypter(encrypt.AES(key)).encrypt(plainPrivateKey, iv: iv);

    await vault.write(key: 'encrypted_pk', value: encrypted.base64);
    await vault.write(key: 'encryption_iv', value: iv.base64);
    await vault.delete(key: 'private_key');
    await vault.write(key: 'secure_password', value: pin);
  }

  Future<bool> hasSavedWallet() async {
    return await vault.read(key: 'encrypted_pk') != null;
  }

  Future<String?> exportPrivateKey() async {
    bool isAuth = await authenticateUser();
    if (!isAuth || credentials == null) return null;
    return bytesToHex(credentials!.privateKey).padLeft(64, '0');
  }

  Future<String?> signPlainTextMessage(String message) async {
    bool isAuth = await authenticateUser();
    if (!isAuth || credentials == null) return null;
    try {
      final signature = await credentials!.signPersonalMessage(Uint8List.fromList(utf8.encode(message)));
      return bytesToHex(signature, include0x: true);
    } catch (e) { return null; }
  }

  void activatePanicMode(String decoyAddress, String privateKeyHex) {
    myAddress = EthereumAddress.fromHex(decoyAddress);
    credentials = EthPrivateKey.fromHex(privateKeyHex.replaceAll('0x', '').padLeft(64, '0'));
  }

  // =========================================================================
  // 🔥 MOTOR CRIPTOGRÁFICO A PRUEBA DE BALAS (EXTRACCIÓN SEGURA DESDE HARDWARE)
  // =========================================================================
  
 Future<String?> generateDelegatedSignature(String actionType, {String? toAddress, BigInt? amountWei}) async {
    bool isAuth = await authenticateUser();
    if (!isAuth) return null;

    try {
      debugPrint("🚀 [FIRMA 1] Iniciando extracción de bóveda...");
      final encryptedBase64 = await vault.read(key: 'encrypted_pk');
      final ivBase64 = await vault.read(key: 'encryption_iv');
      final savedPassword = await vault.read(key: 'secure_password');
      
      if (encryptedBase64 == null || ivBase64 == null || savedPassword == null) {
        debugPrint("❌ [FIRMA ERROR] Faltan datos en el Secure Storage.");
        return null;
      }

      final bytes = utf8.encode("${savedPassword}SaltSeguroTTC123");
      final key = encrypt.Key.fromBase16(sha256.convert(bytes).toString().substring(0, 64));
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decryptedPK = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedBase64), iv: encrypt.IV.fromBase64(ivBase64));

      debugPrint("🚀 [FIRMA 2] Llave desencriptada. Limpiando basura...");
      
      // 🔥 LA DESTRUCCIÓN DE BASURA (Expresión regular que deja SOLO hex válidos)
      String cleanHex = decryptedPK.toLowerCase().replaceAll('0x', '');
      cleanHex = cleanHex.replaceAll(RegExp(r'[^0-9a-f]'), ''); // Elimina TODO lo que no sea a-f o 0-9
      if (cleanHex.length > 64) cleanHex = cleanHex.substring(cleanHex.length - 64);
      cleanHex = cleanHex.padLeft(64, '0');

      debugPrint("🚀 [FIRMA 3] Llave purificada. Longitud final: ${cleanHex.length} caracteres.");

      EthPrivateKey bulletproofKey = EthPrivateKey.fromHex(cleanHex);
      
     debugPrint("🚀 [FIRMA 4] Llave Web3 creada con éxito. Obteniendo datos de red...");

      final chainIdBigInt = await client.getChainId();
      BigInt nonce;
      try {
        final nonceResult = await client.call(
            contract: ecosystemContract, 
            function: ecosystemContract.function('nonces'), 
            params: [bulletproofKey.address]
        );
        nonce = nonceResult.first as BigInt;
      } catch (e) {
        debugPrint("❌ [CRASH CONTRATO FANTASMA] Error leyendo el Smart Contract: $e");
        debugPrint("⚠️ POSIBLE CAUSA: Reiniciaste el nodo Avalanche y la dirección del Ecosystem cambió.");
        return null;
      }

      debugPrint("🚀 [FIRMA 5] Construyendo Hexadecimal Empaquetado...");

      String packedHex = "";
      if (actionType == "WITHDRAW") packedHex += bytesToHex(utf8.encode("withdraw"));
      if (actionType == "BUY") packedHex += bytesToHex(utf8.encode("buy"));

      packedHex += bulletproofKey.address.hexEip55.toLowerCase().replaceAll('0x', '').padLeft(40, '0');

      if (actionType == "SEND") {
        packedHex += toAddress!.toLowerCase().replaceAll('0x', '').padLeft(40, '0');
        packedHex += amountWei!.toRadixString(16).padLeft(64, '0');
      } else if (actionType == "STAKE") {
        packedHex += amountWei!.toRadixString(16).padLeft(64, '0');
      }

      packedHex += nonce.toRadixString(16).padLeft(64, '0');
      if (actionType != "BUY") packedHex += chainIdBigInt.toRadixString(16).padLeft(64, '0');

      debugPrint("🚀 [FIRMA 6] Aplicando Keccak256 y firmando...");
      final messageHash = keccak256(hexToBytes(packedHex));
      final signature = await bulletproofKey.signPersonalMessage(messageHash);
      
      debugPrint("✅ [FIRMA ÉXITO] Todo perfecto.");
      return bytesToHex(signature, include0x: true);

    } catch (e, stack) {
      debugPrint("❌ [CRASH FATAL RASTREADO] Error en paso específico: $e");
      debugPrint("$stack");
      return null;
    }
  }
  // 🔥 NUEVO: Método para enviar actualizaciones del Token FCM al Backend
  Future<void> syncFcmToken(String newFcmToken) async {
    // Si el usuario no ha iniciado sesión, no hacemos nada
    if (myAddress == null || _jwtToken == null) return; 

    try {
      await http.put(
        Uri.parse(ApiConfig.updateFcmToken), // 🔥 REGLA RESPETADA: Usando ApiConfig
        headers: authHeaders,
        body: jsonEncode({
          "walletAddress": myAddress!.hex.toLowerCase(),
          "fcmToken": newFcmToken
        })
      );
      debugPrint("📱 [FCM] Nuevo Token sincronizado con el servidor exitosamente");
    } catch (e) {
      debugPrint("🚨 [FCM ERROR] No se pudo sincronizar el nuevo token: $e");
    }
  }
}