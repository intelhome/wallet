import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/transaction_skeleton.dart';

class VaultDetailModal {
  static void show({
    required BuildContext context,
    //required BlockchainService service,
    required dynamic vault,
    required VoidCallback onUpdate,
  }) {

    final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    
    BuildContext rootContext = context;
    bool isProcessing = false;

    bool isFlexible = vault['vaultType'] == 'FLEXIBLE';
    double balance = double.parse(vault['currentBalance'].toString());
    
    DateTime? unlockDate = !isFlexible && vault['unlockDate'] != null ? DateTime.parse(vault['unlockDate']) : null;
    bool isLocked = !isFlexible && unlockDate != null && DateTime.now().isBefore(unlockDate);

    // 🔥 MODAL INTERNO PARA APORTAR MÁS DINERO (SOLO FLEXIBLE)
    void mostrarModalAporte(BuildContext ctx, ColorScheme colorScheme) {
      final montoController = TextEditingController();
      bool isDepositing = false;

      showDialog(
        context: ctx,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text("Aportar a la Ucha", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Ingresa la cantidad de TTC que deseas sumar a esta meta.", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: "Monto TTC",
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDepositing ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: isDepositing ? null : () async {
                    if (montoController.text.isEmpty) return;
                    double amount = double.parse(montoController.text);

                    // 🛡️ HUELLA DACTILAR
                    showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Confirma tu nuevo aporte."));
                    bool isAuth = await authCore.authenticateUser();
                    Navigator.pop(rootContext); 

                    if (!isAuth) {
                      UIHelper.showCustomSnackbar("Aporte cancelado", isError: true);
                      return;
                    }

                    setDialogState(() => isDepositing = true);
                    
                   try {
                      // 🔥 AHORA SÍ: LLAMADA REAL AL BACKEND
                      String res = await vaultService.depositToFlexibleVault(vault['id'], amount);
                      
                      if (res == "Exito") {
                        if (dialogContext.mounted) Navigator.pop(dialogContext); // Cierra dialog
                        if (ctx.mounted) Navigator.pop(ctx); // Cierra modal de detalles
                        UIHelper.showCustomSnackbar("¡Aporte exitoso! TTC sumados a tu Ucha.", isError: false);
                        onUpdate(); // Actualiza la lista principal de bóvedas
                      } else {
                        UIHelper.showCustomSnackbar(res, isError: true);
                      }
                    } finally {
                      if (dialogContext.mounted) setDialogState(() => isDepositing = false);
                    }
                  },
                  child: isDepositing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Firmar Aporte"),
                )
              ],
            );
          }
        )
      );
    }

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final onSurfaceColor = colorScheme.onSurface;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
              decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CABECERA
                  Icon(isFlexible ? Icons.savings : Icons.lock_clock, color: isFlexible ? Colors.blueAccent : Colors.purpleAccent, size: 48),
                  const SizedBox(height: 10),
                  Text(vault['goalName'] ?? "Mi Bolsillo", style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isFlexible ? Colors.blueAccent.withOpacity(0.1) : Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(isFlexible ? "Ucha Flexible" : "Plazo Fijo", style: TextStyle(color: isFlexible ? Colors.blueAccent : Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // SALDO GIGANTE
                  Text("${balance.toStringAsFixed(2)} TTC", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                  const SizedBox(height: 25),

                  if (vault['targetAmount'] != null && double.parse(vault['targetAmount'].toString()) > 0) ...[
                    Builder(
                      builder: (context) {
                        double target = double.parse(vault['targetAmount'].toString());
                        double progress = (balance / target).clamp(0.0, 1.0);
                        bool isCompleted = progress >= 1.0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.withOpacity(0.1) : onSurfaceColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.transparent)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(isCompleted ? "¡Meta Alcanzada! 🎉" : "Progreso de la meta", style: TextStyle(color: isCompleted ? Colors.green[800] : onSurfaceColor.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("${(progress * 100).toStringAsFixed(1)}%", style: TextStyle(color: isCompleted ? Colors.green : colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 12,
                                  backgroundColor: (isCompleted ? Colors.green : colorScheme.primary).withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : colorScheme.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Meta: ${target.toStringAsFixed(2)} TTC", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                                  if (!isCompleted)
                                    Text("Faltan: ${(target - balance).toStringAsFixed(2)} TTC", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 🔥 SECCIÓN DE INFORMACIÓN DETALLADA (M3 TONAL CARDS)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.03), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Información del Bolsillo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        
                        _buildInfoRow("Creado el", vault['createdAt'] != null ? DateTime.parse(vault['createdAt']).toString().substring(0, 10) : "Reciente", Icons.calendar_today, onSurfaceColor),
                        if (!isFlexible) ...[
                          const Divider(height: 20),
                          _buildInfoRow("Tasa de Interés", "5% APY (Anual)", Icons.trending_up_rounded, Colors.green),
                          const Divider(height: 20),
                          _buildInfoRow("Estado", isLocked ? "Bloqueado" : "Madurado", isLocked ? Icons.lock_outline : Icons.lock_open, isLocked ? Colors.orange : Colors.green),
                        ],
                        if (vault['autoSaveFrequency'] != 'NONE') ...[
                          const Divider(height: 20),
                          _buildInfoRow("Auto-Ahorro", "${vault['autoSaveAmount']} TTC / ${vault['autoSaveFrequency']}", Icons.autorenew, Colors.blueAccent),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ALERTA DE PENALIDAD
                  if (!isFlexible && isLocked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.5))),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Bloqueado hasta: ${unlockDate!.day}/${unlockDate.month}/${unlockDate.year}. Retirar ahora implica una penalización del 10% sobre tu capital.",
                              style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 🔥 BOTONES DE ACCIÓN M3
                  if (isFlexible) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Aportar más TTC", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => mostrarModalAporte(context, colorScheme),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isLocked && !isFlexible) ? Colors.redAccent.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                        foregroundColor: (isLocked && !isFlexible) ? Colors.redAccent : colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      icon: isProcessing ? const SizedBox() : Icon(isLocked ? Icons.heart_broken : Icons.download_rounded),
                      label: isProcessing 
                          ? const CircularProgressIndicator() 
                          : Text(isLocked ? "Romper y pagar penalidad" : "Retirar Fondos Completos", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: isProcessing ? null : () async {
                        // 🛡️ HUELLA DACTILAR PARA RETIRO
                        showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Confirma el retiro de tus fondos."));
                        bool isAuth = await authCore.authenticateUser();
                        Navigator.pop(rootContext); 

                        if (!isAuth) {
                          UIHelper.showCustomSnackbar("Operación cancelada", isError: true);
                          return;
                        }

                        setStateModal(() => isProcessing = true);
                        try {
                          String res = await vaultService.withdrawVault(vault['id']);
                          if (res == "Exito") {
                            Navigator.pop(ctx);
                            UIHelper.showCustomSnackbar("Fondos enviados a tu billetera principal", isError: false);
                            onUpdate(); 
                          } else {
                            UIHelper.showCustomSnackbar(res, isError: true);
                          }
                        } finally {
                          if (ctx.mounted) setStateModal(() => isProcessing = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // Helper para las filas de información
  static Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}