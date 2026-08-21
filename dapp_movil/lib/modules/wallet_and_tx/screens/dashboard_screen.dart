import 'dart:convert';

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/PremiumBlockerModal.dart';
import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/user_card.dart';
import 'package:dapp_movil/modules/ai_assistant/screens/ai_assistant_deepseek_screen.dart';
import 'package:dapp_movil/modules/ai_assistant/screens/ai_assistant_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/memberships_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/burner_wallets/screens/burner_wallets_screen.dart';
import 'package:dapp_movil/modules/business/screens/admin_burner_history_screen.dart';
import 'package:dapp_movil/modules/business/screens/employee_management_screen.dart';
import 'package:dapp_movil/modules/business/screens/job_invites_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_admin_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_details_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_employee_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_history_screen.dart';
import 'package:dapp_movil/modules/business/screens/team_management_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/debts_and_payments_hub_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/debts_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/scheduled_payments_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/split_bill_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/document_notary/screens/document_notary_screen.dart';
import 'package:dapp_movil/modules/document_notary/screens/document_validator_screen.dart';
import 'package:dapp_movil/modules/document_notary/screens/hash_validator_screen.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/contacts_screen.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/social_screen.DART';
import 'package:dapp_movil/modules/settings_and_profile/modals/web3_id_card_modal.dart';
import 'package:dapp_movil/modules/settings_and_profile/screens/notifications_screen.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/screens/vaults_screen.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_paypal_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/paypal_payment_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/request_money_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/send_flow_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/withdraw_fiat_screen.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../modals/send_modal.dart';
import '../../vaults_and_savings/modals/stake_modal.dart';
import '../modals/buy_modal.dart';
import '../screens/buy_screen.dart';
import '../../vaults_and_savings/screens/stake_screen.dart';
import '../../auth_and_security/screens/splash_screen.dart';
import '../../../core/services/app_drawer.dart';
import '../modals/receive_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/screens/app_lock_screen.dart';
import '../../settings_and_profile/screens/settings_screen.dart';
import '../../../core/notifications/push_notification_service.dart';
import 'package:app_links/app_links.dart';

class DashboardApp extends StatefulWidget {
 // final BlockchainService service;
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp>
    with WidgetsBindingObserver {

      AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
SmartVaultService get vaultService => Provider.of<SmartVaultService>(context, listen: false);
UserService get userService => Provider.of<UserService>(context, listen: false);

  String _balanceTTC = "0.000";
  String _stakedTTC = "0.000";
  String _ethPriceUSD = "0.000";
  String _balanceETH = "0.0000";
  String _aliasUsuario = "Cargando...";
  final String _avaxPriceUSD = "0.000";
  String _miAlias = "Mi cartera";
  bool _isSyncing = true;
  bool _retiroListoParaReclamar = false;
  Timer? _redDotTimer;
  DateTime? _backgroundTime;
  bool _isLockScreenOpen = false;

  double _presupuestoMensual = 500.0;
  double _gastadoMes = 0.0;

  bool _isReadyForNotifications = false;
  late TransactionService _txServiceCached;

  Future<List<dynamic>>? _debtsFuture;
 DebtService get debtService => Provider.of<DebtService>(context, listen: false);
late AppLinks _appLinks;
StreamSubscription<Uri>? _sub; 

  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appLinks = AppLinks();

    _cargarCacheLocal();

    _cargarBalance();

    _iniciarEscuchadorDeDeepLinks();
    _txServiceCached = Provider.of<TransactionService>(context, listen: false);
   // _initNotifications();
   

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _isReadyForNotifications = true;
    });

    txService.listenToTransfers((bool isReceiver, String fromAddress) async {
      if (isReceiver && _isReadyForNotifications) {
        
        // 🔥 FIX: 1. Leemos la configuración actual del usuario desde el Backend
       try {
          final userData = await userService.getUserByWallet(authCore.publicAddress);
          if (userData != null) {
            bool pushHabilitado = userData['notifyPush'] ?? true;
            
            if (!pushHabilitado) {
              print("Notificación ignorada: El usuario desactivó las notificaciones PUSH.");
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) _cargarBalance();
              });
              return; 
            }
          }
        } catch (e) {
          print("Error al verificar preferencias de notificación: $e");
        }

        // 🔥 3. Si pasó las validaciones, mostramos la alerta normal
        String titulo = "¡Fondos Recibidos! 💸";
        String mensaje = "Acabas de recibir una transferencia de TTC.";

        if (fromAddress.contains("da170adc8b8df87a86fd3518d8d69bdba7955e5c") || 
            fromAddress.contains("0c1703518b106924ced490b7764e2e2b3cdfe83a") || 
            fromAddress.toLowerCase().contains("system")) {
          titulo = "¡Tokens Acreditados! 🌟";
          mensaje = "Tus tokens han sido procesados en la blockchain (Compra / Cashback).";
        }

        PushNotificationService.showLocalNotification(titulo, mensaje);
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _cargarBalance();
      });
    });
  }

  //   @override
  // void dispose() {
  //   _sub?.cancel();
  //   WidgetsBinding.instance.removeObserver(this); // Limpiar el observador
  //   _redDotTimer?.cancel(); // Limpiar el reloj del punto rojo

  //   txService.stopListening();
  //   super.dispose();
  // }

