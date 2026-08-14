import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/contact_service.dart';

class AddContactModal {
  // static void show(BuildContext context, {required VoidCallback onSuccess}) {
  //   TextEditingController aliasSearchController = TextEditingController();
  //   Map<String, dynamic>? usuarioEncontrado;
  //   bool buscando = false;
  //   String errorMsg = "";
  //   String catSeleccionada = "Normal";

  //   final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //   final userService = Provider.of<UserService>(context, listen: false);
  //   final contactService = Provider.of<ContactService>(context, listen: false);

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (BuildContext context, StateSetter setModalState) {
  //         final colorScheme = Theme.of(context).colorScheme;
  //         final onSurfaceColor = colorScheme.onSurface;
  //         final cardColor = Theme.of(context).cardColor;

  //         return Container(
  //           padding: EdgeInsets.only(
  //             bottom: MediaQuery.of(ctx).viewInsets.bottom,
  //             left: 24, right: 24, top: 24,
  //           ),
  //           decoration: BoxDecoration(
  //             color: cardColor,
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
  //               const SizedBox(height: 20),
  //               Text("Agregar Nuevo Contacto", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 20),

  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextField(
  //                       controller: aliasSearchController,
  //                       style: TextStyle(color: onSurfaceColor),
  //                       decoration: InputDecoration(
  //                         hintText: "Buscar por @alias o 0x...",
  //                         prefixText: "@ ",
  //                         filled: true,
  //                         fillColor: onSurfaceColor.withOpacity(0.05),
  //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 10),
  //                   ElevatedButton(
  //                     style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 15)),
  //                     onPressed: () async {
  //                       final query = aliasSearchController.text.trim().replaceAll("@", "");
  //                       if (query.isEmpty) return;

  //                       setModalState(() { buscando = true; errorMsg = ""; usuarioEncontrado = null; });
                        
  //                       // Usamos el UserService limpio que creamos antes
  //                       var res = await userService.searchByAlias(query);
  //                       if (res == null && query.startsWith("0x")) {
  //                         res = await userService.getUserByWallet(query);
  //                       }

  //                       if (res != null) {
  //                         setModalState(() { usuarioEncontrado = res; buscando = false; });
  //                       } else {
  //                         setModalState(() { errorMsg = "Usuario no encontrado."; buscando = false; });
  //                       }
  //                     },
  //                     child: buscando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.search, color: onSurfaceColor),
  //                   ),
  //                 ],
  //               ),

  //               if (errorMsg.isNotEmpty)
  //                 Padding(padding: const EdgeInsets.all(8.0), child: Text(errorMsg, style: TextStyle(color: colorScheme.error))),

  //               if (usuarioEncontrado != null) ...[
  //                 const SizedBox(height: 20),
  //                 Container(
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
  //                   child: Column(
  //                     children: [
  //                       CircleAvatar(backgroundColor: colorScheme.primary, child: const Icon(Icons.person, color: Colors.white)),
  //                       const SizedBox(height: 10),
  //                       Text("@${usuarioEncontrado!['alias']}", style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.bold)),
  //                       const SizedBox(height: 5),
  //                       Text(usuarioEncontrado!['walletAddress'], style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
  //                       const SizedBox(height: 15),

  //                       DropdownButtonFormField<String>(
  //                         value: catSeleccionada,
  //                         dropdownColor: cardColor,
  //                         style: TextStyle(color: onSurfaceColor),
  //                         decoration: InputDecoration(
  //                           labelText: "Categoría",
  //                           filled: true,
  //                           fillColor: Colors.black12,
  //                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  //                         ),
  //                         items: ['Normal', 'Familiar', 'Comercial'].map((String cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
  //                         onChanged: (val) { setModalState(() => catSeleccionada = val!); },
  //                       ),
  //                       const SizedBox(height: 20),

  //                       SizedBox(
  //                         width: double.infinity,
  //                         child: ElevatedButton.icon(
  //                           style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
  //                           onPressed: () async {
  //                             // Usamos el ContactService limpio
  //                             String res = await contactService.addContact(
  //                               usuarioEncontrado!['walletAddress'].toString(), 
  //                               usuarioEncontrado!['alias'], 
  //                               catSeleccionada
  //                             );

  //                             if (res == "Exito") {
  //                               Navigator.pop(ctx);
  //                               UIHelper.showCustomSnackbar("Contacto Guardado");
  //                               onSuccess();
  //                             } else {
  //                               setModalState(() => errorMsg = res);
  //                             }
  //                           },
  //                           icon: const Icon(Icons.save, color: Colors.white),
  //                           label: const Text("Guardar Contacto", style: TextStyle(color: Colors.white)),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //               const SizedBox(height: 30),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final colorScheme = Theme.of(context).colorScheme;
          final onSurfaceColor = colorScheme.onSurface;
          final cardColor = Theme.of(context).cardColor;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  
                  // BUSCADOR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurfaceColor.withOpacity(0.05))),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(Icons.search_rounded, color: onSurfaceColor.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: aliasSearchController,
                            style: TextStyle(color: onSurfaceColor),
                            decoration: InputDecoration(
                              hintText: "Ingresa alias o wallet...",
                              hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.4)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4361EE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                          ),
                          onPressed: () async {
                            final query = aliasSearchController.text.trim().replaceAll("@", "");
                            if (query.isEmpty) return;

                            setModalState(() { buscando = true; errorMsg = ""; usuarioEncontrado = null; });
                            
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
                          child: buscando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Buscar", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  if (errorMsg.isNotEmpty)
                    Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text(errorMsg, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)))),

                  if (usuarioEncontrado != null) ...[
                    const SizedBox(height: 24),
                    // TARJETA DE USUARIO
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: onSurfaceColor.withOpacity(0.05))),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SmartAvatar(address: usuarioEncontrado!['walletAddress'], size: 56),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(usuarioEncontrado!['alias'] ?? "Usuario", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text("@${usuarioEncontrado!['alias']}", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          const Text("Gasless Platinum", style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(color: onSurfaceColor.withOpacity(0.05), height: 1),
                        FutureBuilder<Map<String, dynamic>?>(
                      future: Provider.of<UserService>(ctx, listen: false).getUserByWallet(usuarioEncontrado!['walletAddress']),
                      builder: (context, snapshot) {
                        String phone = "No registrado";
                        String cedula = "No registrada";
                        String email = "No registrado";

                        if (snapshot.hasData && snapshot.data != null) {
                          phone = snapshot.data!['phoneNumber'] ?? phone;
                          cedula = snapshot.data!['cedula'] ?? cedula;
                          email = snapshot.data!['email'] ?? email;
                        }

                        return Column(
                          children: [
                            _buildInfoRow(Icons.phone_android_rounded, "Celular", phone, false, onSurfaceColor),
                            _buildInfoRow(Icons.badge_outlined, "Cédula", cedula, false, onSurfaceColor),
                            _buildInfoRow(Icons.email_outlined, "Correo", email, false, onSurfaceColor),
                          ],
                        );
                      }
                    ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CATEGORÍA (CHIPS)
                    Text("Categoría", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Normal', 'Familiar', 'Comercial'].map((String cat) {
                        bool isSel = catSeleccionada == cat;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => catSeleccionada = cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF4361EE) : cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSel ? Colors.transparent : onSurfaceColor.withOpacity(0.1))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(cat == 'Normal' ? Icons.person_outline : cat == 'Familiar' ? Icons.people_alt_outlined : Icons.storefront_outlined, size: 16, color: isSel ? Colors.white : onSurfaceColor.withOpacity(0.6)),
                                  const SizedBox(width: 6),
                                  Text(cat, style: TextStyle(color: isSel ? Colors.white : onSurfaceColor.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 13)),
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC3FF), 
                          foregroundColor: const Color(0xFF00218d),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                        ),
                        onPressed: () async {
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
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text("Guardar Contacto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String title, String value, bool showCopy, Color onSurfaceColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Icon(icon, color: onSurfaceColor.withOpacity(0.5), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: onSurfaceColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: title == 'Wallet' ? 'monospace' : null)),
              ],
            ),
          ),
          if (showCopy) Icon(Icons.copy_rounded, color: onSurfaceColor.withOpacity(0.3), size: 18),
        ],
      ),
    );
  }
}