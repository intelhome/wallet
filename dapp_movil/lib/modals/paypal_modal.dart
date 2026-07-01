// import 'package:flutter/material.dart';
// import '../services/blockchain_service.dart';
// import '../modules/wallet_and_tx/screens/transaction_pending_screen.dart';
// class PaypalModal {
//   static void show({
//     required BuildContext context,
//     required BlockchainService service,
//     required VoidCallback onUpdateBalance,
//     required void Function(String, {bool esError}) mostrarMensaje,
//   }) {
//     double montoDolares = 0;
//     bool isProcessing = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,

//       builder: (ctx) {
//         final onSurfaceColor = Theme.of(ctx).colorScheme.onSurface;
//         final cardColor = Theme.of(ctx).cardColor;

//         return Container(
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight: Radius.circular(20),
//             ),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
//             left: 24,
//             right: 24,
//             top: 24,
//           ),
//           child: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setModalState) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Text(
//                     "Pago Seguro con PayPal",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: onSurfaceColor,
//                     ),
//                   ), // <-- CAMBIO
//                   const SizedBox(height: 5),
//                   const Text(
//                     "1 TTC = \$1.00 USD",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.greenAccent,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 25),

//                   TextField(
//                     style: TextStyle(color: onSurfaceColor, fontSize: 24),
//                     textAlign: TextAlign.center,
//                     enabled: !isProcessing,
//                     decoration: InputDecoration(
//                       labelText: "Monto a Invertir (USD)",
//                       labelStyle: TextStyle(
//                         color: onSurfaceColor.withOpacity(0.6),
//                         fontSize: 16,
//                       ),
//                       prefixIcon: const Icon(
//                         Icons.attach_money,
//                         color: Colors.greenAccent,
//                         size: 30,
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: onSurfaceColor.withOpacity(0.2),
//                         ),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Colors.blueAccent),
//                       ),
//                     ),
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     onChanged: (val) {
//                       setModalState(() {
//                         montoDolares = double.tryParse(val) ?? 0;
//                       });
//                     },
//                   ),

//                   const SizedBox(height: 15),

//                   if (montoDolares > 0)
//                     Text(
//                       "Recibirás: ${montoDolares.toStringAsFixed(2)} TTC",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: onSurfaceColor.withOpacity(0.8),
//                         fontSize: 16,
//                       ),
//                     )
//                   else
//                     const SizedBox(height: 19),

//                   const SizedBox(height: 30),

//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: const Color(
//                         0xFF003087,
//                       ), // Azul Oficial PayPal
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: isProcessing
//                         ? const SizedBox.shrink()
//                         : const Icon(Icons.payment),
//                     onPressed: (montoDolares <= 0 || isProcessing)
//                         ? null
//                         : () async {
//                             setModalState(() => isProcessing = true);

//                             if (await service.authenticateUser()) {
//                               // mostrarMensaje("Conectando con pasarela de PayPal...");

//                               mostrarMensaje("Pago aprobado. Acuñando TTC...");
//                               await Future.delayed(const Duration(seconds: 2));

//                               Navigator.pop(ctx);

//                               Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => TransactionPendingScreen(service: service),
//                             ),
//                           );
//                           service.buyTokensL2(montoDolares);
//                               // Llamada al backend
//                               // final resultado = await service.buyTokensL2(
//                               //   montoDolares,
//                               // );

//                               // if (!context.mounted) return;
//                               // Navigator.pop(context);

//                               // if (resultado.startsWith("Error")) {
//                               //   mostrarMensaje(resultado, esError: true);
//                               // } else {
//                               //   mostrarMensaje(
//                               //     "¡Inversión exitosa! TTC acreditados.",
//                               //   );
//                               //   onUpdateBalance();
//                               // }
//                             } else {
//                               // setModalState(() => isProcessing = false);
//                               if (!ctx.mounted) return;
//                           setModalState(() => isProcessing = false);
//                             }
//                           },
//                     label: isProcessing
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : const Text(
//                             "Pagar con PayPal",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                   ),s
//                 ],
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
