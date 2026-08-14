import 'dart:async';

import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/admin/screens/admin_panel_screen.dart';
import 'package:dapp_movil/modules/admin/screens/main_menu_admin.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/document_notary/screens/hash_validator_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/request_money_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../wallet_and_tx/screens/dashboard_screen.dart';
import '../../wallet_and_tx/screens/main_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../wallet_and_tx/modals/receive_modal.dart';

class LoginScreen extends StatefulWidget {
 const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  
  final FlutterSecureStorage _vault = const FlutterSecureStorage();
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  // Animaciones y Carrusel de Información
  int _currentInfoIndex = 0;
  Timer? _carouselTimer;
  final List<Map<String, String>> _infoCards = [
    {
      "icon": "Icons.lock", 
      "title": "Bienvenido de nuevo.",
      "subtitle": "Tu billetera está protegida por\nencriptación y seguridad biométrica."
    },
    {
      "icon": "Icons.security",
      "title": "Transacciones Seguras.",
      "subtitle": "Envía y recibe TTC al instante,\nsin fronteras y con bajas comisiones."
    },
    {
      "icon": "Icons.explore",
      "title": "Ecosistema TTC",
      "subtitle": "Explora Notaría Digital, Grupos,\nMembresías y Funciones Empresariales."
    },
    {
      "icon": "Icons.trending_up",
      "title": "Haz crecer tu capital.",
      "subtitle": "Genera rendimientos pasivos haciendo\nStaking y ahorrando en tu bóveda."
    }
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _passController.dispose();
    super.dispose();
  }

