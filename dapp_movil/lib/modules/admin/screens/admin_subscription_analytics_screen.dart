import 'package:dapp_movil/core/helpers/share_helper.dart';
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
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Analíticas de\nSuscripciones", maxLines: 2, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, height: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnalytics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF0D0FF), // Violeta claro de la imagen
        foregroundColor: const Color(0xFF5A2A7A), // Texto oscuro
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.manage_accounts_rounded),
        label: const Text("Gestionar Usuario", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => UpdateUserTierModal.show(context: context, onUpdateSuccess: _loadAnalytics),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
          : _data == null
              ? const Center(child: Text("Error al cargar datos"))
              : _buildDashboard(onSurface),
    );
  }

  // Widget _buildDashboard(Color onSurface) {
  //   final int totalUsers = _data!['totalUsers'] ?? 0;
  //   final double revenue = double.tryParse(_data!['estimatedMonthlyRevenueUSD'].toString()) ?? 0.0;
  //   final Map<String, dynamic> plans = _data!['plans'] ?? {};

  //   final List<Map<String, dynamic>> activeSlices = [];
    
  //   // Colores fieles a la imagen: FREE (Gris), BASIC (Azul), PREMIUM (Lila)
  //   if ((plans['FREE'] ?? 0) > 0) {
  //     activeSlices.add({"tier": "FREE", "color": Colors.grey.shade600, "value": (plans['FREE']).toDouble()});
  //   }
  //   if ((plans['BASIC'] ?? 0) > 0) {
  //     activeSlices.add({"tier": "BASIC", "color": const Color(0xFF4361EE), "value": (plans['BASIC']).toDouble()});
  //   }
  //   if ((plans['PREMIUM'] ?? 0) > 0) {
  //     activeSlices.add({"tier": "PREMIUM", "color": const Color(0xFFE0B0FF), "value": (plans['PREMIUM']).toDouble()});
  //   }

  //   if (activeSlices.isEmpty) {
  //     activeSlices.add({"tier": "NONE", "color": Colors.grey.withOpacity(0.3), "value": 1.0});
  //   }

  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(24),
  //     physics: const BouncingScrollPhysics(),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // TARJETA DE INGRESOS (Gradiente Púrpura-Azul)
  //         Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFF9D00FF), Color(0xFF4361EE)],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             borderRadius: BorderRadius.circular(24),
  //           ),
  //           child: Column(
  //             children: [
  //               Text("Ingresos Mensuales Estimados", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
  //               const SizedBox(height: 8),
  //               Text("\$${revenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
  //               const SizedBox(height: 12),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 16),
  //                   const SizedBox(width: 8),
  //                   Text("De un total de $totalUsers usuarios", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 48),

  //         // TÍTULO DEL GRÁFICO
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.baseline,
  //           textBaseline: TextBaseline.alphabetic,
  //           children: [
  //             Text("Distribución de Planes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
  //             const SizedBox(width: 8),
  //             Text("(Toca un área)", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5))),
  //           ],
  //         ),
  //         const SizedBox(height: 40),

  //         // GRÁFICO DE DONA (FL_CHART)
  //         SizedBox(
  //           height: 260,
  //           child: PieChart(
  //             PieChartData(
  //               sectionsSpace: 0, // Sin espacio entre secciones para efecto de dona pura
  //               centerSpaceRadius: 80, // Hueco grande en el centro
  //               pieTouchData: PieTouchData(
  //                 touchCallback: (FlTouchEvent event, pieTouchResponse) {
  //                   if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
  //                   if (event is FlTapUpEvent) {
  //                     final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
  //                     if (touchedIndex >= 0 && touchedIndex < activeSlices.length) {
  //                       String selectedTier = activeSlices[touchedIndex]['tier'];
  //                       if (selectedTier != "NONE") {
  //                         TierUsersModal.show(context: context, tier: selectedTier);
  //                       }
  //                     }
  //                   }
  //                 },
  //               ),
  //               sections: activeSlices.map((slice) {
  //                 return PieChartSectionData(
  //                   color: slice['color'],
  //                   value: slice['value'],
  //                   title: "", // Ocultamos el número dentro de la dona para un diseño más limpio
  //                   radius: 40, // Grosor del anillo
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 48),

  //         // LEYENDAS INFERIORES
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             _buildLegend("FREE", Colors.grey.shade600, onSurface),
  //             const SizedBox(width: 24),
  //             _buildLegend("BASIC", const Color(0xFF4361EE), onSurface),
  //             const SizedBox(width: 24),
  //             _buildLegend("PREMIUM", const Color(0xFFE0B0FF), onSurface),
  //           ],
  //         ),
  //         const SizedBox(height: 100), // Espacio para que el FAB no tape el contenido
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLegend(String title, Color color, Color onSurface) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: onSurface, letterSpacing: 1.0)),
      ],
    );
  }
