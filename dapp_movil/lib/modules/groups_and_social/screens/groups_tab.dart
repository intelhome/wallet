import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/helpers/route_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/group_social_service.dart';
import '../modals/group_modals.dart';
import '../screens/group_details_screen.dart';

class GroupsTab extends StatelessWidget {
  final List<dynamic> grupos;
  final List<dynamic> contactos;
  final bool cargando;
  final VoidCallback onRefresh;

  const GroupsTab({super.key, required this.grupos, required this.contactos, required this.cargando, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    if (cargando) return UIHelper.buildSkeletonList(context, itemCount: 6);
    if (grupos.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Directorio Vacío", message: "Aún no tienes grupos comunes.", actionLabel: "Crear mi primer grupo", onAction: () => GroupModals.showCreate(context, contactosDisponibles: contactos, onSuccess: onRefresh));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), 
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        final g = grupos[index];
        bool isCreator = g['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, RouteHelper.slideUpRoute(GroupDetailsScreen(groupData: g)));
            onRefresh(); 
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(radius: 24, backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.diversity_3_rounded, color: colorScheme.primary)),
              title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(isCreator ? "Eres el administrador" : "Creado por @${g['creatorAlias']}", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) async {
                  if (val == "EDIT") GroupModals.showEdit(context, id: g['id'], nombreActual: g['name'], onSuccess: onRefresh);
                  else if (val == "DELETE") GroupModals.showDeleteConfirm(context, id: g['id'], onSuccess: onRefresh);
                  else if (val == "LEAVE") { await groupService.rejectGroupInvite(g['id']); onRefresh(); }
                },
                itemBuilder: (ctx) => [
                  if (isCreator) PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: onSurface.withOpacity(0.5), size: 20), const SizedBox(width: 10), const Text("Editar Nombre")])),
                  if (isCreator) PopupMenuItem(value: "DELETE", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), Text("Eliminar Grupo", style: TextStyle(color: colorScheme.error))])),
                  if (!isCreator) PopupMenuItem(value: "LEAVE", child: Row(children: [Icon(Icons.exit_to_app_rounded, color: colorScheme.tertiary, size: 20), const SizedBox(width: 10), Text("Abandonar Grupo", style: TextStyle(color: colorScheme.tertiary))])),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}