 void _startCarousel() {
    _stopCarousel(); // Aseguramos que no haya temporizadores duplicados
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentInfoIndex = (_currentInfoIndex + 1) % _infoCards.length;
        });
      }
    });
  }

  void _stopCarousel() {
    _carouselTimer?.cancel();
  }

  // MÉTODOS DE DESBLOQUEO (Mantenidos de tu clase original)
  Future<void> _unlock() async {
    if (_passController.text.isEmpty) return;

    setState(() => _isLoading = true);
    String pinIngresado = _passController.text;

    // 🔥 1. INTERCEPTAMOS EL MODO PÁNICO
    String? localPanicPin = await _vault.read(key: 'panic_pin');

    if (localPanicPin != null && localPanicPin == pinIngresado) {
      print("💀 [LOGIN] PIN DE PÁNICO DETECTADO EN MEMORIA LOCAL.");
      String? decoyPrivKey = await _vault.read(key: 'decoy_private_key');
      String? decoyAddress = await _vault.read(key: 'decoy_address');
      
      if (decoyPrivKey != null && decoyAddress != null) {
        authCore.activatePanicMode(decoyAddress, decoyPrivKey);
        String result = await authCore.requestJwtToken(pinIngresado);
        if (mounted) setState(() => _isLoading = false);
        if (result == "SUCCESS") {
          _navegarAlDashboard();
        } else {
           UIHelper.showCustomSnackbar("Error al iniciar bóveda señuelo.", isError: true);
        }
        return; 
      }
    }

    // 2. FLUJO NORMAL SI NO ES MODO PÁNICO
    String result = await authCore.unlockWallet(pinIngresado);
    if (mounted) setState(() => _isLoading = false);

    if (result == "SUCCESS") {
      _navegarAlDashboard();
    } else if (result == "2FA_REQUIRED") {
      _mostrarDialogo2FA(pinIngresado);
    } else if (result == "ERROR_PIN" || result == "ERROR_CREDENTIALS") {
      _passController.clear();
      UIHelper.showCustomSnackbar("Contraseña incorrecta. Inténtalo de nuevo.", isError: true);
    } else {
      _passController.clear();
      UIHelper.showCustomSnackbar(result, isError: true);
    }
  }

  Future<void> _unlockConHuella() async {
    setState(() => _isLoading = true);
    String result = await authCore.loginWithBiometrics();
    if (mounted) setState(() => _isLoading = false);

    if (result == "SUCCESS") {
      _navegarAlDashboard();
    } else if (result == "2FA_REQUIRED") {
      String? savedPassword = await _vault.read(key: 'secure_password');
      if (savedPassword != null) {
        _mostrarDialogo2FA(savedPassword);
      } else {
        UIHelper.showCustomSnackbar("Error leyendo credenciales internas.", isError: true);
      }
    } else if (result == "ERROR_CANCELLED") {
      // Ignorar
    } else {
      UIHelper.showCustomSnackbar("Error al autenticar con biometría.", isError: true);
    }
  }

  void _mostrarDialogo2FA(String passwordAUsar) {
    final TextEditingController codeController = TextEditingController();
    bool verificando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Column(
            children: [
              Icon(Icons.security, color: Colors.blueAccent, size: 40),
              SizedBox(height: 10),
              Text("Autenticador 2FA", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Tu cuenta está protegida. Ingresa el código de 6 dígitos de tu Google Authenticator.", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "", filled: true, fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: verificando ? null : () async {
                if (codeController.text.length != 6) return;
                setStateDialog(() => verificando = true);
                HapticFeedback.mediumImpact();
                String result = await authCore.requestJwtToken(passwordAUsar, twoFactorCode: codeController.text);
                if (result == "SUCCESS") {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _navegarAlDashboard();
                } else {
                  setStateDialog(() => verificando = false);
                  UIHelper.showCustomSnackbar("Código incorrecto", isError: true);
                }
              },
              child: verificando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Verificar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarAlDashboard() {
    if (!mounted) return;
    if (authCore.role == "ROLE_ADMIN") {
      Navigator.pushReplacement(context, RouteHelper.fadeRoute(const MainMenuAdmin()));
    } else {
      Navigator.pushReplacement(context, RouteHelper.fadeRoute( MainScreen()));
    }
  }

  // =====================================
  // UI BUILDER
  // =====================================

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final btnBlue = const Color(0xFF4361EE);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView( // <-- Soluciona el Overflow
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // 1. CAROUSEL INFORMATIVO SUPERIOR (Efecto Flip/Fade + QR)
            GestureDetector(
                onTap: () {
                  if (_currentInfoIndex == -1) {
                    setState(() => _currentInfoIndex = 0);
                    _startCarousel(); 
                  }
                },
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: _currentInfoIndex == -1 ? Colors.white : theme.cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: onSurface.withOpacity(0.05)),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          if (child.key == const ValueKey<int>(-1) || 
                              (_currentInfoIndex == 0 && child.key == const ValueKey<int>(0))) {
                             final rotate = Tween(begin: 3.14159265359, end: 0.0).animate(animation);
                             return AnimatedBuilder(
                               animation: rotate,
                               child: child,
                               builder: (context, child) {
                                 final angle = rotate.value;
                                 return Transform(
                                   transform: Matrix4.rotationY(angle),
                                   alignment: Alignment.center,
                                   child: child,
                                 );
                               }
                             );
                          }
                          return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                        },
                        child: _currentInfoIndex == -1 
                          ? _buildBackCard(theme)
                          : Container(
                              key: ValueKey<int>(_currentInfoIndex),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // 🔥 PADDING REDUCIDO para más espacio interno
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12), // 🔥 Reducido de 16 a 12
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                                      borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: _getIconForIndex(_currentInfoIndex),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_infoCards[_currentInfoIndex]['title']!, textAlign: TextAlign.center, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(_infoCards[_currentInfoIndex]['subtitle']!, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, height: 1.3)),
                                  const SizedBox(height: 10), 
                                ],
                              ),
                            ),
                      ),
                      
                      if (_currentInfoIndex != -1)
                        Transform.translate(
                          offset: const Offset(0, 20),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.scaffoldBackgroundColor,
                              foregroundColor: onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: onSurface.withOpacity(0.1))
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 0,
                            ),
                         onPressed: () async {
                               HapticFeedback.mediumImpact();
                               _stopCarousel(); // 🔥 DETENER EL CARRUSEL
                               
                               // Pedimos la huella antes de girar la tarjeta
                               String result = await authCore.loginWithBiometrics();
                               if (!context.mounted) return;
                               
                               if (result == "SUCCESS") {
                                 // Huella exitosa: giramos la tarjeta
                                 setState(() => _currentInfoIndex = -1); 
                               } else {
                                 // Si falla o cancela, reanudamos el carrusel
                                 _startCarousel(); 
                                 
                                 if (result == "2FA_REQUIRED") {
                                   UIHelper.showCustomSnackbar("Por seguridad 2FA, inicia sesión para ver tu QR.");
                                 } else if (result != "ERROR_CANCELLED") {
                                   UIHelper.showCustomSnackbar("Error al acceder a la bóveda.", isError: true);
                                 }
                               }
                            },
                            child: Text("Ver mi QR", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
                          ),
                        )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 2. HUELLA DACTILAR GIGANTE
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _unlockConHuella,
                  child: Container(
                    padding: const EdgeInsets.all(24), // Reducido levemente para evitar overflow
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onSurface.withOpacity(0.02),
                      border: Border.all(color: onSurface.withOpacity(0.05), width: 2),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20), // Reducido levemente
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onSurface.withOpacity(0.05),
                        border: Border.all(color: onSurface.withOpacity(0.1), width: 1),
                      ),
                      child: Icon(Icons.fingerprint_rounded, size: 40, color: onSurface.withOpacity(0.8)), // Reducido levemente
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Tocar para desbloquear con\nhuella dactilar", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, height: 1.4)),
              const SizedBox(height: 30),

              // 3. CAMPO CONTRASEÑA Y BOTÓN
              TextField(
                controller: _passController,
                obscureText: _obscurePass,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.key_outlined, color: onSurface.withOpacity(0.6)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnBlue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _unlock,
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Desbloquear con contraseña", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // 4. ACCESOS RÁPIDOS INFERIORES (3 BOTONES CUADRADOS)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.published_with_changes_rounded,
                      label: "Verificar\nTransferencia",
                      color: btnBlue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HashValidatorScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.output_rounded,
                      label: "Generar\nTransferencia",
                      color: btnBlue,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        String result = await authCore.loginWithBiometrics();
                        if (!context.mounted) return;
                        if (result == "SUCCESS") ReceiveModal.show(context: context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.qr_code_2_rounded,
                      label: "Generar\nEnlace",
                      color: btnBlue,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        String result = await authCore.loginWithBiometrics();
                        if (!context.mounted) return;
                        if (result == "SUCCESS") Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestMoneyScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


// LADO REVERSO: Código QR Real
  Widget _buildBackCard(ThemeData theme) {
    final address = authCore.publicAddress;
    final linkPago = "ttcwallet://pay?to=$address";

    String displayAddress = "Cargando billetera...";
    if (address.isNotEmpty && address.length > 14) {
      displayAddress = "${address.substring(0, 8)}...${address.substring(address.length - 6)}";
    }

    return Container(
      key: const ValueKey<int>(-1), 
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔥 Si la address está lista, mostramos el QR real, sino un loader
          if (address.isNotEmpty)
            QrImageView(
              data: linkPago,
              version: QrVersions.auto,
              size: 110.0, // Tamaño ajustado para no causar overflow
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black87),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
            )
          else
            const SizedBox(height: 110, width: 110, child: Center(child: CircularProgressIndicator())),
            
          const SizedBox(height: 12),
          const Text("Tu Dirección Pública", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(displayAddress, style: const TextStyle(color: Colors.black54, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          const Text("Toca en cualquier parte para volver", style: TextStyle(color: Colors.black38, fontSize: 11)),
        ],
      ),
    );
  }
  // WIDGET HELPER PARA LOS 3 BOTONES INFERIORES
  Widget _buildQuickActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER PARA ICONOS DEL CARRUSEL
  Widget _getIconForIndex(int index) {
    List<IconData> icons = [Icons.lock_rounded, Icons.security_rounded, Icons.explore_rounded, Icons.trending_up_rounded];
    return Icon(icons[index], color: Colors.white, size: 32);
  }
}

// class LoginScreen extends StatefulWidget {
//  const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _passController = TextEditingController();
//   bool _isLoading = false;
//   bool _obscurePass = true;

//   final FlutterSecureStorage _vault = const FlutterSecureStorage();

//   AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

// Future<void> _unlock() async {
//     if (_passController.text.isEmpty) return;

//     setState(() => _isLoading = true);
//     String pinIngresado = _passController.text;

//     // 🔥 1. INTERCEPTAMOS EL MODO PÁNICO
//     String? localPanicPin = await _vault.read(key: 'panic_pin');

//     if (localPanicPin != null && localPanicPin == pinIngresado) {
//       print("💀 [LOGIN] PIN DE PÁNICO DETECTADO EN MEMORIA LOCAL.");
//       String? decoyPrivKey = await _vault.read(key: 'decoy_private_key');
//       String? decoyAddress = await _vault.read(key: 'decoy_address');
      
//       if (decoyPrivKey != null && decoyAddress != null) {
//         // Configuramos la app para usar la billetera señuelo
//         authCore.activatePanicMode(decoyAddress, decoyPrivKey);
        
//         // 🔥 MAGIA: Pedimos un JWT al backend. Como el backend creó un "Usuario Fantasma", ¡esto funcionará!
//         String result = await authCore.requestJwtToken(pinIngresado);
        
//         if (mounted) setState(() => _isLoading = false);
        
//         if (result == "SUCCESS") {
//           _navegarAlDashboard();
//         } else {
//            UIHelper.showCustomSnackbar("Error al iniciar bóveda señuelo.", isError: true);
//         }
//         return; 
//       }
//     }

//     // 2. FLUJO NORMAL SI NO ES MODO PÁNICO
//     print("✅ [LOGIN] PIN normal detectado. Procediendo a desencriptar bóveda principal...");
//     String result = await authCore.unlockWallet(pinIngresado);

//     if (mounted) setState(() => _isLoading = false);

//     if (result == "SUCCESS") {
//       _navegarAlDashboard();
//     } else if (result == "2FA_REQUIRED") {
//       _mostrarDialogo2FA(pinIngresado);
//     } else if (result == "ERROR_PIN" || result == "ERROR_CREDENTIALS") {
//       _passController.clear();
//       UIHelper.showCustomSnackbar("Contraseña incorrecta. Inténtalo de nuevo.", isError: true);
//     } else {
//       _passController.clear();
//       UIHelper.showCustomSnackbar(result, isError: true);
//     }
//   }

//   // Future<void> _unlockConHuella() async {
//   //   setState(() => _isLoading = true);

//   //   bool success = await widget.service.loginWithBiometrics();

//   //   if (mounted) setState(() => _isLoading = false);

//   //   if (success) {
//   //     _navegarAlDashboard();
//   //   }
//   // }

// Future<void> _unlockConHuella() async {
//     setState(() => _isLoading = true);

//     String result = await authCore.loginWithBiometrics();

//     if (mounted) setState(() => _isLoading = false);

//     if (result == "SUCCESS") {
//       _navegarAlDashboard();
//     } else if (result == "2FA_REQUIRED") {
//       // Si usó huella, leemos la contraseña guardada internamente para enviarla al backend con el código
//       String? savedPassword = await _vault.read(key: 'secure_password');
//       if (savedPassword != null) {
//         _mostrarDialogo2FA(savedPassword);
//       } else {
//         UIHelper.showCustomSnackbar("Error leyendo credenciales internas.", isError: true);
//       }
//     } else if (result == "ERROR_CANCELLED") {
//       // No hacemos nada, el usuario canceló la huella a propósito
//     } else {
//       UIHelper.showCustomSnackbar("Error al autenticar con biometría.",isError: true);
//     }
//   }

//   void _mostrarDialogo2FA(String passwordAUsar) {
//     final TextEditingController codeController = TextEditingController();
//     bool verificando = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setStateDialog) => AlertDialog(
//           backgroundColor: Theme.of(context).cardColor,
//           title: const Column(
//             children: [
//               Icon(Icons.security, color: Colors.blueAccent, size: 40),
//               SizedBox(height: 10),
//               Text("Autenticador 2FA", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Tu cuenta está protegida. Ingresa el código de 6 dígitos de tu Google Authenticator.", 
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: codeController,
//                 keyboardType: TextInputType.number,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
//                 maxLength: 6,
//                 decoration: InputDecoration(
//                   counterText: "",
//                   filled: true,
//                   fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
//               onPressed: verificando ? null : () async {
//                 if (codeController.text.length != 6) return;
//                 setStateDialog(() => verificando = true);

//                 // Re-intentamos el login, enviando la contraseña Y el código de 6 dígitos
//                 HapticFeedback.mediumImpact();
//                 String result = await authCore.requestJwtToken(passwordAUsar, twoFactorCode: codeController.text);

//                 if (result == "SUCCESS") {
//                   if (!mounted) return;
//                   Navigator.pop(ctx);
//                   _navegarAlDashboard();
//                 } else {
//                   setStateDialog(() => verificando = false);
//                   UIHelper.showCustomSnackbar("Código incorrecto", isError: true);
//                 }
//               },
//               child: verificando
//                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                 : const Text("Verificar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _navegarAlDashboard() {
//     if (!mounted) return;
//     if (authCore.role == "ROLE_ADMIN") {
//       Navigator.pushReplacement(
//         context,
//         RouteHelper.fadeRoute(const MainMenuAdmin()), 
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         RouteHelper.fadeRoute( MainScreen()),
//       );
//     }
//   }


// @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20.0, top: 10.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: onSurface.withOpacity(0.05),
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: Icon(Icons.qr_code_scanner_rounded, color: colorScheme.onSurface.withOpacity(0.7), size: 22),
//                 tooltip: "Recibir sin entrar",
//                 onPressed: () async {
//                   HapticFeedback.mediumImpact();
//                   String result = await authCore.loginWithBiometrics();

//                   if (!context.mounted) return;

//                   if (result == "SUCCESS") {
//                     ReceiveModal.show(context: context);
//                   } 
//                   else if (result == "2FA_REQUIRED") {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Por seguridad 2FA, inicia sesión completo para ver tu QR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
//                         backgroundColor: Colors.orange
//                       )
//                     );
//                   } 
//                   else if (result != "ERROR_CANCELLED") {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: const Text("Error al acceder a la bóveda o huella incorrecta.", style: TextStyle(color: Colors.white)), 
//                         backgroundColor: Theme.of(context).colorScheme.error
//                       )
//                     );
//                   }
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Spacer(),

//                       // 1. ÍCONO CANDADO SUPERIOR
//                       Container(
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: onSurface.withOpacity(0.05),
//                         ),
//                         child: Icon(Icons.lock_outline_rounded, size: 32, color: colorScheme.primary),
//                       ),
//                       const SizedBox(height: 24),

//                       // 2. TEXTOS DE BIENVENIDA
//                       Text(
//                         "Bienvenido de nuevo",
//                         style: TextStyle(color: onSurface, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5), 
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 12),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 40),
//                         child: Text(
//                           "Tu billetera está protegida por encriptación\nde grado bancario y seguridad biométrica.",
//                           style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.5),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       const SizedBox(height: 40),

