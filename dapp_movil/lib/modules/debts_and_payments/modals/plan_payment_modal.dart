import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

    final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');
    DateTime? fechaSeleccionada;
    bool guardando = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder( 
        builder: (contextDialog, setStateModal) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(ctx)),
                      const Expanded(child: Text("Planificar Pago", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: onSurface.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.send_time_extension_rounded, color: Color(0xFFC77DFF)),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Planificar Pago a @$aliasDestino", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Configura los detalles de la transferencia diferida.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, height: 1.4)),
                        const SizedBox(height: 16),
                        Divider(color: onSurface.withOpacity(0.05)),
                        const SizedBox(height: 16),

                        Text("Llave del Contacto", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: TextEditingController(text: addressDestino),
                          readOnly: true,
                          style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            filled: true, fillColor: theme.scaffoldBackgroundColor,
                            suffixIcon: Icon(Icons.lock_outline_rounded, color: onSurface.withOpacity(0.3), size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text("Monto a transferir (TTC)", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: montoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.attach_money_rounded, color: onSurface.withOpacity(0.5)),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFBAC3FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Gasless", style: TextStyle(color: Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 10))])
                            ),
                            filled: true, fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text("Motivo del pago (Opcional)", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: motivoController,
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "Ej: Pago alquiler",
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                            filled: true, fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text("Fecha de ejecución", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          readOnly: true,
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: fechaSeleccionada == null ? "dd/mm/aaaa --:--" : "${fechaSeleccionada!.day.toString().padLeft(2,'0')}/${fechaSeleccionada!.month.toString().padLeft(2,'0')}/${fechaSeleccionada!.year}  ${fechaSeleccionada!.hour.toString().padLeft(2,'0')}:${fechaSeleccionada!.minute.toString().padLeft(2, '0')}",
                            hintStyle: TextStyle(color: fechaSeleccionada == null ? onSurface.withOpacity(0.4) : onSurface),
                            suffixIcon: Icon(Icons.calendar_month_outlined, color: onSurface.withOpacity(0.3), size: 18),
                            filled: true, fillColor: theme.scaffoldBackgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (pickedDate != null) {
                              if (!ctx.mounted) return;
                              TimeOfDay? pickedTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                              if (pickedTime != null) {
                                setStateModal(() { fechaSeleccionada = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute); });
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBAC3FF), 
                              foregroundColor: const Color(0xFF00218d),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                            ),
                            onPressed: guardando ? null : () async {
                              HapticFeedback.mediumImpact();
                              double monto = double.tryParse(montoController.text) ?? 0;
                              if (monto <= 0 || fechaSeleccionada == null) {
                                UIHelper.showCustomSnackbar("Llene el monto y la fecha", isError: true);
                                return;
                              }

                              setStateModal(() => guardando = true);

                              String motivo = motivoController.text.isEmpty ? "Pago Programado" : motivoController.text;
                              BigInt amountWei = BigInt.from(monto * 1e18);

                              String? firma = await authCore.generateDelegatedSignature("SEND", toAddress: addressDestino.toLowerCase().trim(), amountWei: amountWei);
                              
                              if (firma != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                                  customTitle: "Planificando Pago", 
                                  customMessage: "Verificando fondos y firmando acuerdo...",
                                  recipientAddress: addressDestino,
                                  expectedTxType: "SCHEDULED_PAYMENT",
                                  onUpdateBalance: () {} 
                                )));
                                
                                await Future.delayed(const Duration(milliseconds: 500));

                                bool success = await scheduledService.saveScheduledPayment({
                                  "fromAddress": authCore.publicAddress.toLowerCase(),
                                  "toAddress": addressDestino.toLowerCase(),
                                  "amountPerPayment": double.parse(montoController.text),
                                  "totalInstallments": 1, 
                                  "frequency": "ONCE",
                                  "nextExecutionDate": fechaSeleccionada!.toUtc().toIso8601String(),
                                  "paymentReason": motivo,
                                  "signature": firma       
                                });

                                if (context.mounted) Navigator.pop(context);

                                if (success) {
                                  UIHelper.showCustomSnackbar("Acuerdo planificado con éxito");
                                  if (ctx.mounted) Navigator.pop(ctx); 
                                } else {
                                  UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes o error de red", isError: true);
                                }
                              } else {
                                UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
                              }
                              setStateModal(() => guardando = false);
                            },
                            child: guardando 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF00218d), strokeWidth: 2))
                              : const Text("Firmar Acuerdo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
      )
    );
  }
  
//   static void show({
//     required BuildContext context,
//     required String aliasDestino,
//     required String addressDestino, // Necesitamos la wallet destino
//     String? initialAmount,
//     String? initialReason,
//     //required BlockchainService service,
//   }) {

//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final scheduledService = Provider.of<ScheduledPaymentService>(context, listen: false);

//     final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
//     final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');
//     DateTime? fechaSeleccionada;
//     bool guardando = false;
    
//    showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => StatefulBuilder( // 🔥 Necesario para actualizar variables dentro del modal
//         builder: (context, setStateModal) {
//         final theme = Theme.of(context);
//           final colorScheme = theme.colorScheme;
//           final onSurface = colorScheme.onSurface;

//           return Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.calendar_month_rounded, size: 50, color: colorScheme.primary),
//                 const SizedBox(height: 15),
//                 Text("Planificar Pago a @$aliasDestino", style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
//                 const SizedBox(height: 20),
                
