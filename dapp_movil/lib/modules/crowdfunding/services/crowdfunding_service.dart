import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../config/blockchain_config.dart'; // Donde declaramos las direcciones de contratos
import '../../auth_and_security/services/auth_core_service.dart';

class CrowdfundingService {
  final AuthCoreService authCore;

  CrowdfundingService(this.authCore);

  // 🔥 HELPER LOCAL DE ERRORES 🔥
  String _extractErrorMessage(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      return parsed['message'] ?? parsed['error'] ?? "Error HTTP $statusCode";
    } catch (_) {
      return "Error HTTP $statusCode";
    }
  }

  /// Obtiene la lista de campañas filtrada (Pública, no requiere JWT estricto)
  // Future<List<dynamic>> getCampaigns({String filter = "WORLDWIDE", String region = "", double lat = 0, double lon = 0}) async {
  //   try {
  //   //String url = "${ApiConfig.getCampaigns}?filterType=$filter";
  //     String url = "${ApiConfig.getCampaigns}?filterType=$filter";
  //     if (filter == "NEARBY") url += "&lat=$lat&lon=$lon&radiusKm=50"; 
  //     if (filter == "REGION") url += "&region=${Uri.encodeComponent(region)}"; // 🔥 Transforma ", Azuay" en "%2C+Azuay"

  //     print("📡 [CROWDFUNDING GET] URL: $url");
  //     final res = await http.get(Uri.parse(url));
  //     if (res.statusCode == 200) {
  //       return jsonDecode(res.body);
  //     }
  //     return [];
  //   } catch (e) {
  //     print("Error obteniendo campañas: $e");
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getCampaigns({String filter = "WORLDWIDE", String region = "", double lat = 0, double lon = 0}) async {
    final cacheService = LocalCacheService();
    // No cacheamos "NEARBY" porque las coordenadas cambian constantemente
    final bool canCache = filter != "NEARBY"; 

    try {
      String url = "${ApiConfig.getCampaigns}?filterType=$filter";
      if (filter == "NEARBY") url += "&lat=$lat&lon=$lon&radiusKm=50"; 
      if (filter == "REGION") url += "&region=${Uri.encodeComponent(region)}";

      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (canCache) await cacheService.saveCampaigns(filter, region, data); // 🔥 GUARDAR CACHÉ
        return data;
      }
    } catch (e) {
      print("Error obteniendo campañas de red: $e");
    }
    
    // 🔥 FALLBACK
    if (canCache) return cacheService.getCachedCampaigns(filter, region);
    return [];
  }

  /// 1. Lanza la campaña y la guarda en MongoDB
  // Future<String> launchCampaign(String title, String description, String category, String region, double targetAmount, int durationDays) async {
  //   if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

  //   try {
  //     int smartContractId = 1; // Simulación del SC si tuvieras contratos dinámicos
  //     final res = await http.post(
  //       Uri.parse(ApiConfig.createCampaign),
  //       headers: authCore.authHeaders,
  //       body: jsonEncode({
  //         "smartContractId": smartContractId,
  //         "title": title,
  //         "description": description,
  //         "category": category,
  //         "creatorAddress": authCore.publicAddress.toLowerCase(),
  //         "targetAmount": targetAmount,
  //         "region": region,
  //         "durationDays": durationDays,
  //         "location": { "type": "Point", "coordinates": [-79.0045, -2.9001] }
  //       })
  //     );
      
  //     if (res.statusCode == 200) return "Exito";
  //     return "Error al crear: ${_extractErrorMessage(res.body, res.statusCode)}";
  //   } catch (e) {
  //     return "Error crítico al crear campaña: $e";
  //   }
  // }

  Future<String> launchCampaign(String title, String desc, String cat, String reg, double target, int days, double lat, double lon) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createCampaign),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "title": title, "description": desc, "category": cat, "region": reg,
          "targetAmount": target, "durationDays": days,
          "creatorAddress": authCore.publicAddress.toLowerCase(),
          "lat": lat, "lon": lon // 🔥 Inyectamos coordenadas
        })
      ).timeout(const Duration(seconds: 25));
      
      if (res.statusCode == 200 || res.statusCode == 201) return "Exito";
      return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
    } catch (e) { return "Error crítico al crear: $e"; }
  }

  /// 2. Envía los TTC y registra el donante
  Future<String> pledgeCampaign(String mongoId, double amount, bool isAnonymous) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

    try {
      // A. Transferimos los tokens reales usando el endpoint estándar de envíos (Antes era sendTokensL2)
      final sendRes = await http.post(
        Uri.parse(ApiConfig.sendTokens),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "fromAddress": authCore.publicAddress.toLowerCase(),
          "toAddress": BlockchainConfig.crowdfundingContract, // Usando la constante de configuración
          "amountTTC": amount.toString(),
        })
      ).timeout(const Duration(seconds: 20));

      if (sendRes.statusCode != 200 && sendRes.statusCode != 201) {
         return "Error al enviar fondos: ${_extractErrorMessage(sendRes.body, sendRes.statusCode)}";
      }

      // B. Registramos la donación en la base de datos de la campaña
      String url = ApiConfig.pledgeCampaign.replaceAll("{id}", mongoId);
      final res = await http.post(
        Uri.parse(url),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "amount": amount,
          "donorAddress": authCore.publicAddress.toLowerCase(),
          "isAnonymous": isAnonymous
        })
      );

      if (res.statusCode == 200) return "Exito";
      return "Error al sincronizar donación: ${_extractErrorMessage(res.body, res.statusCode)}";
      
    } catch (e) {
      return "Error de red al donar: $e";
    }
  }

  /// 3. El creador reclama los fondos de una campaña exitosa
  Future<String> claimCampaign(String mongoId) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

    try {
      print("🚀 [FRONT-CROWDFUNDING] Solicitando retiro de fondos para la campaña: $mongoId");
      String url = ApiConfig.claimCampaign.replaceAll("{id}", mongoId);
      
      final res = await http.put(
        Uri.parse(url), 
        headers: authCore.authHeaders
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) return "Exito";
      
      return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
    } on TimeoutException {
      return "Error: La red está validando la transacción. Tus fondos aparecerán pronto.";
    } on SocketException {
      return "Error: Sin conexión al servidor central.";
    } catch (e) {
      return "Error crítico al reclamar: $e";
    }
  }

  /// 4. El creador cancela la campaña y reembolsa
  Future<String> cancelCampaign(String mongoId, String reason) async {
    if (authCore.publicAddress.isEmpty) return "Error: Billetera no conectada";

    try {
      String url = ApiConfig.cancelCampaign.replaceAll("{id}", mongoId);
      final res = await http.put(
        Uri.parse(url), 
        headers: authCore.authHeaders,
        body: jsonEncode({
          "reason": reason,
          "creatorAddress": authCore.publicAddress.toLowerCase()
        })
      );

      if (res.statusCode == 200) return "Exito";
      
      return "Error: ${_extractErrorMessage(res.body, res.statusCode)}";
    } catch (e) {
      return "Error de red al cancelar la campaña";
    }
  }
}