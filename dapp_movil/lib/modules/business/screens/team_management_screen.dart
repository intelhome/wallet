import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/business/modals/create_department_modal.dart';
import 'package:dapp_movil/modules/business/modals/create_task_modal.dart';
import 'package:dapp_movil/modules/business/modals/department_details_modal.dart';
import 'package:dapp_movil/modules/business/modals/task_details_modal.dart';
import 'package:dapp_movil/modules/business/modals/team_member_details_modal.dart';
import 'package:dapp_movil/modules/business/screens/business_calendar_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_history_screen.dart';
import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:dapp_movil/modules/business/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});
  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  List<dynamic> _team = []; 
  List<dynamic> _tasks = [];
  List<dynamic> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Future<void> _cargarDatos() async {
  //   setState(() => _isLoading = true);
  //   final bService = Provider.of<BusinessService>(context, listen: false);
  //   final tService = Provider.of<BusinessTaskService>(context, listen: false);
    
  //   var results = await Future.wait<dynamic>([
  //     bService.getTeamWithDetails(),
  //     tService.getEmployerTasks(),
  //     bService.getDepartments()
  //   ]);
  //   _team = results[0];
  //   _tasks = results[1];
  //   _departments = results[2];
    
  //   if (mounted) setState(() => _isLoading = false);
  // }

  Future<void> _cargarDatos() async {
    final cacheService = LocalCacheService();
    
    // 1. Mostrar Caché rápido
    final cachedTeam = cacheService.getCachedTeamWithDetails();
    final cachedTasks = cacheService.getCachedEmployerTasks();
    final cachedDepts = cacheService.getCachedDepartments();
    
    if (cachedTeam.isNotEmpty || cachedTasks.isNotEmpty || cachedDepts.isNotEmpty) {
      if (mounted) setState(() {
        _team = cachedTeam;
        _tasks = cachedTasks;
        _departments = cachedDepts;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true); // Solo mostramos spinner si el caché está vacío
    }

    // 2. Traer de red en segundo plano
    final bService = Provider.of<BusinessService>(context, listen: false);
    final tService = Provider.of<BusinessTaskService>(context, listen: false);
    
    var results = await Future.wait<dynamic>([
      bService.getTeamWithDetails(),
      tService.getEmployerTasks(),
      bService.getDepartments()
    ]);
    
    if (mounted) {
      setState(() {
        _team = results[0];
        _tasks = results[1];
        _departments = results[2];
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarMiembro(String identifier) async {
    bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Remover", mensaje: "¿Seguro que deseas remover a este miembro?", textoConfirmar: "Eliminar", colorConfirmar: Colors.redAccent);
    if (confirm != true) return;

    final res = await Provider.of<BusinessService>(context, listen: false).removeTeamMember(identifier);
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Miembro removido exitosamente");
      _cargarDatos();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  void _abrirModalInvitacion() {
    final identifierController = TextEditingController();
    String type = "ALIAS";
    String role = "CASHIER";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Invitar Empleado", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                items: const [
                  DropdownMenuItem(value: "ALIAS", child: Text("Por @Alias")),
                  DropdownMenuItem(value: "CEDULA", child: Text("Por Cédula de Identidad")),
                  DropdownMenuItem(value: "WALLET", child: Text("Por Billetera (0x)")),
                ],
                onChanged: (v) => setModalState(() => type = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: identifierController,
                decoration: InputDecoration(labelText: "Identificador del empleado", filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(labelText: "Rol en la empresa", filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                items: const [
                  DropdownMenuItem(value: "CASHIER", child: Text("Cajero (Solo cobrar)")),
                  DropdownMenuItem(value: "ADMIN", child: Text("Administrador (Todos los permisos)")),
                ],
                onChanged: (v) => setModalState(() => role = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  if (identifierController.text.isEmpty) return;
                  Navigator.pop(ctx);
                  UIHelper.showCustomSnackbar("Enviando invitación...", isError: false);
                  final bService = Provider.of<BusinessService>(context, listen: false);
                  String res = await bService.inviteTeamMember(identifierController.text, type, role);
                  if (res == "SUCCESS") {
                    UIHelper.showCustomSnackbar("¡Invitación enviada!");
                    _cargarDatos(); 
                  } else {
                    UIHelper.showCustomSnackbar(res, isError: true);
                  }
                },
                child: const Text("Enviar Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkloadBadge(String wallet) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<BusinessTaskService>(context, listen: false).getUserWorkload(wallet),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        
        final data = snap.data!;
        final status = data['workloadStatus'];
        Color color = Colors.green;
        if (status == 'OPTIMAL') color = Colors.orange;
        if (status == 'OVERLOADED') color = Colors.redAccent;

        return Tooltip(
          message: "Tareas activas: ${data['activeTasksCount']} | Horas: ${data['totalEstimatedHours']}/${data['capacityHours']}",
          triggerMode: TooltipTriggerMode.tap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.battery_charging_full_rounded, size: 12, color: color),
                const SizedBox(width: 4),
                Text("${data['workloadPercentage']}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final activeTeam = _team.where((m) => m['status'] == 'ACCEPTED').toList();
    final pendingTeam = _team.where((m) => m['status'] == 'PENDING').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestión Comercial", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: "Calendario",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCalendarScreen(isEmployer: true)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: "Historial General",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskHistoryScreen()));
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people_rounded), text: "Equipo"), 
              Tab(icon: Icon(Icons.domain_rounded), text: "Áreas"),
              Tab(icon: Icon(Icons.assignment_rounded), text: "Tareas")
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: EQUIPO
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _abrirModalInvitacion,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text("Invitar"),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Miembros Activos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  activeTeam.isEmpty
                    ? UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin equipo", message: "Aún no tienes empleados activos.")
                    : Column(
                        children: activeTeam.map((member) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => TeamMemberDetailsModal.show(context, member),
                            leading: SmartAvatar(address: member['wallet'] ?? "", size: 40),
                          title: Text(member['alias'] ?? member['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Row(
                              children: [
                                Text(member['role'] ?? "EMPLEADO"),
                                const SizedBox(width: 8),
                                _buildWorkloadBadge(member['wallet'] ?? "") // 🔥 Semáforo de carga
                              ],
                            ),
                            trailing: IconButton(icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent), onPressed: () => _eliminarMiembro(member['identifier'])),
                          ),
                        )).toList(),
                      ),
                  const SizedBox(height: 24),
                  const Text("Invitaciones Pendientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 12),
                  ...pendingTeam.map((member) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.access_time_filled_rounded, color: Colors.white)),
                      title: Text(member['identifier'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Esperando respuesta...", style: TextStyle(color: Colors.orange, fontSize: 12)),
                      trailing: IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent), onPressed: () => _eliminarMiembro(member['identifier'])),
                    ),
                  )),
                ],
              ),
            ),
            
            // TAB 2: DEPARTAMENTOS
            Scaffold(
              body: RefreshIndicator(
                onRefresh: _cargarDatos,
                child: _departments.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.account_tree_rounded, title: "Sin Áreas", message: "Crea departamentos para agrupar a tus empleados.")
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _departments.length,
                      itemBuilder: (ctx, i) {
                        var dept = _departments[i];
                        List wallets = dept['memberWallets'] ?? [];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => DepartmentDetailsModal.show(context, dept, activeTeam, _cargarDatos),
                            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.domain, color: Colors.white)),
                            title: Text(dept['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${wallets.length} miembros | Pto: ${dept['allocatedBudget']} TTC"),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => CreateDepartmentModal.show(context, _cargarDatos),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text("Nueva Área"),
              ),
            ),

            // TAB 3: TAREAS
            Scaffold(
              body: RefreshIndicator(
                onRefresh: _cargarDatos,
                child: _tasks.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.assignment_turned_in_rounded, title: "Sin Tareas", message: "No has asignado ninguna tarea.")
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                    itemBuilder: (ctx, i) => TaskCard(
                        task: _tasks[i], 
                        isEmployer: true, 
                        onRefresh: _cargarDatos,
                      ),
                    ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                // 🔥 Modificado para aceptar _departments también
                onPressed: () => CreateTaskModal.show(context, activeTeam, _departments, _cargarDatos),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text("Nueva Tarea"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}