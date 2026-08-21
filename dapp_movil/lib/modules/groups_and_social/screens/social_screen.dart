import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/contact_service.dart';
import '../services/family_service.dart';
import '../services/group_social_service.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../modals/add_contact_modal.dart';
import '../modals/add_family_modal.dart';
import '../modals/group_modals.dart';

// Importa las nuevas Tabs
import './contacts_tab.dart';
import './family_tab.dart';
import './groups_tab.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  ContactService get contactService => Provider.of<ContactService>(context, listen: false);
  GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);
  FamilyService get familyService => Provider.of<FamilyService>(context, listen: false);
  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  
  late TabController _tabController;

  // Estados
  List<dynamic> _contactos = [];
  bool _cargandoContactos = true;
  String _balanceTTC = "0.000";

  List<dynamic> _grupos = [];
  bool _cargandoGrupos = true;

  List<dynamic> _familyMembers = [];
  List<dynamic> _familyInvites = [];
  bool _cargandoFamilia = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {})); 

    _cargarContactos();
    _cargarSaldo();
    _cargarGrupos();
    _cargarFamilia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarSaldo() async {
    try {
      final saldo = await txService.getBalance();
      if (mounted) setState(() => _balanceTTC = (double.tryParse(saldo) ?? 0.0).toStringAsFixed(3));
    } catch (e) {}
  }

  Future<void> _cargarContactos() async {
    final lista = await contactService.getContacts(
      onNetworkSync: (freshContacts) {
        if (mounted) setState(() => _contactos = freshContacts);
      }
    );
    if (mounted) {
      setState(() {
        _contactos = lista;
        _cargandoContactos = false;
      });
    }
  }

  Future<void> _cargarGrupos() async {
    setState(() => _cargandoGrupos = true);
    final res = await groupService.getUserGroups();
    if (mounted) setState(() { _grupos = res; _cargandoGrupos = false; });
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Directorio", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2,
          labelColor: colorScheme.primary,
          unselectedLabelColor: onSurface.withOpacity(0.6),
          dividerColor: onSurface.withOpacity(0.1),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: "Contactos"),
            Tab(icon: Icon(Icons.family_restroom_rounded), text: "Familia"),
            Tab(icon: Icon(Icons.groups_rounded), text: "Grupos"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: ValueKey<int>(_tabController.index),
        heroTag: 'fab_social',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
          ContactsTab(
            contactos: _contactos,
            cargando: _cargandoContactos,
            balanceTTC: _balanceTTC,
            onRefresh: _cargarContactos,
            onUpdateBalance: _cargarSaldo,
          ),
          FamilyTab(
            familyMembers: _familyMembers,
            familyInvites: _familyInvites,
            cargando: _cargandoFamilia,
            onRefresh: _cargarFamilia,
          ),
          GroupsTab(
            grupos: _grupos,
            contactos: _contactos,
            cargando: _cargandoGrupos,
            onRefresh: _cargarGrupos,
          ),
        ],
      ),
    );
  }
}