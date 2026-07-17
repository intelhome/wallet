import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/chat_and_social/screens/chat_room_screen.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/add_contact_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/add_family_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/contact_details_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/edit_contact_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/family_invite_details_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/group_modals.dart';
import 'package:dapp_movil/modules/groups_and_social/services/contact_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/family_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/receive_modal.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../../core/services/smart_avatar.dart';
import 'package:url_launcher/url_launcher.dart'; // 🔥 Para WhatsApp
import 'package:share_plus/share_plus.dart';
import '../../debts_and_payments/modals/plan_payment_modal.dart';
import '../../debts_and_payments/modals/installments_modal.dart';
import '../../settings_and_profile/modals/report_modal.dart';
import 'group_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}
class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  ContactService get contactService => Provider.of<ContactService>(context, listen: false);
  GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);
  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  
  // 🔥 NUEVO SERVICIO AÑADIDO A TUS GETTERS
  FamilyService get familyService => Provider.of<FamilyService>(context, listen: false);
  
  late TabController _tabController;

  List<dynamic> _contactos = [];
  List<dynamic> _contactosFiltrados = [];
  bool _cargando = true;
  String _balanceTTC = "0.000";
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'Todos';
  final List<String> _filters = ['Todos', 'Favoritos', 'Familiar', 'Comercial', 'Normal'];

  List<dynamic> _grupos = [];
  bool _cargandoGrupos = true;

  // 🔥 NUEVAS VARIABLES DE ESTADO PARA FAMILIA
  List<dynamic> _familyMembers = [];
  List<dynamic> _familyInvites = [];
  bool _cargandoFamilia = true;

  @override
  void initState() {
    super.initState();
    // 🔥 CAMBIADO: AHORA SON 3 PESTAÑAS
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {})); 

    _cargarContactos();
    _cargarSaldo();
    _cargarGrupos();
    _cargarFamilia(); // 🔥 NUEVA CARGA INDEPENDIENTE
    _searchController.addListener(_filtrarContactos);
  }

  Future<void> _cargarSaldo() async {
    try {
      final saldo = await txService.getBalance();
      if (mounted) setState(() => _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3));
    } catch (e) {}
  }

  // Future<void> _cargarContactos() async {
  //   setState(() => _cargando = true);
  //   final lista = await contactService.getContacts();
  //   if (mounted) {
  //     setState(() {
  //       _contactos = lista;
  //       _filtrarContactos(); 
  //       _cargando = false;
  //     });
  //   }
  // }

  Future<void> _cargarContactos() async {
    // 1. Ya NO ponemos _cargando = true de inicio para no detener la UI
    final lista = await contactService.getContacts(
      onNetworkSync: (freshContacts) {
        // 3. Cuando AWS responda por detrás, repintamos si hay contactos nuevos
        if (mounted) {
          setState(() {
            _contactos = freshContacts;
            _filtrarContactos();
          });
        }
      }
    );

    // 2. Cargamos instantáneamente lo que nos devuelva Hive
    if (mounted) {
      setState(() {
        _contactos = lista;
        _filtrarContactos(); 
        _cargando = false; // Apagamos el esqueleto de carga instantáneamente
      });
    }
  }

  Future<void> _cargarGrupos() async {
    setState(() => _cargandoGrupos = true);
    final res = await groupService.getUserGroups();
    if (mounted) {
      setState(() {
        _grupos = res;
        _cargandoGrupos = false;
      });
    }
  }

  // 🔥 NUEVA FUNCIÓN PARA CARGAR SOLO DATOS DE LA PESTAÑA FAMILIAR
  Future<void> _cargarFamilia() async {
    setState(() => _cargandoFamilia = true);
    try {
      var resultados = await Future.wait([
        familyService.getFamilyMembers(),
        familyService.getPendingInvites(),
      ]);
      if (mounted) {
        setState(() {
          _familyMembers = resultados[0];
          _familyInvites = resultados[1];
          _cargandoFamilia = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoFamilia = false);
    }
  }
  
  void _filtrarContactos() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      _contactosFiltrados = _contactos.where((c) {
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

  Future<void> _enviarWhatsAppInvitacion(String aliasDestino) async {
    String mensaje = "Hola, te saluda el equipo de TTC Wallet...\nhttps://ttc-wallet.com/download\nEste es un mensaje automático de @$aliasDestino";
    final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensaje)}");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _ejecutarAccion(String id, bool esFavorito, String operacion, String aliasActual, String catActual, String address) async {
    final colorScheme = Theme.of(context).colorScheme;

    if (operacion == "SEND") { SendModal.show(context: context, balanceTTC: _balanceTTC, onUpdateBalance: _cargarSaldo, initialAddress: address, mostrarMensaje: (m, {bool esError=false}) {}); return;}
    if (operacion == "REQUEST") { ReceiveModal.show(context: context); return;}
    if (operacion == "PLAN") { PlanPaymentModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
    if (operacion == "INSTALLMENTS") { InstallmentsModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
    if (operacion == "REPORT") { ReportModal.show(context: context, aliasDestino: aliasActual, walletAddress: address); return;}
    if (operacion == "INVITE_WA") { _enviarWhatsAppInvitacion(aliasActual); return;}
    if (operacion == "EDIT") { EditContactModal.show(context, id: id, aliasActual: aliasActual, catActual: catActual, onSuccess: _cargarContactos); return; }
    
    setState(() => _cargando = true);
    
    if (operacion == "BORRAR") {
      bool success = await contactService.deleteContact(id);
      if (success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Contacto eliminado"), backgroundColor: colorScheme.error));
    } else if (operacion == "FAV") {
      await contactService.updateContact(id, isFavorite: !esFavorito);
    }

    _cargarContactos(); 
  }

  void _abrirChat(String alias, String address) {
    Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(alias: alias, address: address)));
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Directorio", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       bottom: TabBar(
  //         controller: _tabController,
  //         indicatorColor: colorScheme.primary,
  //         indicatorWeight: 3,
  //         labelColor: colorScheme.primary,
  //         unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
  //         tabs: const [
  //           Tab(icon: Icon(Icons.person_rounded), text: "Contactos"),
  //           Tab(icon: Icon(Icons.family_restroom_rounded), text: "Familia"), // 🔥 PESTAÑA AÑADIDA
  //           Tab(icon: Icon(Icons.diversity_3_rounded), text: "Grupos"),
  //         ],
  //       ),
  //     ),
  //     floatingActionButton: FloatingActionButton.extended(
  //       key: ValueKey<int>(_tabController.index),
  //       heroTag: 'fab_principal',
  //       backgroundColor: colorScheme.primary,
  //       foregroundColor: colorScheme.onPrimary,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
  //       // 🔥 DINÁMICA DEL BOTÓN SEGÚN LA PESTAÑA 0, 1 O 2
  //       icon: Icon(
  //         _tabController.index == 0 ? Icons.person_add_rounded : 
  //         _tabController.index == 1 ? Icons.family_restroom_rounded : 
  //         Icons.group_add_rounded
  //       ),
  //       label: Text(
  //         _tabController.index == 0 ? "Añadir Contacto" : 
  //         _tabController.index == 1 ? "Vincular Familiar" : 
  //         "Crear Grupo", 
  //         style: const TextStyle(fontWeight: FontWeight.bold)
  //       ),
  //       onPressed: () {
  //         if (_tabController.index == 0) {
  //           AddContactModal.show(context, onSuccess: _cargarContactos);
  //         } else if (_tabController.index == 1) {
  //           AddFamilyModal.show(context, onSuccess: _cargarFamilia); // Modal nuevo
  //         } else {
  //           GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos);
  //         }
  //       },
  //     ),
  //     body: TabBarView(
  //       controller: _tabController,
  //       children: [
  //         // ==============================
  //         // PESTAÑA 1: CONTACTOS (TU LÓGICA ORIGINAL)
  //         // ==============================
  //         Column(
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
  //               child: TextField(
  //                 controller: _searchController,
  //                 decoration: InputDecoration(
  //                   hintText: "Buscar por @alias o 0x...",
  //                   prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
  //                   filled: true, fillColor: theme.cardColor,
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
  //                 ),
  //               ),
  //             ),
  //             SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //               child: Row(
  //                 children: _filters.map((filter) {
  //                   final isSelected = _selectedFilter == filter;
  //                   return Padding(
  //                     padding: const EdgeInsets.only(right: 8),
  //                     child: ChoiceChip(
  //                       label: Text(filter),
  //                       selected: isSelected,
  //                       selectedColor: colorScheme.primary,
  //                       backgroundColor: theme.cardColor,
  //                       onSelected: (selected) { if (selected) setState(() { _selectedFilter = filter; _filtrarContactos(); }); },
  //                     ),
  //                   );
  //                 }).toList(),
  //               ),
  //             ),
  //             Expanded(
  //               child: _cargando 
  //                ? UIHelper.buildSkeletonList(context, itemCount: 6)
  //                : _contactosFiltrados.isEmpty 
  //                   ? UIHelper.emptyState(
  //                       context: context, icon: Icons.person_off_rounded,
  //                       title: "Directorio Vacío", message: "Aún no tienes contactos en esta categoría.",
  //                       actionLabel: "Añadir mi primer contacto",
  //                       onAction: () => AddContactModal.show(context, onSuccess: _cargarContactos),
  //                     )
  //                   : ListView.builder(
  //                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //                       itemCount: _contactosFiltrados.length,
  //                       itemBuilder: (context, index) {
  //                         final c = _contactosFiltrados[index];
  //                         final bool isFav = c['favorite'] == true;
  //                         final String alias = c['alias'] ?? "Desconocido";
  //                         final String address = c['contactAddress'] ?? "";
  //                         final String categoria = c['category'] ?? "Normal";
                          
  //                         return Container(
  //                           margin: const EdgeInsets.only(bottom: 12),
  //                           decoration: BoxDecoration(
  //                             color: theme.cardColor, borderRadius: BorderRadius.circular(20), 
  //                             border: isFav ? Border.all(color: colorScheme.secondary.withOpacity(0.5), width: 1.5) : null,
  //                           ),
  //                           child: ListTile(
  //                             onTap: () => ContactDetailsModal.show(context: context, contact: c),
  //                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                             leading: SmartAvatar(address: address, size: 48),
  //                             title: Row(children: [Text(alias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (isFav) Icon(Icons.star_rounded, color: colorScheme.secondary, size: 18)]),
  //                             subtitle: Text(address.length > 10 ? "${address.substring(0, 8)}...${address.substring(address.length - 6)}" : address, style: const TextStyle(fontSize: 12)),
                              
  //                             trailing: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 IconButton(
  //                                   icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
  //                                   onPressed: () => _abrirChat(alias, address),
  //                                   tooltip: "Chat Seguro",
  //                                 ),
  //                                 PopupMenuButton<String>(
  //                                   icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
  //                                   color: theme.cardColor,
  //                                   onSelected: (val) => _ejecutarAccion(c['id'], isFav, val, alias, categoria, address),
  //                                   itemBuilder: (ctx) => [
  //                                     PopupMenuItem(value: "SEND", child: Row(children: [Icon(Icons.send_rounded, color: Colors.greenAccent.shade400, size: 20), const SizedBox(width: 10), const Text("Transferir")])),
  //                                     PopupMenuItem(value: "REQUEST", child: Row(children: [Icon(Icons.qr_code_rounded, color: colorScheme.primary, size: 20), const SizedBox(width: 10), const Text("Solicitar Pago")])),
  //                                     const PopupMenuDivider(),
  //                                     const PopupMenuItem(value: "PLAN", child: Row(children: [Icon(Icons.calendar_month_rounded, color: Colors.deepPurpleAccent, size: 20), SizedBox(width: 10), Text("Planificar Pago")])),
  //                                     PopupMenuItem(value: "INSTALLMENTS", child: Row(children: [Icon(Icons.request_quote_rounded, color: Colors.amber.shade700, size: 20), const SizedBox(width: 10), const Text("Configurar Cuotas")])),
  //                                     PopupMenuItem(value: "REPORT", child: Row(children: [Icon(Icons.insert_chart_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), const Text("Generar Reporte")])),
  //                                     PopupMenuItem(value: "INVITE_WA", child: Row(children: [const Icon(Icons.share_rounded, color: Colors.teal, size: 20), const SizedBox(width: 10), const Text("Invitar a TTC")])),
  //                                     const PopupMenuDivider(),
  //                                     const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Contacto")])),
  //                                     PopupMenuItem(value: "FAV", child: Row(children: [Icon(isFav ? Icons.star_border_rounded : Icons.star_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), Text(isFav ? "Quitar Favorito" : "Marcar Favorito")])),
  //                                     PopupMenuItem(value: "BORRAR", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Contacto", style: TextStyle(color: Colors.red))])),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),
  //             ),
  //           ],
  //         ),

  //         // ==============================
  //         // 🔥 PESTAÑA 2: FAMILIA (NUEVA LÓGICA)
  //         // ==============================
  //         _cargandoFamilia
  //             ? UIHelper.buildSkeletonList(context, itemCount: 4)
  //             : RefreshIndicator(
  //                 onRefresh: _cargarFamilia,
  //                 child: ListView(
  //                   padding: const EdgeInsets.all(16),
  //                   children: [
  //                     // Subsección: Solicitudes Entrantes
  //                     if (_familyInvites.isNotEmpty) ...[
  //                       Text("Solicitudes Familiares", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
  //                       const SizedBox(height: 10),
  //                       ..._familyInvites.map((inv) => Card(
  //                         color: Colors.orange.withOpacity(0.08),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.orange, width: 0.5)),
  //                         margin: const EdgeInsets.only(bottom: 12),
  //                         child: ListTile(
  //                           leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 20)),
  //                           title: Text("@${inv['senderAlias'] ?? 'Usuario'}", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                           subtitle: const Text("Te ha enviado una invitación familiar"),
  //                           trailing: ElevatedButton(
  //                             style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
  //                             onPressed: () => FamilyInviteDetailsModal.show(context, inv, _cargarFamilia), // Pasamos _cargarFamilia para refrescar al aceptar
  //                             child: const Text("Revisar"),
  //                           ),
  //                         ),
  //                       )),
  //                       const SizedBox(height: 16),
  //                     ],

  //                     // Subsección: Lista de familiares
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text("Círculo de Confianza", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface)),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 12),
                      
  //                     if (_familyMembers.isEmpty)
  //                       Padding(
  //                         padding: const EdgeInsets.only(top: 40.0),
  //                         child: UIHelper.emptyState(context: context, icon: Icons.diversity_1_rounded, title: "Núcleo Vacío", message: "Vincula a tus familiares para enviar dinero y chatear con seguridad."),
  //                       )
  //                     else
  //                       ..._familyMembers.map((m) => Card(
  //                         margin: const EdgeInsets.only(bottom: 12),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                         child: ListTile(
  //                           leading: SmartAvatar(address: m['wallet'] ?? '', size: 40),
  //                           title: Text(m['alias'] ?? "Familiar", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                           subtitle: Text("Cédula: ${m['cedula'] ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
  //                           trailing: const Icon(Icons.shield_rounded, color: Colors.green, size: 20),
  //                           onTap: () {
  //                             _abrirChat(m['alias'] ?? 'Familiar', m['wallet'] ?? '');
  //                           },
  //                         ),
  //                       )),
  //                   ],
  //                 ),
  //               ),

  //         // ==============================
  //         // PESTAÑA 3: GRUPOS (TU LÓGICA ORIGINAL CORREGIDA)
  //         // ==============================
  //         _cargandoGrupos 
  //            ? UIHelper.buildSkeletonList(context, itemCount: 6)
  //           : _grupos.isEmpty
  //             ? UIHelper.emptyState(
  //                 context: context, icon: Icons.group_off_rounded,
  //                 title: "Directorio Vacío", message: "Aún no tienes grupos comunes.",
  //                 actionLabel: "Crear mi primer grupo",
  //                 onAction: () => GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos),
  //               )
  //             : ListView.builder(
  //                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), 
  //                 itemCount: _grupos.length,
  //                 itemBuilder: (context, index) {
  //                   final g = _grupos[index];
  //                   bool isCreator = g['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
                    
  //                   return GestureDetector(
  //                     onTap: () async {
  //                       // Asegúrate de tener GroupDetailsScreen importado
  //                       await Navigator.push(context, RouteHelper.slideUpRoute(GroupDetailsScreen(groupData: g)));
  //                       if (mounted) _cargarGrupos(); 
  //                     },
  //                     child: Container(
  //                       margin: const EdgeInsets.only(bottom: 12),
  //                       decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
  //                       child: ListTile(
  //                         contentPadding: const EdgeInsets.all(16),
  //                         leading: CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.diversity_3_rounded, color: colorScheme.primary)),
  //                         title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //                         subtitle: Text(isCreator ? "Eres el administrador" : "Creado por @${g['creatorAlias']}", style: const TextStyle(fontSize: 13)),
  //                         trailing: PopupMenuButton<String>(
  //                           icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
  //                           color: theme.cardColor,
  //                           onSelected: (val) async {
  //                             // 🔥 CORRECCIÓN DEL ERROR DE COMPILACIÓN AQUÍ
  //                             if (val == "EDIT") GroupModals.showEdit(context, id: g['id'], nombreActual: g['name'], onSuccess: _cargarGrupos);
  //                             else if (val == "DELETE") GroupModals.showDeleteConfirm(context, id: g['id'], onSuccess: _cargarGrupos);
  //                             else if (val == "LEAVE") { await groupService.rejectGroupInvite(g['id']); _cargarGrupos(); }
  //                           },
  //                           itemBuilder: (ctx) => [
  //                             if (isCreator) const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Nombre")])),
  //                             if (isCreator) PopupMenuItem(value: "DELETE", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Grupo", style: TextStyle(color: Colors.red))])),
  //                             if (!isCreator) const PopupMenuItem(value: "LEAVE", child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 20), SizedBox(width: 10), Text("Abandonar Grupo", style: TextStyle(color: Colors.orange))])),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               )
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Directory", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4361EE),
          indicatorWeight: 2,
          labelColor: const Color(0xFF4361EE),
          unselectedLabelColor: onSurface.withOpacity(0.6),
          dividerColor: onSurface.withOpacity(0.1),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: "Contacts"),
            Tab(icon: Icon(Icons.family_restroom_rounded), text: "Family"),
            Tab(icon: Icon(Icons.groups_rounded), text: "Groups"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: ValueKey<int>(_tabController.index),
        heroTag: 'fab_principal',
        backgroundColor: const Color(0xFF4361EE),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        onPressed: () {
          if (_tabController.index == 0) AddContactModal.show(context, onSuccess: _cargarContactos);
          else if (_tabController.index == 1) AddFamilyModal.show(context, onSuccess: _cargarFamilia);
          else GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos);
        },
        child: Icon(
          _tabController.index == 0 ? Icons.person_add_rounded : 
          _tabController.index == 1 ? Icons.family_restroom_rounded : 
          Icons.group_add_rounded
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==============================
          // PESTAÑA 1: CONTACTOS
          // ==============================
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by @alias or 0x...",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.6)),
                    filled: true, 
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  ),
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
                          color: isSelected ? Colors.white : onSurface.withOpacity(0.6),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF4361EE),
                        backgroundColor: theme.cardColor,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        showCheckmark: false,
                        onSelected: (selected) { if (selected) setState(() { _selectedFilter = filter; _filtrarContactos(); }); },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: _cargando 
                 ? UIHelper.buildSkeletonList(context, itemCount: 6)
                 : _contactosFiltrados.isEmpty 
                    ? UIHelper.emptyState(
                        context: context, icon: Icons.person_off_rounded,
                        title: "Directorio Vacío", message: "Aún no tienes contactos en esta categoría.",
                        actionLabel: "Añadir mi primer contacto",
                        onAction: () => AddContactModal.show(context, onSuccess: _cargarContactos),
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
                                    icon: const Icon(Icons.chat_bubble, color: Color(0xFF4361EE), size: 22),
                                    onPressed: () => _abrirChat(alias, address),
                                    tooltip: "Chat Seguro",
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                                    color: theme.cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (val) => _ejecutarAccion(c['id'], isFav, val, alias, categoria, address),
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(value: "SEND", child: Row(children: [Icon(Icons.send_rounded, color: Colors.greenAccent.shade400, size: 20), const SizedBox(width: 10), const Text("Transferir")])),
                                      PopupMenuItem(value: "REQUEST", child: Row(children: [Icon(Icons.qr_code_rounded, color: colorScheme.primary, size: 20), const SizedBox(width: 10), const Text("Solicitar Pago")])),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(value: "PLAN", child: Row(children: [Icon(Icons.calendar_month_rounded, color: Colors.deepPurpleAccent, size: 20), SizedBox(width: 10), Text("Planificar Pago")])),
                                      PopupMenuItem(value: "INSTALLMENTS", child: Row(children: [Icon(Icons.request_quote_rounded, color: Colors.amber.shade700, size: 20), const SizedBox(width: 10), const Text("Configurar Cuotas")])),
                                      PopupMenuItem(value: "REPORT", child: Row(children: [Icon(Icons.insert_chart_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), const Text("Generar Reporte")])),
                                      PopupMenuItem(value: "INVITE_WA", child: Row(children: [const Icon(Icons.share_rounded, color: Colors.teal, size: 20), const SizedBox(width: 10), const Text("Invitar a TTC")])),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Contacto")])),
                                      PopupMenuItem(value: "FAV", child: Row(children: [Icon(isFav ? Icons.star_border_rounded : Icons.star_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), Text(isFav ? "Quitar Favorito" : "Marcar Favorito")])),
                                      PopupMenuItem(value: "BORRAR", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Contacto", style: TextStyle(color: Colors.red))])),
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

          // ==============================
          // PESTAÑA 2: FAMILIA
          // ==============================
          _cargandoFamilia
              ? UIHelper.buildSkeletonList(context, itemCount: 4)
              : RefreshIndicator(
                  onRefresh: _cargarFamilia,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_familyInvites.isNotEmpty) ...[
                        Text("Solicitudes Familiares", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        ..._familyInvites.map((inv) => Container(
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange, width: 0.5)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 20)),
                            title: Text("@${inv['senderAlias'] ?? 'Usuario'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text("Te ha enviado una invitación familiar"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              onPressed: () => FamilyInviteDetailsModal.show(context, inv, _cargarFamilia),
                              child: const Text("Revisar"),
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                      Text("Círculo de Confianza", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      if (_familyMembers.isEmpty)
                        Padding(padding: const EdgeInsets.only(top: 40.0), child: UIHelper.emptyState(context: context, icon: Icons.diversity_1_rounded, title: "Núcleo Vacío", message: "Vincula a tus familiares para enviar dinero y chatear con seguridad."))
                      else
                        ..._familyMembers.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.05))),
                          child: ListTile(
                            leading: SmartAvatar(address: m['wallet'] ?? '', size: 48),
                            title: Text(m['alias'] ?? "Familiar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text("Cédula: ${m['cedula'] ?? 'N/A'}", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                            trailing: IconButton(icon: const Icon(Icons.chat_bubble, color: Color(0xFF4361EE), size: 22), onPressed: () => _abrirChat(m['alias'] ?? 'Familiar', m['wallet'] ?? '')),
                          ),
                        )),
                    ],
                  ),
                ),

          // ==============================
          // PESTAÑA 3: GRUPOS
          // ==============================
          _cargandoGrupos 
             ? UIHelper.buildSkeletonList(context, itemCount: 6)
            : _grupos.isEmpty
              ? UIHelper.emptyState(
                  context: context, icon: Icons.group_off_rounded,
                  title: "Directorio Vacío", message: "Aún no tienes grupos comunes.",
                  actionLabel: "Crear mi primer grupo",
                  onAction: () => GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), 
                  itemCount: _grupos.length,
                  itemBuilder: (context, index) {
                    final g = _grupos[index];
                    bool isCreator = g['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, RouteHelper.slideUpRoute(GroupDetailsScreen(groupData: g)));
                        if (mounted) _cargarGrupos(); 
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(radius: 24, backgroundColor: const Color(0xFF4361EE).withOpacity(0.1), child: const Icon(Icons.diversity_3_rounded, color: Color(0xFF4361EE))),
                          title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(isCreator ? "Eres el administrador" : "Creado por @${g['creatorAlias']}", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.6)),
                            color: theme.cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) async {
                              if (val == "EDIT") GroupModals.showEdit(context, id: g['id'], nombreActual: g['name'], onSuccess: _cargarGrupos);
                              else if (val == "DELETE") GroupModals.showDeleteConfirm(context, id: g['id'], onSuccess: _cargarGrupos);
                              else if (val == "LEAVE") { await groupService.rejectGroupInvite(g['id']); _cargarGrupos(); }
                            },
                            itemBuilder: (ctx) => [
                              if (isCreator) const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Nombre")])),
                              if (isCreator) PopupMenuItem(value: "DELETE", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Grupo", style: TextStyle(color: Colors.red))])),
                              if (!isCreator) const PopupMenuItem(value: "LEAVE", child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 20), SizedBox(width: 10), Text("Abandonar Grupo", style: TextStyle(color: Colors.orange))])),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                )
        ],
      ),
    );
  }
}


