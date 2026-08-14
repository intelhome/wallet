import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/business/modals/create_task_modal.dart';
import 'package:dapp_movil/modules/business/services/business_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
            
            // CABECERA (AVATAR, ALIAS Y ROL)
            Center(child: SmartAvatar(address: wallet.isNotEmpty ? wallet : member['identifier'], size: 80)),
            const SizedBox(height: 16),
            Text("@$alias", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface)),
            const SizedBox(height: 4),
            Text(member['role'] == 'ADMIN' ? "Administrador de la Empresa" : "Desarrollador Blockchain Senior", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 12),
            
            // BADGE GASLESS
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text("Gasless Activado", style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // DATOS PERSONALES (CARD AGRUPADA)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: onSurface.withOpacity(0.05))
              ),
              child: Column(
                children: [
                  _buildMockupRow(context, Icons.badge_rounded, "Cédula", member['cedula'] ?? "0987654321", false),
                  Divider(color: onSurface.withOpacity(0.05), height: 1),
                  _buildMockupRow(context, Icons.phone_android_rounded, "Celular", member['phoneNumber'] ?? "+593 98 765 4321", false),
                  Divider(color: onSurface.withOpacity(0.05), height: 1),
                  _buildMockupRow(context, Icons.email_rounded, "Correo", member['email'] ?? "bryanf2@ttc.com", false),
                  Divider(color: onSurface.withOpacity(0.05), height: 1),
                  _buildMockupRow(context, Icons.account_balance_wallet_rounded, "Billetera TTC", wallet.isNotEmpty ? "${wallet.substring(0,6)}...${wallet.substring(wallet.length-4)}".toUpperCase() : "N/A", true, wallet),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BOTÓN CHAT (ESTILO MOCKUP)
            // SizedBox(
            //   height: 56,
            //   child: ElevatedButton.icon(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFFBAC3FF), 
            //       foregroundColor: const Color(0xFF00218d),
            //       elevation: 0,
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
            //     ),
            //     icon: const Icon(Icons.send_rounded),
            //     label: const Text("Enviar Mensaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            //     onPressed: () {
            //       Navigator.pop(ctx);
            //       if (wallet.isNotEmpty) {
            //         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
            //           address: wallet,
            //           alias: alias,
            //         )));
            //       }
            //     },
            //   ),
            // ),
            // BOTONES DE ACCIÓN RÁPIDA (MOCKUP M3)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.primary),
                        foregroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text("Mensaje", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (wallet.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(address: wallet, alias: alias)));
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: const Text("Asignar Tarea", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        // 🔥 Obtenemos el equipo actual (necesario para el Modal)
                        final bService = Provider.of<BusinessService>(context, listen: false);
                        List<dynamic> activeTeam = []; 
                        List<dynamic> departments = [];
                        try {
                          activeTeam = await bService.getTeamMembers(); 
                          departments = await bService.getDepartments(); 
                        } catch(e) {}
                        
                        if (!context.mounted) return;
                        
                        // Abrimos el modal con los datos bloqueados para este empleado
                        CreateTaskModal.show(
                          context, activeTeam, departments, () {},
                          initialAssigneeAlias: alias, // Pasa el alias del usuario actual
                          lockAssignee: true,          // Lo bloquea en la UI
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 10),
          ],
        ),
      ),
    );
  }

  static Widget _buildMockupRow(BuildContext context, IconData icon, String titulo, String valor, bool showCopy, [String fullValue = ""]) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: onSurface.withOpacity(0.7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: onSurface.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface)),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: Icon(Icons.copy_rounded, color: onSurface.withOpacity(0.5), size: 20),
              onPressed: () {
                if (fullValue.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: fullValue));
                  UIHelper.showCustomSnackbar("Billetera copiada al portapapeles");
                }
              },
            ),
        ],
      ),
    );
  }
}