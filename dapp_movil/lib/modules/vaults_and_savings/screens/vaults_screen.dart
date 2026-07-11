import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../modals/create_vault_modal.dart';
import '../modals/vault_detail_modal.dart';

class VaultsScreen extends StatefulWidget {
  const VaultsScreen({super.key});

  @override
  State<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends State<VaultsScreen> {
  SmartVaultService get vaultService => Provider.of<SmartVaultService>(context, listen: false);
  
  List<dynamic> _vaults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarBovedas();
  }

  Future<void> _cargarBovedas() async {
    final cacheService = LocalCacheService();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final wallet = authCore.publicAddress.toLowerCase();

    // 1. Caché rápido
    final cached = cacheService.getCachedUserVaults(wallet);
    if (cached.isNotEmpty && mounted) {
      setState(() { _vaults = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final freshData = await vaultService.getUserVaults();
    if (mounted) {
      setState(() { _vaults = freshData; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filtramos las listas para cada Tab
    final flexibleVaults = _vaults.where((v) => v['vaultType'] == 'FLEXIBLE').toList();
    final fixedVaults = _vaults.where((v) => v['vaultType'] != 'FLEXIBLE').toList();

    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mis Bolsillos",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
            dividerColor: Colors.transparent,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                text: "Ucha Flexible", 
                icon: Icon(Icons.water_drop_rounded)
              ),
              Tab(
                text: "Plazo Fijo", 
                icon: Icon(Icons.shield_rounded)
              ),
            ],
          ),
        ),
        body: _isLoading && _vaults.isEmpty
            ? UIHelper.buildSkeletonList(context, itemCount: 3)
            : TabBarView(
                children: [
                  // Tab 1: Uchas Flexibles
                  _buildVaultList(flexibleVaults, true),
                  
                  // Tab 2: Plazos Fijos
                  _buildVaultList(fixedVaults, false),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
           heroTag: 'fab_principal',
          onPressed: () => CreateVaultModal.show(
            context: context,
            onCreated: _cargarBovedas,
          ),
          icon: const Icon(Icons.add),
          label: const Text(
            "Nuevo Ahorro",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
        ),
      ),
    );
  }

  // 🔥 Helper reutilizable para renderizar cada lista
  Widget _buildVaultList(List<dynamic> vaultsList, bool isFlexibleTab) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    if (vaultsList.isEmpty) {
      return UIHelper.emptyState(
        context: context,
        icon: isFlexibleTab ? Icons.savings_rounded : Icons.lock_clock_rounded,
        title: isFlexibleTab ? "Sin Uchas Flexibles" : "Sin Plazos Fijos",
        message: isFlexibleTab 
            ? "Crea una Ucha flexible para tus metas cortas y retira cuando quieras."
            : "Bloquea tus fondos a un Plazo Fijo para generar ganancias anuales (APY).",
        actionLabel: "Crear Bolsillo",
        onAction: () => CreateVaultModal.show(context: context, onCreated: _cargarBovedas),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _cargarBovedas(),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100, top: 16),
        itemCount: vaultsList.length,
        itemBuilder: (context, index) {
          final vault = vaultsList[index];
          final isFlexible = vault['vaultType'] == 'FLEXIBLE';
          final balance = double.parse(vault['currentBalance'].toString());
          final targetAmount = vault['targetAmount'] != null ? double.parse(vault['targetAmount'].toString()) : 0.0;
          final hasTarget = targetAmount > 0;
          final progress = hasTarget ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            color: isFlexible ? Colors.blueAccent.withOpacity(0.05) : Colors.purpleAccent.withOpacity(0.05),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => VaultDetailModal.show(context: context, vault: vault, onUpdate: _cargarBovedas),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isFlexible ? Colors.blueAccent.withOpacity(0.1) : Colors.purpleAccent.withOpacity(0.1), 
                            shape: BoxShape.circle
                          ),
                          child: Icon(
                            isFlexible ? Icons.savings_rounded : Icons.lock_clock_rounded, 
                            color: isFlexible ? Colors.blueAccent : Colors.purpleAccent, 
                            size: 32
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vault['goalName'] ?? "Sin Nombre", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(isFlexible ? Icons.water_drop_rounded : Icons.shield_rounded, size: 12, color: onSurfaceColor.withOpacity(0.5)),
                                  const SizedBox(width: 4),
                                  Text(isFlexible ? "Ucha Flexible" : "Plazo Fijo", style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.6), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("${balance.toStringAsFixed(2)} TTC", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurfaceColor)),
                            ],
                          ),
                        ),
                        if (isFlexible)
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1), 
                              foregroundColor: Colors.blueAccent
                            ),
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => VaultDetailModal.show(context: context, vault: vault, onUpdate: _cargarBovedas),
                          )
                      ],
                    ),
                    if (hasTarget) ...[
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: (isFlexible ? Colors.blueAccent : Colors.purpleAccent).withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(isFlexible ? Colors.blueAccent : Colors.purpleAccent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: onSurfaceColor.withOpacity(0.6))),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}