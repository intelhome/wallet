import 'package:dapp_movil/modules/auth_and_security/screens/register_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'password_setup_screen.dart';
import 'import_wallet_screen.dart';


class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
 // final BlockchainService _service = BlockchainService();
  bool _conectando = true;
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _conectarNodo();
  }

  Future<void> _conectarNodo() async {
    await authCore.init();
    
    // Verificamos si ya existe una llave encriptada en la bóveda
    bool hasWallet = await authCore.hasSavedWallet();

    if (hasWallet) {
      if (!mounted) return;
      // Si ya tiene billetera, lo mandamos directo a poner su PIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      // Si NO tiene billetera, quitamos el cargando y le mostramos el botón de "Crear Cartera"
      setState(() => _conectando = false);
    }
  }

  // Future<void> _conectarNodo() async {
  //   await _service.init();
  //   setState(() => _conectando = false);
  // }

  // Future<void> _irARegistro() async {
  //   // 1. Pedimos la huella ANTES de dejarlo elegir un alias
  //   bool isAuthorized = await _service.authenticateUser();

  //   if (isAuthorized) {
  //     if (!mounted) return;
  //     // 2. Lo enviamos a la pantalla de Registro, pasándole el servicio
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => RegisterScreen(service: _service),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text(
  //           'Debes verificar tu identidad para continuar',
  //           style: TextStyle(color: Colors.white),
  //         ),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future<void> _irARegistro() async {
    // 1. Pedimos la huella
    bool isAuthorized = await authCore.authenticateUser();

    if (isAuthorized) {
      if (!mounted) return;
      
      // 2. ¡NUEVO DESTINO! Vamos a la Bóveda de Semillas
      Navigator.push( // Cambiamos a push normal para que pueda retroceder si quiere
        context,
        MaterialPageRoute(
          //builder: (context) => PasswordSetupScreen(service: _service),
          builder: (context) => RegisterScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes verificar tu identidad para continuar',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Scaffold(
  //       backgroundColor: theme.scaffoldBackgroundColor,
  //     body: Center(
  //       child: _conectando
  //         ? CircularProgressIndicator(color: colorScheme.onPrimary)
  //           : Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //               Icon(Icons.security_rounded, size: 120, color: colorScheme.onSurface),
  //                 const SizedBox(height: 24),
  //                 Text("TTC Wallet", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -1)),
  //                 const SizedBox(height: 60),
  //                ElevatedButton.icon(
  //                   onPressed: _irARegistro,
  //                   icon: Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary),
  //                   label: Text("Crear Cartera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary)),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: theme.cardColor, // 🔥 Botón blanco/gris oscuro según el tema
  //                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
  //                     elevation: 0,
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde 16px
  //                   ),
  //                 ),

  //                 const SizedBox(height: 20),

  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) => ImportWalletScreen(),
  //                       ),
  //                     );
  //                   },
  //                   child: Text(
  //                     "Ya tengo una billetera (Importar)",
  //                     style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 16, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: _conectando
          ? CircularProgressIndicator(color: colorScheme.onPrimary)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, size: 80, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 32),
                  Text("TTC Wallet", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -1)),
                  const SizedBox(height: 16),
                  Text(
                    "Tu puerta al ecosistema DeFi. Sin gas, seguro y totalmente descentralizado.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7), height: 1.4),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _irARegistro,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Crear Billetera", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4361EE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportWalletScreen()));
                    },
                    child: Text(
                      "Ya tengo una billetera (Importar)",
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
