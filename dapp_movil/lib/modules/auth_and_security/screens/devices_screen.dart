import 'package:dapp_movil/core/helpers/ui_helper.dart';
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
  bool _is2faEnabled = false;

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
    final userData = await userService.getAnalyticsData(); // Para saber si tiene 2FA
    
    // 🔥 ORDENAMOS DE MÁS RECIENTE A MÁS ANTIGUO (El más reciente es el dispositivo actual)
    data.sort((a, b) {
      final dateA = DateTime.tryParse(a['loginDate'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['loginDate'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); 
    });

    if (mounted) {
      setState(() {
        _devices = data;
        _is2faEnabled = userData?['is2faEnabled'] ?? false;
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
              const Text("Para desvincular este equipo, ingresa el código de tu Google Authenticator."),
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
              child: const Text("Confirmar"),
            )
          ],
        );
      }
    );
  }

  Future<void> _desvincularDispositivo(String loginDate) async {
    // 1. Validar identidad con huella SIEMPRE
    bool auth = await authCore.authenticateUser();
    if (!auth) {
      UIHelper.showCustomSnackbar("Autenticación cancelada", isError: true);
      return;
    }

    // 2. Pedir código 2FA SOLO si el usuario lo tiene configurado
    String? codigo;
    if (_is2faEnabled) {
      codigo = await _pedirCodigo2FA(context);
      if (codigo == null || codigo.length != 6) return;
    }

    setState(() => _isLoading = true);
    
    // 3. Ejecutar acción de desvinculación individual
    String resultado = await userService.revokeDevice(loginDate, codigo);
    
    if (mounted) setState(() => _isLoading = false);

    if (resultado == "SUCCESS") {
      UIHelper.showCustomSnackbar("Dispositivo desvinculado exitosamente 🔒", isError: false);
      _cargarDispositivos(); // Refresca la lista
    } else {
      UIHelper.showCustomSnackbar(resultado, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Dispositivos Vinculados", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.cardColor,
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
                    "Revisa qué dispositivos tienen acceso a tu cuenta en este momento. Toca el botón de desvincular para retirar el acceso inmediatamente.",
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: _devices.isEmpty 
                      ? const Center(child: Text("No hay dispositivos registrados."))
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            // El primer elemento (más reciente) es el dispositivo actual
                            bool isCurrent = index == 0; 
                            
                            // Formateamos la fecha para que sea legible
                            DateTime date = DateTime.tryParse(device['loginDate'] ?? '') ?? DateTime.now();
                            String dateFormatted = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                            
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isCurrent ? Colors.green.withOpacity(0.3) : Colors.transparent)
                              ),
                              elevation: 0,
                              color: theme.cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent ? Colors.green.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    isCurrent ? Icons.phone_android_rounded : Icons.computer_rounded,
                                    color: isCurrent ? Colors.green : colorScheme.primary,
                                  ),
                                ),
                                title: Text(device['deviceName'] ?? "Dispositivo", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("IP: ${device['ipAddress'] ?? 'Oculta'}\nÚltimo acceso: $dateFormatted", style: TextStyle(height: 1.3, fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
                                ),
                                isThreeLine: true,
                                trailing: isCurrent 
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Text("ESTE EQUIPO", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.phonelink_erase_rounded, color: Colors.redAccent),
                                        tooltip: "Desvincular Dispositivo",
                                        onPressed: () => _desvincularDispositivo(device['loginDate']),
                                      ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}