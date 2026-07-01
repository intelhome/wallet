import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/group_social_service.dart';

class GroupModals {
  
  // --- CREAR GRUPO ---
  static void showCreate(BuildContext context, {required List<dynamic> contactosDisponibles, required VoidCallback onSuccess}) {
    TextEditingController nombreGrupoController = TextEditingController();
    List<dynamic> seleccionados = [];
    bool creando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext contextDialog, StateSetter setModalState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85, 
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.group_add, size: 50, color: colorScheme.primary),
                const SizedBox(height: 10),
                Text("Crear Fondo Común", textAlign: TextAlign.center, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nombreGrupoController,
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Nombre del Grupo",
                    prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                    filled: true,
                    fillColor: onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Selecciona los integrantes:", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Expanded(
                  child: contactosDisponibles.isEmpty 
                    ? const Center(child: Text("No tienes contactos para agregar"))
                    : ListView.builder(
                        itemCount: contactosDisponibles.length,
                        itemBuilder: (context, i) {
                          var c = contactosDisponibles[i];
                          bool isSelected = seleccionados.contains(c);
                          return CheckboxListTile(
                            activeColor: colorScheme.primary,
                            title: Text("@${c['alias']}", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                            secondary: SmartAvatar(address: c['contactAddress'], size: 35),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) seleccionados.add(c);
                                else seleccionados.remove(c);
                              });
                            },
                          );
                        },
                      ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                  child: creando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                    : Text("Crear Grupo con ${seleccionados.length} miembros", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
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