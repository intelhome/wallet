import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/group_social_service.dart';

class GroupModals {
  
  // // --- CREAR GRUPO ---
  // static void showCreate(BuildContext context, {required List<dynamic> contactosDisponibles, required VoidCallback onSuccess}) {
  //   TextEditingController nombreGrupoController = TextEditingController();
  //   List<dynamic> seleccionados = [];
  //   bool creando = false;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Theme.of(context).cardColor,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (BuildContext contextDialog, StateSetter setModalState) {
  //         final theme = Theme.of(ctx);
  //         final colorScheme = theme.colorScheme;
  //         final onSurface = colorScheme.onSurface;

  //         return Container(
  //           height: MediaQuery.of(ctx).size.height * 0.85, 
  //           padding: const EdgeInsets.all(24),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               Icon(Icons.group_add, size: 50, color: colorScheme.primary),
  //               const SizedBox(height: 10),
  //               Text("Crear Fondo Común", textAlign: TextAlign.center, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 20),
                
  //               TextField(
  //                 controller: nombreGrupoController,
  //                 style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
  //                 decoration: InputDecoration(
  //                   labelText: "Nombre del Grupo",
  //                   prefixIcon: Icon(Icons.title, color: colorScheme.primary),
  //                   filled: true,
  //                   fillColor: onSurface.withOpacity(0.05),
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               Text("Selecciona los integrantes:", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 10),

  //               Expanded(
  //                 child: contactosDisponibles.isEmpty 
  //                   ? const Center(child: Text("No tienes contactos para agregar"))
  //                   : ListView.builder(
  //                       itemCount: contactosDisponibles.length,
  //                       itemBuilder: (context, i) {
  //                         var c = contactosDisponibles[i];
  //                         bool isSelected = seleccionados.contains(c);
  //                         return CheckboxListTile(
  //                           activeColor: colorScheme.primary,
  //                           title: Text("@${c['alias']}", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
  //                           secondary: SmartAvatar(address: c['contactAddress'], size: 35),
  //                           value: isSelected,
  //                           onChanged: (val) {
  //                             setModalState(() {
  //                               if (val == true) seleccionados.add(c);
  //                               else seleccionados.remove(c);
  //                             });
  //                           },
  //                         );
  //                       },
  //                     ),
  //               ),
  //               const SizedBox(height: 20),

  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //                 onPressed: (seleccionados.isEmpty || nombreGrupoController.text.trim().isEmpty || creando) ? null : () async {
  //                   setModalState(() => creando = true);
                    
  //                   List<Map<String, dynamic>> members = seleccionados.map((c) => {
  //                     "walletAddress": c['contactAddress'].toString().toLowerCase(),
  //                     "alias": c['alias']
  //                   }).toList();

  //                   final groupService = Provider.of<GroupSocialService>(contextDialog, listen: false);
  //                   final result = await groupService.createGroup(nombreGrupoController.text.trim(), "Admin", members);

