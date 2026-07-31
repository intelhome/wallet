import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/main_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import '../../groups_and_social/screens/add_contact_screen.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import '../../../config/api_config.dart';

class TransactionPendingScreen extends StatefulWidget {
  //final BlockchainService service;
  final String? customTitle;
  final String? customMessage;
  final String? recipientAddress;
  final VoidCallback? onUpdateBalance;

  final String? expectedTxType;
  final bool isGroupPayment; // 🔥 SE AGREGÓ PARA CONTROLES GRUPALES

  const TransactionPendingScreen({
    super.key,
    this.customTitle,
    this.customMessage,
    this.recipientAddress,
    this.onUpdateBalance,
    this.expectedTxType,
    this.isGroupPayment = false,
  });

  @override
  State<TransactionPendingScreen> createState() =>
      _TransactionPendingScreenState();
}

class _TransactionPendingScreenState extends State<TransactionPendingScreen> {

  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  
  Timer? _fallbackTimer;
  IOWebSocketChannel? _wsChannel;
  bool _isSuccess = false;
  bool _isFetchingRPC = false;
  int _intentos = 0;
  bool _isFailed = false;
  String _errorMessage = "La transacción no pudo ser procesada.";

  @override
  void initState() {
    super.initState();
    _conectarWSTransactions();
  }

  Future<bool> _isContactAlreadySaved(String addressToVerify) async {
    try {
      String myAddress = authCore.publicAddress.toLowerCase();
      String endpoint = ApiConfig.getContacts.replaceAll(
        "{address}",
        myAddress,
      );

      final res = await http.get(
        Uri.parse(endpoint),
        // 🔥 FIX 3: Añadimos el token al buscar contactos
        headers: {
          if (authCore.jwtToken != null)
            "Authorization": "Bearer ${authCore.jwtToken}",
        },
      );

      if (res.statusCode == 200) {
        List<dynamic> contacts = jsonDecode(res.body);
        for (var contact in contacts) {
          if (contact['contactAddress'].toString().toLowerCase() ==
              addressToVerify.toLowerCase()) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("Error verificando contactos en segundo plano: $e");
      return false;
    }
  }
  void _forzarExitoLocal() async {
    _fallbackTimer?.cancel();
    _wsChannel?.sink.close();
    setState(() => _isSuccess = true);
    
    await Future.delayed(const Duration(milliseconds: 2000));
    widget.onUpdateBalance?.call(); 

    mainScreenKey.currentState?.forceDashboardRefresh();
    
    // 🔥 Si es un pago de splitwise/grupos, SOLO RETROCEDEMOS, ¡NO popHastaFirst!
    if (widget.isGroupPayment) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // if (mounted) {
    //   if (widget.recipientAddress != null && widget.recipientAddress!.isNotEmpty && widget.recipientAddress != "STAKE_CONTRACT") {
    //     bool yaExiste = await _isContactAlreadySaved(widget.recipientAddress!);
    //     if (!mounted) return;
    //     if (!yaExiste) {
    //       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddContactScreen(addressToSave: widget.recipientAddress!)));
    //     } else {
    //       Navigator.of(context).popUntil((route) => route.isFirst);
    //     }
    //   } else {
    //     Navigator.of(context).popUntil((route) => route.isFirst);
    //   }
    // }
    if (mounted) {
      // 🔥 FIX: Ya no destruimos la pila de navegación. 
      // Solo cerramos esta pantalla y le avisamos a SendModal que fue un ÉXITO (true).
      Navigator.pop(context, true); 
    }
  }

  void _conectarWSTransactions() async {
    try {
      final wsUrl = "${ApiConfig.wsTransactionsUpdates}/${authCore.publicAddress}";
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          if (authCore.jwtToken != null) 
            "Authorization": "Bearer ${authCore.jwtToken}"
        }
      );

      _wsChannel!.stream.listen((message) {
        print("WS Transaction Event: $message");
        if (message == "COMPLETED"|| message == "UPDATE_DEBTS") {
          _forzarExitoLocal();
        } else if (message == "FAILED") {
          _forzarFalloLocal();
        }
      }, onError: (err) {
        print("WS Error: $err");
      }, onDone: () {
        print("WS Transacciones cerrado");
      });
    } catch (e) {
      print("Error iniciando WS: $e");
    }

    _startFallbackTimer();
  }

void _forzarFalloLocal({String? motivo}) {
    _fallbackTimer?.cancel();
    _wsChannel?.sink.close();
    
    if (mounted) {
      setState(() {
        _isFailed = true;
        if (motivo != null) _errorMessage = motivo;
      });
    }
  }