@override
  void dispose() {
    _sub?.cancel();
    WidgetsBinding.instance.removeObserver(this); // Limpiar el observador
    _redDotTimer?.cancel(); // Limpiar el reloj del punto rojo

    // 🔥 CAMBIO CRÍTICO: Usar la variable cacheada en lugar del getter
    _txServiceCached.stopListening(); 
    
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);

        // 🔥 Si pasaron más de 30 segundos y la pantalla de bloqueo NO está abierta
        if (diff.inSeconds > 30 && !_isLockScreenOpen) {
          _isLockScreenOpen = true;

          // rootNavigator: true asegura que se muestre por encima de modales inferiores
          Navigator.of(context, rootNavigator: true)
              .push(
                MaterialPageRoute(
                  builder: (_) => AppLockScreen(authCore: authCore),
                ),
              )
              .then((_) {
                // Cuando la pantalla de bloqueo se cierra con éxito, reiniciamos la bandera
                _isLockScreenOpen = false;
                _cargarBalance(); // Opcional: Refresca datos al volver
              });
        }
        _backgroundTime = null;
      }
    }
  }

  void _abrirTarjetaWeb3() {
    Web3IdCardModal.show(
      context: context,
      alias: _miAlias, // Usamos el alias que ya tienes cargado en memoria
      address: authCore.publicAddress,
      onScanResult: (String result) {
        // Si el QR tiene formato de link (ej. ttcwallet://pay?to=@juan)
        if (result.startsWith('ttcwallet://')) {
          _procesarLinkDePago(Uri.parse(result));
        } else {
          // Si por error escaneó solo un alias plano ("@juan")
          _procesarLinkDePago(Uri.parse('ttcwallet://pay?to=$result'));
        }
      }
    );
  }

Future<void> _iniciarEscuchadorDeDeepLinks() async {
    _appLinks = AppLinks();

    try {
      // 1. Si la app estaba CERRADA por completo y se abrió con el link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _procesarLinkDePago(initialUri);

      // 2. Si la app estaba MINIMIZADA en segundo plano
      _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) _procesarLinkDePago(uri);
      }, onError: (err) {
        print("Error escuchando link: $err");
      });
    } catch (e) {
      print("Error iniciando AppLinks: $e");
    }
  }
  Future<void> _procesarLinkDePago(Uri uri) async {
    // Validamos que sea ttcwallet://pay
    if (uri.scheme == 'ttcwallet' && uri.host == 'pay') {
      String destinatario = uri.queryParameters['to'] ?? '';
      String monto = uri.queryParameters['amount'] ?? '0';

      if (destinatario.isEmpty) return;

      // 🔥 BUENAS PRÁCTICAS: Validamos la identidad en el backend antes de mostrar la UI
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator())
      );

      final payeeInfo = await userService.fetchPayeeInfo(destinatario);
      
      if (mounted) Navigator.pop(context); // Quitamos el loading

      if (payeeInfo != null) {
        String aliasReal = "@${payeeInfo['alias']}";

        // 🔥 ¡Magia! Abrimos tu SendModal integrando tus variables de estado reales
        SendModal.show(
          context: context,
          balanceTTC: _balanceTTC, // Usamos tu variable de estado real
          initialAddress: aliasReal, // Mostramos el Alias por UX (ej: @juan)
          initialAmount: monto,
          onUpdateBalance: _cargarBalance, // Usamos tu método real de refresco
          mostrarMensaje: _mostrarMensaje, // Usamos tu método real de SnackBars
        );
      } else {
        _mostrarMensaje("Enlace inválido o usuario no registrado.", esError: true);
      }
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar saldos
      final saldo = await txService.getBalance();
      final staked = await vaultService.getStakedBalance();

      // 🔥 REFACTORIZADO: OBTENER EL ALIAS DEL USUARIO USANDO EL SERVICIO 🔥
      String aliasFetch = "Usuario";
      final userData = await userService.getUserByWallet(authCore.publicAddress);
      if (userData != null && userData['alias'] != null) {
        aliasFetch = userData['alias'];
      }

      if (mounted) {
        setState(() {
          _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3);
          _stakedTTC = (double.tryParse(staked) ?? 0.0).toStringAsFixed(3);
          _aliasUsuario = aliasFetch;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _aliasUsuario = "Usuario");
      print("Error cargando datos del dashboard: $e");
    }
  }

  // Future<void> _cargarCacheLocal() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   if (mounted) {
  //     setState(() {
  //       _balanceTTC = prefs.getString('cache_balanceTTC') ?? "0.000";
  //       _stakedTTC = prefs.getString('cache_stakedTTC') ?? "0.000";
  //       _ethPriceUSD = prefs.getString('cache_ethPriceUSD') ?? "0.000";
  //       _balanceETH = prefs.getString('cache_balanceETH') ?? "0.0000";
  //       _miAlias = prefs.getString('cache_alias') ?? "Mi cartera";

  //       // Si encontramos caché, quitamos la pantalla de carga INMEDIATAMENTE
  //       if (_balanceTTC != "0.000" || _miAlias != "Mi cartera") {
  //         _isSyncing = false;
  //       }
  //     });
  //   }
  // }

