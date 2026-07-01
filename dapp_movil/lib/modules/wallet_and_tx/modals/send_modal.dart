import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
//import 'package:dapp_movil/modules/burner_wallets/services/burner_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/transaction_details_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/transaction_simulator_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/receipt_preview_screen.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/transaction_pending_screen.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:pay/pay.dart';
import '../../../core/services/smart_avatar.dart';
import 'buy_modal.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// class SendModal {
//   static void show({
//     required BuildContext context,
//     //required BlockchainService service,
//     required String balanceTTC,
//     required VoidCallback onUpdateBalance,
//     required void Function(String, {bool esError}) mostrarMensaje,
//     String? initialAddress,
//     String? initialAmount,
//     String? initialAlias,
//     bool isGroupPayment = false,
//     String? debtId,
//     String? sharedDebtId,
//     //String? fromBurnerAddress,
//     Function(double amount, String txHash)? onTransferSuccess,
//   }) {

//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final txService = Provider.of<TransactionService>(context, listen: false);
// final userService = Provider.of<UserService>(context, listen: false);
// final debtService = Provider.of<DebtService>(context, listen: false); // 🔥 NUEVO
// //final burnerService = Provider.of<BurnerService>(context, listen: false);
//     // 🔥 FIX: Guardamos el contexto principal para que no muera al cerrar el modal
//     BuildContext rootContext = context;

//     // 🔥 PREPARAMOS GOOGLE PAY
//    Pay? payClient;
//     PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
//       payClient = Pay({ PayProvider.google_pay: config });
//     });

//     final TextEditingController addressController = TextEditingController(text: initialAddress ?? "");
//     final TextEditingController montoController = TextEditingController(text: initialAmount ?? "");
//     final TextEditingController reasonController = TextEditingController();
    
//    String direccionDestino = (initialAddress ?? "").trim();
//    double montoIngresado = double.tryParse(initialAmount ?? '0') ?? 0.0;
    
//     bool isProcessing = false;
//     bool isPaid = false;

    

//    showModalBottomSheet(
//       context: rootContext,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,
//       builder: (ctx) {
//       final theme = Theme.of(ctx); // 🔥 Inyección M3
//         final colorScheme = theme.colorScheme;
//         final onSurfaceColor = colorScheme.onSurface;
//         final cardColor = theme.cardColor;

//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateModal) {
            
//             // if (gpayConfig == null) {
//             //   PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
//             //     if (context.mounted) {
//             //       setStateModal(() => gpayConfig = config);
//             //     }
//             //   });
//             // }

//             String destinoLimpio = direccionDestino.trim();
//             bool isOffChain = destinoLimpio.startsWith("@");

//             return Container(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(ctx).viewInsets.bottom,
//                 left: 24, right: 24, top: 24
//               ),
//               decoration: BoxDecoration(
//                 color: cardColor,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)) // 🔥 Borde 24 M3
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Enviar TTC", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
//                         IconButton(
//                           icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
//                           onPressed: () async {
//                             final scannedAddress = await Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const QRScannerScreen()),
//                             );
//                             if (scannedAddress != null) {
//                               setStateModal(() {
//                                 addressController.text = scannedAddress.trim();
//                                 direccionDestino = scannedAddress.trim();
//                               });
//                             }
//                           },
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.close, color: onSurfaceColor.withOpacity(0.6)),
//                           onPressed: () => Navigator.pop(ctx)
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),

