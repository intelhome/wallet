import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// class PayDebtModal {
//   static void show({
//     required BuildContext context,
//     //required BlockchainService service,
//     required String debtId,
//     required double maxAmount, // La deuda restante
//     required String creditorAddress,
//     required VoidCallback onSuccess,
//     required void Function(String, {bool esError}) mostrarMensaje,
//   }) {

//     final debtService = Provider.of<DebtService>(context, listen: false);
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final userService = Provider.of<UserService>(context, listen: false); // Para buscar alias
// final txService =  Provider.of<TransactionService>(context, listen: false); 


//     final TextEditingController amountController = TextEditingController();
//     double montoIngresado = 0.0;
//     bool isProcessing = false;
//     String statusText = "";
//     IOWebSocketChannel? _txWsChannel;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,
//       builder: (ctx) {
//         final theme = Theme.of(ctx);
//         final onSurface = theme.colorScheme.onSurface;

//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Container(
//               decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
//               padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("Abonar a la deuda", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
//                       if (!isProcessing)
//                         IconButton(icon: Icon(Icons.close, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Text("Deuda restante: $maxAmount TTC", style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 16),
                  
//                   TextField(
//                     controller: amountController,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     enabled: !isProcessing,
//                     decoration: InputDecoration(
//                       labelText: "¿Cuánto deseas pagar? (TTC)",
//                       prefixIcon: const Icon(Icons.monetization_on_rounded, color: Colors.green),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//                       suffixIcon: TextButton(
//                         onPressed: isProcessing ? null : () {
//                           setState(() { amountController.text = maxAmount.toString(); montoIngresado = maxAmount; });
//                         },
//                         child: const Text("TODO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
//                       ),
//                     ),
//                     onChanged: (val) => montoIngresado = double.tryParse(val) ?? 0.0,
//                   ),
                  
//                   const SizedBox(height: 24),
//                   if (isProcessing) ...[
//                     const Center(child: CircularProgressIndicator()),
//                     const SizedBox(height: 10),
//                     Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
//                   ] else
//                     SizedBox(
//                       height: 55,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
//                         onPressed: () async {
//                           HapticFeedback.mediumImpact();
//                           if (montoIngresado <= 0 || montoIngresado > maxAmount) {
//                             mostrarMensaje("Monto inválido. Máximo: $maxAmount TTC", esError: true);
//                             return;
//                           }

//                           // 1. 🔥 PEDIR HUELLA PARA PAGAR
//                           HapticFeedback.mediumImpact();
//                           // bool auth = await authCore.authenticateUser();
//                           // if (!auth) return;

//                           // setState(() { isProcessing = true; statusText = "Enviando transacción a la red..."; });
//                           BigInt amountWei = BigInt.from(montoIngresado * 1e18);
//                           String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: creditorAddress, amountWei: amountWei);
//                           if (signature == null) return;

//                           setState(() { isProcessing = true; statusText = "Enviando transacción a la red..."; });

//                           // 2. Conectar al WS para escuchar si la Tx realmente pasa
//                           try {
//                             _txWsChannel = IOWebSocketChannel.connect(
//                               Uri.parse("${ApiConfig.wsTransactionsUpdates}/${authCore.publicAddress.toLowerCase()}"),
//                               headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
//                             );

//                             _txWsChannel!.stream.listen((message) async {
//                               if (message == "COMPLETED") {
//                                 // 4. LA BLOCKCHAIN CONFIRMÓ. AHORA SÍ ACTUALIZAMOS LA DB
//                                 setState(() => statusText = "Transacción confirmada. Actualizando deuda...");
                                
//                                 await http.post(
//                                   Uri.parse(ApiConfig.payDebt.replaceAll("{debtId}", debtId)),
//                                   headers: { "Content-Type": "application/json", "Authorization": "Bearer ${authCore.jwtToken}" },
//                                   body: jsonEncode({ "amountPaid": montoIngresado, "txHash": "TX_VERIFIED" })
//                                 );

//                                 mostrarMensaje("¡Pago realizado con éxito!", esError: false);
//                                 _txWsChannel?.sink.close();
//                                 onSuccess();
//                                 Navigator.pop(ctx);
//                               } else if (message == "FAILED") {
//                                 // LA BLOCKCHAIN FALLÓ. NO ACTUALIZAMOS LA DEUDA.
//                                 setState(() { isProcessing = false; });
//                                 mostrarMensaje("La transacción falló en la Blockchain (Verifica tu saldo/gas).", esError: true);
//                                 _txWsChannel?.sink.close();
//                               }
//                             });
//                           } catch (e) {
//                              setState(() { isProcessing = false; });
//                              mostrarMensaje("Error conectando al servidor", esError: true);
//                              return;
//                           }

