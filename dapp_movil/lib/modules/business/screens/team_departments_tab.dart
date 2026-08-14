import 'package:flutter/material.dart';
import '../../../core/helpers/ui_helper.dart';
import '../modals/create_department_modal.dart';
import '../modals/department_details_modal.dart';

class TeamDepartmentsTab extends StatelessWidget {
  final List<dynamic> departments;
  final List<dynamic> activeTeam;
  final VoidCallback onRefresh;

  const TeamDepartmentsTab({
    super.key,
    required this.departments,
    required this.activeTeam,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreateDepartmentModal.show(context, onRefresh),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: departments.isEmpty
          ? UIHelper.emptyState(context: context, icon: Icons.account_tree_rounded, title: "Sin Areas", message: "Crea departamentos para agrupar a tus empleados.")
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: departments.length,
              itemBuilder: (ctx, i) {
                var dept = departments[i];
                List wallets = dept['memberWallets'] ?? [];
                double allocated = double.tryParse(dept['allocatedBudget']?.toString() ?? '0') ?? 0.0;
                double used = double.tryParse(dept['usedBudget']?.toString() ?? '0') ?? 0.0; 
                double remaining = allocated - used;
                double progress = allocated > 0 ? (used / allocated).clamp(0.0, 1.0) : 0.0;
                
                IconData iconData = Icons.domain_rounded;
                String deptName = dept['name'].toString().toLowerCase();
                if (deptName.contains('tecnologia') || deptName.contains('ti') || deptName.contains('dev')) iconData = Icons.computer_rounded;
                if (deptName.contains('venta') || deptName.contains('sales')) iconData = Icons.trending_up_rounded;
                if (deptName.contains('recurso') || deptName.contains('hr')) iconData = Icons.people_alt_rounded;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => DepartmentDetailsModal.show(context, dept, activeTeam, onRefresh),
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
                                child: Icon(iconData, color: colorScheme.primary, size: 28),
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
                                onPressed: () => DepartmentDetailsModal.show(context, dept, activeTeam, onRefresh),
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
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
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
    );
  }
}