//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: isOffChain ? Colors.amber.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
//                      borderRadius: BorderRadius.circular(16),// 🔥 Borde 24 M3
//                      border: Border.all(color: isOffChain ? colorScheme.secondary.withOpacity(0.5) : colorScheme.primary.withOpacity(0.5)),
//                       ),
//                       child: Row(
//                         children: [
//                        Icon(isOffChain ? Icons.flash_on_rounded : Icons.link_rounded, color: isOffChain ? colorScheme.secondary : colorScheme.primary),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               isOffChain ? "Modo Pay ⚡ (Instantáneo y 0 Gas)" : "Modo On-Chain 🔗 (Requiere Gas y minado)",
//                              style: TextStyle(color: isOffChain ? colorScheme.secondary : colorScheme.primary, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     TextField(
//                       controller: addressController,
//                       style: TextStyle(color: onSurfaceColor),
//                       onChanged: (val) => setStateModal(() => direccionDestino = val),
//                       decoration: InputDecoration(
//                         labelText: "Destino (0x... o @alias)",
//                         prefixIcon: const Icon(Icons.account_balance_wallet),
//                         filled: true,
//                        fillColor: onSurfaceColor.withOpacity(0.05), // 🔥 Input limpio
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 Borde 16
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     TextField(
//                       controller: montoController,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       style: TextStyle(color: onSurfaceColor),
//                       onChanged: (val) => setStateModal(() => montoIngresado = double.tryParse(val) ?? 0),
//                       decoration: InputDecoration(
//                         labelText: "Monto a enviar",
//                         prefixIcon: const Icon(Icons.attach_money),
//                         filled: true,
//                        fillColor: onSurfaceColor.withOpacity(0.05), // 🔥 Input limpio
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 Borde 16
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//                     Container(
//       margin: const EdgeInsets.only(top: 5, bottom: 25),
//       decoration: BoxDecoration(
//         color: isPaid ? Colors.green.withOpacity(0.1) : onSurfaceColor.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: isPaid ? Colors.green : Colors.transparent)
//       ),
//       child: SwitchListTile(
//         activeColor: Colors.green,
//         title: Text("Pago Comercial", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
//         subtitle: Text("Actívalo si pagas en un comercio. No te sugeriremos guardar el contacto.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12)),
//         value: isPaid,
//         onChanged: (val) => setStateModal(() => isPaid = val),
//       ),
//     ),

//                     // 🔥 ACCOUNT ABSTRACTION UI (GASLESS) 🔥
//                     if (!isOffChain)
//                       Container(
//                         margin: const EdgeInsets.only(bottom: 20),
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: colorScheme.primary.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
//                               child: Icon(Icons.local_gas_station_rounded, color: colorScheme.primary, size: 20),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
//                                   Row(
//                                     children: [
//                                       Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.5), decoration: TextDecoration.lineThrough)),
//                                       const SizedBox(width: 6),
//                                       Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
//                               child: const Text("Patrocinado", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
//                             )
//                           ],
//                         ),
//                       ),

//                     // 🔥 BOTÓN PRINCIPAL DE ENVÍO CRYPTO 🔥
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                          backgroundColor: isOffChain ? colorScheme.secondary : colorScheme.primary, // 🔥 M3
//                           foregroundColor: isOffChain ? colorScheme.onSecondary : colorScheme.onPrimary,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde 16
//                         ),
//                         onPressed: (isProcessing || destinoLimpio.isEmpty || montoIngresado <= 0) ? null : () async {

//                           // 🛡️ 1. ESCUDO ANTI-POISONING (Solo On-Chain)
//                           HapticFeedback.mediumImpact();
//                           if (!isOffChain) {
//                             setStateModal(() => isProcessing = true);
//                             List<dynamic> misContactos = await userService.getUserContacts();
                            
//                             bool isKnown = misContactos.any((c) => 
//                               c['contactAddress'].toString().toLowerCase() == destinoLimpio.toLowerCase()
//                             );

//                             setStateModal(() => isProcessing = false);

//                             if (!isKnown) {
//                               bool proceed = await _mostrarAlertaPoisoning(rootContext, destinoLimpio);
//                               if (!proceed) return; // Si el usuario cancela, abortamos todo
//                             }
//                           }

//                           // 🔥 1. EL VALIDADOR DE LIQUIDEZ 🔥
//                         //   double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
//                         // if (montoIngresado > saldoActual) {
//                         //     if (fromBurnerAddress != null) {
//                         //       // Es una Burner Wallet: Solo mostramos error
//                         //       mostrarMensaje("La tarjeta virtual no tiene saldo suficiente. Saldo actual: $saldoActual TTC", esError: true);
//                         //       setStateModal(() => isProcessing = false);
//                         //       return;
//                         //     } else {
//                         //       // Es la Billetera Principal: Mostramos el Upsell de Compra
//                         //       double faltante = montoIngresado - saldoActual;
//                         //       mostrarUpsellDeCompra(rootContext, faltante, onUpdateBalance, isGroupPayment);
//                         //       setStateModal(() => isProcessing = false);
//                         //       return; 
//                         //     }
//                         //   }

//                         double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
//                           if (montoIngresado > saldoActual) {
//                             // Es la Billetera Principal: Mostramos el Upsell de Compra
//                             double faltante = montoIngresado - saldoActual;
//                             mostrarUpsellDeCompra(rootContext, faltante, onUpdateBalance, isGroupPayment);
//                             setStateModal(() => isProcessing = false);
//                             return; 
//                           }

//                           FocusScope.of(context).unfocus();
                          
//                           bool proceedSimulation = await TransactionSimulatorModal.show(
//                             context: rootContext,
//                             amount: montoIngresado,
//                             destination: destinoLimpio,
//                             currentBalance: saldoActual,
//                             isOffChain: isOffChain,
//                           ) ?? false;

//                           if (!proceedSimulation) {
//                             setStateModal(() => isProcessing = false);
//                             return; // El usuario se arrepintió al ver los números
//                           }
                          
//                           showDialog(
//                             context: rootContext, 
//                             barrierDismissible: false, 
//                             builder: (_) => TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar el envío.")
//                           );
                          
                          
//                           // 🔥 HUELLA DACTILAR ANTES DE ENVIAR
//                         //   bool isAuth = await authCore.authenticateUser();

//                         //  // Navigator.pop(rootContext);
                          
//                         //   if (!isAuth) {
//                         //     Navigator.pop(rootContext);
//                         //     mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
//                         //     return; 
//                         //   }

//                         BigInt amountWei = BigInt.from(montoIngresado * 1e18);
//                           String? signature;
                          
//                           if (isOffChain) {
//                             bool isAuth = await authCore.authenticateUser();
//                             if (!isAuth) {
//                               Navigator.pop(rootContext);
//                               mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
//                               return; 
//                             }
//                           } else {
//                             signature = await authCore.generateDelegatedSignature(
//                                 "SEND", 
//                                 toAddress: destinoLimpio, 
//                                 amountWei: amountWei
//                             );

//                             if (signature == null) {
//                               Navigator.pop(rootContext);
//                               mostrarMensaje("Autenticación o firma cancelada. Envío abortado.", esError: true);
//                               return; 
//                             }
//                           }

//                           Navigator.pop(rootContext); // 1. Quitar Skeleton de Huella
//                           Navigator.pop(ctx);         // 2. Quitar Modal Inferior de Send (¡ANTES de abrir Pending!)

                       

//                           try {
//                             String txHashResult = "0x...";
//                             String tipoTxFinal = isOffChain ? 'BINANCE_PAY' : 'SEND';

//                             Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
//                                 customTitle: isOffChain ? "Envío Instantáneo" : "Minando Envío", 
//                                 customMessage: isOffChain ? "Transfiriendo por Binance Pay..." : "Registrando en Blockchain...", 
//                                 recipientAddress: destinoLimpio, 
//                                 isGroupPayment: isGroupPayment, 
//                                 expectedTxType: tipoTxFinal, 
//                                 onUpdateBalance: onUpdateBalance 
//                             )));

//                           //   if (isOffChain) {
//                           //     String aliasParaBackend = destinoLimpio.startsWith("@") ? destinoLimpio.substring(1).trim() : destinoLimpio.trim();
//                           //     Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( customTitle: "Envío Instantáneo", customMessage: "Transfiriendo por Binance Pay...", 
//                           //       recipientAddress: destinoLimpio, isGroupPayment: isGroupPayment, expectedTxType: "BINANCE_PAY", onUpdateBalance: onUpdateBalance 
//                           //     )));

//                           //     final res = await txService.sendOffChainAlias(aliasParaBackend, montoIngresado);
//                           //     if (res.startsWith("Error")) { 
//                           //       Navigator.pop(rootContext); mostrarMensaje(res, esError: true);
//                           //       return;
//                           //     } else {
//                           //       txHashResult = res.replaceAll("Exito: ", "").trim();
//                           //       if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                           //       if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
//                           //     }
//                           //   } else {
//                           //     Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( customTitle: "Minando Envío", customMessage: "Registrando en Blockchain...", 
//                           //       isGroupPayment: isGroupPayment, recipientAddress: destinoLimpio, expectedTxType: "SEND", onUpdateBalance: onUpdateBalance 
//                           //     )));

//                           //   //  final res = await service.sendTokensL2(destinoLimpio, montoIngresado);
//                           //   final res = fromBurnerAddress != null 
//                           //       ? await burnerService.sendFromBurnerWallet(fromBurnerAddress, destinoLimpio, montoIngresado)
//                           //       : await txService.sendTokensL2(destinoLimpio, montoIngresado);
                                
//                           //     if (res.startsWith("Error")) { 
//                           //       Navigator.pop(rootContext); mostrarMensaje(res, esError: true); 
//                           //       return;
//                           //     } else {
//                           //       txHashResult = res.replaceAll("Exito: ", "").trim();
//                           //       if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                           //       if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
//                           //     }
//                           //   }

//                           //   // 🔥 INVOCAMOS LA LÓGICA DE COMPROBANTES
//                           //   await _manejarFlujoPostPago(
//                           //     rootContext: rootContext,
//                           //     tipoTx: tipoTxFinal,
//                           //     montoIngresado: montoIngresado,
//                           //     txHashResult: txHashResult,
//                           //     destinoLimpio: destinoLimpio,
//                           //     isPaid: isPaid
//                           //   );

//                           // } finally {
//                           //   if (ctx.mounted) setStateModal(() => isProcessing = false);
//                           // }

//                          if (isOffChain) {
//                               String aliasParaBackend = destinoLimpio.startsWith("@") ? destinoLimpio.substring(1).trim() : destinoLimpio.trim();
                              
//                               final res = await txService.sendOffChainAlias(aliasParaBackend, montoIngresado);
//                               if (res.startsWith("Error")) { 
//                                 Navigator.pop(rootContext, false); // Forzamos cierre de pending con error
//                                 mostrarMensaje(res, esError: true);
//                                 return;
//                               } else {
//                                 txHashResult = res.replaceAll("Exito: ", "").trim();
//                                 if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                                 if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
//                               }
//                             } else {
//                               // 🔥 LÓGICA DE ENVÍO L2 PURA (Sin Burner)
//                               //final res = await txService.sendTokensL2(destinoLimpio, montoIngresado);
//                               final res = await txService.sendTokensL2(destinoLimpio, montoIngresado, signature!);
                                  
//                               if (res.startsWith("Error")) { 
//                                 Navigator.pop(rootContext, false); // Forzamos cierre de pending con error
//                                 mostrarMensaje(res, esError: true); 
//                                 return;
//                               } else {
//                                 txHashResult = res.replaceAll("Exito: ", "").trim();
//                                 if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                                 if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
//                               }
//                             }

//                             // 🔥 AHORA SÍ ESPERAMOS A QUE LA PANTALLA PENDING CONFIRME EL WEBSOCKET
//                             final result = await pendingFuture;

//                             // SI FUE EXITOSA, MOSTRAMOS EL POPUP DE COMPROBANTE
//                             if (result == true) {
//                               // 🔥 Se eliminó el onTransferSuccess
                              
//                               await _manejarFlujoPostPago(
//                                 rootContext: rootContext,
//                                 tipoTx: tipoTxFinal,
//                                 montoIngresado: montoIngresado,
//                                 txHashResult: txHashResult,
//                                 destinoLimpio: destinoLimpio,
//                                 isPaid: isPaid
//                               );
//                             }

//                           } finally {
//                             if (ctx.mounted) setStateModal(() => isProcessing = false);
//                           }
//                         },
//                         child: isProcessing 
//                           ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                           : Text(isOffChain ? "Enviar Instantáneo" : "Firmar Envío Web3", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                       ),
//                     ),

//                     if (!isOffChain) ...[
//                       const SizedBox(height: 20),
//                       Row(
//                         children: [
//                           Expanded(child: Divider(color: onSurfaceColor.withOpacity(0.2))),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 10),
//                             child: Text("O PAGA CON FIAT", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
//                           ),
//                           Expanded(child: Divider(color: onSurfaceColor.withOpacity(0.2))),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: OutlinedButton.icon(
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: colorScheme.onSurface,
//                             side: BorderSide(
//                               color: (destinoLimpio.isEmpty || montoIngresado <= 0) 
//                                   ? colorScheme.onSurface.withOpacity(0.1) 
//                                   : colorScheme.onSurface.withOpacity(0.3), 
//                               width: 1.5
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                           ),
//                           icon: isProcessing 
//                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2)) 
//                               : Icon(Icons.g_mobiledata, color: (destinoLimpio.isEmpty || montoIngresado <= 0) ? Colors.white24 : Colors.blueAccent, size: 36),
//                           label: Text(
//                             isProcessing ? "Procesando..." : "Pagar con Google Pay",
//                             style: TextStyle(color: (destinoLimpio.isEmpty || montoIngresado <= 0) ? Colors.white24 : Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)
//                           ),
//                           onPressed: (destinoLimpio.isEmpty || montoIngresado <= 0 || isProcessing) ? null : () async {
//                             setStateModal(() => isProcessing = true);

