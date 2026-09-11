import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/modules/admin/modals/admin_transaction_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/admin_service.dart';

class AdminComplianceScreen extends StatefulWidget {
  const AdminComplianceScreen({super.key});

  @override
  State<AdminComplianceScreen> createState() => _AdminComplianceScreenState();
}

class _AdminComplianceScreenState extends State<AdminComplianceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ScrollController _whalesScrollController = ScrollController();
  List<dynamic> _whalesList = [];
  bool _isLoadingWhales = true;
  bool _isFetchingMoreWhales = false;
  bool _hasMoreWhales = true;
  int _pageWhales = 0;

  final ScrollController _failsScrollController = ScrollController();
  List<dynamic> _failsList = [];
  bool _isLoadingFails = true;
  bool _isFetchingMoreFails = false;
  bool _hasMoreFails = true;
  int _pageFails = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _loadInitialWhales();
    _whalesScrollController.addListener(() {
      if (_whalesScrollController.position.pixels >= _whalesScrollController.position.maxScrollExtent - 200) _loadMoreWhales();
    });

    _loadInitialFails();
    _failsScrollController.addListener(() {
      if (_failsScrollController.position.pixels >= _failsScrollController.position.maxScrollExtent - 200) _loadMoreFails();
    });
  }

  // --- LÓGICA WHALES (> 1000 TTC) ---
  Future<void> _loadInitialWhales() async {
    setState(() { _isLoadingWhales = true; _pageWhales = 0; _hasMoreWhales = true; });
    final data = await Provider.of<AdminService>(context, listen: false).getWhaleTransactions(1000, page: _pageWhales);
    if (mounted) setState(() { _whalesList = data['content'] ?? []; _hasMoreWhales = !(data['last'] ?? true); _isLoadingWhales = false; });
  }

  Future<void> _loadMoreWhales() async {
    if (_isFetchingMoreWhales || !_hasMoreWhales || _isLoadingWhales) return;
    setState(() => _isFetchingMoreWhales = true);
    _pageWhales++;
    final data = await Provider.of<AdminService>(context, listen: false).getWhaleTransactions(1000, page: _pageWhales);
    if (mounted) setState(() { _whalesList.addAll(data['content'] ?? []); _hasMoreWhales = !(data['last'] ?? true); _isFetchingMoreWhales = false; });
  }

  // --- LÓGICA FALLIDAS ---
  Future<void> _loadInitialFails() async {
    setState(() { _isLoadingFails = true; _pageFails = 0; _hasMoreFails = true; });
    final data = await Provider.of<AdminService>(context, listen: false).getFailedTransactions(page: _pageFails);
    if (mounted) setState(() { _failsList = data['content'] ?? []; _hasMoreFails = !(data['last'] ?? true); _isLoadingFails = false; });
  }

  Future<void> _loadMoreFails() async {
    if (_isFetchingMoreFails || !_hasMoreFails || _isLoadingFails) return;
    setState(() => _isFetchingMoreFails = true);
    _pageFails++;
    final data = await Provider.of<AdminService>(context, listen: false).getFailedTransactions(page: _pageFails);
    if (mounted) setState(() { _failsList.addAll(data['content'] ?? []); _hasMoreFails = !(data['last'] ?? true); _isFetchingMoreFails = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Compliance & AML", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: colorScheme.primary),
            tooltip: "Exportar a PDF",
            onPressed: () {
              // Validamos qué pestaña está activa para saber qué datos exportar
              if (_tabController.index == 0) {
                ShareHelper.generarYCompartirPDFCompliance(context, _whalesList, "Reporte de Ballenas (>1000 TTC)");
              } else {
                ShareHelper.generarYCompartirPDFCompliance(context, _failsList, "Reporte de Transacciones Fallidas/Revertidas");
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE0B0FF),
          labelColor: const Color(0xFFE0B0FF),
          unselectedLabelColor: onSurface.withOpacity(0.5),
          tabs: const [
            Tab(icon: Icon(Icons.waves_rounded), text: "Ballenas (>1000)"),
            Tab(icon: Icon(Icons.gpp_bad_rounded), text: "Revertidas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_whalesList, _isLoadingWhales, _hasMoreWhales, _isFetchingMoreWhales, _whalesScrollController, _loadInitialWhales, true),
          _buildList(_failsList, _isLoadingFails, _hasMoreFails, _isFetchingMoreFails, _failsScrollController, _loadInitialFails, false),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, bool isLoading, bool hasMore, bool isFetchingMore, ScrollController controller, Future<void> Function() onRefresh, bool isWhale) {
      final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    if (isLoading && items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.check_circle_outline_rounded, title: "Todo en orden", message: "No se encontraron transacciones en esta categoría.");

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (isFetchingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == items.length) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
          
          final tx = items[i];
          double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
          String date = tx['timestamp']?.toString().substring(0, 16).replaceAll("T", " ") ?? "";
          String status = tx['status'] ?? "UNKNOWN";
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: theme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), 
              side: BorderSide(color: isWhale ? Colors.blue.withOpacity(0.3) : colorScheme.error.withOpacity(0.3))
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: (isWhale ? Colors.blue : colorScheme.error).withOpacity(0.1),
                child: Icon(isWhale ? Icons.water_drop_rounded : Icons.gpp_bad_rounded, color: isWhale ? Colors.blue : colorScheme.error),
              ),
              title: Text("${amount.toStringAsFixed(2)} TTC", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("De: ${tx['senderAddress'] ?? ''}", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                  Text("Para: ${tx['receiverAddress'] ?? ''}", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 10)),
                ],
              ),
              // 🔥 FLECHA Y ESTADO EN EL TRAILING
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (status == 'COMPLETED' ? Colors.green : colorScheme.error).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: status == 'COMPLETED' ? Colors.green : colorScheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.4), size: 20),
                ],
              ),
              // 🔥 LLAMADA AL NUEVO MODAL AL HACER CLIC
              onTap: () {
                AdminTransactionDetailsModal.show(
                  context: context, 
                  tx: tx, 
                  isWhaleAlert: isWhale
                );
              },
            ),
          );
        },
      ),
    );
  }
}