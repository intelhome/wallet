import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import '../../wallet_and_tx/screens/dashboard_screen.dart';
import 'login_screen.dart';
import 'package:safe_device/safe_device.dart';

class InitialRouter extends StatefulWidget {
  const InitialRouter({super.key});

  @override
  State<InitialRouter> createState() => _InitialRouterState();
}

class _InitialRouterState extends State<InitialRouter> {
 // final BlockchainService _blockchainService = BlockchainService();
  final bool _requiereDesbloqueo = false;
  bool _isDeviceSafe = true;
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _checkExistingWallet();
  }

  Future<void> _checkExistingWallet() async {
    bool isJailBroken = false;

    try {
      isJailBroken = await SafeDevice.isJailBroken;
    } catch (e) {
      print("Error verificando seguridad del dispositivo: $e");
    }

    // SI EL DISPOSITIVO ESTÁ ROTEADO, BLOQUEAMOS TODO
    if (isJailBroken) {
      if (mounted) {
        setState(() => _isDeviceSafe = false);
      }
      return; // 🛑 Abortamos la carga de la billetera
    }

    await authCore.init();
    bool exists = await authCore.hasSavedWallet();

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (exists) {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaBienvenida()),
      );
    }
  }

  // Future<void> _intentarDesbloqueo() async {
  //   bool isAuthorized = await _blockchainService.authenticateUser();

  //   if (isAuthorized) {
     
  //     await _blockchainService.loadSavedWallet();
  //     if (!mounted) return;
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => DashboardApp(service: _blockchainService),
  //       ),
  //     );
  //   } else {
    
  //     setState(() {
  //       _requiereDesbloqueo = true;
  //     });
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.deepPurple.shade900,
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Icon(
  //             Icons.account_balance_wallet,
  //             size: 80,
  //             color: Colors.white,
  //           ),
  //           const SizedBox(height: 20),

  //           _requiereDesbloqueo
  //               ? ElevatedButton.icon(
  //                   onPressed: _intentarDesbloqueo,
  //                   icon: const Icon(Icons.fingerprint),
  //                   label: const Text(
  //                     "Desbloquear Cartera",
  //                     style: TextStyle(fontSize: 18),
  //                   ),
  //                   style: ElevatedButton.styleFrom(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 30,
  //                       vertical: 15,
  //                     ),
  //                     foregroundColor: Colors.deepPurple.shade900,
  //                   ),
  //                 )
  //               : const CircularProgressIndicator(color: Colors.white),

  //           const SizedBox(height: 20),
  //           Text(
  //             _requiereDesbloqueo
  //                 ? "App bloqueada por seguridad"
  //                 : "Asegurando conexión Web3...",
  //             style: const TextStyle(color: Colors.white, fontSize: 16),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isDeviceSafe) {
      return Scaffold(
      backgroundColor: colorScheme.error,
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Icon(Icons.gpp_bad_rounded, size: 100, color: colorScheme.onError),
              SizedBox(height: 20),
              Text("Dispositivo Comprometido", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onError, fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 15),
              Text(
                "Por normas de seguridad financiera, esta aplicación no puede ejecutarse en dispositivos con Root o Jailbreak.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onError.withOpacity(0.8), fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
       backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 24),
            Text("Asegurando conexión Web3...", style: TextStyle(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
