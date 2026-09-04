import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:dapp_movil/modules/crowdfunding/widgets/campaign_card.dart';

class NearbyCampaignsTab extends StatefulWidget {
  const NearbyCampaignsTab({super.key});

  @override
  State<NearbyCampaignsTab> createState() => _NearbyCampaignsTabState();
}

class _NearbyCampaignsTabState extends State<NearbyCampaignsTab> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _campaigns = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;
  double _lat = 0;
  double _lon = 0;
  bool _hasGps = false;

  @override
  void initState() {
    super.initState();
    _iniciarBusquedaGPS();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _iniciarBusquedaGPS() async {
    setState(() => _isLoading = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if(mounted) setState(() { _isLoading = false; _hasGps = false; });
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 10));
      _lat = pos.latitude; _lon = pos.longitude; _hasGps = true;
      _loadInitial();
    } catch (e) {
      if(mounted) setState(() { _isLoading = false; _hasGps = false; });
    }
  }

  Future<void> _loadInitial() async {
    if (!mounted || !_hasGps) return;
    setState(() { _page = 0; _hasMore = true; _isLoading = true; });

    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "NEARBY", lat: _lat, lon: _lon, page: _page);

    if (mounted) {
      setState(() {
        _campaigns = data['content'] ?? [];
        _hasMore = !(data['last'] ?? true);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading || !_hasGps) return;
    setState(() => _isFetchingMore = true);
    
    _page++;
    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "NEARBY", lat: _lat, lon: _lon, page: _page);

    if (mounted) {
      setState(() {
        _campaigns.addAll(data['content'] ?? []);
        _hasMore = !(data['last'] ?? true);
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (!_hasGps) return UIHelper.emptyState(context: context, icon: Icons.gps_off_rounded, title: "GPS Inactivo", message: "Activa tu ubicación para ver campañas cercanas.", actionLabel: "Reintentar", onAction: _iniciarBusquedaGPS);
    if (_campaigns.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.location_on, title: "Nada por aquí", message: "No se encontraron campañas cerca de ti.");

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80, top: 16),
        itemCount: _campaigns.length + (_isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _campaigns.length) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
          return CampaignCard(campaign: _campaigns[index], onRefresh: _loadInitial);
        },
      ),
    );
  }
}