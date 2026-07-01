import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsGroupScreen extends StatefulWidget {
  //final BlockchainService service;
  final Map<String, dynamic> group;
  final bool isAdmin;

  const SettingsGroupScreen({
    super.key,
    required this.group,
    required this.isAdmin,
  });

  @override
  State<SettingsGroupScreen> createState() => _SettingsGroupScreenState();
}

class _SettingsGroupScreenState extends State<SettingsGroupScreen> {

  // 🔥 AGREGAR:
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);
  
  late double _currentThreshold;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Leemos el límite actual (o 100 si no existe)
    _currentThreshold = (widget.group['multisigThreshold'] as num?)?.toDouble() ?? 100.0;
  }

  Future<void> _proposeLimitChange() async {
    if (_currentThreshold < 30 || _currentThreshold > 2000) {
      UIHelper.showCustomSnackbar("El límite debe estar entre 30 y 2000 TTC", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    // Requiere huella
    bool auth = await authCore.authenticateUser();
    if (!auth) {
      setState(() => _isLoading = false);
      return;
    }

    String res = await groupService.proposeGroupThreshold(widget.group['id'], _currentThreshold);
    
    setState(() => _isLoading = false);

    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Propuesta enviada al grupo para votación.", isError: false);
      Navigator.pop(context); // Volvemos al dashboard
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
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
        title: const Text("Configuración del Grupo"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 🔥 SECCIÓN 1: GOBERNANZA (Solo Admin)
                if (widget.isAdmin) ...[
                  Text("Gobernanza y Seguridad", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.how_to_vote_rounded, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Text("Límite de Votación (TTC)", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Los pagos menores a ${_currentThreshold.toInt()} TTC se enviarán de forma instantánea. Los pagos iguales o mayores requerirán la firma unánime de todos los miembros activos.",
                          style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("30", style: TextStyle(color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                            Text("${_currentThreshold.toInt()} TTC", style: TextStyle(color: colorScheme.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("2000", style: TextStyle(color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _currentThreshold,
                          min: 30,
                          max: 2000,
                          divisions: 197, // Saltos de 10 en 10
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.primary.withOpacity(0.2),
                          onChanged: (val) => setState(() => _currentThreshold = val),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: _proposeLimitChange,
                            child: const Text("Proponer Nuevo Límite", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // 🔥 SECCIÓN 2: ZONA DE PELIGRO
                Text("Zona de Peligro", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: colorScheme.error.withOpacity(0.2), child: Icon(Icons.exit_to_app_rounded, color: colorScheme.error)),
                    title: Text("Salir del Grupo", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                    subtitle: Text("Abandonarás la bóveda y los fondos.", style: TextStyle(color: colorScheme.error.withOpacity(0.7), fontSize: 12)),
                    onTap: () {
                      UIHelper.showCustomSnackbar("Función en desarrollo", isError: true);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}