//                             showDialog(
//                             context: rootContext, 
//                             barrierDismissible: false, 
//                             builder: (_) => TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar el envío.")
//                           );

//                             HapticFeedback.mediumImpact();
//                             bool isAuth = await authCore.authenticateUser();

                            

//                             if (!isAuth) {
//                               Navigator.pop(rootContext);
//                               setStateModal(() => isProcessing = false);
//                               mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
//                               return;
//                             }

// Navigator.pop(rootContext); // 1. Quitar Skeleton de Huella
//                           Navigator.pop(ctx);
//                             setStateModal(() => isProcessing = true);
//                             //Navigator.pop(ctx); // Cierra el modal de envíos

//                             if (payClient == null) {
//                               mostrarMensaje("Cargando servicios de Google, intenta de nuevo.", esError: true);
//                               return;
//                             }
                            
//                             // 🔥 INICIO DEL FLUJO HÍBRIDO (REAL / SIMULADOR) 🔥
//                             try {
//                               // 1. Intentamos abrir la pasarela real de Google Pay
//                               final result = await payClient!.showPaymentSelector(
//                                 PayProvider.google_pay, 
//                                 [ PaymentItem(label: 'Envío de TTC a $destinoLimpio', amount: montoIngresado.toStringAsFixed(2), status: PaymentItemStatus.final_price) ],
//                               );
//                             } catch (e) {
//                               // 2. 🔥 SI FALLA (Por falta de Wallet en el Emulador), SIMULAMOS 🔥
//                               print("Error nativo de GPay atrapado: $e");
//                               mostrarMensaje("Billetera inactiva. Usando modo simulador de pago...");
//                               await Future.delayed(const Duration(seconds: 2)); 
//                             }

//                             // try {
//                             //   // 3. FLUJO COMÚN (Para pagos Reales o Simulados)
//                             //   Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                             //     customTitle: "Enviando y Recompensando", 
//                             //     customMessage: "Acreditando Cashback en tu billetera...",
//                             //     isGroupPayment: isGroupPayment,
//                             //     recipientAddress: destinoLimpio, 
//                             //     expectedTxType: "SEND_FIAT", 
//                             //     onUpdateBalance: onUpdateBalance
//                             //   )));

//                             //   Navigator.pop(ctx);

//                             //   String orderId = "GPAY-SEND-${DateTime.now().millisecondsSinceEpoch}"; 
//                             //   final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);

