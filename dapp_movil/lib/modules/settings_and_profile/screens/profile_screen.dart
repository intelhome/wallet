import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/PremiumBlockerModal.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/screens/splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String aliasUsuario;

  const ProfileScreen({
    super.key,
    required this.aliasUsuario,
  });

  void _borrarCartera(BuildContext context) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 🔥 Borde 24
        title: Text("⚠️ ¿Borrar Cartera?", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w900)),
        content: Text(
          "Si no tienes respaldada tu frase secreta de 12 palabras, PERDERÁS TODOS TUS FONDOS para siempre. ¿Estás seguro?",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              //final authCore = Provider.of<AuthCoreService>(context, listen: false);
              await authCore.deleteWallet();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const InitialRouter()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text(
              "Sí, borrar todo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCore = Provider.of<AuthCoreService>(context);

    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final colorScheme = Theme.of(context).  colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Mi Perfil", style: TextStyle(color: onSurfaceColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                SmartAvatar(address: authCore.publicAddress, size: 90),
                const SizedBox(height: 15),
                Text(
                  "@$aliasUsuario",
                  style: TextStyle(
                    color: onSurfaceColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${authCore.publicAddress.substring(0, 8)}...${authCore.publicAddress.substring(authCore.publicAddress.length - 6)}",
                    style: TextStyle(
                      color: onSurfaceColor.withOpacity(0.6),
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // 🔥 24px M3
              ),
              child: ListView(
                children: [
                  ListTile(
                   leading: Icon(Icons.settings_rounded, color: colorScheme.primary), // 🔥 Primary
                    title: Text("Configuración y Seguridad", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(),
                        ),
                      );
                    },
                  ),
 Divider(color: onSurfaceColor.withOpacity(0.1), height: 30),
             ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: Colors.blueAccent),
                  title: const Text("Modo Negocio (TTC Business)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Convierte tu app en un Punto de Venta"),
                  trailing: ValueListenableBuilder<bool>(
                    valueListenable: isBusinessModeGlobal,
                    builder: (context, isActive, _) {
                      return Switch(
                        value: isActive,
                        activeColor: Colors.blueAccent,
                        onChanged: (val) {
                          // 🔥 1. VALIDACIÓN PREMIUM ANTES DE ACTIVAR 🔥
                          if (val == true) { 
                            final planConfig = Provider.of<PlanConfigService>(context, listen: false);
                            final authCore = Provider.of<AuthCoreService>(context, listen: false);
                            
                            // Validamos contra la palabra clave exacta de Spring Boot
                            if (!planConfig.hasFeature(authCore.currentTier, 'OPCION_NEGOCIO')) {
                              PremiumBlockerModal.show(context, planRequerido: "PREMIUM", featureName: "TTC Business (Punto de Venta)");
                              return; // Cancelamos el encendido del Switch
                            }
                          }

                          // 2. Si pasó la validación (o si lo está apagando), aplicamos el cambio
                          isBusinessModeGlobal.value = val;
                          Navigator.pop(context); // Cierra el perfil
                        },
                      );
                    }
                  ),
                ),
                  Divider(color: onSurfaceColor.withOpacity(0.1), height: 30),
                  ListTile(
                   leading: Icon(Icons.delete_forever_rounded, color: colorScheme.error), // 🔥 Error
                    title: Text("Desvincular Cartera", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                      "Borra los datos de este dispositivo",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () => _borrarCartera(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
