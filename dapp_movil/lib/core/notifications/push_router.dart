import 'package:dapp_movil/main.dart';
import 'package:dapp_movil/modules/vaults_and_savings/screens/vaults_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PushRouter {
  
  static void handleNotificationClick(Map<String, dynamic> data) async {
    print("==================================================");
    print("📲 [FLUTTER PUSH ROUTER] Notificación Tocada!");
    print("📦 DATOS OCULTOS RECIBIDOS: $data");
    print("==================================================");

    if (data.isEmpty) {
      print("⚠️ Los datos llegaron vacíos.");
      return;
    }

    String? action = data['action'] ?? data['type']; 
    print("🎯 ACCIÓN DETECTADA: $action");
    
    BuildContext? context = navigatorKey.currentContext;

    if (context == null) {
      print("⏳ Esperando que el árbol de UI se construya...");
      await Future.delayed(const Duration(seconds: 2));
      context = navigatorKey.currentContext;
      if (context == null) {
        print("❌ FATAL: No se pudo obtener el Context de Flutter.");
        return;
      }
    }

    switch (action) {
      case 'OPEN_SEND_MODAL':
        String destination = data['destination'] ?? '';
        String amount = data['amount'] ?? '';
        
        print("✅ EJECUTANDO MODAL DE PAGO AUTOMÁTICO -> Destino: $destination | Monto: $amount");

        final txService = Provider.of<TransactionService>(context, listen: false);
        String balance = await txService.getBalance();

        SendModal.show(
          context: context,
          balanceTTC: balance,
          initialAddress: destination,
          initialAmount: amount,
          onUpdateBalance: () {}, 
          mostrarMensaje: (msg, {bool esError = false}) {
            ScaffoldMessenger.of(context!).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green));
          }
        );
        break;

      case 'OPEN_SMART_VAULTS':
        String suggestedAmount = data['suggestedAmount'] ?? '0';
        
        print("✅ EJECUTANDO CONSEJO DE AHORRO -> Sugerido: $suggestedAmount TTC");

        // Mostramos un popup amigable con la sugerencia
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context!).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent, size: 28), 
                SizedBox(width: 8), 
                Text("Asesor IA", style: TextStyle(fontWeight: FontWeight.bold))
              ]
            ),
            content: Text(
              "¡He notado un nuevo ingreso! Tienes una excelente oportunidad para generar rendimientos. ¿Deseas ir a tus Bolsillos Inteligentes y ahorrar los $suggestedAmount TTC recomendados?",
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("En otro momento", style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const Icon(Icons.savings_rounded, size: 18),
                label: const Text("Ir a mis Bolsillos", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.push(context!, MaterialPageRoute(builder: (_) => const VaultsScreen()));
                },
              )
            ],
          )
        );
        break;

      default:
        print("🤷‍♂️ Acción no reconocida o no manejada por el Router.");
    }
  }
}