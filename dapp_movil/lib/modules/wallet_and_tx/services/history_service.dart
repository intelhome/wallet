import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../../core/services/local_cache_service.dart';

class HistoryService {
  final AuthCoreService authCore;
  final LocalCacheService _cacheService = LocalCacheService();

  HistoryService(this.authCore);

  /// Obtiene una página específica de transacciones
  Future<Map<String, dynamic>> getTransactionHistoryPaged({int page = 0, int size = 20}) async {
    if (authCore.publicAddress.isEmpty) return {"content": []};

    try {
      final url = Uri.parse(
        "${ApiConfig.getHistoryPaged.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?page=$page&size=$size"
      );

      final response = await http.get(
        url,
        headers: {
          ...authCore.authHeaders,
          "Cache-Control": "no-cache",
        }
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Si estamos pidiendo la primera página, guardamos en caché
        if (page == 0 && data['content'] != null) {
          await _cacheService.saveTransactions(data['content']);
        }
        
        return data; // Devuelve el objeto paginado completo de Spring Boot
      }
      return {"content": []};
    } catch (e) {
      // Si falla la red en la primera página, devuelve el caché
      if (page == 0) {
        return {"content": _cacheService.getCachedTransactions()};
      }
      return {"content": []};
    }
  }
}