//                             //  if (res.startsWith("Error")) {
//                             //     Navigator.pop(rootContext);
//                             //     mostrarMensaje(res, esError: true);
//                             //   } else {
//                             //     String txHashResult = res.replaceAll("Exito: ", "").trim();
//                             //     // 🔥 3. AÑADIDO: Éxito en Google Pay / Simulador
//                             //     if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                             //     if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
//                             //     await _manejarFlujoPostPago(
//                             //       rootContext: rootContext,
//                             //       tipoTx: 'SEND_FIAT',
//                             //       montoIngresado: montoIngresado,
//                             //       txHashResult: txHashResult,
//                             //       destinoLimpio: destinoLimpio,
//                             //       isPaid: isPaid
//                             //     );
//                             //   }
//                             // } catch (e) {
//                             //   Navigator.pop(rootContext);
//                             //   mostrarMensaje("Error al procesar la orden en el servidor.", esError: true);
//                             // }

//                             try {
//                               // 3. FLUJO COMÚN (Para pagos Reales o Simulados)
//                               Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                                 customTitle: "Enviando y Recompensando", 
//                                 customMessage: "Acreditando Cashback en tu billetera...",
//                                 isGroupPayment: isGroupPayment,
//                                 recipientAddress: destinoLimpio, 
//                                 expectedTxType: "SEND_FIAT", 
//                                 onUpdateBalance: onUpdateBalance
//                               )));

//                               String orderId = "GPAY-SEND-${DateTime.now().millisecondsSinceEpoch}"; 
//                               final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);

//                              if (res.startsWith("Error")) {
//                                 Navigator.pop(rootContext, false);
//                                 mostrarMensaje(res, esError: true);
//                               } else {
//                                 String txHashResult = res.replaceAll("Exito: ", "").trim();
//                                 if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                                 if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
                                
//                                 // ESPERAMOS LA CONFIRMACIÓN
//                                 final result = await pendingFuture;

//                                 if (result == true) {

//                                   if (onTransferSuccess != null) {
//                                 onTransferSuccess(montoIngresado, txHashResult);
//                               }

//                                   await _manejarFlujoPostPago(
//                                     rootContext: rootContext,
//                                     tipoTx: 'SEND_FIAT',
//                                     montoIngresado: montoIngresado,
//                                     txHashResult: txHashResult,
//                                     destinoLimpio: destinoLimpio,
//                                     isPaid: isPaid
//                                   );
//                                 }
//                               }
//                             } catch (e) {
//                               mostrarMensaje("Error al procesar la orden.", esError: true);
//                             }
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 10),

//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                            backgroundColor: colorScheme.primary, // 🔥 Primary
//                 foregroundColor: colorScheme.onPrimary,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde 16 M3
//                           ),
//                           icon: const Icon(Icons.paypal, color: Colors.white),
//                           label: const Text("Pagar con PayPal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                           onPressed: (destinoLimpio.isEmpty || montoIngresado <= 0) ? null : () async {
                            
//                             showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar el envío."));

//                             HapticFeedback.mediumImpact();
//                             // bool isAuth = await authCore.authenticateUser();
//                             // if (!isAuth) {
//                             //   Navigator.pop(rootContext);
//                             //   mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
//                             //   return; 
//                             // }

//                             BigInt amountWei = BigInt.from(montoIngresado * 1e18);
//                           String? signature;
                          
//                           if (isOffChain) {
//                             bool isAuth = await authCore.authenticateUser();
//                             if (!isAuth) {
//                               Navigator.pop(rootContext);
//                               mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
//                               return; 
//                             }
//                           } else {
//                             signature = await authCore.generateDelegatedSignature(
//                                 "SEND", 
//                                 toAddress: destinoLimpio, 
//                                 amountWei: amountWei
//                             );

//                             if (signature == null) {
//                               Navigator.pop(rootContext);
//                               mostrarMensaje("Autenticación o firma cancelada. Envío abortado.", esError: true);
//                               return; 
//                             }
//                           }
//                             Navigator.pop(rootContext);
//                             Navigator.pop(ctx);

//                             Navigator.of(rootContext).push(
//                               MaterialPageRoute(
//                                 builder: (BuildContext context) => UsePaypal(
//                                   sandboxMode: true,
//                                   clientId: "AW91VEGq61jntCQhvokYTUOaxCVcizMrknQfIkXklZtzlNDZdWN74Un4PIxng_hxrTot6_TuDyv1o24W",
//                                   secretKey: "ELBDqAKGPSxRGp-LutS9fgTiFIswAan_9wVyK5MqnGQcGfMllkUA9C1AyrJcXxXyPuoSTLl0EXwHAtoE",
//                                   returnURL: "https://sandbox.paypal.com/return",
//                                   cancelURL: "https://sandbox.paypal.com/cancel",
//                                   transactions: [
//                                     {
//                                       "amount": {
//                                         "total": montoIngresado.toStringAsFixed(2),
//                                         "currency": "USD",
//                                         "details": {
//                                           "subtotal": montoIngresado.toStringAsFixed(2),
//                                           "shipping": '0',
//                                           "shipping_discount": 0
//                                         }
//                                       },
//                                       "description": "Envío de TTC a $destinoLimpio",
//                                       "item_list": {
//                                         "items": [
//                                           {
//                                             "name": "Envío TTC a Billetera",
//                                             "quantity": 1,
//                                             "price": montoIngresado.toStringAsFixed(2),
//                                             "currency": "USD"
//                                           }
//                                         ]
//                                       }
//                                     }
//                                   ],
//                                   note: "Envío seguro de TTC.",
                              
//                                 // onSuccess: (Map params) {
//                                 //     Future.delayed(const Duration(milliseconds: 500), () async {
//                                 //       Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(customTitle: "Enviando y Recompensando", customMessage: "Entregando fondos y calculando tu Cashback...",
//                                 //         isGroupPayment: isGroupPayment,
//                                 //         recipientAddress: destinoLimpio, expectedTxType: "SEND_FIAT", onUpdateBalance: onUpdateBalance 
//                                 //       )));
//                                 //       String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
//                                 //       final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);
//                                 //       if (res.startsWith("Error")) { 
//                                 //         Navigator.pop(rootContext); mostrarMensaje(res, esError: true); 
//                                 //       } else {
//                                 //         String txHashResult = res.replaceAll("Exito: ", "").trim();
//                                 //         if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                                 //         if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);

//                                 //         // 🔥 INVOCAMOS LA LÓGICA DE COMPROBANTES PARA PAYPAL
//                                 //         await _manejarFlujoPostPago(
//                                 //           rootContext: rootContext,
//                                 //           tipoTx: 'SEND_FIAT',
//                                 //           montoIngresado: montoIngresado,
//                                 //           txHashResult: txHashResult,
//                                 //           destinoLimpio: destinoLimpio,
//                                 //           isPaid: isPaid
//                                 //         );
//                                 //       }
//                                 //     });
//                                 //   },
//                                 onSuccess: (Map params) {
//                                     Future.delayed(const Duration(milliseconds: 500), () async {
                                      
