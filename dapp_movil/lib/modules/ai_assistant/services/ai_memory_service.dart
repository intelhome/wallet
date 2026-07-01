import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class AiMemoryService {
  final AuthCoreService authCore;

  AiMemoryService(this.authCore);

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
  };

  // Future<List<dynamic>> getPreferences() async {
  //   if (authCore.publicAddress.isEmpty) return [];
  //   try {
  //     final url = Uri.parse(ApiConfig.getAiMemory.replaceAll("{address}", authCore.publicAddress.toLowerCase()));
  //     final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));

  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body);
  //       return data['preferences'] ?? [];
  //     }
  //   } catch (e) {
  //     print("❌ [AiMemoryService] Error getPreferences: $e");
  //   }
  //   return [];
  // }

  Future<List<dynamic>> getPreferences() async {
    if (authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      final url = Uri.parse(ApiConfig.getAiMemory.replaceAll("{address}", wallet));
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = data['preferences'] ?? [];
        await cacheService.saveAiPreferences(wallet, prefs);
        return prefs;
      }
    } catch (e) { print("❌ Error getPreferences: $e"); }
    
    return cacheService.getCachedAiPreferences(wallet); 
  }

  Future<bool> togglePreference(String id, bool isActive) async {
    if (authCore.publicAddress.isEmpty) return false;
    try {
      String urlStr = ApiConfig.toggleAiMemory
          .replaceAll("{address}", authCore.publicAddress.toLowerCase())
          .replaceAll("{id}", id);
          
      final res = await http.put(
        Uri.parse(urlStr),
        headers: _headers,
        body: jsonEncode({"isActive": isActive}),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (e) {
      print("❌ [AiMemoryService] Error togglePreference: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendMessageWithMemory(String message, String systemPrompt) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.aiChat), // Asegúrate de que esto apunta a /ai/chat-memory en api_config.dart
        headers: _headers,
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase(),
          "message": message,
          "systemPrompt": systemPrompt 
        }),
      ).timeout(const Duration(seconds: 30));

      print("📥 [SPRING -> FLUTTER] Status Code: ${res.statusCode}");
      print("📥 [SPRING -> FLUTTER] Response Body: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("❌ [AiMemoryService] Error sendMessageWithMemory: $e");
    }
    return null;
  }

  Future<bool> extractPreferencesFromChat(List<String> plainMessages) async {
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/ai/extract"); 
      
      final res = await http.post(
        url,
        headers: _headers, // Usa el _headers que ya tienes configurado
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase(),
          "messages": plainMessages
        })
      );
      
      return res.statusCode == 200;
    } catch (e) {
      print("Error en extracción federada: $e");
      return false;
    }
  }
}