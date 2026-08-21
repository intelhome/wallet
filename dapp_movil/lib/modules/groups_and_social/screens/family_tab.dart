import 'package:flutter/material.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/route_helper.dart';
import '../../chat_and_social/screens/chat_room_screen.dart';
import '../modals/family_invite_details_modal.dart';

class FamilyTab extends StatelessWidget {
  final List<dynamic> familyMembers;
  final List<dynamic> familyInvites;
  final bool cargando;
  final VoidCallback onRefresh;

  const FamilyTab({super.key, required this.familyMembers, required this.familyInvites, required this.cargando, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    if (cargando) return UIHelper.buildSkeletonList(context, itemCount: 4);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (familyInvites.isNotEmpty) ...[
            Text("Solicitudes Familiares", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            ...familyInvites.map((inv) => Container(
              decoration: BoxDecoration(color: colorScheme.tertiary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.tertiary, width: 0.5)),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: colorScheme.tertiary, child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 20)),
                title: Text("@${inv['senderAlias'] ?? 'Usuario'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Te ha enviado una invitación familiar"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => FamilyInviteDetailsModal.show(context, inv, onRefresh),
                  child: const Text("Revisar"),
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
          Text("Círculo de Confianza", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: onSurface)),
          const SizedBox(height: 12),
          if (familyMembers.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 40.0), child: UIHelper.emptyState(context: context, icon: Icons.diversity_1_rounded, title: "Núcleo Vacío", message: "Vincula a tus familiares para enviar dinero y chatear con seguridad."))
          else
            ...familyMembers.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.05))),
              child: ListTile(
                leading: SmartAvatar(address: m['wallet'] ?? '', size: 48),
                title: Text(m['alias'] ?? "Familiar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text("Cédula: ${m['cedula'] ?? 'N/A'}", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                trailing: IconButton(icon: Icon(Icons.chat_bubble, color: colorScheme.primary, size: 22), onPressed: () => Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(alias: m['alias'] ?? 'Familiar', address: m['wallet'] ?? '')))),
              ),
            )),
        ],
      ),
    );
  }
}