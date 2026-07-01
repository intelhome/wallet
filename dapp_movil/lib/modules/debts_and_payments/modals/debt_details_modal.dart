import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/share_helper.dart';

class DebtDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic debt,
    //required String myAddress,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final myAddress = authCore.publicAddress;

    double total = double.tryParse(debt['totalAmount'].toString()) ?? 0;
    double pagado = double.tryParse(debt['paidAmount'].toString()) ?? 0;
    double restante = total - pagado;
    
    String status = debt['status'] ?? 'UNKNOWN';
    String reason = debt['reason'] ?? 'Sin motivo';
    String debtor = debt['debtorAddress'] ?? '';
    String creditor = debt['creditorAddress'] ?? '';
    
    bool soyDeudor = debtor.toLowerCase() == myAddress.toLowerCase();
    bool isCompleted = status == "COMPLETED";
    bool isRejected = status == "REJECTED";

    Color statusColor = isCompleted ? Colors.green : (isRejected ? colorScheme.error : Colors.orange);
    IconData statusIcon = isCompleted ? Icons.check_circle_rounded : (isRejected ? Icons.cancel_rounded : Icons.pending_actions_rounded);
    String statusText = isCompleted ? "Completada" : (isRejected ? "Rechazada" : (status == "PENDING_APPROVAL" ? "Por Aceptar" : "Activa / Pendiente"));

    String fecha = "Desconocida";
    if (debt['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(debt['createdAt'].toString()).toLocal();
        fecha = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch(e){}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 16),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            
            CircleAvatar(radius: 32, backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor, size: 32)),
            const SizedBox(height: 16),
            
            Text(reason, style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text("Estado: $statusText", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 24),

            // Tarjeta de progreso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total:", style: TextStyle(color: onSurface.withOpacity(0.6))),
                      Text("$total TTC", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Pagado:", style: TextStyle(color: onSurface.withOpacity(0.6))),
                      Text("$pagado TTC", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Restante:", style: TextStyle(color: onSurface.withOpacity(0.6))),
                      Text("$restante TTC", style: TextStyle(color: isCompleted ? Colors.green : colorScheme.error, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total > 0 ? (pagado / total) : 0,
                    backgroundColor: onSurface.withOpacity(0.1),
                    color: Colors.green,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoRow("Deudor", debtor, onSurface, true),
            _buildInfoRow("Acreedor", creditor, onSurface, true),
            _buildInfoRow("Fecha Creación", fecha, onSurface, false),
            
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text("Exportar PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ShareHelper.generarYCompartirPDFDeuda(context, debt, myAddress);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: onSurface, side: BorderSide(color: onSurface.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value, Color onSurface, bool isWallet) {
    String displayValue = value;
    if (isWallet && value.length > 20) {
      displayValue = "${value.substring(0, 8)}...${value.substring(value.length - 6)}";
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.6))),
          Row(
            children: [
              if (isWallet) ...[SmartAvatar(address: value, size: 18), const SizedBox(width: 6)],
              Text(displayValue, style: TextStyle(color: onSurface, fontFamily: isWallet ? 'monospace' : null, fontWeight: FontWeight.bold)),
              if (isWallet) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: value));
                    UIHelper.showCustomSnackbar("Copiado");
                  },
                  child: const Icon(Icons.copy_rounded, size: 16, color: Colors.blueAccent),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
}