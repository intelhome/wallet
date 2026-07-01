import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DevicesScreen extends StatefulWidget {

  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  UserService get userService => Provider.of<UserService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _cargarDispositivos();
  }

  Future<void> _cargarDispositivos() async {
    setState(() => _isLoading = true);
   final data = await userService.getActiveDevices();
    if (mounted) {
      setState(() {
        _devices = data;
        _isLoading = false;
      });
    }
  }

  Future<String?> _pedirCodigo2FA(BuildContext context) async {
    String codigo = "";
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.security_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Autenticación 2FA"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Para revocar accesos en otros equipos, ingresa el código de tu Google Authenticator."),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "000000",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, codigo),
              child: const Text("Revocar Sesiones"),
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
        content: const Text(
          "Para revocar sesiones, primero debes habilitar la Autenticación de Doble Factor (2FA) en tu Perfil por motivos de seguridad.",
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Entendido"),
            ),
          )
        ],
      )
    );
  }

  Future<void> _revocarSesiones() async {
    // 1. Validar identidad con huella
    bool auth = await authCore.authenticateUser();
    if (!auth) return;

    // 2. Pedir código 2FA
    String? codigo = await _pedirCodigo2FA(context);
    if (codigo == null || codigo.length != 6) return;

    setState(() => _isLoading = true);
    
    // 3. Ejecutar acción en el servidor
    String resultado = await userService.revokeOtherSessions(codigo);
    
    if (mounted) setState(() => _isLoading = false);

    if (resultado == "SUCCESS") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Todas las demás sesiones han sido cerradas 🔒"),
        backgroundColor: Colors.green,
      ));
      _cargarDispositivos(); // Refrescar lista visual
    } else if (resultado.contains("2FA_REQUIRED")) {
      _mostrarAlertaDebeActivar2FA(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultado),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Dispositivos Vinculados"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sesiones Activas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "Aquí se muestran los dispositivos que tienen acceso a tu billetera. Revoca el acceso si no reconoces alguno.",
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // LISTA DE DISPOSITIVOS
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        bool isCurrent = device['deviceName'] == "Dispositivo Móvil (Android/iOS)"; 
                        
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrent ? Colors.green.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                isCurrent ? Icons.phone_android_rounded : Icons.desktop_windows_rounded,
                                color: isCurrent ? Colors.green : colorScheme.primary,
                              ),
                            ),
                            title: Text(device['deviceName'] ?? "Desconocido", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("IP: ${device['ipAddress'] ?? 'Oculta'}\nActivo: ${device['loginDate']?.toString().substring(0, 10) ?? 'Reciente'}"),
                            isThreeLine: true,
                            trailing: isCurrent 
                                ? const Text("ESTE EQUIPO", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  // BOTÓN DE REVOCAR (Solo si hay más de 1 dispositivo)
                  if (_devices.length > 1) 
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.redAccent)
                          ),
                        ),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text("Cerrar todas las demás sesiones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: _revocarSesiones,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}