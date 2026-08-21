import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/contact_service.dart';

class SyncContactsModal {
  static void show({
    required BuildContext context,
    required List<dynamic> registrados,
    required Map<String, String> phoneToNameMap, // Todos los contactos de la agenda
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SyncContactsContent(
        registrados: registrados,
        phoneToNameMap: phoneToNameMap,
        onRefresh: () {
          onRefresh();
        },
      ),
    );
  }
}

// Widget con estado interno para manejar el buscador
class _SyncContactsContent extends StatefulWidget {
  final List<dynamic> registrados;
  final Map<String, String> phoneToNameMap;
  final VoidCallback onRefresh;

  const _SyncContactsContent({
    required this.registrados,
    required this.phoneToNameMap,
    required this.onRefresh,
  });

  @override
  State<_SyncContactsContent> createState() => _SyncContactsContentState();
}

class _SyncContactsContentState extends State<_SyncContactsContent> {
  String _searchQuery = "";
  List<String> _contactosYaSincronizados = [];

  // Mapeamos los registrados para fácil búsqueda
  late Map<String, dynamic> _registradosMap;

  @override
  void initState() {
    super.initState();
    _registradosMap = {
      for (var u in widget.registrados) u['phoneNumber'].toString().replaceAll(RegExp(r'[^\d+]'), ''): u
    };
  }

  void _invitarWhatsapp(String phone) async {
    String msj = "¡Hola! Estoy usando TTC Wallet para manejar mis finanzas. Únete a la red aquí: https://ttc-wallet.com/download";
    final Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msj)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      UIHelper.showCustomSnackbar("No se pudo abrir WhatsApp.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // Convertimos el map de la agenda a una lista para poder filtrarla
    List<MapEntry<String, String>> contactosMostrados = widget.phoneToNameMap.entries.where((entry) {
      return entry.value.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             entry.key.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sincronizar Contactos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: "Buscar contactos...",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.6)),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: contactosMostrados.length,
              itemBuilder: (context, index) {
                final phone = contactosMostrados[index].key;
                final nombreAgenda = contactosMostrados[index].value;
                final bool estaEnTtc = _registradosMap.containsKey(phone);
                final bool yaAgregado = _contactosYaSincronizados.contains(phone);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Avatar circular con iniciales
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (estaEnTtc ? colorScheme.primary : colorScheme.tertiary).withOpacity(0.2),
                        child: Text(
                          nombreAgenda.isNotEmpty ? nombreAgenda.substring(0, 2).toUpperCase() : "?",
                          style: TextStyle(color: estaEnTtc ? colorScheme.primary : colorScheme.tertiary, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nombres
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreAgenda, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
                            const SizedBox(height: 4),
                            Text(phone, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                          ],
                        ),
                      ),
                      // Botones de acción dinámicos
                      if (estaEnTtc && !yaAgregado)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            foregroundColor: colorScheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text("Agregar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () async {
                            final u = _registradosMap[phone];
                            final contactService = Provider.of<ContactService>(context, listen: false);
                            String res = await contactService.addContact(u['walletAddress'], u['alias'], "Normal");
                            if (res == "Exito") {
                              setState(() => _contactosYaSincronizados.add(phone));
                              widget.onRefresh();
                            } else {
                              UIHelper.showCustomSnackbar(res, isError: true);
                            }
                          },
                        )
                      else if (yaAgregado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text("Agregado", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: onSurface.withOpacity(0.8)),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                          label: const Text("Invitar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _invitarWhatsapp(phone),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // BOTON INFERIOR GENERAL
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E), // Verde WhatsApp
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text("Invitar a otros por WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () => _invitarWhatsapp(""),
              ),
            ),
          ),
        ],
      ),
    );
  }
}