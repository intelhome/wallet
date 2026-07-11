import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// class InstallmentsModal {
//   // Función helper (privada)
//   static int _obtenerNumeroCuotas(String valor) {
//     if (valor == '3 Meses') return 3;
//     if (valor == '6 Meses') return 6;
//     if (valor == '12 Meses') return 12;
//     return 999; // Suscripción indefinida
//   }

//   static String _mapearFrecuencia(String valor) {
//     if (valor == 'Semanal') return 'WEEKLY';
//     if (valor == 'Quincenal') return 'BIWEEKLY';
//     return 'MONTHLY'; // Por defecto
//   }

//   static void show({
//     required BuildContext context,
//     required String aliasDestino,
//     required String addressDestino,
//     String? initialAmount,
//     String? initialReason,
//     String? initialFrequency,
//     String? initialInstallments,
//    // required BlockchainService service,
//   }) {

//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final scheduledService = Provider.of<ScheduledPaymentService>(context, listen: false);
// final txService =  Provider.of<TransactionService>(context, listen: false); 


//    final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
//     final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');

//    String frecuenciaDropdown = 'Mensual';
//     if (initialFrequency != null) {
//       if (initialFrequency.toUpperCase() == 'WEEKLY' || initialFrequency.toUpperCase() == 'SEMANAL') frecuenciaDropdown = 'Semanal';
//       if (initialFrequency.toUpperCase() == 'BIWEEKLY' || initialFrequency.toUpperCase() == 'QUINCENAL') frecuenciaDropdown = 'Quincenal';
//     }
    
//     String cuotasDropdown = '3 Meses';
//     if (initialInstallments != null) {
//       if (initialInstallments == '6') cuotasDropdown = '6 Meses';
//       if (initialInstallments == '12') cuotasDropdown = '12 Meses';
//     }