Future<void> _cargarCacheLocal() async {
    final cacheService = LocalCacheService();
    final data = cacheService.getCachedDashboardData();

    if (mounted && data.isNotEmpty) {
      setState(() {
        _balanceTTC = data['balanceTTC'] ?? "0.000";
        _stakedTTC = data['stakedTTC'] ?? "0.000";
        _ethPriceUSD = data['ethPriceUSD'] ?? "0.000";
        _balanceETH = data['balanceETH'] ?? "0.0000";
        _miAlias = data['alias'] ?? "Mi cartera";
        _isSyncing = false; // Apaga loader al instante
      });
    }
  }
  
  void _evaluarPuntoRojo(double montoPend, int unlockTime) {
    _redDotTimer?.cancel(); // Cancelamos cualquier reloj anterior

    if (montoPend > 0) {
      int ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (ahora >= unlockTime) {
        setState(() => _retiroListoParaReclamar = true);
      } else {
        setState(() => _retiroListoParaReclamar = false);
        // Creamos un reloj que "despertará" exactamente cuando pasen los minutos faltantes
        int delay = unlockTime - ahora;
        _redDotTimer = Timer(Duration(seconds: delay), () {
          if (mounted) setState(() => _retiroListoParaReclamar = true);
        });
      }
    } else {
      setState(() => _retiroListoParaReclamar = false);
    }
  }

  final cacheService = LocalCacheService();

  // Future<void> _cargarBalance() async {
  //   final results = await Future.wait([
  //     txService.getBalance(),
  //     vaultService.getStakedBalance(),
  //     txService.getEthPriceInUsd(),
  //     txService.getEthBalance(),
  //   ]);

  //   if (!mounted) return;

  //   final saldo = results[0];
  //   final stake = results[1];
  //   final currentEthPrice = results[2];
  //   final saldoEth = results[3];

  //   if (mounted) {
  //     setState(() {
  //       _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3);
  //       _stakedTTC = stake;
  //       _ethPriceUSD = currentEthPrice;
  //       _balanceETH = saldoEth;
  //     });
  //   }

  //   try {
  //     // 🔥 REFACTORIZADO: Obtenemos el alias limpiamente usando UserService 🔥
  //     final userData = await userService.getUserByWallet(authCore.publicAddress);

  //     if (!mounted) return;

  //     if (userData != null && userData['alias'] != null) {
  //       setState(() {
  //         _miAlias = "@" + userData['alias'];
  //       });
  //     }

  //     final pendingData = await vaultService.getPendingWithdrawal();

  //     if (!mounted) return;
      
  //     double montoPend = (pendingData['amount'] as num).toDouble();
  //     int unlockTime = pendingData['unlockTime'] as int;

  //     if (mounted) {
  //       _evaluarPuntoRojo(montoPend, unlockTime);
  //     }

  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('cache_balanceTTC', _balanceTTC);
  //     await prefs.setString('cache_stakedTTC', _stakedTTC);
  //     await prefs.setString('cache_ethPriceUSD', _ethPriceUSD);
  //     await prefs.setString('cache_balanceETH', _balanceETH);
  //     await prefs.setString('cache_alias', _miAlias);
  //   } catch (e) {
  //     print("Error sincronizando: $e");
  //   } finally {
  //     // Apagamos la pantalla de carga sin importar si hubo éxito o error
  //     if (mounted) {
  //       setState(() {
  //         _isSyncing = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _cargarBalance() async {
    if (mounted) {
      setState(() {
        _isSyncing = true; 
      });
    }

    final results = await Future.wait([
      txService.getBalance(),
      vaultService.getStakedBalance(),
      txService.getEthPriceInUsd(),
      txService.getEthBalance(),
    ]);

    if (!mounted) return;

    final saldo = results[0];
    final stake = results[1];
    final currentEthPrice = results[2];
    final saldoEth = results[3];

    if (mounted) {
      setState(() {
        _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3);
        _stakedTTC = stake;
        _ethPriceUSD = currentEthPrice;
        _balanceETH = saldoEth;
      });
    }

    try {
      // 🔥 REFACTORIZADO: Obtenemos el alias limpiamente usando UserService 🔥
      final userData = await userService.getUserByWallet(authCore.publicAddress);

      final prefs = await SharedPreferences.getInstance();
      double presupuesto = prefs.getDouble('presupuesto_mensual') ?? 500.0;



      double gastado = 0.0;
      try {
        final txs = await txService.getTransactionHistory();
        final myWallet = authCore.publicAddress.toLowerCase();
        final now = DateTime.now();

        for (var tx in txs) {
          if (tx['status'] == 'COMPLETED' &&
              (tx['txType'] == 'SEND' || tx['txType'] == 'BINANCE_PAY' || tx['txType'] == 'SEND_FIAT') &&
              tx['senderAddress']?.toString().toLowerCase() == myWallet) {
             
             if (tx['timestamp'] != null) {
               DateTime txDate = DateTime.parse(tx['timestamp'].toString()).toLocal();
               // Sumar solo si es del mes y año actual
               if (txDate.month == now.month && txDate.year == now.year) {
                 gastado += double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
               }
             }
          }
        }
      } catch (e) {
        print("Error calculando gastos del historial: $e");
      }


      if (!mounted) return;

      if (userData != null && userData['alias'] != null) {
        setState(() {
          _miAlias = "@" + userData['alias'];
        });
      }

      setState(() {
         _presupuestoMensual = presupuesto;
        _gastadoMes = gastado;
      });

      final pendingData = await vaultService.getPendingWithdrawal();

      

      if (!mounted) return;
      
      double montoPend = (pendingData['amount'] as num).toDouble();
      int unlockTime = pendingData['unlockTime'] as int;

      if (mounted) {
        _evaluarPuntoRojo(montoPend, unlockTime);
      }

      // 🔥 REFACTORIZADO: Guardando la información usando Hive (LocalCacheService)
      final cacheService = LocalCacheService();
      await cacheService.saveDashboardData({
        'balanceTTC': _balanceTTC,
        'stakedTTC': _stakedTTC,
        'ethPriceUSD': _ethPriceUSD,
        'balanceETH': _balanceETH,
        'alias': _miAlias,
      });
      
    } catch (e) {
      print("Error sincronizando: $e");
    } finally {
      // Apagamos la pantalla de carga sin importar si hubo éxito o error
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: esError ? Colors.red.shade800 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _copiarDireccion() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: authCore.publicAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Dirección copiada al portapapeles!')),
    );
  }

  void _borrarCarteraConfirmacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Borrar cartera DEFINITIVAMENTE?"),
        content: const Text(
          "Si continuas se borrara tu cartera y perderas todos tus fondos en ella si no tienes respaldo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Cierra el diálogo
              await authCore.deleteWallet();
              if (!mounted) return;
              // Volvemos al router para que detecte que no hay cartera y pida crear una
              Navigator.pushReplacement(
                context,
                RouteHelper.fadeRoute(const InitialRouter()),
              );
            },
            child: const Text("SÍ, BORRAR"),
          ),
        ],
      ),
    );
  }

  void _abrirModalComprar() {
    Navigator.push(
      context,
      RouteHelper.slideUpRoute(
        BuyScreen(
          onUpdateBalance: _cargarBalance,
          mostrarMensaje: _mostrarMensaje,
        )
      )
    );
  }

  // void _abrirModalEnviar() {
  //   SendModal.show(
  //     context: context,
  //     balanceTTC: _balanceTTC,
  //     onUpdateBalance: _cargarBalance,
  //     mostrarMensaje: _mostrarMensaje,
  //   );
  // }

  void _abrirModalEnviar() {
    Navigator.push(
      context,
      RouteHelper.slideUpRoute(
        SendFlowScreen(
          balanceTTC: _balanceTTC,
          onUpdateBalance: _cargarBalance,
          mostrarMensaje: _mostrarMensaje,
        )
      )
    );
  }

  void _abrirModalStake() {
    Navigator.push(
      context,
      RouteHelper.slideUpRoute(
        StakeScreen(
          balanceTTC: _balanceTTC,
          stakedTTC: _stakedTTC,
          onUpdateBalance: _cargarBalance,
          mostrarMensaje: _mostrarMensaje,
        )
      )
    );
  }

  void _abrirModalRecibir() {
    ReceiveModal.show(
      context: context,
    );
  }

  void _toggleDiscreetMode() async {
    // Si está oculto y el usuario quiere ver sus saldos, EXIGIMOS biometría
    if (discreetModeNotifier.value == true) {
      bool auth = await authCore.authenticateUser();
      if (!auth) {
        _mostrarMensaje("Autenticación cancelada", esError: true);
        return; // Si cancela la huella, NO revelamos el saldo
      }
    }

    // Cambiamos el estado global
    discreetModeNotifier.value = !discreetModeNotifier.value;

    // Guardamos en la memoria del teléfono
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('discreetMode', discreetModeNotifier.value);
  }

  void _abrirPantallaRetiro() {
    Navigator.push(
      context,RouteHelper.slideUpRoute(WithdrawFiatScreen(
           balanceTTC: _balanceTTC, // El saldo que ya tienes cargado en el Dashboard
          onUpdateBalance: _cargarDatos, // Tu función que refresca los saldos
        ))
    );
  }

  void _abrirPantallaEmpresas(){
    Navigator.push(
      context,RouteHelper.slideUpRoute(TeamManagementScreen(
        ))
    );
  }

   void _abrirPantallaEmpresasInvitacion(){
    Navigator.push(
      context,RouteHelper.slideUpRoute(JobInvitesScreen(
        ))
    );
  }

     void _abrirPantallaTaskUsuario(){
    Navigator.push(
      context,RouteHelper.slideUpRoute(TaskEmployeeScreen(
        ))
    );
  }

  void _abrirPantallaPagosDivididos(){
  Navigator.push(
    context,
    RouteHelper.slideUpRoute(
      SplitBillScreen(
        onBillSplitSuccess: () {
          // 🔥 Aquí llamas a la función que recarga tu lista de deudas/facturas
          _cargarDeudas(); 
        },
      ),
    ),
  );
}

