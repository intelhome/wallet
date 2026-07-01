import 'package:flutter/material.dart';
import '../../../core/services/smart_avatar.dart';
import '../../chat_and_social/screens/chat_room_screen.dart'; // Ajusta tu ruta del chat

class TeamMemberDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> member) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    String wallet = member['wallet'] ?? "";
    String alias = member['alias'] ?? "Usuario";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            
            // CABECERA (AVATAR Y ALIAS)
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  SmartAvatar(address: wallet.isNotEmpty ? wallet : member['identifier'], size: 80),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 3)),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("@$alias", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(member['role'] == 'ADMIN' ? "Administrador" : "Cajero", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // DATOS PERSONALES
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildFilaDato(Icons.badge_rounded, "Cédula", member['cedula'] ?? "No disponible"),
                  const Divider(),
                  _buildFilaDato(Icons.phone_rounded, "Celular", member['phoneNumber'] ?? "No disponible"),
                  const Divider(),
                  _buildFilaDato(Icons.email_rounded, "Correo", member['email'] ?? "No disponible"),
                  const Divider(),
                  _buildFilaDato(Icons.wallet_rounded, "Billetera", wallet.isNotEmpty ? "${wallet.substring(0,6)}...${wallet.substring(wallet.length-4)}" : "N/A"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BOTÓN CHAT
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text("Enviar Mensaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (wallet.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
                      address: wallet, // ✅ Corregido a 'address'
                      alias: alias,
                    )));
                  }
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 10),
          ],
        ),
      ),
    );
  }

  static Widget _buildFilaDato(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const Spacer(),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}