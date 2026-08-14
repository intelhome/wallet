import 'package:flutter/material.dart';


class PaymentOptionsModal {
  static void show({
    required BuildContext context,
    required String planName,
    required double amount,
    required String cycle,
    required Function(bool autoRenew) onPayWithFiat,
    required Function(bool autoRenew) onPayWithCrypto,
  }) {
    bool isAutoRenew = true; 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final theme = Theme.of(ctx);
            final onSurface = theme.colorScheme.onSurface;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Método de Pago", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                      IconButton(icon: Icon(Icons.close_rounded, color: onSurface), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // TOGGLE DE AUTORENOVACIÓN
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: onSurface.withOpacity(0.05)),
                    ),
                    child: SwitchListTile(
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF10B981), // Verde éxito
                      title: Text("Autorenovación", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                      subtitle: Text(
                        isAutoRenew ? "Se cobrará automáticamente al vencer" : "Pago único, se cancelará al vencer", 
                        style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))
                      ),
                      value: isAutoRenew,
                      onChanged: (val) => setStateModal(() => isAutoRenew = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("SELECCIONA UNA OPCIÓN", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 16),

                  // OPCIÓN 1: PAGO FIAT (PAGOPLUX)
                  _buildPaymentOption(
                    theme: theme,
                    icon: Icons.credit_card_rounded,
                    iconColor: Colors.blueAccent,
                    title: "Tarjeta de Crédito / Débito",
                    subtitle: "Pago procesado seguro por PagoPlux",
                    onTap: () {
                      Navigator.pop(ctx);
                      onPayWithFiat(isAutoRenew);
                    },
                  ),
                  const SizedBox(height: 16),

                  // OPCIÓN 2: PAGO CRYPTO (TTC)
                  _buildPaymentOption(
                    theme: theme,
                    icon: Icons.token_rounded,
                    iconColor: const Color(0xFFBAC3FF),
                    title: "Pagar con Billetera TTC",
                    subtitle: "Débito On-Chain: ${amount.toStringAsFixed(2)} TTC",
                    onTap: () {
                      Navigator.pop(ctx);
                      onPayWithCrypto(isAutoRenew);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              )
              );
            }
          ),
        ),
    );
  }

  static Widget _buildPaymentOption({
    required ThemeData theme, required IconData icon, required Color iconColor, 
    required String title, required String subtitle, required VoidCallback onTap
  }) {
    final onSurface = theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: onSurface.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

// class PaymentOptionsModal {
//   static void show({
//     required BuildContext context,
//     required String planName,
//     required double amount,
//     required String cycle, // "MONTHLY" o "ANNUAL"
//     required Function(bool autoRenew) onPayWithFiat,
//     required Function(bool autoRenew) onPayWithCrypto,
//   }) {
//     bool isAutoRenew = true; // Por defecto lo marcamos como activo

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => SafeArea(
//         child: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateModal) {
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.all(20.0),
//                   child: Text("Elige tu método de pago", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 ),
                
//                 SwitchListTile(
//                   title: const Text("Autorenovación", style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Text(isAutoRenew ? "Se cobrará automáticamente al vencer" : "Pago único, se cancelará al vencer", style: const TextStyle(fontSize: 12)),
//                   value: isAutoRenew,
//                   activeColor: Colors.purpleAccent,
//                   onChanged: (val) => setStateModal(() => isAutoRenew = val),
//                 ),
//                 const Divider(),

//                 ListTile(
//                   leading: const Icon(Icons.credit_card, color: Colors.blueAccent, size: 30),
//                   title: const Text("Pagar con Tarjeta", style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Text("A través de PagoPlux"),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     onPayWithFiat(isAutoRenew);
//                   },
//                 ),
//                 const Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.token_rounded, color: Colors.deepPurpleAccent, size: 30),
//                   title: Text("Pagar con TTC (${amount.toStringAsFixed(2)} TTC)", style: const TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Text("Débito instantáneo de tu Billetera Web3"),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     onPayWithCrypto(isAutoRenew);
//                   },
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             );
//           }
//         ),
//       ),
//     );
//   }
// }