//  void _abrirPantallaPaypal() {
//   SendPaypalModal.show(
//     context: context,
//     onSuccess: () {
//       // Aquí llamas a tu función para recargar el saldo o historial del Dashboard
//        _cargarBalance();
//       print("Pago PayPal completado, refrescando Dashboard");
//     },
//   );
// }

void _abrirPantallaPaypal() async {
    // 1. Verificamos SI NOSOTROS (el que paga/cobra) tenemos PayPal habilitado
    final userService = Provider.of<UserService>(context, listen: false);
    final myStatus = await userService.checkPayeePayPal(authCore.publicAddress);

    // Si nos dice que es false (no activo) o nulo
    if (myStatus == null || myStatus['paypalEnabled'] != true) {
      
      // 2. Le preguntamos si desea configurarlo AHORA
      bool? goSettings = await UIHelper.mostrarConfirmacion(
        context: context, 
        titulo: "PayPal no configurado", 
        mensaje: "Para poder utilizar la pasarela P2P de PayPal, debes vincular tu correo primero en las configuraciones de seguridad de forma encriptada.\n\n¿Deseas configurarlo ahora?", 
        textoConfirmar: "Ir a Configuración", 
        colorConfirmar: Colors.blueAccent
      );

      if (goSettings == true && mounted) {
        // 3. Abrimos SettingsScreen y le pasamos una GlobalKey para llamar a su método interno
        final GlobalKey<SettingsScreenState> settingsKey = GlobalKey<SettingsScreenState>();
        
        Navigator.push(context, RouteHelper.slideUpRoute(SettingsScreen(
          key: settingsKey,
          aliasUsuario: _miAlias.replaceAll("@", "")
        )));

        // Le damos un milisegundo a la pantalla para renderizar y disparamos el Focus
        Future.delayed(const Duration(milliseconds: 800), () {
           settingsKey.currentState?.focusOnPayPal();
        });
      }
      return; 
    }

    // Si sí lo tiene activo, abre el modal normal
    SendPaypalModal.show(
      context: context,
      onSuccess: () {
        _cargarBalance();
        print("Pago PayPal completado, refrescando Dashboard");
      },
    );
  }

