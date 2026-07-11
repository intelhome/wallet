import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/receipt_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../wallet_and_tx/screens/qr_scanner_screen.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../services/burner_service.dart';

// class SendBurnerModal {
//   static void show({
//     required BuildContext context,
//     required String burnerAddress,
//     required String balanceTTC,
//     required VoidCallback onUpdateBalance,
//   }) {
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
//     final burnerService = Provider.of<BurnerService>(context, listen: false);
//     BuildContext rootContext = context;

//     final TextEditingController addressController = TextEditingController();
//     final TextEditingController montoController = TextEditingController();
//     final TextEditingController reasonController = TextEditingController();
    
//     String direccionDestino = "";
//     double montoIngresado = 0;
//     bool isProcessing = false;

//     showModalBottomSheet(
//       context: rootContext,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,
//       builder: (ctx) {
//         final theme = Theme.of(ctx);
//         final colorScheme = theme.colorScheme;
        
//         // 🔥 COLORES CORPORATIVOS PARA LA BURNER WALLET (Naranja/Ámbar)
//         final Color burnerColor = Colors.deepOrange;

//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateModal) {
//             return Container(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(ctx).viewInsets.bottom,
//                 left: 24, right: 24, top: 24
//               ),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//                 border: Border.all(color: burnerColor.withOpacity(0.5), width: 2), // Contorno diferente
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.local_fire_department_rounded, color: burnerColor),
//                             const SizedBox(width: 8),
//                             const Text("Pago Corporativo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.6)),
//                           onPressed: () => Navigator.pop(ctx)
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),

//                     // INDICADOR DE SALDO DISPONIBLE
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: burnerColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Column(
//                         children: [
//                           Text("Presupuesto Disponible", style: TextStyle(color: burnerColor, fontWeight: FontWeight.bold)),
//                           const SizedBox(height: 4),
//                           Text("$balanceTTC TTC", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: burnerColor)),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     TextField(
//                       controller: addressController,
//                       onChanged: (val) => setStateModal(() => direccionDestino = val.trim()),
//                       decoration: InputDecoration(
//                         labelText: "Destino (Billetera 0x...)",
//                         prefixIcon: const Icon(Icons.account_balance_wallet),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
//                           onPressed: () async {
//                             final scannedAddress = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
//                             if (scannedAddress != null) {
//                               setStateModal(() {
//                                 addressController.text = scannedAddress.trim();
//                                 direccionDestino = scannedAddress.trim();
//                               });
//                             }
//                           },
//                         ),
//                         filled: true,
//                         fillColor: colorScheme.onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     TextField(
//                       controller: montoController,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       onChanged: (val) => setStateModal(() => montoIngresado = double.tryParse(val) ?? 0),
//                       decoration: InputDecoration(
//                         labelText: "Monto a pagar",
//                         prefixIcon: const Icon(Icons.attach_money),
//                         filled: true,
//                         fillColor: colorScheme.onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
//                     const SizedBox(height: 30),

//                     TextField(
//                       controller: reasonController,
//                       style: TextStyle(color: colorScheme.onSurface),
//                       decoration: InputDecoration(
//                         labelText: "Motivo del pago (Obligatorio)",
//                         prefixIcon: const Icon(Icons.notes_rounded),
//                         filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 30),

//                     // 🔥 BOTÓN PRINCIPAL DE ENVÍO BURNER 🔥
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: burnerColor,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         ),
//                         onPressed: (isProcessing || direccionDestino.isEmpty || montoIngresado <= 0) ? null : () async {
                          
//                           double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
//                           if (montoIngresado > saldoActual) {
//                             UIHelper.showCustomSnackbar("La tarjeta corporativa no tiene saldo suficiente. Saldo: $saldoActual TTC", isError: true);
//                             return;
//                           }

//                           FocusScope.of(context).unfocus();
                          
//                           showDialog(
//                             context: rootContext, 
//                             barrierDismissible: false, 
//                             builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar el gasto corporativo.")
//                           );
                          
//                          bool isAuth = await authCore.authenticateUser();
                          
//                           if (!isAuth) {
//                             Navigator.pop(rootContext); // Cerramos el Skeleton de huella
//                             UIHelper.showCustomSnackbar("Autenticación cancelada.", isError: true);
//                             return; 
//                           }
                          
