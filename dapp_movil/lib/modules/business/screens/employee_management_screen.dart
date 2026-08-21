import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_service.dart';
import '../modals/invite_member_modal.dart';
import 'team_member_dashboard_screen.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<dynamic> _activeTeam = [];
  List<dynamic> _pendingTeam = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    setState(() => _isLoading = true);
    final bService = Provider.of<BusinessService>(context, listen: false);
    
    // Obtenemos los datos enriquecidos con tareas y carga laboral
    final data = await bService.getTeamDashboardAnalytics();
    
    if (mounted) {
      setState(() {
        _activeTeam = data.where((m) => m['status'] == 'ACCEPTED').toList();
        _pendingTeam = data.where((m) => m['status'] != 'ACCEPTED').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(String identifier) async {
    bool? confirm = await UIHelper.mostrarConfirmacion(
      context: context, 
      titulo: "Eliminar Usuario", 
      mensaje: "¿Estás seguro de que deseas eliminar o cancelar la invitación a este usuario?", 
      textoConfirmar: "Eliminar", 
      colorConfirmar: Theme.of(context).colorScheme.error
    );
    if (confirm != true) return;

    final bService = Provider.of<BusinessService>(context, listen: false);
    UIHelper.showCustomSnackbar("Procesando...", isError: false);
    String res = await bService.removeTeamMember(identifier);
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Usuario eliminado con éxito.");
      _loadTeam();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  Widget _buildWorkloadIndicator(dynamic member, ColorScheme colorScheme) {
    final status = member['workloadStatus'] ?? 'LOW';
    double percentage = double.tryParse(member['workloadPercentage']?.toString() ?? '0') ?? 0.0;
    
    Color color = colorScheme.primary;
    String statusText = "Estable";

    if (status == 'OPTIMAL') { color = colorScheme.tertiary; statusText = "Óptimo"; }
    if (status == 'OVERLOADED') { color = colorScheme.error; statusText = "Sobrecargado"; }

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
                Text("Carga laboral", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 12)),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Gestión de Personal", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => InviteMemberModal.show(context, _loadTeam),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Invitar", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary, 
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text("Empleados Activos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 16),
              _activeTeam.isEmpty
                ? UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin equipo", message: "Aún no tienes empleados activos.")
                : Column(
                    children: _activeTeam.map((member) => Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // 🔥 Abre el dashboard completo del empleado
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TeamMemberDashboardScreen(
                            member: member, 
                            onRemoveMember: _removeMember,
                            onRefreshTeam: _loadTeam
                          )));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SmartAvatar(address: member['walletAddress'] ?? member['identifier'], size: 50),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(member['alias'] ?? member['identifier'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Text(member['role'] ?? "EMPLEADO", style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.3)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildWorkloadIndicator(member, colorScheme),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
              const SizedBox(height: 32),
              
              Text("Invitaciones Pendientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 16),
              ..._pendingTeam.map((member) {
                String identifier = member['identifier'] ?? '?';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: theme.cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: onSurface.withOpacity(0.05),
                          child: Text(identifier.isNotEmpty ? identifier[0].toUpperCase() : "?", style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(identifier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text("En espera de aceptación", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel_rounded, color: colorScheme.error.withOpacity(0.8)),
                          onPressed: () => _removeMember(identifier),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
    );
  }
}