Widget _buildBudgetTracker() {
    if (_presupuestoMensual <= 0) return const SizedBox.shrink(); 
    
    double progress = (_gastadoMes / _presupuestoMensual).clamp(0.0, 1.0);
    
    Color progressColor = Colors.green;
    if (progress >= 0.9) {
      progressColor = Colors.redAccent;
    } else if (progress >= 0.65) {
      progressColor = Colors.orangeAccent;
    }

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Presupuesto Mensual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
              Text("${_gastadoMes.toStringAsFixed(2)} / ${_presupuestoMensual.toStringAsFixed(0)} TTC", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: progressColor)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress >= 1.0 
              ? "¡Atención! Has superado tu límite mensual." 
              : "Puedes gastar ${(_presupuestoMensual - _gastadoMes).toStringAsFixed(2)} TTC más este mes.",
            style: TextStyle(fontSize: 12, color: progress >= 1.0 ? Colors.redAccent : onSurface.withOpacity(0.5), fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.normal),
          )
        ],
      ),
    );
  }


 void _cargarDeudas() {
    setState(() { _debtsFuture = debtService.getUserDebts(); });
  }

  @override
  Widget build(BuildContext context) {
     final planConfig = Provider.of<PlanConfigService>(context);
    final authCore = Provider.of<AuthCoreService>(context);
    final bool isBusiness = authCore.role == 'ROLE_BUSINESS' || authCore.role == 'ROLE_ADMIN';
    final currentTier = authCore.currentTier;
    double balanceNum = double.tryParse(_balanceTTC) ?? 0.000;
    double precioEth = double.tryParse(_ethPriceUSD) ?? 0.000;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
if (_isSyncing) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                UIHelper.buildDashboardSkeleton(context), // 🔥 La tarjeta falsa parpadeante
                const SizedBox(height: 40),
                Expanded(child: UIHelper.buildSkeletonList(context, itemCount: 3)), // 🔥 Botones/Listas falsas
              ],
            ),
          ),
        ),
      );
    }
