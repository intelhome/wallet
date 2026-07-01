import 'package:flutter/material.dart';

class TransactionSimulatorModal {
  /// Retorna [true] si el usuario acepta la simulación, [false] o null si cancela.
  static Future<bool?> show({
    required BuildContext context,
    required double amount,
    required String destination,
    required double currentBalance,
    required bool isOffChain,
  }) {
    // Cálculo de la simulación
    double gasFee = isOffChain ? 0.0 : 0.005; // AVAX estimado si es On-Chain
    double newBalance = currentBalance - amount;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security_rounded, size: 50, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text("Simulación de Transacción", style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text("Revisa el impacto exacto en tus fondos antes de firmar.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),

              // 🔥 CAJA DE SIMULACIÓN VISUAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Destino
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Enviar a:", style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            destination.length > 20 ? "${destination.substring(0, 10)}...${destination.substring(destination.length - 6)}" : destination, 
                            textAlign: TextAlign.right,
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontFamily: 'monospace')
                          ),
                        ),
                      ],
                    ),
                    Divider(color: onSurface.withOpacity(0.1), height: 30),
                    
                    // Monto a enviar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Monto a enviar:", style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        Text("- ${amount.toStringAsFixed(4)} TTC", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Comisión
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Comisión de red:", style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        isOffChain 
                          ? const Text("0.00 TTC (Gratis)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          : Text("~ $gasFee AVAX (Patrocinado)", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: onSurface.withOpacity(0.1), height: 30),

                    // Balance Resultante
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Balance Resultante:", style: TextStyle(color: onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
                        Text("${newBalance.toStringAsFixed(4)} TTC", style: TextStyle(color: newBalance >= 0 ? Colors.green : colorScheme.error, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: colorScheme.error.withOpacity(0.5))
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Cancelar", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text("Autorizar", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }
    );
  }
}