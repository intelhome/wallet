import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/contact_service.dart';

class EditContactModal {
  static void show(BuildContext context, {required String id, required String aliasActual, required String catActual, required VoidCallback onSuccess}) {
    final TextEditingController aliasController = TextEditingController(text: aliasActual);
    String catSeleccionada = ['Familiar', 'Comercial', 'Normal'].contains(catActual) ? catActual : 'Normal';
    bool guardando = false;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (contextDialog, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text("Editar Contacto", style: TextStyle(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: aliasController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Alias", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: catSeleccionada,
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Categoría", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Normal', 'Familiar', 'Comercial'].map((String cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) { setStateDialog(() => catSeleccionada = val!); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
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
              child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Guardar", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}