//   AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
//   ContactService get contactService => Provider.of<ContactService>(context, listen: false);
//   GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);
//   TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  
//   late TabController _tabController;

//   List<dynamic> _contactos = [];
//   List<dynamic> _contactosFiltrados = [];
//   List<dynamic> _familyMembers = [];
//   List<dynamic> _familyInvites = [];
//   bool _cargando = true;
//   String _balanceTTC = "0.000";
//   final TextEditingController _searchController = TextEditingController();
  
//   String _selectedFilter = 'Todos';
//   final List<String> _filters = ['Todos', 'Favoritos', 'Familiar', 'Comercial', 'Normal'];

//   List<dynamic> _grupos = [];
//   bool _cargandoGrupos = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _tabController.addListener(() => setState(() {})); 

//     _cargarContactos();
//     _cargarSaldo();
//     _cargarGrupos();
//     _searchController.addListener(_filtrarContactos);
//   }

//   Future<void> _cargarSaldo() async {
//     try {
//       final saldo = await txService.getBalance();
//       if (mounted) setState(() => _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3));
//     } catch (e) {}
//   }

//   Future<void> _cargarContactos() async {
//     setState(() => _cargando = true);
//     final lista = await contactService.getContacts();
//     if (mounted) {
//       setState(() {
//         _contactos = lista;
//         _filtrarContactos(); 
//         _cargando = false;
//       });
//     }
//   }

