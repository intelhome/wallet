import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/family_service.dart';

class FamilyInviteDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> invite, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            
            // Función interna para manejar la respuesta a la solicitud
            Future<void> responder(bool aceptar) async {
              setModalState(() => isProcessing = true);
              final service = Provider.of<FamilyService>(context, listen: false);
              String res = await service.respondToInvite(invite['senderWallet'], aceptar);
              
              if (res == "SUCCESS") {
                Navigator.pop(ctx);
                UIHelper.showCustomSnackbar(aceptar ? "¡Vínculo familiar aceptado y guardado!" : "Invitación familiar rechazada.");
                onSuccess(); // Recarga la pantalla de contactos
              } else {
                setModalState(() => isProcessing = false);
                UIHelper.showCustomSnackbar(res, isError: true);
              }
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Píldora superior (indicador de arrastre)
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  
                  const Text("Solicitud de Familia", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  
                  // Avatar del remitente
                  SmartAvatar(address: invite['senderWallet'] ?? '', size: 80),
                  const SizedBox(height: 16),
                  
                  // Nombres y Alias
                  Text("@${invite['senderAlias'] ?? 'Usuario'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Cédula: ${invite['senderCedula'] ?? 'Oculta'}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  
                  // Caja de Información de Contacto
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05), 
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email_rounded, size: 20, color: Colors.grey), 
                            const SizedBox(width: 12), 
                            Text(invite['senderEmail'] ?? "Correo no disponible", style: const TextStyle(fontWeight: FontWeight.w500))
                          ]
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 20, color: Colors.grey), 
                            const SizedBox(width: 12), 
                            Text(invite['senderPhone'] ?? "Celular no disponible", style: const TextStyle(fontWeight: FontWeight.w500))
                          ]
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botones de Acción
                  if (isProcessing) 
                    const CircularProgressIndicator()
                  else 
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                            ), 
                            onPressed: () => responder(false), 
                            child: const Text("Rechazar", style: TextStyle(fontWeight: FontWeight.bold))
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(vertical: 16), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ), 
                            onPressed: () => responder(true), 
                            child: const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold))
                          )
                        ),
                      ],
                    ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}