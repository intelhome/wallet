import 'dart:async';
import 'dart:convert';

import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/crowdfunding/modals/campaign_details_modal.dart';
import 'package:dapp_movil/modules/crowdfunding/modals/create_crowdfunding_modal.dart';
import 'package:dapp_movil/modules/crowdfunding/modals/donate_modal.dart';
import 'package:dapp_movil/modules/crowdfunding/screens/global_campaigns_tab.dart';
import 'package:dapp_movil/modules/crowdfunding/screens/nearby_campaigns_tab.dart';
import 'package:dapp_movil/modules/crowdfunding/screens/region_campaigns_tab.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/services/transaction_skeleton.dart';


class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {

  void _crearCampana() async {
    String regionDetectada = "Global";
    double lat = 0.0;
    double lon = 0.0;

    UIHelper.showCustomSnackbar("Obteniendo ubicación para tu campaña...", isError: false);
    
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: const Duration(seconds: 15));
      lat = pos.latitude; lon = pos.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        regionDetectada = "${place.locality}, ${place.administrativeArea}, ${place.country}"; 
      }
    } catch (e) {
      print("⚠️ No se pudo geolocalizar al crear campaña. Se usará Global/0.0");
    }

    if (!mounted) return;

    CreateCrowdfundingModal.show(
      context: context,
      initialRegion: regionDetectada,
      initialLat: lat,
      initialLon: lon,
      onSuccess: () {
        // En una arquitectura compleja usaríamos un EventBus o Provider para recargar las tabs.
        // Por ahora, le notificamos al usuario.
        UIHelper.showCustomSnackbar("Campaña creada. Arrastra la lista hacia abajo para refrescar.");
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // 🔥 Limpio de colores quemados
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("Crowdfunding DeFi", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
            tabs: const [
              Tab(icon: Icon(Icons.public_rounded), text: "Global"),
              Tab(icon: Icon(Icons.location_on_rounded), text: "Cerca de mí"),
              Tab(icon: Icon(Icons.map_rounded), text: "Por Región"),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), // Evita deslizar por error
          children: [
            GlobalCampaignsTab(),
            NearbyCampaignsTab(),
            RegionCampaignsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _crearCampana,
          icon: const Icon(Icons.add_rounded),
          label: const Text("Lanzar Campaña", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// class CampaignsScreen extends StatefulWidget {
//   const CampaignsScreen({super.key});

//   @override
//   State<CampaignsScreen> createState() => _CampaignsScreenState();
// }

// class _CampaignsScreenState extends State<CampaignsScreen> {

//   List<dynamic> _campaigns = [];
// bool _isLoading = true;

//   //late Future<List<dynamic>> _campaignsFuture;
//   String _currentFilter = "WORLDWIDE";
//   String _currentRegion = "";
//   final TextEditingController _regionController = TextEditingController();

//   AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

//   @override
//   void initState() {
//     super.initState();
//     _pedirPermisoUbicacionInicial();
//     //_loadCampaigns();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadCampaigns();
//     });
//   }

//   Future<void> _pedirPermisoUbicacionInicial() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       await Geolocator.requestPermission();
//     }
//   }

//   // void _loadCampaigns() {
//   //   _campaignsFuture = Provider.of<CrowdfundingService>(context, listen: false)
//   //       .getCampaigns(filter: _currentFilter, region: _currentRegion);
//   // }

//   void _loadCampaigns() async {
//     setState(() => _isLoading = true);
//     final cacheService = LocalCacheService();

//     // 1. Mostrar Caché Rápido (Si no es búsqueda por GPS)
//     if (_currentFilter != "NEARBY") {
//       final cached = cacheService.getCachedCampaigns(_currentFilter, _currentRegion);
//       if (cached.isNotEmpty && mounted) {
//         setState(() {
//           _campaigns = cached;
//           _isLoading = false;
//         });
//       }
//     }

//     // 2. Traer de red fresca
//     try {
//       final freshData = await Provider.of<CrowdfundingService>(context, listen: false)
//           .getCampaigns(filter: _currentFilter, region: _currentRegion);
      
//       if (mounted) {
//         setState(() {
//           _campaigns = freshData;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted && _campaigns.isEmpty) setState(() => _isLoading = false);
//     }
//   }

//   // Future<void> _obtenerCercanos() async {
//   //   LocationPermission permission = await Geolocator.checkPermission();
//   //   if (permission == LocationPermission.denied) {
//   //     permission = await Geolocator.requestPermission();
//   //     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//   //       UIHelper.showCustomSnackbar("Se requiere GPS para ver campañas locales", isError: true);
//   //       return;
//   //     }
//   //   }
    
//   //   UIHelper.showCustomSnackbar("Buscando a tu alrededor...", isError: false);
    
//   //   // 1. Iniciamos la carga manual
//   //   setState(() {
//   //     _currentFilter = "NEARBY";
//   //     _currentRegion = "";
//   //     _isLoading = true; 
//   //   });
    
//   //   try {
//   //     print("📍 [GPS] Intentando obtener coordenadas físicas...");
//   //     Position pos = await Geolocator.getCurrentPosition(
//   //       desiredAccuracy: LocationAccuracy.best,
//   //       timeLimit: const Duration(seconds: 15)
//   //     );
//   //     print("✅ [GPS] Éxito: Lat ${pos.latitude}, Lon ${pos.longitude}");
      
//   //     // 2. Traemos la data
//   //     final fresh = await Provider.of<CrowdfundingService>(context, listen: false)
//   //         .getCampaigns(filter: "NEARBY", lat: pos.latitude, lon: pos.longitude);
      
//   //     // 3. Pintamos la pantalla
//   //     if (mounted) {
//   //       setState(() {
//   //         _campaigns = fresh;
//   //         _isLoading = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     UIHelper.showCustomSnackbar("Error obteniendo ubicación. Asegúrate de encender el GPS del emulador/teléfono.", isError: true);
//   //     // Apagamos el loader si hubo error
//   //     if (mounted) setState(() => _isLoading = false);
//   //   }
//   // }

//   Future<void> _obtenerCercanos() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         UIHelper.showCustomSnackbar("Se requiere GPS para ver campañas locales", isError: true);
//         return;
//       }
//     }
    
//     UIHelper.showCustomSnackbar("Buscando a tu alrededor...", isError: false);
    
//     setState(() {
//       _currentFilter = "NEARBY";
//       _currentRegion = "";
//       _isLoading = true;
//     });

//     try {
//       Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//         timeLimit: const Duration(seconds: 15)
//       );
      
//       final freshData = await Provider.of<CrowdfundingService>(context, listen: false)
//           .getCampaigns(filter: "NEARBY", lat: pos.latitude, lon: pos.longitude);
          
//       if (mounted) {
//         setState(() {
//           _campaigns = freshData;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _isLoading = false);
//       UIHelper.showCustomSnackbar("Error obteniendo ubicación. Enciende el GPS.", isError: true);
//     }
//   }

//   void _buscarPorRegion() {
//     if (_regionController.text.trim().isEmpty) return;
//     setState(() {
//       _currentFilter = "REGION";
//       _currentRegion = _regionController.text.trim();
//     });
//     _loadCampaigns();
//   }

//   void _crearCampana() async {
//     String regionDetectada = "Global";
//     double lat = 0.0;
//     double lon = 0.0;

//     UIHelper.showCustomSnackbar("Obteniendo ubicación para tu campaña...", isError: false);
    
//    try {
//       print("📍 [GPS CREAR] Iniciando petición al hardware GPS...");
//       Position pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//         timeLimit: const Duration(seconds: 15)
//       );
//       print("✅ [GPS CREAR] Éxito: Lat ${pos.latitude}, Lon ${pos.longitude}");
//       lat = pos.latitude;
//       lon = pos.longitude;

//       // 🔥 Resolviendo la región real a partir de coordenadas
//       List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks.first;
//         regionDetectada = "${place.locality}, ${place.administrativeArea}, ${place.country}"; // Ej: Cuenca, Azuay, Ecuador
//       }
//     } catch (e) {
//       print("⚠️ No se pudo geolocalizar al crear campaña. Se usará Global/0.0");
//     }

//     if (!mounted) return;

//     CreateCrowdfundingModal.show(
//       context: context,
//       initialRegion: regionDetectada,
//       initialLat: lat,
//       initialLon: lon,
//       onSuccess: () {
//         setState(() { _currentFilter = "WORLDWIDE"; _currentRegion = ""; });
//         _loadCampaigns();
//       }
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         backgroundColor: const Color(0xFF0F1626), // Dark background matching the image
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: const Text("Crowdfunding DeFi", style: TextStyle(fontWeight: FontWeight.bold)),
//           bottom: TabBar(
//             indicatorColor: const Color(0xFFB5C0FF),
//             labelColor: const Color(0xFFB5C0FF),
//             unselectedLabelColor: Colors.grey,
//             onTap: (index) {
//               if (index == 0) {
//                 setState(() { _currentFilter = "WORLDWIDE"; _currentRegion = ""; });
//                 _loadCampaigns();
//               } else if (index == 1) {
//                 _obtenerCercanos();
//               } else if (index == 2) {
//                 setState(() { _currentFilter = "REGION"; });
//                 if (_currentRegion.isNotEmpty) _loadCampaigns();
//               }
//             },
//             tabs: const [
//               Tab(icon: Icon(Icons.public_rounded), text: "Global"),
//               Tab(icon: Icon(Icons.location_on_rounded), text: "Cerca de mí"),
//               Tab(icon: Icon(Icons.map_rounded), text: "Por Región"),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           physics: const NeverScrollableScrollPhysics(), // Evitar deslices accidentales mientras cargan
//           children: [
//             _buildList(), // Tab 1: Global
//             _buildList(), // Tab 2: Cerca de mí
//             _buildRegionSearchAndList(), // Tab 3: Búsqueda
//           ],
//         ),
//         floatingActionButton: FloatingActionButton.extended(
//           onPressed: _crearCampana,
//           icon: const Icon(Icons.add_rounded),
//           label: const Text("Lanzar Campaña", style: TextStyle(fontWeight: FontWeight.bold)),
//           backgroundColor: const Color(0xFFB5C0FF),
//           foregroundColor: const Color(0xFF001F44),
//         ),
//       ),
//     );
//   }

//   Widget _buildRegionSearchAndList() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: GestureDetector(
//             onTap: () => _mostrarBuscadorRegiones(context),
//             child: AbsorbPointer(
//               child: TextField(
//                 controller: _regionController,
//                 decoration: InputDecoration(
//                   hintText: "Toca para buscar región...",
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         if (_currentRegion.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Text("Resultados en: $_currentRegion", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
//           ),
//         Expanded(child: _buildList()),
//       ],
//     );
//   }

//   Future<void> _mostrarBuscadorRegiones(BuildContext context) async {
//     final selectedRegion = await showModalBottomSheet<String>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => const RegionSearchModal(),
//     );

//     if (selectedRegion != null && selectedRegion.isNotEmpty) {
//       setState(() {
//         _currentFilter = "REGION";
//         _currentRegion = selectedRegion;
//         _regionController.text = selectedRegion;
//       });
//       _loadCampaigns();
//     }
//   }
//   // Widget _buildList() {
//   //   return FutureBuilder<List<dynamic>>(
//   //     future: _campaignsFuture,
//   //     builder: (context, snapshot) {
//   //       if (snapshot.connectionState == ConnectionState.waiting) {
//   //         return const Center(child: CircularProgressIndicator());
//   //       }
//   //       if (snapshot.hasError) {
//   //         return UIHelper.emptyState(context: context, icon: Icons.error_outline, title: "Error", message: snapshot.error.toString());
//   //       }
//   //       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//   //         return UIHelper.emptyState(context: context, icon: Icons.inbox_rounded, title: "Sin Campañas", message: "No se encontraron resultados en esta categoría.");
//   //       }

//   //       final campaigns = snapshot.data!;
//   //       return RefreshIndicator(
//   //         onRefresh: () async => _loadCampaigns(),
//   //         child: ListView.builder(
//   //           padding: const EdgeInsets.only(bottom: 80, top: 16), // Espacio para el FAB
//   //           itemCount: campaigns.length,
//   //           itemBuilder: (context, index) => _buildCampaignCard(campaigns[index]),
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }

//   Widget _buildList() {
//     // 1. Mostrar spinner solo si está cargando y NO hay caché
//     if (_isLoading && _campaigns.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }
    
//     // 2. Mostrar estado vacío
//     if (_campaigns.isEmpty) {
//       return UIHelper.emptyState(context: context, icon: Icons.inbox_rounded, title: "Sin Campañas", message: "No se encontraron resultados en esta categoría.");
//     }

//     // 3. Pintar la lista (Usando _campaigns)
//     return RefreshIndicator(
//       onRefresh: () async => _loadCampaigns(),
//       child: ListView.builder(
//         padding: const EdgeInsets.only(bottom: 80, top: 16),
//         itemCount: _campaigns.length,
//         itemBuilder: (context, index) => _buildCampaignCard(_campaigns[index]),
//       ),
//     );
//   }

//   Widget _buildCampaignCard(dynamic campaign) {
//     final colorScheme = Theme.of(context).colorScheme;
//     double target = double.tryParse(campaign['targetAmount']?.toString() ?? "0") ?? 0;
//     double raised = double.tryParse(campaign['raisedAmount']?.toString() ?? "0") ?? 0;
//     double progress = target > 0 ? (raised / target) : 0;
//     String status = campaign['status'] ?? "ACTIVE";

//     int backers = campaign['backersCount'] ?? (campaign['title'] == 'test coordenadas' ? 12 : 0); // Mock data for UI 
//     int daysLeft = campaign['daysLeft'] ?? (campaign['title'] == 'test coordenadas' ? 5 : 14); // Mock data for UI

//     return GestureDetector(
//       onTap: () {
//         CampaignDetailsModal.show(
//           context: context, 
//           campaign: campaign,
//           onRefresh: _loadCampaigns
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFF192033), // Dark card background from image
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(color: const Color(0xFF3B1E54), borderRadius: BorderRadius.circular(12)),
//                     child: Text((campaign['category'] ?? "LOCAL").toUpperCase(), style: const TextStyle(color: Color(0xFFB5C0FF), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
//                   ),
//                   Flexible(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
//                         const SizedBox(width: 4),
//                         Flexible(
//                           child: Text("${campaign['region'] ?? 'Azuay, Ecuador'}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
              
//               Text(campaign['title'] ?? "Sin título", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
//               const SizedBox(height: 16),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.people_outline_rounded, color: Colors.grey, size: 16),
//                       const SizedBox(width: 6),
//                       Text("$backers backers", style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time_rounded, color: Colors.grey, size: 16),
//                       const SizedBox(width: 6),
//                       Text("$daysLeft days left", style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("$raised TTC recaudados", style: const TextStyle(color: Color(0xFFB5C0FF), fontWeight: FontWeight.bold, fontSize: 13)),
//                   Text("Meta: $target TTC", style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: LinearProgressIndicator(
//                   value: progress,
//                   minHeight: 8,
//                   backgroundColor: Colors.white.withOpacity(0.1),
//                   color: status == "FAILED_REFUNDED" || status == "CANCELLED" ? Colors.red : (progress >= 1.0 ? Colors.green : const Color(0xFFB5C0FF)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class RegionSearchModal extends StatefulWidget {
//   const RegionSearchModal({super.key});
//   @override
//   State<RegionSearchModal> createState() => _RegionSearchModalState();
// }

// class _RegionSearchModalState extends State<RegionSearchModal> {
//   List<dynamic> _resultados = [];
//   bool _buscando = false;
//   Timer? _debounce;

//   void _buscar(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     if (query.length < 3) { setState(() => _resultados = []); return; }
    
//    _debounce = Timer(const Duration(milliseconds: 600), () async {
//       setState(() => _buscando = true);
//       try {
//         final res = await http.get(
//           Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6"),
//           headers: {"User-Agent": "TTCWalletApp/1.0"} // 🔥 OpenStreetMap requiere esto o da error 403
//         );
//         if (res.statusCode == 200) setState(() => _resultados = jsonDecode(res.body));
//       } catch (e) { print("🚨 [BUSCADOR] Error: $e"); }
//       setState(() => _buscando = false);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextField(
//             autofocus: true,
//             decoration: InputDecoration(hintText: "Ej. Cuenca, Ecuador", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
//             onChanged: _buscar,
//           ),
//           const SizedBox(height: 16),
//           if (_buscando) const CircularProgressIndicator(),
//           ..._resultados.map((lugar) => ListTile(
//             leading: const Icon(Icons.location_on_outlined),
//             title: Text(lugar['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
//             onTap: () => Navigator.pop(context, lugar['display_name']),
//           )).toList(),
//         ],
//       ),
//     );
//   }
// }