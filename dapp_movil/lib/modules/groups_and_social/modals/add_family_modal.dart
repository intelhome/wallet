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
    
    String type = "ALIAS";
    bool isSearching = false;
    bool isInviting = false;
    Map<String, dynamic>? usuarioEncontrado;
    bool showExternalForm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (contextDialog, setModalState) {
          final theme = Theme.of(contextDialog);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          // Future<void> buscarPerfil() async {
          //   if (identifierController.text.trim().isEmpty) return;
          //   setModalState(() { isSearching = true; showExternalForm = false; usuarioEncontrado = null; });
          //   Map<String, dynamic>? resultado;
          //   String query = identifierController.text.trim();
          //   try {
          //     if (type == "WALLET") {
          //       final userService = Provider.of<UserService>(context, listen: false);
          //       resultado = await userService.getUserByWallet(query);
          //     } else {
          //       final familyService = Provider.of<FamilyService>(context, listen: false);
          //       resultado = await familyService.buscarUsuarioParaFamilia(query, type);
          //     }
          //   } catch (e) {}

          //   setModalState(() {
          //     isSearching = false;
          //     if (resultado != null && (resultado['walletAddress'] != null || resultado['alias'] != null)) {
          //       usuarioEncontrado = resultado;
          //     } else {
          //       showExternalForm = true; 
          //       UIHelper.showCustomSnackbar("Usuario no encontrado.", isError: true);
          //     }
          //   });
          // }

Future<void> buscarPerfil() async {
            if (identifierController.text.trim().isEmpty) return;
            setModalState(() { isSearching = true; showExternalForm = false; usuarioEncontrado = null; });
            
            try {
              final familyService = Provider.of<FamilyService>(context, listen: false);
              
              // 🔥 FIX 2: Pasamos la variable local 'type' como segundo argumento
              final resultado = await familyService.buscarUsuarioParaFamilia(
                identifierController.text.trim(), 
                type 
              );
              
              setModalState(() {
                isSearching = false;
                if (resultado != null) {
                  if (resultado['exists'] == true) {
                    usuarioEncontrado = resultado; 
                    type = resultado['type']; 
                  } else {
                    showExternalForm = true; 
                    UIHelper.showCustomSnackbar(resultado['message'] ?? "Usuario no encontrado. Se enviará enlace.", isError: false);
                  }
                } else {
                  showExternalForm = true;
                  UIHelper.showCustomSnackbar("Usuario no encontrado en la red.", isError: true);
                }
              });
            } catch (e) {
               setModalState(() => isSearching = false);
            }
          }

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
              Navigator.pop(ctx); UIHelper.showCustomSnackbar("Solicitud familiar enviada."); onSuccess();
            } else if (res['status'] == 'PENDING_NON_EXISTENT') {
              Navigator.pop(ctx); UIHelper.showCustomSnackbar("Invitación externa registrada."); onSuccess();
              String msj = "¡Hola! Te he invitado a formar parte de mi círculo familiar seguro en nuestra billetera criptográfica. Descarga la aplicación: https://play.google.com/store/apps/details?id=com.tuapp.dapp_movil";
              final Uri waUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msj)}");
              launchUrl(waUrl, mode: LaunchMode.externalApplication);
            } else {
              UIHelper.showCustomSnackbar(res['message'] ?? "Error", isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () {
                        if (usuarioEncontrado != null || showExternalForm) {
                          setModalState(() { usuarioEncontrado = null; showExternalForm = false; });
                        } else {
                          Navigator.pop(ctx);
                        }
                      }),
                      Expanded(child: Text(usuarioEncontrado != null ? "Detalles del Familiar" : "Vincular Familiar", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      const SizedBox(width: 48),
                    ],
                  ),
                  if (usuarioEncontrado != null) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Verifica los datos antes de enviar la solicitud.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
                    ),
                  const SizedBox(height: 24),

                  // ==============================
                  // ZONA 1: BÚSQUEDA
                  // ==============================
                  if (usuarioEncontrado == null && !showExternalForm) ...[
                    Text("Método de Búsqueda", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: ["ALIAS", "WALLET", "CEDULA"].map((t) {
                          bool isSel = type == t;
                          String label = t == "ALIAS" ? "Alias" : t == "WALLET" ? "Billetera" : "Cédula";
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => type = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: isSel ? const Color(0xFF4361EE) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                                child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSel ? Colors.white : onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Identificador del Familiar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.1))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: identifierController,
                              decoration: InputDecoration(hintText: "Ingresa el alias ej: @juanperez", hintStyle: TextStyle(color: onSurface.withOpacity(0.4)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                            ),
                          ),
                          GestureDetector(
                            onTap: isSearching ? null : buscarPerfil,
                            child: Container(
                              height: 48, width: 48,
                              decoration: BoxDecoration(color: const Color(0xFF4361EE), borderRadius: BorderRadius.circular(12)),
                              child: isSearching ? const Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],

                  // ==============================
                  // ZONA 2: PERFIL ENCONTRADO
                  // ==============================
                  if (usuarioEncontrado != null) ...[
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          SmartAvatar(address: usuarioEncontrado!['wallet'] ?? '', size: 100),
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF7209B7), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 3)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("@${usuarioEncontrado!['alias'] ?? 'Desconocido'}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text("${usuarioEncontrado!['wallet'].toString().substring(0,6)}...${usuarioEncontrado!['wallet'].toString().substring(usuarioEncontrado!['wallet'].toString().length-4)}".toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontFamily: 'monospace')),
                            const SizedBox(width: 8),
                            Icon(Icons.copy_rounded, size: 14, color: onSurface.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                   FutureBuilder<Map<String, dynamic>?>(
                      future: Provider.of<UserService>(ctx, listen: false).getUserByWallet(usuarioEncontrado!['wallet']),
                      builder: (context, snapshot) {
                        String cedula = "No registrada";
                        String phone = "No registrado";
                        String email = "No registrado";

                        if (snapshot.hasData && snapshot.data != null) {
                          cedula = snapshot.data!['cedula'] ?? cedula;
                          phone = snapshot.data!['phoneNumber'] ?? phone;
                          email = snapshot.data!['email'] ?? email;
                        }

                        return Column(
                          children: [
                            _buildInfoCard(Icons.badge_outlined, "Cédula de Identidad", cedula, theme, onSurface),
                            _buildInfoCard(Icons.phone_android_rounded, "Número Celular", phone, theme, onSurface),
                            _buildInfoCard(Icons.email_outlined, "Correo Electrónico", email, theme, onSurface),
                          ],
                        );
                      }
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                        onPressed: isInviting ? null : procesarInvitacion,
                        icon: isInviting ? const SizedBox() : const Icon(Icons.person_add_alt_1_rounded),
                        label: isInviting ? const CircularProgressIndicator(color: Colors.white) : const Text("Enviar Solicitud Familiar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: onSurface, side: BorderSide(color: onSurface.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                        onPressed: () => setModalState(() => usuarioEncontrado = null),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text("Buscar otra persona", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],

                  if (showExternalForm) ...[
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Text("El usuario no existe. Rellena estos datos para crear una invitación en espera. Cuando se registre, se vinculará automáticamente.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13))),
                    const SizedBox(height: 16),
                    TextField(controller: emailController, decoration: InputDecoration(labelText: "Correo Electrónico (Opcional)", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, decoration: InputDecoration(labelText: "Celular (Opcional)", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))), onPressed: isInviting ? null : procesarInvitacion, icon: isInviting ? const SizedBox() : const Icon(Icons.wechat_rounded), label: isInviting ? const CircularProgressIndicator(color: Colors.white) : const Text("Invitar por WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoCard(IconData icon, String title, String value, ThemeData theme, Color onSurface) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
      child: Row(
        children: [
          Icon(icon, color: onSurface.withOpacity(0.5), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}