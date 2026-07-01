import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
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

  final DateTime _screenOpenTime = DateTime.now();
  
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

  // void _forzarExitoLocal() async {
  //   _fallbackTimer?.cancel();
  //   _wsChannel?.sink.close();
  //   setState(() => _isSuccess = true);
    
  //   await Future.delayed(const Duration(milliseconds: 2000));

  //   final cacheService = LocalCacheService();
    
  //   await cacheService.clearDashboardCache(); 
    
  //   if (widget.expectedTxType == 'SEND' || 
  //       widget.expectedTxType == 'BINANCE_PAY' || 
  //       widget.expectedTxType == 'SEND_FIAT' || 
  //       widget.expectedTxType == 'BUY' || 
  //       widget.expectedTxType == 'BUY_FIAT') {
  //     await cacheService.clearTransactionsCache();
  //   }
  //   if (widget.expectedTxType == 'STAKE' || widget.expectedTxType == 'UNSTAKE' || widget.expectedTxType == 'WITHDRAW') {
  //     await cacheService.clearVaultsCache();
  //   }
  //   if (widget.expectedTxType == 'SHARE_DEBT') {
  //     await cacheService.clearDebtsCache();
  //   }

  //   widget.onUpdateBalance?.call(); 
    
  //   if (widget.isGroupPayment) {
  //     if (mounted) Navigator.pop(context, true);
  //     return;
  //   }

  //   if (mounted) {
  //     Navigator.pop(context, true); 
  //   }
  // }

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

  // void _startFallbackTimer() async {
  //   await Future.delayed(const Duration(seconds: 4));
  //   if (!mounted) return;

  //   _fallbackTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
  //     _intentos++;
  //     if (_intentos >= 4) {
  //        _forzarExitoLocal();
  //        return;
  //     }
      
  //     if (_isFetchingRPC) return;
  //     _isFetchingRPC = true;

  //     try {
  //       final txs = await txService.getTransactionHistory();
  //       if (txs.isNotEmpty) {
  //         final latestTx = txs.first;
  //         final status = latestTx['status'] ?? 'UNKNOWN';
  //         final txType = latestTx['txType'] ?? '';

  //         if (widget.expectedTxType != null && txType != widget.expectedTxType) {
  //           _isFetchingRPC = false;
  //           return; 
  //         }
          
  //         if (status == 'COMPLETED') {
  //           _forzarExitoLocal();
  //         } else if (status == 'FAILED') {
  //           _forzarFalloLocal();
  //         }
  //       }
  //     } catch (e) {
  //       print("Error en fallback RPC: $e");
  //     } finally {
  //       _isFetchingRPC = false; 
  //     }
  //   });
  // }

  void _startFallbackTimer() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    _fallbackTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      _intentos++;
      if (_intentos >= 6) {
         _forzarExitoLocal();
         return;
      }
      
      if (_isFetchingRPC) return;
      _isFetchingRPC = true;

      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final url = "${ApiConfig.getHistory.replaceAll("{address}", authCore.publicAddress.toLowerCase())}?t=$timestamp";
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            ...authCore.authHeaders,
            "Cache-Control": "no-cache" 
          }
        );

        if (response.statusCode == 200) {
          List<dynamic> txs = jsonDecode(response.body);
          if (txs.isNotEmpty) {
            final latestTx = txs.first;
            
            DateTime txTime = DateTime.parse(latestTx['timestamp'].toString()).toLocal();
            
            if (txTime.isBefore(_screenOpenTime.subtract(const Duration(minutes: 2)))) {
              _isFetchingRPC = false;
              return; 
            }

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
        }
      } catch (e) {
        print("Error en fallback RPC directo: $e");
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
            _cerrarPantallaError(); 
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
                ? _buildErrorView(colorScheme.onSurface, theme) 
                : _isSuccess
                    ? _buildSuccessView(colorScheme.onSurface)
                    : _buildProcessingView(colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView(Color onSurfaceColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutBack,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    height: 60, width: 60,
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 6, strokeCap: StrokeCap.round),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            widget.customTitle ?? "Procesando", 
            style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.customMessage ?? "Asegurando en la Blockchain. Por favor, no cierres la app.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(Color onSurfaceColor) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
              border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                ),
                const SizedBox(height: 24),
                Text("¡Éxito Total!", style: TextStyle(color: onSurfaceColor, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text("Transacción confirmada.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(Color onSurfaceColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.15), blurRadius: 40, spreadRadius: 5)],
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 70),
          ),
          const SizedBox(height: 24),
          Text("Transacción Fallida", style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 14, height: 1.4)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Volver a intentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _cerrarPantallaError,
            ),
          )
        ],
      ),
    );
  }
}