//   Future<void> _cargarGrupos() async {
//     setState(() => _cargandoGrupos = true);
//     final res = await groupService.getUserGroups();
//     if (mounted) {
//       setState(() {
//         _grupos = res;
//         _cargandoGrupos = false;
//       });
//     }
//   }
  
//   void _filtrarContactos() {
//     String query = _searchController.text.toLowerCase().trim();
//     setState(() {
//       _contactosFiltrados = _contactos.where((c) {
//         final alias = (c['alias'] ?? '').toString().toLowerCase();
//         final address = (c['contactAddress'] ?? '').toString().toLowerCase();
//         final categoria = (c['category'] ?? 'Normal').toString().trim().toLowerCase();
//         final isFav = c['favorite'] == true;

//         bool matchesSearch = query.isEmpty || alias.contains(query) || address.contains(query);
//         if (!matchesSearch) return false;

//         if (_selectedFilter == 'Todos') return true;
//         if (_selectedFilter == 'Favoritos') return isFav;
//         return categoria == _selectedFilter.toLowerCase();
//       }).toList();
//     });
//   }

//   Future<void> _enviarWhatsAppInvitacion(String aliasDestino) async {
//     String mensaje = "Hola, te saluda el equipo de TTC Wallet...\nhttps://ttc-wallet.com/download\nEste es un mensaje automático de @$aliasDestino";
//     // Este Uri.parse es correcto, abre la app externa de WhatsApp, no hace llamadas a tu backend
//     final Uri url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(mensaje)}");
//     if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
//   }

