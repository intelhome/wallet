import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/modules/admin/modals/admin_campaign_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/admin_service.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _stuckCampaigns = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMore();
    });
  }

  Future<void> _loadInitial() async {
    setState(() { _isLoading = true; _page = 0; _hasMore = true; });
    final data = await Provider.of<AdminService>(context, listen: false).getStuckCampaigns(page: _page);
    if (mounted) setState(() { _stuckCampaigns = data['content'] ?? []; _hasMore = !(data['last'] ?? true); _isLoading = false; });
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);
    _page++;
    final data = await Provider.of<AdminService>(context, listen: false).getStuckCampaigns(page: _page);
    if (mounted) setState(() { _stuckCampaigns.addAll(data['content'] ?? []); _hasMore = !(data['last'] ?? true); _isFetchingMore = false; });
  }

  Future<void> _forceRefund(String campaignId, String title) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    TextEditingController reasonCtrl = TextEditingController();

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.gavel_rounded, color: colorScheme.error), const SizedBox(width: 10), const Text("Reembolso Forzado")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Esta acción ordenará a la bóveda Escrow que devuelva los fondos a todos los donantes de la campaña.", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Razón del reembolso (Políticas KYC/AML...)",
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            onPressed: () {
              if (reasonCtrl.text.isEmpty) {
                UIHelper.showCustomSnackbar("Debes proveer una razón", isError: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text("Ejecutar Escrow"),
          )
        ],
      ),
    );

    if (confirm != true) return;

    // Pedir biometría al admin por seguridad
    bool isAuth = await Provider.of<AuthCoreService>(context, listen: false).authenticateUser();
    if (!isAuth) return;

    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Operación Crítica", message: "Procesando reembolsos masivos en Blockchain..."));

    final adminService = Provider.of<AdminService>(context, listen: false);
    String res = await adminService.forceRefundCampaign(campaignId, reasonCtrl.text);

    if (mounted) Navigator.pop(context); // Cerrar Skeleton

    if (res == "Exito") {
      UIHelper.showCustomSnackbar("Reembolso forzado ejecutado con éxito.");
      _loadInitial();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
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
        title: const Text("Soporte de Campañas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_rounded, color: colorScheme.primary),
            tooltip: "Exportar Campañas a PDF",
            onPressed: () {
              if (_stuckCampaigns.isNotEmpty) {
                ShareHelper.generarYCompartirPDFSoporte(context, _stuckCampaigns);
              } else {
                UIHelper.showCustomSnackbar("No hay datos para exportar.");
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _stuckCampaigns.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _stuckCampaigns.isEmpty
          ? UIHelper.emptyState(context: context, icon: Icons.volunteer_activism_rounded, title: "Sin Problemas", message: "No se detectaron campañas atascadas en la red.")
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _stuckCampaigns.length + (_isFetchingMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _stuckCampaigns.length) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                  
                  final campaign = _stuckCampaigns[i];
                  double raised = double.tryParse(campaign['raisedAmount']?.toString() ?? '0') ?? 0.0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: theme.cardColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        AdminCampaignDetailsModal.show(
                          context: context, 
                          campaign: campaign, 
                          onRefundSuccess: _loadInitial, 
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(campaign['title'] ?? 'Campaña Atascada', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("Fondos atrapados: $raised TTC", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Venció el: ${campaign['deadline']?.toString().substring(0, 10)}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}