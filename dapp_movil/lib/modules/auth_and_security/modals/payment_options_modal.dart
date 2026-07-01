import 'package:flutter/material.dart';

class PaymentOptionsModal {
  static void show({
    required BuildContext context,
    required String planName,
    required double amount,
    required String cycle, // "MONTHLY" o "ANNUAL"
    required Function(bool autoRenew) onPayWithFiat,
    required Function(bool autoRenew) onPayWithCrypto,
  }) {
    bool isAutoRenew = true; // Por defecto lo marcamos como activo

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Elige tu método de pago", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                SwitchListTile(
                  title: const Text("Autorenovación", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isAutoRenew ? "Se cobrará automáticamente al vencer" : "Pago único, se cancelará al vencer", style: const TextStyle(fontSize: 12)),
                  value: isAutoRenew,
                  activeColor: Colors.purpleAccent,
                  onChanged: (val) => setStateModal(() => isAutoRenew = val),
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.credit_card, color: Colors.blueAccent, size: 30),
                  title: const Text("Pagar con Tarjeta", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("A través de PagoPlux"),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPayWithFiat(isAutoRenew);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.token_rounded, color: Colors.deepPurpleAccent, size: 30),
                  title: Text("Pagar con TTC (${amount.toStringAsFixed(2)} TTC)", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Débito instantáneo de tu Billetera Web3"),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPayWithCrypto(isAutoRenew);
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          }
        ),
      ),
    );
  }
}