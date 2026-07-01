import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/family_service.dart';

class AddFamilyModal {
  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    final identifierController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    String type = "CEDULA";
    bool isSearching = false;
    bool isInviting = false;
    
    // Estados dinámicos
    Map<String, dynamic>? usuarioEncontrado;
    bool showExternalForm = false; // Se activa si la búsqueda falla

  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (contextDialog, setModalState) {
          final theme = Theme.of(contextDialog);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          // 🔥 PASO 1: Búsqueda Inteligente (Alias/Cédula vs Wallet)
          Future<void> buscarPerfil() async {
            if (identifierController.text.trim().isEmpty) return;
            
            setModalState(() {
              isSearching = true;
              showExternalForm = false;
              usuarioEncontrado = null;
            });

            Map<String, dynamic>? resultado;
            String query = identifierController.text.trim();

            try {
              if (type == "WALLET") {
                // 🔥 SOLUCIÓN: Usamos tu UserService directo si es búsqueda por billetera
                final userService = Provider.of<UserService>(context, listen: false);
                resultado = await userService.getUserByWallet(query);
              } else {
                // Si es Alias o Cédula, usamos la lógica anterior
                final familyService = Provider.of<FamilyService>(context, listen: false);
                resultado = await familyService.buscarUsuarioParaFamilia(query, type);
              }
            } catch (e) {
              print("Error en búsqueda familiar: $e");
            }

            setModalState(() {
              isSearching = false;
              if (resultado != null && (resultado['walletAddress'] != null || resultado['alias'] != null)) {
                usuarioEncontrado = resultado;
              } else {
                showExternalForm = true; 
                UIHelper.showCustomSnackbar("Usuario no encontrado en la red.", isError: true);
              }
            });
          }

          // 🔥 PASO 2: Confirmar Vinculación
          Future<void> procesarInvitacion() async {
            setModalState(() => isInviting = true);
            final familyService = Provider.of<FamilyService>(context, listen: false);
            
            final res = await familyService.inviteFamilyMember(
              identifierController.text.trim(), type,
              email: showExternalForm ? emailController.text.trim() : null,
              phone: showExternalForm ? phoneController.text.trim() : null,
            );

            setModalState(() => isInviting = false);

            if (res['status'] == 'PENDING') {
              Navigator.pop(ctx);
              UIHelper.showCustomSnackbar("Solicitud familiar enviada.");
              onSuccess();
            } else if (res['status'] == 'PENDING_NON_EXISTENT') {
              Navigator.pop(ctx);
              UIHelper.showCustomSnackbar("Invitación externa registrada.");
              onSuccess();
              
              String msj = "¡Hola! Te he invitado a formar parte de mi círculo familiar seguro en nuestra billetera criptográfica. Descarga la aplicación e ingresa con tu cédula para aceptar la vinculación: https://play.google.com/store/apps/details?id=com.tuapp.dapp_movil";
              final Uri waUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msj)}");
              launchUrl(waUrl, mode: LaunchMode.externalApplication);
            } else {
              UIHelper.showCustomSnackbar(res['message'] ?? "Error", isError: true);
            }
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const Text("Vincular Familiar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),

                // ==============================
                // ZONA 1: BÚSQUEDA
                // ==============================
                if (usuarioEncontrado == null && !showExternalForm) ...[
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    items: const [
                      DropdownMenuItem(value: "CEDULA", child: Text("Por Cédula de Identidad")),
                      DropdownMenuItem(value: "ALIAS", child: Text("Por @Alias")),
                      DropdownMenuItem(value: "WALLET", child: Text("Por Billetera (0x)")),
                    ],
                    onChanged: (v) => setModalState(() => type = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: identifierController,
                          decoration: InputDecoration(labelText: "Identificador", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: isSearching ? null : buscarPerfil,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56, width: 56,
                          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: isSearching 
                              ? Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                              : Icon(Icons.search_rounded, color: colorScheme.primary),
                        ),
                      )
                    ],
                  ),
                ],

                // ==============================
                // ZONA 2: PERFIL ENCONTRADO
                // ==============================
                if (usuarioEncontrado != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
                    child: Column(
                      children: [
                        SmartAvatar(address: usuarioEncontrado!['walletAddress'] ?? '', size: 80),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("@${usuarioEncontrado!['alias'] ?? 'Desconocido'}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(usuarioEncontrado!['walletAddress'] ?? '', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: isInviting ? null : procesarInvitacion,
                    icon: isInviting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.family_restroom_rounded),
                    label: const Text("Enviar Solicitud Familiar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => setModalState(() => usuarioEncontrado = null),
                    child: const Text("Buscar otra persona", style: TextStyle(color: Colors.grey)),
                  )
                ],

                // ==============================
                // ZONA 3: USUARIO INEXISTENTE (FORMULARIO)
                // ==============================
                if (showExternalForm) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Text("El usuario no existe. Rellena estos datos para crear una invitación en espera. Cuando se registre, se vinculará automáticamente.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: emailController, decoration: InputDecoration(labelText: "Correo Electrónico (Opcional)", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneController, decoration: InputDecoration(labelText: "Celular (Opcional)", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: isInviting ? null : procesarInvitacion,
                    icon: isInviting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.wechat_rounded),
                    label: const Text("Invitar por WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  TextButton(
                    onPressed: () => setModalState(() => showExternalForm = false),
                    child: const Text("Intentar buscar de nuevo", style: TextStyle(color: Colors.grey)),
                  )
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}