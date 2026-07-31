import 'package:flutter/material.dart';
import '../../../core/helpers/ui_helper.dart';


class ChangeCalculatorModal {
  static void show({
    required BuildContext context,
    required double totalToPay,
  }) {
    final TextEditingController receivedCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(ctx);
          final onSurface = theme.colorScheme.onSurface;
          final cardColor = theme.cardColor;

          double recibido = double.tryParse(receivedCtrl.text) ?? 0.0;
          double cambio = recibido - totalToPay;
          bool esSuficiente = cambio >= 0;

          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, 
              top: 16, 
              left: 24, 
              right: 24
            ),
            child: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "CALCULADORA DE VUELTOS",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Resumen de la venta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total de la venta:", style: TextStyle(fontSize: 16, color: onSurface.withOpacity(0.7))),
                        Text(
                          "\$${totalToPay.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFBAC3FF)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Entrada de efectivo
                  TextField(
                    controller: receivedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    autofocus: true,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: onSurface),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 20, top: 4),
                        child: Text("\$", style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                      labelText: "Efectivo Recibido",
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6)),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: onSurface.withOpacity(0.3))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    ),
                    onChanged: (v) => setModalState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Billetes Rápidos
                  Text("Accesos rápidos de billetes:", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 20, 50, 100].map((billete) {
                      bool isSelected = recibido == billete.toDouble();
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isSelected ? theme.scaffoldBackgroundColor : onSurface,
                          backgroundColor: isSelected ? const Color(0xFFBAC3FF) : Colors.transparent,
                          side: BorderSide(color: isSelected ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          receivedCtrl.text = billete.toString();
                          setModalState(() {});
                        },
                        child: Text("\$$billete", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Panel de Resultado Dinámico
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          recibido == 0 ? "Vuelto a entregar:" : (esSuficiente ? "Vuelto a entregar:" : "Falta dinero:"),
                          style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6)),
                        ),
                        Text(
                          "\$${cambio.abs().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.w600, 
                            color: recibido == 0 ? onSurface.withOpacity(0.5) : (esSuficiente ? Colors.greenAccent : Colors.redAccent)
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBAC3FF),
                        foregroundColor: const Color(0xFF00218d),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Finalizar Calculo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// class ChangeCalculatorModal {
//   static void show({
//     required BuildContext context,
//     required double totalToPay,
//   }) {
//     final TextEditingController receivedCtrl = TextEditingController();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) {
//           double recibido = double.tryParse(receivedCtrl.text) ?? 0.0;
//           double cambio = recibido - totalToPay;
//           bool esSuficiente = cambio >= 0;

//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(ctx).cardColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
//             ),
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
//               top: 20, 
//               left: 24, 
//               right: 24
//             ),
//             child: SingleChildScrollView( // 🔥 Evita el error de overflow
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.withOpacity(0.3),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     "CALCULADORA DE VUELTOS",
//                     style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
//                   ),
//                   const SizedBox(height: 25),
                  
//                   // Resumen de la venta
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.blueAccent.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Total de la venta:", style: TextStyle(fontSize: 16)),
//                         Text(
//                           "\$${totalToPay.toStringAsFixed(2)}",
//                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
//                         ),
//                       ],
//                     ),
//                   ),
                  
//                   const SizedBox(height: 25),
                  
//                   // Entrada de efectivo
//                   TextField(
//                     controller: receivedCtrl,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                     textAlign: TextAlign.center,
//                     autofocus: true,
//                     style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//                     decoration: InputDecoration(
//                       hintText: "0.00",
//                       prefixIcon: const Icon(Icons.attach_money, color: Colors.green, size: 30),
//                       labelText: "Efectivo Recibido",
//                       labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                     ),
//                     onChanged: (v) => setModalState(() {}),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Billetes Rápidos (M3 Chips)
//                   const Text("Accesos rápidos de billetes:", style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   const SizedBox(height: 10),
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 10,
//                     alignment: WrapAlignment.center,
//                     children: [5, 10, 20, 50, 100].map((billete) {
//                       return ChoiceChip(
//                         label: Text("\$$billete", style: const TextStyle(fontWeight: FontWeight.bold)),
//                         selected: recibido == billete.toDouble(),
//                         onSelected: (selected) {
//                           receivedCtrl.text = billete.toString();
//                           setModalState(() {});
//                         },
//                       );
//                     }).toList(),
//                   ),
                  
//                   const SizedBox(height: 30),
                  
//                   // Panel de Resultado Dinámico
//                   if (recibido > 0)
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(vertical: 25),
//                       decoration: BoxDecoration(
//                         color: esSuficiente ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(24),
//                         border: Border.all(color: esSuficiente ? Colors.green : Colors.red, width: 2),
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             esSuficiente ? "CAMBIO A DEVOLVER" : "FALTA DINERO",
//                             style: TextStyle(fontWeight: FontWeight.w900, color: esSuficiente ? Colors.green : Colors.red, letterSpacing: 1),
//                           ),
//                           Text(
//                             "\$${cambio.abs().toStringAsFixed(2)}",
//                             style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: esSuficiente ? Colors.green : Colors.red),
//                           ),
//                         ],
//                       ),
//                     ),
                  
//                   const SizedBox(height: 25),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 60,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey.shade200,
//                         foregroundColor: Colors.black,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                       ),
//                       onPressed: () => Navigator.pop(ctx),
//                       child: const Text("Finalizar Calculo", style: TextStyle(fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }