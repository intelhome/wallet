import 'package:dapp_movil/modules/burner_wallets/modals/send_burner_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/burner_service.dart';

class BurnerDetailsModal {
  static void show(BuildContext rootContext, dynamic wallet, VoidCallback onRefresh) {
    showModalBottomSheet(
      context: rootContext,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final onSurface = colorScheme.onSurface;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(wallet['label'] ?? 'Tarjeta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: onSurface)),
              Text("Opciones de Tarjeta Virtual", style: TextStyle(color: onSurface.withOpacity(0.5))),
              const SizedBox(height: 24),

              // BOTÓN ENVIAR PAGO
            // BOTÓN ENVIAR PAGO
              // BOTÓN ENVIAR PAGO
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.deepOrange)),
                title: const Text("Hacer un Pago Seguro", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Usar fondos de la Tarjeta Virtual"),
                onTap: () {
                  Navigator.pop(ctx);
                  SendBurnerModal.show(
                    context: rootContext, 
                    burnerAddress: wallet['burnerAddress'],
                    balanceTTC: wallet['balance'].toString(),
                    onUpdateBalance: onRefresh,
                  );
                },
              ),
              const Divider(height: 10),

              // BOTÓN COPIAR DIRECCIÓN
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.copy_rounded, color: Colors.blueGrey)),
                title: const Text("Copiar Dirección", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: wallet['burnerAddress']));
                  UIHelper.showCustomSnackbar("Dirección temporal copiada");
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 10),

              // BOTÓN QUEMAR
              ListTile(
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.local_fire_department_rounded, color: Colors.redAccent)),
                title: const Text("Quemar Tarjeta", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                subtitle: const Text("Destruye la llave y recupera el saldo"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBurn(rootContext, wallet, onRefresh);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  static void _confirmBurn(BuildContext rootContext, dynamic wallet, VoidCallback onRefresh) {
    final authCore = Provider.of<AuthCoreService>(rootContext, listen: false);
    final burnerService = Provider.of<BurnerService>(rootContext, listen: false);
    
    showDialog(
      context: rootContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("¿Quemar Billetera?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("La llave privada se destruirá irreversiblemente. Si hay fondos sobrantes en esta dirección, se realizará un barrido automático devolviéndolos a tu cuenta principal."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la destrucción y barrido."));
              HapticFeedback.mediumImpact();
              bool isAuth = await authCore.authenticateUser();
              Navigator.pop(rootContext);

              if (!isAuth) return;

              // showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Protocolo de Barrido", message: "Recuperando fondos sobrantes..."));
              // String res = await burnerService.burnWallet(wallet['burnerAddress']);
              // Navigator.pop(rootContext);
             showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Protocolo de Barrido", message: "Recuperando fondos sobrantes..."));
              
              // 🔥 NUEVO: Atrapamos el double en lugar del String y eliminamos el if (res) de abajo
              try {
                double refunded = await burnerService.burnWallet(wallet['burnerAddress']);
                Navigator.pop(rootContext);
                UIHelper.showCustomSnackbar("Protocolo completado. Se rescataron ${refunded.toStringAsFixed(2)} TTC.");
                onRefresh(); // Llama a la actualización por WebSocket
              } catch (e) {
                Navigator.pop(rootContext);
                UIHelper.showCustomSnackbar(e.toString().replaceAll("Exception: ", ""), isError: true);
              }
              
              // if (!res.startsWith("Error")) {
              //   UIHelper.showCustomSnackbar("Protocolo de incineración iniciado.");
              //   onRefresh(); // Llama a la actualización por WebSocket
              // } else {
              //   UIHelper.showCustomSnackbar(res, isError: true);
              // }
            },
            child: const Text("Quemar Ahora", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}