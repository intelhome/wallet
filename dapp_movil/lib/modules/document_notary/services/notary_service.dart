import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class NotaryService {
  final AuthCoreService authCore;

  NotaryService(this.authCore);

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

  /// Crea un registro notarial delegado (Gasless para el usuario)
  Future<String> createDocumentDelegated(String hash, String title, String fileUrl, List<String> signers) async {
    try {
      print("[FRONT-NOTARY] Subiendo documento '$title' con hash $hash...");
      final res = await http.post(
        Uri.parse(ApiConfig.createDocument),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "docHash": hash,
          "title": title,
          "fileUrl": fileUrl,
          "creatorAddress": authCore.publicAddress.toLowerCase(),
          "requiredSigners": signers
        })
      );

      if (res.statusCode == 200) {
        print("[FRONT-NOTARY] Documento creado on-chain y off-chain con éxito.");
        return "Exito";
      }
      
      String error = _extractErrorMessage(res.body, res.statusCode);
      print("[FRONT-NOTARY] Error al crear documento: $error");
      return "Error: $error";
    } catch (e) {
      print("[FRONT-NOTARY] Excepción de red al crear documento: $e");
      return "Error de red al crear documento";
    }
  }

  Future<Map<String, dynamic>> getDocumentHistoryPaged({int page = 0, int size = 20}) async {
    if (authCore.publicAddress.isEmpty) return {"content": []};
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      print("[FRONT-NOTARY] Consultando historial paginado (Pag: $page) para $wallet...");
      String endpoint = "${ApiConfig.getDocumentHistoryPaged.replaceAll("{address}", wallet)}?page=$page&size=$size";
      
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("[FRONT-NOTARY] Historial recibido: ${data['content']?.length ?? 0} elementos");
        
        // Guardamos en caché SOLO la primera página para arranques rápidos en offline
        if (page == 0 && data['content'] != null) {
          await cacheService.saveDocumentHistory(wallet, data['content']);
        }
        return data;
      }
    } catch (e) { 
      print("[FRONT-NOTARY] Error red al obtener historial paginado: $e"); 
    }
    
    // Si falla y es la primera página, enviamos el caché
    if (page == 0) {
      return {"content": cacheService.getCachedDocumentHistory(wallet), "last": true};
    }
    return {"content": [], "last": true};
  }

  Future<List<dynamic>> getPendingDocuments() async {
    if (authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      print("[FRONT-NOTARY] Consultando documentos pendientes para $wallet...");
      String endpoint = ApiConfig.getPendingDocuments.replaceAll("{address}", wallet);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("[FRONT-NOTARY] Documentos pendientes obtenidos: ${data.length}");
        await cacheService.savePendingDocuments(wallet, data);
        return data;
      }
    } catch (e) { 
      print("[FRONT-NOTARY] Error red al obtener pendientes: $e"); 
    }
    return cacheService.getCachedPendingDocuments(wallet);
  }

  /// Registra la firma digital usando la nueva estructura de DTO
  Future<String> signDocumentDelegated(String hash) async {
    try {
      print("✍️ [FRONT-NOTARY] Solicitando firma para el documento $hash...");
      final res = await http.post(
        Uri.parse(ApiConfig.signDocument.replaceAll("{hash}", hash)),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "signerAddress": authCore.publicAddress.toLowerCase(),
          "signatureHex": "0x0" // Listo para meta-transacciones Web3 en el futuro
        })
      );

      if (res.statusCode == 200) {
         print("✅ [FRONT-NOTARY] Firma inmutable registrada con éxito.");
         return "Exito";
      }

      String error = _extractErrorMessage(res.body, res.statusCode);
      print("[FRONT-NOTARY] Error al firmar documento: $error");
      return "Error: $error";
    } catch (e) {
      print("[FRONT-NOTARY] Excepción de red al firmar: $e");
      return "Error de red al firmar";
    }
  }

  Future<Map<String, dynamic>?> getDocumentInfo(String hash) async {
    try {
      String endpoint = ApiConfig.getDocumentInfo.replaceAll("{hash}", hash);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getDocumentHistory() async {
    if (authCore.publicAddress.isEmpty) return [];
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    try {
      print("[FRONT-NOTARY] Consultando historial de documentos para $wallet...");
      String endpoint = ApiConfig.getDocumentHistory.replaceAll("{address}", wallet);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("[FRONT-NOTARY] Historial de documentos cargado: ${data.length}");
        await cacheService.saveDocumentHistory(wallet, data);
        return data;
      }
    } catch (e) { 
      print("[FRONT-NOTARY] Error red al obtener historial: $e"); 
    }
    return cacheService.getCachedDocumentHistory(wallet);
  }
}