import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class BusinessGroupService {
  final AuthCoreService authCore;
  BusinessGroupService(this.authCore);

 Future<String> createAreaGroup({required String areaName, required String groupName, required List<dynamic> members}) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createBusinessGroup),
        headers: authCore.authHeaders,
        body: jsonEncode({
          "businessId": authCore.publicAddress.toLowerCase(),
          "areaName": areaName,
          "groupName": groupName,
          "creatorAddress": authCore.publicAddress.toLowerCase(),
          "creatorAlias": "Admin", // O el alias real
          "areaMembers": members.map((m) => {
            "walletAddress": m['walletAddress'] ?? m['wallet'] ?? m['identifier'],
            "alias": m['alias'] ?? "Usuario"
          }).toList()
        })
      );
      return res.statusCode == 200 ? "SUCCESS" : "Error al crear grupo corporativo";
    } catch (e) {
      return "Error de red";
    }
  }

Future<List<dynamic>> getBusinessGroups(bool isEmployer) async {
    try {
      String url = isEmployer 
          ? "${ApiConfig.baseUrl}/business-groups/business/${authCore.publicAddress.toLowerCase()}"
          : "${ApiConfig.baseUrl}/business-groups/employee/${authCore.publicAddress.toLowerCase()}";
          
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 15));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { 
      return []; 
    }
  }

  Future<List<dynamic>> getGroupMembers(String groupId) async {
    try {
      final url = ApiConfig.getBusinessGroupMembers.replaceAll("{groupId}", groupId);
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<String> removeMember(String groupId, String memberWallet) async {
    try {
      final url = ApiConfig.removeBusinessGroupMember
          .replaceAll("{groupId}", groupId)
          .replaceAll("{wallet}", memberWallet);
          
      final res = await http.delete(
        Uri.parse(url), 
        headers: authCore.authHeaders,
        body: jsonEncode({"businessWallet": authCore.publicAddress.toLowerCase()})
      );
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar miembro";
    } catch (e) { return "Error de red"; }
  }

  Future<List<dynamic>> getGroupProductivity(String groupId) async {
    try {
      final url = ApiConfig.getBusinessGroupProductivity.replaceAll("{groupId}", groupId);
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<String> addResource(String groupId, Map<String, dynamic> resource) async {
    try {
      final url = ApiConfig.addBusinessGroupResource.replaceAll("{groupId}", groupId);
      final res = await http.post(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(resource));
      return res.statusCode == 200 ? "SUCCESS" : "Error al subir recurso";
    } catch (e) { return "Error de red"; }
  }

  Future<String> addGoal(String groupId, Map<String, dynamic> goal) async {
    try {
      final url = ApiConfig.addBusinessGroupGoal.replaceAll("{groupId}", groupId);
      final res = await http.post(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(goal));
      return res.statusCode == 200 ? "SUCCESS" : "Error al crear objetivo";
    } catch (e) { return "Error de red"; }
  }

  Future<String> updateAnnouncement(String groupId, String announcement) async {
    try {
      final url = ApiConfig.updateBusinessGroupAnnouncement.replaceAll("{groupId}", groupId);
      final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode({
        "adminWallet": authCore.publicAddress.toLowerCase(),
        "announcement": announcement
      }));
      return res.statusCode == 200 ? "SUCCESS" : "Error al fijar anuncio";
    } catch (e) { return "Error de red"; }
  }

  Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    try {
      final url = ApiConfig.getBusinessGroupById.replaceAll("{groupId}", groupId);
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> auditEmployee(String groupId, String memberWallet) async {
    try {
      final url = ApiConfig.auditBusinessGroupMember
          .replaceAll("{groupId}", groupId)
          .replaceAll("{address}", memberWallet);
      final res = await http.post(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) {
      return null;
    }
  }

  // Future<String> updateResource(String groupId, String resourceId, Map<String, dynamic> data) async {
  //   try {
  //     final url = ApiConfig.updateBusinessGroupResource.replaceAll("{groupId}", groupId).replaceAll("{resourceId}", resourceId);
  //     final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(data));
  //     return res.statusCode == 200 ? "SUCCESS" : "Error al actualizar recurso";
  //   } catch (e) { return "Error de red"; }
  // }

  Future<String> deleteResource(String groupId, String resourceId) async {
    try {
      final url = ApiConfig.deleteBusinessGroupResource.replaceAll("{groupId}", groupId).replaceAll("{resourceId}", resourceId);
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar recurso";
    } catch (e) { return "Error de red"; }
  }

  // Future<String> updateGoal(String groupId, String goalId, Map<String, dynamic> data) async {
  //   try {
  //     final url = ApiConfig.updateBusinessGroupGoal.replaceAll("{groupId}", groupId).replaceAll("{goalId}", goalId);
  //     final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(data));
  //     return res.statusCode == 200 ? "SUCCESS" : "Error al actualizar meta";
  //   } catch (e) { return "Error de red"; }
  // }

  Future<String> deleteGoal(String groupId, String goalId) async {
    try {
      final url = ApiConfig.deleteBusinessGroupGoal.replaceAll("{groupId}", groupId).replaceAll("{goalId}", goalId);
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar meta";
    } catch (e) { return "Error de red"; }
  }

  Future<String> addGoalProgress(String groupId, String goalId, Map<String, dynamic> progress) async {
    try {
      final url = ApiConfig.addBusinessGroupGoalProgress.replaceAll("{groupId}", groupId).replaceAll("{goalId}", goalId);
      final res = await http.post(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(progress));
      return res.statusCode == 200 ? "SUCCESS" : "Error al registrar avance";
    } catch (e) { return "Error de red"; }
  }

  Future<String> updateResource(String groupId, String resourceId, Map<String, dynamic> data) async {
    try {
      final url = ApiConfig.updateBusinessGroupResource.replaceAll("{groupId}", groupId).replaceAll("{resourceId}", resourceId);
      final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(data));
      return res.statusCode == 200 ? "SUCCESS" : "Error al actualizar recurso";
    } catch (e) { return "Error de red"; }
  }

  Future<String> updateGoal(String groupId, String goalId, Map<String, dynamic> data) async {
    try {
      final url = ApiConfig.updateBusinessGroupGoal.replaceAll("{groupId}", groupId).replaceAll("{goalId}", goalId);
      final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(data));
      return res.statusCode == 200 ? "SUCCESS" : "Error al actualizar meta";
    } catch (e) { return "Error de red"; }
  }
}