//               TextField(
//                   controller: TextEditingController(text: addressDestino),
//                   readOnly: true,
//                   style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace'),
//                   decoration: InputDecoration(
//                     labelText: "Llave del Contacto",
//                     prefixIcon: const Icon(Icons.vpn_key_rounded, color: Colors.grey),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 M3
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 TextField(
//                   controller: montoController,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
//                   decoration: InputDecoration(
//                     labelText: "Monto a transferir (TTC)",
//                     prefixIcon: Icon(Icons.attach_money_rounded, color: colorScheme.primary),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 // --- MOTIVO DEL PAGO ---
//                 TextField(
//                   controller: motivoController,
//                   style: TextStyle(color: onSurface),
//                   decoration: InputDecoration(
//                     labelText: "Motivo del pago (Opcional)",
//                     prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.primary),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//               // --- FECHA Y HORA DE EJECUCIÓN ---
//                 TextField(
//                   readOnly: true,
//                   style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
//                   decoration: InputDecoration(
//                     labelText: "Fecha y Hora exacta de ejecución",
//                     hintText: fechaSeleccionada == null 
//                         ? "Seleccionar fecha y hora" 
//                         : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year} a las ${fechaSeleccionada!.hour}:${fechaSeleccionada!.minute.toString().padLeft(2, '0')}",
//                     prefixIcon: Icon(Icons.access_time_filled_rounded, color: colorScheme.secondary),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   ),
//                onTap: () async {
//                     // 1. Pedimos la Fecha
//                     DateTime? pickedDate = await showDatePicker(
//                       context: ctx, 
//                       initialDate: DateTime.now().add(const Duration(days: 1)), 
//                       firstDate: DateTime.now(), 
//                       lastDate: DateTime(2030)
//                     );
//                     if (pickedDate != null) {
//                       // 2. Pedimos la Hora
//                       if (!ctx.mounted) return;
//                       TimeOfDay? pickedTime = await showTimePicker(
//                         context: ctx, 
//                         initialTime: TimeOfDay.now()
//                       );
//                       if (pickedTime != null) {
//                         setStateModal(() {
//                           fechaSeleccionada = DateTime(
//                             pickedDate.year, pickedDate.month, pickedDate.day, 
//                             pickedTime.hour, pickedTime.minute
//                           );
//                         });
//                       }
//                     }
//                   },
//                 ),
//                 const SizedBox(height: 30),
// // --- BOTÓN PRINCIPAL ---
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.primary, 
//                       foregroundColor: colorScheme.onPrimary,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)) // 🔥 M3
//                     ),
//                     onPressed: guardando ? null : () async {
//                       HapticFeedback.mediumImpact();
//                       double monto = double.tryParse(montoController.text) ?? 0;
//                       if (monto <= 0 || fechaSeleccionada == null) {
//                         UIHelper.showCustomSnackbar("Llene el monto y la fecha", isError: true);
//                         return;
//                       }

//                       setStateModal(() => guardando = true);

//                      String motivo = motivoController.text.isEmpty ? "Pago Programado" : motivoController.text;
//                       BigInt amountWei = BigInt.from(monto * 1e18);
//                       HapticFeedback.mediumImpact();

//                       // 2. Firma Web3 Binaria (Autorizamos la transferencia on-chain)
//                       String? firma = await authCore.generateDelegatedSignature(
//                         "SEND", 
//                         toAddress: addressDestino.toLowerCase().trim(), 
//                         amountWei: amountWei
//                       );
                      
//                       if (firma != null) {
//                         // 🔥 FIX 1: Mostrar Pantalla de Espera Visual
//                         Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                           customTitle: "Planificando Pago", 
//                           customMessage: "Verificando fondos y firmando acuerdo...",
//                           recipientAddress: addressDestino,
//                           expectedTxType: "SCHEDULED_PAYMENT",
//                           onUpdateBalance: () {} 
//                         )));
                        
//                         await Future.delayed(const Duration(milliseconds: 500));

//                         bool success = await scheduledService.saveScheduledPayment({
//                           "fromAddress": authCore.publicAddress.toLowerCase(),
//                           "toAddress": addressDestino.toLowerCase(),
//                           "amountPerPayment": double.parse(montoController.text),
//                           "totalInstallments": 1, // 🔥 FIX 2: Agregamos esto para que Spring Boot no falle
//                           "frequency": "ONCE",
//                           "nextExecutionDate": fechaSeleccionada!.toUtc().toIso8601String(),
//                           "paymentReason": motivo,
//                           "signature": firma       
//                         });

//                         // Cerramos la pantalla de carga (loading)
//                         if (context.mounted) Navigator.pop(context);

//                         if (success) {
//                           UIHelper.showCustomSnackbar("Acuerdo planificado con éxito");
//                           if (ctx.mounted) Navigator.pop(ctx); // Cierra el modal principal
//                         } else {
//                           UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes o error de red", isError: true);
//                         }
//                       } else {
//                         // El usuario canceló la huella
//                         UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
//                       }
//                       setStateModal(() => guardando = false);
//                     },
//                     icon: guardando 
//                       ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
//                       : const Icon(Icons.draw_rounded),
//                     label: Text(guardando ? "Firmando..." : "Firmar Acuerdo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           );
//         }
//       )
//     );
//   }
}