import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/admin/screens/admin_panel_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;

  final FlutterSecureStorage _vault = const FlutterSecureStorage();

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  // @override
  // void initState() {
  //   super.initState();
  //   // Lanzamos la huella automáticamente al abrir la pantalla
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _unlockConHuella();
  //   });
  // }

 Future<void> _unlock() async {
    if (_passController.text.isEmpty) return;

    setState(() => _isLoading = true);
    String pinIngresado = _passController.text;

    String? localPanicPin = await _vault.read(key: 'panic_pin');

    if (localPanicPin != null && localPanicPin == pinIngresado) {
      print("💀 [LOGIN] PIN DE PÁNICO DETECTADO EN MEMORIA LOCAL.");
      String? decoyPrivKey = await _vault.read(key: 'decoy_private_key');
      String? decoyAddress = await _vault.read(key: 'decoy_address');
      
      if (decoyPrivKey != null && decoyAddress != null) {
        String result = await authCore.unlockWallet(pinIngresado);
        if (mounted) setState(() => _isLoading = false);
        _navegarAlDashboard();
        return; 
      }
    }

    print("✅ [LOGIN] PIN normal detectado. Procediendo a desencriptar bóveda principal...");

    // final panicData = await widget.service.checkPanicPin(pinIngresado);
    
    // if (panicData['isPanic'] == "true") {
    //   String decoyAddress = panicData['decoyAddress'];
    //   String privateKey = panicData['privateKey']; // Extraemos la llave
      
    //   widget.service.activatePanicMode(decoyAddress, privateKey);
      
    //   if (mounted) setState(() => _isLoading = false);
    //   _navegarAlDashboard(); 
    //   return; 
    // }

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
      // Ej: "Tu cuenta de empresa está en revisión..."
      _passController.clear();
      UIHelper.showCustomSnackbar(result, isError: true);
    }
  }

  // Future<void> _unlockConHuella() async {
  //   setState(() => _isLoading = true);

  //   bool success = await widget.service.loginWithBiometrics();

  //   if (mounted) setState(() => _isLoading = false);

  //   if (success) {
  //     _navegarAlDashboard();
  //   }
  // }

Future<void> _unlockConHuella() async {
    setState(() => _isLoading = true);

    String result = await authCore.loginWithBiometrics();

    if (mounted) setState(() => _isLoading = false);

    if (result == "SUCCESS") {
      _navegarAlDashboard();
    } else if (result == "2FA_REQUIRED") {
      // Si usó huella, leemos la contraseña guardada internamente para enviarla al backend con el código
      String? savedPassword = await _vault.read(key: 'secure_password');
      if (savedPassword != null) {
        _mostrarDialogo2FA(savedPassword);
      } else {
        UIHelper.showCustomSnackbar("Error leyendo credenciales internas.", isError: true);
      }
    } else if (result == "ERROR_CANCELLED") {
      // No hacemos nada, el usuario canceló la huella a propósito
    } else {
      UIHelper.showCustomSnackbar("Error al autenticar con biometría.",isError: true);
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
              Text("Tu cuenta está protegida. Ingresa el código de 6 dígitos de tu Google Authenticator.", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: verificando ? null : () async {
                if (codeController.text.length != 6) return;
                setStateDialog(() => verificando = true);

                // Re-intentamos el login, enviando la contraseña Y el código de 6 dígitos
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
              child: verificando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Verificar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarAlDashboard() {
    if (!mounted) return;
    if (authCore.role == "ROLE_ADMIN") {
      Navigator.pushReplacement(
        context,
        RouteHelper.fadeRoute(const AdminPanelScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        RouteHelper.fadeRoute( MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    return Scaffold(
     backgroundColor: theme.scaffoldBackgroundColor,
     appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Icon(Icons.qr_code_2_rounded, color: colorScheme.primary, size: 28),
              tooltip: "Recibir sin entrar",
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
              ),
            onPressed: () async {
                // Esto pide la huella y automáticamente carga widget.service.publicAddress
                HapticFeedback.mediumImpact();
                String result = await authCore.loginWithBiometrics();

                if (!context.mounted) return;

                if (result == "SUCCESS") {
                  ReceiveModal.show(
                    context: context,
                  );
                } 
                else if (result == "2FA_REQUIRED") {
                  // Si el usuario tiene doble factor, le pedimos que inicie sesión normal por seguridad extra
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Por seguridad 2FA, inicia sesión completo para ver tu QR.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                      backgroundColor: Colors.orange
                    )
                  );
                } 
                else if (result != "ERROR_CANCELLED") {
                  // Falló la huella o no hay bóveda creada
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Error al acceder a la bóveda o huella incorrecta.", style: TextStyle(color: Colors.white)), 
                      backgroundColor: Theme.of(context).colorScheme.error
                    )
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Icon(Icons.lock_rounded, size: 80, color: colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                "Bienvenido de nuevo",
                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5), 
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Ingresa tu contraseña para desbloquear tu billetera",
              style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _passController,
                keyboardType: TextInputType.text,
                obscureText: _obscurePass,
                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: onSurface.withOpacity(0.05),
                  hintText: "Contraseña",
                  hintStyle: TextStyle(color: onSurface.withOpacity(0.3), letterSpacing: 0),
                  prefixIcon: Icon(Icons.key_rounded, color: onSurface.withOpacity(0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),

              // if (_isLoading)
              //   const Center(
              //     child: CircularProgressIndicator(color: Colors.blueAccent),
              //   ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // 🔥 M3 Primary
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _unlock,
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                    : const Text("Desbloquear con contraseña", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
             Row(
                children: [
                  Expanded(child: Divider(color: onSurface.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("O", style: TextStyle(color: onSurface.withOpacity(0.4), fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: onSurface.withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: _isLoading ? null : _unlockConHuella,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1), // 🔥 Fondo tonal suave
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2),
                  ),
                  child: Icon(Icons.fingerprint_rounded, size: 60, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),
             Text(
                "Toca para usar Biometría",
                style: TextStyle(color: colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

}
