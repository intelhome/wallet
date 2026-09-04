import 'package:dapp_movil/modules/groups_and_social/modals/sync_contacts_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _ContactsTabState extends State<ContactsTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Favoritos', 'Familiar', 'Comercial', 'Normal'];
  List<dynamic> _contactosFiltrados = [];

  // 🔥 Estados del Tutorial Mágico
  bool _showSyncTooltip = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrar);
    _filtrar();

    // 🔥 Configuración de animación de destello (Latido)
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
    _checkFirstTimeSync();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeSync() async {
    final prefs = await SharedPreferences.getInstance();
    bool hideTooltip = prefs.getBool('hide_contact_sync_tooltip') ?? false;
    
    if (!hideTooltip) {
      if (mounted) setState(() => _showSyncTooltip = true);
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _dismissTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_contact_sync_tooltip', true);
    if (mounted) {
      setState(() => _showSyncTooltip = false);
      _pulseController.stop();
      _pulseController.reset();
    }
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
    // Al presionar sincronizar, asumimos que ya no necesita el tooltip nunca más
    _dismissTooltip();

    if (!await FlutterContacts.requestPermission(readonly: true)) {
      UIHelper.showCustomSnackbar("Permiso de contactos denegado", isError: true);
      return;
    }

    UIHelper.showCustomSnackbar("Leyendo agenda del teléfono...", isError: false);
    
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    List<String> phoneNumbers = [];
    Map<String, String> phoneToNameMap = {};

    for (var c in contacts) {
      if (c.phones.isNotEmpty) {
        for (var p in c.phones) {
          String cleanPhone = p.number.replaceAll(RegExp(r'[^\d+]'), '');
          phoneNumbers.add(cleanPhone);
          phoneToNameMap[cleanPhone] = c.displayName;
        }
      }
    }

    if (phoneNumbers.isEmpty) {
      UIHelper.showCustomSnackbar("No se encontraron números en tu agenda.", isError: true);
      return;
    }

    final contactService = Provider.of<ContactService>(context, listen: false);
    final registeredUsers = await contactService.syncPhoneContacts(phoneNumbers);

    if (!mounted) return;
    
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

    return Stack(
      children: [
        Column(
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
                  
                  // 🔥 BOTÓN DE SINCRONIZACIÓN ANIMADO Y CON TEXTO
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _showSyncTooltip ? colorScheme.primary : theme.cardColor, // Resalta el fondo si es primera vez
                        borderRadius: BorderRadius.circular(12),
                        border: _showSyncTooltip ? null : Border.all(color: onSurface.withOpacity(0.1)),
                        boxShadow: _showSyncTooltip ? [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)] : [],
                      ),
                      child: InkWell(
                        onTap: _sincronizarAgenda,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.sync_rounded, color: _showSyncTooltip ? Colors.white : colorScheme.primary, size: 20),
                              const SizedBox(width: 6),
                              Text("Sincronizar", style: TextStyle(color: _showSyncTooltip ? Colors.white : colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
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
        ),
        
        // 🔥 GLOBO FLOTANTE DEL TUTORIAL
        if (_showSyncTooltip)
          Positioned(
            top: 70, // Justo debajo del botón
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.import_contacts_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text("¡Importa tu agenda!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Dale clic aquí arriba para cruzar tus contactos del celular con TTC Wallet automáticamente.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          backgroundColor: Colors.white24,
                        ),
                        onPressed: _dismissTooltip,
                        child: const Text("No volver a mostrar", style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}