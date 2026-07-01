import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';

class BusinessService {
  final AuthCoreService authCore;
  BusinessService(this.authCore);
  

  Future<String> inviteTeamMember(String identifier, String type, String role) async {
    try {
      // 🔥 FIX: Si es ALIAS, le quitamos el '@' por si el usuario lo escribió
      String cleanIdentifier = type == "ALIAS" ? identifier.replaceAll("@", "") : identifier;

      final res = await http.post(
        Uri.parse(ApiConfig.inviteTeamMember),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "businessWallet": authCore.publicAddress.toLowerCase(),
          "identifier": cleanIdentifier, // Enviamos el identificador limpio
          "type": type, 
          "role": role 
        })
      );
      if (res.statusCode == 200) return "SUCCESS";
      return jsonDecode(res.body)['error'] ?? "Error desconocido";
    } catch (e) { return "Error de conexión"; }
  }

// Future<List<dynamic>> getMyPendingInvites() async {
//     try {
//       final url = ApiConfig.getPendingInvites.replaceAll("{address}", authCore.publicAddress.toLowerCase());
//       final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      
//       // 🔥 LOG para ver qué responde exactamente el servidor
//       print("📡 [MIS INVITACIONES] HTTP ${res.statusCode}: ${res.body}");
      
//       return res.statusCode == 200 ? jsonDecode(res.body) : [];
//     } catch (e) { 
//       print("🚨 [MIS INVITACIONES] Error: $e");
//       return []; 
//     }
//   }

Future<List<dynamic>> getMyPendingInvites() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getPendingInvites.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.savePendingInvites(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedPendingInvites(); // 🔥 FALLBACK
  }

  Future<String> respondToInvite(String businessWallet, bool accept) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.respondBusinessInvite),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "userWallet": authCore.publicAddress.toLowerCase(),
          "businessWallet": businessWallet.toLowerCase(),
          "accept": accept
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : "Error al responder";
    } catch (e) { return "Error de red"; }
  }

  // 🔥 NUEVO: Obtener la lista del equipo de mi empresa
  Future<List<dynamic>> getTeamMembers() async {
    try {
      final url = ApiConfig.getTeamMembers.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  // 🔥 NUEVO: Despedir empleado o cancelar invitación
  Future<String> removeTeamMember(String identifier) async {
    try {
      final url = ApiConfig.removeTeamMember
          .replaceAll("{address}", authCore.publicAddress.toLowerCase())
          .replaceAll("{identifier}", identifier);
      
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar";
    } catch (e) {
      return "Error de red";
    }
  }

  // Future<List<dynamic>> getTeamWithDetails() async {
  //   try {
  //     final url = ApiConfig.getTeamWithDetails.replaceAll("{address}", authCore.publicAddress.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { return []; }
  // }

  Future<List<dynamic>> getTeamWithDetails() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getTeamWithDetails.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveTeamWithDetails(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedTeamWithDetails(); // 🔥 FALLBACK
  }

  // Future<List<dynamic>> getMyEmployers() async {
  //   try {
  //     final url = ApiConfig.getMyEmployers.replaceAll("{address}", authCore.publicAddress.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { return []; }
  // }

  Future<List<dynamic>> getMyEmployers() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getMyEmployers.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveMyEmployers(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedMyEmployers(); // 🔥 FALLBACK
  }
  // --- DEPARTAMENTOS ---
  // Future<List<dynamic>> getDepartments() async {
  //   try {
  //     final url = ApiConfig.getDepartments.replaceAll("{address}", authCore.publicAddress.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { return []; }
  // }

  Future<List<dynamic>> getDepartments() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getDepartments.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveDepartments(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedDepartments(); // 🔥 FALLBACK
  }

  Future<String> createDepartment(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.createDepartment), headers: authCore.authHeaders, body: jsonEncode(data));
      return res.statusCode == 200 ? "SUCCESS" : "Error al crear departamento";
    } catch (e) { return "Error de red"; }
  }

  Future<String> addMemberToDepartment(String departmentId, String memberWallet) async {
    try {
      final url = ApiConfig.addDepartmentMember.replaceAll("{departmentId}", departmentId);
      final res = await http.post(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode({"memberWallet": memberWallet}));
      return res.statusCode == 200 ? "SUCCESS" : "Error al asignar miembro";
    } catch (e) { return "Error de red"; }
  }

  Future<String> removeMemberFromDepartment(String departmentId, String memberWallet) async {
    try {
      final url = ApiConfig.removeDepartmentMember.replaceAll("{departmentId}", departmentId).replaceAll("{wallet}", memberWallet);
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al remover miembro";
    } catch (e) { return "Error de red"; }
  }
  
  Future<String> deleteDepartment(String departmentId) async {
    try {
      final url = ApiConfig.deleteDepartment.replaceAll("{departmentId}", departmentId);
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar";
    } catch (e) { return "Error de red"; }
  }
}