  void _cerrarPantallaError() {
    Navigator.pop(context, false);
    // 🔥 Conservamos tu lógica de rutas segura
    // if (widget.isGroupPayment) {
    //   Navigator.pop(context);
    // } else {
    //   Navigator.of(context).popUntil((route) => route.isFirst);
    // }
  }

  void _startFallbackTimer() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    _fallbackTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      _intentos++;
      if (_intentos >= 4) {
         _forzarExitoLocal();
         return;
      }
      
      if (_isFetchingRPC) return;
      _isFetchingRPC = true;

      try {
        final txs = await txService.getTransactionHistory();
        if (txs.isNotEmpty) {
          final latestTx = txs.first;
          final status = latestTx['status'] ?? 'UNKNOWN';
          final txType = latestTx['txType'] ?? '';

          if (widget.expectedTxType != null && txType != widget.expectedTxType) {
            _isFetchingRPC = false;
            return; 
          }
          
          if (status == 'COMPLETED') {
            _forzarExitoLocal();
          } else if (status == 'FAILED') {
            _forzarFalloLocal();
          }
        }
      } catch (e) {
        print("Error en fallback RPC: $e");
      } finally {
        _isFetchingRPC = false; 
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _wsChannel?.sink.close(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
       if (_isFailed) {
            _cerrarPantallaError(); // Si ya falló, permitimos que el botón de retroceso lo cierre
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
               content: const Text("Transacción en proceso, por favor espere.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               backgroundColor: theme.colorScheme.secondary,
              )
            );
          }
        }
      },
     child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isFailed 
                ? _buildErrorView(colorScheme.onSurface, theme) // 🔥 NUEVA VISTA DE ERROR
                : _isSuccess
                    ? _buildSuccessView(colorScheme.onSurface)
                    : _buildProcessingView(colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView(Color onSurfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 80, width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFBAC3FF), shape: BoxShape.circle)),
                const CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A2E3D))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(widget.customTitle ?? "Minando Tokens", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(widget.customMessage ?? "Acreditando tus fondos en la\nBlockchain...", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.4)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF1E2336), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt_rounded, color: Color(0xFFBAC3FF), size: 16),
                SizedBox(width: 8),
                Text("GASLESS TRANSACTION ACTIVE", style: TextStyle(color: Color(0xFFBAC3FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildProcessingView(Color onSurfaceColor) {
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 500),
  //     curve: Curves.easeInOut,
  //     padding: const EdgeInsets.all(32),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).cardColor,
  //       borderRadius: BorderRadius.circular(32),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
  //           blurRadius: 40,
  //           spreadRadius: 10,
  //           offset: const Offset(0, 10),
  //         )
  //       ],
  //       border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1.5),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         TweenAnimationBuilder(
  //           tween: Tween<double>(begin: 0.8, end: 1.2),
  //           duration: const Duration(seconds: 1),
  //           curve: Curves.easeInOutBack,
  //           builder: (context, double scale, child) {
  //             return Transform.scale(
  //               scale: scale,
  //               child: Container(
  //                 padding: const EdgeInsets.all(24),
  //                 decoration: BoxDecoration(
  //                   color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: SizedBox(
  //                   height: 60, width: 60,
  //                   child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 6, strokeCap: StrokeCap.round),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //         const SizedBox(height: 32),
  //         Text(
  //           widget.customTitle ?? "Procesando", 
  //           style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           widget.customMessage ?? "Asegurando en la Blockchain. Por favor, no cierres la app.", 
  //           textAlign: TextAlign.center,
  //           style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSuccessView(Color onSurfaceColor) {
    String recipient = widget.recipientAddress ?? "0x...";
    String shortRecipient = recipient.length > 10 ? "${recipient.substring(0, 6)}...${recipient.substring(recipient.length - 4)}" : recipient;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Círculos concéntricos de éxito
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.1), width: 2)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 2)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text("¡Éxito Total!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Transacción confirmada correctamente.", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
        const SizedBox(height: 40),
        
        // Tarjeta de detalles
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Monto", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                  const Text("-- TTC", style: TextStyle(color: Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Destinatario", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      SmartAvatar(address: recipient, size: 20),
                      const SizedBox(width: 8),
                      Text(shortRecipient, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hash de Transacción", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text("Confirmado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_rounded, color: Colors.white.withOpacity(0.5), size: 16),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF1E2336), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text("0.00 Gas (Gasless)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(Color onSurfaceColor, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xFFFFA3A3), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFFFA3A3).withOpacity(0.2), blurRadius: 40)]),
          child: const Icon(Icons.close_rounded, color: Color(0xFF8C1D18), size: 64),
        ),
        const SizedBox(height: 32),
        const Text("Transacción Fallida", style: TextStyle(color: Color(0xFFFFA3A3), fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          "Hubo un error al procesar tu operación. Por\nfavor, verifica tus fondos e intenta de nuevo.", 
          textAlign: TextAlign.center, 
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.4)
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFF1E2336), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 18),
              const SizedBox(width: 10),
              Text(_errorMessage.length > 30 ? "Código de Error: TX-042" : _errorMessage, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBAC3FF), foregroundColor: const Color(0xFF00218d), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            onPressed: _cerrarPantallaError,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Reintentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {}, 
          icon: const Text("Contactar Soporte", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          label: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white70),
        )
      ],
    );
  }

  // Widget _buildSuccessView(Color onSurfaceColor) {
  //   return TweenAnimationBuilder(
  //     tween: Tween<double>(begin: 0.0, end: 1.0),
  //     duration: const Duration(milliseconds: 600),
  //     curve: Curves.elasticOut,
  //     builder: (context, double value, child) {
  //       return Transform.scale(
  //         scale: value,
  //         child: Container(
  //           padding: const EdgeInsets.all(32),
  //           decoration: BoxDecoration(
  //             color: Theme.of(context).cardColor,
  //             borderRadius: BorderRadius.circular(32),
  //             boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
  //             border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(20),
  //                 decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
  //                 child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
  //               ),
  //               const SizedBox(height: 24),
  //               Text("¡Éxito Total!", style: TextStyle(color: onSurfaceColor, fontSize: 26, fontWeight: FontWeight.w900)),
  //               const SizedBox(height: 8),
  //               Text("Transacción confirmada.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 16)),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _buildErrorView(Color onSurfaceColor, ThemeData theme) {
  //   return Container(
  //     padding: const EdgeInsets.all(32),
  //     decoration: BoxDecoration(
  //       color: theme.cardColor,
  //       borderRadius: BorderRadius.circular(32),
  //       boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.15), blurRadius: 40, spreadRadius: 5)],
  //       border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
  //           child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 70),
  //         ),
  //         const SizedBox(height: 24),
  //         Text("Transacción Fallida", style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.w900)),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
  //           child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 14, height: 1.4)),
  //         ),
  //         const SizedBox(height: 32),
  //         SizedBox(
  //           width: double.infinity, height: 56,
  //           child: ElevatedButton.icon(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
  //               elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
  //             ),
  //             icon: const Icon(Icons.refresh_rounded),
  //             label: const Text("Volver a intentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //             onPressed: _cerrarPantallaError,
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }
}