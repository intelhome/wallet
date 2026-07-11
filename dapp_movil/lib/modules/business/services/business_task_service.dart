import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class BusinessTaskService {
  final AuthCoreService authCore;
  BusinessTaskService(this.authCore);

  // Future<String> createTask(Map<String, dynamic> taskData) async {
  //   try {
  //     final res = await http.post(Uri.parse(ApiConfig.createBusinessTask),
  //         headers: authCore.authHeaders, body: jsonEncode(taskData));
  //     return res.statusCode == 200 ? "SUCCESS" : "Error al crear tarea";
  //   } catch (e) { return "Error de red"; }
  // }

  Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      // Formateamos los datos para enviarlos exactamente como el Backend (CreateTaskDTO) los espera.
      final res = await http.post(
          Uri.parse(ApiConfig.createBusinessTask),
          headers: authCore.authHeaders, 
          body: jsonEncode(taskData)
      );
      return res.statusCode == 200 ? "SUCCESS" : "Error al crear tarea";
    } catch (e) { 
      return "Error de red"; 
    }
  }

  // Future<List<dynamic>> getEmployerTasks() async {
  //   try {
  //     final url = ApiConfig.getBusinessTasksEmployer.replaceAll("{address}", authCore.publicAddress.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { return []; }
  // }

  Future<List<dynamic>> getEmployerTasks() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getBusinessTasksEmployer.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveEmployerTasks(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedEmployerTasks(); // 🔥 FALLBACK
  }

  // Future<List<dynamic>> getEmployeeTasks() async {
  //   try {
  //     final url = ApiConfig.getBusinessTasksEmployee.replaceAll("{address}", authCore.publicAddress.toLowerCase());
  //     final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
  //     return res.statusCode == 200 ? jsonDecode(res.body) : [];
  //   } catch (e) { return []; }
  // }

  Future<List<dynamic>> getEmployeeTasks() async {
    final cacheService = LocalCacheService();
    try {
      final url = ApiConfig.getBusinessTasksEmployee.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveEmployeeTasks(data); // 🔥 GUARDADO
        return data;
      }
    } catch (e) { print("Error red: $e"); }
    return cacheService.getCachedEmployeeTasks(); // 🔥 FALLBACK
  }

  Future<String> updateTaskStatus(String taskId, Map<String, dynamic> payload) async {
    try {
      final url = ApiConfig.updateBusinessTaskStatus.replaceAll("{taskId}", taskId);
      final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(payload));
      return res.statusCode == 200 ? "SUCCESS" : "Error al actualizar estado";
    } catch (e) { return "Error de red"; }
  }
  Future<String> editTask(String taskId, Map<String, dynamic> taskData) async {
    try {
      final url = ApiConfig.editBusinessTask.replaceAll("{taskId}", taskId);
      final res = await http.put(Uri.parse(url), headers: authCore.authHeaders, body: jsonEncode(taskData));
      return res.statusCode == 200 ? "SUCCESS" : "Error al editar tarea";
    } catch (e) { return "Error de red"; }
  }

  Future<String> deleteTask(String taskId) async {
    try {
      final url = ApiConfig.deleteBusinessTask.replaceAll("{taskId}", taskId);
      final res = await http.delete(Uri.parse(url), headers: authCore.authHeaders);
      return res.statusCode == 200 ? "SUCCESS" : "Error al eliminar tarea";
    } catch (e) { return "Error de red"; }
  }

  Future<Map<String, dynamic>?> getUserWorkload(String wallet) async {
    try {
      final url = ApiConfig.getUserWorkload.replaceAll("{wallet}", wallet.toLowerCase());
      final res = await http.get(Uri.parse(url), headers: authCore.authHeaders);
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
}