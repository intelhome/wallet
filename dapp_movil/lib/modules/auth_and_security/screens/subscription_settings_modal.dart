import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/auth_core_service.dart';
import '../services/planConfigService.dart';

class SubscriptionSettingsModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final authCore = Provider.of<AuthCoreService>(context, listen: false);
        final planService = Provider.of<PlanConfigService>(context, listen: false);
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.manage_accounts_rounded, size: 50, color: Colors.purpleAccent),
                    const SizedBox(height: 10),
                    const Text("Gestión de Suscripción", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Plan Actual: ${authCore.currentTier}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 5),
                          const Text("Si cancelas la autorenovación, disfrutarás de tus beneficios hasta que el ciclo de facturación actual termine. Luego, tu cuenta volverá a ser FREE.", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        icon: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cancel_rounded),
                        label: Text(isProcessing ? "Cancelando..." : "Cancelar Autorenovación", style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: isProcessing ? null : () async {
                         bool? confirmar = await UIHelper.mostrarConfirmacion(
                            context: ctx, 
                            titulo: "Cancelar", 
                            mensaje: "¿Seguro que deseas cancelar tu suscripción?",
                            textoConfirmar: "Sí, cancelar", // 🔥 FIX: Parámetro requerido agregado
                            colorConfirmar: Colors.redAccent, // Opcional, para que el botón de confirmación se vea rojo
                          );
                          if (confirmar != true) return;

                          setStateModal(() => isProcessing = true);
                          bool ok = await planService.cancelAutoRenew(authCore);
                          setStateModal(() => isProcessing = false);

                          if (ok) {
                            Navigator.pop(ctx);
                            UIHelper.showCustomSnackbar("Suscripción cancelada con éxito");
                          } else {
                            UIHelper.showCustomSnackbar("Error al conectar con el servidor", isError: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar", style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}