import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/decoy_wallet_setup_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/devices_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_config_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  UserService get userService => Provider.of<UserService>(context, listen: false);
  UserConfigService get configService => Provider.of<UserConfigService>(context, listen: false);
  
  late String _selectedTheme;
  
  bool _isLoadingNotifications = true;
  bool _is2faEnabled = false;
  bool _isFrozen = false;
  bool _isLoadingSecurity = true;
  bool _cargandoConfiguraciones = true;
  
  // Variables M3 Mapeadas con BD
  bool _notifyEmail = true;
  bool _notifyWhatsapp = false;
  bool _notifyPush = true;
  bool _showCrowdfunding = true;
  bool _paypalEnabled = false;
  
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _paypalEmailController = TextEditingController();
  bool _guardandoPaypal = false;

  @override
  void initState() {
    super.initState();
    _recuperarConfiguracionesRemotas();
    _cargarEstadoSeguridad();
    
    // Leemos en qué estado está el interruptor global del tema
    if (themeNotifier.value == ThemeMode.light) {
      _selectedTheme = 'Claro';
    } else if (themeNotifier.value == ThemeMode.dark) {
      _selectedTheme = 'Oscuro';
    } else {
      _selectedTheme = 'Sistema';
    }
  }

  Future<void> _recuperarConfiguracionesRemotas() async {
    print("📝 [LOG UI] Cargando preferencias de usuario...");
    final data = await configService.getConfig();
    if (data != null && mounted) {
      setState(() {
        _notifyEmail = data['notifyEmail'] ?? true;
        _notifyWhatsapp = data['notifyWhatsapp'] ?? false;
        _notifyPush = data['notifyPush'] ?? true;
        _showCrowdfunding = data['showCrowdfunding'] ?? true;
        _paypalEnabled = data['paypalEnabled'] ?? false;
        _limitController.text = (data['dailyFiatLimit'] ?? 500.0).toString();
        _paypalEmailController.text = _paypalEnabled ? "********@paypal.com" : "";
        
        // Asignar variables globales de tu lógica anterior
        showCrowdfundingGlobal.value = _showCrowdfunding;
        
        _cargandoConfiguraciones = false;
        _isLoadingNotifications = false;
      });
      
      // Hacemos una llamada extra al usuario base solo para saber si tiene el 2FA prendido
      final userBase = await userService.getAnalyticsData();
      if (userBase != null && mounted) {
        setState(() {
           _is2faEnabled = userBase['is2faEnabled'] ?? false;
        });
      }
    } else {
      if (mounted) setState(() {
         _cargandoConfiguraciones = false;
         _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _cargarEstadoSeguridad() async {
    bool frozenStatus = await userService.checkIfFrozen();
    if (mounted) {
      setState(() {
        _isFrozen = frozenStatus;
        _isLoadingSecurity = false; 
      });
    }
  }

  void _guardarPreferenciasNotificaciones() async {
    print("📝 [LOG UI] Enviando guardado de notificaciones...");
    bool ok = await configService.updateNotificationPreferences(_notifyEmail, _notifyWhatsapp, _notifyPush);
    if (!ok) UIHelper.showCustomSnackbar("Error al sincronizar preferencias", isError: true);
  }

  Future<void> _guardarPreferenciaCrowdfunding(bool val) async {
    setState(() => _showCrowdfunding = val);
    showCrowdfundingGlobal.value = val;
    bool ok = await configService.updateCrowdfundingVisibility(val);
    if (!ok) {
      UIHelper.showCustomSnackbar("Error al actualizar visibilidad de Crowdfunding", isError: true);
      setState(() => _showCrowdfunding = !val);
      showCrowdfundingGlobal.value = !val;
    }
  }

  Future<void> _iniciarActivacion2FA() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool isAuth = await authCore.authenticateUser();
    if (!isAuth) {
      UIHelper.showCustomSnackbar("Autenticación cancelada", isError: true);
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (c) => Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.generate2FA),
        headers: {"Content-Type": "application/json", if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"},
        body: jsonEncode({"walletAddress": authCore.publicAddress.toLowerCase()})
      );
      if (!mounted) return;
      Navigator.pop(context); 
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _mostrarModalConfiguracion2FA(data['qrUrl'], data['secret']);
      } else {
        UIHelper.showCustomSnackbar("Error al generar 2FA", isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      UIHelper.showCustomSnackbar("Error de conexión", isError: true);
    }
  }

  void _mostrarModalConfiguracion2FA(String qrUrl, String secret) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController codeController = TextEditingController();
    bool verificando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, size: 50, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text("Configurar Google Authenticator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 10),
              Text("1. Escanea este código QR con tu aplicación de autenticación.", textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: qrUrl, version: QrVersions.auto, size: 180.0, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 20),
              Text("2. Ingresa el código de 6 dígitos generado.", textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: verificando ? null : () async {
                    if (codeController.text.length != 6) return;
                    setModalState(() => verificando = true);
                    try {
                      final res = await http.post(
                        Uri.parse(ApiConfig.enable2FA),
                        headers: {"Content-Type": "application/json", if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"},
                        body: jsonEncode({"walletAddress": authCore.publicAddress.toLowerCase(), "code": codeController.text})
                      );
                      if (res.statusCode == 200) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        setState(() => _is2faEnabled = true);
                        ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("¡Doble Factor de Seguridad Activado! 🛡️"), backgroundColor: Colors.green));
                      } else {
                        setModalState(() => verificando = false);
                        UIHelper.showCustomSnackbar("Código incorrecto", isError: true);
                      }
                    } catch (e) {
                      setModalState(() => verificando = false);
                      UIHelper.showCustomSnackbar("Error de red", isError: true);
                    }
                  },
                  child: verificando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Verificar y Activar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarLlavePrivada(String privateKey) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor; 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 60),
            const SizedBox(height: 10),
            Text("NUNCA COMPARTAS ESTA LLAVE", style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("Cualquier persona con esta llave tendrá acceso total a tus fondos. El soporte de TTC nunca te pedirá esta llave.", style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: privateKey, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.error.withOpacity(0.5))),
              child: Row(
                children: [
                  Expanded(child: Text(privateKey, style: TextStyle(color: onSurfaceColor, fontFamily: 'monospace', fontSize: 12), textAlign: TextAlign.center)),
                  IconButton(
                    icon: Icon(Icons.copy, color: colorScheme.primary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: privateKey));
                      UIHelper.showCustomSnackbar("Llave copiada. ¡Mantenla segura!");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: onSurfaceColor.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar", style: TextStyle(color: onSurfaceColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoLimite(BuildContext context) {
    final TextEditingController limitController = TextEditingController();
    bool actualizando = false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
          title: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.security_rounded, color: colorScheme.primary)),
              const SizedBox(width: 12),
              Expanded(child: Text("Límite Diario", style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ingresa el nuevo límite máximo para transacciones Fiat. Requerimos tu huella dactilar para confirmar.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14, height: 1.4)),
              const SizedBox(height: 24),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money_rounded, color: colorScheme.primary),
                  hintText: "Ej: 1000",
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                  filled: true,
                  fillColor: colorScheme.onSurface.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: actualizando ? null : () async {
                if (limitController.text.isEmpty) return;
                bool isAuth = await authCore.authenticateUser();
                if (!isAuth) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Autenticación cancelada", style: TextStyle(color: Colors.white)), backgroundColor: colorScheme.error));
                  return;
                }
                setStateDialog(() => actualizando = true);
                
                double newLimit = double.tryParse(limitController.text) ?? 0.0;
                print("📝 [LOG UI] Llamando al servicio modular para actualizar límite a $newLimit");
                bool success = await configService.updateDailyLimit(newLimit);
                
                setStateDialog(() => actualizando = false);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                if (success) {
                  setState(() => _limitController.text = newLimit.toString());
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Límite actualizado de forma segura 🔒", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Error al actualizar el límite", style: TextStyle(color: Colors.white)), backgroundColor: colorScheme.error));
                }
              },
              icon: actualizando ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) : const Icon(Icons.fingerprint_rounded, size: 20),
              label: Text(actualizando ? "Guardando..." : "Autenticar", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pedirCodigo2FA(BuildContext context, bool isFreezing) async {
    String codigo = "";
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.security_rounded, color: isFreezing ? Colors.red : Colors.green),
              const SizedBox(width: 10),
              const Text("Autenticación 2FA"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isFreezing ? "Para congelar tu cuenta, ingresa el código de tu Google Authenticator." : "Para reactivar tu cuenta, verifica tu identidad con el código 2FA."),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(hintText: "000000", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onChanged: (val) => codigo = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isFreezing ? Colors.red : Colors.green, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, codigo),
              child: const Text("Verificar"),
            )
          ],
        );
      }
    );
  }

  void _mostrarAlertaDebeActivar2FA(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 50),
        title: const Text("Seguridad Incompleta", textAlign: TextAlign.center),
        content: const Text("No puedes usar la Zona de Peligro porque tu cuenta no tiene Autenticación de Doble Factor.\n\nPor favor, habilita Google Authenticator y vuelve a intentarlo.", textAlign: TextAlign.center),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido")))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text("Configuración", style: TextStyle(color: onSurfaceColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      body: _cargandoConfiguraciones 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= APARIENCIA =================
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
                child: Text("APARIENCIA", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(Icons.dark_mode, color: onSurfaceColor.withOpacity(0.7)),
                  title: Text("Tema de la aplicación", style: TextStyle(color: onSurfaceColor)),
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    dropdownColor: cardColor,
                    style: TextStyle(color: onSurfaceColor),
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                    items: <String>['Claro', 'Oscuro', 'Sistema'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue == null) return;
                      setState(() => _selectedTheme = newValue);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('themeMode', newValue);

                      if (newValue == 'Claro') themeNotifier.value = ThemeMode.light;
                      else if (newValue == 'Oscuro') themeNotifier.value = ThemeMode.dark;
                      else themeNotifier.value = ThemeMode.system;

                      UIHelper.showCustomSnackbar("Tema $_selectedTheme aplicado", isError: false);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ValueListenableBuilder<bool>(
                valueListenable: customCardNotifier,
                builder: (context, isCustom, _) {
                  return ListTile(
                    leading: Icon(Icons.palette_outlined, color: isCustom ? theme.colorScheme.primary : Colors.grey),
                    title: const Text("Tarjeta Personalizada", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Usar colores basados en tu Smart Avatar"),
                    trailing: Switch(
                      value: isCustom,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        customCardNotifier.value = val;
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              ListTile(
                leading: Icon(Icons.security, color: colorScheme.primary),
                title: Text("Límite Transaccional Diario", style: TextStyle(color: onSurfaceColor)),
                subtitle: Text("Controla cuánto dinero fiduciario puedes mover al día.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6))),
                trailing: Icon(Icons.edit, color: onSurfaceColor.withOpacity(0.4), size: 18),
                onTap: () => _mostrarDialogoLimite(context),
              ),
              const SizedBox(height: 24),

              // ================= CONEXIÓN =================
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
                child: Text("CONEXIÓN", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(Icons.wifi_tethering, color: onSurfaceColor.withOpacity(0.7)),
                  title: Text("Red actual", style: TextStyle(color: onSurfaceColor)),
                  subtitle: const Text("Local Available Network", style: TextStyle(color: Colors.grey)),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Conectado", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.circle, color: Colors.green, size: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ================= NOTIFICACIONES =================
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
                child: Text("NOTIFICACIONES", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: _isLoadingNotifications
                    ? Padding(padding: const EdgeInsets.all(20.0), child: Center(child: CircularProgressIndicator(color: colorScheme.primary)))
                    : Column(
                        children: [
                          SwitchListTile(
                            activeColor: colorScheme.primary,
                            title: Text("Notificaciones Push", style: TextStyle(color: onSurfaceColor)),
                            subtitle: Text("Alertas en tu celular", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                            secondary: Icon(Icons.notifications_active, color: colorScheme.secondary),
                            value: _notifyPush,
                            onChanged: (val) {
                              setState(() => _notifyPush = val);
                              _guardarPreferenciasNotificaciones();
                            },
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),
                          SwitchListTile(
                            activeColor: colorScheme.primary,
                            title: Text("Correos Electrónicos", style: TextStyle(color: onSurfaceColor)),
                            subtitle: Text("Recibos y estados de cuenta", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                            secondary: Icon(Icons.email, color: colorScheme.primary),
                            value: _notifyEmail,
                            onChanged: (val) {
                              setState(() => _notifyEmail = val);
                              _guardarPreferenciasNotificaciones();
                            },
                          ),
                          Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),
                          SwitchListTile(
                            activeColor: colorScheme.primary,
                            title: Text("Alertas por WhatsApp", style: TextStyle(color: onSurfaceColor)),
                            subtitle: Text("Avisos de transferencias grandes", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                            secondary: const Icon(Icons.chat, color: Colors.green),
                            value: _notifyWhatsapp,
                            onChanged: (val) {
                              setState(() => _notifyWhatsapp = val);
                              _guardarPreferenciasNotificaciones();
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: SwitchListTile(
                  activeColor: colorScheme.primary,
                  title: Text("Sección de Impacto Social", style: TextStyle(color: onSurfaceColor)),
                  subtitle: Text("Muestra la pestaña de donaciones y Crowdfunding comunitario en el menú inferior.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12)),
                  secondary: Icon(Icons.volunteer_activism_rounded, color: colorScheme.primary),
                  value: _showCrowdfunding,
                  onChanged: _guardarPreferenciaCrowdfunding,
                ),
              ),
              const SizedBox(height: 12),

              // ================= SEGURIDAD Y PASARELAS =================
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
                child: Text("SEGURIDAD Y PAGOS FIAT", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.shield, color: _is2faEnabled ? Colors.green : onSurfaceColor.withOpacity(0.7)),
                      title: Text("Autenticador de Google (2FA)", style: TextStyle(color: onSurfaceColor)),
                      subtitle: Text(
                        _is2faEnabled ? "Activado y protegiendo tu cuenta" : "Añade una capa extra de seguridad",
                        style: TextStyle(color: _is2faEnabled ? Colors.green : onSurfaceColor.withOpacity(0.5), fontSize: 12),
                      ),
                      trailing: _is2faEnabled 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: _iniciarActivacion2FA,
                            child: const Text("Activar", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      onTap: _is2faEnabled ? () {
                        UIHelper.showCustomSnackbar("El 2FA está activado. Contacte a soporte para desactivarlo.", isError: false);
                      } : _iniciarActivacion2FA,
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),
                    
                    ListTile(
                      leading: Icon(Icons.account_balance_wallet, color: onSurfaceColor.withOpacity(0.7)),
                      title: Text("Dirección Pública", style: TextStyle(color: onSurfaceColor)),
                      subtitle: Text(authCore.publicAddress, style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12), overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(Icons.copy, color: colorScheme.primary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: authCore.publicAddress));
                          UIHelper.showCustomSnackbar("Dirección copiada", isError: false);
                        },
                      ),
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),

                    // BOTÓN DE PÁNICO
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning_amber_rounded, color: Colors.white)),
                        title: const Text("Botón de Pánico", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Congela instantáneamente todas las salidas de dinero si crees que tu cuenta está en riesgo."),
                        trailing: _isLoadingSecurity 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Switch(
                              activeColor: Colors.red,
                              value: _isFrozen, 
                              onChanged: (val) async {
                                String? codigo = await _pedirCodigo2FA(context, val);
                                if (codigo == null || codigo.length != 6) return; 
                                setState(() => _isLoadingSecurity = true);
                                String resultado = await userService.toggleAccountFreeze(val, codigo);
                                if (mounted) setState(() => _isLoadingSecurity = false);

                                if (resultado == "SUCCESS") {
                                  setState(() => _isFrozen = val);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "Cuenta Congelada 🥶. Envíos bloqueados." : "Cuenta Reactivada 🟢. Operaciones normales."), backgroundColor: val ? Colors.red : Colors.green));
                                } else if (resultado.contains("2FA_REQUIRED")) {
                                  _mostrarAlertaDebeActivar2FA(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado), backgroundColor: Colors.orange));
                                }
                              },
                            ),
                      ),
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),

                    // DISPOSITIVOS VINCULADOS
                    ListTile(
                      leading: Icon(Icons.devices_rounded, color: colorScheme.primary),
                      title: const Text("Dispositivos Vinculados", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Revisa dónde está abierta tu sesión y revoca accesos."),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DevicesScreen()));
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),

                    // BÓVEDA SEÑUELO
                    ListTile(
                      leading: const Icon(Icons.sos_rounded, color: Colors.redAccent),
                      title: Text("Modo Pánico / Bóveda Señuelo", style: TextStyle(color: onSurfaceColor)),
                      subtitle: Text("Oculta tus fondos en caso de coerción", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: onSurfaceColor.withOpacity(0.5), size: 16),
                      onTap: () async {
                        bool isAuth = await authCore.authenticateUser();
                        if (!isAuth) {
                          UIHelper.showCustomSnackbar("Autenticación biométrica requerida", isError: true);
                          return;
                        }
                        if (_is2faEnabled) {
                          String? codigo = await _pedirCodigo2FA(context, false);
                          if (codigo == null || codigo.length != 6) {
                             UIHelper.showCustomSnackbar("Código 2FA incorrecto o expirado", isError: true);
                             return;
                          }
                        }
                        if (!mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DecoyWalletSetupScreen()));
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),

                    // CONFIGURACIÓN DE PAYPAL
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Activar pagos con PayPal", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Permite que otros usuarios te envíen dinero Fiat directo a tu cuenta bancaria/PayPal."),
                            value: _paypalEnabled,
                            activeColor: colorScheme.primary,
                            onChanged: (val) => setState(() => _paypalEnabled = val),
                          ),
                          if (_paypalEnabled) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _paypalEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: "Correo Electrónico de PayPal",
                                prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                hintText: "ejemplo@paypal.com"
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                onPressed: _guardandoPaypal ? null : () async {
                                  if (_paypalEmailController.text.trim().isEmpty) {
                                    UIHelper.showCustomSnackbar("Por favor ingresa tu correo de PayPal", isError: true);
                                    return;
                                  }
                                  setState(() => _guardandoPaypal = true);
                                  print("📝 [LOG UI] Guardando pasarela PayPal...");
                                  bool ok = await configService.savePayPalConfig(_paypalEnabled, _paypalEmailController.text);
                                  setState(() => _guardandoPaypal = false);
                                  if (ok) {
                                    UIHelper.showCustomSnackbar("¡Pasarela de PayPal configurada de forma encriptada!");
                                  } else {
                                    UIHelper.showCustomSnackbar("Error al guardar credenciales", isError: true);
                                  }
                                },
                                icon: _guardandoPaypal ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.security_rounded),
                                label: const Text("Guardar Cuenta Encriptada", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                    Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),

                    // LLAVE PRIVADA
                    ListTile(
                      leading: Icon(Icons.vpn_key, color: colorScheme.error),
                      title: Text("Revelar Llave Privada", style: TextStyle(color: onSurfaceColor)),
                      subtitle: Text("Peligro: NUNCA compartas esta llave", style: TextStyle(color: colorScheme.error, fontSize: 11)),
                      trailing: Icon(Icons.visibility, color: onSurfaceColor.withOpacity(0.5)),
                      onTap: () async {
                        String? privateKeyHex = await authCore.exportPrivateKey();
                        if (!mounted) return;
                        if (privateKeyHex != null) {
                          _mostrarLlavePrivada(privateKeyHex);
                        } else {
                          UIHelper.showCustomSnackbar("Autenticación requerida para ver la llave.", isError: true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

// class SettingsScreen extends StatefulWidget {
//  // final BlockchainService service;

//   const SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   // 🔥 AGREGAR:
//   AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
//   UserService get userService => Provider.of<UserService>(context, listen: false);
  
//   late String _selectedTheme;
//   final bool _isDarkMode = true;
//   // bool _notifyEmail = true;
//   // bool _notifyWhatsapp = false;
//   // bool _notifyPush = true;
//   bool _isLoadingNotifications = true;
//   bool _isSavingNotifications = false;
//   bool _is2faEnabled = false;
//   bool _isFrozen = false;
//   bool _isLoadingSecurity = true;
//   // bool _showCrowdfunding = true;

// UserConfigService get configService => Provider.of<UserConfigService>(context, listen: false);

// bool _cargandoConfiguraciones = true;
  
//   // Variables de estados M3 mapeadas uno a uno con la base de datos modular
//   bool _notifyEmail = true;
//   bool _notifyWhatsapp = false;
//   bool _notifyPush = true;
//   bool _showCrowdfunding = true;
//   bool _paypalEnabled = false;
//   final TextEditingController _limitController = TextEditingController();
//   final TextEditingController _paypalEmailController = TextEditingController();

//   // bool _paypalEnabled = false;
//   // final TextEditingController _paypalEmailController = TextEditingController();
//   bool _guardandoPaypal = false;

//   @override
//   void initState() {
//     super.initState();
//     //_loadNotificationPreferences();
//     _recuperarConfiguracionesRemotas();
//     _cargarEstadoSeguridad();
//     // Cuando la pantalla se abre, leemos en qué estado está el interruptor global
//     if (themeNotifier.value == ThemeMode.light) {
//       _selectedTheme = 'Claro';
//     } else if (themeNotifier.value == ThemeMode.dark) {
//       _selectedTheme = 'Oscuro';
//     } else {
//       _selectedTheme = 'Sistema';
//     }
//   }

//   Future<void> _recuperarConfiguracionesRemotas() async {
//     final data = await configService.getConfig();
//     if (data != null && mounted) {
//       setState(() {
//         _notifyEmail = data['notifyEmail'] ?? true;
//         _notifyWhatsapp = data['notifyWhatsapp'] ?? false;
//         _notifyPush = data['notifyPush'] ?? true;
//         _showCrowdfunding = data['showCrowdfunding'] ?? true;
//         _paypalEnabled = data['paypalEnabled'] ?? false;
//         _limitController.text = (data['dailyFiatLimit'] ?? 500.0).toString();
//         // Nota: El email viene encriptado en base de datos. Si deseas mostrar un placeholder o guardarlo limpio:
//         _paypalEmailController.text = _paypalEnabled ? "********@paypal.com" : "";
//         _cargandoConfiguraciones = false;
//       });
//     } else {
//       if (mounted) setState(() => _cargandoConfiguraciones = false);
//     }
//   }

//   Future<void> _cargarEstadoSeguridad() async {
//     bool frozenStatus = await userService.checkIfFrozen();
//     if (mounted) {
//       setState(() {
//         _isFrozen = frozenStatus;
//         _isLoadingSecurity = false; // Ya tenemos la verdad absoluta
//       });
//     }
//   }

//   // Future<void> _loadNotificationPreferences() async {
//   //  // final theme = Theme.of(context);
//   //   //final colorScheme = theme.colorScheme;
//   //  // final onSurface = colorScheme.onSurface;
//   //   setState(() => _isLoadingNotifications = true);
//   //   try {
//   //     // Reutilizamos tu endpoint existente para obtener los datos del usuario
//   //     String endpoint = ApiConfig.getAliasWallet.replaceAll(
//   //       "{address}",
//   //       authCore.publicAddress.toLowerCase(),
//   //     );
//   //     final res = await http.get(
//   //       Uri.parse(endpoint),
//   //       headers: {
//   //         "Content-Type": "application/json",
//   //         if (authCore.jwtToken != null)
//   //           "Authorization": "Bearer ${authCore.jwtToken}",
//   //       },
//   //     );

//   //     if (res.statusCode == 200) {
//   //       final data = jsonDecode(res.body);
//   //       if (mounted) {
//   //         setState(() {
//   //           // Leemos de la BD, si vienen nulos, ponemos los valores por defecto
//   //           _notifyEmail = data['notifyEmail'] ?? true;
//   //           _notifyWhatsapp = data['notifyWhatsapp'] ?? false;
//   //           _notifyPush = data['notifyPush'] ?? true;
//   //           _is2faEnabled = data['is2faEnabled'] ?? false;
//   //           _showCrowdfunding = data['showCrowdfunding'] ?? true;
//   //           showCrowdfundingGlobal.value = _showCrowdfunding;
//   //           _isLoadingNotifications = false;
//   //         });
//   //       }
//   //     } else {
//   //       if (mounted) setState(() => _isLoadingNotifications = false);
//   //     }
//   //   } catch (e) {
//   //     print("Error cargando notificaciones: $e");
//   //     if (mounted) setState(() => _isLoadingNotifications = false);
//   //   }
//   // }

//   Future<void> _iniciarActivacion2FA() async {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
//     // 1. Pedimos huella por seguridad antes de generar códigos
//     bool isAuth = await authCore.authenticateUser();
//     if (!isAuth) {
//       UIHelper.showCustomSnackbar("Autenticación cancelada", isError: true);
//       return;
//     }

//     showDialog(context: context, barrierDismissible: false, builder: (c) => Center(child: CircularProgressIndicator(color: colorScheme.primary)));

//     try {
//       // 2. Pedimos al servidor que genere el secreto
//       final res = await http.post(
//         Uri.parse(ApiConfig.generate2FA),
//         headers: {
//           "Content-Type": "application/json",
//           if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//         },
//         body: jsonEncode({"walletAddress": authCore.publicAddress.toLowerCase()})
//       );

//       if (!mounted) return;
//       Navigator.pop(context); // Quitamos el loading

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         String qrUrl = data['qrUrl'];
//         String secret = data['secret'];
        
//         // 3. Mostramos el Modal con el QR
//         _mostrarModalConfiguracion2FA(qrUrl, secret);
//       } else {
//         UIHelper.showCustomSnackbar("Error al generar 2FA", isError: true);
//       }
//     } catch (e) {
//       Navigator.pop(context);
//       UIHelper.showCustomSnackbar("Error de conexión", isError: true);
//     }
//   }

//   Future<void> _guardarPreferenciaCrowdfunding(bool val) async {
//     setState(() => _showCrowdfunding = val);
//     showCrowdfundingGlobal.value = val;
//     try {
//       String endpoint = ApiConfig.toggleCrowdfunding.replaceAll("{address}", authCore.publicAddress.toLowerCase());
//       final res = await http.put(
//         Uri.parse(endpoint),
//         headers: {
//           "Content-Type": "application/json",
//           if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}",
//         },
//         body: jsonEncode({"showCrowdfunding": val}),
//       );

//       if (res.statusCode != 200) {
//         UIHelper.showCustomSnackbar("Error al actualizar estado", isError: true);
//         setState(() => _showCrowdfunding = !val); // Revertir si falla
//       }
//     } catch (e) {
//       UIHelper.showCustomSnackbar("Error de red", isError: true);
//       setState(() => _showCrowdfunding = !val);
//     }
//   }

// void _mostrarModalConfiguracion2FA(String qrUrl, String secret) {
//   final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
//     final TextEditingController codeController = TextEditingController();
//     bool verificando = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Padding(
//           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.security, size: 50, color: colorScheme.primary),
//               const SizedBox(height: 10),
//               Text("Configurar Google Authenticator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
//               const SizedBox(height: 10),
//               Text("1. Escanea este código QR con tu aplicación de autenticación.", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
//               const SizedBox(height: 20),
              
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
//                 child: QrImageView(data: qrUrl, version: QrVersions.auto, size: 180.0, backgroundColor: Colors.white),
//               ),
//               const SizedBox(height: 20),
              
//               Text("2. Ingresa el código de 6 dígitos generado.", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
//               const SizedBox(height: 10),
              
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
//               const SizedBox(height: 20),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                   onPressed: verificando ? null : () async {
//                     if (codeController.text.length != 6) return;
//                     setModalState(() => verificando = true);

//                     try {
//                       final res = await http.post(
//                         Uri.parse(ApiConfig.enable2FA),
//                         headers: {
//                           "Content-Type": "application/json",
//                           if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//                         },
//                         body: jsonEncode({
//                           "walletAddress": authCore.publicAddress.toLowerCase(),
//                           "code": codeController.text
//                         })
//                       );

//                       if (res.statusCode == 200) {
//                         if (!mounted) return;
//                         Navigator.pop(ctx);
//                         setState(() => _is2faEnabled = true);
//                         ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("¡Doble Factor de Seguridad Activado! 🛡️"), backgroundColor: Colors.green));
//                       } else {
//                         setModalState(() => verificando = false);
//                         UIHelper.showCustomSnackbar("Código incorrecto", isError: true);
//                       }
//                     } catch (e) {
//                       setModalState(() => verificando = false);
//                       UIHelper.showCustomSnackbar("Error de red", isError: true);
//                     }
//                   },
//                   child: verificando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Verificar y Activar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _mostrarLlavePrivada(String privateKey) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
//     final onSurfaceColor = Theme.of(
//       context,
//     ).colorScheme.onSurface; // <-- AGREGAR
//     final cardColor = Theme.of(context).cardColor; // <-- AGREGAR
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           // <-- QUITAR CONST
//           color: cardColor, // <-- CAMBIO
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.warning_amber_rounded,
//               color: colorScheme.error,
//               size: 60,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "NUNCA COMPARTAS ESTA LLAVE",
//               style: TextStyle(
//                 color: colorScheme.error,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               // <-- QUITAR CONST
//               "Cualquier persona con esta llave tendrá acceso total a tus fondos. El soporte de TTC nunca te pedirá esta llave.",
//               style: TextStyle(
//                 color: onSurfaceColor.withOpacity(0.7),
//                 fontSize: 14,
//               ), // <-- CAMBIO
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),

//             // Código QR de la Llave Privada
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: QrImageView(
//                 data: privateKey,
//                 version: QrVersions.auto,
//                 size: 200.0,
//                 backgroundColor: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Caja con la llave en texto
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: onSurfaceColor.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: colorScheme.error.withOpacity(0.5)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       privateKey,
//                       style: TextStyle(
//                         color: onSurfaceColor,
//                         fontFamily: 'monospace',
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.copy, color: colorScheme.primary),
//                     onPressed: () {
//                       HapticFeedback.lightImpact();
//                       Clipboard.setData(ClipboardData(text: privateKey));
//                       UIHelper.showCustomSnackbar("Llave copiada. ¡Mantenla segura!"
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: onSurfaceColor.withOpacity(0.1),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: () => Navigator.pop(context),
//               child: Text("Cerrar", style: TextStyle(color: onSurfaceColor)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Future<void> _guardarPreferenciasNotificaciones() async {
//   //   final theme = Theme.of(context);
//   //   final colorScheme = theme.colorScheme;
//   //   final onSurface = colorScheme.onSurface;
//   //   setState(() => _isSavingNotifications = true);
//   //   try {
//   //     // 🔥 USAMOS EL ENDPOINT DEL API_CONFIG 🔥
//   //     String endpoint = ApiConfig.updateNotifications.replaceAll(
//   //       "{address}",
//   //       authCore.publicAddress.toLowerCase(),
//   //     );

//   //     final res = await http.put(
//   //       Uri.parse(endpoint),
//   //       headers: {
//   //         "Content-Type": "application/json",
//   //         if (authCore.jwtToken != null)
//   //           "Authorization": "Bearer ${authCore.jwtToken}",
//   //       },
//   //       body: jsonEncode({
//   //         "notifyEmail": _notifyEmail,
//   //         "notifyWhatsapp": _notifyWhatsapp,
//   //         "notifyPush": _notifyPush,
//   //       }),
//   //     );

//   //     if (res.statusCode != 200) {
//   //       UIHelper.showCustomSnackbar("Error al guardar en el servidor", isError: true);
//   //     }
//   //   } catch (e) {
//   //     UIHelper.showCustomSnackbar("Error de red al guardar", isError: true);
//   //   } finally {
//   //     if (mounted) setState(() => _isSavingNotifications = false);
//   //   }
//   // }

//   void _guardarPreferenciasNotificaciones() async {
//     bool ok = await configService.updateNotificationPreferences(_notifyEmail, _notifyWhatsapp, _notifyPush);
//     if (!ok) UIHelper.showCustomSnackbar("Error al sincronizar preferencias", isError: true);
//   }

// void _mostrarDialogoLimite(BuildContext context) {
//     final TextEditingController limitController = TextEditingController();
//     bool actualizando = false;
    
//     // 🔥 REGLAS M3
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setStateDialog) => AlertDialog(
//           backgroundColor: theme.cardColor,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 🔥 M3 Borde de diálogo
//           title: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
//                 child: Icon(Icons.security_rounded, color: colorScheme.primary),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text("Límite Diario", style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 "Ingresa el nuevo límite máximo para transacciones Fiat. Requerimos tu huella dactilar para confirmar.",
//                 style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14, height: 1.4),
//               ),
//               const SizedBox(height: 24),
//               TextField(
//                 controller: limitController,
//                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                 style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.attach_money_rounded, color: colorScheme.primary),
//                   hintText: "Ej: 1000",
//                   hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
//                   filled: true,
//                   fillColor: colorScheme.onSurface.withOpacity(0.05), // 🔥 Input limpio
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 M3 Borde de Input
//                 ),
//               ),
//             ],
//           ),
//           actionsAlignment: MainAxisAlignment.center,
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: Text("Cancelar", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
//             ),
//             const SizedBox(width: 8),
//             ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorScheme.primary,
//                 foregroundColor: colorScheme.onPrimary,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 M3 Borde de Botón
//               ),
//               onPressed: actualizando
//                   ? null
//                   : () async {
//                       if (limitController.text.isEmpty) return;

//                       // 1. BIOMETRÍA
//                       bool isAuth = await authCore.authenticateUser();
//                       if (!isAuth) {
//                         if (!context.mounted) return;
//                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Autenticación cancelada", style: TextStyle(color: Colors.white)), backgroundColor: colorScheme.error));
//                         return;
//                       }

//                       setStateDialog(() => actualizando = true);

//                       // 2. LLAMADA LIMPIA AL SERVICIO
//                       double newLimit = double.tryParse(limitController.text) ?? 0.0;
//                       bool success = await userService.updateDailyLimit(newLimit);

//                       setStateDialog(() => actualizando = false);

//                       if (!context.mounted) return;
//                       Navigator.pop(ctx);

//                       if (success) {
//                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Límite actualizado de forma segura 🔒", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Error al actualizar el límite", style: TextStyle(color: Colors.white)), backgroundColor: colorScheme.error));
//                       }
//                     },
//               icon: actualizando 
//                 ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
//                 : const Icon(Icons.fingerprint_rounded, size: 20),
//               label: Text(actualizando ? "Guardando..." : "Autenticar", style: const TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// Future<String?> _pedirCodigo2FA(BuildContext context, bool isFreezing) async {
//     String codigo = "";
//     return showDialog<String>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: Row(
//             children: [
//               Icon(Icons.security_rounded, color: isFreezing ? Colors.red : Colors.green),
//               const SizedBox(width: 10),
//               const Text("Autenticación 2FA"),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(isFreezing 
//                 ? "Para congelar tu cuenta, ingresa el código de tu Google Authenticator."
//                 : "Para reactivar tu cuenta, verifica tu identidad con el código 2FA."),
//               const SizedBox(height: 15),
//               TextField(
//                 keyboardType: TextInputType.number,
//                 maxLength: 6,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
//                 decoration: InputDecoration(
//                   hintText: "000000",
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 onChanged: (val) => codigo = val,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, null), // Cancela
//               child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isFreezing ? Colors.red : Colors.green,
//                 foregroundColor: Colors.white
//               ),
//               onPressed: () => Navigator.pop(ctx, codigo),
//               child: const Text("Verificar"),
//             )
//           ],
//         );
//       }
//     );
//   }

//   // ⚠️ ALERTA: DEBE ACTIVAR 2FA PRIMERO
//   void _mostrarAlertaDebeActivar2FA(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 50),
//         title: const Text("Seguridad Incompleta", textAlign: TextAlign.center),
//         content: const Text(
//           "No puedes usar la Zona de Peligro porque tu cuenta no tiene Autenticación de Doble Factor.\n\nPor favor, ve a tu Perfil, habilita Google Authenticator y vuelve a intentarlo.",
//           textAlign: TextAlign.center,
//         ),
//         actions: [
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("Entendido"),
//             ),
//           )
//         ],
//       )
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
    
//     final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
//     final cardColor = Theme.of(context).cardColor;
//     return Scaffold(
//       //backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         title: Text("Configuración", style: TextStyle(color: onSurfaceColor)),
//         backgroundColor: Colors.transparent,
//         iconTheme: IconThemeData(color: onSurfaceColor),
//         //elevation: 0,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
//             child: Text(
//               "APARIENCIA",
//               style: TextStyle(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Card(
//             color: cardColor,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: ListTile(
//               leading: Icon(
//                 Icons.dark_mode,
//                 color: onSurfaceColor.withOpacity(0.7),
//               ), // <-- CAMBIO
//               title: Text(
//                 "Tema de la aplicación",
//                 style: TextStyle(color: onSurfaceColor),
//               ), // <-- CAMBIO
//               trailing: DropdownButton<String>(
//                 value: _selectedTheme,
//                 dropdownColor: cardColor,
//                 style: TextStyle(color: onSurfaceColor),
//                 underline: const SizedBox(),
//                 icon: Icon(
//                   Icons.arrow_drop_down,
//                   color: colorScheme.primary,
//                 ),
//                 items: <String>['Claro', 'Oscuro', 'Sistema'].map((
//                   String value,
//                 ) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),

//                 onChanged: (String? newValue) async {
//                   if (newValue == null) return;

//                   setState(() {
//                     _selectedTheme = newValue;
//                   });

//                   // <-- AGREGADO: Guardamos la decisión en la memoria del teléfono -->
//                   final prefs = await SharedPreferences.getInstance();
//                   await prefs.setString('themeMode', newValue);

//                   // CAMBIAMOS EL TEMA GLOBAL AL INSTANTE
//                   if (newValue == 'Claro') {
//                     themeNotifier.value = ThemeMode.light;
//                   } else if (newValue == 'Oscuro') {
//                     themeNotifier.value = ThemeMode.dark;
//                   } else {
//                     themeNotifier.value = ThemeMode.system;
//                   }

//                   UIHelper.showCustomSnackbar("Tema $_selectedTheme aplicado", isError: false);
//                 },
//               ),
//             ),
//           ),
//           SizedBox(height: 24),


//           ValueListenableBuilder<bool>(
//   valueListenable: customCardNotifier,
//   builder: (context, isCustom, _) {
//     return ListTile(
//       leading: Icon(
//         Icons.palette_outlined, 
//         color: isCustom ? theme.colorScheme.primary : Colors.grey
//       ),
//       title: const Text("Tarjeta Personalizada", style: TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: const Text("Usar colores basados en tu Smart Avatar"),
//       trailing: Switch(
//         value: isCustom,
//         activeColor: theme.colorScheme.primary,
//         onChanged: (val) {
//           customCardNotifier.value = val;
//         },
//       ),
//     );
//   },
// ),

//           SizedBox(height: 24),
//           ListTile(
//             leading: Icon(Icons.security, color: colorScheme.primary),
//             title: Text(
//               "Límite Transaccional Diario",
//               style: TextStyle(color: onSurfaceColor),
//             ),
//             subtitle: Text(
//               "Controla cuánto dinero fiduciario puedes mover al día.",
//               style: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
//             ),
//             trailing: Icon(Icons.edit, color: onSurfaceColor.withOpacity(0.4), size: 18),
//             onTap: () => _mostrarDialogoLimite(context),
//           ),
//           const SizedBox(height: 24),

//           Padding(
//             padding: EdgeInsets.only(left: 8, bottom: 8),
//             child: Text(
//               "CONEXIÓN",
//               style: TextStyle(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Card(
//             color: cardColor,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: ListTile(
//               leading: Icon(
//                 Icons.wifi_tethering,
//                 color: onSurfaceColor.withOpacity(0.7),
//               ), // <-- CAMBIO
//               title: Text(
//                 "Red actual",
//                 style: TextStyle(color: onSurfaceColor),
//               ),
//               subtitle: Text(
//                 "Local Available Network",
//                 style: TextStyle(color: Colors.white54),
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: const [
//                   Text(
//                     "Conectado",
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Icon(Icons.circle, color: Colors.green, size: 12),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),

//           Padding(
//             padding: EdgeInsets.only(left: 8, bottom: 8, top: 10),
//             child: Text(
//               "NOTIFICACIONES",
//               style: TextStyle(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Card(
//             color: cardColor,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: _isLoadingNotifications
//                 ? Padding(
//                     padding: EdgeInsets.all(20.0),
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         color: colorScheme.primary,
//                       ),
//                     ),
//                   )
//                 : Column(
//                     children: [
//                       SwitchListTile(
//                         activeColor: colorScheme.primary,
//                         title: Text(
//                           "Notificaciones Push",
//                           style: TextStyle(color: onSurfaceColor),
//                         ),
//                         subtitle: Text(
//                           "Alertas en tu celular",
//                           style: TextStyle(
//                             color: onSurfaceColor.withOpacity(0.5),
//                             fontSize: 12,
//                           ),
//                         ),
//                         secondary: Icon(
//                           Icons.notifications_active,
//                           color: colorScheme.secondary,
//                         ),
//                         value: _notifyPush,
//                         onChanged: (val) {
//                           setState(() => _notifyPush = val);
//                           _guardarPreferenciasNotificaciones();
//                         },
//                       ),
//                       Divider(
//                         color: Theme.of(context).dividerColor,
//                         height: 1,
//                         indent: 60,
//                       ),
//                       SwitchListTile(
//                         activeColor: colorScheme.primary,
//                         title: Text(
//                           "Correos Electrónicos",
//                           style: TextStyle(color: onSurfaceColor),
//                         ),
//                         subtitle: Text(
//                           "Recibos y estados de cuenta",
//                           style: TextStyle(
//                             color: onSurfaceColor.withOpacity(0.5),
//                             fontSize: 12,
//                           ),
//                         ),
//                         secondary: Icon(
//                           Icons.email,
//                           color: colorScheme.primary,
//                         ),
//                         value: _notifyEmail,
//                         onChanged: (val) {
//                           setState(() => _notifyEmail = val);
//                           _guardarPreferenciasNotificaciones();
//                         },
//                       ),
//                       Divider(
//                         color: Theme.of(context).dividerColor,
//                         height: 1,
//                         indent: 60,
//                       ),
//                       SwitchListTile(
//                         activeColor: colorScheme.primary,
//                         title: Text(
//                           "Alertas por WhatsApp",
//                           style: TextStyle(color: onSurfaceColor),
//                         ),
//                         subtitle: Text(
//                           "Avisos de transferencias grandes",
//                           style: TextStyle(
//                             color: onSurfaceColor.withOpacity(0.5),
//                             fontSize: 12,
//                           ),
//                         ),
//                         secondary: const Icon(Icons.chat, color: Colors.green),
//                         value: _notifyWhatsapp,
//                         onChanged: (val) {
//                           setState(() => _notifyWhatsapp = val);
//                           _guardarPreferenciasNotificaciones();
//                         },
//                       ),
//                     ],
//                   ),
//           ),
//           const SizedBox(height: 24),
          
//           Card(
//             color: cardColor,
//             elevation: 0,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             child: SwitchListTile(
//               activeColor: colorScheme.primary,
//               title: Text("Sección de Impacto Social", style: TextStyle(color: onSurfaceColor)),
//               subtitle: Text(
//                 "Muestra la pestaña de donaciones y Crowdfunding comunitario en el menú inferior.",
//                 style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12),
//               ),
//               secondary: Icon(Icons.volunteer_activism_rounded, color: colorScheme.primary),
//               value: _showCrowdfunding,
//               onChanged: _guardarPreferenciaCrowdfunding,
//             ),
//           ),
//           const SizedBox(height: 12),

//           Padding(
//             padding: EdgeInsets.only(left: 8, bottom: 8),
//             child: Text(
//               "SEGURIDAD",
//               style: TextStyle(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Card(
//             color: cardColor,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               children: [

//                 ListTile(
//                   leading: Icon(Icons.shield, color: _is2faEnabled ? Colors.green : onSurfaceColor.withOpacity(0.7)),
//                   title: Text("Autenticador de Google (2FA)", style: TextStyle(color: onSurfaceColor)),
//                   subtitle: Text(
//                     _is2faEnabled ? "Activado y protegiendo tu cuenta" : "Añade una capa extra de seguridad",
//                     style: TextStyle(color: _is2faEnabled ? Colors.green : onSurfaceColor.withOpacity(0.5), fontSize: 12),
//                   ),
//                   trailing: _is2faEnabled 
//                     ? const Icon(Icons.check_circle, color: Colors.green)
//                     : ElevatedButton(
//                         style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
//                         onPressed: _iniciarActivacion2FA,
//                         child: const Text("Activar", style: TextStyle(color: Colors.white, fontSize: 12)),
//                       ),
//                   onTap: _is2faEnabled ? () {
//                     UIHelper.showCustomSnackbar("El 2FA está activado. Contacte a soporte para desactivarlo.", isError: false);
//                   } : _iniciarActivacion2FA,
//                 ),
                
//                 Divider(color: Theme.of(context).dividerColor, height: 1, indent: 60),
                
//                 ListTile(
//                   leading: Icon(
//                     Icons.account_balance_wallet,
//                     color: onSurfaceColor.withOpacity(0.7),
//                   ),
//                   title: Text(
//                     "Dirección Pública",
//                     style: TextStyle(color: onSurfaceColor),
//                   ),
//                   subtitle: Text(
//                     authCore.publicAddress,
//                     style: TextStyle(
//                       color: onSurfaceColor.withOpacity(0.5),
//                       fontSize: 12,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: IconButton(
//                     icon: Icon(Icons.copy, color: colorScheme.primary),
//                     onPressed: () {
//                       HapticFeedback.lightImpact();
//                       Clipboard.setData(
//                         ClipboardData(text: authCore.publicAddress),
//                       );
//                       UIHelper.showCustomSnackbar("Dirección copiada", isError: false);
//                     },
//                   ),
//                 ),

//                 Divider(
//                   color: Theme.of(context).dividerColor,
//                   height: 1,
//                   indent: 60,
//                 ),

//                 // Puedes poner esto dentro del ListView de tu SettingsScreen
// Card(
//   color: Colors.redAccent.withOpacity(0.1),
//   shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(20),
//     side: const BorderSide(color: Colors.redAccent),
//   ),
//   child: ListTile(
//     contentPadding: const EdgeInsets.all(16),
//     leading: const CircleAvatar(
//       backgroundColor: Colors.redAccent,
//       child: Icon(Icons.warning_amber_rounded, color: Colors.white),
//     ),
//     title: const Text("Botón de Pánico", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
//     subtitle: const Text("Congela instantáneamente todas las salidas de dinero si crees que tu cuenta está en riesgo."),
//     trailing: _isLoadingSecurity 
//       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//       : Switch(
//           activeColor: Colors.red,
//           value: _isFrozen, 
//           onChanged: (val) async {
//             // 1. Pedimos el código de Google Authenticator
//             String? codigo = await _pedirCodigo2FA(context, val);
            
//             // Si el usuario presionó "Cancelar" o dejó en blanco, abortamos
//             if (codigo == null || codigo.length != 6) return; 
            
//             setState(() => _isLoadingSecurity = true);

//             // 2. Enviamos el estado y el código al Backend
//             String resultado = await userService.toggleAccountFreeze(val, codigo);
            
//             if (mounted) setState(() => _isLoadingSecurity = false);

//             if (resultado == "SUCCESS") {
//               setState(() => _isFrozen = val);
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                 content: Text(val ? "Cuenta Congelada 🥶. Envíos bloqueados." : "Cuenta Reactivada 🟢. Operaciones normales."),
//                 backgroundColor: val ? Colors.red : Colors.green,
//               ));
//             } else if (resultado.contains("2FA_REQUIRED")) {
//               // 3. Atrapamos a los que no tienen el 2FA activado
//               _mostrarAlertaDebeActivar2FA(context);
//             } else {
//               // 4. Mostramos errores genéricos o código inválido
//               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                 content: Text(resultado), // "Código de autenticación 2FA incorrecto o expirado"
//                 backgroundColor: Colors.orange,
//               ));
//             }
//           },
//         ),
//   ),
// ),

// Divider(
//                   color: Theme.of(context).dividerColor,
//                   height: 1,
//                   indent: 60,
//                 ),

// Card(
//   color: theme.cardColor,
//   shape: RoundedRectangleBorder(
//     borderRadius: BorderRadius.circular(20),
//   side: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
//   ),
//   child: ListTile(
//     contentPadding: const EdgeInsets.all(16),
//     leading: CircleAvatar(
//       backgroundColor: colorScheme.primary.withOpacity(0.1),
//       child: Icon(Icons.devices_rounded, color: colorScheme.primary),
//     ),
//     title: const Text("Dispositivos Vinculados", style: TextStyle(fontWeight: FontWeight.bold)),
//     subtitle: const Text("Revisa dónde está abierta tu sesión y revoca accesos."),
//     trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
//     onTap: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => DevicesScreen()),
//       );
//     },
//   ),
// ),

// Divider(
//                   color: Theme.of(context).dividerColor,
//                   height: 1,
//                   indent: 60,
//                 ),


//                 // 🔥 NUEVO: BOTÓN DE CONFIGURACIÓN DEL MODO PÁNICO
//                 ListTile(
//                   leading: const Icon(Icons.sos_rounded, color: Colors.redAccent),
//                   title: Text(
//                     "Modo Pánico / Bóveda Señuelo",
//                     style: TextStyle(color: onSurfaceColor),
//                   ),
//                   subtitle: Text(
//                     "Oculta tus fondos en caso de coerción",
//                     style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios_rounded,
//                     color: onSurfaceColor.withOpacity(0.5),
//                     size: 16,
//                   ),
//                   onTap: () async {
//                     // 1. 🛡️ VERIFICACIÓN BIOMÉTRICA (Huella Dactilar)
//                     bool isAuth = await authCore.authenticateUser();
//                     if (!isAuth) {
//                       UIHelper.showCustomSnackbar("Autenticación biométrica requerida", isError: true);
//                       return;
//                     }

//                     // 2. 🔐 VERIFICACIÓN 2FA (Si está activado en la cuenta)
//                     if (_is2faEnabled) {
//                       // Reutilizamos tu modal de _pedirCodigo2FA
//                       String? codigo = await _pedirCodigo2FA(context, false);
                      
//                       if (codigo == null || codigo.length != 6) {
//                          UIHelper.showCustomSnackbar("Código 2FA incorrecto o expirado", isError: true);
//                          return;
//                       }
//                       // Nota: Aquí se asume que la pantalla de configuración (DecoyWalletSetupScreen) 
//                       // o el backend validarán el estado de la sesión, pero ya pasamos la barrera local.
//                     }

//                     if (!mounted) return;
                    
//                     // 3. 🚀 NAVEGAR A LA PANTALLA DE CONFIGURACIÓN
//                     Navigator.push(
//                       context, 
//                       MaterialPageRoute(
//                         builder: (_) => DecoyWalletSetupScreen() // Asegúrate de tener importada esta pantalla
//                       )
//                     );
//                   },
//                 ),

//                 Divider(
//                   color: Theme.of(context).dividerColor,
//                   height: 1,
//                   indent: 60,
//                 ),

// const SizedBox(height: 24),
//                 Text("Métodos de Pago Fiat", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
//                 const SizedBox(height: 8),
//                 Card(
//                   color: theme.cardColor,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         SwitchListTile(
//                           contentPadding: EdgeInsets.zero,
//                           title: const Text("Activar pagos con PayPal", style: TextStyle(fontWeight: FontWeight.bold)),
//                           subtitle: const Text("Permite que otros usuarios te envíen dinero Fiat directo a tu cuenta bancaria/PayPal."),
//                           value: _paypalEnabled,
//                           activeColor: colorScheme.primary,
//                           onChanged: (val) {
//                             setState(() => _paypalEnabled = val);
//                           },
//                         ),
//                         if (_paypalEnabled) ...[
//                           const SizedBox(height: 12),
//                           TextField(
//                             controller: _paypalEmailController,
//                             keyboardType: TextInputType.emailAddress,
//                             style: TextStyle(color: colorScheme.onSurface),
//                             decoration: InputDecoration(
//                               labelText: "Correo Electrónico de PayPal",
//                               prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
//                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//                               hintText: "ejemplo@paypal.com"
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             height: 48,
//                             child: ElevatedButton.icon(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: colorScheme.primary,
//                                 foregroundColor: colorScheme.onPrimary,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
//                               ),
//                               onPressed: _guardandoPaypal ? null : () async {
//                                 if (_paypalEmailController.text.trim().isEmpty) {
//                                   UIHelper.showCustomSnackbar("Por favor ingresa tu correo de PayPal", isError: true);
//                                   return;
//                                 }
//                                 setState(() => _guardandoPaypal = true);
//                                 final uService = Provider.of<UserService>(context, listen: false);
//                                 bool ok = await uService.savePayPalConfig(_paypalEnabled, _paypalEmailController.text);
//                                 setState(() => _guardandoPaypal = false);
                                
//                                 if (ok) {
//                                   UIHelper.showCustomSnackbar("¡Pasarela de PayPal configurada de forma encriptada!");
//                                 } else {
//                                   UIHelper.showCustomSnackbar("Error al guardar credenciales", isError: true);
//                                 }
//                               },
//                               icon: _guardandoPaypal 
//                                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                                 : const Icon(Icons.security_rounded),
//                               label: const Text("Guardar Cuenta Encriptada", style: TextStyle(fontWeight: FontWeight.bold)),
//                             ),
//                           )
//                         ]
//                       ],
//                     ),
//                   ),
//                 ),

//                 Divider(
//                   color: Theme.of(context).dividerColor,
//                   height: 1,
//                   indent: 60,
//                 ),



//                 ListTile(
//                   leading: Icon(Icons.vpn_key, color: colorScheme.error),
//                   title: Text(
//                     "Revelar Llave Privada",
//                     style: TextStyle(color: onSurfaceColor),
//                   ),
//                   subtitle: Text(
//                     "Peligro: NUNCA compartas esta llave",
//                     style: TextStyle(color: colorScheme.error, fontSize: 11),
//                   ),
//                   trailing: Icon(
//                     Icons.visibility,
//                     color: onSurfaceColor.withOpacity(0.5),
//                   ),
//                   onTap: () async {
//                     // 1. Llamamos al servicio (esto disparará el sensor de huella del celular)
//                     String? privateKeyHex = await authCore.exportPrivateKey();

//                     if (!mounted) return;

//                     // 2. Si la huella fue correcta y nos devolvió la llave, abrimos tu modal
//                     if (privateKeyHex != null) {
//                       _mostrarLlavePrivada(privateKeyHex);
//                     } else {
//                       // Si el usuario canceló la huella o falló
//                       UIHelper.showCustomSnackbar("Autenticación requerida para ver la llave.", isError: true);
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
