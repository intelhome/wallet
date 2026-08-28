import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/business_groups/modals/add_business_goal_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/add_business_resource_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/add_goal_progress_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/edit_business_goal_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/edit_business_resource_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/view_all_business_lists_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/view_business_goal_details_modal.dart';
import 'package:dapp_movil/modules/business_groups/modals/view_business_resource_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';

class BusinessGroupResourcesTab extends StatefulWidget {
  final dynamic group;
  final bool isEmployer;

  const BusinessGroupResourcesTab({super.key, required this.group, required this.isEmployer});

  @override
  State<BusinessGroupResourcesTab> createState() => _BusinessGroupResourcesTabState();
}

class _BusinessGroupResourcesTabState extends State<BusinessGroupResourcesTab> {
  bool _isFabExpanded = false;

  void _onSuccessUpdate() {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final myWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();

    List<dynamic> allResources = widget.group['resources'] ?? [];
    List<dynamic> allGoals = widget.group['goals'] ?? [];

    List<dynamic> topGoals = allGoals.take(3).toList();
    List<dynamic> topResources = allResources.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ================= KPIs / METAS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Metas Grupales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
            ]
          ),
          const SizedBox(height: 8),
          if (topGoals.isEmpty)
            Text("No se han definido metas para este equipo.", style: TextStyle(color: onSurface.withOpacity(0.5))),
          ...topGoals.map((goal) {
            double target = (goal['targetValue'] as num).toDouble();
            double current = (goal['currentValue'] as num).toDouble();
            double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
            bool isCompleted = current >= target;
            bool canEdit = widget.isEmployer; 

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => ViewBusinessGoalDetailsModal.show(context, widget.group['id'], goal, _onSuccessUpdate),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(goal['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          if (canEdit)
                           PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                              color: theme.cardColor,
                              onSelected: (val) async {
                                if (val == 'EDIT') {
                                  EditBusinessGoalModal.show(context, widget.group['id'], goal, _onSuccessUpdate);
                                } else if (val == 'DELETE') {
                                  bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Eliminar", mensaje: "¿Eliminar objetivo?", textoConfirmar: "Eliminar", colorConfirmar: colorScheme.error);
                                  if (confirm == true) {
                                    final res = await Provider.of<BusinessGroupService>(context, listen: false).deleteGoal(widget.group['id'], goal['id']);
                                    if (res == "SUCCESS") _onSuccessUpdate();
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: "EDIT", child: Text("Editar")),
                                PopupMenuItem(value: "DELETE", child: Text("Eliminar", style: TextStyle(color: colorScheme.error))),
                              ],
                            )
                        ],
                      ),
                      Text("${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ${goal['unit']}", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: onSurface.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? colorScheme.tertiary : colorScheme.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        if (allGoals.length > 3)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: () => ViewAllBusinessListsModal.showGoals(context, widget.group['id'], allGoals, widget.isEmployer, _onSuccessUpdate),
              child: Text("Ver los ${allGoals.length} Objetivos", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            
          const SizedBox(height: 24),
          Divider(color: onSurface.withOpacity(0.05)),
          const SizedBox(height: 16),

          // ================= RECURSOS Y LINKS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recursos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface))
            ],
          ),
          const SizedBox(height: 8),
          if (topResources.isEmpty)
            Text("El área no tiene recursos fijados.", style: TextStyle(color: onSurface.withOpacity(0.5))),
          ...topResources.map((res) {
            bool isLink = res['type'] == 'LINK';
            bool iAddedIt = res['addedBy']?.toString().toLowerCase() == myWallet;
            bool canEdit = widget.isEmployer || iAddedIt;

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
                title: Text(res['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Por: ${res['addedBy']?.toString().substring(0,6) ?? 'Admin'}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              trailing: canEdit ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                    color: theme.cardColor,
                    onSelected: (val) async {
                      if (val == 'EDIT') {
                        EditBusinessResourceModal.show(context, widget.group['id'], res, _onSuccessUpdate);
                      } else if (val == 'DELETE') {
                        bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Eliminar", mensaje: "¿Eliminar recurso?", textoConfirmar: "Eliminar", colorConfirmar: colorScheme.error);
                        if (confirm == true) {
                          final resp = await Provider.of<BusinessGroupService>(context, listen: false).deleteResource(widget.group['id'], res['id']);
                          if (resp == "SUCCESS") _onSuccessUpdate();
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: "EDIT", child: Text("Editar")),
                      PopupMenuItem(value: "DELETE", child: Text("Eliminar", style: TextStyle(color: colorScheme.error))),
                    ],
                  ) : null,
                onTap: () => ViewBusinessResourceModal.show(context, res),
              ),
            );
          }),
         if (allResources.length > 3)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.secondary,
                side: BorderSide(color: colorScheme.secondary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: () => ViewAllBusinessListsModal.showResources(context, widget.group['id'], allResources, widget.isEmployer, _onSuccessUpdate),
              child: Text("Ver los ${allResources.length} Recursos", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),

      // 🔥 FAB ANIMADO TIPO TASK ADMIN SCREEN 🔥
     floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              heroTag: "btn_new_goal",
              // 🔥 FIX: Color sólido en lugar de usar withOpacity(0.1)
              backgroundColor: theme.cardColor, 
              foregroundColor: colorScheme.primary,
              elevation: 4, // Le damos un poco de elevación para que no se pierda en el fondo
              onPressed: () {
                setState(() => _isFabExpanded = false);
                AddBusinessGoalModal.show(context, widget.group['id'], _onSuccessUpdate);
              },
              icon: const Icon(Icons.add_chart_rounded),
              label: const Text("Nuevo Objetivo", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: "btn_new_resource",
              // 🔥 FIX: Color sólido en lugar de usar withOpacity(0.1)
              backgroundColor: theme.cardColor,
              foregroundColor: colorScheme.secondary,
              elevation: 4,
              onPressed: () {
                setState(() => _isFabExpanded = false);
                AddBusinessResourceModal.show(context, widget.group['id'], _onSuccessUpdate);
              },
              icon: const Icon(Icons.add_link_rounded),
              label: const Text("Nuevo Recurso", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
          
          FloatingActionButton(
            heroTag: "btn_main_toggle_resources",
            backgroundColor: _isFabExpanded ? onSurface.withOpacity(0.2) : colorScheme.primary,
            foregroundColor: _isFabExpanded ? onSurface : colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: child.key == const ValueKey('icon1') ? Tween<double>(begin: 1, end: 0.75).animate(anim) : Tween<double>(begin: 0.75, end: 1).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _isFabExpanded
                  ? const Icon(Icons.close_rounded, key: ValueKey('icon1'))
                  : const Icon(Icons.add_rounded, key: ValueKey('icon2')),
            ),
          ),
        ],
      ),
    );
  }
}