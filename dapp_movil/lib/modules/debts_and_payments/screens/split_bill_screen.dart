import 'dart:convert';
import 'package:dapp_movil/modules/settings_and_profile/modals/qr_scanner_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../debts_and_payments/services/debt_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/ui_helper.dart';

class SplitBillScreen extends StatefulWidget {
  final VoidCallback onBillSplitSuccess;

  final Function(double totalAmount, String reason, double perPerson)? onBillSplitSuccessDetails;
  
 final String? initialAmount;
  final String? initialReason;
  final List<Map<String, String>>? initialParticipants;
  final String? initialDestination;

  const SplitBillScreen({
    super.key, 
    required this.onBillSplitSuccess,
    this.onBillSplitSuccessDetails,
    this.initialAmount,
    this.initialReason,
    this.initialParticipants,
    this.initialDestination,
  });

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  final TextEditingController _aliasController = TextEditingController();
  
  late final TextEditingController _destinationWalletController;
  bool _isSearchingDestinationAlias = false;
  
  // 🔥 NUEVO: Controller y variables para la Billetera Colectiva/Comercio de Destino
  //final TextEditingController _destinationWalletController = TextEditingController();
  //bool _isSearchingDestinationAlias = false;
  
  late final List<Map<String, String>> _participants;
  bool _isSearchingAlias = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
   _destinationWalletController = TextEditingController(text: widget.initialDestination?.replaceAll('@', '') ?? '');
    _participants = widget.initialParticipants != null ? List.from(widget.initialParticipants!) : [];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _aliasController.dispose();
    _destinationWalletController.dispose();
    super.dispose();
  }

  // NUEVO: Buscar cuenta de destino o comercio por @Alias
  Future<void> _buscarDestinoPorAlias() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    String query = _destinationWalletController.text.trim().replaceAll("@", "").toLowerCase();
    
    if (query.isEmpty) return;
    if (query.startsWith("0x") && query.length == 42) {
      UIHelper.showCustomSnackbar("Dirección de billetera directa detectada.", isError: false);
      return;
    }

    setState(() => _isSearchingDestinationAlias = true);
    HapticFeedback.lightImpact();

    try {
      String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", query);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        String wallet = "";
        
        if (data is List && data.isNotEmpty) {
          wallet = data.first['walletAddress'] ?? "";
        } else if (data is Map) {
          wallet = data['walletAddress'] ?? "";
        }

        if (wallet.isNotEmpty) {
          setState(() {
            _destinationWalletController.text = wallet.toLowerCase();
          });
          UIHelper.showCustomSnackbar("¡Destino/Comercio vinculado con éxito!", isError: false);
        } else {
          UIHelper.showCustomSnackbar("El alias ingresado no está registrado", isError: true);
        }
      } else {
        UIHelper.showCustomSnackbar("Comercio no encontrado", isError: true);
      }
    } catch (e) {
      UIHelper.showCustomSnackbar("Error de red al consultar alias destino", isError: true);
    } finally {
      setState(() => _isSearchingDestinationAlias = false);
    }
  }

  Future<void> _buscarYAgregarParticipante() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    String query = _aliasController.text.trim().replaceAll("@", "").toLowerCase();
    
    if (query.isEmpty) return;

    if (_participants.any((p) => p['alias'] == query)) {
      UIHelper.showCustomSnackbar("El usuario ya está en la lista", isError: true);
      return;
    }

    setState(() => _isSearchingAlias = true);
    HapticFeedback.lightImpact();

    try {
      String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", query);
      final res = await http.get(Uri.parse(endpoint), headers: authCore.authHeaders);

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        String wallet = "";
        
        if (data is List && data.isNotEmpty) {
          wallet = data.first['walletAddress'] ?? "";
        } else if (data is Map) {
          wallet = data['walletAddress'] ?? "";
        }

        if (wallet.isNotEmpty) {
          setState(() {
            _participants.add({
              "alias": query,
              "wallet": wallet.toLowerCase(),
            });
            _aliasController.clear();
          });
          UIHelper.showCustomSnackbar("¡Contacto añadido!", isError: false);
        } else {
          UIHelper.showCustomSnackbar("Usuario no registrado en el sistema", isError: true);
        }
      } else {
        UIHelper.showCustomSnackbar("Usuario no encontrado", isError: true);
      }
    } catch (e) {
      UIHelper.showCustomSnackbar("Error de conexión al buscar alias", isError: true);
    } finally {
      setState(() => _isSearchingAlias = false);
    }
  }

  Future<void> _procesarDivisionDeCuenta() async {
    final debtService = Provider.of<DebtService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false); // 🔥 NUEVO: Para ejecutar el pago L2 del creador

    double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    int totalPeople = _participants.length + 1; // Amigos + Tú
    double perPerson = totalAmount / totalPeople;
    String destinoWallet = _destinationWalletController.text.trim().toLowerCase();

    if (totalAmount <= 0 || _participants.isEmpty) return;
    if (_reasonController.text.trim().isEmpty) {
      UIHelper.showCustomSnackbar("Por favor ingresa el motivo del gasto", isError: true);
      return;
    }
    if (destinoWallet.isEmpty || !destinoWallet.startsWith("0x") || destinoWallet.length != 42) {
      UIHelper.showCustomSnackbar("Por favor, ingresa o escanea una billetera de destino válida (0x...)", isError: true);
      return;
    }

    // 1. Solicitud de Biometría / Huella de Seguridad
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu pago individual y los cobros."),
    // );
    // bool auth = await authCore.authenticateUser();
    // if (mounted) Navigator.pop(context);
    // if (!auth) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu pago individual y los cobros."),
    );
    BigInt amountWei = BigInt.from(perPerson * 1e18);
    String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: destinoWallet, amountWei: amountWei);
    if (mounted) Navigator.pop(context);
    if (signature == null) return;

    // 2. Transición a pantalla de procesamiento pendiente
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionPendingScreen(
          customTitle: "Liquidando Cuenta Colectiva",
          customMessage: "Pagando tu parte y enviando solicitudes de cobros divididos...",
          expectedTxType: "SPLIT_BILL",
          onUpdateBalance: widget.onBillSplitSuccess,
        ),
      ),
    );

    bool procesoExitoso = true;

    // 🔥 3. EL CREADOR PAGA SU PARTE DIRECTAMENTE AL COMERCIO DE DESTINO EN L2
    try {
     // String txRes = await txService.sendTokensL2(destinoWallet, perPerson, );
     String txRes = await txService.sendTokensL2(destinoWallet, perPerson, signature);
      if (!txRes.startsWith("Exito")) {
        procesoExitoso = false;
      }
    } catch (e) {
      procesoExitoso = false;
    }

    // 4. Se generan las solicitudes automáticas off-chain para los amigos implicados
    if (procesoExitoso) {
      String shortAddress = "${destinoWallet.substring(0, 6)}...${destinoWallet.substring(destinoWallet.length - 4)}";
      for (var amigo in _participants) {
        String res = await debtService.createDebtRequest(
          amigo['wallet']!,
          perPerson,
          "${_reasonController.text.trim()} (Destino Comercio: $shortAddress ✂️)",
        );
        if (res != "Exito") procesoExitoso = false;
      }
    }

    if (mounted) Navigator.pop(context); // Sacamos la pantalla pending

    if (procesoExitoso) {
      UIHelper.showCustomSnackbar("¡Tu cuota ha sido transferida y las solicitudes enviadas! 🎉", isError: false);
      widget.onBillSplitSuccess(); 

      // 🔥 NUEVO: Disparamos el callback detallado para que el Chat pinte la tarjeta interactiva
      if (widget.onBillSplitSuccessDetails != null) {
        widget.onBillSplitSuccessDetails!(totalAmount, _reasonController.text.trim(), perPerson);
      }
      
      Navigator.pop(context); 
    } else {
      UIHelper.showCustomSnackbar("Error al procesar el pago masivo. Revisa balances.", isError: true);
      widget.onBillSplitSuccess();
      Navigator.pop(context);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final onSurface = colorScheme.onSurface;

  //   double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
  //   int totalPeople = _participants.length + 1;
  //   double perPerson = totalPeople > 1 ? (totalAmount / totalPeople) : 0.0;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Dividir Cuenta Colectiva", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       centerTitle: true,
  //     ),
  //   body: GestureDetector(
  //       onTap: () => FocusScope.of(context).unfocus(),
  //       child: SafeArea(
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               const SizedBox(height: 10),
                
  //               // SECCIÓN: MONTO GRANDIOSO Y CONCEPTO
  //               Card(
  //                 color: theme.cardColor,
  //                 elevation: 0,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(24),
  //                   side: BorderSide(color: onSurface.withOpacity(0.05)),
  //                 ),
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(20.0),
  //                   child: Column(
  //                     children: [
  //                       TextField(
  //                         controller: _amountController,
  //                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: -1),
  //                         onChanged: (val) => setState(() {}),
  //                         decoration: InputDecoration(
  //                           hintText: "0.00",
  //                           suffixText: "TTC",
  //                           suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
  //                           hintStyle: TextStyle(color: onSurface.withOpacity(0.2)),
  //                           border: InputBorder.none,
  //                           helperText: "Monto Neto de la Factura",
  //                           helperStyle: TextStyle(color: onSurface.withOpacity(0.4)),
  //                         ),
  //                       ),
  //                       const Divider(height: 20),
  //                       TextField(
  //                         controller: _reasonController,
  //                         decoration: InputDecoration(
  //                           hintText: "¿Qué se está pagando? (ej. Restaurante Cuenca)",
  //                           prefixIcon: const Icon(Icons.receipt_long_rounded, color: Colors.orange),
  //                           filled: true,
  //                           fillColor: onSurface.withOpacity(0.05),
  //                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               // SECCIÓN BILLETERA / COMERCIO DE DESTINO
  //               Text("Cuenta de Destino o Comercio (Ambos Pagan Aquí)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextField(
  //                       controller: _destinationWalletController,
  //                       decoration: InputDecoration(
  //                         hintText: "Billetera 0x... o @Alias del Comercio",
  //                         prefixIcon: const Icon(Icons.account_balance_rounded, color: Colors.purpleAccent),
  //                         filled: true,
  //                         fillColor: onSurface.withOpacity(0.05),
  //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   InkWell(
  //                     onTap: _buscarDestinoPorAlias,
  //                     borderRadius: BorderRadius.circular(16),
  //                     child: Container(
  //                       height: 52, width: 52,
  //                       decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //                       child: _isSearchingDestinationAlias
  //                           ? const Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent))
  //                           : const Icon(Icons.search_rounded, color: Colors.purpleAccent),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   InkWell(
  //                     onTap: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(builder: (_) => const QrScannerScreen()),
  //                       ).then((scannedValue) {
  //                         if (scannedValue != null && scannedValue.toString().isNotEmpty) {
  //                           setState(() {
  //                             _destinationWalletController.text = scannedValue.toString().toLowerCase();
  //                           });
  //                           UIHelper.showCustomSnackbar("Código QR de factura leído correctamente.", isError: false);
  //                         }
  //                       });
  //                     },
  //                     borderRadius: BorderRadius.circular(16),
  //                     child: Container(
  //                       height: 52, width: 52,
  //                       decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //                       child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.orangeAccent),
  //                     ),
  //                   )
  //                 ],
  //               ),
  //               const SizedBox(height: 20),

  //               // SECCIÓN: BUSCADOR DE PARTICIPANTES
  //               Text("Amigos incluidos en la cuenta", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextField(
  //                       controller: _aliasController,
  //                       textInputAction: TextInputAction.search,
  //                       onSubmitted: (_) => _buscarYAgregarParticipante(),
  //                       decoration: InputDecoration(
  //                         hintText: "Escribe el @alias de tu amigo",
  //                         prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.blueAccent),
  //                         filled: true,
  //                         fillColor: onSurface.withOpacity(0.05),
  //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   InkWell(
  //                     onTap: _buscarYAgregarParticipante,
  //                     borderRadius: BorderRadius.circular(16),
  //                     child: Container(
  //                       height: 52, width: 52,
  //                       decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //                       child: _isSearchingAlias
  //                           ? const Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
  //                           : const Icon(Icons.person_add_alt_1_rounded, color: Colors.blueAccent),
  //                     ),
  //                   )
  //                 ],
  //               ),
  //               const SizedBox(height: 12),

  //               // LISTA DINÁMICA DE AMIGOS (Sin Expanded y con shrinkWrap)
  //               _participants.isEmpty
  //                   ? Padding(
  //                       padding: const EdgeInsets.symmetric(vertical: 20.0),
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Icon(Icons.group_add_rounded, size: 40, color: onSurface.withOpacity(0.15)),
  //                           const SizedBox(height: 8),
  //                           Text("Aún no agregas amigos a la división.", style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13)),
  //                         ],
  //                       ),
  //                     )
  //                   : ListView.builder(
  //                       shrinkWrap: true, // 🔥 Vital para usar dentro de un ScrollView
  //                       physics: const NeverScrollableScrollPhysics(), // 🔥 Evita conflicto de scrolls
  //                       itemCount: _participants.length,
  //                       itemBuilder: (ctx, index) {
  //                         final amigo = _participants[index];
  //                         return Container(
  //                           margin: const EdgeInsets.only(bottom: 8),
  //                           decoration: BoxDecoration(
  //                             color: theme.cardColor,
  //                             borderRadius: BorderRadius.circular(16),
  //                             border: Border.all(color: onSurface.withOpacity(0.03)),
  //                           ),
  //                           child: ListTile(
  //                             leading: SmartAvatar(address: amigo['wallet']!, size: 36),
  //                             title: Text("@${amigo['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                             subtitle: Text(
  //                               "${amigo['wallet']!.substring(0, 6)}...${amigo['wallet']!.substring(amigo['wallet']!.length - 4)}",
  //                               style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
  //                             ),
  //                             trailing: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Text(
  //                                   "${perPerson.toStringAsFixed(2)} TTC", 
  //                                   style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)
  //                                 ),
  //                                 const SizedBox(width: 4),
  //                                 IconButton(
  //                                   icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
  //                                   onPressed: () => setState(() => _participants.removeAt(index)),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),

  //               const SizedBox(height: 20),

  //               // RESUMEN MATEMÁTICO INFERIOR Y BOTÓN ACCIÓN
  //               Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: colorScheme.primary.withOpacity(0.06),
  //                   borderRadius: BorderRadius.circular(20),
  //                   border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
  //                 ),
  //                 child: Column(
  //                   children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text("Miembros implicados:", style: TextStyle(color: onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
  //                         Text("$totalPeople (Amigos + Tú)", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 6),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         const Text("Tu cuota a transferir ahora:", style: TextStyle(fontWeight: FontWeight.bold)),
  //                         Text("${perPerson.toStringAsFixed(2)} TTC", style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 18)),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               const SizedBox(height: 14),
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 54,
  //                 child: ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: colorScheme.primary,
  //                     foregroundColor: colorScheme.onPrimary,
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                   ),
  //                   icon: const Icon(Icons.call_split_rounded),
  //                   label: Text(
  //                     "Pagar mi parte y solicitar a ${_participants.length} amigos",
  //                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  //                   ),
  //                   onPressed: (_participants.isEmpty || totalAmount <= 0 || _destinationWalletController.text.isEmpty) ? null : _procesarDivisionDeCuenta,
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    int totalPeople = _participants.length + 1;
    double perPerson = totalPeople > 1 ? (totalAmount / totalPeople) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Dividir Cuenta Colectiva", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECCIÓN: MONTO GRANDIOSO Y CONCEPTO
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: onSurface.withOpacity(0.05)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Campo de texto gigante interactivo
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (val) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 60, 
                            fontWeight: FontWeight.bold, 
                            color: Color(0xFFBAC3FF),
                            height: 1.1,
                          ),
                          decoration: InputDecoration(
                            hintText: "Cantidad",
                            hintStyle: TextStyle(fontSize: 48, color: onSurface.withOpacity(0.2)),
                            suffixText: "TTC",
                            suffixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            hintText: "¿Qué se está pagando? (ej. Restaurante)",
                            prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFe0b6ff)),
                            filled: true,
                            fillColor: onSurface.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECCIÓN BILLETERA / COMERCIO DE DESTINO
                Text("CUENTA DE DESTINO O COMERCIO (AMBOS PAGAN AQUÍ)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6), letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _destinationWalletController,
                        decoration: InputDecoration(
                          hintText: "0xa754b5a56b325...",
                          prefixIcon: const Icon(Icons.account_balance_rounded, color: Color(0xFFe0b6ff)),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _buscarDestinoPorAlias,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 52, width: 52,
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                        child: _isSearchingDestinationAlias
                            ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBAC3FF)))
                            : const Icon(Icons.search_rounded, color: Color(0xFFBAC3FF)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        ).then((scannedValue) {
                          if (scannedValue != null && scannedValue.toString().isNotEmpty) {
                            setState(() {
                              _destinationWalletController.text = scannedValue.toString().toLowerCase();
                            });
                            UIHelper.showCustomSnackbar("Código QR de factura leído correctamente.", isError: false);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 52, width: 52,
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFFB86B)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // SECCIÓN: BUSCADOR DE PARTICIPANTES
                Text("AMIGOS INCLUIDOS EN LA CUENTA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6), letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aliasController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscarYAgregarParticipante(),
                        decoration: InputDecoration(
                          hintText: "Escribe el @alias de tu amigo",
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFFBAC3FF)),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _buscarYAgregarParticipante,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 52, width: 52,
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                        child: _isSearchingAlias
                            ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBAC3FF)))
                            : const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFBAC3FF)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),

                // LISTA DINÁMICA DE AMIGOS
                if (_participants.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: _participants.length,
                    itemBuilder: (ctx, index) {
                      final amigo = _participants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: SmartAvatar(address: amigo['wallet']!, size: 40),
                          title: Text("@${amigo['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "${amigo['wallet']!.substring(0, 6)}...${amigo['wallet']!.substring(amigo['wallet']!.length - 4)}",
                            style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: onSurface.withOpacity(0.6)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${perPerson.toStringAsFixed(2)} TTC", 
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => setState(() => _participants.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 32),

                // RESUMEN MATEMÁTICO INFERIOR Y BOTÓN ACCIÓN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Miembros implicados:", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
                    Text("$totalPeople (Amigos + Tú)", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tu cuota a transferir ahora:", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
                    Text("${perPerson.toStringAsFixed(2)} TTC", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFBAC3FF), fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBAC3FF),
                      foregroundColor: const Color(0xFF00218d),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.call_split_rounded, size: 20),
                    label: Text(
                      "Pagar mi parte y solicitar a ${_participants.length} amigos",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: (_participants.isEmpty || totalAmount <= 0 || _destinationWalletController.text.isEmpty) ? null : _procesarDivisionDeCuenta,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}