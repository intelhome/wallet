import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/admin_service.dart';
import '../../../core/services/smart_avatar.dart';

class PendingBusinessesScreen extends StatefulWidget {
  const PendingBusinessesScreen({super.key});

  @override
  State<PendingBusinessesScreen> createState() => _PendingBusinessesScreenState();
}

class _PendingBusinessesScreenState extends State<PendingBusinessesScreen> {
  bool _isLoading = true;
  List<dynamic> _businesses = [];

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  // Future<void> _cargarEmpresas() async {
  //   setState(() => _isLoading = true);
  //   final adminService = Provider.of<AdminService>(context, listen: false);
  //   _businesses = await adminService.getPendingBusinesses();
  //   setState(() => _isLoading = false);
  // }

  Future<void> _cargarEmpresas() async {
    final cacheService = LocalCacheService();

    // 1. Caché Rápido
    final cached = cacheService.getCachedPendingBusinesses();
    if (cached.isNotEmpty && mounted) {
      setState(() { _businesses = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final adminService = Provider.of<AdminService>(context, listen: false);
    final fresh = await adminService.getPendingBusinesses();
    
    if (mounted) {
      setState(() { _businesses = fresh; _isLoading = false; });
    }
  }

  Future<void> _revisarEmpresa(String wallet, String nombre, bool isApproved) async {
    bool? confirm = await UIHelper.mostrarConfirmacion(
      context: context,
      titulo: isApproved ? "Aprobar Empresa" : "Rechazar Empresa",
      mensaje: isApproved 
          ? "¿Estás seguro de que deseas habilitar la cuenta comercial de $nombre?" 
          : "¿Deseas rechazar permanentemente la solicitud de $nombre?",
      textoConfirmar: isApproved ? "Aprobar" : "Rechazar",
      colorConfirmar: isApproved ? Colors.green : Colors.redAccent,
    );

    if (confirm != true) return;

    if (!mounted) return;
    UIHelper.showCustomSnackbar("Procesando...", isError: false);

    final adminService = Provider.of<AdminService>(context, listen: false);
    String res = await adminService.reviewBusiness(wallet, isApproved);

    if (res == "Exito") {
      UIHelper.showCustomSnackbar(isApproved ? "✅ Empresa aprobada." : "🚫 Empresa rechazada.");
      _cargarEmpresas(); // Refrescamos la lista
    } else {
      UIHelper.showCustomSnackbar("Error: $res", isError: true);
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
        title: const Text("Solicitudes Comerciales", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
        : _businesses.isEmpty
            ? UIHelper.emptyState(context: context, icon: Icons.store_mall_directory_rounded, title: "Al Día", message: "No hay empresas pendientes de aprobación.")
            : RefreshIndicator(
                color: Colors.purpleAccent,
                onRefresh: _cargarEmpresas,
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _businesses.length,
                  itemBuilder: (context, index) {
                    final b = _businesses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.2))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SmartAvatar(address: b['walletAddress'], size: 48),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b['businessName'] ?? "Empresa Desconocida", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                      Text("@${b['alias']}", style: TextStyle(color: onSurface.withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text("PENDIENTE", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                                )
                              ],
                            ),
                            const Divider(height: 32),
                            _buildInfoRow(Icons.email_rounded, b['email']),
                            _buildInfoRow(Icons.phone_rounded, b['phoneNumber']),
                            _buildInfoRow(Icons.badge_rounded, "RUC: ${b['ruc'] ?? 'N/A'}"),
                            if (b['website'] != null && b['website'].toString().isNotEmpty)
                              _buildInfoRow(Icons.language_rounded, b['website']),
                            
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], false),
                                    child: const Text("Rechazar"),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], true),
                                    child: const Text("Aprobar"),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}