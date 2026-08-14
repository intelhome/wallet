import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';

class ScheduledDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> tx) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    String status = tx['status'] ?? 'PENDING';
    String executionDate = "Fecha no disponible";
    
    // Parseo de fecha real
    if (tx['executionDate'] != null) {
      try {
        DateTime dt = DateTime.parse(tx['executionDate'].toString()).toLocal();
        List<String> months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
        executionDate = "${dt.day} de ${months[dt.month - 1]}, ${dt.year}";
      } catch (e) {}
    }

    String alias = tx['receiverAlias'] ?? tx['alias'] ?? "Usuario";
    String wallet = tx['receiverAddress'] ?? tx['walletAddress'] ?? "0x0000...0000";
    String shortWallet = wallet.length > 10 ? "${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}".toUpperCase() : wallet;

    // Configuración visual por estado
    Color statusColor = status == 'COMPLETED' ? Colors.green : (status == 'FAILED' ? Colors.redAccent : Colors.orangeAccent);
    String statusText = status == 'COMPLETED' ? 'Completado' : (status == 'FAILED' ? 'Fallido' : 'Pendiente');
    IconData statusIcon = status == 'COMPLETED' ? Icons.check_circle_outline_rounded : (status == 'FAILED' ? Icons.cancel_outlined : Icons.schedule_rounded);

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
            // Ícono Superior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
              child: Icon(statusIcon, color: statusColor, size: 36),
            ),
            const SizedBox(height: 16),
            
            Text("Pago Programado", style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Píldora Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            
            // Monto y Fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(amount.toStringAsFixed(2), style: TextStyle(color: onSurface, fontSize: 56, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(width: 8),
                Text("TTC", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, color: onSurface.withOpacity(0.5), size: 14),
                const SizedBox(width: 8),
                Text("Ejecución: $executionDate", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 32),

            // Tarjeta Destinatario
                  //final userService = Provider.of<UserService>(context, listen: false);

                  FutureBuilder<Map<String, dynamic>?>(
              future: Provider.of<UserService>(context, listen: false).getUserByWallet(wallet),
              builder: (context, snapshot) {
                String realAlias = alias;
                String realEmail = "Correo no registrado";
                
                if (snapshot.hasData && snapshot.data != null) {
                  realAlias = snapshot.data!['alias'] ?? alias;
                  realEmail = snapshot.data!['email'] ?? "Correo no registrado";
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DESTINATARIO", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SmartAvatar(address: wallet, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("@$realAlias", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(realEmail, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(shortWallet, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace')),
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
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}