import 'dart:async';
import 'dart:convert';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:dapp_movil/modules/crowdfunding/widgets/campaign_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../../core/helpers/ui_helper.dart';

class RegionCampaignsTab extends StatefulWidget {
  const RegionCampaignsTab({super.key});

  @override
  State<RegionCampaignsTab> createState() => _RegionCampaignsTabState();
}

class _RegionCampaignsTabState extends State<RegionCampaignsTab> {
  final TextEditingController _regionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _campaigns = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String _currentRegion = "";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMore();
    });
  }

  Future<void> _loadInitial() async {
    if (!mounted || _currentRegion.isEmpty) return;
    setState(() { _isLoading = true; _page = 0; _hasMore = true; });

    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "REGION", region: _currentRegion, page: _page);

    if (mounted) {
      setState(() {
        _campaigns = data['content'] ?? [];
        _hasMore = !(data['last'] ?? true);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading || _currentRegion.isEmpty) return;
    setState(() => _isFetchingMore = true);
    
    _page++;
    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "REGION", region: _currentRegion, page: _page);

    if (mounted) {
      setState(() {
        _campaigns.addAll(data['content'] ?? []);
        _hasMore = !(data['last'] ?? true);
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _mostrarBuscadorRegiones() async {
    final selectedRegion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _RegionSearchModalContent(),
    );

    if (selectedRegion != null && selectedRegion.isNotEmpty) {
      setState(() { _currentRegion = selectedRegion; _regionController.text = selectedRegion; });
      _loadInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
            onTap: _mostrarBuscadorRegiones,
            child: AbsorbPointer(
              child: TextField(
                controller: _regionController,
                decoration: InputDecoration(
                  hintText: "Toca para buscar región...",
                  hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
        ),
        if (_currentRegion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text("Resultados en: $_currentRegion", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
          ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _campaigns.isEmpty && _currentRegion.isNotEmpty
              ? UIHelper.emptyState(context: context, icon: Icons.map, title: "Sin Resultados", message: "No hay campañas en esta región.")
              : _currentRegion.isEmpty 
                  ? Center(child: Text("Busca una región para empezar.", style: TextStyle(color: onSurface.withOpacity(0.5))))
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80, top: 0),
                        itemCount: _campaigns.length + (_isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _campaigns.length) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                          return CampaignCard(campaign: _campaigns[index], onRefresh: _loadInitial);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Componente Modal de Búsqueda de Region (OpenStreetMap)
// -------------------------------------------------------------
class _RegionSearchModalContent extends StatefulWidget {
  const _RegionSearchModalContent();
  @override
  State<_RegionSearchModalContent> createState() => _RegionSearchModalContentState();
}

class _RegionSearchModalContentState extends State<_RegionSearchModalContent> {
  List<dynamic> _resultados = [];
  bool _buscando = false;
  Timer? _debounce;

  void _buscar(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.length < 3) { setState(() => _resultados = []); return; }
    
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _buscando = true);
      try {
        final res = await http.get(
          Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6"),
          headers: {"User-Agent": "TTCWalletApp/1.0"} 
        );
        if (res.statusCode == 200) setState(() => _resultados = jsonDecode(res.body));
      } catch (e) { print("🚨 [BUSCADOR] Error: $e"); }
      if (mounted) setState(() => _buscando = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: "Ej. Cuenca, Ecuador", 
              prefixIcon: const Icon(Icons.search), 
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
            ),
            onChanged: _buscar,
          ),
          const SizedBox(height: 16),
          if (_buscando) const CircularProgressIndicator(),
          ..._resultados.map((lugar) => ListTile(
            leading: Icon(Icons.location_on_outlined, color: onSurface.withOpacity(0.7)),
            title: Text(lugar['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: onSurface)),
            onTap: () => Navigator.pop(context, lugar['display_name']),
          )).toList(),
        ],
      ),
    );
  }
}