//                           Navigator.pop(rootContext); // Quitar Skeleton de Huella
//                           // 🔥 OJO: Aquí NO debe haber ningún Navigator.pop(ctx) antes del try.

//                          try {
//                             Navigator.pop(ctx); // 1. Cerramos el modal inferior al instante

//                             // 2. Abrimos la pantalla de carga normal a pantalla completa
//                             Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
//                                 customTitle: "Pago Corporativo", 
//                                 customMessage: "Procesando gasto con tarjeta virtual...", 
//                                 recipientAddress: direccionDestino, 
//                                 isGroupPayment: false, 
//                                 expectedTxType: 'SEND', 
//                                 onUpdateBalance: () {} // Aquí no hace refresh, lo forzaremos manualmente abajo
//                             )));

//                             // 3. Ejecutamos la petición en el backend
//                             final res = await burnerService.sendFromBurnerWallet(burnerAddress, direccionDestino, montoIngresado, reasonController.text.trim());
                                
//                             // 4. Forzamos el cierre de la pantalla de carga apenas el backend responda
//                             if (rootContext.mounted) Navigator.pop(rootContext);

//                             if (res.startsWith("Error")) { 
//                               UIHelper.showCustomSnackbar(res, isError: true); 
//                               return;
//                             } 
                            
//                             // 5. Si fue éxito, recargamos e informamos
//                             String txHash = res.replaceAll("Exito:", "").trim();
//                             onUpdateBalance(); 
//                             UIHelper.showCustomSnackbar("Gasto corporativo realizado con éxito");

//                             // 6. Preguntamos educadamente si desea ver el comprobante
//                             if (rootContext.mounted) {
//                               bool? verComprobante = await UIHelper.mostrarConfirmacion(
//                                 context: rootContext,
//                                 titulo: "Transacción Exitosa",
//                                 mensaje: "¿Deseas ver el comprobante de pago ahora para compartirlo al comercio?",
//                                 textoConfirmar: "Ver Comprobante",
//                                 colorConfirmar: Colors.green,
//                               );

//                               if (verComprobante == true) {
//                                 dynamic mockTx = {
//                                   'txType': 'SEND',
//                                   'amount': montoIngresado,
//                                   'txHash': txHash,
//                                   'senderAddress': burnerAddress,
//                                   'receiverAddress': direccionDestino,
//                                   'status': 'COMPLETED',
//                                   'timestamp': DateTime.now().toIso8601String()
//                                 };
//                                 Navigator.push(rootContext, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
//                               }
//                             }

//                           } catch (e) {
//                             if (rootContext.mounted) Navigator.pop(rootContext); // Seguro anti-atascos
//                             UIHelper.showCustomSnackbar("Error inesperado en el pago corporativo", isError: true);
//                           } finally {
//                             if (ctx.mounted) setStateModal(() => isProcessing = false);
//                           }
//                         },
//                         child: isProcessing 
//                           ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                           : const Text("Autorizar Pago Corporativo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       }
//     );
//   }
// }

class SendBurnerModal extends StatefulWidget {
  final String burnerAddress;
  final String balanceTTC;
  final VoidCallback onUpdateBalance;

  const SendBurnerModal({
    super.key,
    required this.burnerAddress,
    required this.balanceTTC,
    required this.onUpdateBalance,
  });

  static void show({required BuildContext context, required String burnerAddress, required String balanceTTC, required VoidCallback onUpdateBalance}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => SendBurnerModal(burnerAddress: burnerAddress, balanceTTC: balanceTTC, onUpdateBalance: onUpdateBalance),
    );
  }

  @override
  State<SendBurnerModal> createState() => _SendBurnerModalState();
}

