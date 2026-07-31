import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
                      const Expanded(child: Text("Plan de Cuotas", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text("Configurar Plan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 4),
                  Text("Establece los detalles de tu plan de pagos gasless.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, height: 1.4)),
                  const SizedBox(height: 24),

                  Text("Monto por cuota (TTC)", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.payments_outlined, color: onSurface.withOpacity(0.5)),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_gas_station_rounded, color: Colors.teal, size: 12), SizedBox(width: 4), Text("0 Gas", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 10))])
                      ),
                      filled: true, fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text("Descripción", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivoController,
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "ej. Suscripción compartida",
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.description_outlined, color: onSurface.withOpacity(0.5)),
                      filled: true, fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Frecuencia", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(prefixIcon: Icon(Icons.history_rounded, color: onSurface.withOpacity(0.5)), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1)))),
                              dropdownColor: theme.cardColor,
                              style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                              icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                              value: frecuenciaDropdown,
                              items: ['Semanal', 'Quincenal', 'Mensual'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) { setStateModal(() => frecuenciaDropdown = val!); },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cuotas", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(prefixIcon: Icon(Icons.format_list_numbered_rounded, color: onSurface.withOpacity(0.5)), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1)))),
                              dropdownColor: theme.cardColor,
                              style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                              icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                              value: cuotasDropdown,
                              items: ['3 Meses', '6 Meses', '12 Meses', 'Indefinido'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) { setStateModal(() => cuotasDropdown = val!); },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!pagarAhora) ...[
                    Text("Fecha de inicio del plan", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: fechaInicio == null ? "dd/mm/aaaa" : "${fechaInicio!.day.toString().padLeft(2,'0')}/${fechaInicio!.month.toString().padLeft(2,'0')}/${fechaInicio!.year}",
                        hintStyle: TextStyle(color: fechaInicio == null ? onSurface.withOpacity(0.4) : onSurface),
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: onSurface.withOpacity(0.5)),
                        suffixIcon: Icon(Icons.calendar_month_outlined, color: onSurface.withOpacity(0.3), size: 18),
                        filled: true, fillColor: theme.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
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
                    const SizedBox(height: 24),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: pagarAhora ? const Color(0xFF4361EE).withOpacity(0.1) : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: onSurface.withOpacity(0.05))
                    ),
                    child: SwitchListTile(
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4361EE),
                      title: Text("Pagar la primera cuota HOY", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text("El plan comenzará inmediatamente.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11)),
                      value: pagarAhora,
                      onChanged: (val) => setStateModal(() => pagarAhora = val),
                    ),
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
                        double montoPorCuota = monto; 
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
                      child: guardando 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF00218d), strokeWidth: 2))
                        : const Text("Firmar Acuerdo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  // static void show({
  //   required BuildContext context,
  //   required String aliasDestino,
  //   required String addressDestino,
  //   String? initialAmount,
  //   String? initialReason,
  //   String? initialFrequency,
  //   String? initialInstallments,
  // }) {

  //   final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //   final scheduledService = Provider.of<ScheduledPaymentService>(context, listen: false);
  //   final txService =  Provider.of<TransactionService>(context, listen: false); 
  //   BuildContext rootContext = context;

  //   final TextEditingController montoController = TextEditingController(text: initialAmount ?? '');
  //   final TextEditingController motivoController = TextEditingController(text: initialReason ?? '');

  //   String frecuenciaDropdown = 'Mensual';
  //   if (initialFrequency != null) {
  //     if (initialFrequency.toUpperCase() == 'WEEKLY' || initialFrequency.toUpperCase() == 'SEMANAL') frecuenciaDropdown = 'Semanal';
  //     if (initialFrequency.toUpperCase() == 'BIWEEKLY' || initialFrequency.toUpperCase() == 'QUINCENAL') frecuenciaDropdown = 'Quincenal';
  //   }
    
  //   String cuotasDropdown = '3 Meses';
  //   if (initialInstallments != null) {
  //     if (initialInstallments == '6') cuotasDropdown = '6 Meses';
  //     if (initialInstallments == '12') cuotasDropdown = '12 Meses';
  //   }

  //   DateTime? fechaInicio; 
  //   bool pagarAhora = false; 
  //   bool guardando = false;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (context, setStateModal) {
  //         final theme = Theme.of(context);
  //         final colorScheme = theme.colorScheme;
  //         final onSurface = colorScheme.onSurface;

  //         return Container(
  //           decoration: BoxDecoration(
  //             color: theme.cardColor,
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
  //           ),
  //           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
  //                 child: Icon(Icons.request_quote_rounded, size: 40, color: colorScheme.secondary),
  //               ),
  //               const SizedBox(height: 16),
  //               Text("Plan de Cuotas", style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900)),
  //               Text("Destinatario: @$aliasDestino", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
  //               const SizedBox(height: 24),

  //               TextField(
  //                 controller: montoController,
  //                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //                 inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
  //                 style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
  //                 decoration: InputDecoration(
  //                   labelText: "Monto por cada cuota (TTC)",
  //                   prefixIcon: Icon(Icons.monetization_on_rounded, color: colorScheme.secondary),
  //                   filled: true, fillColor: onSurface.withOpacity(0.05),
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               TextField(
  //                 controller: motivoController,
  //                 style: TextStyle(color: onSurface),
  //                 decoration: InputDecoration(
  //                   labelText: "Descripción (Ej: Netflix compartido)",
  //                   prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.secondary),
  //                   filled: true, fillColor: onSurface.withOpacity(0.05),
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
                
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: DropdownButtonFormField<String>(
  //                       decoration: InputDecoration(labelText: "Frecuencia", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //                       dropdownColor: theme.cardColor,
  //                       value: frecuenciaDropdown,
  //                       items: ['Semanal', 'Quincenal', 'Mensual'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
  //                       onChanged: (val) { setStateModal(() => frecuenciaDropdown = val!); },
  //                     ),
  //                   ),
  //                   const SizedBox(width: 10),
  //                   Expanded(
  //                     child: DropdownButtonFormField<String>(
  //                       decoration: InputDecoration(labelText: "Cuotas", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //                       dropdownColor: theme.cardColor,
  //                       value: cuotasDropdown,
  //                       items: ['3 Meses', '6 Meses', '12 Meses', 'Indefinido'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
  //                       onChanged: (val) { setStateModal(() => cuotasDropdown = val!); },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),

  //               Container(
  //                 decoration: BoxDecoration(
  //                   color: pagarAhora ? colorScheme.secondary.withOpacity(0.1) : onSurface.withOpacity(0.05),
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(color: pagarAhora ? colorScheme.secondary : Colors.transparent)
  //                 ),
  //                 child: SwitchListTile(
  //                   activeColor: colorScheme.secondary,
  //                   title: Text("Pagar la primera cuota HOY", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
  //                   subtitle: Text(
  //                     pagarAhora ? "Se debitará al instante y el plan seguirá el próximo ciclo." : "Elige la fecha y hora de inicio.",
  //                     style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
  //                   ),
  //                   value: pagarAhora,
  //                   onChanged: (val) => setStateModal(() => pagarAhora = val),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               if (!pagarAhora)
  //                 TextField(
  //                   readOnly: true,
  //                   style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
  //                   decoration: InputDecoration(
  //                     labelText: "Fecha de inicio del plan",
  //                     hintText: fechaInicio == null ? "Seleccionar día y hora" : "${fechaInicio!.day.toString().padLeft(2,'0')}/${fechaInicio!.month.toString().padLeft(2,'0')}/${fechaInicio!.year} a las ${fechaInicio!.hour}:${fechaInicio!.minute.toString().padLeft(2, '0')}",
  //                     prefixIcon: Icon(Icons.calendar_today_rounded, color: colorScheme.secondary),
  //                     filled: true, fillColor: onSurface.withOpacity(0.05),
  //                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                   ),
  //                   onTap: () async {
  //                     DateTime? pickedDate = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime(2030));
  //                     if (pickedDate != null) {
  //                       if (!ctx.mounted) return;
  //                       TimeOfDay? pickedTime = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
  //                       if (pickedTime != null) {
  //                         setStateModal(() => fechaInicio = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
  //                       }
  //                     }
  //                   },
  //                 ),

  //               const SizedBox(height: 32),

  //               SizedBox(
  //                 width: double.infinity, height: 56,
  //                 child: ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: colorScheme.secondary, 
  //                     foregroundColor: Colors.white,
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
  //                   ),
  //                   onPressed: guardando ? null : () async {
  //                     HapticFeedback.mediumImpact();
  //                     double monto = double.tryParse(montoController.text) ?? 0;
  //                     if (monto <= 0) return;
  //                     if (!pagarAhora && fechaInicio == null) {
  //                       UIHelper.showCustomSnackbar("Selecciona cuándo empieza el plan", isError: true);
  //                       return;
  //                     }

  //                     FocusScope.of(ctx).unfocus();
  //                     showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Firma tu acuerdo recurrente."));
  //                     bool isAuth = await authCore.authenticateUser();
  //                     Navigator.pop(rootContext); 

  //                     if (!isAuth) return;

  //                     setStateModal(() => guardando = true);

  //                     int numCuotas = _obtenerNumeroCuotas(cuotasDropdown); 
  //                     String freqDb = _mapearFrecuencia(frecuenciaDropdown); 
  //                     double montoPorCuota = monto; // 🔥 FIX: El monto ingresado YA ES la cuota
  //                     String motivo = motivoController.text.isEmpty ? "Plan de Cuotas" : motivoController.text;

  //                     BigInt amountWei = BigInt.from(montoPorCuota * 1e18);
  //                     String? firma = await authCore.generateDelegatedSignature("SEND", toAddress: addressDestino.toLowerCase().trim(), amountWei: amountWei);
                      
  //                     if (firma != null) {
  //                       DateTime proximoCobro = fechaInicio ?? DateTime.now();
  //                       if (pagarAhora) {
  //                         if (freqDb == 'WEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 7));
  //                         else if (freqDb == 'BIWEEKLY') proximoCobro = proximoCobro.add(const Duration(days: 14));
  //                         else proximoCobro = DateTime(proximoCobro.year, proximoCobro.month + 1, proximoCobro.day);
  //                       }

  //                       Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
  //                         customTitle: "Activando Plan", 
  //                         customMessage: pagarAhora ? "Cobrando primera cuota y firmando..." : "Verificando fondos y firmando...",
  //                         recipientAddress: addressDestino,
  //                         expectedTxType: "SCHEDULED_PAYMENT",
  //                         onUpdateBalance: () {} 
  //                       )));

  //                       if (pagarAhora) {
  //                         String res = await txService.sendTokensL2(addressDestino, montoPorCuota, firma);
  //                         if (!res.startsWith("Exito")) {
  //                           Navigator.pop(rootContext); 
  //                           UIHelper.showCustomSnackbar("Error al cobrar cuota inicial: $res", isError: true);
  //                           setStateModal(() => guardando = false);
  //                           return;
  //                         }
  //                       }

  //                       bool success = await scheduledService.saveScheduledPayment({
  //                         "fromAddress": authCore.publicAddress.toLowerCase(),
  //                         "toAddress": addressDestino.toLowerCase(),
  //                         "amountPerPayment": montoPorCuota,
  //                         "totalInstallments": numCuotas,
  //                         "frequency": freqDb,
  //                         "nextExecutionDate": proximoCobro.toUtc().toIso8601String(),
  //                         "paymentReason": motivo,
  //                         "signature": firma
  //                       });

  //                       Navigator.pop(rootContext); 

  //                       if (success) {
  //                         UIHelper.showCustomSnackbar(pagarAhora ? "Cuota pagada y plan activado" : "Plan de cuotas programado con éxito");
  //                         if (ctx.mounted) Navigator.pop(ctx);
  //                       } else {
  //                         UIHelper.showCustomSnackbar("Rechazado: Fondos insuficientes", isError: true);
  //                       }
  //                     } else {
  //                       UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
  //                     }
  //                     setStateModal(() => guardando = false);
  //                   },
  //                   icon: guardando 
  //                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
  //                     : const Icon(Icons.draw_rounded),
  //                   label: Text(guardando ? "Firmando..." : "Firmar Acuerdo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }
  //     )
  //   );
  // }
}