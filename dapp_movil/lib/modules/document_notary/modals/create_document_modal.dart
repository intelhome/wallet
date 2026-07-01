import 'dart:convert';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Detalles del Documento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
          
          // Hash visual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text("Hash: ${widget.fileHash}", style: TextStyle(color: colorScheme.primary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input de Título
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Título del Contrato/Acuerdo",
              hintText: "Ej. Préstamo a Juan, Contrato de Alquiler...",
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),

          const Text("¿Quiénes deben firmar?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          // Lista de contactos
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _misContactos.isEmpty
                ? const Center(child: Text("No tienes contactos guardados."))
                : ListView.builder(
                    itemCount: _misContactos.length,
                    itemBuilder: (ctx, i) {
                      var c = _misContactos[i];
                      String wallet = c['contactAddress'].toString().toLowerCase();
                      bool isSelected = _firmantesSeleccionados.contains(wallet);

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: colorScheme.primary,
                        title: Text("@${c['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(wallet.substring(0, 10) + "..."),
                        secondary: const CircleAvatar(child: Icon(Icons.person)),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _firmantesSeleccionados.add(wallet);
                            } else {
                              _firmantesSeleccionados.remove(wallet);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Navigator.pop(context); // Cierra el modal
              widget.onConfirm(_titleController.text.trim(), _firmantesSeleccionados); // Devuelve los datos
            },
            child: Text("Registrar con ${_firmantesSeleccionados.length} Firmantes", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}