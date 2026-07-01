import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/admin/modals/tier_users_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_service.dart';
import '../modals/update_user_tier_modal.dart';

class AdminSubscriptionAnalyticsScreen extends StatefulWidget {
  const AdminSubscriptionAnalyticsScreen({super.key});

  @override
  State<AdminSubscriptionAnalyticsScreen> createState() => _AdminSubscriptionAnalyticsScreenState();
}

class _AdminSubscriptionAnalyticsScreenState extends State<AdminSubscriptionAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  // Future<void> _loadAnalytics() async {
  //   setState(() => _isLoading = true);
  //   final adminService = Provider.of<AdminService>(context, listen: false);
  //   _data = await adminService.getSubscriptionAnalytics();
  //   setState(() => _isLoading = false);
  // }

  Future<void> _loadAnalytics() async {
    final cacheService = LocalCacheService();

    // 1. Caché Rápido
    final cached = cacheService.getCachedAdminAnalytics();
    if (cached != null && mounted) {
      setState(() { _data = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final adminService = Provider.of<AdminService>(context, listen: false);
    final fresh = await adminService.getSubscriptionAnalytics();
    
    if (mounted) {
      setState(() { _data = fresh; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Suscripciones", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.manage_accounts, color: Colors.white),
        label: const Text("Gestionar Usuario", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => UpdateUserTierModal.show(context: context, onUpdateSuccess: _loadAnalytics),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("Error al cargar datos"))
              : _buildDashboard(colorScheme),
    );
  }

  Widget _buildDashboard(ColorScheme colorScheme) {
    final int totalUsers = _data!['totalUsers'] ?? 0;
    final double revenue = double.tryParse(_data!['estimatedMonthlyRevenueUSD'].toString()) ?? 0.0;
    final Map<String, dynamic> plans = _data!['plans'] ?? {};

    final List<Map<String, dynamic>> activeSlices = [];
    
    if ((plans['FREE'] ?? 0) > 0) {
      activeSlices.add({"tier": "FREE", "color": Colors.grey, "value": (plans['FREE']).toDouble(), "radius": 40.0});
    }
    if ((plans['BASIC'] ?? 0) > 0) {
      activeSlices.add({"tier": "BASIC", "color": Colors.blueAccent, "value": (plans['BASIC']).toDouble(), "radius": 45.0});
    }
    if ((plans['PREMIUM'] ?? 0) > 0) {
      activeSlices.add({"tier": "PREMIUM", "color": Colors.purpleAccent, "value": (plans['PREMIUM']).toDouble(), "radius": 50.0});
    }

    // Si la BD está totalmente vacía, mostramos un gráfico gris por defecto
    if (activeSlices.isEmpty) {
      activeSlices.add({"tier": "NONE", "color": Colors.grey.withOpacity(0.3), "value": 1.0, "radius": 40.0});
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // TARJETA DE INGRESOS
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurple]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
          ),
          child: Column(
            children: [
              const Text("Ingresos Mensuales Estimados", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 10),
              Text("\$${revenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text("De un total de $totalUsers usuarios", style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // GRÁFICO DE PASTEL (FL_CHART)
        const Text("Distribución de Planes (Toca un área)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
                  
                  if (event is FlTapUpEvent) {
                    final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    
                    if (touchedIndex >= 0 && touchedIndex < activeSlices.length) {
                      String selectedTier = activeSlices[touchedIndex]['tier'];
                      if (selectedTier != "NONE") {
                        TierUsersModal.show(context: context, tier: selectedTier);
                      }
                    }
                  }
                },
              ),
              // Construimos las secciones dinámicamente
              sections: activeSlices.map((slice) {
                return PieChartSectionData(
                  color: slice['color'],
                  value: slice['value'],
                  title: slice['tier'] == "NONE" ? "0" : slice['value'].toInt().toString(),
                  radius: slice['radius'],
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // LEYENDAS (Siempre mostramos las 3 para referencia visual)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegend("FREE", Colors.grey),
            _buildLegend("BASIC", Colors.blueAccent),
            _buildLegend("PREMIUM", Colors.purpleAccent),
          ],
        ),
        const SizedBox(height: 80), // Espacio para el FAB
      ],
    );
  }
  Widget _buildLegend(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}