return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      floatingActionButton: FloatingActionButton(
       // heroTag: 'fab_principal',
       heroTag: 'fab_dashboard_ai',
        backgroundColor: (planConfig.hasFeature(currentTier, 'IA') || isBusiness) ? colorScheme.tertiary : Colors.grey,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        onPressed: () {
       
          if (planConfig.hasFeature(currentTier, 'IA') || isBusiness) {
            Navigator.push(context, RouteHelper.fadeRoute(const AiAssistantDeepSeekScreen()));
          } else {
            PremiumBlockerModal.show(context, planRequerido: "BASIC", featureName: "Asistente Inteligente IA");
          }
        },
        child: Icon(Icons.smart_toy_rounded, color: theme.scaffoldBackgroundColor, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: SafeArea(
        
        child: RefreshIndicator(
          color: colorScheme.primary,
          backgroundColor: theme.cardColor,
          onRefresh: _cargarBalance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Márgenes M3
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // 🔥 HEADER DEL PERFIL 🔥
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(SettingsScreen(aliasUsuario: _miAlias.replaceAll("@", "")))),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2)),
                                child: SmartAvatar(address: authCore.publicAddress, size: 48),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_miAlias.startsWith("@") ? _miAlias : "@$_miAlias", style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _copiarDireccion,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("${authCore.publicAddress.substring(0, 6)}...${authCore.publicAddress.substring(authCore.publicAddress.length - 4)}", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontFamily: 'monospace')),
                                        const SizedBox(width: 6),
                                        Icon(Icons.copy, size: 14, color: colorScheme.primary),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                     IconButton(
                        icon: Icon(Icons.qr_code_scanner_rounded, color: colorScheme.primary, size: 34),
                        onPressed: _abrirTarjetaWeb3,
                      ),

                      IconButton(
                            icon: Icon(Icons.notifications_rounded, color: colorScheme.primary, size: 30),
                            onPressed: () {
                              Navigator.push(context, RouteHelper.slideUpRoute(const NotificationsScreen()));
                            },
                          ),
                        ],
                      ),
                      //boton de notificaciones (próximamente)
                  const SizedBox(height: 32),

                  // 🔥 TARJETA PRINCIPAL DE BALANCE (Premium UI) 🔥

                ValueListenableBuilder<bool>(
                    valueListenable: discreetModeNotifier,
                    builder: (context, isDiscreet, _) {
                      // 🔥 PASO 1: Envolvemos con el segundo ValueListenableBuilder
                      return ValueListenableBuilder<bool>(
                        valueListenable: customCardNotifier,
                        builder: (context, isCustom, _) { 
                          return UserCard(
                            address: authCore.publicAddress,
                            balanceTTC: _balanceTTC,
                            stakedTTC: _stakedTTC,
                            currentTier: authCore.currentTier,
                            isDiscreet: isDiscreet,
                            useAvatarColors: isCustom, 
                            onToggleDiscreet: _toggleDiscreetMode,
                            presupuestoMensual: _presupuestoMensual,
                            gastadoMes: _gastadoMes,
                          );
                        },
                      );
                    }
                  ),

                  // Budget Tracker se removió porque ahora vive en la UserCard

                  const SizedBox(height: 24),
                  Text("Operaciones Rápidas", style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  // 🔥 BOTONES RESPONSIVOS (Evita Overflow) 🔥
                  // Usamos SingleChildScrollView horizontal para que se adapte a cualquier pantalla
                 Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculamos el espacio para forzar exactamente 4 columnas
                        const double spacing = 12.0; 
                        final double itemWidth = (constraints.maxWidth - (spacing * 3)) / 4;
                        
                        // 🔥 Determinamos si es Empresa o Admin para ocultar funcionalidades
                        final authCore = Provider.of<AuthCoreService>(context, listen: false);
                        final isBusiness = (authCore.accountType ?? '').toUpperCase() == "BUSINESS";
                        final isAdmin = (authCore.role ?? '').toUpperCase() == "ROLE_ADMIN";

                return Wrap(
                            spacing: spacing,
                            runSpacing: 24.0, 
                            alignment: WrapAlignment.start, 
                            children: [
                              // --- FILA 1: BÁSICOS ---
                             SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.add_shopping_cart_rounded, texto: "Comprar", 
                                color: (planConfig.hasFeature(currentTier, 'COMPRAR') || isBusiness) ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => (planConfig.hasFeature(currentTier, 'COMPRAR') || isBusiness) ? _abrirModalComprar() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Comprar TTC")
                              )),
                              SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.send_rounded, texto: "Enviar", 
                                color: planConfig.hasFeature(currentTier, 'ENVIAR') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'ENVIAR') ? _abrirModalEnviar() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Enviar Fondos")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.qr_code_rounded, texto: "Recibir", 
                                color: planConfig.hasFeature(currentTier, 'RECIBIR') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'RECIBIR') ? _abrirModalRecibir() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Recibir Fondos")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.account_balance_rounded, texto: "Retirar", 
                                color: planConfig.hasFeature(currentTier, 'RETIRAR') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'RETIRAR') ? _abrirPantallaRetiro() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Retirar Fondos")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.paypal_rounded, texto: "Paypal", 
                                color: planConfig.hasFeature(currentTier, 'PAYPAL') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'PAYPAL') ? _abrirPantallaPaypal() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Pagos por PayPal")
                              )),
                              
                              // Historial general (Para todos)
                              SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.history_rounded, texto: "Historial\nActividades", onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const TaskHistoryScreen())), color: colorScheme.primary)),

                              // --- FILA 2: SOCIAL & PAGOS ---
                             SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.contacts_rounded, texto: "Contactos", 
                                color: planConfig.hasFeature(currentTier, 'CONTACTOS') ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
                                // Cambia const ContactsScreen() a const SocialScreen()
                                onTap: () => planConfig.hasFeature(currentTier, 'CONTACTOS') ? Navigator.push(context, RouteHelper.slideUpRoute(const SocialScreen())) : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Agenda de Contactos")
                              )),
                              // Invitaciones y Tareas de empresa son libres para aceptar trabajos/colaborar
                              SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.add_business_rounded, texto: "Invitaciones", onTap: _abrirPantallaEmpresasInvitacion, color: colorScheme.primary)),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.task_rounded, texto: "Tareas\nEmpresa", onTap: _abrirPantallaTaskUsuario, color: colorScheme.primary)),

                              SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.add_link_rounded, texto: "Enlaces de\nCobro", 
                                color: planConfig.hasFeature(currentTier, 'ENLACES_COBRO') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'ENLACES_COBRO') ? Navigator.push(context, RouteHelper.slideUpRoute(const RequestMoneyScreen())) : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Enlaces de Cobro")
                              )),

                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.payments_rounded, texto: "Pagos\nDivididos", 
                                color: planConfig.hasFeature(currentTier, 'PAGOS_DIVIDIDOS') ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'PAGOS_DIVIDIDOS') ? _abrirPantallaPagosDivididos() : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Pagos Divididos")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.handshake_rounded, texto: "Deudas",
                                color: planConfig.hasFeature(currentTier, 'DEUDAS') ? Colors.orange : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'DEUDAS') ? Navigator.push(context, RouteHelper.slideUpRoute(DebtsScreen())) : PremiumBlockerModal.show(context, planRequerido: "BASIC", featureName: "Gestión de Deudas")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.event_repeat_rounded, texto: "Pagos\nProgramados", color: Colors.orange, onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const ScheduledPaymentsScreen())))),

                              // --- FILA 3: DEFI & AHORRO ---
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.savings_rounded, texto: "Bolsillos",
                                color: planConfig.hasFeature(currentTier, 'BOSILLOS') ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'BOSILLOS') ? Navigator.push(context, RouteHelper.slideUpRoute(VaultsScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Bolsillos Inteligentes")
                              )),
                              if (!isBusiness) SizedBox(width: itemWidth, child: Badge(
                                isLabelVisible: _retiroListoParaReclamar, backgroundColor: colorScheme.error,
                                child: _BotonAccion(
                                  icono: Icons.auto_graph_rounded, texto: "Minar",
                                  color: planConfig.hasFeature(currentTier, 'MINAR') ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
                                  onTap: () => planConfig.hasFeature(currentTier, 'MINAR') ? _abrirModalStake() : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Staking y Minería")
                                ),
                              )),

                              // --- FILA 4: AVANZADO & NOTARÍA ---
                              if (!isBusiness) SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.wallet_giftcard_rounded, texto: "Burner\nWallet", 
                                color: planConfig.hasFeature(currentTier, 'CARTERA_TEMPORAL') ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'CARTERA_TEMPORAL') ? Navigator.push(context, RouteHelper.slideUpRoute(const BurnerWalletsScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Carteras Desechables")
                              )),
                              SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.workspace_premium_rounded, texto: "Membresía", color: const Color(0xFF10B981), onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const MembershipsScreen())))), // Membresía siempre libre
                              SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.description_rounded, texto: "Notaría",
                                color: planConfig.hasFeature(currentTier, 'NOTARIA') ? Colors.deepPurple : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'NOTARIA') ? Navigator.push(context, RouteHelper.slideUpRoute(const DocumentNotaryScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Notaría Blockchain")
                              )),
                              
                              SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.adf_scanner_rounded, texto: "Validar\nDoc.",
                                color: planConfig.hasFeature(currentTier, 'VALIDAR_DOCUMENTO') ? Colors.deepPurple : Colors.grey.withOpacity(0.5), 
                                onTap: () => planConfig.hasFeature(currentTier, 'VALIDAR_DOCUMENTO') ? Navigator.push(context, RouteHelper.slideUpRoute(DocumentValidatorScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Validación Notarial")
                              )),
                              SizedBox(width: itemWidth, child: _BotonAccion(
                                icono: Icons.document_scanner_rounded, texto: "Validar\nHash", 
                                color: planConfig.hasFeature(currentTier, 'VALIDAR_HASH') ? Colors.deepPurple : Colors.grey.withOpacity(0.5),
                                onTap: () => planConfig.hasFeature(currentTier, 'VALIDAR_HASH') ? Navigator.push(context, RouteHelper.slideUpRoute(HashValidatorScreen())) : PremiumBlockerModal.show(context, planRequerido: "FREE", featureName: "Verificador de Hashes")
                              )),

                              // --- FILA 5: EMPRESAS (Solo Negocios y Admins) ---
                          if (isBusiness || isAdmin)
                                SizedBox(width: itemWidth, child: _BotonAccion(
                                  icono: Icons.business_center_rounded, texto: "Empresas", 
                                  color: (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness || isAdmin) ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                  onTap: () => (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness || isAdmin) ? _abrirPantallaEmpresas() : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Panel de Empresas")
                                )),

                                if (isBusiness || isAdmin)
                                SizedBox(width: itemWidth, child: _BotonAccion(
                                  icono: Icons.manage_accounts_rounded, texto: "Personal", 
                                  color: (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness || isAdmin) ? colorScheme.primary : Colors.grey.withOpacity(0.5),
                                  onTap: () => (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness || isAdmin) ? Navigator.push(context, RouteHelper.slideUpRoute(const EmployeeManagementScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Gestión de Personal")
                                )),
                            
                              if (isBusiness)
                                SizedBox(
                                  width: itemWidth, 
                                  child: _BotonAccion(
                                    icono: Icons.business_center_rounded, 
                                    texto: "Historial\nCorporativo", 
                                    color: (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness) ? Colors.deepOrange : Colors.grey.withOpacity(0.5),
                                    onTap: () => (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness) ? Navigator.push(context, RouteHelper.slideUpRoute(const AdminBurnerHistoryScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Panel de Empresas")
                                  )
                                ),

                                if (isBusiness)
                                 SizedBox(
                                   width: itemWidth, 
                                   child: _BotonAccion(
                                     icono: Icons.task_rounded, 
                                     texto: "Administración\nDe Tareas", 
                                     color: (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness) ? Colors.deepOrange : Colors.grey.withOpacity(0.5),
                                     onTap: () => (planConfig.hasFeature(currentTier, 'OPCION_NEGOCIO') || isBusiness) ? Navigator.push(context, RouteHelper.slideUpRoute(const TaskAdminScreen())) : PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Panel de Empresas")
                                   )
                                 ),
                            ],
                          );

//                         return Wrap(
//                           spacing: spacing,
//                           runSpacing: 24.0, 
//                           alignment: WrapAlignment.start, 
//                           children: [
//                             // --- FILA 1: BÁSICOS ---
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.add_shopping_cart_rounded, texto: "Comprar", onTap: _abrirModalComprar, color: colorScheme.primary)),
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.send_rounded, texto: "Enviar", onTap: _abrirModalEnviar, color: colorScheme.primary)),
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.qr_code_rounded, texto: "Recibir", onTap: _abrirModalRecibir, color: colorScheme.primary)),
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.account_balance_rounded, texto: "Retirar", onTap: _abrirPantallaRetiro, color: colorScheme.primary)),
//  SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.business_center_rounded, texto: "Empresas", onTap: _abrirPantallaEmpresas, color: colorScheme.primary)),
//  SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.add_business_rounded, texto: "Invitaciones", onTap: _abrirPantallaEmpresasInvitacion, color: colorScheme.primary)),
//  SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.payments_rounded, texto: "Pagos\nDivididos", onTap: _abrirPantallaPagosDivididos, color: colorScheme.primary)),

