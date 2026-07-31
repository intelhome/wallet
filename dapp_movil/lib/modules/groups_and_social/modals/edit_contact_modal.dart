import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/contact_service.dart';

class EditContactModal {

  static void show(BuildContext context, {required String id, required String aliasActual, required String catActual, required VoidCallback onSuccess, String? walletAddress}) {
    final TextEditingController aliasController = TextEditingController(text: aliasActual);
    String catSeleccionada = ['Familiar', 'Comercial', 'Normal'].contains(catActual) ? catActual : 'Normal';
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (contextDialog, setStateDialog) {
          final colorScheme = Theme.of(context).colorScheme;
          final onSurface = colorScheme.onSurface;
          final cardColor = Theme.of(context).cardColor;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABECERA
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(ctx)),
                      const Expanded(child: Text("Editar Contacto", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SMART AVATAR (Requiere que pases walletAddress en los parámetros)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: onSurface.withOpacity(0.1), width: 4)
                      ),
                      child: SmartAvatar(address: walletAddress ?? '0x0000000000000000000000000000000000000000', size: 100),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ALIAS (TIPO PÍLDORA OSCURA)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Alias", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.5))),
                        TextField(
                          controller: aliasController,
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CATEGORÍA (CHIPS M3)
                  Text("Categoría", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Normal', 'Familiar', 'Comercial'].map((String cat) {
                      bool isSel = catSeleccionada == cat;
                      IconData icon = cat == 'Normal' ? Icons.person_outline : cat == 'Familiar' ? Icons.people_alt_outlined : Icons.storefront_outlined;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setStateDialog(() => catSeleccionada = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF4361EE) : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? Colors.transparent : onSurface.withOpacity(0.1))
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 16, color: isSel ? Colors.white : onSurface.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                Text(cat, style: TextStyle(color: isSel ? Colors.white : onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // BOTÓN GUARDAR
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBAC3FF), 
                        foregroundColor: const Color(0xFF00218d),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                      ),
                      onPressed: guardando ? null : () async {
                        if (aliasController.text.trim().isEmpty) return;
                        setStateDialog(() => guardando = true);
                        
                        final contactService = Provider.of<ContactService>(contextDialog, listen: false);
                        bool success = await contactService.updateContact(id, alias: aliasController.text.trim(), category: catSeleccionada);
                        
                        if (success) {
                          Navigator.pop(ctx);
                          onSuccess(); 
                        } else {
                          setStateDialog(() => guardando = false);
                        }
                      },
                      child: guardando ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
//   static void show(BuildContext context, {required String id, required String aliasActual, required String catActual, required VoidCallback onSuccess}) {
//     final TextEditingController aliasController = TextEditingController(text: aliasActual);
//     String catSeleccionada = ['Familiar', 'Comercial', 'Normal'].contains(catActual) ? catActual : 'Normal';
//     bool guardando = false;
//     final colorScheme = Theme.of(context).colorScheme;

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (contextDialog, setStateDialog) => AlertDialog(
//           backgroundColor: Theme.of(context).cardColor,
//           title: Text("Editar Contacto", style: TextStyle(color: colorScheme.onSurface)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: aliasController,
//                 style: TextStyle(color: colorScheme.onSurface),
//                 decoration: InputDecoration(labelText: "Alias", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
//               ),
//               const SizedBox(height: 15),
//               DropdownButtonFormField<String>(
//                 value: catSeleccionada,
//                 dropdownColor: Theme.of(context).cardColor,
//                 style: TextStyle(color: colorScheme.onSurface),
//                 decoration: InputDecoration(labelText: "Categoría", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
//                 items: ['Normal', 'Familiar', 'Comercial'].map((String cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
//                 onChanged: (val) { setStateDialog(() => catSeleccionada = val!); },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
//               onPressed: guardando ? null : () async {
//                 if (aliasController.text.trim().isEmpty) return;
//                 setStateDialog(() => guardando = true);
                
//                 final contactService = Provider.of<ContactService>(contextDialog, listen: false);
//                 bool success = await contactService.updateContact(id, alias: aliasController.text.trim(), category: catSeleccionada);
                
//                 if (success) {
//                   Navigator.pop(ctx);
//                   onSuccess(); 
//                 } else {
//                   setStateDialog(() => guardando = false);
//                 }
//               },
//               child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Guardar", style: TextStyle(color: Colors.white)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }