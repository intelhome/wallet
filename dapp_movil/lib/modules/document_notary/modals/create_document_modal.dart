import 'dart:convert';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';

class CreateDocumentModal extends StatefulWidget {
  final String fileHash;
  //final BlockchainService service;
  final Function(String title, List<String> selectedSigners) onConfirm;

  const CreateDocumentModal({
    super.key,
    required this.fileHash,
    //required this.service,
    required this.onConfirm,
  });

  static void show({
    required BuildContext context,
    required String fileHash,
    //required BlockchainService service,
    required Function(String title, List<String> selectedSigners) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateDocumentModal(fileHash: fileHash, onConfirm: onConfirm),
    );
  }

  @override
  State<CreateDocumentModal> createState() => _CreateDocumentModalState();
}

class _CreateDocumentModalState extends State<CreateDocumentModal> {

  UserService get userService => Provider.of<UserService>(context, listen: false);
  AuthCoreService get  authCore => Provider.of<AuthCoreService>(context, listen: false);
  
  final TextEditingController _titleController = TextEditingController();
  List<dynamic> _misContactos = [];
  List<String> _firmantesSeleccionados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Me agrego a mí mismo por defecto como primer firmante
    _firmantesSeleccionados.add(authCore.publicAddress.toLowerCase());
    _cargarContactos();
  }

  Future<void> _cargarContactos() async {
    try {
      String endpoint = ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase());
      final res = await http.get(Uri.parse(endpoint), headers: {
        "Content-Type": "application/json",
        if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
      });

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _misContactos = jsonDecode(res.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

  return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, //  Color de fondo adaptativo
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Detalles del Documento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              IconButton(icon: Icon(Icons.close, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Hash visual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor, // 🔥 Tarjeta adaptativa
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text("HASH DEL DOCUMENTO", style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.fileHash,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 13, fontFamily: 'monospace', height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text("Verificado en la red principal", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Input de Título
          TextField(
            controller: _titleController,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: "Título del Contrato/Acuerdo",
              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              hintText: "Ej. documento",
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.title, color: colorScheme.onSurface),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text("¿Quiénes deben firmar?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
          const SizedBox(height: 12),

          // Lista de contactos
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _misContactos.isEmpty
                ? Center(child: Text("No tienes contactos guardados.", style: TextStyle(color: colorScheme.onSurface)))
                : ListView.builder(
                    itemCount: _misContactos.length,
                    itemBuilder: (ctx, i) {
                      var c = _misContactos[i];
                      String wallet = c['contactAddress'].toString().toLowerCase();
                      bool isSelected = _firmantesSeleccionados.contains(wallet);
                      bool isMe = wallet == authCore.publicAddress.toLowerCase();

                      // 🔥 EXTRACCIÓN DE DATOS REALES (Cédula y Correo)
                      String cedula = c['cedula'] ?? c['id'] ?? 'Sin ID registrado';
                      String email = c['email'] ?? 'Sin correo registrado';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // AVATAR REAL
                                SmartAvatar(address: wallet, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("@${c['alias']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                                      Text(isMe ? "Firmante Principal" : "Invitado", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Theme(
                                  data: ThemeData(unselectedWidgetColor: colorScheme.onSurface.withOpacity(0.4)),
                                  child: Checkbox(
                                    value: isSelected,
                                    activeColor: colorScheme.primary,
                                    checkColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _firmantesSeleccionados.add(wallet);
                                        } else {
                                          _firmantesSeleccionados.remove(wallet);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // DATOS COMPLETOS DE IDENTIDAD (Wallet, ID y Email)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                                    const SizedBox(width: 8),
                                    Text(email, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.account_balance_wallet_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(wallet, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 12, fontFamily: 'monospace')),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (_titleController.text.trim().isEmpty) {
                UIHelper.showCustomSnackbar("Ingresa un título", isError: true);
                return;
              }
              if (_firmantesSeleccionados.isEmpty) {
                UIHelper.showCustomSnackbar("Debes elegir al menos 1 firmante", isError: true);
                return;
              }
              Navigator.pop(context);
              widget.onConfirm(_titleController.text.trim(), _firmantesSeleccionados); 
            },
            child: Text("Registrar con ${_firmantesSeleccionados.length} Firmantes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}