import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_task_service.dart';
import '../modals/invite_member_modal.dart';
import '../modals/team_member_details_modal.dart';

class TeamMembersTab extends StatelessWidget {
  final List<dynamic> activeTeam;
  final List<dynamic> pendingTeam;
  final VoidCallback onRefresh;
  final Function(String) onRemoveMember;

  const TeamMembersTab({
    super.key,
    required this.activeTeam,
    required this.pendingTeam,
    required this.onRefresh,
    required this.onRemoveMember,
  });

  Widget _buildWorkloadBar(BuildContext context, String wallet, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<BusinessTaskService>(context, listen: false).getUserWorkload(wallet),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 6, child: LinearProgressIndicator());
        
        final data = snap.data!;
        final status = data['workloadStatus'];
        double percentage = (data['workloadPercentage'] as num).toDouble();
        
        Color color = colorScheme.primary;
        String statusText = "Estable";

        if (status == 'OPTIMAL') { 
          color = colorScheme.tertiary; 
          statusText = "Optimo"; 
        }
        if (status == 'OVERLOADED') { 
          color = colorScheme.error; 
          statusText = "Ocupado"; 
        }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => InviteMemberModal.show(context, onRefresh),
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Miembro", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary, 
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text("Usuarios Activos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          activeTeam.isEmpty
            ? UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin equipo", message: "Aun no tienes empleados activos.")
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
                                    Text(member['role'] ?? "EMPLEADO", style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.person_remove_rounded, color: colorScheme.onSurface.withOpacity(0.3)),
                                onPressed: () => onRemoveMember(member['identifier'])
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildWorkloadBar(context, member['wallet'] ?? "", colorScheme),
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
                      onPressed: () => onRemoveMember(identifier),
                      child: const Text("Cancelar", style: TextStyle(fontSize: 12)),
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