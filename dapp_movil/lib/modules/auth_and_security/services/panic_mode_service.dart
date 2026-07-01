import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/api_config.dart';
import 'auth_core_service.dart';

class PanicModeService {
  final AuthCoreService authCore;
  final FlutterSecureStorage _vault = const FlutterSecureStorage();

  PanicModeService(this.authCore);

  Future<String> setupDecoyWallet(String panicPin, double initialAmount) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.setupDecoy), headers: authCore.authHeaders,
        body: jsonEncode({"mainWalletAddress": authCore.publicAddress.toLowerCase(), "panicPin": panicPin, "initialAmount": initialAmount})
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _vault.write(key: 'panic_pin', value: panicPin);
        await _vault.write(key: 'decoy_address', value: data['decoyAddress']);
        await _vault.write(key: 'decoy_private_key', value: data['privateKeyHex']);
        return "Exito";
      }
      return "Error del servidor";
    } catch (e) { return "Error de red"; }
  }

  Future<String> deleteDecoyWallet() async {
    try {
      final res = await http.delete(Uri.parse(ApiConfig.deleteDecoy.replaceAll("{address}", authCore.publicAddress.toLowerCase())), headers: authCore.authHeaders);
      if (res.statusCode == 200) {
        await _vault.delete(key: 'panic_pin');
        await _vault.delete(key: 'decoy_address');
        await _vault.delete(key: 'decoy_private_key');
        return "Exito";
      }
      return "Error";
    } catch (e) { return "Error de red"; }
  }

  Future<Map<String, dynamic>> syncDecoyState() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.getDecoy.replaceAll("{address}", authCore.publicAddress.toLowerCase())), headers: authCore.authHeaders);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['exists'] == true) {
          await _vault.write(key: 'decoy_address', value: data['decoyAddress']);
          await _vault.write(key: 'panic_pin', value: data['panicPin']);
        } else {
          await _vault.delete(key: 'decoy_address');
          await _vault.delete(key: 'panic_pin');
          await _vault.delete(key: 'decoy_private_key');
        }
        return data;
      }
      return {"exists": false};
    } catch (e) { return {"exists": false}; }
  }
}