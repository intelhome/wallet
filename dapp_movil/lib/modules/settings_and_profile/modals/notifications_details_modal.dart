import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';

class NotificationsDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> notif) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    String title = notif['title'] ?? 'Notificación';
    String body = notif['body'] ?? '';
    
    // Parseo de fecha
    String dateStr = "Fecha desconocida";
    if (notif['timestamp'] != null) {
      try {
        DateTime dt = DateTime.parse(notif['timestamp'].toString()).toLocal();
        List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        dateStr = "${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {}
    }

    // Extracción de datos del usuario si existen en el payload de la notificación
    String? wallet = notif['relatedAddress'] ?? notif['walletAddress'] ?? notif['senderAddress'];
    String? alias = notif['relatedAlias'] ?? notif['alias'] ?? notif['senderAlias'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 32),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF4361EE).withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Color(0xFFBAC3FF), size: 36),
            ),
            const SizedBox(height: 16),
            
            Text(title, style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            
            // Tarjeta de Usuario Opcional (Si la notificación está vinculada a alguien)
            if (wallet != null && wallet.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    SmartAvatar(address: wallet, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alias != null ? "@$alias" : "Usuario", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(wallet.length > 10 ? "${wallet.substring(0, 10)}...${wallet.substring(wallet.length - 4)}" : wallet, 
                                style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace')
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: wallet));
                                  UIHelper.showCustomSnackbar("Billetera copiada");
                                },
                                child: Icon(Icons.copy_rounded, color: onSurface.withOpacity(0.5), size: 14),
                              )
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(body, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 15, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            Text(dateStr, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBAC3FF),
                  foregroundColor: const Color(0xFF00218d),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}