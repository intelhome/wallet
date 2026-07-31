import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/admin_service.dart';

class UpdateUserTierModal {
  static void show({required BuildContext context, required VoidCallback onUpdateSuccess}) {
    final TextEditingController walletController = TextEditingController();
    String selectedTier = "BASIC";
    bool isProcessing = false;

  
    final cachedPlans = LocalCacheService().getCachedAdminPlans();
    
    // Fallback de seguridad (por si la caché está vacía)
    final Map<String, String> prices = {
      "FREE": "0.00",
      "BASIC": "9.99",
      "PREMIUM": "29.99"
    };

    // 🔥 2. SOBRESCRIBIMOS EL MAPA CON LOS PRECIOS REALES
    for (var plan in cachedPlans) {
      String tierName = (plan['tier'] ?? '').toString().toUpperCase();
      double price = (plan['price'] is int) 
          ? (plan['price'] as int).toDouble() 
          : (double.tryParse(plan['price'].toString()) ?? 0.0);
          
      if (prices.containsKey(tierName)) {
        prices[tierName] = price.toStringAsFixed(2);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext dialogCtx, StateSetter setStateModal) {
            final theme = Theme.of(ctx);
            final onSurface = theme.colorScheme.onSurface;
            final cardColor = theme.cardColor;

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.90, // Casi pantalla completa
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // HEADER CON ÍCONO DE CERRAR Y TÍTULO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        IconButton(icon: Icon(Icons.close_rounded, color: onSurface), onPressed: () => Navigator.pop(ctx)),
                        const Expanded(child: Text("Asignar Plan", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 48), // Espaciador para centrar el título
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BÚSQUEDA DE BILLETERA
                          Text("Billetera del Usuario", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.7))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: walletController,
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Billetera del Usuario (0x...)",
                              hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                              prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // SELECCIÓN DE PLAN
                          Text("SELECCIONAR NUEVO PLAN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: onSurface.withOpacity(0.7))),
                          const SizedBox(height: 16),

                          ...["FREE", "BASIC", "PREMIUM"].map((tier) {
                            bool isSelected = selectedTier == tier;
                            return GestureDetector(
                              onTap: () => setStateModal(() => selectedTier = tier),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFBAC3FF).withOpacity(0.1) : cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.05), width: isSelected ? 1.5 : 1),
                                ),
                                child: Column(
                                  children: [
                                    Text(tier, style: TextStyle(color: isSelected ? const Color(0xFFBAC3FF) : onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text("${prices[tier]} / mes", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 24),

                          // RESUMEN DINÁMICO DEL PLAN
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: Color(0xFFBAC3FF), size: 20),
                                    const SizedBox(width: 12),
                                    Text("Resumen de Cambio: $selectedTier", style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildSummaryRow(onSurface, "Transacciones Gasless", "Hasta ${selectedTier == 'PREMIUM' ? 'ilimitadas' : selectedTier == 'BASIC' ? '50' : '5'} transacciones sin costo de gas por mes."),
                                _buildSummaryRow(onSurface, selectedTier == 'PREMIUM' ? "Auditoría IA Avanzada" : "Auditoría IA Básica", selectedTier == 'FREE' ? "Sin revisión automática antes de firmar." : "Revisión automática de contratos antes de firmar."),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // BOTÓN STICKY INFERIOR
                  Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor, 
                      border: Border(top: BorderSide(color: onSurface.withOpacity(0.05)))
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC3FF), 
                          foregroundColor: const Color(0xFF00218d),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), 
                          elevation: 0
                        ),
                        onPressed: isProcessing ? null : () async {
                          if (walletController.text.trim().isEmpty) {
                            UIHelper.showCustomSnackbar("Ingresa la billetera del usuario", isError: true);
                            return;
                          }
                          setStateModal(() => isProcessing = true);
                          
                          final adminService = Provider.of<AdminService>(context, listen: false);
                          String res = await adminService.updateUserTier(walletController.text.trim(), selectedTier);
                          
                          if (res == "Exito") {
                            Navigator.pop(ctx);
                            UIHelper.showCustomSnackbar("Plan de usuario actualizado a $selectedTier");
                            onUpdateSuccess();
                          } else {
                            setStateModal(() => isProcessing = false);
                            UIHelper.showCustomSnackbar(res, isError: true);
                          }
                        },
                        icon: isProcessing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF00218d), strokeWidth: 2))
                            : const Icon(Icons.upgrade_rounded),
                        label: Text(isProcessing ? "Procesando..." : "Actualizar Membresía", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // WIDGET HELPER PARA LAS FILAS DEL RESUMEN
  static Widget _buildSummaryRow(Color onSurface, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: onSurface.withOpacity(0.8), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// class UpdateUserTierModal {
//   static void show({required BuildContext context, required VoidCallback onUpdateSuccess}) {
//     final TextEditingController walletController = TextEditingController();
//     String selectedTier = "BASIC";
//     bool isProcessing = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) {
//         final colorScheme = Theme.of(ctx).colorScheme;
        
//         return StatefulBuilder(
//           builder: (BuildContext dialogCtx, StateSetter setStateModal) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.admin_panel_settings, size: 40, color: Colors.purpleAccent),
//                   const SizedBox(height: 10),
//                   const Text("Gestionar Plan de Usuario", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 20),
                  
//                   TextField(
//                     controller: walletController,
//                     decoration: InputDecoration(
//                       labelText: "Billetera del Usuario (0x...)",
//                       prefixIcon: const Icon(Icons.account_balance_wallet),
//                       filled: true,
//                       fillColor: colorScheme.onSurface.withOpacity(0.05),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   DropdownButtonFormField<String>(
//                     value: selectedTier,
//                     decoration: InputDecoration(
//                       labelText: "Nuevo Plan a Asignar",
//                       filled: true,
//                       fillColor: colorScheme.onSurface.withOpacity(0.05),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                     ),
//                     items: ["FREE", "BASIC", "PREMIUM"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
//                     onChanged: (val) => setStateModal(() => selectedTier = val!),
//                   ),
//                   const SizedBox(height: 30),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
//                       ),
//                       onPressed: isProcessing ? null : () async {
//                         if (walletController.text.trim().isEmpty) return;
//                         setStateModal(() => isProcessing = true);
                        
//                         final adminService = Provider.of<AdminService>(context, listen: false);
//                         String res = await adminService.updateUserTier(walletController.text.trim(), selectedTier);
                        
//                         if (res == "Exito") {
//                           Navigator.pop(ctx);
//                           UIHelper.showCustomSnackbar("Plan de usuario actualizado a $selectedTier");
//                           onUpdateSuccess();
//                         } else {
//                           setStateModal(() => isProcessing = false);
//                           ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.redAccent));
//                         }
//                       },
//                       child: isProcessing 
//                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                           : const Text("Actualizar Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             );
//           }
//         );
//       }
//     );
//   }
// }