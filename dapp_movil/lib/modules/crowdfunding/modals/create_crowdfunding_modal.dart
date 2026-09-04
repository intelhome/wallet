import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/crowdfunding_service.dart';

class CreateCrowdfundingModal {
  static void show({
    required BuildContext context,
    String? initialTitle,
    String? initialTargetAmount,
    required String initialRegion,
    String? initialDurationDays,
    required double initialLat,
    required double initialLon,
    required VoidCallback onSuccess,
  }) {
    final titleCtrl = TextEditingController(text: initialTitle ?? "");
    final goalCtrl = TextEditingController(text: initialTargetAmount ?? "");
    final durationCtrl = TextEditingController(text: initialDurationDays ?? "30");
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        // Obtenemos los servicios desde el contexto de la app
        final authCore = Provider.of<AuthCoreService>(context, listen: false);
        final crowdfundingService = Provider.of<CrowdfundingService>(context, listen: false);

        return StatefulBuilder(
          builder: (contextDialog, setStateModal) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 40),
                const SizedBox(height: 10),
                const Text("Iniciar Proyecto Social", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: "Título (Ej: Ayuda para Tobi)", filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: "Duración de campaña (Días)", prefixIcon: const Icon(Icons.calendar_today_rounded), filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: goalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: "Meta a recaudar (TTC)", prefixIcon: const Icon(Icons.flag_rounded), filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),

                // AVISO DE CONTRATO INTELIGENTE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(child: Text("Contrato Escrow: Si no alcanzas la meta en 30 días, el dinero será devuelto automáticamente a los donantes.", style: TextStyle(fontSize: 12, color: Colors.amber))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

            SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary, // Limpio!
                        foregroundColor: colorScheme.onPrimary, // Limpio!
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: isProcessing ? null : () async {
                      if (titleCtrl.text.isEmpty || goalCtrl.text.isEmpty) return;
                      FocusScope.of(contextDialog).unfocus();

                      // 🛡️ REGLA DE ORO: BIOMETRÍA PARA FIRMAR EL SMART CONTRACT
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la firma del Smart Contract."));
                        bool isAuth = await authCore.authenticateUser();
                        Navigator.pop(context); 

                        if (!isAuth) return;

                        setStateModal(() => isProcessing = true);
                        try {
                          // 🔥 Solo dejamos esta llamada limpia y eliminamos la repetida
                          String res = await crowdfundingService.launchCampaign(
                            titleCtrl.text, 
                            "Descripción por defecto", 
                            "LOCAL", 
                            initialRegion, // 🔥 Usamos la región real
                            double.parse(goalCtrl.text), 
                            int.parse(durationCtrl.text), 
                            initialLat, // 🔥 Usamos latitud real
                            initialLon  // 🔥 Usamos longitud real
                          );
                          
                          if (res == "Exito") {
                            Navigator.pop(ctx);
                            UIHelper.showCustomSnackbar("Campaña creada en la Blockchain");
                            onSuccess(); // Llamamos la función para recargar la lista
                          } else {
                            UIHelper.showCustomSnackbar(res, isError: true);
                          }
                        } finally {
                          if (contextDialog.mounted) setStateModal(() => isProcessing = false);
                        }
                      },
                      child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Firmar y Lanzar Campaña", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }
}