import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../../core/helpers/share_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  UserService get userService => Provider.of<UserService>(context, listen: false);
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;

  // Controladores para las Historias
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controlador de Confeti para la Pantalla 3
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await userService.getAnalyticsData();
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  // Future<void> _loadData() async {
  //   final cacheService = LocalCacheService();

  //   // 1. Cargar caché inmediatamente (¡Velocidad luz!)
  //   final cachedData = cacheService.getCachedAnalytics();
  //   if (cachedData.isNotEmpty && mounted) {
  //     setState(() {
  //       _analyticsData = cachedData;
  //       _isLoading = false; // Pintamos la pantalla al instante
  //     });
  //   }

  //   // 2. Traer data fresca de la red en segundo plano
  //   try {
  //     final freshData = await userService.getAnalyticsData();
  //     if (mounted && freshData != null) {
  //       await cacheService.saveAnalytics(freshData); // Guardamos la nueva data
  //       setState(() {
  //         _analyticsData = freshData;
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     // Si la red falla, el usuario ni lo nota porque ya está viendo el caché
  //     if (mounted && _analyticsData == null) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  // --- MODALS DE DETALLES INTERACTIVOS ---

  void _showPieDetailsModal(String category, double amount, bool esGasto) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: (esGasto ? colorScheme.error : Colors.teal).withOpacity(0.1),
              child: Icon(esGasto ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                  color: esGasto ? colorScheme.error : Colors.teal, size: 30),
            ),
            const SizedBox(height: 16),
            Text(_getFriendlyName(category), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "${amount.toStringAsFixed(2)} TTC",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              esGasto ? "Total gastado en esta categoría" : "Total ingresado por esta categoría",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Entendido"),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showLineDetailsModal(String date, double ingresos, double egresos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text("Actividad del $date", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumenMini("Ingresos", ingresos, Colors.teal),
                _buildResumenMini("Egresos", egresos, Theme.of(context).colorScheme.error),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenMini(String titulo, double monto, Color color) {
    return Column(
      children: [
        Text(titulo, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 8),
        Text("${monto.toStringAsFixed(2)} TTC", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  // --- VISTAS DE LAS HISTORIAS (PÁGINAS) ---

  Widget _buildStory1_Resumen(double totalMovido) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, size: 80, color: Colors.amberAccent),
          const SizedBox(height: 20),
          Text("Este mes estuviste imparable",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 30),
          Text("Moviste un total de", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 16)),
          const SizedBox(height: 10),
          // Animación del número gigante
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: totalMovido),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Text(
                "${value.toStringAsFixed(2)} TTC",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.amberAccent),
              );
            },
          ),
          const Spacer(),
          const Text("Desliza para ver tus gráficos 👉", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStory2_Graficos(Map<String, dynamic> data) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const SizedBox(height: 40), // Espacio para el top bar
          const Text("Tu Radiografía Financiera", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const TabBar(
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.deepPurpleAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Gastos"), Tab(text: "Ingresos"), Tab(text: "Actividad")],
          ),
          Expanded(
            child: TabBarView(
              // Bloqueamos el scroll del TabBar para que no interfiera con el PageView de las historias
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInteractivePieChart(data['distribucionGastos'] ?? {}, true),
                _buildInteractivePieChart(data['distribucionIngresos'] ?? {}, false),
                _buildInteractiveLineChart(data['actividadDiaria'] ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStory3_Recompensas(double cashback) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch_rounded, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 20),
              const Text("¡La Blockchain te premió!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              const Text("Tus rendimientos DeFi y Cashback sumaron:",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurpleAccent),
                ),
                child: Text("+${cashback.toStringAsFixed(2)} TTC",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
              ),
            ],
          ),
        ),
        // Disparador de Confeti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ),
      ],
    );
  }

  // --- CONSTRUCTORES DE GRÁFICOS INTERACTIVOS ---

  Widget _buildInteractivePieChart(Map<String, dynamic> distribucion, bool esGasto) {
    final entries = distribucion.entries.where((e) => (e.value as num).toDouble() > 0).toList();
    if (entries.isEmpty) return UIHelper.emptyState(context: context,icon: Icons.pie_chart_outline, title: "Sin datos", message: "No hay movimientos aquí.");

    List<Color> colors = [Colors.deepPurpleAccent, Colors.teal, Colors.orangeAccent, Colors.pinkAccent, Colors.blueAccent];
    
    List<PieChartSectionData> sections = List.generate(entries.length, (index) {
      double value = (entries[index].value as num).toDouble();
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: value.toStringAsFixed(0),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("Toca una sección para ver detalles", style: TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: sections,
              // 🔥 AQUI ESTÁ LA INTERACTIVIDAD
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                    int index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < entries.length) {
                      _showPieDetailsModal(entries[index].key, (entries[index].value as num).toDouble(), esGasto);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        // Leyendas
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(entries.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[index % colors.length])),
                  const SizedBox(width: 6),
                  Text(_getFriendlyName(entries[index].key), style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInteractiveLineChart(List<dynamic> actividadDiaria) {
    if (actividadDiaria.isEmpty) return UIHelper.emptyState(context: context,icon: Icons.show_chart, title: "Sin datos", message: "Aún no hay historial.");

    List<FlSpot> ingresosSpots = [];
    List<FlSpot> egresosSpots = [];

    for (int i = 0; i < actividadDiaria.length; i++) {
      var day = actividadDiaria[i];
      ingresosSpots.add(FlSpot(i.toDouble(), (day['ingresos'] as num).toDouble()));
      egresosSpots.add(FlSpot(i.toDouble(), (day['egresos'] as num).toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Toca un punto en la gráfica para ver el día", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: ingresosSpots, isCurved: true, color: Colors.teal, barWidth: 4, dotData: const FlDotData(show: true)),
                  LineChartBarData(spots: egresosSpots, isCurved: true, color: Theme.of(context).colorScheme.error, barWidth: 4, dotData: const FlDotData(show: true)),
                ],
                // 🔥 AQUI ESTÁ LA INTERACTIVIDAD
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (FlTouchEvent event, lineTouchResponse) {
                    if (event is FlTapUpEvent && lineTouchResponse != null && lineTouchResponse.lineBarSpots != null) {
                      int spotIndex = lineTouchResponse.lineBarSpots!.first.spotIndex;
                      var dayData = actividadDiaria[spotIndex];
                      _showLineDetailsModal(
                        dayData['fecha'], 
                        (dayData['ingresos'] as num).toDouble(), 
                        (dayData['egresos'] as num).toDouble()
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFriendlyName(String key) {
    Map<String, String> names = {
      "PAYPAL_P2P": "Fondeo PayPal",
      "SEND": "Transferencias",
      "RECEIVE": "Recibido",
      "GROUP_ACTION": "Grupos DAO",
      "STAKE": "Staking DeFi",
      "STAKE_REWARD": "Recompensas",
      "CASHBACK_REWARD": "Cashback",
    };
    return names[key] ?? key;
  }

  // --- INDICADOR SUPERIOR DE HISTORIAS ---
  Widget _buildStoryIndicators() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage >= index ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_analyticsData == null) {
      return const Scaffold(body: Center(child: Text("Error al cargar analíticas")));
    }

    double totalIngresos = double.tryParse(_analyticsData!['totalIngresos'].toString()) ?? 0.0;
    double totalEgresos = double.tryParse(_analyticsData!['totalEgresos'].toString()) ?? 0.0;
    double totalMovido = totalIngresos + totalEgresos;
    double totalCashback = double.tryParse(_analyticsData!['totalCashback'].toString()) ?? 0.0;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              if (index == 2) {
                _confettiController.play(); // Dispara el confeti en la pantalla 3
              }
            },
            children: [
              _buildStory1_Resumen(totalMovido),
              _buildStory2_Graficos(_analyticsData!),
              _buildStory3_Recompensas(totalCashback),
            ],
          ),
          _buildStoryIndicators(),
          
          // Botón de cierre superior derecho
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}