//                                       Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                                         customTitle: "Enviando y Recompensando", customMessage: "Entregando fondos y calculando tu Cashback...",
//                                         isGroupPayment: isGroupPayment,
//                                         recipientAddress: destinoLimpio, expectedTxType: "SEND_FIAT", onUpdateBalance: onUpdateBalance 
//                                       )));

//                                       String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
//                                       final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);
                                      
//                                       if (res.startsWith("Error")) { 
//                                         Navigator.pop(rootContext, false); 
//                                         mostrarMensaje(res, esError: true); 
//                                       } else {
//                                         String txHashResult = res.replaceAll("Exito: ", "").trim();
//                                         if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
//                                         if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);

//                                         // ESPERAMOS LA CONFIRMACIÓN DEL WEBSOCKET
//                                         final result = await pendingFuture;

//                                         if (result == true) {

//                                           if (onTransferSuccess != null) {
//                                 onTransferSuccess(montoIngresado, txHashResult);
//                               }
                              
//                                           await _manejarFlujoPostPago(
//                                             rootContext: rootContext,
//                                             tipoTx: 'SEND_FIAT',
//                                             montoIngresado: montoIngresado,
//                                             txHashResult: txHashResult,
//                                             destinoLimpio: destinoLimpio,
//                                             isPaid: isPaid
//                                           );
//                                         }
//                                       }
//                                     });
//                                   },
//                                   onError: (error) { mostrarMensaje("Error en PayPal: $error", esError: true); },
//                                   onCancel: (params) { mostrarMensaje("Pago cancelado", esError: true); },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       }
//     );
//   }
  
