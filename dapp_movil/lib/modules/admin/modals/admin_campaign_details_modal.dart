import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/admin_service.dart';

class AdminCampaignDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic campaign,
    required VoidCallback onRefundSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        double raised = double.tryParse(campaign['raisedAmount']?.toString() ?? '0') ?? 0.0;
        double target = double.tryParse(campaign['targetAmount']?.toString() ?? '1') ?? 1.0;
        int donors = campaign['totalDonors'] ?? 0;
        String deadline = campaign['deadline']?.toString().substring(0, 10) ?? "N/A";
        String creator = campaign['creatorAddress'] ?? "N/A";

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
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Revisión de Soporte", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("Campaña Atascada en Escrow", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(campaign['title'] ?? 'Campaña sin nombre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface)),
              const SizedBox(height: 16),

              // DATOS DE LA CAMPAÑA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                child: Column(
                  children: [
                    _buildRow("Fondos Bloqueados:", "$raised TTC", onSurface, isAlert: true),
                    const Divider(height: 24),
                    _buildRow("Meta Original:", "$target TTC", onSurface),
                    const Divider(height: 24),
                    _buildRow("Vencimiento:", deadline, onSurface),
                    const Divider(height: 24),
                    _buildRow("Donantes Afectados:", "$donors billeteras", onSurface),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text("Creador / Beneficiario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  SmartAvatar(address: creator, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(creator, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: onSurface.withOpacity(0.7)))),
                ],
              ),
              const SizedBox(height: 32),

              // BOTÓN FORZAR REEMBOLSO
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error, 
                    foregroundColor: colorScheme.onError, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    elevation: 0
                  ),
                  onPressed: () => _executeForceRefund(context, campaign['id'], ctx, onRefundSuccess),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: const Text("Forzar Reembolso Masivo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cerrar", style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  static Widget _buildRow(String label, String value, Color onSurface, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: isAlert ? Colors.red : onSurface, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // Lógica interactiva que antes estaba en la Screen, ahora en el Modal
  static Future<void> _executeForceRefund(BuildContext context, String campaignId, BuildContext modalContext, VoidCallback onSuccess) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    TextEditingController reasonCtrl = TextEditingController();

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.gavel_rounded, color: colorScheme.error), const SizedBox(width: 10), const Text("Auditoría Escrow")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Esta acción devolverá los fondos a todas las billeteras donantes.", style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
            const SizedBox(height: 15),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Razón oficial (Quedará en auditoría)",
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            onPressed: () {
              if (reasonCtrl.text.isEmpty) {
                UIHelper.showCustomSnackbar("Debes proveer una razón", isError: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text("Confirmar Ejecución"),
          )
        ],
      ),
    );

    if (confirm != true) return;

    bool isAuth = await Provider.of<AuthCoreService>(context, listen: false).authenticateUser();
    if (!isAuth) return;

    if (!context.mounted) return;
    
    // Cierra el BottomSheet
    Navigator.pop(modalContext);

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Operación Crítica", message: "Procesando reembolsos masivos en Blockchain..."));

    final adminService = Provider.of<AdminService>(context, listen: false);
    String res = await adminService.forceRefundCampaign(campaignId, reasonCtrl.text);

    if (context.mounted) Navigator.pop(context); // Cierra Skeleton

    if (res == "Exito") {
      UIHelper.showCustomSnackbar("Reembolso forzado ejecutado con éxito.");
      onSuccess();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }
}