//   // 🔥 Lógica de acciones 100% delegada a los Modales y Servicios
//   Future<void> _ejecutarAccion(String id, bool esFavorito, String operacion, String aliasActual, String catActual, String address) async {
//     final colorScheme = Theme.of(context).colorScheme;

//     if (operacion == "SEND") { SendModal.show(context: context, balanceTTC: _balanceTTC, onUpdateBalance: _cargarSaldo, initialAddress: address, mostrarMensaje: (m, {bool esError=false}) {}); return;}
//     if (operacion == "REQUEST") { ReceiveModal.show(context: context); return;}
//     if (operacion == "PLAN") { PlanPaymentModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
//     if (operacion == "INSTALLMENTS") { InstallmentsModal.show(context: context, aliasDestino: aliasActual, addressDestino: address); return;}
//     if (operacion == "REPORT") { ReportModal.show(context: context, aliasDestino: aliasActual, walletAddress: address); return;}
//     if (operacion == "INVITE_WA") { _enviarWhatsAppInvitacion(aliasActual); return;}
//     if (operacion == "EDIT") { EditContactModal.show(context, id: id, aliasActual: aliasActual, catActual: catActual, onSuccess: _cargarContactos); return; }
    
//     setState(() => _cargando = true);
    
//     if (operacion == "BORRAR") {
//       bool success = await contactService.deleteContact(id);
//       if (success) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Contacto eliminado"), backgroundColor: colorScheme.error));
//     } else if (operacion == "FAV") {
//       await contactService.updateContact(id, isFavorite: !esFavorito);
//     }

