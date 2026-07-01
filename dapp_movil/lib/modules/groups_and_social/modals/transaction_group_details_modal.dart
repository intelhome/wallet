import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/helpers/share_helper.dart';

class TransactionGroupDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic tx,
    required String vaultAddress,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // 🔥 INYECCIÓN DEL TEMA M3 🔥
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;
        final cardColor = theme.cardColor;

        // Extraer datos seguros
        bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress.toLowerCase();
        String tipoRaw = tx['txType']?.toString() ?? "UNKNOWN";
        String estado = tx['status']?.toString() ?? "PENDING";
        String monto = tx['amount']?.toString() ?? "0.00";
        String hash = tx['txHash']?.toString() ?? "N/A";
        String sender = tx['senderAddress']?.toString() ?? "N/A";
        String receiver = tx['receiverAddress']?.toString() ?? "N/A";
        
        String fechaRaw = tx['timestamp']?.toString() ?? "";
        String fechaFormat = fechaRaw.length >= 16 ? fechaRaw.substring(0, 16).replaceAll("T", " ") : fechaRaw;

        // Adaptamos colores al tema
        Color successColor = Colors.green.shade600;
        Color pendingColor = Colors.orange.shade600;
        Color colorEstado = estado == "COMPLETED" ? successColor : pendingColor;
        Color colorMonto = esIngreso ? successColor : colorScheme.error;
        String signo = esIngreso ? "+" : "-";

        return Container(
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔥 DRAG HANDLE M3
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              
              CircleAvatar(
                radius: 32,
                backgroundColor: colorMonto.withOpacity(0.1),
                child: Icon(esIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: colorMonto, size: 32),
              ),
              const SizedBox(height: 16),
              
              Text(
                "$signo$monto TTC",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorMonto),
              ),
              const SizedBox(height: 4),
              Text(
                esIngreso ? "Ingreso a Bóveda" : "Pago desde Bóveda",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: onSurfaceColor.withOpacity(0.7)),
              ),
              
              // 🔥 PÍLDORA DE ESTADO M3
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                child: Text(estado == "COMPLETED" ? "Completada Exitosamente" : "Pendiente", style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              
              Divider(color: onSurfaceColor.withOpacity(0.1)),
              const SizedBox(height: 12),

              _buildCopyableRow(ctx, "Fecha", fechaFormat, onSurfaceColor, false),
              _buildCopyableRow(ctx, "De", sender, onSurfaceColor, true),
              _buildCopyableRow(ctx, "Para", receiver, onSurfaceColor, true),
              _buildCopyableRow(ctx, "Tx Hash", hash, onSurfaceColor, true),
              _buildCopyableRow(ctx, "Red", "Avalanche L2 (Web3)", onSurfaceColor, false),

              const SizedBox(height: 24),

              // BOTONES DE ACCIÓN M3
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text("Compartir", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ShareHelper.compartirTransaccionPDF(context, tx, vaultAddress);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurfaceColor,
                        side: BorderSide(color: onSurfaceColor.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  // Helper local para mantener el archivo independiente
  static Widget _buildCopyableRow(BuildContext context, String label, String value, Color onSurface, bool copyable) {
    String displayValue = value;
    if (value.length > 25 && value.startsWith('0x')) {
      displayValue = "${value.substring(0, 10)}...${value.substring(value.length - 8)}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
          Row(
            children: [
              Text(displayValue, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14)),
              if (copyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: value));
                    UIHelper.showCustomSnackbar("¡Copiado al portapapeles!", isError: false);
                  },
                  child: Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}