//                       // 3. TARJETA PRINCIPAL DE LOGIN
//                       Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 24),
//                         padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
//                         decoration: BoxDecoration(
//                           color: theme.cardColor.withOpacity(0.3), // Fondo sutil adaptativo
//                           borderRadius: BorderRadius.circular(24),
//                           border: Border.all(color: onSurface.withOpacity(0.08)), // Borde delimitador
//                         ),
//                         child: Column(
//                           children: [
//                             // HUELLA BIOMÉTRICA CON CÍRCULOS CONCÉNTRICOS
//                             GestureDetector(
//                               onTap: _isLoading ? null : _unlockConHuella,
//                               child: Container(
//                                 padding: const EdgeInsets.all(24),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: colorScheme.primary.withOpacity(0.05),
//                                   border: Border.all(color: colorScheme.primary.withOpacity(0.1), width: 1),
//                                 ),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(24),
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: colorScheme.primary.withOpacity(0.1),
//                                   ),
//                                   child: Icon(Icons.fingerprint_rounded, size: 56, color: colorScheme.primary),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                             Text(
//                               "Toca para usar Biometría",
//                               style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
//                               textAlign: TextAlign.center,
//                             ),
                            
//                             const SizedBox(height: 40),
                            
//                             // DIVISOR "o"
//                             Row(
//                               children: [
//                                 Expanded(child: Divider(color: onSurface.withOpacity(0.1))),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                                   child: Text("o", style: TextStyle(color: onSurface.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 14)),
//                                 ),
//                                 Expanded(child: Divider(color: onSurface.withOpacity(0.1))),
//                               ],
//                             ),
//                             const SizedBox(height: 32),