//     _cargarContactos(); 
//   }

//   void _abrirChat(String alias, String address) {
//     Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(alias: alias, address: address)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text("Directorio", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: colorScheme.primary,
//           indicatorWeight: 3,
//           labelColor: colorScheme.primary,
//           unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
//           tabs: const [
//             Tab(icon: Icon(Icons.person_rounded), text: "Contactos"),
//             Tab(icon: Icon(Icons.diversity_3_rounded), text: "Grupos"),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         key: ValueKey<int>(_tabController.index),
//         heroTag: 'fab_principal',
//         backgroundColor: colorScheme.primary,
//         foregroundColor: colorScheme.onPrimary,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
//         icon: Icon(_tabController.index == 0 ? Icons.person_add_rounded : Icons.group_add_rounded),
//         label: Text(_tabController.index == 0 ? "Añadir Contacto" : "Crear Grupo", style: const TextStyle(fontWeight: FontWeight.bold)),
//         onPressed: _tabController.index == 0 
//             ? () => AddContactModal.show(context, onSuccess: _cargarContactos) 
//             : () => GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // ==============================
//           // PESTAÑA 1: CONTACTOS
//           // ==============================
//           Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: "Buscar por @alias o 0x...",
//                     prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
//                     filled: true, fillColor: theme.cardColor,
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
//                   ),
//                 ),
//               ),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Row(
//                   children: _filters.map((filter) {
//                     final isSelected = _selectedFilter == filter;
//                     return Padding(
//                       padding: const EdgeInsets.only(right: 8),
//                       child: ChoiceChip(
//                         label: Text(filter),
//                         selected: isSelected,
//                         selectedColor: colorScheme.primary,
//                         backgroundColor: theme.cardColor,
//                         onSelected: (selected) { if (selected) setState(() { _selectedFilter = filter; _filtrarContactos(); }); },
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               Expanded(
//                 child: _cargando 
//                  ? UIHelper.buildSkeletonList(context, itemCount: 6)
//                   : _contactosFiltrados.isEmpty 
//                       ? UIHelper.emptyState(
//                           context: context, icon: Icons.person_off_rounded,
//                           title: "Directorio Vacío", message: "Aún no tienes contactos en esta categoría.",
//                           actionLabel: "Añadir mi primer contacto",
//                           onAction: () => AddContactModal.show(context, onSuccess: _cargarContactos),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                           itemCount: _contactosFiltrados.length,
//                           itemBuilder: (context, index) {
//                             final c = _contactosFiltrados[index];
//                             final bool isFav = c['favorite'] == true;
//                             final String alias = c['alias'] ?? "Desconocido";
//                             final String address = c['contactAddress'] ?? "";
//                             final String categoria = c['category'] ?? "Normal";
                            
//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 12),
//                               decoration: BoxDecoration(
//                                 color: theme.cardColor, borderRadius: BorderRadius.circular(20), 
//                                 border: isFav ? Border.all(color: colorScheme.secondary.withOpacity(0.5), width: 1.5) : null,
//                               ),
//                               child: ListTile(
//                                 onTap: () => ContactDetailsModal.show(context: context, contact: c),
//                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                                 leading: SmartAvatar(address: address, size: 48),
//                                 title: Row(children: [Text(alias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (isFav) Icon(Icons.star_rounded, color: colorScheme.secondary, size: 18)]),
//                                 subtitle: Text(address.length > 10 ? "${address.substring(0, 8)}...${address.substring(address.length - 6)}" : address, style: const TextStyle(fontSize: 12)),
                                
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
//                                       onPressed: () => _abrirChat(alias, address),
//                                       tooltip: "Chat Seguro",
//                                     ),
//                                     PopupMenuButton<String>(
//                                       icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
//                                       color: theme.cardColor,
//                                       onSelected: (val) => _ejecutarAccion(c['id'], isFav, val, alias, categoria, address),
//                                       itemBuilder: (ctx) => [
//                                         PopupMenuItem(value: "SEND", child: Row(children: [Icon(Icons.send_rounded, color: Colors.greenAccent.shade400, size: 20), const SizedBox(width: 10), const Text("Transferir")])),
//                                         PopupMenuItem(value: "REQUEST", child: Row(children: [Icon(Icons.qr_code_rounded, color: colorScheme.primary, size: 20), const SizedBox(width: 10), const Text("Solicitar Pago")])),
//                                         const PopupMenuDivider(),
//                                         const PopupMenuItem(value: "PLAN", child: Row(children: [Icon(Icons.calendar_month_rounded, color: Colors.deepPurpleAccent, size: 20), SizedBox(width: 10), Text("Planificar Pago")])),
//                                         PopupMenuItem(value: "INSTALLMENTS", child: Row(children: [Icon(Icons.request_quote_rounded, color: Colors.amber.shade700, size: 20), const SizedBox(width: 10), const Text("Configurar Cuotas")])),
//                                         PopupMenuItem(value: "REPORT", child: Row(children: [Icon(Icons.insert_chart_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), const Text("Generar Reporte")])),
//                                         PopupMenuItem(value: "INVITE_WA", child: Row(children: [const Icon(Icons.share_rounded, color: Colors.teal, size: 20), const SizedBox(width: 10), const Text("Invitar a TTC")])),
//                                         const PopupMenuDivider(),
//                                         const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Contacto")])),
//                                         PopupMenuItem(value: "FAV", child: Row(children: [Icon(isFav ? Icons.star_border_rounded : Icons.star_rounded, color: colorScheme.secondary, size: 20), const SizedBox(width: 10), Text(isFav ? "Quitar Favorito" : "Marcar Favorito")])),
//                                         PopupMenuItem(value: "BORRAR", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Contacto", style: TextStyle(color: Colors.red))])),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//               ),
//             ],
//           ),

//           // ==============================
//           // PESTAÑA 2: GRUPOS
//           // ==============================
//           _cargandoGrupos 
//              ? UIHelper.buildSkeletonList(context, itemCount: 6)
//             : _grupos.isEmpty
//               ? UIHelper.emptyState(
//                   context: context, icon: Icons.group_off_rounded,
//                   title: "Directorio Vacío", message: "Aún no tienes grupos comunes.",
//                   actionLabel: "Crear mi primer grupo",
//                   onAction: () => GroupModals.showCreate(context, contactosDisponibles: _contactos, onSuccess: _cargarGrupos),
//                 )
//               : ListView.builder(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), 
//                   itemCount: _grupos.length,
//                   itemBuilder: (context, index) {
//                     final g = _grupos[index];
//                     bool isCreator = g['creatorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
                    
//                     return GestureDetector(
//                       onTap: () async {
//                         await Navigator.push(context, RouteHelper.slideUpRoute(GroupDetailsScreen(groupData: g)));
//                         if (mounted) _cargarGrupos(); 
//                       },
//                       child: Container(
//                         margin: const EdgeInsets.only(bottom: 12),
//                         decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.all(16),
//                           leading: CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.diversity_3_rounded, color: colorScheme.primary)),
//                           title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                           subtitle: Text(isCreator ? "Eres el administrador" : "Creado por @${g['creatorAlias']}", style: const TextStyle(fontSize: 13)),
//                           trailing: PopupMenuButton<String>(
//                             icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
//                             color: theme.cardColor,
//                             onSelected: (val) async {
//                               if (val == "EDIT") GroupModals.showEdit(context, id: g['id'], nombreActual: g['name'], onSuccess: _cargarGrupos);
//                               else if (val == "DELETE") GroupModals.showDeleteConfirm(context, id: g['id'], onSuccess: _cargarGrupos);
//                               else if (val == "LEAVE") { await groupService.rejectGroupInvite(g['id']); _cargarGrupos(); }
//                             },
//                             itemBuilder: (ctx) => [
//                               if (isCreator) const PopupMenuItem(value: "EDIT", child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueGrey, size: 20), SizedBox(width: 10), Text("Editar Nombre")])),
//                               if (isCreator) PopupMenuItem(value: "DELETE", child: Row(children: [Icon(Icons.delete_rounded, color: colorScheme.error, size: 20), const SizedBox(width: 10), const Text("Eliminar Grupo", style: TextStyle(color: Colors.red))])),
//                               if (!isCreator) const PopupMenuItem(value: "LEAVE", child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 20), SizedBox(width: 10), Text("Abandonar Grupo", style: TextStyle(color: Colors.orange))])),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }
//                 )
//         ],
//       ),
//     );
//   }
// }