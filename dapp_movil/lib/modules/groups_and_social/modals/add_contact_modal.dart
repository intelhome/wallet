import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/contact_service.dart';

class AddContactModal {
  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    TextEditingController aliasSearchController = TextEditingController();
    Map<String, dynamic>? usuarioEncontrado;
    bool buscando = false;
    String errorMsg = "";
    String catSeleccionada = "Normal";

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final contactService = Provider.of<ContactService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final colorScheme = Theme.of(context).colorScheme;
          final onSurfaceColor = colorScheme.onSurface;
          final cardColor = Theme.of(context).cardColor;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text("Agregar Nuevo Contacto", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: aliasSearchController,
                        style: TextStyle(color: onSurfaceColor),
                        decoration: InputDecoration(
                          hintText: "Buscar por @alias o 0x...",
                          prefixText: "@ ",
                          filled: true,
                          fillColor: onSurfaceColor.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () async {
                        final query = aliasSearchController.text.trim().replaceAll("@", "");
                        if (query.isEmpty) return;

                        setModalState(() { buscando = true; errorMsg = ""; usuarioEncontrado = null; });
                        
                        // Usamos el UserService limpio que creamos antes
                        var res = await userService.searchByAlias(query);
                        if (res == null && query.startsWith("0x")) {
                          res = await userService.getUserByWallet(query);
                        }

                        if (res != null) {
                          setModalState(() { usuarioEncontrado = res; buscando = false; });
                        } else {
                          setModalState(() { errorMsg = "Usuario no encontrado."; buscando = false; });
                        }
                      },
                      child: buscando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.search, color: onSurfaceColor),
                    ),
                  ],
                ),

                if (errorMsg.isNotEmpty)
                  Padding(padding: const EdgeInsets.all(8.0), child: Text(errorMsg, style: TextStyle(color: colorScheme.error))),

                if (usuarioEncontrado != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        CircleAvatar(backgroundColor: colorScheme.primary, child: const Icon(Icons.person, color: Colors.white)),
                        const SizedBox(height: 10),
                        Text("@${usuarioEncontrado!['alias']}", style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(usuarioEncontrado!['walletAddress'], style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: catSeleccionada,
                          dropdownColor: cardColor,
                          style: TextStyle(color: onSurfaceColor),
                          decoration: InputDecoration(
                            labelText: "Categoría",
                            filled: true,
                            fillColor: Colors.black12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: ['Normal', 'Familiar', 'Comercial'].map((String cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) { setModalState(() => catSeleccionada = val!); },
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
                            onPressed: () async {
                              // Usamos el ContactService limpio
                              String res = await contactService.addContact(
                                usuarioEncontrado!['walletAddress'].toString(), 
                                usuarioEncontrado!['alias'], 
                                catSeleccionada
                              );

                              if (res == "Exito") {
                                Navigator.pop(ctx);
                                UIHelper.showCustomSnackbar("Contacto Guardado");
                                onSuccess();
                              } else {
                                setModalState(() => errorMsg = res);
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text("Guardar Contacto", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}