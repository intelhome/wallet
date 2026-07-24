import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/share_helper.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../burner_wallets/services/burner_service.dart';
import '../../wallet_and_tx/modals/transaction_details_modal.dart';

class AdminBurnerHistoryScreen extends StatefulWidget {
  const AdminBurnerHistoryScreen({super.key});

  @override
  State<AdminBurnerHistoryScreen> createState() => _AdminBurnerHistoryScreenState();
}

class _AdminBurnerHistoryScreenState extends State<AdminBurnerHistoryScreen> {
  BurnerService get burnerService => Provider.of<BurnerService>(context, listen: false);
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  List<dynamic> _allTransactions = [];
  Map<String, List<dynamic>> _groupedTransactions = {};
  bool _isLoading = true;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final txs = await burnerService.getBurnerTransactionsHistory();
    if (mounted) {
      setState(() {
        _allTransactions = txs.toList();
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023), 
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      helpText: 'Seleccionar Rango', cancelText: 'CANCELAR', confirmText: 'GUARDAR',
      initialDateRange: _fechaInicio != null && _fechaFin != null ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!) : null,
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );

    if (rango != null) {
      setState(() { _fechaInicio = rango.start; _fechaFin = rango.end; _applyFilter(); });
    }
  }

  void _limpiarFiltroFechas() {
    setState(() { _fechaInicio = null; _fechaFin = null; _applyFilter(); });
  }

  void _applyFilter() {
    List<dynamic> filtered = _allTransactions.where((tx) {
      if (_fechaInicio != null && _fechaFin != null && tx['timestamp'] != null) {
        try {
          DateTime txDate = DateTime.parse(tx['timestamp'].toString());
          DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
          DateTime start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
          DateTime end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
          if (justDate.isBefore(start) || justDate.isAfter(end)) return false; 
        } catch (e) { return false; }
      }
      return true;
    }).toList();
    _groupedTransactions = _groupTransactionsByDate(filtered);
  }

  Map<String, List<dynamic>> _groupTransactionsByDate(List<dynamic> transactions) {
    Map<String, List<dynamic>> grouped = {};
    for (var tx in transactions) {
      String dateStr = "Fecha desconocida";
      if (tx['timestamp'] != null) {
        try {
          DateTime date = DateTime.parse(tx['timestamp'].toString());
          dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        } catch (e) { }
      }
      if (!grouped.containsKey(dateStr)) grouped[dateStr] = [];
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // Calcular gasto mensual total para la tarjeta superior
    double totalMensual = 0.0;
    for (var tx in _allTransactions) {
      if (tx['amount'] != null) {
        totalMensual += (tx['amount'] as num).toDouble();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Historial\nCorporativo", style: TextStyle(color: onSurface, fontWeight: FontWeight.w900, fontSize: 24, height: 1.1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: onSurface.withOpacity(0.7)),
            onPressed: _seleccionarRangoFechas,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: onSurface.withOpacity(0.7)),
            onPressed: () {
              if (_allTransactions.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay transacciones."))); return; }
              ShareHelper.generarYCompartirPDFHistory(context, _allTransactions, authCore.publicAddress);
            },
          ),
          IconButton(
            icon: Icon(Icons.download_outlined, color: onSurface.withOpacity(0.7)),
            onPressed: () {
              if (_allTransactions.isNotEmpty) {
                ShareHelper.exportarHistorialCSV(context, _allTransactions, authCore.publicAddress);
              }
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? UIHelper.buildSkeletonList(context)
          : Column(
              children: [
                if (_fechaInicio != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 16, color: colorScheme.error),
                            const SizedBox(width: 4),
                            Text("Limpiar filtro de fechas", style: TextStyle(color: colorScheme.error, fontSize: 12)),
                          ],
                        ),
                        backgroundColor: colorScheme.error.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        onPressed: _limpiarFiltroFechas,
                      ),
                    ),
                  ),

                // TARJETA DE GASTO MENSUAL (ESTILO MOCKUP)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: onSurface.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("GASTO MENSUAL", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(totalMensual.toStringAsFixed(2), style: const TextStyle(color: Colors.deepOrangeAccent, fontSize: 32, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          const Text("TTC", style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.deepOrangeAccent, size: 16),
                          const SizedBox(width: 6),
                          Text("+5.2% vs last month", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LISTA AGRUPADA
                Expanded(
                  child: _groupedTransactions.isEmpty
                    ? UIHelper.emptyState(
                        context: context, icon: Icons.business_center_rounded, title: "Historial Vacío",
                        message: "Los empleados aún no han realizado transacciones con las tarjetas corporativas."
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _groupedTransactions.keys.length,
                        itemBuilder: (context, index) {
                          String date = _groupedTransactions.keys.elementAt(index);
                          List<dynamic> txs = _groupedTransactions[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16), 
                                child: Text(date, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16))
                              ),
                              ...txs.map((tx) => _buildTransactionCard(tx, onSurface, context)).toList(),
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionCard(dynamic tx, Color onSurfaceColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
    
    // Identificar si es fondeo (ingreso a la tarjeta) o gasto
    final bool isFunding = tx['txType'] == 'BURNER_FUNDING';
    
    final String reason = tx['reason'] ?? (isFunding ? 'Fondo Operativo' : 'Pago de Tarea');

    String timeStr = "--:--";
    if (tx['timestamp'] != null) {
      try {
        DateTime date = DateTime.parse(tx['timestamp'].toString());
        timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {}
    }

    Color iconColor = isFailed ? colorScheme.error : (isFunding ? const Color(0xFFBAC3FF) : Colors.deepOrangeAccent);
    Color bgColor = isFailed ? colorScheme.error.withOpacity(0.1) : (isFunding ? const Color(0xFFBAC3FF).withOpacity(0.1) : Colors.deepOrangeAccent.withOpacity(0.1));
    IconData icon = isFunding ? Icons.download_rounded : Icons.local_fire_department_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurfaceColor.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => TransactionDetailsModal.show(context: context, tx: tx),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reason, style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(isFailed ? "Fallida" : (isFunding ? "Ingreso" : "Gasto Corporativo"), style: TextStyle(color: isFailed ? colorScheme.error : onSurfaceColor.withOpacity(0.6), fontSize: 12)),
                        Text("  •  $timeStr", style: TextStyle(color: onSurfaceColor.withOpacity(0.4), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFunding ? "+ ${amount.toStringAsFixed(2)} TTC" : "- ${amount.toStringAsFixed(2)} TTC", 
                    style: TextStyle(color: isFunding ? const Color(0xFFBAC3FF) : onSurfaceColor, fontWeight: FontWeight.bold, fontSize: 15, decoration: isFailed ? TextDecoration.lineThrough : null)
                  ),
                  if (!isFunding && !isFailed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: colorScheme.secondary, size: 10),
                          const SizedBox(width: 4),
                          Text("Audited", style: TextStyle(color: colorScheme.secondary, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: Text("Historial Corporativo", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       iconTheme: IconThemeData(color: colorScheme.onSurface),
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
  //           onPressed: () {
  //             if (_allTransactions.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay transacciones."))); return; }
  //             ShareHelper.generarYCompartirPDFHistory(context, _allTransactions, authCore.publicAddress);
  //           },
  //         ),
  //         if (_allTransactions.isNotEmpty && !_isLoading)
  //           Padding(
  //             padding: const EdgeInsets.only(right: 8.0),
  //             child: IconButton(
  //               icon: Icon(Icons.download_rounded, color: colorScheme.primary),
  //               style: IconButton.styleFrom(backgroundColor: colorScheme.primary.withOpacity(0.1)),
  //               onPressed: () => ShareHelper.exportarHistorialCSV(context, _allTransactions, authCore.publicAddress),
  //             ),
  //           ),
  //       ],
  //     ),
  //     body: Column(
  //       children: [
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //           child: Row(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.only(right: 8),
  //                 child: ActionChip(
  //                   label: Icon(_fechaInicio != null ? Icons.calendar_month_rounded : Icons.date_range_rounded, size: 20, color: _fechaInicio != null ? colorScheme.onPrimary : colorScheme.primary),
  //                   backgroundColor: _fechaInicio != null ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                   onPressed: _seleccionarRangoFechas,
  //                 ),
  //               ),
  //               if (_fechaInicio != null)
  //                 Padding(
  //                   padding: const EdgeInsets.only(right: 8),
  //                   child: ActionChip(
  //                     label: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
  //                     backgroundColor: colorScheme.error.withOpacity(0.1),
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                     onPressed: _limpiarFiltroFechas,
  //                   )
  //                 ),
  //             ]
  //           ),
  //         ),
  //         Expanded(
  //           child: _isLoading
  //               ? UIHelper.buildSkeletonList(context)
  //               : _groupedTransactions.isEmpty
  //                 ? UIHelper.emptyState(
  //                     context: context, icon: Icons.business_center_rounded, title: "Historial Vacío",
  //                     message: "Los empleados aún no han realizado transacciones con las tarjetas corporativas."
  //                   )
  //                 : ListView.builder(
  //                     padding: const EdgeInsets.all(16),
  //                     itemCount: _groupedTransactions.keys.length,
  //                     itemBuilder: (context, index) {
  //                       String date = _groupedTransactions.keys.elementAt(index);
  //                       List<dynamic> txs = _groupedTransactions[date]!;
  //                       return Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(date, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14))),
  //                           ...txs.map((tx) => _buildTransactionCard(tx, colorScheme.onSurface, context)).toList(),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTransactionCard(dynamic tx, Color onSurfaceColor, BuildContext context) {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
  //   final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
  //   final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
    
  //   final String reason = tx['reason'] ?? 'Pago de Tarea';

  //   String timeStr = "--:--";
  //   if (tx['timestamp'] != null) {
  //     try {
  //       DateTime date = DateTime.parse(tx['timestamp'].toString());
  //       timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  //     } catch (e) {}
  //   }

  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).cardColor,
  //       borderRadius: BorderRadius.circular(24),
  //       border: isFailed ? Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.5) : Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 1),
  //     ),
  //     child: InkWell(
  //       onTap: () => TransactionDetailsModal.show(context: context, tx: tx),
  //       borderRadius: BorderRadius.circular(24),
  //       child: ListTile(
  //         contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //         leading: CircleAvatar(backgroundColor: Colors.deepOrange.withOpacity(0.1), child: const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange)),
  //         title: Text(reason, style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
  //         subtitle: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const SizedBox(height: 4),
  //             Text(isFailed ? "Fallida" : "Gasto Corporativo", style: TextStyle(color: isFailed ? colorScheme.error : onSurfaceColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
  //             const SizedBox(height: 2),
  //             Text(timeStr, style: TextStyle(color: onSurfaceColor.withOpacity(0.4), fontSize: 11)),
  //           ],
  //         ),
  //         trailing: Text("- ${amount.toStringAsFixed(2)} TTC", style: TextStyle(color: isFailed ? colorScheme.error : onSurfaceColor, fontWeight: FontWeight.w900, fontSize: 16, decoration: isFailed ? TextDecoration.lineThrough : null)),
  //       ),
  //     ),
  //   );
  // }
}