import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/screens/qr_scanner_screen.dart';
import '../../wallet_and_tx/modals/buy_modal.dart';

class RequestGroupPaymentModal {
  static void show({
    required BuildContext context,
   // required BlockchainService service,
    required String groupId,
    required VoidCallback onSuccess,
    required bool isCreator,    // 🔥 NUEVO: Para saber si mostramos el Switch
    required double saldoGrupo,
    // 🔥 NUEVOS PARÁMETROS PARA MODO "PAGAR AYUDA"
    String? customTitle,
    String? initialDesc,
    String? initialDest,
    String? initialAmount,
    bool lockDest = false,
    String? sharedDebtId,
    bool forceVault = false,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final groupService = Provider.of<GroupSocialService>(context, listen: false);

  final TextEditingController descController = TextEditingController(text: initialDesc ?? "");
    final TextEditingController amountController = TextEditingController(text: initialAmount ?? "");
    final TextEditingController destController = TextEditingController(text: initialDest ?? "");
    bool isProcessing = false;
    bool _usarFondoComun = forceVault;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final onSurface = Theme.of(ctx).colorScheme.onSurface;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 24, right: 24, top: 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.receipt_long, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 10),
                
                // 🔥 Título Dinámico
                Text(customTitle ?? "Dividir Cuenta", textAlign: TextAlign.center, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                
                if (!forceVault)
                  Text("El monto total se dividirá equitativamente entre los miembros activos del grupo.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 20),

                TextField(
                  controller: descController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: "¿De qué es este pago/cobro?",
                    hintText: "Ej: Pizza, Regalo, Viaje...",
                    prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
                    filled: true,
                    fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: destController,
                  readOnly: lockDest, // 🔥 Bloquea escritura si es un aporte de Vaca
                  style: TextStyle(color: onSurface, fontWeight: lockDest ? FontWeight.bold : FontWeight.normal),
                  decoration: InputDecoration(
                    labelText: "Billetera Destino Final",
                    hintText: "0x...",
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                    
                    // 🔥 Oculta el QR si el destino está bloqueado
                    suffixIcon: lockDest ? const Icon(Icons.lock_rounded, color: Colors.grey) : IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                      onPressed: () async {
                        final scannedAddress = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                        );
                        if (scannedAddress != null) {
                          setModalState(() {
                            destController.text = scannedAddress.trim();
                          });
                        }
                      },
                    ),
                    filled: true,
                    fillColor: lockDest ? onSurface.withOpacity(0.1) : onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Monto Total (TTC)",
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                    filled: true,
                    fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                if (isCreator) 
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _usarFondoComun ? Colors.blueAccent.withOpacity(0.1) : onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _usarFondoComun ? Colors.blueAccent : Colors.transparent)
                    ),
                    child: SwitchListTile(
                      activeColor: Colors.blueAccent,
                      title: Text("Pagar con Bóveda del Grupo", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Saldo de la bóveda: ${saldoGrupo.toStringAsFixed(2)} TTC\n" + 
                        (_usarFondoComun ? "Se enviará un pago único desde el grupo." : "Se dividirá la cuenta entre los miembros."),
                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
                      ),
                      value: _usarFondoComun,
                      
                      // 🔥 Mantiene el switch encendido pero intocable si es forceVault
                      onChanged: forceVault ? (val) {
                         UIHelper.showCustomSnackbar("Este pago debe hacerse obligatoriamente con la Bóveda.");
                      } : (val) {
                        double totalAEnviar = double.tryParse(amountController.text) ?? 0.0;
                        if (val == true && totalAEnviar > saldoGrupo) {
                          UIHelper.showCustomSnackbar("Bóveda insuficiente. Necesitas $totalAEnviar TTC pero el grupo solo tiene ${saldoGrupo.toStringAsFixed(2)} TTC.", isError: true);
                          return; 
                        }
                        setModalState(() => _usarFondoComun = val);
                      },
                    ),
                  ),

                // 🔥 ACCOUNT ABSTRACTION UI (GASLESS) 🔥
                if (isCreator && _usarFondoComun)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.local_gas_station_rounded, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              Row(
                                children: [
                                  Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough)),
                                  const SizedBox(width: 6),
                                  const Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
                          child: const Text("Patrocinado", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: isProcessing ? null : () async {
                    HapticFeedback.mediumImpact();
                    if (descController.text.isEmpty || amountController.text.isEmpty || destController.text.isEmpty) return;
                    
                    double total = double.tryParse(amountController.text) ?? 0;
                    if (total <= 0) return;

                    if (_usarFondoComun && total > saldoGrupo) {
                       UIHelper.showCustomSnackbar("Saldo de bóveda insuficiente (${saldoGrupo.toStringAsFixed(2)} TTC disponibles).", isError: true);
                       return;
                    }

                    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza el pago grupal."));
                    // Validar biometría antes de cualquier pago grupal
                    HapticFeedback.mediumImpact();
                    bool auth = await authCore.authenticateUser();

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (!auth) return;

                    setModalState(() => isProcessing = true);

                    Navigator.pop(ctx);

                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                      customTitle: _usarFondoComun ? "Pago desde Bóveda" : "Creando Cobro Grupal", 
                      customMessage: _usarFondoComun ? "Ejecutando en la Blockchain..." : "Notificando a los miembros...",
                      isGroupPayment: true,
                      expectedTxType: "GROUP_ACTION",
                      onUpdateBalance: onSuccess 
                    )));
                    
                    String res = await groupService.requestGroupPayment(groupId, total, descController.text, destController.text.trim(), useGroupFunds: _usarFondoComun,sharedDebtId: sharedDebtId);
                    
                    if (context.mounted) Navigator.pop(context);

                    if (res == "SUCCESS") {
                      if (context.mounted) Navigator.pop(context);
                      UIHelper.showCustomSnackbar(
                        _usarFondoComun ? "Pago enviado desde la bóveda" : "Cobro solicitado al grupo",
                        isError: false
                      );
                      onSuccess(); 
                     // if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      UIHelper.showCustomSnackbar("Error: $res", isError: true);
                      //setModalState(() => isProcessing = false);
                    }
                  },
                  child: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirmar Transacción", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}