//     DateTime? fechaInicio; // Base para el cobro
//     bool pagarAhora = false; // 🔥 NUEVO SWITCH
//     bool guardando = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), // 🔥 M3
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setStateModal) {
//           final theme = Theme.of(context);
//           final colorScheme = theme.colorScheme;
//           final onSurface = colorScheme.onSurface;

//           return Padding(
//             padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.request_quote_rounded, size: 50, color: colorScheme.secondary),
//                 const SizedBox(height: 15),
//                 Text("Plan de Cuotas: @$aliasDestino", style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
//                 const SizedBox(height: 20),

//                 // --- MONTO ---
//                 TextField(
//                   controller: montoController,
//                   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
//                   decoration: InputDecoration(
//                     labelText: "Monto por cada cuota (TTC)",
//                     prefixIcon: Icon(Icons.monetization_on_rounded, color: colorScheme.secondary),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 // --- MOTIVO ---
//                 TextField(
//                   controller: motivoController,
//                   style: TextStyle(color: onSurface),
//                   decoration: InputDecoration(
//                     labelText: "Descripción (Ej: Netflix compartido)",
//                     prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.secondary),
//                     filled: true,
//                     fillColor: onSurface.withOpacity(0.05),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   ),
//                 ),
//                 const SizedBox(height: 15),
                
//                 // --- DESPLEGABLES ---
//                 Row(
//                   children: [
//                     Expanded(
//                       child: DropdownButtonFormField<String>(
//                         decoration: InputDecoration(labelText: "Frecuencia", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
//                         dropdownColor: theme.cardColor,
//                         style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
//                         value: frecuenciaDropdown,
//                         items: ['Semanal', 'Quincenal', 'Mensual'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                         onChanged: (val) { setStateModal(() => frecuenciaDropdown = val!); },
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: DropdownButtonFormField<String>(
//                         decoration: InputDecoration(labelText: "Cuotas", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
//                         dropdownColor: theme.cardColor,
//                         style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
//                         value: cuotasDropdown,
//                         items: ['3 Meses', '6 Meses', '12 Meses', 'Indefinido'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
//                         onChanged: (val) { setStateModal(() => cuotasDropdown = val!); },
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 15),

//                 // 🔥 SWITCH: ¿PAGAR AHORA O PROGRAMAR?
//                 Container(
//                   decoration: BoxDecoration(
//                     color: pagarAhora ? colorScheme.secondary.withOpacity(0.1) : onSurface.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: pagarAhora ? colorScheme.secondary : Colors.transparent)
//                   ),
//                   child: SwitchListTile(
//                     activeColor: colorScheme.secondary,
//                     title: Text("Pagar la primera cuota HOY", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
//                     subtitle: Text(
//                       pagarAhora ? "Se debitará al instante y el plan seguirá el próximo ciclo." : "Elige la fecha y hora de inicio.",
//                       style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
//                     ),
//                     value: pagarAhora,
//                     onChanged: (val) => setStateModal(() => pagarAhora = val),
//                   ),
//                 ),
//                 const SizedBox(height: 15),

//                 // 🔥 SELECTOR DE FECHA (Solo visible si NO paga hoy)
//                 if (!pagarAhora)
//                   TextField(
//                     readOnly: true,
//                     style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
//                     decoration: InputDecoration(
//                       labelText: "Fecha de inicio del plan",
//                       hintText: fechaInicio == null ? "Seleccionar día y hora" : "${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year} a las ${fechaInicio!.hour}:${fechaInicio!.minute.toString().padLeft(2, '0')}",
//                       prefixIcon: Icon(Icons.calendar_today_rounded, color: colorScheme.secondary),
//                       filled: true,
//                       fillColor: onSurface.withOpacity(0.05),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                     ),
//                     onTap: () async {
//                       DateTime? pickedDate = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
//                       if (pickedDate != null) {
//                         if (!ctx.mounted) return;
//                         TimeOfDay? pickedTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
//                         if (pickedTime != null) {
//                           setStateModal(() => fechaInicio = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
//                         }
//                       }
//                     },
//                   ),

//                 const SizedBox(height: 30),

//                 // --- BOTÓN PRINCIPAL ---
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: colorScheme.secondary, 
//                       foregroundColor: colorScheme.onSecondary,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
//                     ),
//                     onPressed: guardando ? null : () async {
//                       HapticFeedback.mediumImpact();
//                       double monto = double.tryParse(montoController.text) ?? 0;
//                       if (monto <= 0) return;
//                       if (!pagarAhora && fechaInicio == null) {
//                         UIHelper.showCustomSnackbar("Selecciona cuándo empieza el plan", isError: true);
//                         return;
//                       }

//                       setStateModal(() => guardando = true);

//                       // 1. Firma Legal
//                       int numCuotas = _obtenerNumeroCuotas(cuotasDropdown); 
//                       String freqDb = _mapearFrecuencia(frecuenciaDropdown); 
//                       double montoPorCuota = monto / numCuotas;
//                       String motivo = motivoController.text.isEmpty ? "Plan de Cuotas" : motivoController.text;

//                       // 2. Firma Web3 Binaria basada en la CUOTA exacta
//                       BigInt amountWei = BigInt.from(montoPorCuota * 1e18);
//                       String? firma = await authCore.generateDelegatedSignature(
//                         "SEND", 
//                         toAddress: addressDestino.toLowerCase().trim(), 
//                         amountWei: amountWei
//                       );
                      
//                       if (firma != null) {
                        
//                         // Calculamos la fecha del próximo cobro automático
//                         DateTime proximoCobro = DateTime.now();
//                         if (pagarAhora) {
//                           if (freqDb == 'WEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 7));
//                           else if (freqDb == 'BIWEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 14));
//                           else proximoCobro = DateTime(proximoCobro.year, proximoCobro.month + 1, proximoCobro.day);
//                         }

//                         // 🔥 2. Mostrar Pantalla de Espera Visual (TransactionPendingScreen)
//                         Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                           customTitle: "Activando Plan", 
//                           customMessage: pagarAhora ? "Cobrando primera cuota y firmando..." : "Verificando fondos y firmando...",
//                           recipientAddress: addressDestino,
//                           expectedTxType: "SCHEDULED_PAYMENT",
//                           onUpdateBalance: () {} 
//                         )));
                        
//                         await Future.delayed(const Duration(milliseconds: 500));

//                         // 3. Si eligió pagar la primera cuota ahora mismo:
//                         if (pagarAhora) {
//                           String res = await txService.sendTokensL2(addressDestino, montoPorCuota, firma);
//                           if (!res.startsWith("Exito")) {
//                             if (context.mounted) Navigator.pop(context); // Cerramos el loading
//                             UIHelper.showCustomSnackbar("Error al cobrar cuota inicial: $res", isError: true);
//                             setStateModal(() => guardando = false);
//                             return;
//                           }
//                         }

//                         // 4. Guardar el contrato en el backend para los cobros futuros
//                         bool success = await scheduledService.saveScheduledPayment({
//                           "fromAddress": authCore.publicAddress.toLowerCase(),
//                           "toAddress": addressDestino.toLowerCase(),
//                           "amountPerPayment": montoPorCuota,
//                           "totalInstallments": numCuotas,
//                           "frequency": freqDb,
//                           "nextExecutionDate": proximoCobro.toUtc().toIso8601String(),
//                           "paymentReason": motivo,
//                           "signature": firma
//                         });

//                         // Cerramos la pantalla de carga
//                         if (context.mounted) Navigator.pop(context);

//                         if (success) {
//                           UIHelper.showCustomSnackbar(pagarAhora ? "Cuota pagada y plan activado" : "Plan de cuotas programado con éxito");
//                           if (ctx.mounted) Navigator.pop(ctx);
//                         } else {
//                           UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes o error de red", isError: true);
//                         }
//                       } else {
//                         UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
//                       }
//                       setStateModal(() => guardando = false);
//                     },
//                     icon: guardando 
//                       ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onSecondary, strokeWidth: 2))
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
// }

class InstallmentsModal {
  static int _obtenerNumeroCuotas(String valor) {
    if (valor == '3 Meses') return 3;
    if (valor == '6 Meses') return 6;
    if (valor == '12 Meses') return 12;
    return 999; 
  }

  static String _mapearFrecuencia(String valor) {
    if (valor == 'Semanal') return 'WEEKLY';
    if (valor == 'Quincenal') return 'BIWEEKLY';
    return 'MONTHLY'; 
  }

  static void show({
    required BuildContext context,
    required String aliasDestino,
    required String addressDestino,
    String? initialAmount,
    String? initialReason,
    String? initialFrequency,
    String? initialInstallments,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final scheduledService = Provider.of<ScheduledPaymentService>(context, listen: false);
    final txService =  Provider.of<TransactionService>(context, listen: false); 
    BuildContext rootContext = context;

    final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');

    String frecuenciaDropdown = 'Mensual';
    if (initialFrequency != null) {
      if (initialFrequency.toUpperCase() == 'WEEKLY' || initialFrequency.toUpperCase() == 'SEMANAL') frecuenciaDropdown = 'Semanal';
      if (initialFrequency.toUpperCase() == 'BIWEEKLY' || initialFrequency.toUpperCase() == 'QUINCENAL') frecuenciaDropdown = 'Quincenal';
    }
    
    String cuotasDropdown = '3 Meses';
    if (initialInstallments != null) {
      if (initialInstallments == '6') cuotasDropdown = '6 Meses';
      if (initialInstallments == '12') cuotasDropdown = '12 Meses';
    }

    DateTime? fechaInicio; 
    bool pagarAhora = false; 
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          final theme = Theme.of(context);
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
                  decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.request_quote_rounded, size: 40, color: colorScheme.secondary),
                ),
                const SizedBox(height: 16),
                Text("Plan de Cuotas", style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
                Text("Destinatario: @$aliasDestino", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 24),

                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: "Monto por cada cuota (TTC)",
                    prefixIcon: Icon(Icons.monetization_on_rounded, color: colorScheme.secondary),
                    filled: true, fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: motivoController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    labelText: "Descripción (Ej: Netflix compartido)",
                    prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.secondary),
                    filled: true, fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: "Frecuencia", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                        dropdownColor: theme.cardColor,
                        value: frecuenciaDropdown,
                        items: ['Semanal', 'Quincenal', 'Mensual'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (val) { setStateModal(() => frecuenciaDropdown = val!); },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: "Cuotas", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                        dropdownColor: theme.cardColor,
                        value: cuotasDropdown,
                        items: ['3 Meses', '6 Meses', '12 Meses', 'Indefinido'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (val) { setStateModal(() => cuotasDropdown = val!); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: pagarAhora ? colorScheme.secondary.withOpacity(0.1) : onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pagarAhora ? colorScheme.secondary : Colors.transparent)
                  ),
                  child: SwitchListTile(
                    activeColor: colorScheme.secondary,
                    title: Text("Pagar la primera cuota HOY", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      pagarAhora ? "Se debitará al instante y el plan seguirá el próximo ciclo." : "Elige la fecha y hora de inicio.",
                      style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                    value: pagarAhora,
                    onChanged: (val) => setStateModal(() => pagarAhora = val),
                  ),
                ),
                const SizedBox(height: 16),

                if (!pagarAhora)
                  TextField(
                    readOnly: true,
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Fecha de inicio del plan",
                      hintText: fechaInicio == null ? "Seleccionar día y hora" : "${fechaInicio!.day.toString().padLeft(2,'0')}/${fechaInicio!.month.toString().padLeft(2,'0')}/${fechaInicio!.year} a las ${fechaInicio!.hour}:${fechaInicio!.minute.toString().padLeft(2, '0')}",
                      prefixIcon: Icon(Icons.calendar_today_rounded, color: colorScheme.secondary),
                      filled: true, fillColor: onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (pickedDate != null) {
                        if (!ctx.mounted) return;
                        TimeOfDay? pickedTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                        if (pickedTime != null) {
                          setStateModal(() => fechaInicio = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
                        }
                      }
                    },
                  ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: guardando ? null : () async {
                      HapticFeedback.mediumImpact();
                      double monto = double.tryParse(montoController.text) ?? 0;
                      if (monto <= 0) return;
                      if (!pagarAhora && fechaInicio == null) {
                        UIHelper.showCustomSnackbar("Selecciona cuándo empieza el plan", isError: true);
                        return;
                      }

                      FocusScope.of(ctx).unfocus();
                      showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Firma tu acuerdo recurrente."));
                      bool isAuth = await authCore.authenticateUser();
                      Navigator.pop(rootContext); 

                      if (!isAuth) return;

                      setStateModal(() => guardando = true);

                      int numCuotas = _obtenerNumeroCuotas(cuotasDropdown); 
                      String freqDb = _mapearFrecuencia(frecuenciaDropdown); 
                      double montoPorCuota = monto; // 🔥 FIX: El monto ingresado YA ES la cuota
                      String motivo = motivoController.text.isEmpty ? "Plan de Cuotas" : motivoController.text;

                      BigInt amountWei = BigInt.from(montoPorCuota * 1e18);
                      String? firma = await authCore.generateDelegatedSignature("SEND", toAddress: addressDestino.toLowerCase().trim(), amountWei: amountWei);
                      
                      if (firma != null) {
                        DateTime proximoCobro = fechaInicio ?? DateTime.now();
                        if (pagarAhora) {
                          if (freqDb == 'WEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 7));
                          else if (freqDb == 'BIWEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 14));
                          else proximoCobro = DateTime(proximoCobro.year, proximoCobro.month + 1, proximoCobro.day);
                        }

                        Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                          customTitle: "Activando Plan", 
                          customMessage: pagarAhora ? "Cobrando primera cuota y firmando..." : "Verificando fondos y firmando...",
                          recipientAddress: addressDestino,
                          expectedTxType: "SCHEDULED_PAYMENT",
                          onUpdateBalance: () {} 
                        )));

                        if (pagarAhora) {
                          String res = await txService.sendTokensL2(addressDestino, montoPorCuota, firma);
                          if (!res.startsWith("Exito")) {
                            Navigator.pop(rootContext); 
                            UIHelper.showCustomSnackbar("Error al cobrar cuota inicial: $res", isError: true);
                            setStateModal(() => guardando = false);
                            return;
                          }
                        }

                        bool success = await scheduledService.saveScheduledPayment({
                          "fromAddress": authCore.publicAddress.toLowerCase(),
                          "toAddress": addressDestino.toLowerCase(),
                          "amountPerPayment": montoPorCuota,
                          "totalInstallments": numCuotas,
                          "frequency": freqDb,
                          "nextExecutionDate": proximoCobro.toUtc().toIso8601String(),
                          "paymentReason": motivo,
                          "signature": firma
                        });

                        Navigator.pop(rootContext); 

                        if (success) {
                          UIHelper.showCustomSnackbar(pagarAhora ? "Cuota pagada y plan activado" : "Plan de cuotas programado con éxito");
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else {
                          UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes", isError: true);
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