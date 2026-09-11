import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/share_helper.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class AdminTransactionDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic tx,
    required bool isWhaleAlert,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
        String date = tx['timestamp']?.toString().substring(0, 16).replaceAll("T", " ") ?? "Desconocida";
        String status = tx['status'] ?? "UNKNOWN";
        String type = tx['txType'] ?? "TRANSFER";

        Color alertColor = isWhaleAlert ? Colors.blue : colorScheme.error;
        IconData alertIcon = isWhaleAlert ? Icons.water_drop_rounded : Icons.gpp_bad_rounded;
        String alertTitle = isWhaleAlert ? "Alerta de Alto Volumen" : "Transacción Fallida";

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 12
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              
              // CABECERA DE ALERTA
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: alertColor.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(alertIcon, color: alertColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alertTitle, style: TextStyle(color: alertColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Tipo de op: $type", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // MONTO Y ESTADO
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text("Monto Involucrado", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 8),
                    Text("${amount.toStringAsFixed(2)} TTC", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: (status == 'COMPLETED' ? Colors.green : colorScheme.error).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("Estado final: $status", style: TextStyle(color: status == 'COMPLETED' ? Colors.green : colorScheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // DETALLES TÉCNICOS
              Text("Detalles de Enrutamiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
              const SizedBox(height: 12),
              _buildDetailRow("Fecha de red", date, onSurface),
              _buildDetailRow("Remitente", tx['senderAddress'] ?? 'N/A', onSurface, isWallet: true),
              _buildDetailRow("Destinatario", tx['receiverAddress'] ?? 'N/A', onSurface, isWallet: true),
              
              const SizedBox(height: 24),
              Text("Identificador Criptográfico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
              const SizedBox(height: 8),
              
              // HASH CON BOTÓN DE COPIAR
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tx['txHash'] ?? ''));
                  UIHelper.showCustomSnackbar("Hash copiado al portapapeles");
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.1))),
                  child: Row(
                    children: [
                      Expanded(child: Text(tx['txHash'] ?? 'N/A', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: onSurface.withOpacity(0.8)))),
                      const SizedBox(width: 12),
                      Icon(Icons.copy_rounded, color: onSurface.withOpacity(0.5), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // BOTONES DE ACCIÓN (Compartir PDF y Cerrar)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final adminWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress;
                        ShareHelper.compartirTransaccionPDF(context, tx, adminWallet); // Generamos el PDF de auditoría
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text("Exportar PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        foregroundColor: colorScheme.onPrimary, 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                        elevation: 0
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  static Widget _buildDetailRow(String label, String value, Color onSurface, {bool isWallet = false}) {
    String displayValue = value;
    if (isWallet && value.length > 25) {
      displayValue = "${value.substring(0, 8)}...${value.substring(value.length - 4)}";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold))),
          if (isWallet && value.startsWith('0x')) ...[
            SmartAvatar(address: value, size: 24),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(displayValue, style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: isWallet ? 'monospace' : null))),
        ],
      ),
    );
  }
}