//                             // CAMPO DE CONTRASEÑA OUTLINED
//                             TextField(
//                               controller: _passController,
//                               keyboardType: TextInputType.text,
//                               obscureText: _obscurePass,
//                               style: TextStyle(color: onSurface, fontWeight: FontWeight.w500),
//                               decoration: InputDecoration(
//                                 filled: true,
//                                 fillColor: Colors.transparent,
//                                 hintText: "Contraseña",
//                                 hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
//                                 prefixIcon: Icon(Icons.key_outlined, color: onSurface.withOpacity(0.5)),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: onSurface.withOpacity(0.5)),
//                                   onPressed: () => setState(() => _obscurePass = !_obscurePass),
//                                 ),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12), 
//                                   borderSide: BorderSide(color: onSurface.withOpacity(0.2))
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12), 
//                                   borderSide: BorderSide(color: colorScheme.primary)
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 24),

//                             // BOTÓN DE DESBLOQUEO PILL-SHAPE
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: colorScheme.primary,
//                                   foregroundColor: colorScheme.onPrimary,
//                                   elevation: 0,
//                                   padding: const EdgeInsets.symmetric(vertical: 18),
//                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                                 ),
//                                 onPressed: _isLoading ? null : _unlock,
//                                 child: _isLoading
//                                     ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
//                                     : const Text("Desbloquear con contraseña", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       const Spacer(),
                      
//                       // 4. ENLACES INFERIORES
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 32.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text("Ayuda", style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 13)),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                               child: Icon(Icons.circle, size: 4, color: onSurface.withOpacity(0.2)),
//                             ),
//                             Text("Importar Billetera", style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 13)),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }
//         ),
//       ),
//     );
//   }
// }