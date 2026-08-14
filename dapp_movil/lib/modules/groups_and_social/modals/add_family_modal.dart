import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/family_service.dart';

class AddFamilyModal {
  // static void show(BuildContext context, {required VoidCallback onSuccess}) {
  //   final identifierController = TextEditingController();
  //   final emailController = TextEditingController();
  //   final phoneController = TextEditingController();
    
  //   String type = "CEDULA";
  //   bool isSearching = false;
  //   bool isInviting = false;
    
  //   // Estados dinámicos
  //   Map<String, dynamic>? usuarioEncontrado;
  //   bool showExternalForm = false; // Se activa si la búsqueda falla

  // showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (contextDialog, setModalState) {
  //         final theme = Theme.of(contextDialog);
  //         final colorScheme = theme.colorScheme;
  //         final onSurface = colorScheme.onSurface;

  //         // 🔥 PASO 1: Búsqueda Inteligente (Alias/Cédula vs Wallet)
  //         Future<void> buscarPerfil() async {
  //           if (identifierController.text.trim().isEmpty) return;
            
  //           setModalState(() {
  //             isSearching = true;
  //             showExternalForm = false;
  //             usuarioEncontrado = null;
  //           });

  //           Map<String, dynamic>? resultado;
  //           String query = identifierController.text.trim();

  //           try {
  //             if (type == "WALLET") {
  //               // 🔥 SOLUCIÓN: Usamos tu UserService directo si es búsqueda por billetera
  //               final userService = Provider.of<UserService>(context, listen: false);
  //               resultado = await userService.getUserByWallet(query);
  //             } else {
  //               // Si es Alias o Cédula, usamos la lógica anterior
  //               final familyService = Provider.of<FamilyService>(context, listen: false);
  //               resultado = await familyService.buscarUsuarioParaFamilia(query, type);
  //             }
  //           } catch (e) {
  //             print("Error en búsqueda familiar: $e");
  //           }

  //           setModalState(() {
  //             isSearching = false;
  //             if (resultado != null && (resultado['walletAddress'] != null || resultado['alias'] != null)) {
  //               usuarioEncontrado = resultado;
  //             } else {
  //               showExternalForm = true; 
  //               UIHelper.showCustomSnackbar("Usuario no encontrado en la red.", isError: true);
  //             }
  //           });
  //         }

  //         // 🔥 PASO 2: Confirmar Vinculación
  //         Future<void> procesarInvitacion() async {
  //           setModalState(() => isInviting = true);
  //           final familyService = Provider.of<FamilyService>(context, listen: false);
            
  //           final res = await familyService.inviteFamilyMember(
  //             identifierController.text.trim(), type,
  //             email: showExternalForm ? emailController.text.trim() : null,
  //             phone: showExternalForm ? phoneController.text.trim() : null,
  //           );

  //           setModalState(() => isInviting = false);

  //           if (res['status'] == 'PENDING') {
  //             Navigator.pop(ctx);
  //             UIHelper.showCustomSnackbar("Solicitud familiar enviada.");
  //             onSuccess();
  //           } else if (res['status'] == 'PENDING_NON_EXISTENT') {
  //             Navigator.pop(ctx);
  //             UIHelper.showCustomSnackbar("Invitación externa registrada.");
  //             onSuccess();
              
  //             String msj = "¡Hola! Te he invitado a formar parte de mi círculo familiar seguro en nuestra billetera criptográfica. Descarga la aplicación e ingresa con tu cédula para aceptar la vinculación: https://play.google.com/store/apps/details?id=com.tuapp.dapp_movil";
  //             final Uri waUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msj)}");
  //             launchUrl(waUrl, mode: LaunchMode.externalApplication);
  //           } else {
  //             UIHelper.showCustomSnackbar(res['message'] ?? "Error", isError: true);
  //           }
  //         }

  //         return Container(
  //           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
  //           decoration: BoxDecoration(
  //             color: theme.scaffoldBackgroundColor,
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
  //               const Text("Vincular Familiar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
  //               const SizedBox(height: 20),