//                           // 3. Disparar el envío a Web3
//                           //String res = await txService.sendTokensL2(creditorAddress, montoIngresado);
//                           String res = await txService.sendTokensL2(creditorAddress, montoIngresado, signature);
//                           if (!res.startsWith("Exito")) {
//                             setState(() { isProcessing = false; });
//                             mostrarMensaje(res, esError: true);
//                             _txWsChannel?.sink.close();
//                           }
//                           // Si es éxito, el WS (paso 2) se encargará de terminar el proceso
//                         },
//                         child: const Text("Confirmar Pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           }
//         );
//       }
//     ).whenComplete(() => _txWsChannel?.sink.close());
//   }
// }

class PlanPaymentModal {
  static void show({
    required BuildContext context,
    required String aliasDestino,
    required String addressDestino, 
    String? initialAmount,
    String? initialReason,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final scheduledService = Provider.of<ScheduledPaymentService>(context, listen: false);
    BuildContext rootContext = context;

    final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');
    DateTime? fechaSeleccionada;
    bool guardando = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparente para esquinas redondeadas completas
      builder: (ctx) => StatefulBuilder( 
        builder: (context, setStateModal) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.calendar_month_rounded, size: 40, color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text("Planificar Pago", style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
                Text("Destinatario: @$aliasDestino", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 24),

                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: "Monto a transferir (TTC)",
                    prefixIcon: Icon(Icons.attach_money_rounded, color: colorScheme.primary),
                    filled: true, fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: motivoController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: "Motivo del pago (Opcional)",
                    prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                    filled: true, fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  readOnly: true,
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Fecha y Hora exacta de ejecución",
                    hintText: fechaSeleccionada == null 
                        ? "Seleccionar fecha y hora" 
                        : "${fechaSeleccionada!.day.toString().padLeft(2,'0')}/${fechaSeleccionada!.month.toString().padLeft(2,'0')}/${fechaSeleccionada!.year} a las ${fechaSeleccionada!.hour}:${fechaSeleccionada!.minute.toString().padLeft(2, '0')}",
                    prefixIcon: Icon(Icons.access_time_filled_rounded, color: colorScheme.secondary),
                    filled: true, fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: ctx, 
                      initialDate: DateTime.now().add(const Duration(days: 1)), 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime(2030)
                    );
                    if (pickedDate != null) {
                      if (!ctx.mounted) return;
                      TimeOfDay? pickedTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                      if (pickedTime != null) {
                        setStateModal(() {
                          fechaSeleccionada = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: guardando ? null : () async {
                      HapticFeedback.mediumImpact();
                      double monto = double.tryParse(montoController.text) ?? 0;
                      if (monto <= 0 || fechaSeleccionada == null) {
                        UIHelper.showCustomSnackbar("Llene el monto y la fecha", isError: true);
                        return;
                      }

                      FocusScope.of(ctx).unfocus();
                      showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Firma tu acuerdo de pago."));
                      bool isAuth = await authCore.authenticateUser();
                      Navigator.pop(rootContext); 

                      if (!isAuth) return;

                      setStateModal(() => guardando = true);

                      String motivo = motivoController.text.isEmpty ? "Pago Programado" : motivoController.text;
                      BigInt amountWei = BigInt.from(monto * 1e18);

                      String? firma = await authCore.generateDelegatedSignature(
                        "SEND", 
                        toAddress: addressDestino.toLowerCase().trim(), 
                        amountWei: amountWei
                      );
                      
                      if (firma != null) {
                        Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                          customTitle: "Planificando Pago", 
                          customMessage: "Verificando fondos y guardando contrato...",
                          recipientAddress: addressDestino,
                          expectedTxType: "SCHEDULED_PAYMENT",
                          onUpdateBalance: () {} 
                        )));

                        bool success = await scheduledService.saveScheduledPayment({
                          "fromAddress": authCore.publicAddress.toLowerCase(),
                          "toAddress": addressDestino.toLowerCase(),
                          "amountPerPayment": monto,
                          "totalInstallments": 1,
                          "frequency": "ONCE",
                          "nextExecutionDate": fechaSeleccionada!.toUtc().toIso8601String(),
                          "paymentReason": motivo,
                          "signature": firma       
                        });

                        Navigator.pop(rootContext); // Cerrar loading

                        if (success) {
                          UIHelper.showCustomSnackbar("Acuerdo planificado con éxito", isError: false);
                          if (ctx.mounted) Navigator.pop(ctx); 
                        } else {
                          UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes o error de red", isError: true);
                        }
                      } else {
                        UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
                      }
                      setStateModal(() => guardando = false);
                    },
                    icon: guardando 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.draw_rounded),
                    label: Text(guardando ? "Firmando..." : "Firmar Acuerdo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }
      )
    );
  }
}