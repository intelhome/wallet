import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/business_groups/modals/view_business_goal_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';
import 'add_goal_progress_modal.dart';

class ViewAllBusinessListsModal {
  static void showGoals(BuildContext context, String groupId, List<dynamic> goals, bool isEmployer, VoidCallback onSuccess) {
    _showList(context, "Todos los Objetivos", goals, isEmployer, groupId, true, onSuccess);
  }

  static void showResources(BuildContext context, String groupId, List<dynamic> resources, bool isEmployer, VoidCallback onSuccess) {
    _showList(context, "Todos los Recursos", resources, isEmployer, groupId, false, onSuccess);
  }

  static void _showList(BuildContext context, String title, List<dynamic> items, bool isEmployer, String groupId, bool isGoal, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;
        final myWallet = Provider.of<AuthCoreService>(ctx, listen: false).publicAddress.toLowerCase();

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                  IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text("Lista vacía", style: TextStyle(color: onSurface.withOpacity(0.5))))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          bool iAddedIt = item['addedBy']?.toString().toLowerCase() == myWallet;
                          bool canEdit = isEmployer || iAddedIt;

                          if (isGoal) {
                            double target = (item['targetValue'] as num).toDouble();
                            double current = (item['currentValue'] as num).toDouble();
                            double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
                            bool isCompleted = current >= target;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: theme.cardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => ViewBusinessGoalDetailsModal.show(ctx, groupId, item, onSuccess),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                          if (canEdit)
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                                              color: theme.cardColor,
                                              onSelected: (val) async {
                                                if (val == 'DELETE') {
                                                  bool? confirm = await UIHelper.mostrarConfirmacion(context: ctx, titulo: "Eliminar", mensaje: "¿Eliminar objetivo?", textoConfirmar: "Eliminar", colorConfirmar: colorScheme.error);
                                                  if (confirm == true) {
                                                    final res = await Provider.of<BusinessGroupService>(ctx, listen: false).deleteGoal(groupId, item['id']);
                                                    if (res == "SUCCESS") { Navigator.pop(ctx); onSuccess(); }
                                                  }
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                const PopupMenuItem(value: "EDIT", child: Text("Editar (Próximamente)")),
                                                PopupMenuItem(value: "DELETE", child: Text("Eliminar", style: TextStyle(color: colorScheme.error))),
                                              ],
                                            )
                                        ],
                                      ),
                                      Text("${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ${item['unit']}", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: onSurface.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? colorScheme.tertiary : colorScheme.primary)),
                                      ),
                                      const SizedBox(height: 12),
                                      if (!isCompleted)
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.primary, side: BorderSide(color: colorScheme.primary.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          icon: const Icon(Icons.add_task_rounded, size: 18),
                                          label: const Text("Registrar Avance"),
                                          onPressed: () => AddGoalProgressModal.show(ctx, groupId, item['id'], item['unit'], onSuccess),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            bool isLink = item['type'] == 'LINK';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: theme.cardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: onSurface.withOpacity(0.05))),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(isLink ? Icons.link_rounded : Icons.description_rounded, color: colorScheme.secondary),
                                ),
                                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Agregado por: ${item['addedBy']?.toString().substring(0,6) ?? 'Admin'}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                                trailing: canEdit ? PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                                  color: theme.cardColor,
                                  onSelected: (val) async {
                                    if (val == 'DELETE') {
                                      bool? confirm = await UIHelper.mostrarConfirmacion(context: ctx, titulo: "Eliminar", mensaje: "¿Eliminar recurso?", textoConfirmar: "Eliminar", colorConfirmar: colorScheme.error);
                                      if (confirm == true) {
                                        final res = await Provider.of<BusinessGroupService>(ctx, listen: false).deleteResource(groupId, item['id']);
                                        if (res == "SUCCESS") { Navigator.pop(ctx); onSuccess(); }
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: "EDIT", child: Text("Editar (Próximamente)")),
                                    PopupMenuItem(value: "DELETE", child: Text("Eliminar", style: TextStyle(color: colorScheme.error))),
                                  ],
                                ) : null,
                                onTap: () async {
                                  if (isLink && item['urlOrHash'] != null) {
                                    String finalUrl = item['urlOrHash'].toString().trim();
                                    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) finalUrl = 'https://$finalUrl';
                                    try { await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.platformDefault); } catch (e) { UIHelper.showCustomSnackbar("Error al abrir", isError: true); }
                                  }
                                },
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      }
    );
  }
}