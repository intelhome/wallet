import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../screens/paypal_payment_screen.dart';

class SendPaypalModal {
  static void show({
    required BuildContext context,
    required VoidCallback onSuccess,
    String? initialAlias,
    String? initialAmount,
  }) {
    final userService = Provider.of<UserService>(context, listen: false);

  final TextEditingController identifierController = TextEditingController(text: initialAlias ?? '');
    final TextEditingController amountController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController reasonController = TextEditingController();

    Map<String, dynamic>? usuarioEncontrado;
    bool buscando = false;
    String errorMsg = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext contextDialog, StateSetter setModalState) {
          final theme = Theme.of(contextDialog);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          // Función interna para buscar el destinatario en el backend y verificar si tiene PayPal activo
          Future<void> buscarDestinatario() async {
            String query = identifierController.text.trim();
            if (query.isEmpty) return;

            setModalState(() {
              buscando = true;
              errorMsg = "";
              usuarioEncontrado = null;
            });
            HapticFeedback.lightImpact();

            final check = await userService.checkPayeePayPal(query);

            setModalState(() {
              buscando = false;
              if (check == null) {
                errorMsg = "Error de conexión con el servidor.";
              } else if (check.containsKey('error')) {
                errorMsg = check['error']; // 🔥 Muestra: "El usuario destinatario no existe en la red."
              } else if (check['paypalEnabled'] == false) {
                errorMsg = check['message'] ?? "El usuario no acepta pagos por PayPal.";
              } else {
                usuarioEncontrado = check; 
              }
            });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            // child: SingleChildScrollView(
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     crossAxisAlignment: CrossAxisAlignment.stretch,
            //     children: [
            //       Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  
            //       // Encabezado estético PayPal
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           const Icon(Icons.payment_rounded, color: Colors.blueAccent, size: 28),
            //           const SizedBox(width: 8),
            //           Text("Transferencia PayPal P2P", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            //         ],
            //       ),
            //       const SizedBox(height: 24),

            //       // INPUT DE BÚSQUEDA DEL DESTINATARIO
            //       if (usuarioEncontrado == null) ...[
            //         Row(
            //           children: [
            //             Expanded(
            //               child: TextField(
            //                 controller: identifierController,
            //                 textInputAction: TextInputAction.search,
            //                 onSubmitted: (_) => buscarDestinatario(),
            //                 style: TextStyle(color: onSurface),
            //                 decoration: InputDecoration(
            //                   hintText: "Buscar destinatario (@alias, wallet o cédula)",
            //                   prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.blueAccent),
            //                   filled: true,
            //                   fillColor: onSurface.withOpacity(0.05),
            //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            //                 ),
            //               ),
            //             ),
            //             const SizedBox(width: 12),
            //             InkWell(
            //              onTap: buscando ? null : buscarDestinatario,
            //               borderRadius: BorderRadius.circular(16),
            //               child: Container(
            //                 height: 54, width: 54,
            //                 decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            //                 child: buscando
            //                     ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
            //                     : const Icon(Icons.search_rounded, color: Colors.blueAccent),
            //               ),
            //             )
            //           ],
            //         ),
            //         if (errorMsg.isNotEmpty) ...[
            //           const SizedBox(height: 12),
            //           Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            //         ],
            //       ],

            //       // PERFIL DEL RECEPTOR ENCONTRADO CON CAMPOS DE ENVÍO
            //       if (usuarioEncontrado != null) ...[
            //         Container(
            //           padding: const EdgeInsets.all(16),
            //           decoration: BoxDecoration(
            //             color: Colors.blue.withOpacity(0.05),
            //             borderRadius: BorderRadius.circular(24),
            //             border: Border.all(color: Colors.blue.withOpacity(0.15)),
            //           ),
            //           child: Row(
            //             children: [
            //               SmartAvatar(address: usuarioEncontrado!['walletAddress'] ?? '', size: 48),
            //               const SizedBox(width: 16),
            //               Expanded(
            //                 child: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Text("@${usuarioEncontrado!['alias']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            //                     const SizedBox(height: 2),
            //                     Text("Verificado para recibir USD Fiat", style: TextStyle(color: Colors.blue.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            //                   ],
            //                 ),
            //               ),
            //               IconButton(
            //                 icon: const Icon(Icons.change_circle_rounded, color: Colors.grey),
            //                 onPressed: () => setModalState(() => usuarioEncontrado = null),
            //               )
            //             ],
            //           ),
            //         ),
            //         const SizedBox(height: 20),

            //         // INPUT DEL MONTO FIAT
            //         TextField(
            //           controller: amountController,
            //           keyboardType: const TextInputType.numberWithOptions(decimal: true),
            //           style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
            //           textAlign: TextAlign.center,
            //           decoration: InputDecoration(
            //             hintText: "0.00",
            //             suffixText: "USD",
            //             suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            //             helperText: "Monto Neto a enviar de cuenta a cuenta",
            //             filled: true,
            //             fillColor: onSurface.withOpacity(0.03),
            //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            //           ),
            //         ),
            //         const SizedBox(height: 16),

            //         // INPUT DEL MOTIVO
            //         TextField(
            //           controller: reasonController,
            //           style: TextStyle(color: onSurface),
            //           decoration: InputDecoration(
            //             hintText: "Motivo del pago (Opcional)",
            //             prefixIcon: const Icon(Icons.description_rounded, color: Colors.grey),
            //             filled: true,
            //             fillColor: onSurface.withOpacity(0.05),
            //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            //           ),
            //         ),
            //         const SizedBox(height: 24),

            //         // BOTÓN DE ENVÍO DIRECTO EXCLUSIVO PAYPAL
            //         SizedBox(
            //           height: 56,
            //           child: ElevatedButton.icon(
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: Colors.blueAccent,
            //               foregroundColor: Colors.white,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //               elevation: 0,
            //             ),
            //             icon: const Icon(Icons.open_in_new_rounded),
            //             label: const Text("Abrir Pasarela PayPal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            //             onPressed: () {
            //               double? amount = double.tryParse(amountController.text.trim());
            //               if (amount == null || amount <= 0) {
            //                 UIHelper.showCustomSnackbar("Por favor ingresa un monto válido", isError: true);
            //                 return;
            //               }
                          
            //               Navigator.pop(ctx); // Cierra el modal de PayPal
                          
            //               // Abrimos la pantalla de carga e interacción con PayPal
            //              Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (_) => PaypalPaymentScreen(
            //                     targetIdentifier: identifierController.text.isEmpty ? usuarioEncontrado!['alias'] : identifierController.text.trim(),
            //                     amount: amount,
            //                     reason: reasonController.text.trim(),
            //                     targetWallet: usuarioEncontrado!['walletAddress'],
            //                   ),
            //                 ),
            //               ).then((_) async {
            //                 // 🔥 CÓDIGO PARA ELIMINAR EL CACHÉ
            //                 final cacheService = LocalCacheService();
            //                 // await cacheService.clearDashboardCache();
            //                 // await cacheService.clearTransactionsCache();
                            
            //                 onSuccess(); // Esto llamará a _cargarBalance()
            //               });
            //             },
            //           ),
            //         ),
            //       ],
            //       const SizedBox(height: 30),
            //     ],
            //   ),
            // ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Manija de arrastre (Drag Handle)
                  Center(
                    child: Container(
                      width: 40, height: 4, 
                      margin: const EdgeInsets.only(bottom: 24), 
                      decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))
                    )
                  ),
                  
