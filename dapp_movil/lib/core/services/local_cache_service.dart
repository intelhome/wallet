import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  final Box _txBox = Hive.box('transactions_cache');
  final Box _contactBox = Hive.box('contacts_cache');
  final Box _chatBox = Hive.box('chat_cache');
  final Box _userBox = Hive.box('user_cache');
  final Box _crowdBox = Hive.box('crowd_cache');
  final Box _businessBox = Hive.box('business_cache');
  final Box _adminBox = Hive.box('admin_cache');
  final Box _aiBox = Hive.box('ai_cache');
  final Box _burnerBox = Hive.box('burner_cache');
  final Box _debtsBox = Hive.box('debts_cache');
  final Box _notaryBox = Hive.box('notary_cache');
  final Box _notifBox = Hive.box('notifications_cache');
  final Box _vaultsBox = Hive.box('vaults_cache');

  Future<void> clearTransactionsCache() async => await _txBox.clear();
  Future<void> clearVaultsCache() async => await _vaultsBox.clear();
  Future<void> clearDebtsCache() async => await _debtsBox.clear();
  Future<void> clearDashboardCache() async => await _userBox.delete('dashboard');

  // ==========================================
  // 1. TRANSACCIONES
  // ==========================================
  Future<void> saveTransactions(List<dynamic> transactions) async => await _txBox.put('my_history', jsonEncode(transactions));
  List<dynamic> getCachedTransactions() {
    String? data = _txBox.get('my_history');
    return data != null ? jsonDecode(data) : [];
  }

  // ==========================================
  // 2. CONTACTOS
  // ==========================================
  Future<void> saveContacts(List<dynamic> contacts) async => await _contactBox.put('my_contacts', jsonEncode(contacts));
  List<dynamic> getCachedContacts() {
    String? data = _contactBox.get('my_contacts');
    return data != null ? jsonDecode(data) : [];
  }

  // ==========================================
  // 3. DATOS DEL USUARIO (DASHBOARD)
  // ==========================================
  Future<void> saveDashboardData(Map<String, dynamic> data) async => await _userBox.put('dashboard', jsonEncode(data));
  Map<String, dynamic> getCachedDashboardData() {
    String? data = _userBox.get('dashboard');
    return data != null ? jsonDecode(data) : {};
  }

  // ==========================================
  // 4. CHATS SEGUROS (Por Billetera)
  // ==========================================
  Future<void> saveChatHistory(String peerWallet, List<Map<String, dynamic>> messages) async {
    // Convertimos las fechas a String antes de guardar en JSON
    final encodableList = messages.map((m) => {
      ...m,
      "timestamp": m["timestamp"] is DateTime ? (m["timestamp"] as DateTime).toIso8601String() : m["timestamp"]
    }).toList();
    await _chatBox.put('chat_$peerWallet', jsonEncode(encodableList));
  }

  List<Map<String, dynamic>> getCachedChat(String peerWallet) {
    String? data = _chatBox.get('chat_$peerWallet');
    if (data == null) return [];
    
    List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) {
      final map = Map<String, dynamic>.from(e);
      // Restauramos la fecha a DateTime
      if (map['timestamp'] != null) map['timestamp'] = DateTime.parse(map['timestamp'].toString());
      return map;
    }).toList();
  }

  // ==========================================
  // 5. ANALÍTICAS (PANTALLA DE HISTORIAS)
  // ==========================================
  Future<void> saveAnalytics(Map<String, dynamic> data) async => await _userBox.put('analytics_data', jsonEncode(data));
  Map<String, dynamic> getCachedAnalytics() {
    String? data = _userBox.get('analytics_data');
    return data != null ? jsonDecode(data) : {};
  }

  // ==========================================
  // 6. CHATS SEGUROS Y BANDEJA DE ENTRADA (INBOX)
  // ==========================================
  Future<void> saveInbox(List<dynamic> inbox) async => await _chatBox.put('my_inbox', jsonEncode(inbox));
  
  List<Map<String, dynamic>> getCachedInbox() {
    String? data = _chatBox.get('my_inbox');
    if (data == null) return [];
    List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ==========================================
  // 7. CROWDFUNDING (CAMPAÑAS)
  // ==========================================
  Future<void> saveCampaigns(String filter, String region, List<dynamic> campaigns) async {
    // Guardamos con una clave dinámica para separar Global vs Región
    await _crowdBox.put('camp_${filter}_$region', jsonEncode(campaigns));
  }
  
  List<dynamic> getCachedCampaigns(String filter, String region) {
    String? data = _crowdBox.get('camp_${filter}_$region');
    return data != null ? jsonDecode(data) : [];
  }

  // ==========================================
  // 8. MÓDULO EMPRESARIAL (BUSINESS & TASKS)
  // ==========================================
  
  // A. Empleados y Equipo
  Future<void> saveTeamWithDetails(List<dynamic> team) async => await _businessBox.put('team_details', jsonEncode(team));
  List<dynamic> getCachedTeamWithDetails() => _businessBox.get('team_details') != null ? jsonDecode(_businessBox.get('team_details')) : [];

  // B. Departamentos
  Future<void> saveDepartments(List<dynamic> depts) async => await _businessBox.put('departments', jsonEncode(depts));
  List<dynamic> getCachedDepartments() => _businessBox.get('departments') != null ? jsonDecode(_businessBox.get('departments')) : [];

  // C. Tareas de la Empresa (Jefe)
  Future<void> saveEmployerTasks(List<dynamic> tasks) async => await _businessBox.put('employer_tasks', jsonEncode(tasks));
  List<dynamic> getCachedEmployerTasks() => _businessBox.get('employer_tasks') != null ? jsonDecode(_businessBox.get('employer_tasks')) : [];

  // D. Tareas Asignadas (Empleado)
  Future<void> saveEmployeeTasks(List<dynamic> tasks) async => await _businessBox.put('employee_tasks', jsonEncode(tasks));
  List<dynamic> getCachedEmployeeTasks() => _businessBox.get('employee_tasks') != null ? jsonDecode(_businessBox.get('employee_tasks')) : [];

  // E. Invitaciones Laborales
  Future<void> savePendingInvites(List<dynamic> invites) async => await _businessBox.put('pending_invites', jsonEncode(invites));
  List<dynamic> getCachedPendingInvites() => _businessBox.get('pending_invites') != null ? jsonDecode(_businessBox.get('pending_invites')) : [];

  // F. Mis Empleadores
  Future<void> saveMyEmployers(List<dynamic> employers) async => await _businessBox.put('my_employers', jsonEncode(employers));
  List<dynamic> getCachedMyEmployers() => _businessBox.get('my_employers') != null ? jsonDecode(_businessBox.get('my_employers')) : [];


// ==========================================
  // 9. MÓDULO DE ADMINISTRACIÓN (SUPER ADMIN)
  // ==========================================
  Future<void> saveAdminPlans(List<dynamic> plans) async => await _adminBox.put('plans', jsonEncode(plans));
  List<dynamic> getCachedAdminPlans() => _adminBox.get('plans') != null ? jsonDecode(_adminBox.get('plans')) : [];

  Future<void> savePendingBusinesses(List<dynamic> list) async => await _adminBox.put('pending_biz', jsonEncode(list));
  List<dynamic> getCachedPendingBusinesses() => _adminBox.get('pending_biz') != null ? jsonDecode(_adminBox.get('pending_biz')) : [];

  Future<void> saveAdminAnalytics(Map<String, dynamic> data) async => await _adminBox.put('analytics', jsonEncode(data));
  Map<String, dynamic>? getCachedAdminAnalytics() => _adminBox.get('analytics') != null ? jsonDecode(_adminBox.get('analytics')) : null;

  Future<void> saveUsersByTier(String tier, List<dynamic> users) async => await _adminBox.put('tier_$tier', jsonEncode(users));
  List<dynamic> getCachedUsersByTier(String tier) => _adminBox.get('tier_$tier') != null ? jsonDecode(_adminBox.get('tier_$tier')) : [];

  // ==========================================
  // 10. MÓDULO DE IA (GUSTOS Y MEMORIA)
  // ==========================================
  Future<void> saveAiPreferences(String wallet, List<dynamic> prefs) async => await _aiBox.put('prefs_$wallet', jsonEncode(prefs));
  List<dynamic> getCachedAiPreferences(String wallet) => _aiBox.get('prefs_$wallet') != null ? jsonDecode(_aiBox.get('prefs_$wallet')) : [];

  // ==========================================
  // 11. MÓDULO BURNER WALLETS (EFÍMERAS)
  // ==========================================
  Future<void> saveActiveBurners(String wallet, List<dynamic> burners) async => await _burnerBox.put('burners_$wallet', jsonEncode(burners));
  List<dynamic> getCachedActiveBurners(String wallet) => _burnerBox.get('burners_$wallet') != null ? jsonDecode(_burnerBox.get('burners_$wallet')) : [];

  Future<void> saveBurnerHistory(String wallet, List<dynamic> history) async => await _burnerBox.put('history_$wallet', jsonEncode(history));
  List<dynamic> getCachedBurnerHistory(String wallet) => _burnerBox.get('history_$wallet') != null ? jsonDecode(_burnerBox.get('history_$wallet')) : [];

  // ==========================================
  // 12. DEUDAS Y PAGOS PROGRAMADOS
  // ==========================================
  Future<void> saveUserDebts(String wallet, List<dynamic> debts) async => await _debtsBox.put('debts_$wallet', jsonEncode(debts));
  List<dynamic> getCachedUserDebts(String wallet) => _debtsBox.get('debts_$wallet') != null ? jsonDecode(_debtsBox.get('debts_$wallet')) : [];

  Future<void> saveGroupSharedDebts(String groupId, List<dynamic> debts) async => await _debtsBox.put('shared_$groupId', jsonEncode(debts));
  List<dynamic> getCachedGroupSharedDebts(String groupId) => _debtsBox.get('shared_$groupId') != null ? jsonDecode(_debtsBox.get('shared_$groupId')) : [];

  Future<void> saveScheduledPayments(String wallet, List<dynamic> payments) async => await _debtsBox.put('sched_$wallet', jsonEncode(payments));
  List<dynamic> getCachedScheduledPayments(String wallet) => _debtsBox.get('sched_$wallet') != null ? jsonDecode(_debtsBox.get('sched_$wallet')) : [];

  // ==========================================
  // 13. NOTARÍA DE DOCUMENTOS
  // ==========================================
  Future<void> savePendingDocuments(String wallet, List<dynamic> docs) async => await _notaryBox.put('pending_$wallet', jsonEncode(docs));
  List<dynamic> getCachedPendingDocuments(String wallet) => _notaryBox.get('pending_$wallet') != null ? jsonDecode(_notaryBox.get('pending_$wallet')) : [];

  Future<void> saveDocumentHistory(String wallet, List<dynamic> history) async => await _notaryBox.put('history_$wallet', jsonEncode(history));
  List<dynamic> getCachedDocumentHistory(String wallet) => _notaryBox.get('history_$wallet') != null ? jsonDecode(_notaryBox.get('history_$wallet')) : [];

  // ==========================================
  // 14. NOTIFICACIONES PUSH / IN-APP
  // ==========================================
  Future<void> saveNotifications(List<dynamic> notifs) async => await _notifBox.put('my_notifs', jsonEncode(notifs));
  List<dynamic> getCachedNotifications() => _notifBox.get('my_notifs') != null ? jsonDecode(_notifBox.get('my_notifs')) : [];

  // ==========================================
  // 15. BÓVEDAS INTELIGENTES (SMART VAULTS)
  // ==========================================
  Future<void> saveUserVaults(String wallet, List<dynamic> vaults) async => await _vaultsBox.put('vaults_$wallet', jsonEncode(vaults));
  List<dynamic> getCachedUserVaults(String wallet) => _vaultsBox.get('vaults_$wallet') != null ? jsonDecode(_vaultsBox.get('vaults_$wallet')) : [];

  // ==========================================
  // LIMPIEZA GLOBAL (AL CERRAR SESIÓN)
  // ==========================================
  Future<void> clearAllCache() async {
    await _txBox.clear();
    await _contactBox.clear();
    await _chatBox.clear();
    await _userBox.clear();
    await _crowdBox.clear();
    await _businessBox.clear();
    await _adminBox.clear();  
    await _aiBox.clear();     
    await _burnerBox.clear();
    await _debtsBox.clear();
    await _notaryBox.clear();
    await _notifBox.clear();
    await _vaultsBox.clear();
  }
}