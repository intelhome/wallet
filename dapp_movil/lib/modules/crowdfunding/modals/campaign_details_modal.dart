import 'package:dapp_movil/config/blockchain_config.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../../../core/services/transaction_skeleton.dart';

class CampaignDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic campaign,
    //required BlockchainService service,
    required VoidCallback onRefresh,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final crowdService = Provider.of<CrowdfundingService>(context, listen: false);

    final amountCtrl = TextEditingController();
    bool isProcessing = false;
    bool isAnonymous = false; // 🔥 PUNTO 7
    
    bool isCreator = campaign['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
    bool isSuccessful = campaign['status'] == 'SUCCESSFUL';
    bool isCancelled = campaign['status'] == 'CANCELLED';

    double target = (campaign['targetAmount'] ?? 1).toDouble();
    double raised = (campaign['raisedAmount'] ?? 0).toDouble();
    double progress = (raised / target).clamp(0.0, 1.0);

    List<dynamic> pledges = campaign['pledges'] ?? [];

    BuildContext rootContext = context;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(rootContext).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setStateModal) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    
                    // HEADER
                    if (isCreator) 
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("👑 Panel de Administración", style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                      
                    Text(campaign['title'] ?? 'Campaña', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text("Creador: ${campaign['creatorAddress'].toString().substring(0, 10)}...", style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    
                    if (isCancelled)
                       Padding(
                         padding: const EdgeInsets.only(top: 10),
                         child: Text("🛑 CAMPAÑA CANCELADA\nMotivo: ${campaign['cancellationReason']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                       ),
                    
                    const SizedBox(height: 24),

                    // BARRA DE PROGRESO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("$raised TTC recaudados", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Meta: $target TTC", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: colorScheme.primary.withOpacity(0.1), color: progress >= 1.0 ? Colors.green : colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // SECCIÓN DONANTES
                    // ==========================================
                    const Text("Top Donantes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (pledges.isEmpty)
                      const Text("Aún no hay donaciones. ¡Sé el primero!", style: TextStyle(color: Colors.grey)),
                    ...pledges.map((p) {
                      // Detectamos si es anónimo (Jackson suele serializar 'isAnonymous' como 'anonymous')
                      bool anon = p['anonymous'] ?? p['isAnonymous'] ?? false;
                      
                      // Lógica de visualización
                      String alias = anon ? "Anónimo" : (p['donorAlias'] ?? "Usuario de la Comunidad");
                      String walletLabel = anon ? "0xAnónimo" : p['donorAddress'].toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1), 
                          child: Icon(anon ? Icons.visibility_off : Icons.person, color: colorScheme.primary)
                        ),
                        title: Text(alias, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(walletLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Text("+${p['amount']} TTC", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    }).toList(),

                    const SizedBox(height: 30),

                    // ==========================================
                    // ACCIONES
                    // ==========================================
                    if (!isCancelled && !isSuccessful && !isCreator) ...[
                      // VISTA DONANTE: FORMULARIO DE DONACIÓN
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: "Quiero donar (TTC)", prefixIcon: const Icon(Icons.volunteer_activism_rounded), filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text("Donación Anónima"),
                        subtitle: const Text("Ocultar mi dirección al público"),
                        value: isAnonymous,
                        activeColor: colorScheme.primary,
                        onChanged: (val) => setStateModal(() => isAnonymous = val),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: isProcessing ? null : () async {
                            if (amountCtrl.text.isEmpty) return;
                            FocusScope.of(ctx).unfocus();

                            showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Verifica tu identidad para donar."));
                            bool isAuth = await authCore.authenticateUser();
                            if (rootContext.mounted) Navigator.pop(rootContext);

                            if (!isAuth) return;

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (rootContext.mounted) {
                              Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(customTitle: "Enviando Donación", customMessage: "Bloqueando TTC...", recipientAddress: BlockchainConfig.crowdfundingContract, expectedTxType: "SEND", onUpdateBalance: onRefresh)));
                            }

                            String res = await crowdService.pledgeCampaign(campaign['id'], double.parse(amountCtrl.text), isAnonymous);
                            if (res == "Exito") {
                              UIHelper.showCustomSnackbar("¡Gracias por tu donación!");
                              onRefresh(); 
                            } else {
                              if (rootContext.mounted) Navigator.pop(rootContext);
                              UIHelper.showCustomSnackbar(res, isError: true);
                            }
                          },
                          child: const Text("Donar y Firmar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],

                    // VISTA CREADOR: RECLAMAR
                 if (isCreator && isSuccessful)
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: isProcessing ? null : () async {
                            
                            // 🔥 NUEVO: BIOMETRÍA PARA RECLAMAR
                            showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Verifica tu identidad para reclamar los fondos."));
                            bool isAuth = await authCore.authenticateUser();
                            if (rootContext.mounted) Navigator.pop(rootContext);

                            if (!isAuth) return;

                            setStateModal(() => isProcessing = true);
                            try {
                              String res = await crowdService.claimCampaign(campaign['id']);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (res == "Exito") {
                                UIHelper.showCustomSnackbar("¡Fondos transferidos a tu billetera!");
                                onRefresh();
                              } else {
                                UIHelper.showCustomSnackbar(res, isError: true);
                              }
                            } finally {
                              if (modalContext.mounted) setStateModal(() => isProcessing = false);
                            }
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text("Reclamar Fondos Exitosos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),

                    // 🔥 PUNTO 4: VISTA CREADOR: CANCELAR
                    if (isCreator && !isSuccessful && !isCancelled)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SizedBox(
                          width: double.infinity, height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: isProcessing ? null : () => _showCancelDialog(rootContext, campaign, ctx, onRefresh),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text("Cancelar y Reembolsar Donantes", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  // =========================================================================
  // DIÁLOGO DE CANCELACIÓN (PIDE LA RAZÓN)
  // =========================================================================
  static void _showCancelDialog(BuildContext rootContext, dynamic campaign, BuildContext modalContext, VoidCallback onRefresh) {
      
    final reasonCtrl = TextEditingController();
    bool isProcessing = false;
    final authCore = Provider.of<AuthCoreService>(rootContext, listen: false);
    final crowdService = Provider.of<CrowdfundingService>(rootContext, listen: false);

    showDialog(
      context: rootContext,
      builder: (ctxDialog) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.warning_rounded, color: Colors.red), SizedBox(width: 10), Text("Cancelar Campaña")]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Si cancelas, el contrato inteligente devolverá automáticamente todos los fondos a los donantes y no podrás reactivar la campaña.", style: TextStyle(fontSize: 13)),
              const SizedBox(height: 15),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(hintText: "Razón de cancelación (Se enviará por notificación a los donantes)", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctxDialog), child: const Text("Volver", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: isProcessing ? null : () async {
                if (reasonCtrl.text.isEmpty) {
                  UIHelper.showCustomSnackbar( "Debes escribir una razón");
                  return;
                }
                
                // Pedimos biometría por ser acción crítica
                bool isAuth = await authCore.authenticateUser();
                if (!isAuth) return;

                setStateDialog(() => isProcessing = true);
                
                String res = await crowdService.cancelCampaign(campaign['id'], reasonCtrl.text);
                
                if (context.mounted) setStateDialog(() => isProcessing = false);

                if (res == "Exito") {
                  if (ctxDialog.mounted) Navigator.pop(ctxDialog); // Cierra Dialog
                  if (modalContext.mounted) Navigator.pop(modalContext); // Cierra BottomSheet
                  UIHelper.showCustomSnackbar("Campaña cancelada. Fondos reembolsados.", isError: false);
                  onRefresh();
                } else {
                  UIHelper.showCustomSnackbar(res, isError: true);
                }
              },
              child: isProcessing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Confirmar Cancelación"),
            )
          ],
        ),
      )
    );
  }
}