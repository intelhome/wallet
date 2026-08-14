import 'dart:convert';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';

class PlanConfigService {
  // Guardaremos la configuración en memoria: { "FREE": ["ENVIAR", "COMPRAR"], "PREMIUM": [...] }
  Map<String, List<String>> _tierFeatures = {};

  Map<String, double> _tierPrices = {};
  Map<String, double> _tierAnnualPrices = {};

// Future<void> fetchPlansConfig() async {
//     try {
//       final res = await http.get(Uri.parse(ApiConfig.publicPlansConfig));
//       if (res.statusCode == 200) {
//         List<dynamic> plans = jsonDecode(res.body);
//         for (var plan in plans) {
//           String tier = plan['tier'];
//           List<String> features = List<String>.from(plan['allowedFeatures'] ?? []);
//           _tierFeatures[tier] = features;
          
//           // 🔥 NUEVO: Extraemos y guardamos el precio real actualizado por el Admin
//           _tierPrices[tier] = double.tryParse(plan['price'].toString()) ?? 0.0;
//         }
//         print("✅ [CEREBRO] REGLAS Y PRECIOS DESCARGADOS");
//       }
//     } catch (e) {
//       print("🚨 [CEREBRO] ERROR DE RED AL DESCARGAR REGLAS: $e");
//     }
//   }

// bool hasFeature(String currentTier, String featureName) {
//     if (_tierFeatures.isEmpty) {
//       return true; // Por seguridad desbloqueamos si no hay datos
//     }
//     List<String> allowed = _tierFeatures[currentTier] ?? [];
//     return allowed.contains(featureName);
//   }


  Future<String> upgradePlanWithCrypto(AuthCoreService authCore, String planName, String signature, String cycle, bool autoRenew) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.upgradeCryptoPlan),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase(),
          "plan": planName,
          "signature": signature,
          "cycle": cycle,             // 🔥 NUEVO
          "autoRenew": autoRenew      // 🔥 NUEVO
        })
      );

      if (response.statusCode == 200 || response.statusCode == 201) return "Exito";
      
      print("🚨 [UPGRADE ERROR] ${response.body}");
      return response.body; 
    } catch (e) {
      return "Error de red al pagar: $e";
    }
  }

  
  Future<bool> cancelAutoRenew(AuthCoreService authCore) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.cancelAutoRenew),
        headers: authCore.authHeaders,
        body: jsonEncode({"walletAddress": authCore.publicAddress.toLowerCase()})
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

Future<void> fetchPlansConfig() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.publicPlansConfig));
      print("📡 [CEREBRO] RESPUESTA BACKEND: ${res.body}"); // 🔥 LOG VITAL para ver el JSON real
      
      if (res.statusCode == 200) {
        List<dynamic> plans = jsonDecode(res.body);
        for (var plan in plans) {
          // 🔥 FIX 1: Extracción segura. Buscamos 'tier', y si Spring Boot lo renombró, buscamos 'id'
          String tier = plan['tier'] ?? plan['id'] ?? "UNKNOWN";
          
          if (tier == "UNKNOWN") {
            print("⚠️ [CEREBRO] Plan ignorado (Formato irreconocible): $plan");
            continue;
          }

          _tierFeatures[tier] = List<String>.from(plan['allowedFeatures'] ?? []);
          
          // 🔥 FIX 2: Parseo ultra-seguro contra nulos
          _tierPrices[tier] = double.tryParse(plan['price']?.toString() ?? '0.0') ?? 0.0;
          _tierAnnualPrices[tier] = double.tryParse(plan['annualPrice']?.toString() ?? '0.0') ?? 0.0;
        }
        print("✅ [CEREBRO] PRECIOS DESCARGADOS CON ÉXITO: $_tierPrices");
      } else {
        print("🚨 [CEREBRO] ERROR HTTP ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      print("🚨 [CEREBRO] ERROR CRÍTICO AL DESCARGAR REGLAS: $e");
    }
  }

  bool hasFeature(String currentTier, String featureName) {
    if (_tierFeatures.isEmpty) {
      // 🔥 FIX 3: ¡NUNCA hacer "Fail-Open"! 
      // Si la app no puede descargar las reglas, fallamos de forma segura (Fail-Closed).
      // Solo les permitimos lo más básico para que su dinero no quede atrapado.
      print("⚠️ [SEGURIDAD] Reglas no cargadas. Aplicando modo restrictivo para: $featureName");
      return featureName == "ENVIAR" || featureName == "RECIBIR" || featureName == "RETIRAR"; 
    }
    List<String> allowed = _tierFeatures[currentTier] ?? [];
    return allowed.contains(featureName);
  }

  double getPlanAnnualPrice(String tier) => _tierAnnualPrices[tier] ?? 0.0;

  double getPlanPrice(String tier) {
    return _tierPrices[tier] ?? 0.0;
  }

 Future<String> generatePagoPluxLink(AuthCoreService authCore, String planName, double amount) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/fiat-subscriptions/generate-link"),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "walletAddress": authCore.publicAddress.toLowerCase(), // Siempre en minúsculas por seguridad
          "plan": planName, 
          "amount": amount
        })
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['url'];
      } else {
        // 🔥 Capturamos el error real que envía PagoPlux desde el Backend
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Error desconocido del servidor");
      }
    } catch (e) {
      print("🚨 Error PagoPlux: $e");
      // Relanzamos el error para que la pantalla lo atrape
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
  
}