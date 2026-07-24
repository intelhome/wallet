import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/business/modals/create_department_modal.dart';
import 'package:dapp_movil/modules/business/modals/create_task_modal.dart';
import 'package:dapp_movil/modules/business/modals/department_details_modal.dart';
import 'package:dapp_movil/modules/business/modals/invite_member_modal.dart';
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

  // void _abrirModalInvitacion() {
  //   final identifierController = TextEditingController();
  //   String type = "ALIAS";
  //   String role = "CASHIER";

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Theme.of(context).cardColor,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (context, setModalState) => Padding(
  //         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             const Text("Invitar Empleado", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //             const SizedBox(height: 20),
              
  //             DropdownButtonFormField<String>(
  //               value: type,
  //               decoration: InputDecoration(filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //               items: const [
  //                 DropdownMenuItem(value: "ALIAS", child: Text("Por @Alias")),
  //                 DropdownMenuItem(value: "CEDULA", child: Text("Por Cédula de Identidad")),
  //                 DropdownMenuItem(value: "WALLET", child: Text("Por Billetera (0x)")),
  //               ],
  //               onChanged: (v) => setModalState(() => type = v!),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: identifierController,
  //               decoration: InputDecoration(labelText: "Identificador del empleado", filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //             ),
  //             const SizedBox(height: 16),
  //             DropdownButtonFormField<String>(
  //               value: role,
  //               decoration: InputDecoration(labelText: "Rol en la empresa", filled: true, fillColor: Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //               items: const [
  //                 DropdownMenuItem(value: "CASHIER", child: Text("Cajero (Solo cobrar)")),
  //                 DropdownMenuItem(value: "ADMIN", child: Text("Administrador (Todos los permisos)")),
  //               ],
  //               onChanged: (v) => setModalState(() => role = v!),
  //             ),
  //             const SizedBox(height: 24),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //               onPressed: () async {
  //                 if (identifierController.text.isEmpty) return;
  //                 Navigator.pop(ctx);
  //                 UIHelper.showCustomSnackbar("Enviando invitación...", isError: false);
  //                 final bService = Provider.of<BusinessService>(context, listen: false);
  //                 String res = await bService.inviteTeamMember(identifierController.text, type, role);
  //                 if (res == "SUCCESS") {
  //                   UIHelper.showCustomSnackbar("¡Invitación enviada!");
  //                   _cargarDatos(); 
  //                 } else {
  //                   UIHelper.showCustomSnackbar(res, isError: true);
  //                 }
  //               },
  //               child: const Text("Enviar Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildWorkloadBadge(String wallet) {
  //   return FutureBuilder<Map<String, dynamic>?>(
  //     future: Provider.of<BusinessTaskService>(context, listen: false).getUserWorkload(wallet),
  //     builder: (ctx, snap) {
  //       if (!snap.hasData) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        
  //       final data = snap.data!;
  //       final status = data['workloadStatus'];
  //       Color color = Colors.green;
  //       if (status == 'OPTIMAL') color = Colors.orange;
  //       if (status == 'OVERLOADED') color = Colors.redAccent;

  //       return Tooltip(
  //         message: "Tareas activas: ${data['activeTasksCount']} | Horas: ${data['totalEstimatedHours']}/${data['capacityHours']}",
  //         triggerMode: TooltipTriggerMode.tap,
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //           decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(Icons.battery_charging_full_rounded, size: 12, color: color),
  //               const SizedBox(width: 4),
  //               Text("${data['workloadPercentage']}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildWorkloadBar(String wallet, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<BusinessTaskService>(context, listen: false).getUserWorkload(wallet),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 6, child: LinearProgressIndicator());
        
        final data = snap.data!;
        final status = data['workloadStatus'];
        double percentage = (data['workloadPercentage'] as num).toDouble();
        Color color = Colors.green;
        String statusText = "Estable";

        if (status == 'OPTIMAL') { color = const Color(0xFFFFB86B); statusText = "Óptimo"; }
        if (status == 'OVERLOADED') { color = Colors.redAccent; statusText = "Ocupado"; }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text("Carga de trabajo", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
                Text("${percentage.toStringAsFixed(0)}% - $statusText", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final activeTeam = _team.where((m) => m['status'] == 'ACCEPTED').toList();
    final pendingTeam = _team.where((m) => m['status'] == 'PENDING').toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // ==========================================
            // TAB 1: EQUIPO (MOCKUP 1)
            // ==========================================
           Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              floatingActionButton: FloatingActionButton.extended(
                // 🔥 MODIFICADO: Llamada al nuevo modal externo
                onPressed: () => InviteMemberModal.show(context, _cargarDatos),
                icon: const Icon(Icons.add),
                label: const Text("Nuevo Miembro", style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFBAC3FF), 
                foregroundColor: const Color(0xFF00218d),
                elevation: 0,
              ),
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Text("Usuarios Activos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  activeTeam.isEmpty
                    ? UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin equipo", message: "Aún no tienes empleados activos.")
                    : Column(
                        children: activeTeam.map((member) => Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => TeamMemberDetailsModal.show(context, member),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SmartAvatar(address: member['wallet'] ?? "", size: 50),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(member['alias'] ?? member['identifier'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(height: 2),
                                            Text(member['role'] ?? "EMPLEADO", style: TextStyle(color: const Color(0xFFC77DFF), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.person_remove_rounded, color: colorScheme.onSurface.withOpacity(0.3)),
                                        onPressed: () => _eliminarMiembro(member['identifier'])
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildWorkloadBar(member['wallet'] ?? "", colorScheme), // Llamada a la barra nueva
                                ],
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                  const SizedBox(height: 32),
                  
                  Text("Invitaciones Pendientes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  ...pendingTeam.map((member) {
                    String identifier = member['identifier'];
                    String firstLetter = identifier.isNotEmpty ? identifier[0].toUpperCase() : "?";
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                              child: Text(firstLetter, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(identifier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text("Enviada hace poco", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface.withOpacity(0.8),
                                side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _eliminarMiembro(identifier),
                              child: const Text("Cancelar", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // ==========================================
            // TAB 2: DEPARTAMENTOS / ÁREAS (MOCKUP 2)
            // ==========================================
            Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              floatingActionButton: FloatingActionButton(
                onPressed: () => CreateDepartmentModal.show(context, _cargarDatos),
                backgroundColor: const Color(0xFFBAC3FF),
                foregroundColor: const Color(0xFF00218d),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.add),
              ),
              body: RefreshIndicator(
                onRefresh: _cargarDatos,
                child: _departments.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.account_tree_rounded, title: "Sin Áreas", message: "Crea departamentos para agrupar a tus empleados.")
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _departments.length,
                      itemBuilder: (ctx, i) {
                        var dept = _departments[i];
                        List wallets = dept['memberWallets'] ?? [];
                        double allocated = double.tryParse(dept['allocatedBudget']?.toString() ?? '0') ?? 0.0;
                        double used = double.tryParse(dept['usedBudget']?.toString() ?? '0') ?? 0.0; 
                        double remaining = allocated - used;
                        double progress = allocated > 0 ? (used / allocated).clamp(0.0, 1.0) : 0.0;
                        
                        // Asignación inteligente de íconos según el nombre del departamento
                        IconData iconData = Icons.domain_rounded;
                        String deptName = dept['name'].toString().toLowerCase();
                        if (deptName.contains('tecnología') || deptName.contains('ti') || deptName.contains('dev')) iconData = Icons.computer_rounded;
                        if (deptName.contains('venta') || deptName.contains('sales')) iconData = Icons.trending_up_rounded;
                        if (deptName.contains('recurso') || deptName.contains('hr')) iconData = Icons.people_alt_rounded;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => DepartmentDetailsModal.show(context, dept, activeTeam, _cargarDatos),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.onSurface.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(iconData, color: const Color(0xFFBAC3FF), size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(dept['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.people_alt_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                                                const SizedBox(width: 4),
                                                Text("${wallets.length} miembros", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.more_vert_rounded),
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                        onPressed: () => DepartmentDetailsModal.show(context, dept, activeTeam, _cargarDatos),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Presupuesto Mensual", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 13)),
                                      Text("${allocated.toStringAsFixed(0)} TTC", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFC77DFF)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Usado: ${used.toStringAsFixed(0)} TTC", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11)),
                                      Text("Restante: ${remaining.toStringAsFixed(0)} TTC", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),

            // ==========================================
            // TAB 3: TAREAS (Se mantiene funcional como estaba)
            // ==========================================
            Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: RefreshIndicator(
                onRefresh: _cargarDatos,
                child: _tasks.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.assignment_turned_in_rounded, title: "Sin Tareas", message: "No has asignado ninguna tarea.")
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (ctx, i) => TaskCard(
                        task: _tasks[i], 
                        isEmployer: true, 
                        onRefresh: _cargarDatos,
                      ),
                    ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => CreateTaskModal.show(context, activeTeam, _departments, _cargarDatos),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text("Nueva Tarea", style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFBAC3FF),
                foregroundColor: const Color(0xFF00218d),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}