import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/burner_wallets/modals/burner_details_modal.dart';
import 'package:dapp_movil/modules/burner_wallets/modals/create_burner_modal.dart';
import 'package:dapp_movil/modules/burner_wallets/services/burner_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../core/services/transaction_skeleton.dart';

class BurnerWalletsScreen extends StatefulWidget {
  const BurnerWalletsScreen({super.key});

  @override
  State<BurnerWalletsScreen> createState() => _BurnerWalletsScreenState();
}

class _BurnerWalletsScreenState extends State<BurnerWalletsScreen> {
  //late Future<List<dynamic>> _burnersFuture;
  List<dynamic> _burners = [];
  bool _isLoading = true;
  IOWebSocketChannel? _wsChannel;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  BurnerService get burnerService => Provider.of<BurnerService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _refresh();
    _conectarWebsocket();
  }

  // void _refresh() {
  //   if (!mounted) return;
  //   setState(() {
  //     _burnersFuture = burnerService.getActiveBurners();
  //   });
  // }

  void _refresh() async {
    if (!mounted) return;
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    // 1. Mostrar Caché Rápido
    final cached = cacheService.getCachedActiveBurners(wallet);
    if (cached.isNotEmpty && mounted) {
      setState(() { _burners = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Traer de red fresca
    final freshData = await burnerService.getActiveBurners();
    if (mounted) {
      setState(() { _burners = freshData; _isLoading = false; });
    }
  }

  // 🔥 Conexión WebSocket para actualizaciones en TIEMPO REAL
  void _conectarWebsocket() {
    try {
      // Reemplazamos http:// por ws:// en la URL base
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = "$baseWsUrl/ws/burners/${authCore.publicAddress}";
      
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: authCore.authHeaders,
      );

      _wsChannel!.stream.listen((message) {
        print("📲 WS Burner Event: $message");
        _refresh(); // Recarga la lista instantáneamente cuando el backend avisa
      }, onError: (err) {
        print("❌ WS Burner Error: $err");
      });
    } catch (e) {
      print("❌ Error iniciando WS Burner: $e");
    }
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Tarjetas Virtuales", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // body: FutureBuilder<List<dynamic>>(
      //   future: _burnersFuture,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator(color: colorScheme.primary));
      //     }
      //     final burners = snapshot.data ?? [];

      //     if (burners.isEmpty) {
      //       return _buildEmptyState(colorScheme);
      //     }

      //     return RefreshIndicator(
      //       onRefresh: () async => _refresh(),
      //       child: ListView.builder(
      //         padding: const EdgeInsets.all(20),
      //         itemCount: burners.length,
      //         itemBuilder: (context, index) => _BurnerCard(
      //           wallet: burners[index],
      //           onRefresh: _refresh,
      //         ),
      //       ),
      //     );
      //   },
      // ),

       body: _isLoading && _burners.isEmpty
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _burners.isEmpty
              ? _buildEmptyState(colorScheme)
              : RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _burners.length,
                    itemBuilder: (context, index) => _BurnerCard(
                      wallet: _burners[index],
                      onRefresh: _refresh,
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_principal',
        onPressed: () => CreateBurnerModal.show(context: context, onSuccess: _refresh), // 🔥 LLamamos al nuevo modal independiente
        label: const Text("Nueva Tarjeta", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_card_rounded),
      backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary, 
        elevation: 2,
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.security_rounded, size: 80, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text("Privacidad Absoluta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "Genera billeteras secundarias desechables para proteger tu identidad y fondos principales al interactuar con plataformas Web3 desconocidas.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET DE LA TARJETA
class _BurnerCard extends StatelessWidget {
  final dynamic wallet;
  final VoidCallback onRefresh;

  const _BurnerCard({required this.wallet, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String address = wallet['burnerAddress'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: Colors.black45,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => BurnerDetailsModal.show(context, wallet, onRefresh),
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            // 🔥 Degradado usando los colores del AppTheme
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary, colorScheme.tertiary.withOpacity(0.8)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 45,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withOpacity(0.8), // 🔥 Reemplaza el dorado quemado
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white38, width: 0.5),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text("VIRTUAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
                        ),
                        const SizedBox(height: 4),
                        const Text("TTC", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
              
                Text(
                  address,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'monospace', letterSpacing: 1.0),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CARD HOLDER", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text(
                            (wallet['label'] ?? 'BILLETERA TEMPORAL').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("BALANCE", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(
                          "${wallet['balance'] ?? '0.0'} TTC",
                          // 🔥 Reemplaza el amarillo quemado por el texto onPrimary
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 12),
                      const SizedBox(width: 4),
                      Text("TOCA PARA VER DETALLES", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}