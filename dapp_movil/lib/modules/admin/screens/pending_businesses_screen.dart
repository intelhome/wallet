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

  String _searchQuery = "";
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Future<void> _cargarEmpresas() async {
  //   setState(() => _isLoading = true);
  //   final adminService = Provider.of<AdminService>(context, listen: false);
  //   _businesses = await adminService.getPendingBusinesses();
  //   setState(() => _isLoading = false);
  // }

  List<dynamic> _getFilteredBusinesses() {
    return _businesses.where((b) {
      // 1. Filtro por búsqueda (Nombre, Alias o RUC)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (b['businessName'] ?? '').toString().toLowerCase();
        final alias = (b['alias'] ?? '').toString().toLowerCase();
        final ruc = (b['ruc'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !alias.contains(query) && !ruc.contains(query)) {
          return false;
        }
      }
      // 2. Filtro por Fecha (Asumiendo que el backend envía 'createdAt'. Si no, se puede adaptar)
      if (_selectedDate != null && b['createdAt'] != null) {
        try {
          DateTime bDate = DateTime.parse(b['createdAt'].toString());
          if (bDate.year != _selectedDate!.year || bDate.month != _selectedDate!.month || bDate.day != _selectedDate!.day) {
            return false;
          }
        } catch (e) {
          return false; // Si hay error parseando, lo ocultamos para mantener el filtro estricto
        }
      }
      return true;
    }).toList();
  }

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
    final filteredList = _getFilteredBusinesses();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Solicitudes Comerciales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                hintText: "Buscar empresa...",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // BOTÓN DE FILTRO Y LABEL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface.withOpacity(0.8),
                    backgroundColor: _selectedDate != null ? const Color(0xFFBAC3FF).withOpacity(0.1) : Colors.transparent,
                    side: BorderSide(color: _selectedDate != null ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.filter_list_rounded, size: 18),
                  label: const Text("Filtros"),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 12),
                  Chip(
                    label: Text("${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00218d))),
                    backgroundColor: const Color(0xFFBAC3FF),
                    deleteIconColor: const Color(0xFF00218d),
                    onDeleted: () => setState(() => _selectedDate = null),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                  )
                ]
              ],
            ),
          ),

          // LISTA DE TARJETAS
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
              : filteredList.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.store_mall_directory_rounded, title: "Sin Solicitudes", message: "No hay empresas pendientes que coincidan.")
                  : RefreshIndicator(
                      color: const Color(0xFF4361EE),
                      onRefresh: _cargarEmpresas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final b = filteredList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: onSurface.withOpacity(0.05)),
                            ),
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
                                          Text(b['businessName'] ?? "Empresa Desconocida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                                          Text("@${b['alias']}", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))),
                                      child: const Text("PENDIENTE", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                                    )
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Colors.white10)),
                                
                                _buildInfoRow(Icons.email_outlined, b['email'] ?? "No registrado", onSurface),
                                _buildInfoRow(Icons.phone_outlined, b['phoneNumber'] ?? "No registrado", onSurface),
                                _buildInfoRow(Icons.badge_outlined, "RUC: ${b['ruc'] ?? 'N/A'}", onSurface),
                                if (b['website'] != null && b['website'].toString().isNotEmpty)
                                  _buildInfoRow(Icons.language_rounded, b['website'], onSurface),
                                
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], false),
                                        child: const Text("Rechazar", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], true),
                                        child: const Text("Aprobar", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: onSurface.withOpacity(0.5)),
          const SizedBox(width: 16),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: onSurface.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final onSurface = colorScheme.onSurface;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Solicitudes Comerciales", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //     ),
  //     body: _isLoading 
  //       ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
  //       : _businesses.isEmpty
  //           ? UIHelper.emptyState(context: context, icon: Icons.store_mall_directory_rounded, title: "Al Día", message: "No hay empresas pendientes de aprobación.")
  //           : RefreshIndicator(
  //               color: Colors.purpleAccent,
  //               onRefresh: _cargarEmpresas,
  //               child: ListView.builder(
  //                 padding: const EdgeInsets.all(24),
  //                 itemCount: _businesses.length,
  //                 itemBuilder: (context, index) {
  //                   final b = _businesses[index];
  //                   return Card(
  //                     margin: const EdgeInsets.only(bottom: 16),
  //                     elevation: 0,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(24),
  //                       side: BorderSide(color: Colors.purpleAccent.withOpacity(0.2))
  //                     ),
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(20),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Row(
  //                             children: [
  //                               SmartAvatar(address: b['walletAddress'], size: 48),
  //                               const SizedBox(width: 16),
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(b['businessName'] ?? "Empresa Desconocida", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
  //                                     Text("@${b['alias']}", style: TextStyle(color: onSurface.withOpacity(0.5))),
  //                                   ],
  //                                 ),
  //                               ),
  //                               Container(
  //                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                                 decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
  //                                 child: const Text("PENDIENTE", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
  //                               )
  //                             ],
  //                           ),
  //                           const Divider(height: 32),
  //                           _buildInfoRow(Icons.email_rounded, b['email']),
  //                           _buildInfoRow(Icons.phone_rounded, b['phoneNumber']),
  //                           _buildInfoRow(Icons.badge_rounded, "RUC: ${b['ruc'] ?? 'N/A'}"),
  //                           if (b['website'] != null && b['website'].toString().isNotEmpty)
  //                             _buildInfoRow(Icons.language_rounded, b['website']),
                            
  //                           const SizedBox(height: 24),
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: OutlinedButton(
  //                                   style: OutlinedButton.styleFrom(
  //                                     foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
  //                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                                   ),
  //                                   onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], false),
  //                                   child: const Text("Rechazar"),
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 16),
  //                               Expanded(
  //                                 child: ElevatedButton(
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: Colors.green, foregroundColor: Colors.white,
  //                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                                   ),
  //                                   onPressed: () => _revisarEmpresa(b['walletAddress'], b['businessName'], true),
  //                                   child: const Text("Aprobar"),
  //                                 ),
  //                               ),
  //                             ],
  //                           )
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //   );
  // }

  // Widget _buildInfoRow(IconData icon, String text) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8.0),
  //     child: Row(
  //       children: [
  //         Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
  //         const SizedBox(width: 12),
  //         Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
  //       ],
  //     ),
  //   );
  // }
}