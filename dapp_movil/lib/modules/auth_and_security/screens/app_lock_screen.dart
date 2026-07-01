import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLockScreen extends StatefulWidget {
  final AuthCoreService authCore;
  
  const AppLockScreen({super.key, required this.authCore});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Lanzar la huella automáticamente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _desbloquearApp();
    });
  }

  Future<void> _desbloquearApp() async {
    setState(() => _isAuthenticating = true);
    
    bool auth = await widget.authCore.authenticateUser();
    
    if (mounted) setState(() => _isAuthenticating = false);

    if (auth) {
      if (mounted) {
        Navigator.of(context).pop(); // Destruimos la pantalla de bloqueo y volvemos a donde estábamos
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (!didPop) SystemNavigator.pop(); 
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono premium con fondo tonal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_person_rounded, size: 80, color: colorScheme.primary),
                ),
                const SizedBox(height: 32),
                Text(
                  "Bóveda Segura",
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "Tu sesión ha sido suspendida por inactividad. Desbloquea para continuar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // M3 Button
                    ),
                    onPressed: _isAuthenticating ? null : _desbloquearApp,
                    icon: _isAuthenticating 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                      : const Icon(Icons.fingerprint, size: 28),
                    label: const Text("Desbloquear con Biometría", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}