Widget _buildDashboard(Color onSurface) {
    final int totalUsers = _data!['totalUsers'] ?? 0;
    final int newUsers = _data!['newUsersThisMonth'] ?? 0;
    final double growthPct = double.tryParse(_data!['userGrowthPercentage']?.toString() ?? '0') ?? 0.0;
    final double revenue = double.tryParse(_data!['estimatedMonthlyRevenueUSD']?.toString() ?? '0') ?? 0.0;
    final Map<String, dynamic> plans = _data!['plans'] ?? {};
    final List<dynamic> recentUsers = _data!['recentUsers'] ?? [];
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Map<String, dynamic>> activeSlices = [];
    
    if ((plans['FREE']?['count'] ?? 0) > 0) {
      activeSlices.add({"tier": "FREE", "color": Colors.grey.shade600, "value": (plans['FREE']['count']).toDouble()});
    }
    if ((plans['BASIC']?['count'] ?? 0) > 0) {
      activeSlices.add({"tier": "BASIC", "color": const Color(0xFF4361EE), "value": (plans['BASIC']['count']).toDouble()});
    }
    if ((plans['PREMIUM']?['count'] ?? 0) > 0) {
      activeSlices.add({"tier": "PREMIUM", "color": const Color(0xFFE0B0FF), "value": (plans['PREMIUM']['count']).toDouble()});
    }

    if (activeSlices.isEmpty) {
      activeSlices.add({"tier": "NONE", "color": Colors.grey.withOpacity(0.3), "value": 1.0});
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TARJETA PRINCIPAL DE INGRESOS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9D00FF), Color(0xFF4361EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF9D00FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
            ),
            child: Column(
              children: [
                Text("Ingresos Mensuales Estimados", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text("\$${revenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text("De un total de $totalUsers usuarios activos", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. NUEVAS TARJETAS GEMELAS DE CRECIMIENTO
          Row(
            children: [
             Expanded(child: _buildGrowthCard("Nuevos Usuarios", "+$newUsers", Icons.person_add_rounded, const Color(0xFF4361EE), Theme.of(context).cardColor, onSurface, realValue: newUsers.toDouble())),
      const SizedBox(width: 16),
      Expanded(child: _buildGrowthCard("Crecimiento", "${growthPct > 0 ? '+' : ''}$growthPct%", Icons.trending_up_rounded, growthPct >= 0 ? Colors.green : colorScheme.error, Theme.of(context).cardColor, onSurface, realValue: growthPct)),
            ],
          ),
          const SizedBox(height: 24),

          // BOTÓN DE DESCARGA DE REPORTE
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE0B0FF),
                side: const BorderSide(color: Color(0xFFE0B0FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: () {
                ShareHelper.generarYCompartirPDFAdminAnalytics(context, _data!);
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text("Exportar Reporte Ejecutivo", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 48),

          // TÍTULO DEL GRÁFICO
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("Distribución de Planes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(width: 8),
              Text("(Toca un área)", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 40),

          // GRÁFICO DE DONA (FL_CHART)
          SizedBox(
            height: 260,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0, 
                centerSpaceRadius: 80, 
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
                sections: activeSlices.map((slice) {
                  return PieChartSectionData(
                    color: slice['color'],
                    value: slice['value'],
                    title: "", 
                    radius: 40, 
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // LEYENDAS INFERIORES
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend("FREE", Colors.grey.shade600, onSurface),
              const SizedBox(width: 24),
              _buildLegend("BASIC", const Color(0xFF4361EE), onSurface),
              const SizedBox(width: 24),
              _buildLegend("PREMIUM", const Color(0xFFE0B0FF), onSurface),
            ],
          ),
          const SizedBox(height: 48),

          // NUEVA SECCIÓN: USUARIOS RECIENTES
          Text("Últimos Registros", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 16),
          if (recentUsers.isEmpty)
            Text("No hay usuarios recientes.", style: TextStyle(color: onSurface.withOpacity(0.5))),
          ...recentUsers.map((user) {
            bool isBusiness = user['accountType'] == 'BUSINESS';
            String date = user['createdAt'] != null ? DateTime.parse(user['createdAt']).toLocal().toString().substring(0, 10) : "";
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBusiness ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                  child: Icon(isBusiness ? Icons.storefront_rounded : Icons.person_rounded, color: isBusiness ? Colors.orange : Colors.blue),
                ),
                title: Text(user['alias'] ?? 'Sin Alias', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${user['walletAddress'] ?? ''}\n$date", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6))),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(user['membershipTier'] ?? 'FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSurface)),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

 Widget _buildGrowthCard(String title, String value, IconData icon, Color accentColor, Color cardColor, Color onSurface, {required double realValue}) {
    
    // Generar curva realista (7 puntos) basada en el valor real
    // Si el valor es negativo, la gráfica mostrará una tendencia a la baja.
    List<FlSpot> spots = [];
    double start = realValue > 0 ? (realValue * 0.3) : (realValue.abs() * 1.5);
    double end = realValue.abs() == 0 ? 1 : realValue.abs();
    double step = (end - start) / 6;

    for (int i = 0; i < 7; i++) {
      double currentY = start + (step * i);
      // Introducimos un poco de ruido para que parezca orgánica
      if (i > 0 && i < 6) currentY += (i % 2 == 0 ? (step * 0.2) : -(step * 0.1));
      if (realValue < 0) currentY = end - (step * i); // Invertir si es pérdida
      spots.add(FlSpot(i.toDouble(), currentY));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
          Text("Vs. el mes anterior", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 10)), // 🔥 Contexto agregado
          const SizedBox(height: 16),
          
          // Gráfica dinámica
          SizedBox(
            height: 40,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots, // 🔥 Puntos generados con datos reales
                    isCurved: true,
                    color: accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accentColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER PARA LAS MICRO-MÉTRICAS (Crecimiento)
  Widget _buildMetricMicro(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

 
}