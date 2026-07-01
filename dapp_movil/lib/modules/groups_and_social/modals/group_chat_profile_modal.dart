import 'package:flutter/material.dart';
import '../../../core/services/smart_avatar.dart';

class GroupChatProfileModal {
  static void show(BuildContext context, String groupId, String groupName, int totalMembers) {
    final theme = Theme.of(context);
    
   showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 Permite que el modal use más espacio en la pantalla
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView( // 🔥 Evita el error de overflow haciéndolo deslizable
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmartAvatar(address: groupId, size: 80),
                const SizedBox(height: 16),
                Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("$totalMembers Miembros Activos", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                
                // INFORMACIÓN DE SEGURIDAD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.2))),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.green, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cifrado de Sala", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            SizedBox(height: 4),
                            Text("Todos los mensajes y archivos multimedia en este grupo están protegidos mediante cifrado P2P en tránsito.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // INFORMACIÓN DEL TESORERO IA
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2))),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tesorero IA Activo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            SizedBox(height: 4),
                            Text("La inteligencia artificial está atenta a palabras como 'pagué' o 'dividir' para crear cuentas compartidas automáticamente.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => Navigator.pop(ctx), 
                    child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                )
              ]
            )
          ),
        ),
      )
    );
  }
}