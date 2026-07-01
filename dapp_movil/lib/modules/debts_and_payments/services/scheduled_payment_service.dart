import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class ScheduledPaymentService {
  final AuthCoreService authCore;

  ScheduledPaymentService(this.authCore);

  Future<bool> saveScheduledPayment(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/payments/scheduled"),
      headers: authCore.authHeaders,
      body: jsonEncode(data)
    );
    return res.statusCode == 200;
  }

  // Future<List<dynamic>> getMyScheduledPayments() async {
  //   final res = await http.get(
  //     Uri.parse(ApiConfig.getScheduledPayments.replaceAll("{address}", authCore.publicAddress.toLowerCase())),
  //     headers: authCore.authHeaders
  //   );
  //   return res.statusCode == 200 ? jsonDecode(res.body) : [];
  // }

  Future<List<dynamic>> getMyScheduledPayments() async {
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();
    try {
      final res = await http.get(Uri.parse(ApiConfig.getScheduledPayments.replaceAll("{address}", wallet)), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveScheduledPayments(wallet, data);
        return data;
      }
    } catch (e) { print("Error get scheduled: $e"); }
    return cacheService.getCachedScheduledPayments(wallet);
  }

  Future<bool> cancelScheduledPayment(String id) async {
    final res = await http.delete(
      Uri.parse(ApiConfig.cancelScheduledPayment.replaceAll("{id}", id)),
      headers: authCore.authHeaders
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getMerchantSubscriptions() async {
    try {
      final url = ApiConfig.getMerchantSubscriptions.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMerchantReminder(String clientAddress) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.sendMerchantReminder),
        headers: authCore.authHeaders,
        body: jsonEncode({"clientAddress": clientAddress.toLowerCase()})
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}