class _SendBurnerModalState extends State<SendBurnerModal> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isSearching = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _foundUser;
  String _destinationWallet = ""; 

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _buscarUsuario() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (query.startsWith("@")) {
      final result = await userService.searchByAlias(query.substring(1));
      if (result != null) {
        setState(() {
          _foundUser = result;
          _destinationWallet = result['walletAddress'] ?? result['contactAddress'] ?? result['wallet'] ?? "";
        });
        _nextPage();
      } else {
        UIHelper.showCustomSnackbar("Usuario no encontrado.", isError: true);
      }
    } else if (query.startsWith("0x") && query.length == 42) {
      final result = await userService.getUserByWallet(query);
      setState(() {
        if (result != null && result['alias'] != null) {
          _foundUser = result;
          _foundUser!['walletAddress'] = query;
        } else {
          _foundUser = {"alias": "Billetera Externa", "walletAddress": query, "isExternal": true};
        }
        _destinationWallet = query;
      });
      _nextPage();
    } else {
      UIHelper.showCustomSnackbar("Formato incorrecto. Usa @alias o wallet.", isError: true);
    }
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1Search(theme),
          _buildStep2Pay(theme),
        ],
      ),
    );
  }

  Widget _buildStep1Search(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pago Desechable", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),
          Icon(Icons.person_search_rounded, size: 80, color: Colors.deepOrange.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text("¿A quién quieres enviar?", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Busca al destinatario para realizar tu pago anónimo.", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 40),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Ingresa el @alias o wallet 0x...",
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.deepOrange),
                onPressed: () async {
                  final scanned = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                  if (scanned != null) {
                    _searchController.text = scanned.trim();
                    _buscarUsuario();
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _buscarUsuario(),
          ),
          
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: _isSearching ? null : _buscarUsuario,
            child: _isSearching 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Buscar Usuario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Pay(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final String alias = _foundUser?['alias'] ?? "Desconocido";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
              Text("Enviar a @$alias", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          Center(child: SmartAvatar(address: _destinationWallet, size: 70)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card_rounded, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 8),
                Text("Saldo de Tarjeta: ${widget.balanceTTC} TTC", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: "TTC ",
              filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: "Motivo del pago",
              prefixIcon: const Icon(Icons.notes_rounded),
              filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),

          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isProcessing ? null : _ejecutarPago,
            child: _isProcessing 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Autorizar Pago Anónimo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarPago() async {
    double monto = double.tryParse(_montoController.text) ?? 0;
    if (monto <= 0) return;

    double saldoActual = double.tryParse(widget.balanceTTC) ?? 0.0;
    if (monto > saldoActual) {
      UIHelper.showCustomSnackbar("La tarjeta virtual no tiene saldo suficiente.", isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final burnerService = Provider.of<BurnerService>(context, listen: false);

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza el gasto de la tarjeta virtual."));
    bool isAuth = await authCore.authenticateUser();
    if (!mounted) return;
    Navigator.pop(context);

    if (!isAuth) return;

    setState(() => _isProcessing = true);
    
  try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando", message: "Enviando transacción anónima a la red..."));
      
      print("🚀 [UI-SEND-BURNER] Enviando orden de pago por $monto TTC desde ${widget.burnerAddress} a $_destinationWallet...");
      final res = await burnerService.sendFromBurnerWallet(widget.burnerAddress, _destinationWallet, monto, _reasonController.text.trim());
      
      if (!mounted) return;
      Navigator.pop(context); // Cierra Skeleton de Carga

      if (!res.startsWith("Error")) {
        print("✅ [UI-SEND-BURNER] Pago completado. Hash devuelto: $res");
        String txHash = res.replaceAll("Exito:", "").trim();
        widget.onUpdateBalance(); 
        
        Navigator.pop(context); // Cierra el Modal por completo
        
        bool? verComprobante = await UIHelper.mostrarConfirmacion(
          context: context, titulo: "Pago Exitoso",
          mensaje: "¿Deseas ver el comprobante de pago?", textoConfirmar: "Ver Comprobante", colorConfirmar: Colors.green,
        );

        if (verComprobante == true) {
          dynamic mockTx = {
            'txType': 'SEND', 'amount': monto, 'txHash': txHash,
            'senderAddress': widget.burnerAddress, 'receiverAddress': _destinationWallet,
            'status': 'COMPLETED', 'timestamp': DateTime.now().toIso8601String()
          };
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
        } else {
           UIHelper.showCustomSnackbar("Gasto anónimo realizado con éxito.");
        }
      } else {
        print("❌ [UI-SEND-BURNER] Falló el pago corporativo: $res");
        UIHelper.showCustomSnackbar(res, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}