import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/burner_service.dart';

class CreateBurnerModal {
  static void show({
    required BuildContext context, 
    String? initialFundingAmount,
    String? initialLabel,
    required VoidCallback onSuccess
  }) {
    final labelCtrl = TextEditingController(text: initialLabel ?? "");
    final amountCtrl = TextEditingController(text: initialFundingAmount ?? "");
    bool isProcessing = false;

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final burnerService = Provider.of<BurnerService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_card_rounded, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text("Crear Burner Wallet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: "Etiqueta (Ej: Pago en Opensea)",
                      prefixIcon: Icon(Icons.label_outline_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: "Fondeo Inicial (TTC)",
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: colorScheme.onSurface.withOpacity(0.5)),
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text("El fondeo inicial se debitará de tu billetera principal y se enviará a esta nueva tarjeta.", style: TextStyle(color: Colors.orange[800], fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                     onPressed: isProcessing ? null : () async {
                        if (labelCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                        
                        // Necesitamos importar TransactionService al inicio del archivo si no está
                        final txService = Provider.of<TransactionService>(context, listen: false);
                        double monto = double.parse(amountCtrl.text);

                        FocusScope.of(context).unfocus();

                        showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la creación de la tarjeta."));
                        HapticFeedback.mediumImpact();
                        bool isAuth = await authCore.authenticateUser();
                        Navigator.pop(context); 

                        if (!isAuth) return;

                        setStateModal(() => isProcessing = true);
                        try {
                          print("🚀 [UI-CREATE-BURNER] Disparando creación al backend...");
                          
                          // 🔥 FIX: Recibe el Map<String, dynamic>
                          Map<String, dynamic> res = await burnerService.createBurnerWallet(labelCtrl.text, monto);
                          
                          if (res["success"] == true) {
                            print("✅ [UI-CREATE-BURNER] Tarjeta registrada en BD.");
                            String newBurnerAddress = res["data"]["burnerAddress"];

                            // 🔥 FIX: Fondeo On-Chain desde Flutter
                            if (monto > 0) {
                              print("💸 [UI-CREATE-BURNER] Fondeando $monto TTC a $newBurnerAddress...");
                              BigInt amountWei = BigInt.from(monto * 1e18);
                              String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: newBurnerAddress.toLowerCase(), amountWei: amountWei);
                              
                              if (signature != null) {
                                await txService.sendTokensL2(newBurnerAddress, monto, signature);
                                print("✅ [UI-CREATE-BURNER] Fondeo minado con éxito.");
                              }
                            }

                            Navigator.pop(ctx); // Cierra el modal inferior
                            UIHelper.showCustomSnackbar("Tarjeta creada y fondeada exitosamente.", isError: false);
                            
                            // 🔥 FIX: Damos 3 segundos para que la red indexe el saldo antes de listar
                            print("⏳ [UI-CREATE-BURNER] Esperando indexación de saldo...");
                            await Future.delayed(const Duration(seconds: 3));
                            
                            print("🔄 [UI-CREATE-BURNER] Actualizando lista.");
                            onSuccess(); // Dispara el WebSocket / Refresh visual
                          } else {
                            print("❌ [UI-CREATE-BURNER] Error: ${res['error']}");
                            UIHelper.showCustomSnackbar(res['error'], isError: true);
                          }
                        } finally {
                          if (ctx.mounted) setStateModal(() => isProcessing = false);
                        }
                      },
                      child: isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Generar y Firmar Fondeo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}