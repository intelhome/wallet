import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../../debts_and_payments/services/debt_service.dart';
import '../screens/transaction_pending_screen.dart';
import '../modals/transaction_simulator_modal.dart';
import '../modals/transaction_details_modal.dart';
import '../screens/receipt_preview_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../modals/buy_modal.dart';

class SendFlowScreen extends StatefulWidget {
  final String balanceTTC;
  final VoidCallback onUpdateBalance;
  final void Function(String, {bool esError}) mostrarMensaje;
  final String? initialAddress;
  final String? debtId;
  final String? sharedDebtId;

  const SendFlowScreen({
    super.key,
    required this.balanceTTC,
    required this.onUpdateBalance,
    required this.mostrarMensaje,
    this.initialAddress,
    this.debtId,
    this.sharedDebtId,
  });

  @override
  State<SendFlowScreen> createState() => _SendFlowScreenState();
}

class _SendFlowScreenState extends State<SendFlowScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  String _destinationWallet = ""; 

  bool _isOffChain = false; 
  bool _isPaid = false; 
  bool _isProcessingPayment = false;
  
  Pay? _payClient;

  List<Map<String, dynamic>> _recentContacts = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarUsuario());
    }

    PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
      _payClient = Pay({PayProvider.google_pay: config});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentContacts();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // ==========================================
  // PASO 1: BÚSQUEDA
  // ==========================================
 Future<void> _buscarUsuario() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    
    final userService = Provider.of<UserService>(context, listen: false);
    
    // 1. BÚSQUEDA POR ALIAS (@usuario)
    if (query.startsWith("@")) {
      String cleanAlias = query.substring(1);
      final result = await userService.searchByAlias(cleanAlias);
      if (result != null) {
        setState(() {
          _foundUser = result;
          _destinationWallet = result['walletAddress'] ?? result['contactAddress'] ?? result['wallet'] ?? "";
          _isOffChain = true; 
        });
        _nextPage();
      } else {
        widget.mostrarMensaje("Usuario no encontrado. Revisa el alias.", esError: true);
      }
    } 
    // 2. BÚSQUEDA POR WALLET (0x...)
    else if (query.startsWith("0x") && query.length == 42) {
      // 🔥 FIX: Buscamos si esta wallet le pertenece a un usuario de nuestra BD
      final result = await userService.getUserByWallet(query);

      if (result != null && result.isNotEmpty && result['alias'] != null) {
        // ✅ ¡Es un usuario de nuestro ecosistema! Mostramos su perfil completo
        setState(() {
          _foundUser = result;
          _foundUser!['walletAddress'] = query;
          _foundUser!['isExternal'] = false; // Marcamos que SÍ es interno
          _destinationWallet = query;
          _isOffChain = false; // Se mantiene On-Chain porque buscó por wallet
        });
      } else {
        // ❌ No está registrado, es una verdadera billetera externa
        setState(() {
          _foundUser = {
            "alias": "Billetera Externa",
            "walletAddress": query,
            "isExternal": true
          };
          _destinationWallet = query;
          _isOffChain = false; 
        });
      }
      _nextPage();
    } 
    // 3. FORMATO INCORRECTO
    else {
      widget.mostrarMensaje("Formato incorrecto. Usa @alias o una wallet 0x.", esError: true);
    }
    
    setState(() => _isSearching = false);
  }

