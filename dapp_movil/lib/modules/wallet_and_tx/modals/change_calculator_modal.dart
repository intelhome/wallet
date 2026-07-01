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
          double recibido = double.tryParse(receivedCtrl.text) ?? 0.0;
          double cambio = recibido - totalToPay;
          bool esSuficiente = cambio >= 0;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
              top: 20, 
              left: 24, 
              right: 24
            ),
            child: SingleChildScrollView( // 🔥 Evita el error de overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "CALCULADORA DE VUELTOS",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                  ),
                  const SizedBox(height: 25),
                  
                  // Resumen de la venta
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total de la venta:", style: TextStyle(fontSize: 16)),
                        Text(
                          "\$${totalToPay.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Entrada de efectivo
                  TextField(
                    controller: receivedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green, size: 30),
                      labelText: "Efectivo Recibido",
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (v) => setModalState(() {}),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Billetes Rápidos (M3 Chips)
                  const Text("Accesos rápidos de billetes:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 20, 50, 100].map((billete) {
                      return ChoiceChip(
                        label: Text("\$$billete", style: const TextStyle(fontWeight: FontWeight.bold)),
                        selected: recibido == billete.toDouble(),
                        onSelected: (selected) {
                          receivedCtrl.text = billete.toString();
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Panel de Resultado Dinámico
                  if (recibido > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: esSuficiente ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: esSuficiente ? Colors.green : Colors.red, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            esSuficiente ? "CAMBIO A DEVOLVER" : "FALTA DINERO",
                            style: TextStyle(fontWeight: FontWeight.w900, color: esSuficiente ? Colors.green : Colors.red, letterSpacing: 1),
                          ),
                          Text(
                            "\$${cambio.abs().toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: esSuficiente ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Finalizar Calculo", style: TextStyle(fontWeight: FontWeight.bold)),
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