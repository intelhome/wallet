import 'package:dapp_movil/config/blockchain_config.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../../../core/services/transaction_skeleton.dart';

class DonateModal {
  static void show({
    required BuildContext context,
    required dynamic campaign,
   // required BlockchainService service,
    required VoidCallback onRefresh,
  }) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final crowdService = Provider.of<CrowdfundingService>(context, listen: false);

    final amountCtrl = TextEditingController();
    bool isProcessing = false;
    bool isAnonymous = false;
    
    bool isCreator = campaign['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
    bool isSuccessful = campaign['status'] == 'SUCCESSFUL';

    // Para evitar errores en la pantalla de carga, guardamos el root context
    BuildContext rootContext = context;

  showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(rootContext).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;

        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom, 
                left: 24, right: 24, top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(campaign['title'] ?? 'Campaña', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text("Creado por: ${campaign['creatorAddress'].toString().substring(0, 10)}...", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Solo mostramos el input de donar si NO ha llegado a la meta
                  if (!isSuccessful) ...[
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      decoration: InputDecoration(
                        labelText: "Quiero donar (TTC)", 
                        prefixIcon: const Icon(Icons.volunteer_activism_rounded), 
                        filled: true, 
                        fillColor: colorScheme.onSurface.withOpacity(0.05), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // 🔥 SOLUCIÓN 3: Switch para permitir donación anónima
                    SwitchListTile(
                      title: const Text("Donación Anónima"),
                      subtitle: const Text("Ocultar mi dirección al público"),
                      value: isAnonymous,
                      activeColor: colorScheme.primary,
                      onChanged: (val) => setStateModal(() => isAnonymous = val),
                    ),
                    const SizedBox(height: 24),
                  ],

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSuccessful ? Colors.green : colorScheme.primary, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: isProcessing ? null : () async {
                        HapticFeedback.mediumImpact();
                        
                        // 🟢 FLUJO 1: EL CREADOR RECLAMA LOS FONDOS
                        if (isSuccessful && isCreator) {
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
                          return;
                        }

                        // 🔴 FLUJO 2: USUARIO EXTERNO MIRANDO UNA CAMPAÑA CERRADA
                        if (isSuccessful && !isCreator) {
                           UIHelper.showCustomSnackbar("Esta campaña ya alcanzó su meta.");
                           return;
                        }

                        // 🔵 FLUJO 3: DONACIÓN NORMAL
                        if (amountCtrl.text.isEmpty) return;
                        FocusScope.of(ctx).unfocus();

                        // Autenticación biométrica
                        HapticFeedback.mediumImpact();
                        showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Verifica tu identidad para donar."));
                        bool isAuth = await authCore.authenticateUser();
                        if (rootContext.mounted) Navigator.pop(rootContext);

                        if (!isAuth) return;

                        if (ctx.mounted) Navigator.pop(ctx); 

                        if (rootContext.mounted) {
                          Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                            customTitle: "Enviando Donación", 
                            customMessage: "Bloqueando TTC...", 
                            // 🔥 SOLUCIÓN 2: Nombre de variable correcto
                            recipientAddress: BlockchainConfig.crowdfundingContract, 
                            expectedTxType: "SEND", 
                            onUpdateBalance: onRefresh 
                          )));
                        }

                        // 🔥 SOLUCIÓN 3: Pasamos el parámetro de anonimato al backend
                        String res = await crowdService.pledgeCampaign(campaign['id'], double.parse(amountCtrl.text), isAnonymous);
                        if (res == "Exito") {
                          UIHelper.showCustomSnackbar("¡Gracias por tu donación!");
                          onRefresh(); 
                        } else {
                          if (rootContext.mounted) Navigator.pop(rootContext); 
                          UIHelper.showCustomSnackbar(res, isError: true);
                        }
                      },
                      child: isProcessing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                          isSuccessful 
                            ? (isCreator ? "Reclamar Fondos" : "Campaña Completada 🎉") 
                            : "Donar y Firmar", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }
}