  //                   if (result == "SUCCESS") {
  //                     Navigator.pop(ctx);
  //                     UIHelper.showCustomSnackbar("Grupo creado. Invitaciones enviadas.");
  //                     onSuccess(); 
  //                   } else {
  //                     setModalState(() => creando = false);
  //                     UIHelper.showCustomSnackbar(result, isError: true);
  //                   }
  //                 },
  //                 child: creando 
  //                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
  //                   : Text("Crear Grupo con ${seleccionados.length} miembros", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //               )
  //             ],
  //           ),
  //         );
  //       }
  //     )
  //   );
  // }

static void showCreate(BuildContext context, {required List<dynamic> contactosDisponibles, required VoidCallback onSuccess}) {
    TextEditingController nombreGrupoController = TextEditingController();
    TextEditingController searchController = TextEditingController();
    List<dynamic> seleccionados = [];
    bool creando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext contextDialog, StateSetter setModalState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          // Filtro local en el modal
          String query = searchController.text.toLowerCase().trim();
          List<dynamic> filtrados = contactosDisponibles.where((c) {
            final alias = (c['alias'] ?? '').toString().toLowerCase();
            return alias.contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(ctx)),
                    const Expanded(child: Text("Crear Grupo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text("NOMBRE DEL GRUPO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.5), letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextField(
                  controller: nombreGrupoController,
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Ej: Viaje a la Costa",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.groups_rounded, color: onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: onSurface.withOpacity(0.1)),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Seleccionar\nIntegrantes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface, height: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF4361EE).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text("${seleccionados.length}/${contactosDisponibles.length}\nSeleccionados", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFBAC3FF), fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Buscador de contactos
                TextField(
                  controller: searchController,
                  onChanged: (v) => setModalState((){}), // Refresca lista
                  decoration: InputDecoration(
                    hintText: "Buscar contactos...",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                    filled: true, fillColor: theme.cardColor,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // LISTA DE CONTACTOS
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.35, // Altura fija para la lista
                  child: filtrados.isEmpty 
                    ? Center(child: Text("No se encontraron contactos", style: TextStyle(color: onSurface.withOpacity(0.5))))
                    : ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (context, i) {
                          var c = filtrados[i];
                          bool isSelected = seleccionados.contains(c);
                          String wallet = c['contactAddress'] ?? '';
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) seleccionados.remove(c);
                                else seleccionados.add(c);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? const Color(0xFF4361EE) : Colors.transparent)
                              ),
                              child: Row(
                                children: [
                                  SmartAvatar(address: wallet, size: 48),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['alias'] ?? "Usuario", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text("${wallet.substring(0,4)}...${wallet.substring(wallet.length-4)}".toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : onSurface.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6)
                                    ),
                                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 16),

                // BOTÓN CREAR
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBAC3FF), 
                      foregroundColor: const Color(0xFF00218d), 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                    ),
                    onPressed: (seleccionados.isEmpty || nombreGrupoController.text.trim().isEmpty || creando) ? null : () async {
                      setModalState(() => creando = true);
                      
                      List<Map<String, dynamic>> members = seleccionados.map((c) => {
                        "walletAddress": c['contactAddress'].toString().toLowerCase(),
                        "alias": c['alias']
                      }).toList();

                      final groupService = Provider.of<GroupSocialService>(contextDialog, listen: false);
                      final result = await groupService.createGroup(nombreGrupoController.text.trim(), "Admin", members);

                      if (result == "SUCCESS") {
                        Navigator.pop(ctx);
                        UIHelper.showCustomSnackbar("Grupo creado. Invitaciones enviadas.");
                        onSuccess(); 
                      } else {
                        setModalState(() => creando = false);
                        UIHelper.showCustomSnackbar(result, isError: true);
                      }
                    },
                    icon: creando ? const SizedBox() : const Icon(Icons.add_circle_outline_rounded),
                    label: creando 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Text("Crear Grupo (${seleccionados.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      )
    );
  }
  // --- EDITAR NOMBRE DE GRUPO ---
  static void showEdit(BuildContext context, {required String id, required String nombreActual, required VoidCallback onSuccess}) {
    final TextEditingController nameController = TextEditingController(text: nombreActual);
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Renombrar Grupo", style: TextStyle(color: colorScheme.onSurface)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final groupService = Provider.of<GroupSocialService>(context, listen: false);
              await groupService.updateGroupName(id, nameController.text.trim());
              Navigator.pop(ctx);
              onSuccess();
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- CONFIRMAR ELIMINAR GRUPO ---
  static void showDeleteConfirm(BuildContext context, {required String id, required VoidCallback onSuccess}) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("¿Eliminar Grupo?", style: TextStyle(color: colorScheme.error)),
        content: Text("Esta acción no se puede deshacer.", style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () async {
              final groupService = Provider.of<GroupSocialService>(context, listen: false);
              await groupService.deleteGroup(id);
              Navigator.pop(ctx);
              onSuccess();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}