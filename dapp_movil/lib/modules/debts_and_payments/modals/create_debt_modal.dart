import 'dart:convert';

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/qr_scanner_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CreateDebtModal {

  static void show({
    required BuildContext context,
    required VoidCallback onSuccess,
    required void Function(String, {bool esError}) mostrarMensaje,
    String? initialAlias,
    String? initialAmount,
    String? initialWallet,
    String? initialReason,
  }) {
    final debtService = Provider.of<DebtService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    final TextEditingController aliasController = TextEditingController(text: initialAlias?.replaceAll('@', '') ?? '');
    final TextEditingController addressController = TextEditingController(text: initialWallet ?? '');
    final TextEditingController amountController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController reasonController = TextEditingController(text: initialReason ?? '');

    bool isProcessing = false;
    bool isSearchingAlias = false;
    
    //  Variable para guardar los datos del usuario encontrado y mostrar la tarjeta
    Map<String, dynamic>? foundUserData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (contextModal, setState) {
            final theme = Theme.of(ctx);
            final onSurface = theme.colorScheme.onSurface;
            final cardColor = theme.cardColor;

            // Helper para los labels
            Widget buildLabel(String text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(text, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
              );
            }

            return Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Cobrar a un usuario", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                        IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.8)), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 1. BUSCADOR DE ALIAS
                    buildLabel("Alias del usuario"),
                    TextField(
                      controller: aliasController,
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Buscar por alias",
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          child: Text("@", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        suffixIcon: IconButton(
                          icon: isSearchingAlias 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search_rounded, color: Color(0xFFBAC3FF)),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            if (aliasController.text.isEmpty) return;
                            setState(() => isSearchingAlias = true);
                            
                            try {
                              String query = aliasController.text.trim().replaceAll("@", "");
                              String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", query);
                              
                              final res = await http.get(Uri.parse(endpoint), headers: {
                                "Content-Type": "application/json",
                                if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
                              });

                              if (res.statusCode == 200) {
                                var data = jsonDecode(res.body);
                                Map<String, dynamic>? userObj;
                                
                                if (data is List && data.isNotEmpty) userObj = data.first;
                                else if (data is Map) userObj = data as Map<String, dynamic>;

                                if (userObj != null && userObj['walletAddress'] != null) {
                                  setState(() {
                                    addressController.text = userObj!['walletAddress'];
                                    foundUserData = userObj;
                                  });
                                  mostrarMensaje("Usuario encontrado", esError: false);
                                } else {
                                  setState(() => foundUserData = null);
                                  mostrarMensaje("Usuario no encontrado", esError: true);
                                }
                              } else {
                                setState(() => foundUserData = null);
                                mostrarMensaje("Usuario no encontrado", esError: true);
                              }
                            } catch (e) {
                              setState(() => foundUserData = null);
                              mostrarMensaje("Error de red", esError: true);
                            }
                            setState(() => isSearchingAlias = false);
                          },
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. BILLETERA
                    buildLabel("Billetera del Deudor"),
                    TextField(
                      controller: addressController,
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "0x...",
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: onSurface.withOpacity(0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.qr_code_scanner_rounded, color: onSurface.withOpacity(0.5)),
                          onPressed: () async {
                            final scannedAddress = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                            if (scannedAddress != null) setState(() => addressController.text = scannedAddress.trim());
                          },
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔥 TARJETA DINÁMICA (Aparece si se encontró el usuario)
                    if (foundUserData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: onSurface.withOpacity(0.1))
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: const BoxDecoration(color: Color(0xFFE0B0FF), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("@${foundUserData!['alias'] ?? 'usuario'}", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text("ID: ${foundUserData!['cedula'] ?? foundUserData!['identifier'] ?? 'N/A'}", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "${foundUserData!['walletAddress'].toString().substring(0, 6)}...${foundUserData!['walletAddress'].toString().substring(foundUserData!['walletAddress'].toString().length - 4)}", 
                                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontFamily: 'monospace')
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.copy_rounded, size: 14, color: onSurface.withOpacity(0.5))
                                    ],
                                  )
                                ],
                              ),
                            )
                          ]
                        )
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // 3. MONTO
                    buildLabel("Monto a cobrar"),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "0.00",
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.payments_outlined, color: onSurface.withOpacity(0.5)),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 16, top: 14),
                          child: Text("TTC", style: TextStyle(color: const Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 4. MOTIVO
                    buildLabel("Motivo (Opcional)"),
                    TextField(
                      controller: reasonController,
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Ej: Cena de ayer",
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                        prefixIcon: Icon(Icons.description_outlined, color: onSurface.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 5. BOTÓN PRINCIPAL
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC3FF),
                          foregroundColor: const Color(0xFF00218d),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        onPressed: isProcessing ? null : () async {
                          if (addressController.text.isEmpty || amountController.text.isEmpty) {
                            mostrarMensaje("Llena todos los campos obligatorios", esError: true);
                            return;
                          }

                          showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza la creación de este cobro."));
                          bool auth = await authCore.authenticateUser();
                          if (context.mounted) Navigator.pop(context);

                          if (!auth) return;
                          
                          Navigator.pop(ctx); 

                          Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                            customTitle: "Generando Cobro", 
                            customMessage: "Notificando al deudor...",
                            recipientAddress: addressController.text,
                            expectedTxType: "DEBT_CREATION", 
                            onUpdateBalance: onSuccess 
                          )));

                          String res = await debtService.createDebtRequest(addressController.text, double.parse(amountController.text), reasonController.text);
                          
                          if (context.mounted) Navigator.pop(context);
                          
                          if (res == "Exito") {
                             mostrarMensaje("Solicitud de cobro enviada", esError: false);
                             onSuccess(); 
                          } else {
                            mostrarMensaje(res, esError: true);
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text("Enviar Solicitud de Cobro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

//   static void show({
//     required BuildContext context,
//     //required BlockchainService service,
//     required VoidCallback onSuccess,
//     required void Function(String, {bool esError}) mostrarMensaje,
//     String? initialAlias,
//     String? initialAmount,
//     String? initialWallet,
//     String? initialReason,
//   }) {

//     final debtService = Provider.of<DebtService>(context, listen: false);
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final userService = Provider.of<UserService>(context, listen: false); // Para buscar alias

//    final TextEditingController aliasController = TextEditingController(text: initialAlias?.replaceAll('@', '') ?? '');
//     final TextEditingController addressController = TextEditingController(text: initialWallet ?? '');
//     final TextEditingController amountController = TextEditingController(text: initialAmount ?? '');
//     final TextEditingController reasonController = TextEditingController(text: initialReason ?? '');

//     double montoIngresado = double.tryParse(initialAmount ?? '0') ?? 0.0;
    
//     bool isProcessing = false;
//     bool isSearchingAlias = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) {
//         final theme = Theme.of(ctx);
//         final onSurface = theme.colorScheme.onSurface;
//         final colorScheme = theme.colorScheme;

//         return StatefulBuilder(
//           builder: (contextModal, setState) {
//             return Container(
//               decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
//               padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Cobrar a un usuario", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface)),
//                         IconButton(icon: Icon(Icons.close, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // 🔥 1. BUSCADOR DE ALIAS
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: aliasController,
//                             decoration: InputDecoration(
//                               labelText: "Buscar por @alias",
//                               prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.blueAccent),
//                               filled: true,
//                               fillColor: onSurface.withOpacity(0.05),
//                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Container(
//                           decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
//                           child: IconButton(
//                             icon: isSearchingAlias 
//                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//                               : const Icon(Icons.search_rounded, color: Colors.blueAccent),
//                             onPressed: () async {
//                               HapticFeedback.mediumImpact();
//                               if (aliasController.text.isEmpty) return;
//                               setState(() => isSearchingAlias = true);
                              
//                               try {
//                                 String query = aliasController.text.trim().replaceAll("@", "");
//                                 String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", query);
                                
//                                 final res = await http.get(Uri.parse(endpoint), headers: {
//                                   "Content-Type": "application/json",
//                                   if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//                                 });

//                                 if (res.statusCode == 200) {
//                                   var data = jsonDecode(res.body);
//                                   String wallet = "";
//                                   if (data is List && data.isNotEmpty) wallet = data.first['walletAddress'] ?? "";
//                                   else if (data is Map) wallet = data['walletAddress'] ?? "";

//                                   if (wallet.isNotEmpty) {
//                                     setState(() => addressController.text = wallet);
//                                     mostrarMensaje("Usuario encontrado", esError: false);
//                                   } else {
//                                     mostrarMensaje("Usuario no encontrado", esError: true);
//                                   }
//                                 } else {
//                                   mostrarMensaje("Usuario no encontrado", esError: true);
//                                 }
//                               } catch (e) {
//                                 mostrarMensaje("Error de red", esError: true);
//                               }
//                               setState(() => isSearchingAlias = false);
//                             },
//                           ),
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // 🔥 2. CAMPO DE BILLETERA CON QR
//                     TextField(
//                       controller: addressController,
//                       decoration: InputDecoration(
//                         labelText: "Billetera del Deudor",
//                         prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.deepPurpleAccent),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.deepPurpleAccent),
//                           onPressed: () async {
//                             final scannedAddress = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
//                             if (scannedAddress != null) setState(() => addressController.text = scannedAddress.trim());
//                           },
//                         ),
//                         filled: true,
//                         fillColor: onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     TextField(
//                       controller: amountController,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       decoration: InputDecoration(
//                         labelText: "Monto a cobrar (TTC)",
//                         prefixIcon: const Icon(Icons.monetization_on_rounded, color: Colors.green),
//                         filled: true,
//                         fillColor: onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
                    
//                     TextField(
//                       controller: reasonController,
//                       decoration: InputDecoration(
//                         labelText: "Motivo del cobro (Ej: Cena de ayer)",
//                         prefixIcon: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
//                         filled: true,
//                         fillColor: onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
//                     const SizedBox(height: 32),
                    
//                     // 🔥 3. BOTÓN CON SKELETON Y PENDING SCREEN
//                     SizedBox(
//                       height: 56,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: colorScheme.primary,
//                           foregroundColor: colorScheme.onPrimary,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         ),
//                         onPressed: isProcessing ? null : () async {
//                           if (addressController.text.isEmpty || amountController.text.isEmpty || reasonController.text.isEmpty) {
//                             mostrarMensaje("Llena todos los campos", esError: true);
//                             return;
//                           }

//                           // Skeleton + Huella
//                           showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza la creación de este cobro."));
//                           bool auth = await authCore.authenticateUser();
//                           if (context.mounted) Navigator.pop(context); // Quita skeleton

//                           if (!auth) return;
                          
//                           //setState(() => isProcessing = true);
//                           Navigator.pop(ctx); // Cierra el modal de cobro

//                           // Abrimos el Pending Screen para darle contexto al usuario
//                           Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                             customTitle: "Generando Cobro", 
//                             customMessage: "Notificando al deudor...",
//                             recipientAddress: addressController.text,
//                             expectedTxType: "DEBT_CREATION", // Un tipo ficticio para que no espere a Web3
//                             onUpdateBalance: onSuccess 
//                           )));

//                           String res = await debtService.createDebtRequest(addressController.text, double.parse(amountController.text), reasonController.text);
                          
//                           if (context.mounted) Navigator.pop(context);
                          
//                           if (res == "Exito") {
//                              mostrarMensaje("Solicitud de cobro enviada", esError: false);
//                              onSuccess(); // Recarga la lista
//                           } else {
//                             mostrarMensaje(res, esError: true);
//                           }
//                         },
//                         child: const Text("Enviar Solicitud de Cobro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }
//         );
//       }
//     );
//   }
}