Future<void> _loadRecentContacts() async {
    if (!mounted) return;
    try {
      final txService = Provider.of<TransactionService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      final myWallet = authCore.publicAddress.toLowerCase();

      final history = await txService.getTransactionHistory();
      List<String> uniqueWallets = [];

      for (var tx in history) {
        if (tx['status'] != 'COMPLETED') continue;
        if (tx['senderAddress']?.toString().toLowerCase() != myWallet) continue;
        if (tx['txType'] != 'SEND' && tx['txType'] != 'BINANCE_PAY') continue;

        String receiver = tx['receiverAddress']?.toString().toLowerCase() ?? '';
        if (receiver.isNotEmpty && receiver != myWallet && !uniqueWallets.contains(receiver)) {
          uniqueWallets.add(receiver);
        }
        if (uniqueWallets.length >= 5) break; 
      }

      List<Map<String, dynamic>> recents = [];
      for (String wallet in uniqueWallets) {
        final user = await userService.getUserByWallet(wallet);
        if (user != null && user['alias'] != null) {
          recents.add({
            'wallet': wallet, 
            'alias': user['alias'],
            // 🔥 Obtenemos el identificador para la tarjeta
            'identifier': user['cedula'] ?? user['identifier'] ?? user['ruc'] ?? 'Registrado'
          });
        } else {
          recents.add({'wallet': wallet, 'alias': '0x${wallet.substring(2, 6)}...', 'identifier': 'Externa'});
        }
      }

      if (mounted) setState(() { _recentContacts = recents; _isLoadingRecent = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecent = false);
    }
  }

  // Future<void> _loadRecentContacts() async {
  //   if (!mounted) return;
    
  //   try {
  //     final txService = Provider.of<TransactionService>(context, listen: false);
  //     final userService = Provider.of<UserService>(context, listen: false);
  //     final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //     final myWallet = authCore.publicAddress.toLowerCase();

  //     // 1. Obtenemos el historial fresco
  //     final history = await txService.getTransactionHistory();
  //     List<String> uniqueWallets = [];

  //     // 2. Filtramos solo los envíos exitosos hechos por el usuario
  //     for (var tx in history) {
  //       if (tx['status'] != 'COMPLETED') continue;
  //       if (tx['senderAddress']?.toString().toLowerCase() != myWallet) continue;
        
  //       // Solo nos interesan transferencias salientes (SEND o BINANCE_PAY)
  //       if (tx['txType'] != 'SEND' && tx['txType'] != 'BINANCE_PAY') continue;

  //       String receiver = tx['receiverAddress']?.toString().toLowerCase() ?? '';
        
  //       // Extraemos billeteras únicas (las últimas 5)
  //       if (receiver.isNotEmpty && receiver != myWallet && !uniqueWallets.contains(receiver)) {
  //         uniqueWallets.add(receiver);
  //       }
  //       if (uniqueWallets.length >= 5) break; 
  //     }

  //     // 3. Buscamos los datos bonitos (Alias/Avatar) de esas billeteras
  //     List<Map<String, dynamic>> recents = [];
  //     for (String wallet in uniqueWallets) {
  //       final user = await userService.getUserByWallet(wallet);
  //       if (user != null && user['alias'] != null) {
  //         recents.add({'wallet': wallet, 'alias': user['alias']});
  //       } else {
  //         // Si es externa y no tiene alias, mostramos un pedacito de la wallet
  //         recents.add({'wallet': wallet, 'alias': '0x${wallet.substring(2, 6)}...'});
  //       }
  //     }

  //     // 4. Actualizamos la interfaz
  //     if (mounted) {
  //       setState(() {
  //         _recentContacts = recents;
  //         _isLoadingRecent = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("Error cargando contactos recientes: $e");
  //     if (mounted) setState(() => _isLoadingRecent = false);
  //   }
  // }

  // ==========================================
  // VISTAS DEL PAGEVIEW
  // ==========================================

Widget _buildStep1Search() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: Icon(Icons.arrow_back_rounded, color: onSurface), onPressed: () => Navigator.pop(context)),
              Text("Enviar Tokens", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Ícono central
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: onSurface.withOpacity(0.05), shape: BoxShape.circle),
                  child: Icon(Icons.group_rounded, size: 40, color: onSurface.withOpacity(0.5)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF4361EE), shape: BoxShape.circle, border: Border.all(color: theme.scaffoldBackgroundColor, width: 3)),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 14),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("¿A quién quieres enviar?", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 12),
          Text("Busca por @alias para transferencias\nultrarrápidas y sin costo de red.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6), height: 1.4)),
          const SizedBox(height: 32),
          
          // Buscador
          TextField(
            controller: _searchController,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: "Ingresa el @alias o wallet 0x...",
              hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.5)),
              filled: true,
              fillColor: theme.cardColor,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFBAC3FF)),
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

          if (_isLoadingRecent)
             const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: Color(0xFF4361EE))))
          else if (_recentContacts.isNotEmpty) ...[
            const SizedBox(height: 40),
            Text("Contactos Recientes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 170, // 🔥 Aumentado para acomodar el ID abajo
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recentContacts.length,
                itemBuilder: (context, index) {
                  final contact = _recentContacts[index];
                  String shortWallet = contact['wallet'].toString();
                  if (shortWallet.length > 10) shortWallet = "${shortWallet.substring(0, 6)}...${shortWallet.substring(shortWallet.length - 4)}";

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchController.text = contact['wallet'];
                      _buscarUsuario(); 
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(address: contact['wallet'], size: 48),
                          const SizedBox(height: 12),
                          Text("@${contact['alias']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(shortWallet, style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.5), fontFamily: 'monospace')),
                          const Spacer(),
                          Divider(color: onSurface.withOpacity(0.05), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.badge_outlined, size: 12, color: onSurface.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(contact['identifier'] ?? 'Registrado', style: TextStyle(fontSize: 10, color: onSurface.withOpacity(0.5)), overflow: TextOverflow.ellipsis),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
          
          const Spacer(),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
              onPressed: _isSearching ? null : _buscarUsuario,
              child: _isSearching 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Buscar Usuario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStep1Search() {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   return Padding(
  //     padding: const EdgeInsets.all(24.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         Row(
  //           children: [
  //             IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
  //             const Spacer(),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         Icon(Icons.person_search_rounded, size: 80, color: colorScheme.primary.withOpacity(0.5)),
  //         const SizedBox(height: 24),
  //         const Text("¿A quién quieres enviar?", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  //         const SizedBox(height: 10),
  //         Text("Busca por @alias para transferencias ultrarrápidas y sin costo de red.", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
  //         const SizedBox(height: 40),
          
  //         TextField(
  //           controller: _searchController,
  //           decoration: InputDecoration(
  //             labelText: "Ingresa el @alias o wallet 0x...",
  //             prefixIcon: const Icon(Icons.search),
  //             filled: true,
  //             fillColor: colorScheme.onSurface.withOpacity(0.05),
  //             suffixIcon: IconButton(
  //               icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
  //               onPressed: () async {
  //                 final scanned = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
  //                 if (scanned != null) {
  //                   _searchController.text = scanned.trim();
  //                   _buscarUsuario();
  //                 }
  //               },
  //             ),
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //           ),
  //           onSubmitted: (_) => _buscarUsuario(),
  //         ),

  //         if (_isLoadingRecent)
  //            const Padding(
  //              padding: EdgeInsets.only(top: 40),
  //              child: Center(child: CircularProgressIndicator()),
  //            )
  //         else if (_recentContacts.isNotEmpty) ...[
  //           const SizedBox(height: 32),
  //           Text("Transferir de nuevo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7))),
  //           const SizedBox(height: 16),
  //           SizedBox(
  //             height: 90,
  //             child: ListView.builder(
  //               scrollDirection: Axis.horizontal,
  //               itemCount: _recentContacts.length,
  //               itemBuilder: (context, index) {
  //                 final contact = _recentContacts[index];
  //                 return GestureDetector(
  //                   onTap: () {
  //                     HapticFeedback.lightImpact();
  //                     _searchController.text = contact['wallet'];
  //                     _buscarUsuario(); // Dispara automáticamente la búsqueda y pasa al Paso 2
  //                   },
  //                   child: Container(
  //                     width: 72,
  //                     margin: const EdgeInsets.only(right: 16),
  //                     child: Column(
  //                       children: [
  //                         SmartAvatar(address: contact['wallet'], size: 56),
  //                         const SizedBox(height: 8),
  //                         Text(
  //                           "@${contact['alias']}",
  //                           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  //                           overflow: TextOverflow.ellipsis,
  //                           textAlign: TextAlign.center,
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           )
  //         ],
          
  //         const Spacer(),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary,
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
  //           ),
  //           onPressed: _isSearching ? null : _buscarUsuario,
  //           child: _isSearching 
  //               ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
  //               : const Text("Buscar Usuario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildStep2Verify() {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   final onSurface = colorScheme.onSurface;
    
  //   String alias = _foundUser?['alias'] ?? "Desconocido";
  //   bool isExternal = _foundUser?['isExternal'] == true;

  //   // 🔥 CAMPOS ENRIQUECIDOS
  //   String? email = _foundUser?['email'];
  //   String? phone = _foundUser?['phoneNumber'];
  //   String? cedula = _foundUser?['cedula'] ?? _foundUser?['identifier'] ?? _foundUser?['ruc'];

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(24.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Row(
  //           children: [
  //             IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
  //             const Spacer(),
  //           ],
  //         ),
  //         SmartAvatar(address: _destinationWallet, size: 80),
  //         const SizedBox(height: 16),
  //         Text(isExternal ? "Billetera Externa" : "@$alias", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          
  //         const SizedBox(height: 8),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //           decoration: BoxDecoration(color: _isOffChain ? Colors.amber.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
  //           child: Text(
  //             _isOffChain ? "⚡ Pago Instantáneo TTC Pay" : "🔗 Transferencia On-Chain",
  //             style: TextStyle(color: _isOffChain ? Colors.amber[700] : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
  //           ),
  //         ),
  //         const SizedBox(height: 30),

  //         // 🔥 TARJETA DE VERIFICACIÓN DE IDENTIDAD
  //         Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: onSurface.withOpacity(0.03),
  //             borderRadius: BorderRadius.circular(24),
  //             border: Border.all(color: onSurface.withOpacity(0.05))
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Detalles de Seguridad", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 16),
                
  //               _buildVerificationRow(Icons.account_balance_wallet_rounded, "Billetera Pública", _destinationWallet, isMonospace: true),
  //               if (!isExternal) ...[
  //                 const Divider(height: 24),
  //                 _buildVerificationRow(Icons.badge_rounded, "Identificación (Cédula/RUC)", cedula ?? "Oculto por privacidad"),
  //                 const Divider(height: 24),
  //                 _buildVerificationRow(Icons.email_rounded, "Correo Electrónico", email ?? "Oculto por privacidad"),
  //                 const Divider(height: 24),
  //                 _buildVerificationRow(Icons.phone_rounded, "Teléfono Celular", phone ?? "Oculto por privacidad"),
  //               ]
  //             ],
  //           ),
  //         ),

  //         if (isExternal) ...[
  //           const SizedBox(height: 20),
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
  //             child: Row(
  //               children: [
  //                 const Icon(Icons.warning_amber_rounded, color: Colors.orange),
  //                 const SizedBox(width: 12),
  //                 Expanded(child: Text("Billetera no verificada en el ecosistema TTC. Asegúrate de que la dirección sea correcta, las transacciones blockchain son irreversibles.", style: TextStyle(color: Colors.orange[800], fontSize: 12))),
  //               ],
  //             ),
  //           )
  //         ],
          
  //         const SizedBox(height: 40),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: OutlinedButton(
  //                 style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                 onPressed: _prevPage,
  //                 child: const Text("Volver a Buscar"),
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                 onPressed: _nextPage,
  //                 child: const Text("Es Correcto", style: TextStyle(fontWeight: FontWeight.bold)),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildVerificationRow(IconData icon, String label, String value, {bool isMonospace = false}) {
  //   final onSurface = Theme.of(context).colorScheme.onSurface;
  //   return Row(
  //     children: [
  //       Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(label, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
  //             Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: isMonospace ? 'monospace' : null)),
  //           ],
  //         ),
  //       )
  //     ],
  //   );
  // }

  Widget _buildStep2Verify() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    
    String alias = _foundUser?['alias'] ?? "Desconocido";
    bool isExternal = _foundUser?['isExternal'] == true;

    String? email = _foundUser?['email'];
    String? phone = _foundUser?['phoneNumber'];
    String? cedula = _foundUser?['cedula'] ?? _foundUser?['identifier'] ?? _foundUser?['ruc'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(icon: Icon(Icons.arrow_back_rounded, color: onSurface), onPressed: _prevPage),
              Text("Enviar a @$alias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 32),
          
          SmartAvatar(address: _destinationWallet, size: 80),
          const SizedBox(height: 16),
          Text(isExternal ? "Billetera Externa" : "@$alias", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurface)),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isOffChain ? Icons.flash_on_rounded : Icons.link_rounded, color: const Color(0xFFBAC3FF), size: 14),
                const SizedBox(width: 6),
                Text(_isOffChain ? "Pago Instantáneo TTC Pay" : "Transferencia On-Chain", style: const TextStyle(color: Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detalles de Seguridad", style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                _buildVerificationRow(Icons.account_balance_wallet_outlined, "Billetera Pública", _destinationWallet, isMonospace: true),
                if (!isExternal) ...[
                  Divider(color: onSurface.withOpacity(0.05), height: 32),
                  _buildVerificationRow(Icons.badge_outlined, "Identificación (Cédula/RUC)", cedula ?? "Oculto por privacidad"),
                  Divider(color: onSurface.withOpacity(0.05), height: 32),
                  _buildVerificationRow(Icons.email_outlined, "Correo Electrónico", email ?? "Oculto por privacidad"),
                  Divider(color: onSurface.withOpacity(0.05), height: 32),
                  _buildVerificationRow(Icons.phone_outlined, "Teléfono Celular", phone ?? "Oculto por privacidad"),
                ]
              ],
            ),
          ),

          if (isExternal) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Billetera no verificada en el ecosistema TTC. Asegúrate de que la dirección sea correcta.", style: TextStyle(color: Colors.orange[800], fontSize: 12))),
                ],
              ),
            )
          ],
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: onSurface.withOpacity(0.8), side: BorderSide(color: onSurface.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  onPressed: _prevPage,
                  child: const Text("Volver a Buscar", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  onPressed: _nextPage,
                  child: const Text("Es Correcto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(IconData icon, String label, String value, {bool isMonospace = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: onSurface.withOpacity(0.6), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: isMonospace ? 'monospace' : null)),
            ],
          ),
        )
      ],
    );
  }


  // ==========================================
  // PASO 3: PAGO ("enviar tokens")
  // ==========================================
  Widget _buildStep3Pay() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: Icon(Icons.arrow_back_rounded, color: onSurface), onPressed: _prevPage),
              Text("Enviar a @${_foundUser?['alias'] ?? 'Wallet'}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text("TTC", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: onSurface),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: "0"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text("Saldo disponible: ${widget.balanceTTC} TTC", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold))),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: SwitchListTile(
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF4361EE),
              title: Text("Pago Comercial", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
              subtitle: Text("Actívalo si estás pagando un producto o servicio.", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
              value: _isPaid,
              onChanged: (val) => setState(() => _isPaid = val),
            ),
          ),
          
          if (!_isOffChain) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF4361EE).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFF4361EE), size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4361EE))),
                        const SizedBox(height: 4),
                        Row(children: [Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough)), const SizedBox(width: 6), const Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4361EE)))]),
                      ],
                    ),
                  ),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF4361EE).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("Patrocinado", style: TextStyle(color: Color(0xFF4361EE), fontSize: 10, fontWeight: FontWeight.bold)))
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: _isProcessingPayment ? null : _ejecutarPagoCrypto,
              child: _isProcessingPayment 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isOffChain ? "Enviar Instantáneo" : "Firmar Envío Web3", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          if (!_isOffChain) ...[
            const SizedBox(height: 24),
            Row(children: [Expanded(child: Divider(color: onSurface.withOpacity(0.1))), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("O PAGA CON FIAT", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0))), Expanded(child: Divider(color: onSurface.withOpacity(0.1)))]),
            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: onSurface, side: BorderSide(color: onSurface.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 36), // Emulamos los colores oscuros de la imagen
                label: const Text("Pagar con Google Pay", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: _isProcessingPayment ? null : _ejecutarPagoGPay,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: theme.cardColor, foregroundColor: onSurface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.1)))),
                icon: const Icon(Icons.paypal, color: Colors.white),
                label: const Text("Pagar con PayPal", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: _isProcessingPayment ? null : _ejecutarPagoPayPal,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Widget _buildStep3Pay() {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   final onSurface = colorScheme.onSurface;

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(24.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         Row(
  //           children: [
  //             IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
  //             Text("Enviar a @${_foundUser?['alias'] ?? 'Wallet'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           ],
  //         ),
  //         const SizedBox(height: 20),

  //         // CAMPO DE MONTO
  //         TextField(
  //           controller: _amountController,
  //           keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //           style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
  //           textAlign: TextAlign.center,
  //           decoration: InputDecoration(
  //             prefixText: "TTC ",
  //             filled: true, fillColor: onSurface.withOpacity(0.05),
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
  //           ),
  //         ),
  //         Center(child: Padding(padding: const EdgeInsets.only(top: 8), child: Text("Saldo disponible: ${widget.balanceTTC} TTC", style: TextStyle(color: onSurface.withOpacity(0.6))))),
          
  //         const SizedBox(height: 24),

  //         // SWITCH COMERCIAL
  //         Container(
  //           decoration: BoxDecoration(color: _isPaid ? Colors.green.withOpacity(0.1) : onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isPaid ? Colors.green : Colors.transparent)),
  //           child: SwitchListTile(
  //             activeColor: Colors.green,
  //             title: const Text("Pago Comercial", style: TextStyle(fontWeight: FontWeight.bold)),
  //             subtitle: const Text("Actívalo si estás pagando un producto o servicio.", style: TextStyle(fontSize: 12)),
  //             value: _isPaid,
  //             onChanged: (val) => setState(() => _isPaid = val),
  //           ),
  //         ),
          
  //         if (!_isOffChain) ...[
  //           const SizedBox(height: 20),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //             decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.primary.withOpacity(0.3))),
  //             child: Row(
  //               children: [
  //                 Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.local_gas_station_rounded, color: colorScheme.primary, size: 20)),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
  //                       Row(children: [Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough)), const SizedBox(width: 6), Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary))]),
  //                     ],
  //                   ),
  //                 ),
  //                 Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)), child: const Text("Patrocinado", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
  //               ],
  //             ),
  //           ),
  //         ],

  //         const SizedBox(height: 32),

  //         // BOTÓN PRINCIPAL DE CRYPTO
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: _isOffChain ? colorScheme.secondary : colorScheme.primary,
  //             foregroundColor: _isOffChain ? colorScheme.onSecondary : colorScheme.onPrimary,
  //             padding: const EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //           ),
  //           onPressed: _isProcessingPayment ? null : _ejecutarPagoCrypto,
  //           child: _isProcessingPayment 
  //             ? const CircularProgressIndicator(color: Colors.white)
  //             : Text(_isOffChain ? "Enviar Instantáneo" : "Firmar Envío Web3", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //         ),

  //         if (!_isOffChain) ...[
  //           const SizedBox(height: 24),
  //           Row(children: [Expanded(child: Divider(color: onSurface.withOpacity(0.2))), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O PAGA CON FIAT")), Expanded(child: Divider(color: onSurface.withOpacity(0.2)))]),
  //           const SizedBox(height: 24),

  //           // BOTONES FIAT
  //           OutlinedButton.icon(
  //             style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //             icon: const Icon(Icons.g_mobiledata, color: Colors.blueAccent, size: 36),
  //             label: const Text("Pagar con Google Pay", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
  //             onPressed: _isProcessingPayment ? null : _ejecutarPagoGPay,
  //           ),
  //           const SizedBox(height: 12),

  //           ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //             icon: const Icon(Icons.paypal, color: Colors.white),
  //             label: const Text("Pagar con PayPal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //             onPressed: _isProcessingPayment ? null : _ejecutarPagoPayPal,
  //           ),
  //         ]
  //       ],
  //     ),
  //   );
  // }

  // ==========================================
  // FUNCIONES DE EJECUCIÓN 
  // ==========================================

  Future<void> _ejecutarPagoCrypto() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;

    
    try {
       final prefs = await SharedPreferences.getInstance();
       double presupuesto = prefs.getDouble('presupuesto_mensual') ?? 500.0;
       
       // Obtenemos los gastos del mes usando la misma lógica robusta del Dashboard
       final txService = Provider.of<TransactionService>(context, listen: false);
       final authCore = Provider.of<AuthCoreService>(context, listen: false);
       
       double gastado = 0.0;
       final txs = await txService.getTransactionHistory();
       final myWallet = authCore.publicAddress.toLowerCase();
       final now = DateTime.now();

       for (var tx in txs) {
         if (tx['status'] == 'COMPLETED' &&
             (tx['txType'] == 'SEND' || tx['txType'] == 'BINANCE_PAY' || tx['txType'] == 'SEND_FIAT') &&
             tx['senderAddress']?.toString().toLowerCase() == myWallet) {
             if (tx['timestamp'] != null) {
               DateTime txDate = DateTime.parse(tx['timestamp'].toString()).toLocal();
               if (txDate.month == now.month && txDate.year == now.year) {
                 gastado += double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
               }
             }
         }
       }

       // Calculamos el espacio disponible
       double disponible = presupuesto - gastado;

       if (monto > disponible) {
           widget.mostrarMensaje(
               "Límite excedido. Te quedan ${disponible.toStringAsFixed(2)} TTC de tu presupuesto de ${presupuesto.toStringAsFixed(0)} TTC.", 
               esError: true
           );
           return; // 🛑 Bloqueamos la transacción
       }
    } catch (e) {
        print("Error validando presupuesto: $e");
        // Decidimos permitir continuar si falla la validación por error de red
    }

    double saldoActual = double.tryParse(widget.balanceTTC) ?? 0;
    if (monto > saldoActual) {
      widget.mostrarMensaje("Saldo insuficiente. Adquiere más TTC.", esError: true);
      // Aquí podrías llamar al Upsell Modal si lo deseas.
      return;
    }

    // setState(() => _isProcessingPayment = true);
    // final authCore = Provider.of<AuthCoreService>(context, listen: false);
    // final txService = Provider.of<TransactionService>(context, listen: false);
    // final debtService = Provider.of<DebtService>(context, listen: false);

    // bool proceedSimulation = await TransactionSimulatorModal.show(
    //   context: context, amount: monto, destination: _destinationWallet, currentBalance: saldoActual, isOffChain: _isOffChain,
    // ) ?? false;

    setState(() => _isProcessingPayment = true);
    
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    bool proceedSimulation = await TransactionSimulatorModal.show(
      context: context, amount: monto, destination: _destinationWallet, currentBalance: saldoActual, isOffChain: _isOffChain,
    ) ?? false;

    if (!proceedSimulation) { setState(() => _isProcessingPayment = false); return; }

    String? signature;
    if (_isOffChain) {
      bool isAuth = await authCore.authenticateUser();
      if (!isAuth) { setState(() => _isProcessingPayment = false); return; }
    } else {
      BigInt amountWei = BigInt.from(monto * 1e18);
      signature = await authCore.generateDelegatedSignature("SEND", toAddress: _destinationWallet.toLowerCase(), amountWei: amountWei);
      if (signature == null) { setState(() => _isProcessingPayment = false); return; }
    }

    try {
      String txHash = "0x...";
      String tipoTx = _isOffChain ? 'BINANCE_PAY' : 'SEND';

      Future<dynamic> pendingFuture = Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
          customTitle: _isOffChain ? "Envío Instantáneo" : "Minando Envío", 
          customMessage: "Procesando transacción...", 
          recipientAddress: _destinationWallet, expectedTxType: tipoTx, onUpdateBalance: widget.onUpdateBalance 
      )));

      if (_isOffChain) {
        String aliasBackend = _foundUser!['alias'];
        final res = await txService.sendOffChainAlias(aliasBackend, monto);
        if (res.startsWith("Error")) { Navigator.pop(context); widget.mostrarMensaje(res, esError: true); return; }
        txHash = res.replaceAll("Exito: ", "").trim();
      } else {
        final res = await txService.sendTokensL2(_destinationWallet, monto, signature!);
        if (res.startsWith("Error")) { Navigator.pop(context); widget.mostrarMensaje(res, esError: true); return; }
        txHash = res.replaceAll("Exito: ", "").trim();
      }

      if (widget.debtId != null) await debtService.payPersonalDebt(widget.debtId!, monto, _destinationWallet);
      if (widget.sharedDebtId != null) await debtService.notifySharedDebtContribution(widget.sharedDebtId!, monto);

      final result = await pendingFuture;
      if (result == true) await _manejarFlujoPostPago(tipoTx, monto, txHash);

    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _manejarFlujoPostPago(String tipoTx, double monto, String txHash) async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    dynamic mockTx = {
      'txType': tipoTx, 'amount': monto, 'txHash': txHash, 'senderAddress': authCore.publicAddress,
      'receiverAddress': _destinationWallet, 'status': 'COMPLETED', 'timestamp': DateTime.now().toIso8601String()
    };

    if (_isPaid) {
      bool? verComprobante = await UIHelper.mostrarConfirmacion(
        context: context, titulo: "Pago Exitoso",
        mensaje: "¿Deseas ver el comprobante para compartirlo al comercio?", textoConfirmar: "Ver Comprobante", colorConfirmar: Colors.green,
      );
      if (verComprobante == true) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
      }
      Navigator.pop(context); // Cierra el Flujo
    } else {
      List<dynamic> misContactos = await userService.getUserContacts();
      bool isKnown = misContactos.any((c) => c['contactAddress'].toString().toLowerCase() == _destinationWallet.toLowerCase());
      
      if (!isKnown && _foundUser?['isExternal'] == true) {
        TransactionDetailsModal.mostrarDialogoGuardarContacto(context, context, _destinationWallet, authCore.publicAddress);
      } else {
        UIHelper.showCustomSnackbar("Envío exitoso");
        mainScreenKey.currentState?.forceDashboardRefresh();
        Navigator.pop(context); // Cierra el Flujo
      }
    }
  }

 Future<void> _ejecutarPagoGPay() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;

    if (_payClient == null) {
      widget.mostrarMensaje("Cargando servicios de Google, intenta de nuevo.", esError: true);
      return;
    }

    setState(() => _isProcessingPayment = true);

    // 1. Validar huella dactilar
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar la orden GPay."));
    bool isAuth = await authCore.authenticateUser();
    if (!mounted) return;
    Navigator.pop(context); // Cierra el skeleton de huella

    if (!isAuth) {
      setState(() => _isProcessingPayment = false);
      widget.mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
      return;
    }

    // 2. Ejecutar pasarela GPay (o Simulador si falla en emulador)
    try {
      await _payClient!.showPaymentSelector(
        PayProvider.google_pay, 
        [ PaymentItem(label: 'Envío de TTC a $_destinationWallet', amount: monto.toStringAsFixed(2), status: PaymentItemStatus.final_price) ],
      );
    } catch (e) {
      print("Error nativo de GPay atrapado: $e");
      widget.mostrarMensaje("Billetera inactiva. Usando modo simulador de pago...");
      await Future.delayed(const Duration(seconds: 2)); 
    }

    // 3. Registrar el pago fiat en el Backend / Blockchain
    try {
      final txService = Provider.of<TransactionService>(context, listen: false);
      final debtService = Provider.of<DebtService>(context, listen: false);

      Future<dynamic> pendingFuture = Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
        customTitle: "Enviando y Recompensando", 
        customMessage: "Acreditando Cashback en tu billetera...",
        recipientAddress: _destinationWallet, 
        expectedTxType: "SEND_FIAT", 
        onUpdateBalance: widget.onUpdateBalance
      )));

      String orderId = "GPAY-SEND-${DateTime.now().millisecondsSinceEpoch}"; 
      final res = await txService.sendTokensFiat(_destinationWallet, orderId, monto);

      if (res.startsWith("Error")) {
        if (mounted) Navigator.pop(context, false); // Forzamos cierre de pending
        widget.mostrarMensaje(res, esError: true);
      } else {
        String txHashResult = res.replaceAll("Exito: ", "").trim();
        if (widget.debtId != null) await debtService.payPersonalDebt(widget.debtId!, monto, _destinationWallet);
        if (widget.sharedDebtId != null) await debtService.notifySharedDebtContribution(widget.sharedDebtId!, monto);
        
        final result = await pendingFuture;

        if (result == true) {
          await _manejarFlujoPostPago('SEND_FIAT', monto, txHashResult);
        }
      }
    } catch (e) {
      widget.mostrarMensaje("Error al procesar la orden en el servidor.", esError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

Future<void> _ejecutarPagoPayPal() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    // 1. Validación Biométrica
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para abrir PayPal."));
    HapticFeedback.mediumImpact();
    bool isAuth = await authCore.authenticateUser();
    if (!mounted) return;
    Navigator.pop(context); // Cierra skeleton

    if (!isAuth) {
      widget.mostrarMensaje("Autenticación cancelada. Envío abortado.", esError: true);
      return; 
    }

    // 2. Abrir Navegador Webview de PayPal
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext ctx) => UsePaypal(
          sandboxMode: true,
          clientId: "AW91VEGq61jntCQhvokYTUOaxCVcizMrknQfIkXklZtzlNDZdWN74Un4PIxng_hxrTot6_TuDyv1o24W",
          secretKey: "ELBDqAKGPSxRGp-LutS9fgTiFIswAan_9wVyK5MqnGQcGfMllkUA9C1AyrJcXxXyPuoSTLl0EXwHAtoE",
          returnURL: "https://sandbox.paypal.com/return",
          cancelURL: "https://sandbox.paypal.com/cancel",
          transactions: [
            {
              "amount": {
                "total": monto.toStringAsFixed(2),
                "currency": "USD",
                "details": { "subtotal": monto.toStringAsFixed(2), "shipping": '0', "shipping_discount": 0 }
              },
              "description": "Envío de TTC a $_destinationWallet",
              "item_list": { "items": [ { "name": "Envío TTC a Billetera", "quantity": 1, "price": monto.toStringAsFixed(2), "currency": "USD" } ] }
            }
          ],
          note: "Envío seguro de TTC.",
          onSuccess: (Map params) {
            // El Webview se cierra solo, esperamos 500ms y abrimos el PendingScreen
            Future.delayed(const Duration(milliseconds: 500), () async {
              
              Future<dynamic> pendingFuture = Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                customTitle: "Enviando y Recompensando", 
                customMessage: "Entregando fondos y calculando tu Cashback...",
                recipientAddress: _destinationWallet, 
                expectedTxType: "SEND_FIAT", 
                onUpdateBalance: widget.onUpdateBalance 
              )));

              String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
              final res = await txService.sendTokensFiat(_destinationWallet, orderId, monto);
              
              if (res.startsWith("Error")) { 
                if (mounted) Navigator.pop(context, false); 
                widget.mostrarMensaje(res, esError: true); 
              } else {
                String txHashResult = res.replaceAll("Exito: ", "").trim();
                if (widget.debtId != null) await debtService.payPersonalDebt(widget.debtId!, monto, _destinationWallet);
                if (widget.sharedDebtId != null) await debtService.notifySharedDebtContribution(widget.sharedDebtId!, monto);

                // Esperamos la confirmación del WebSocket
                final result = await pendingFuture;

                if (result == true) {
                  await _manejarFlujoPostPago('SEND_FIAT', monto, txHashResult);
                }
              }
            });
          },
          onError: (error) { widget.mostrarMensaje("Error en PayPal: $error", esError: true); },
          onCancel: (params) { widget.mostrarMensaje("Pago cancelado en PayPal", esError: true); },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1Search(),
            _buildStep2Verify(),
            _buildStep3Pay(),
          ],
        ),
      ),
    );
  }
}