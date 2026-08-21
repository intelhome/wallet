import 'package:dapp_movil/modules/groups_and_social/modals/sync_contacts_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/helpers/route_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../chat_and_social/screens/chat_room_screen.dart';
import '../modals/add_contact_modal.dart';
import '../modals/contact_details_modal.dart';
import '../modals/edit_contact_modal.dart';
import '../services/contact_service.dart';
import '../../wallet_and_tx/modals/receive_modal.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../debts_and_payments/modals/plan_payment_modal.dart';
import '../../debts_and_payments/modals/installments_modal.dart';
import '../../settings_and_profile/modals/report_modal.dart';

class ContactsTab extends StatefulWidget {
  final List<dynamic> contactos;
  final bool cargando;
  final String balanceTTC;
  final VoidCallback onRefresh;
  final VoidCallback onUpdateBalance;

  const ContactsTab({super.key, required this.contactos, required this.cargando, required this.balanceTTC, required this.onRefresh, required this.onUpdateBalance});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Favoritos', 'Familiar', 'Comercial', 'Normal'];
  List<dynamic> _contactosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrar);
    _filtrar();
  }

  @override
  void didUpdateWidget(ContactsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contactos != oldWidget.contactos) _filtrar();
  }

  void _filtrar() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      _contactosFiltrados = widget.contactos.where((c) {
        final alias = (c['alias'] ?? '').toString().toLowerCase();
        final address = (c['contactAddress'] ?? '').toString().toLowerCase();
        final categoria = (c['category'] ?? 'Normal').toString().trim().toLowerCase();
        final isFav = c['favorite'] == true;

        bool matchesSearch = query.isEmpty || alias.contains(query) || address.contains(query);
        if (!matchesSearch) return false;

        if (_selectedFilter == 'Todos') return true;
        if (_selectedFilter == 'Favoritos') return isFav;
        return categoria == _selectedFilter.toLowerCase();
      }).toList();
    });
  }

  Future<void> _ejecutarAccion(String id, bool esFavorito, String operacion, String aliasActual, String catActual, String address) async {
    final contactService = Provider.of<ContactService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    if (operacion == "SEND") { SendModal.show(context: context, balanceTTC: widget.balanceTTC, onUpdateBalance: widget.onUpdateBalance, initialAddress: address, mostrarMensaje: (m, {bool esError=false}) {}); return;}
    if (operacion == "REQUEST") { ReceiveModal.show(context: context); return;}
    if (operacion == "PLAN") { PlanPaymentModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
    if (operacion == "INSTALLMENTS") { InstallmentsModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
    if (operacion == "REPORT") { ReportModal.show(context: context, aliasDestino: aliasActual, walletAddress: address); return;}
    if (operacion == "INVITE_WA") { 
      String mensaje = "Hola, te saluda el equipo de TTC Wallet...\nhttps://ttc-wallet.com/download\nEste es un mensaje automático de @$aliasActual";
      final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensaje)}");
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    if (operacion == "EDIT") { EditContactModal.show(context, id: id, aliasActual: aliasActual, catActual: catActual, onSuccess: widget.onRefresh); return; }
    
    if (operacion == "BORRAR") {
      bool success = await contactService.deleteContact(id);
      if (success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Contacto eliminado"), backgroundColor: colorScheme.error));
    } else if (operacion == "FAV") {
      await contactService.updateContact(id, isFavorite: !esFavorito);
    }
    widget.onRefresh(); 
  }

  Future<void> _sincronizarAgenda() async {
    // 1. Pedir permisos al SO
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      UIHelper.showCustomSnackbar("Permiso de contactos denegado", isError: true);
      return;
    }

    UIHelper.showCustomSnackbar("Leyendo agenda del teléfono...", isError: false);
    
    // 2. Extraer contactos con teléfonos
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    List<String> phoneNumbers = [];
    Map<String, String> phoneToNameMap = {};

    for (var c in contacts) {
      if (c.phones.isNotEmpty) {
        for (var p in c.phones) {
          // Limpiar el número (quitar espacios, guiones) conservando el '+' si existe
          String cleanPhone = p.number.replaceAll(RegExp(r'[^\d+]'), '');
          phoneNumbers.add(cleanPhone);
          phoneToNameMap[cleanPhone] = c.displayName; // Guardamos cómo lo tiene agendado el usuario
        }
      }
    }

    if (phoneNumbers.isEmpty) {
      UIHelper.showCustomSnackbar("No se encontraron números en tu agenda.", isError: true);
      return;
    }

    // 3. Enviar al backend para cruzar datos
    final contactService = Provider.of<ContactService>(context, listen: false);
    final registeredUsers = await contactService.syncPhoneContacts(phoneNumbers);

    if (!mounted) return;
    
    // 4. Llamada al modal modularizado
    SyncContactsModal.show(
      context: context, 
      registrados: registeredUsers, 
      phoneToNameMap: phoneToNameMap,
      onRefresh: widget.onRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar por @alias o 0x...",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.6)),
                    filled: true, 
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // NUEVO: Botón de sincronización de contactos
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: IconButton(
                  tooltip: "Sincronizar agenda",
                  icon: const Icon(Icons.sync_rounded, color: Colors.white),
                  onPressed: _sincronizarAgenda,
                ),
              )
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  backgroundColor: theme.cardColor,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  showCheckmark: false,
                  onSelected: (selected) { if (selected) setState(() { _selectedFilter = filter; _filtrar(); }); },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: widget.cargando 
            ? UIHelper.buildSkeletonList(context, itemCount: 6)
            : _contactosFiltrados.isEmpty 
              ? UIHelper.emptyState(
                  context: context, icon: Icons.person_off_rounded,
                  title: "Directorio Vacío", message: "Aún no tienes contactos en esta categoría.",
                  actionLabel: "Añadir mi primer contacto",
                  onAction: () => AddContactModal.show(context, onSuccess: widget.onRefresh),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _contactosFiltrados.length,
                  itemBuilder: (context, index) {
                    final c = _contactosFiltrados[index];
                    final bool isFav = c['favorite'] == true;
                    final String alias = c['alias'] ?? "Desconocido";
                    final String address = c['contactAddress'] ?? "";
                    final String categoria = c['category'] ?? "Normal";
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor, 
                        borderRadius: BorderRadius.circular(12), 
                        border: isFav ? Border.all(color: colorScheme.secondary.withOpacity(0.5), width: 1.5) : Border.all(color: onSurface.withOpacity(0.05), width: 1.0),
                      ),
                      child: ListTile(
                        onTap: () => ContactDetailsModal.show(context: context, contact: c),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: SmartAvatar(address: address, size: 48),
                        title: Text(alias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(address.length > 10 ? "${address.substring(0, 8)}...${address.substring(address.length - 6)}" : address, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: onSurface.withOpacity(0.6))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chat_bubble, color: colorScheme.primary, size: 22),
                              onPressed: () => Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(alias: alias, address: address))),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) => _ejecutarAccion(c['id'], isFav, val, alias, categoria, address),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: "SEND", child: Row(children: [Icon(Icons.send_rounded, color: Colors.green.shade400, size: 20), const SizedBox(width: 10), const Text("Transferir")])),
                                PopupMenuItem(value: "REQUEST", child: Row(children: [Icon(Icons.qr_code_rounded, color: colorScheme.primary, size: 20), const SizedBox(width: 10), const Text("Solicitar Pago")])),
                                const PopupMenuDivider(),
                                PopupMenuItem(value: "PLAN", child: Row(children: [Icon(Icons.calendar_month_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), const Text("Planificar Pago")])),
                                PopupMenuItem(value: "INSTALLMENTS", child: Row(children: [Icon(Icons.request_quote_rounded, color: colorScheme.tertiary, size: 20), const SizedBox(width: 10), const Text("Configurar Cuotas")])),
                                PopupMenuItem(value: "REPORT", child: Row(children: [Icon(Icons.insert_chart_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), const Text("Generar Reporte")])),
                                PopupMenuItem(value: "INVITE_WA", child: Row(children: [Icon(Icons.share_rounded, color: colorScheme.primary, size: 20), const SizedBox(width: 10), const Text("Invitar a TTC")])),
                                const PopupMenuDivider(),
                                PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: onSurface.withOpacity(0.5), size: 20), const SizedBox(width: 10), const Text("Editar Contacto")])),
                                PopupMenuItem(value: "FAV", child: Row(children: [Icon(isFav ? Icons.star_border_rounded : Icons.star_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), Text(isFav ? "Quitar Favorito" : "Marcar Favorito")])),
                                PopupMenuItem(value: "BORRAR", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), Text("Eliminar Contacto", style: TextStyle(color: colorScheme.error))])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}