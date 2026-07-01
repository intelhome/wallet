import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class FamilyService {
  final AuthCoreService authCore;
  FamilyService(this.authCore);

  Future<Map<String, dynamic>> inviteFamilyMember(String identifier, String type, {String? email, String? phone}) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.inviteFamily),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "senderWallet": authCore.publicAddress.toLowerCase(),
          "identifier": identifier,
          "type": type,
          if (email != null) "email": email,
          if (phone != null) "phone": phone,
        })
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {"status": "ERROR", "message": jsonDecode(res.body)['error'] ?? "Error desconocido"};
    } catch (e) {
      return {"status": "ERROR", "message": "Error de conexión"};
    }
  }

  Future<List<dynamic>> getPendingInvites() async {
    try {
      final url = ApiConfig.getFamilyInvites.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<String> respondToInvite(String senderWallet, bool accept) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.respondFamilyInvite),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "userWallet": authCore.publicAddress.toLowerCase(),
          "senderWallet": senderWallet.toLowerCase(),
          "accept": accept
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : jsonDecode(res.body)['error'] ?? "Error";
    } catch (e) { return "Error de red"; }
  }

  Future<List<dynamic>> getFamilyMembers() async {
    try {
      final url = ApiConfig.getFamilyMembers.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  // Busca un usuario en la red antes de invitarlo (Reutiliza tu ruta de búsqueda de usuarios)
  Future<Map<String, dynamic>?> buscarUsuarioParaFamilia(String identifier, String type) async {
    try {
      // Si la búsqueda es por alias, quitamos el @
      String cleanIdentifier = type == "ALIAS" ? identifier.replaceAll("@", "") : identifier;
      
      // Asumiendo que usas la misma ruta que usamos en Split Bill para buscar personas
      String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", cleanIdentifier);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) return data.first;
        if (data is Map<String, dynamic>) return data;
      }
      return null; // No encontrado
    } catch (e) {
      return null;
    }
  }
}