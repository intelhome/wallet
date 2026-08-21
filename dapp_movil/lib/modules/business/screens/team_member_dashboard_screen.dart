import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_service.dart';
import 'task_details_screen.dart';

class TeamMemberDashboardScreen extends StatefulWidget {
  final dynamic member;
  final Function(String) onRemoveMember;
  final VoidCallback onRefreshTeam;

  const TeamMemberDashboardScreen({
    super.key,
    required this.member,
    required this.onRemoveMember,
    required this.onRefreshTeam,
  });

  @override
  State<TeamMemberDashboardScreen> createState() => _TeamMemberDashboardScreenState();
}

class _TeamMemberDashboardScreenState extends State<TeamMemberDashboardScreen> {
  String _selectedStatus = 'Todos';
  List<dynamic> _tasks = [];
  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _tasks = widget.member['assignedTasks'] ?? [];
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final bService = Provider.of<BusinessService>(context, listen: false);
    final depts = await bService.getDepartments();
    if (mounted) setState(() => _departments = depts);
  }

  List<dynamic> get _filteredTasks {
    if (_selectedStatus == 'Todos') return _tasks;
    return _tasks.where((t) => t['status'] == _selectedStatus).toList();
  }

  void _mostrarModalCambiarArea() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Asignar a un Área", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Selecciona el departamento al que quieres mover a este empleado.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              _departments.isEmpty 
                ? const Text("No hay áreas creadas en la empresa.")
                : Column(
                    children: _departments.map((d) => ListTile(
                      leading: Icon(Icons.domain_rounded, color: colorScheme.primary),
                      title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        UIHelper.showCustomSnackbar("Asignando área...");
                        final bService = Provider.of<BusinessService>(context, listen: false);
                        String res = await bService.addMemberToDepartment(d['id'], widget.member['walletAddress']);
                        if (res == "SUCCESS") {
                          UIHelper.showCustomSnackbar("Usuario asignado exitosamente");
                          widget.onRefreshTeam(); // Refresca en el background
                        } else {
                          UIHelper.showCustomSnackbar(res, isError: true);
                        }
                      },
                    )).toList(),
                  )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    String dateJoined = "Reciente";
    if (widget.member['invitedAt'] != null) {
      try {
        DateTime dt = DateTime.parse(widget.member['invitedAt']).toLocal();
        dateJoined = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
      } catch (_) {}
    }

    final statusWorkload = widget.member['workloadStatus'] ?? 'LOW';
    Color workloadColor = colorScheme.primary;
    String statusText = "Estable";

    if (statusWorkload == 'OPTIMAL') { workloadColor = colorScheme.tertiary; statusText = "Óptimo"; }
    if (statusWorkload == 'OVERLOADED') { workloadColor = colorScheme.error; statusText = "Sobrecargado"; }
    double wp = double.tryParse(widget.member['workloadPercentage']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Panel de Empleado", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 1. TARJETA DE PERFIL
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: Column(
              children: [
                Row(
                  children: [
                    SmartAvatar(address: widget.member['walletAddress'] ?? '', size: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.member['alias'] ?? 'Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                          Text(widget.member['email'] ?? widget.member['walletAddress'] ?? '', style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text("Unido el: $dateJoined", style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                // CARGA LABORAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Carga Laboral", style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("${wp.toStringAsFixed(0)}% - $statusText", style: TextStyle(color: workloadColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (wp / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(workloadColor),
                  ),
                ),
                const SizedBox(height: 16),
                // ESTADÍSTICA RÁPIDA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tareas Asignadas", style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("${widget.member['activeTasksCount'] ?? 0} Pendientes", style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // 🔥 2. BOTONES DE ACCIÓN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                    label: const Text("Mover Área", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _mostrarModalCambiarArea,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    icon: const Icon(Icons.person_remove_rounded, size: 18),
                    label: const Text("Despedir", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      widget.onRemoveMember(widget.member['identifier']);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("Tareas del Empleado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
          ),

          // 🔥 3. FILTROS HORIZONTALES
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: ["Todos", "PENDING", "IN_PROGRESS", "COMPLETED", "APPROVED"].map((status) {
                bool isSelected = _selectedStatus == status;
                String displayStatus = status == "PENDING" ? "Pendientes" : status == "IN_PROGRESS" ? "En Progreso" : status == "COMPLETED" ? "En Revisión" : status == "APPROVED" ? "Aprobadas" : "Todos";
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? colorScheme.primary : onSurface.withOpacity(0.1))
                      ),
                      child: Text(
                        displayStatus, 
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.8), 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 12
                        )
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 🔥 4. LISTADO DE TAREAS
          Expanded(
            child: _filteredTasks.isEmpty 
              ? UIHelper.emptyState(context: context, icon: Icons.task_alt_rounded, title: "Sin tareas", message: "No hay actividades en este estado.")
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _filteredTasks.length,
                  itemBuilder: (ctx, i) {
                    final task = _filteredTasks[i];
                    final urgency = task['urgency'] ?? 'MEDIUM';
                    final status = task['status'] ?? 'PENDING';
                    
                    Color indicatorColor = urgency == 'URGENT' || urgency == 'HIGH' ? colorScheme.error : urgency == 'MEDIUM' ? Colors.orangeAccent : onSurface.withOpacity(0.5);
                    String urgencyText = urgency == 'URGENT' ? 'URGENCIA EXTREMA' : urgency == 'HIGH' ? 'URGENCIA ALTA' : urgency == 'MEDIUM' ? 'URGENCIA MEDIA' : 'URGENCIA BAJA';
                    String statusText = status == 'PENDING' ? 'Pendiente' : status == 'IN_PROGRESS' ? 'En Progreso' : status == 'COMPLETED' ? 'En Revisión' : status == 'REWORK_REQUESTED' ? 'En Corrección' : 'Aprobada';
                    IconData statusIcon = status == 'APPROVED' ? Icons.verified_rounded : status == 'COMPLETED' ? Icons.fact_check_rounded : Icons.pending_actions_rounded;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: theme.cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(
                            task: task, isEmployer: true, 
                            onRefresh: widget.onRefreshTeam
                          )));
                        },
                        child: Container(
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: indicatorColor, width: 4))),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task['title'] ?? 'Actividad', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                    decoration: BoxDecoration(color: indicatorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: indicatorColor.withOpacity(0.3))), 
                                    child: Text(urgencyText, style: TextStyle(color: indicatorColor, fontSize: 10, fontWeight: FontWeight.bold))
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: colorScheme.primary.withOpacity(0.3))), 
                                    child: Row(
                                      children: [
                                        Icon(statusIcon, size: 12, color: colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(statusText, style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                )
          )
        ],
      ),
    );
  }
}