//   // 🛡️ POPUP DE ALERTA ANTI-POISONING
//   static Future<bool> _mostrarAlertaPoisoning(BuildContext context, String direccion) async {
//     bool proceed = false;
//     await showDialog(
//       context: context,
//       builder: (ctx) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//           icon: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 40),
//           title: const Text("Dirección Desconocida", textAlign: TextAlign.center),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Estás a punto de enviar dinero a una billetera que NO está en tus contactos.",
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 15),
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                 child: Text(
//                   direccion,
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               const Text("⚠️ Revisa los caracteres centrales. Las estafas de 'Address Poisoning' usan direcciones casi idénticas a las de tus amigos.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)
//             ],
//           ),
//           actionsAlignment: MainAxisAlignment.spaceBetween,
//           actions: [
//             TextButton(
//               onPressed: () {HapticFeedback.mediumImpact(); proceed = false; Navigator.pop(ctx); },
//               child: const Text("Cancelar", style: TextStyle(color: Colors.blue)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
//               onPressed: () {HapticFeedback.mediumImpact(); proceed = true; Navigator.pop(ctx); },
//               child: const Text("Estoy seguro"),
//             )
//           ],
//         );
//       }
//     );
//     return proceed;
//   }

//   // 🔥 NUEVO MÉTODO PARA MANEJAR EL FLUJO POST-PAGO EN TODOS LOS ESCENARIOS
//   static Future<void> _manejarFlujoPostPago({
//     required BuildContext rootContext,
//    // required BlockchainService service,
//     required String tipoTx,
//     required double montoIngresado,
//     required String txHashResult,
//     required String destinoLimpio,
//     required bool isPaid,
//   }) async {
//     final authCore = Provider.of<AuthCoreService>(rootContext, listen: false);
// final userService = Provider.of<UserService>(rootContext, listen: false);

//     // 1. CONSTRUIMOS UN OBJETO MOCK DE TRANSACCIÓN PARA EL COMPROBANTE
//     dynamic mockTx = {
//       'txType': tipoTx, // 'SEND', 'BINANCE_PAY', 'SEND_FIAT'
//       'amount': montoIngresado,
//       'txHash': txHashResult,
//       'senderAddress': authCore.publicAddress,
//       'receiverAddress': destinoLimpio,
//       'status': 'COMPLETED',
//       'timestamp': DateTime.now().toIso8601String()
//     };

//    if (isPaid) {
//       bool? verComprobante = await UIHelper.mostrarConfirmacion(
//         context: rootContext,
//         titulo: "Transacción Exitosa",
//         mensaje: "¿Deseas ver el comprobante de pago ahora para compartirlo al comercio?",
//         textoConfirmar: "Ver Comprobante",
//         colorConfirmar: Colors.green,
//       );

//       if (verComprobante == true) {
//         await Navigator.push(rootContext, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
//       }
//     } 
//     // 🔥 2. SI NO ES COMERCIAL -> SUGERIMOS GUARDAR EL CONTACTO
//     else {
//       List<dynamic> misContactos = await userService.getUserContacts();
//       bool isKnown = misContactos.any((c) => c['contactAddress'].toString().toLowerCase() == destinoLimpio.toLowerCase() || "@${c['alias']}".toLowerCase() == destinoLimpio.toLowerCase());
      
//       if (!isKnown) {
//         TransactionDetailsModal.mostrarDialogoGuardarContacto(rootContext, rootContext, destinoLimpio, authCore.publicAddress);
//       } else {
//          UIHelper.showCustomSnackbar("Envío exitoso a $destinoLimpio");
//       }
//     }
//   }
  
//   // 🛍️ EL POPUP DE UPSELL (VENTA CRUZADA)
//   static void mostrarUpsellDeCompra(BuildContext context, double faltante, VoidCallback onUpdateBalance, bool isGroupPayment) {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//        final theme = Theme.of(ctx); // 🔥 Inyección M3
//         final colorScheme = theme.colorScheme;
//         final onSurfaceColor = colorScheme.onSurface;
        
//         return AlertDialog(
//          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//           backgroundColor: Theme.of(context).cardColor,
//           title: Row(
//             children: [
//               Icon(Icons.warning_amber_rounded, color: colorScheme.secondary, size: 28), // 🔥 Secondary
//               const SizedBox(width: 10),
//               Text("Saldo Insuficiente", style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.w900)),
//             ],
//           ),
//           content: Text(
//             "Te faltan ${faltante.toStringAsFixed(2)} TTC para realizar este envío.\n\n¿Deseas adquirir más tokens ahora mismo?",
//             style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 15),
//           ),
//           actionsAlignment: MainAxisAlignment.spaceBetween,
//           actions: [
//             TextButton(
//               onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx); },
//               child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
//             ),
            
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                backgroundColor: colorScheme.primary, // 🔥 Primary
//                 foregroundColor: colorScheme.onPrimary,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde 16 M3
//               ),
//               icon: const Icon(Icons.credit_card, color: Colors.white, size: 18),
//               label: const Text("Comprar TTC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//               onPressed: () {
//                 Navigator.pop(ctx); // Cerramos el Popup
//                 Navigator.pop(context); // Cerramos el Modal de Envío
                
//                 // Abrimos el Modal de Compra directamente
//                 BuyModal.show(
//                   context: context,
//                  // balanceTTC: "0", // Solo es visual
//                  isGroupPayment: isGroupPayment,
//                   onUpdateBalance: onUpdateBalance, 
//                   mostrarMensaje: (msg, {bool esError = false}) {
//                   UIHelper.showCustomSnackbar(msg, isError: esError);
//                   }
//                 );
//               },
//             )
//           ],
//         );
//       }
//     );
//   }
// }

class SendModal {
  static void show({
    required BuildContext context,
    required String balanceTTC,
    required VoidCallback onUpdateBalance,
    required void Function(String, {bool esError}) mostrarMensaje,
    String? initialAddress,
    String? initialAmount,
    String? initialAlias,
    bool isGroupPayment = false,
    String? debtId,
    String? sharedDebtId,
    Function(double amount, String txHash)? onTransferSuccess,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false); 
    
    BuildContext rootContext = context;

    Pay? payClient;
    PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
      payClient = Pay({ PayProvider.google_pay: config });
    });

    final TextEditingController addressController = TextEditingController(text: initialAddress ?? "");
    final TextEditingController montoController = TextEditingController(text: initialAmount ?? "");
    
    String direccionDestino = (initialAddress ?? "").trim();
    double montoIngresado = double.tryParse(initialAmount ?? '0') ?? 0.0;
    
    bool isProcessing = false;
    bool isPaid = false;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx); 
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;
        final cardColor = theme.cardColor;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            String destinoLimpio = direccionDestino.trim();
            bool isOffChain = destinoLimpio.startsWith("@");

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)) 
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Enviar TTC", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                          onPressed: () async {
                            final scannedAddress = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                            );
                            if (scannedAddress != null) {
                              setStateModal(() {
                                addressController.text = scannedAddress.trim();
                                direccionDestino = scannedAddress.trim();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: onSurfaceColor.withOpacity(0.6)),
                          onPressed: () => Navigator.pop(ctx)
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOffChain ? Colors.amber.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isOffChain ? colorScheme.secondary.withOpacity(0.5) : colorScheme.primary.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(isOffChain ? Icons.flash_on_rounded : Icons.link_rounded, color: isOffChain ? colorScheme.secondary : colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isOffChain ? "Modo Pay ⚡ (Instantáneo y 0 Gas)" : "Modo On-Chain 🔗 (Requiere Gas y minado)",
                              style: TextStyle(color: isOffChain ? colorScheme.secondary : colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: addressController,
                      style: TextStyle(color: onSurfaceColor),
                      onChanged: (val) => setStateModal(() => direccionDestino = val),
                      decoration: InputDecoration(
                        labelText: "Destino (0x... o @alias)",
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        filled: true,
                        fillColor: onSurfaceColor.withOpacity(0.05), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: onSurfaceColor),
                      onChanged: (val) => setStateModal(() => montoIngresado = double.tryParse(val) ?? 0),
                      decoration: InputDecoration(
                        labelText: "Monto a enviar",
                        prefixIcon: const Icon(Icons.attach_money),
                        filled: true,
                        fillColor: onSurfaceColor.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    Container(
                      margin: const EdgeInsets.only(top: 5, bottom: 25),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withOpacity(0.1) : onSurfaceColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isPaid ? Colors.green : Colors.transparent)
                      ),
                      child: SwitchListTile(
                        activeColor: Colors.green,
                        title: Text("Pago Comercial", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                        subtitle: Text("Actívalo si pagas en un comercio. No te sugeriremos guardar el contacto.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12)),
                        value: isPaid,
                        onChanged: (val) => setStateModal(() => isPaid = val),
                      ),
                    ),

                    if (!isOffChain)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.local_gas_station_rounded, color: colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                  Row(
                                    children: [
                                      Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.5), decoration: TextDecoration.lineThrough)),
                                      const SizedBox(width: 6),
                                      Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                              child: const Text("Patrocinado", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),

                    // =======================================================
                    // 🔥 1. BOTÓN PRINCIPAL DE ENVÍO CRYPTO (L2 Y OFF-CHAIN)
                    // =======================================================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOffChain ? colorScheme.secondary : colorScheme.primary, 
                          foregroundColor: isOffChain ? colorScheme.onSecondary : colorScheme.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                        ),
                        onPressed: (isProcessing || destinoLimpio.isEmpty || montoIngresado <= 0) ? null : () async {

                          HapticFeedback.mediumImpact();
                          
                          // 🔥 FIX 1: LÓGICA DE CONTACTOS RESTAURADA PARA AMBOS MODOS
                          setStateModal(() => isProcessing = true);
                          List<dynamic> misContactos = await userService.getUserContacts();
                          
                          bool isKnown = misContactos.any((c) => 
                            c['contactAddress'].toString().toLowerCase() == destinoLimpio.toLowerCase() ||
                            (c['alias'] != null && "@${c['alias']}".toLowerCase() == destinoLimpio.toLowerCase())
                          );
                          setStateModal(() => isProcessing = false);

                          // El aviso de Poisoning lo mostramos si no es conocido y ES una dirección 0x
                          if (!isKnown && !isOffChain) {
                            bool proceed = await _mostrarAlertaPoisoning(rootContext, destinoLimpio);
                            if (!proceed) return; 
                          }

                          double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
                          if (montoIngresado > saldoActual) {
                            double faltante = montoIngresado - saldoActual;
                            mostrarUpsellDeCompra(rootContext, faltante, onUpdateBalance, isGroupPayment);
                            return; 
                          }

                          FocusScope.of(context).unfocus();

                          // double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
                          // if (montoIngresado > saldoActual) {
                          //   double faltante = montoIngresado - saldoActual;
                          //   mostrarUpsellDeCompra(rootContext, faltante, onUpdateBalance, isGroupPayment);
                          //   setStateModal(() => isProcessing = false);
                          //   return; 
                          // }

                          // FocusScope.of(context).unfocus();
                          
                          bool proceedSimulation = await TransactionSimulatorModal.show(
                            context: rootContext, amount: montoIngresado, destination: destinoLimpio,
                            currentBalance: saldoActual, isOffChain: isOffChain,
                          ) ?? false;

                          if (!proceedSimulation) {
                            setStateModal(() => isProcessing = false);
                            return; 
                          }
                          
                          BigInt amountWei;
                          try {
                            List<String> parts = montoIngresado.toString().split('.');
                            BigInt enteros = BigInt.parse(parts[0]) * BigInt.from(10).pow(18);
                            BigInt decimales = parts.length > 1 ? BigInt.parse(parts[1].padRight(18, '0').substring(0, 18)) : BigInt.zero;
                            amountWei = enteros + decimales;
                          } catch(e) {
                            amountWei = BigInt.from(montoIngresado * 1e18);
                          }

                          String? signature;
                          
                          if (isOffChain) {
                            // 🔥 Aquí sí pedimos huella porque NO pasa por la firma Web3 (Es Off-Chain)
                            bool isAuth = await authCore.authenticateUser();
                            if (!isAuth) {
                              mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
                              return; 
                            }
                          } else {
                            // 🔥 Aquí NO pedimos huella extra, `generateDelegatedSignature` ya lo hace por dentro
                            signature = await authCore.generateDelegatedSignature(
                                "SEND", 
                                toAddress: destinoLimpio.toLowerCase().trim(), 
                                amountWei: amountWei
                            );

                            if (signature == null) {
                              mostrarMensaje("Firma cancelada o fallida. Envío abortado.", esError: true);
                              return; 
                            }
                          }

                          Navigator.pop(ctx); 

                         try {
                            String txHashResult = "0x...";
                            String tipoTxFinal = isOffChain ? 'BINANCE_PAY' : 'SEND';

                            Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
                                customTitle: isOffChain ? "Envío Instantáneo" : "Minando Envío", 
                                customMessage: isOffChain ? "Transfiriendo por Binance Pay..." : "Registrando en Blockchain...", 
                                recipientAddress: destinoLimpio, 
                                isGroupPayment: isGroupPayment, 
                                expectedTxType: tipoTxFinal, 
                                onUpdateBalance: onUpdateBalance 
                            )));

                            // 🔥 FIX 2: MICRO-RETRASO PARA EVITAR PANTALLA NEGRA
                            // Asegura que la animación de la pantalla de carga termine antes de que el Backend pueda lanzar un error rápido
                            await Future.delayed(const Duration(milliseconds: 500));

                            if (isOffChain) {
                              String aliasParaBackend = destinoLimpio.startsWith("@") ? destinoLimpio.substring(1).trim() : destinoLimpio.trim();
                              
                              final res = await txService.sendOffChainAlias(aliasParaBackend, montoIngresado);
                              if (res.startsWith("Error")) { 
                                Navigator.pop(rootContext, false); 
                                mostrarMensaje(res, esError: true);
                                return;
                              } else {
                                txHashResult = res.replaceAll("Exito: ", "").trim();
                                if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
                                if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
                              }
                            } else {
                              final res = await txService.sendTokensL2(destinoLimpio, montoIngresado, signature!);
                                  
                              if (res.startsWith("Error")) { 
                                Navigator.pop(rootContext, false); 
                                mostrarMensaje(res, esError: true); 
                                return;
                              } else {
                                txHashResult = res.replaceAll("Exito: ", "").trim();
                                if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
                                if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
                              }
                            }

                            final result = await pendingFuture;

                            if (result == true) {
                              if (onTransferSuccess != null) onTransferSuccess(montoIngresado, txHashResult);
                              
                              await _manejarFlujoPostPago(
                                rootContext: rootContext, tipoTx: tipoTxFinal, montoIngresado: montoIngresado,
                                txHashResult: txHashResult, destinoLimpio: destinoLimpio, isPaid: isPaid
                              );
                            }

                          } finally {
                            if (ctx.mounted) setStateModal(() => isProcessing = false);
                          }
                        },
                        child: isProcessing 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isOffChain ? "Enviar Instantáneo" : "Firmar Envío Web3", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    if (!isOffChain) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Divider(color: onSurfaceColor.withOpacity(0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("O PAGA CON FIAT", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: onSurfaceColor.withOpacity(0.2))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // =======================================================
                      // 🔥 2. BOTÓN DE GOOGLE PAY
                      // =======================================================
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: (destinoLimpio.isEmpty || montoIngresado <= 0) ? colorScheme.onSurface.withOpacity(0.1) : colorScheme.onSurface.withOpacity(0.3), width: 1.5
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2)) 
                                             : Icon(Icons.g_mobiledata, color: (destinoLimpio.isEmpty || montoIngresado <= 0) ? Colors.white24 : Colors.blueAccent, size: 36),
                          label: Text(
                            isProcessing ? "Procesando..." : "Pagar con Google Pay",
                            style: TextStyle(color: (destinoLimpio.isEmpty || montoIngresado <= 0) ? Colors.white24 : Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          onPressed: (destinoLimpio.isEmpty || montoIngresado <= 0 || isProcessing) ? null : () async {
                            HapticFeedback.mediumImpact();
                            
                            bool isAuth = await authCore.authenticateUser();
                            if (!isAuth) {
                              mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
                              return;
                            }

                            Navigator.pop(ctx); 
                            
                            if (payClient == null) {
                              mostrarMensaje("Cargando servicios de Google, intenta de nuevo.", esError: true);
                              return;
                            }
                            
                            try {
                              await payClient!.showPaymentSelector(
                                PayProvider.google_pay, 
                                [ PaymentItem(label: 'Envío de TTC a $destinoLimpio', amount: montoIngresado.toStringAsFixed(2), status: PaymentItemStatus.final_price) ],
                              );
                            } catch (e) {
                              mostrarMensaje("Billetera inactiva. Usando modo simulador de pago...");
                              await Future.delayed(const Duration(seconds: 2)); 
                            }

                            try {
                              Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                                customTitle: "Enviando y Recompensando", customMessage: "Acreditando Cashback en tu billetera...",
                                isGroupPayment: isGroupPayment, recipientAddress: destinoLimpio, expectedTxType: "SEND_FIAT", onUpdateBalance: onUpdateBalance
                              )));

                              String orderId = "GPAY-SEND-${DateTime.now().millisecondsSinceEpoch}"; 
                              final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);

                             if (res.startsWith("Error")) {
                                Navigator.pop(rootContext, false);
                                mostrarMensaje(res, esError: true);
                              } else {
                                String txHashResult = res.replaceAll("Exito: ", "").trim();
                                if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
                                if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);
                                
                                final result = await pendingFuture;

                                if (result == true) {
                                  if (onTransferSuccess != null) onTransferSuccess(montoIngresado, txHashResult);
                                  await _manejarFlujoPostPago(rootContext: rootContext, tipoTx: 'SEND_FIAT', montoIngresado: montoIngresado, txHashResult: txHashResult, destinoLimpio: destinoLimpio, isPaid: isPaid);
                                }
                              }
                            } catch (e) {
                              mostrarMensaje("Error al procesar la orden.", esError: true);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // =======================================================
                      // 🔥 3. BOTÓN DE PAYPAL
                      // =======================================================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary, 
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.paypal, color: Colors.white),
                          label: const Text("Pagar con PayPal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: (destinoLimpio.isEmpty || montoIngresado <= 0) ? null : () async {
                            HapticFeedback.mediumImpact();
                            
                            bool isAuth = await authCore.authenticateUser();
                            if (!isAuth) {
                              mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
                              return; 
                            }
                            
                            Navigator.pop(ctx);

                            Navigator.of(rootContext).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => UsePaypal(
                                  sandboxMode: true,
                                  clientId: "AW91VEGq61jntCQhvokYTUOaxCVcizMrknQfIkXklZtzlNDZdWN74Un4PIxng_hxrTot6_TuDyv1o24W",
                                  secretKey: "ELBDqAKGPSxRGp-LutS9fgTiFIswAan_9wVyK5MqnGQcGfMllkUA9C1AyrJcXxXyPuoSTLl0EXwHAtoE",
                                  returnURL: "https://sandbox.paypal.com/return",
                                  cancelURL: "https://sandbox.paypal.com/cancel",
                                  transactions: [
                                    {
                                      "amount": {
                                        "total": montoIngresado.toStringAsFixed(2),
                                        "currency": "USD",
                                        "details": { "subtotal": montoIngresado.toStringAsFixed(2), "shipping": '0', "shipping_discount": 0 }
                                      },
                                      "description": "Envío de TTC a $destinoLimpio",
                                      "item_list": { "items": [ { "name": "Envío TTC", "quantity": 1, "price": montoIngresado.toStringAsFixed(2), "currency": "USD" } ] }
                                    }
                                  ],
                                  note: "Envío seguro de TTC.",
                                  onSuccess: (Map params) {
                                    Future.delayed(const Duration(milliseconds: 500), () async {
                                      Future<dynamic> pendingFuture = Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                                        customTitle: "Enviando y Recompensando", customMessage: "Entregando fondos y calculando tu Cashback...",
                                        isGroupPayment: isGroupPayment, recipientAddress: destinoLimpio, expectedTxType: "SEND_FIAT", onUpdateBalance: onUpdateBalance 
                                      )));

                                      String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
                                      final res = await txService.sendTokensFiat(destinoLimpio, orderId, montoIngresado);
                                      
                                      if (res.startsWith("Error")) { 
                                        Navigator.pop(rootContext, false); 
                                        mostrarMensaje(res, esError: true); 
                                      } else {
                                        String txHashResult = res.replaceAll("Exito: ", "").trim();
                                        if (debtId != null) await debtService.payPersonalDebt(debtId, montoIngresado, destinoLimpio);
                                        if (sharedDebtId != null) await debtService.notifySharedDebtContribution(sharedDebtId, montoIngresado);

                                        final result = await pendingFuture;

                                        if (result == true) {
                                          if (onTransferSuccess != null) onTransferSuccess(montoIngresado, txHashResult);
                                          await _manejarFlujoPostPago(rootContext: rootContext, tipoTx: 'SEND_FIAT', montoIngresado: montoIngresado, txHashResult: txHashResult, destinoLimpio: destinoLimpio, isPaid: isPaid);
                                        }
                                      }
                                    });
                                  },
                                  onError: (error) { mostrarMensaje("Error en PayPal: $error", esError: true); },
                                  onCancel: (params) { mostrarMensaje("Pago cancelado", esError: true); },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
  
  static Future<bool> _mostrarAlertaPoisoning(BuildContext context, String direccion) async {
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 40),
          title: const Text("Dirección Desconocida", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Estás a punto de enviar dinero a una billetera que NO está en tus contactos.", textAlign: TextAlign.center),
              const SizedBox(height: 15),
              
              // 🔥 FIX 3: SCROLL Y LÍMITE DE ALTURA POR SI PEGAN TEXTOS/LOGS GIGANTES
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(direccion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent), textAlign: TextAlign.center),
                ),
              ),
              
              const SizedBox(height: 15),
              const Text("⚠️ Revisa los caracteres centrales. Las estafas de 'Address Poisoning' usan direcciones casi idénticas a las de tus amigos.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(onPressed: () {HapticFeedback.mediumImpact(); proceed = false; Navigator.pop(ctx); }, child: const Text("Cancelar", style: TextStyle(color: Colors.blue))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () {HapticFeedback.mediumImpact(); proceed = true; Navigator.pop(ctx); }, child: const Text("Estoy seguro"))
          ],
        );
      }
    );
    return proceed;
  }

  static Future<void> _manejarFlujoPostPago({
    required BuildContext rootContext, required String tipoTx, required double montoIngresado,
    required String txHashResult, required String destinoLimpio, required bool isPaid,
  }) async {
    final authCore = Provider.of<AuthCoreService>(rootContext, listen: false);
    final userService = Provider.of<UserService>(rootContext, listen: false);

    dynamic mockTx = {
      'txType': tipoTx, 'amount': montoIngresado, 'txHash': txHashResult,
      'senderAddress': authCore.publicAddress, 'receiverAddress': destinoLimpio,
      'status': 'COMPLETED', 'timestamp': DateTime.now().toIso8601String()
    };

   if (isPaid) {
      bool? verComprobante = await UIHelper.mostrarConfirmacion(
        context: rootContext, titulo: "Transacción Exitosa",
        mensaje: "¿Deseas ver el comprobante de pago ahora para compartirlo al comercio?", textoConfirmar: "Ver Comprobante", colorConfirmar: Colors.green,
      );

      if (verComprobante == true) {
        await Navigator.push(rootContext, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
      }
    } 
    else {
      List<dynamic> misContactos = await userService.getUserContacts();
      bool isKnown = misContactos.any((c) => c['contactAddress'].toString().toLowerCase() == destinoLimpio.toLowerCase() || "@${c['alias']}".toLowerCase() == destinoLimpio.toLowerCase());
      
      if (!isKnown) {
        TransactionDetailsModal.mostrarDialogoGuardarContacto(rootContext, rootContext, destinoLimpio, authCore.publicAddress);
      } else {
         UIHelper.showCustomSnackbar("Envío exitoso a $destinoLimpio");
      }
    }
  }
  
  static void mostrarUpsellDeCompra(BuildContext context, double faltante, VoidCallback onUpdateBalance, bool isGroupPayment) {
    showDialog(
      context: context,
      builder: (ctx) {
       final theme = Theme.of(ctx); 
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;
        
        return AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.secondary, size: 28), 
              const SizedBox(width: 10),
              Text("Saldo Insuficiente", style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          content: Text("Te faltan ${faltante.toStringAsFixed(2)} TTC para realizar este envío.\n\n¿Deseas adquirir más tokens ahora mismo?", style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 15)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(onPressed: () { HapticFeedback.mediumImpact(); Navigator.pop(ctx); }, child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.credit_card, color: Colors.white, size: 18),
              label: const Text("Comprar TTC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx); 
                Navigator.pop(context); 
                BuyModal.show(context: context, isGroupPayment: isGroupPayment, onUpdateBalance: onUpdateBalance, mostrarMensaje: (msg, {bool esError = false}) { UIHelper.showCustomSnackbar(msg, isError: esError); });
              },
            )
          ],
        );
      }
    );
  }
}