//                             // --- FILA 2: SOCIAL & PAGOS ---
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.contacts_rounded, texto: "Contactos", color: Colors.blueAccent, onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const ContactsScreen())))),
//                             SizedBox(width: itemWidth, child: _BotonAccion(
//                               icono: Icons.handshake_rounded, texto: "Deudas",
//                               color: planConfig.hasFeature(currentTier, 'DEUDAS') ? Colors.orange : Colors.grey.withOpacity(0.5),
//                               onTap: () {
//                                 if (planConfig.hasFeature(currentTier, 'DEUDAS')) {
//                                   Navigator.push(context, RouteHelper.slideUpRoute(DebtsScreen()));
//                                 } else {
//                                   PremiumBlockerModal.show(context, planRequerido: "BASIC", featureName: "Gestión de Deudas");
//                                 }
//                               },
//                             )),
//                             SizedBox(width: itemWidth, child: _BotonAccion(
//                               icono: Icons.savings_rounded, texto: "Bolsillos",
//                               color: planConfig.hasFeature(currentTier, 'BOSILLOS') ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
//                               onTap: () {
//                                 if (planConfig.hasFeature(currentTier, 'BOSILLOS')) {
//                                   Navigator.push(context, RouteHelper.slideUpRoute(VaultsScreen()));
//                                 } else {
//                                   PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Bolsillos Inteligentes");
//                                 }
//                               },
//                             )),
//                             SizedBox(width: itemWidth, child: Badge(
//                               isLabelVisible: _retiroListoParaReclamar, backgroundColor: colorScheme.error,
//                               child: _BotonAccion(
//                                 icono: Icons.auto_graph_rounded, texto: "Minar",
//                                 color: planConfig.hasFeature(currentTier, 'MINAR') ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.5),
//                                 onTap: () {
//                                   if (planConfig.hasFeature(currentTier, 'MINAR')) _abrirModalStake();
//                                   else PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Staking y Minería");
//                                 }, 
//                               ),
//                             )),