  //               // ==============================
  //               // ZONA 1: BÚSQUEDA
  //               // ==============================
  //               if (usuarioEncontrado == null && !showExternalForm) ...[
  //                 DropdownButtonFormField<String>(
  //                   value: type,
  //                   decoration: InputDecoration(filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //                   items: const [
  //                     DropdownMenuItem(value: "CEDULA", child: Text("Por Cédula de Identidad")),
  //                     DropdownMenuItem(value: "ALIAS", child: Text("Por @Alias")),
  //                     DropdownMenuItem(value: "WALLET", child: Text("Por Billetera (0x)")),
  //                   ],
  //                   onChanged: (v) => setModalState(() => type = v!),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: TextField(
  //                         controller: identifierController,
  //                         decoration: InputDecoration(labelText: "Identificador", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     InkWell(
  //                       onTap: isSearching ? null : buscarPerfil,
  //                       borderRadius: BorderRadius.circular(16),
  //                       child: Container(
  //                         height: 56, width: 56,
  //                         decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //                         child: isSearching 
  //                             ? Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
  //                             : Icon(Icons.search_rounded, color: colorScheme.primary),
  //                       ),
  //                     )
  //                   ],
  //                 ),
  //               ],

  //               // ==============================
  //               // ZONA 2: PERFIL ENCONTRADO
  //               // ==============================
  //               if (usuarioEncontrado != null) ...[
  //                 Container(
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
  //                   child: Column(
  //                     children: [
  //                       SmartAvatar(address: usuarioEncontrado!['walletAddress'] ?? '', size: 80),
  //                       const SizedBox(height: 12),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Text("@${usuarioEncontrado!['alias'] ?? 'Desconocido'}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  //                           const SizedBox(width: 6),
  //                           const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Text(usuarioEncontrado!['walletAddress'] ?? '', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: onSurface.withOpacity(0.6))),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                   onPressed: isInviting ? null : procesarInvitacion,
  //                   icon: isInviting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.family_restroom_rounded),
  //                   label: const Text("Enviar Solicitud Familiar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                 ),
  //                 TextButton(
  //                   onPressed: () => setModalState(() => usuarioEncontrado = null),
  //                   child: const Text("Buscar otra persona", style: TextStyle(color: Colors.grey)),
  //                 )
  //               ],

  //               // ==============================
  //               // ZONA 3: USUARIO INEXISTENTE (FORMULARIO)
  //               // ==============================
  //               if (showExternalForm) ...[
  //                 Container(
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //                   child: const Text("El usuario no existe. Rellena estos datos para crear una invitación en espera. Cuando se registre, se vinculará automáticamente.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 TextField(controller: emailController, decoration: InputDecoration(labelText: "Correo Electrónico (Opcional)", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
  //                 const SizedBox(height: 12),
  //                 TextField(controller: phoneController, decoration: InputDecoration(labelText: "Celular (Opcional)", filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
  //                 const SizedBox(height: 24),
  //                 ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                   onPressed: isInviting ? null : procesarInvitacion,
  //                   icon: isInviting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.wechat_rounded),
  //                   label: const Text("Invitar por WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                 ),
  //                 TextButton(
  //                   onPressed: () => setModalState(() => showExternalForm = false),
  //                   child: const Text("Intentar buscar de nuevo", style: TextStyle(color: Colors.grey)),
  //                 )
  //               ],
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

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

          Future<void> buscarPerfil() async {
            if (identifierController.text.trim().isEmpty) return;
            setModalState(() { isSearching = true; showExternalForm = false; usuarioEncontrado = null; });
            Map<String, dynamic>? resultado;
            String query = identifierController.text.trim();
            try {
              if (type == "WALLET") {
                final userService = Provider.of<UserService>(context, listen: false);
                resultado = await userService.getUserByWallet(query);
              } else {
                final familyService = Provider.of<FamilyService>(context, listen: false);
                resultado = await familyService.buscarUsuarioParaFamilia(query, type);
              }
            } catch (e) {}

            setModalState(() {
              isSearching = false;
              if (resultado != null && (resultado['walletAddress'] != null || resultado['alias'] != null)) {
                usuarioEncontrado = resultado;
              } else {
                showExternalForm = true; 
                UIHelper.showCustomSnackbar("Usuario no encontrado.", isError: true);
              }
            });
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
                          SmartAvatar(address: usuarioEncontrado!['walletAddress'] ?? '', size: 100),
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
                            Text("${usuarioEncontrado!['walletAddress'].toString().substring(0,6)}...${usuarioEncontrado!['walletAddress'].toString().substring(usuarioEncontrado!['walletAddress'].toString().length-4)}".toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontFamily: 'monospace')),
                            const SizedBox(width: 8),
                            Icon(Icons.copy_rounded, size: 14, color: onSurface.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                   FutureBuilder<Map<String, dynamic>?>(
                      future: Provider.of<UserService>(ctx, listen: false).getUserByWallet(usuarioEncontrado!['walletAddress']),
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