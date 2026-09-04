import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:dapp_movil/modules/crowdfunding/widgets/campaign_card.dart';

class GlobalCampaignsTab extends StatefulWidget {
  const GlobalCampaignsTab({super.key});

  @override
  State<GlobalCampaignsTab> createState() => _GlobalCampaignsTabState();
}

class _GlobalCampaignsTabState extends State<GlobalCampaignsTab> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _campaigns = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _page = 0; _hasMore = true; });

    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "WORLDWIDE", page: _page);

    if (mounted) {
      setState(() {
        _campaigns = data['content'] ?? [];
        _hasMore = !(data['last'] ?? true);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);
    
    _page++;
    final service = Provider.of<CrowdfundingService>(context, listen: false);
    final data = await service.getCampaignsPaged(filter: "WORLDWIDE", page: _page);

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
    if (_isLoading && _campaigns.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_campaigns.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.public, title: "Sin Campañas", message: "No se encontraron campañas globales.");

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