//  SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.paypal_rounded, texto: "Paypal", onTap: _abrirPantallaPaypal, color: colorScheme.primary)),



//                             // --- FILA 3: AVANZADO ---
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.wallet_giftcard_rounded, texto: "Burner\nWallet", color: const Color(0xFF10B981), onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const BurnerWalletsScreen())))),
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.workspace_premium_rounded, texto: "Membresía", color: const Color(0xFF10B981), onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(const MembershipsScreen())))),
//                             SizedBox(width: itemWidth, child: _BotonAccion(
//                               icono: Icons.description_rounded, texto: "Notaría",
//                               color: planConfig.hasFeature(currentTier, 'NOTARIA') ? Colors.deepPurple : Colors.grey.withOpacity(0.5),
//                               onTap: () {
//                                 if (planConfig.hasFeature(currentTier, 'NOTARIA')) {
//                                   Navigator.push(context, RouteHelper.slideUpRoute(const DocumentNotaryScreen()));
//                                 } else {
//                                   PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Notaría Blockchain");
//                                 }
//                               },
//                             )),
//                             SizedBox(width: itemWidth, child: _BotonAccion(
//                               icono: Icons.adf_scanner_rounded, texto: "Validar\nDoc.",
//                               color: planConfig.hasFeature(currentTier, 'VALIDAR_DOCUMENTO') ? Colors.deepPurple : Colors.grey.withOpacity(0.5), 
//                               onTap: () {
//                                 if (planConfig.hasFeature(currentTier, 'VALIDAR_DOCUMENTO')) {
//                                   Navigator.push(context, RouteHelper.slideUpRoute(DocumentValidatorScreen()));
//                                 } else {
//                                   PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "Validación Notarial");
//                                 }
//                               },
//                             )),

//                             // --- FILA 4: EXTRA ---
//                             SizedBox(width: itemWidth, child: _BotonAccion(icono: Icons.document_scanner_rounded, texto: "Validar\nHash", color: Colors.deepPurple, onTap: () => Navigator.push(context, RouteHelper.slideUpRoute(HashValidatorScreen())))),
//                           ],
//                         );
                      }
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class _BotonAccion extends StatelessWidget {
//   final IconData icono;
//   final String texto;
//   final VoidCallback onTap;

//   const _BotonAccion({
//     required this.icono,
//     required this.texto,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
//     final cardColor = Theme.of(context).cardColor;
//     return Column(
//       children: [
//         InkWell(
//           onTap: onTap,
//           child: CircleAvatar(
//             radius: 30,
//             backgroundColor: cardColor,
//             child: Icon(icono, color: onSurfaceColor),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           texto,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: onSurfaceColor,
//           ), // El texto ahora es visible en modo claro
//         ),
//       ],
//     );
//   }
// }

// 🔥 WIDGET DE BOTÓN MODERNIZADO 🔥
class _BotonAccion extends StatefulWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final Color color;

  const _BotonAccion({required this.icono, required this.texto, required this.onTap, required this.color});

  @override
  State<_BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<_BotonAccion> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animación muy rápida (100ms) para dar sensación de respuesta instantánea
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact(); // 🔥 Respuesta táctil física
    widget.onTap(); // Ejecuta la acción real
  }
  
  void _onTapCancel() => _controller.reverse();
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, // Tamaño perfeccionado para encajar en 4 columnas
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icono, color: widget.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              widget.texto,
              textAlign: TextAlign.center,
              maxLines: 2, // Permite saltos de línea (ej. Validar \n Doc.)
              overflow: TextOverflow.visible,
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, fontSize: 11, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}