                  // 2. Encabezado limpio
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: onSurface.withOpacity(0.8), size: 24),
                      const SizedBox(width: 12),
                      Text("Transferencia PayPal P2P", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. ESTADO: BUSCANDO DESTINATARIO
                  if (usuarioEncontrado == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: identifierController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => buscarDestinatario(),
                            style: TextStyle(color: onSurface),
                            decoration: InputDecoration(
                              hintText: "Buscar (@alias o 0x...)",
                              hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                              prefixIcon: Icon(Icons.alternate_email_rounded, color: onSurface.withOpacity(0.6)),
                              filled: true,
                              fillColor: onSurface.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: buscando ? null : buscarDestinatario,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 52, width: 52,
                            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                            child: buscando
                                ? Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                                : Icon(Icons.search_rounded, color: onSurface.withOpacity(0.8)),
                          ),
                        )
                      ],
                    ),
                    if (errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ],
                  ],

                  // 4. ESTADO: USUARIO ENCONTRADO LISTO PARA ENVIAR
                  if (usuarioEncontrado != null) ...[
                    // Tarjeta de Usuario
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurface.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          SmartAvatar(address: usuarioEncontrado!['walletAddress'] ?? '', size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("@${usuarioEncontrado!['alias']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.verified_outlined, color: onSurface.withOpacity(0.6), size: 14),
                                    const SizedBox(width: 4),
                                    Text("Verificado para recibir USD", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: onSurface.withOpacity(0.05), shape: BoxShape.circle),
                              child: Icon(Icons.manage_accounts_outlined, color: onSurface.withOpacity(0.6), size: 20)
                            ),
                            onPressed: () => setModalState(() => usuarioEncontrado = null),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Monto Box (Gigante y estilizado)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurface.withOpacity(0.05)),
                      ),
                      child: Column(
                        children: [
                          Text("MONTO A ENVIAR", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("\$", style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 60, fontWeight: FontWeight.w900, height: 1.1)),
                              Expanded(
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: onSurface, height: 1.1),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: "0.00",
                                    hintStyle: TextStyle(color: onSurface.withOpacity(0.2)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40), // Para balancear visualmente el $ y mantener el centro exacto
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Monto Neto a enviar de cuenta a cuenta", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.start),
                    const SizedBox(height: 24),

                    // Motivo Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurface.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.notes_rounded, color: onSurface.withOpacity(0.6), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("MOTIVO DEL PAGO", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                TextField(
                                  controller: reasonController,
                                  style: TextStyle(color: onSurface, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: "Escribe una nota (Opcional)",
                                    hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón de Envío
                    SizedBox(
                      height: 64,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4361EE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          double? amount = double.tryParse(amountController.text.trim());
                          if (amount == null || amount <= 0) {
                            UIHelper.showCustomSnackbar("Por favor ingresa un monto válido", isError: true);
                            return;
                          }
                          
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaypalPaymentScreen(
                                targetIdentifier: identifierController.text.isEmpty ? usuarioEncontrado!['alias'] : identifierController.text.trim(),
                                amount: amount,
                                reason: reasonController.text.trim(),
                                targetWallet: usuarioEncontrado!['walletAddress'],
                              ),
                            ),
                          ).then((_) async {
                            onSuccess(); 
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.bolt_rounded, size: 20),
                                SizedBox(width: 8),
                                Text("Abrir Pasarela PayPal Pro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("TRANSACCIÓN SEGURA & INSTANTÁNEA", style: TextStyle(fontSize: 9, letterSpacing: 2.0, color: Colors.white70, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}