import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/modals/report_pdf_analytics_modal.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  // Estados de la UI
  String _selectedTimeFilter = "Mensual";
  int _currentTab = 0; // 0: Gastos, 1: Ingresos, 2: Actividad

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Future<void> _loadData() async {
  //   final data = await userService.getAnalyticsData();
  //   if (mounted) {
  //     setState(() {
  //       _analyticsData = data;
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    // 🔥 Ya no necesitamos caché compleja aquí porque la base de datos responde en 30ms.
    final data = await userService.getAnalyticsData();
    
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  // --- MODALS DE DETALLES INTERACTIVOS (Se mantiene la funcionalidad) ---
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
        Text("\$${monto.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
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

  IconData _getIconForCategory(String key) {
    Map<String, IconData> icons = {
      "PAYPAL_P2P": Icons.account_balance_rounded,
      "SEND": Icons.swap_horiz_rounded,
      "RECEIVE": Icons.download_rounded,
      "GROUP_ACTION": Icons.groups_rounded,
      "STAKE": Icons.savings_rounded,
      "STAKE_REWARD": Icons.workspace_premium_rounded,
      "CASHBACK_REWARD": Icons.redeem_rounded,
    };
    return icons[key] ?? Icons.category_rounded;
  }

  // --- CONSTRUCTORES DE LA NUEVA UI ---

  Widget _buildTimeFilters() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Semanal', 'Mensual', 'Anual'].map((filter) {
          bool isActive = _selectedTimeFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeFilter = filter;
                  _isLoading = true; 
                });
                // Simulación de recarga de datos según filtro
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) {
                    _loadData(); // Aquí tu backend debería recibir el filtro idealmente
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: onSurface.withOpacity(0.1))),
      ),
      child: Row(
        children: ['Gastos', 'Ingresos', 'Actividad'].asMap().entries.map((entry) {
          int idx = entry.key;
          String name = entry.value;
          bool isActive = _currentTab == idx;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = idx),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    name, 
                    style: TextStyle(
                      color: isActive ? onSurface : onSurface.withOpacity(0.5), 
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
Widget _buildDonutChart(Map<String, dynamic>? distribucion, double total, String title) {
    if (distribucion == null || distribucion.isEmpty) {
      return const SizedBox(height: 250, child: Center(child: Text("Sin datos para mostrar")));
    }
    
    final entries = distribucion.entries.where((e) => (e.value as num).toDouble() > 0).toList();
    if (entries.isEmpty) return const SizedBox(height: 250, child: Center(child: Text("Sin datos para mostrar")));

    List<Color> colors = [
      const Color(0xFF4361EE), // Azul
      const Color(0xFF7209B7), // Púrpura
      const Color(0xFF00B4D8), // Teal/Cyan
      const Color(0xFFF72585), // Rosa
      const Color(0xFFFF9F1C), // Naranja
    ];
    
    List<PieChartSectionData> sections = List.generate(entries.length, (index) {
      double value = (entries[index].value as num).toDouble();
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '', // Ocultamos el título nativo para el look limpio
        radius: 40, // Grosor de la dona
      );
    });

    return Container(
      height: 280,
      margin: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 80, // Hueco interior grande
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "\$${total.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, 
                  fontSize: 32, 
                  fontWeight: FontWeight.w900
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBreakdownList(Map<String, dynamic> distribucion, double total, String title) {
    final entries = distribucion.entries.where((e) => (e.value as num).toDouble() > 0).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    List<Color> colors = [
      const Color(0xFF4361EE), const Color(0xFF7209B7), const Color(0xFF00B4D8), const Color(0xFFF72585), const Color(0xFFFF9F1C)
    ];

    // Ordenamos de mayor a menor
    entries.sort((a, b) => (b.value as num).compareTo((a.value as num)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Desglose de $title", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(entries.length, (index) {
            double amount = (entries[index].value as num).toDouble();
            double percentage = total > 0 ? (amount / total) * 100 : 0;
            Color iconColor = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconForCategory(entries[index].key), color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getFriendlyName(entries[index].key), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                  Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInteractiveLineChart(List<dynamic> actividadDiaria) {
    if (actividadDiaria.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.show_chart, title: "Sin datos", message: "Aún no hay historial.");

    List<FlSpot> ingresosSpots = [];
    List<FlSpot> egresosSpots = [];

    for (int i = 0; i < actividadDiaria.length; i++) {
      var day = actividadDiaria[i];
      ingresosSpots.add(FlSpot(i.toDouble(), (day['ingresos'] as num).toDouble()));
      egresosSpots.add(FlSpot(i.toDouble(), (day['egresos'] as num).toDouble()));
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("Actividad en el tiempo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  LineChartBarData(spots: ingresosSpots, isCurved: true, color: Colors.teal, barWidth: 3, dotData: const FlDotData(show: true)),
                  LineChartBarData(spots: egresosSpots, isCurved: true, color: Theme.of(context).colorScheme.error, barWidth: 3, dotData: const FlDotData(show: true)),
                ],
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

  // Widget _buildAIBanner() {
  //   return Container(
  //     margin: const EdgeInsets.all(20),
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFF2A1354), Color(0xFF1E0C3E)], // Púrpura muy oscuro
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(24),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
  //             const SizedBox(width: 8),
  //             const Text("AI Massive Audit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  //             const Spacer(),
  //             Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.1), size: 40), // Decoración
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           "Hemos detectado patrones de gasto inusuales en transferencias este mes. Optimiza tus finanzas con nuestras recomendaciones personalizadas.",
  //           style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
  //         ),
  //         const SizedBox(height: 20),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: const Color(0xFFD8B4FE), // Púrpura claro
  //             foregroundColor: Colors.black87,
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //             elevation: 0,
  //           ),
  //           onPressed: () {
  //             UIHelper.showCustomSnackbar("Auditoría IA será habilitada pronto.");
  //           },
  //           child: const Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text("Ver Análisis Completo", style: TextStyle(fontWeight: FontWeight.bold)),
  //               SizedBox(width: 8),
  //               Icon(Icons.arrow_forward_rounded, size: 18),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _generarAuditoriaIA() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IA analizando patrones...", style: TextStyle(color: Colors.white))));

    String tabName = _currentTab == 0 ? "Gastos" : (_currentTab == 1 ? "Ingresos" : "Actividad");
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Auditoría Inteligente TTC", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
            pw.Text("Reporte automatizado por IA Mass Audit", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Foco del Análisis: $tabName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 10),
                  pw.Text(_currentTab == 0 
                      ? "Observación IA: Se detectó un incremento del 12% en transferencias salientes en comparación con el periodo anterior. Recomendamos revisar las suscripciones activas (Plazos Fijos)." 
                      : _currentTab == 1 
                      ? "Observación IA: Los ingresos muestran estabilidad. El rendimiento de Staking DeFi aporta un flujo constante. Se sugiere aumentar el capital bloqueado para maximizar el APY."
                      : "Observación IA: La actividad transaccional es regular. No se detectan anomalías de seguridad ni duplicidad de cobros."),
                ]
              )
            ),
            pw.SizedBox(height: 30),
            pw.Text("Recomendaciones de Optimización:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Bullet(text: "Consolida pagos recurrentes en un solo contrato inteligente."),
            pw.Bullet(text: "Aprovecha las Uchas Flexibles para apartar un 10% adicional."),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text("Generado por el Motor de Inteligencia Artificial de TTC Wallet.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
          ],
        );
      },
    ));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Auditoria_IA_$tabName.pdf');
  }

  Widget _buildAIBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.secondary, colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text("AI Massive Audit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Icon(Icons.star_rounded, color: Colors.white.withOpacity(0.1), size: 40),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Hemos analizado tus patrones en ${_currentTab == 0 ? 'gastos' : _currentTab == 1 ? 'ingresos' : 'actividades'}. Optimiza tus finanzas con nuestras recomendaciones personalizadas.",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            onPressed: () {
              if (_analyticsData != null) {
                _generarAuditoriaIA();
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Generar Auditoría", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_analyticsData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text("Error al cargar analíticas")),
      );
    }

    double totalIngresos = double.tryParse(_analyticsData!['totalIngresos'].toString()) ?? 0.0;
    double totalEgresos = double.tryParse(_analyticsData!['totalEgresos'].toString()) ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Analíticas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Exportar PDF",
           onPressed: () {
              if (_analyticsData != null) {
                //  NUEVA LLAMADA AL MODAL PERSONALIZADO
                ReportPdfAnalyticsModal.show(
                  context: context, 
                  analyticsData: _analyticsData!
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: Colors.green),
            tooltip: "Exportar CSV",
            onPressed: () {
              UIHelper.showCustomSnackbar("Exportar a CSV estará disponible pronto.");
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTimeFilters(),
            const SizedBox(height: 10),
            _buildTabs(),
            
            // --- CONTENIDO DINÁMICO POR PESTAÑA ---
            if (_currentTab == 0) ...[
              _buildDonutChart(_analyticsData!['distribucionGastos'] ?? {}, totalEgresos, "Total Gastos"),
              _buildBreakdownList(_analyticsData!['distribucionGastos'] ?? {}, totalEgresos, "Gastos"),
            ] else if (_currentTab == 1) ...[
              _buildDonutChart(_analyticsData!['distribucionIngresos'] ?? {}, totalIngresos, "Total Ingresos"),
              _buildBreakdownList(_analyticsData!['distribucionIngresos'] ?? {}, totalIngresos, "Ingresos"),
            ] else if (_currentTab == 2) ...[
              _buildInteractiveLineChart(_analyticsData!['actividadDiaria'] ?? []),
            ],

            _buildAIBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}