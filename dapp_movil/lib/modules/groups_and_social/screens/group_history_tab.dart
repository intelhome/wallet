import 'package:flutter/material.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/transaction_group_details_modal.dart';

class GroupHistoryTab extends StatelessWidget {
  final Future<List<dynamic>>? historialFuture;
  final Map<String, dynamic> group;
  final String filtroHistorial;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final VoidCallback onSeleccionarRango;
  final VoidCallback onLimpiarRango;
  final ValueChanged<String> onFiltroChanged;

  const GroupHistoryTab({
    super.key,
    required this.historialFuture,
    required this.group,
    required this.filtroHistorial,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onSeleccionarRango,
    required this.onLimpiarRango,
    required this.onFiltroChanged,
  });

  Map<String, List<dynamic>> _groupTransactionsByDate(List<dynamic> transactions) {
    Map<String, List<dynamic>> grouped = {};
    for (var tx in transactions) {
      String dateStr = "Fecha desconocida";
      if (tx['timestamp'] != null) {
        try {
          DateTime date = DateTime.parse(tx['timestamp'].toString());
          dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        } catch (e) {
          dateStr = "Fecha desconocida";
        }
      }
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  Widget _buildGroupTransactionCard(dynamic tx, Color onSurfaceColor, BuildContext context, String vaultAddress) {
    final colorScheme = Theme.of(context).colorScheme;
    
    bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';

    String title = esIngreso ? "Aporte Recibido" : "Pago Enviado";
    IconData icon = esIngreso ? Icons.call_received_rounded : Icons.arrow_outward_rounded;
    Color iconColor = colorScheme.primary;
    Color iconBgColor = colorScheme.primary.withOpacity(0.2);
    Color amountColor = esIngreso ? colorScheme.primary : onSurfaceColor;
    String prefix = esIngreso ? "+" : "-";

    if (isFailed) {
      iconColor = colorScheme.error;
      iconBgColor = colorScheme.error.withOpacity(0.15);
      amountColor = colorScheme.error;
      prefix = "x";
    }

    String timeStr = "--:--";
    if (tx['timestamp'] != null) {
      try {
        DateTime d = DateTime.parse(tx['timestamp'].toString());
        timeStr = "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isFailed ? Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () => TransactionGroupDetailsModal.show(context: context, tx: tx, vaultAddress: vaultAddress),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("• ${isFailed ? 'Fallida' : 'Completada'} • $timeStr", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(
                "$prefix ${amount.toStringAsFixed(2)} TTC",
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5, decoration: isFailed ? TextDecoration.lineThrough : null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return FutureBuilder<List<dynamic>>(
      future: historialFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("La bóveda no tiene movimientos.", style: TextStyle(color: onSurface.withOpacity(0.5))));
        
        String vaultAddress = group['walletAddress']?.toString().toLowerCase() ?? "";
        
        List<dynamic> historialFiltrado = snapshot.data!.where((tx) {
          if (fechaInicio != null && fechaFin != null && tx['timestamp'] != null) {
            try {
              DateTime txDate = DateTime.parse(tx['timestamp'].toString());
              DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
              DateTime start = DateTime(fechaInicio!.year, fechaInicio!.month, fechaInicio!.day);
              DateTime end = DateTime(fechaFin!.year, fechaFin!.month, fechaFin!.day);
              if (justDate.isBefore(start) || justDate.isAfter(end)) return false;
            } catch (e) { return false; }
          }
          String tipo = (tx['txType'] ?? '').toString().toUpperCase();
          bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
          if (filtroHistorial == 'Todos') return true;
          if (filtroHistorial == 'Aportes') return esIngreso;
          if (filtroHistorial == 'Pagos de ayudas') return tipo == 'SHARED_DEBT_PAYMENT';
          if (filtroHistorial == 'Pagos') return !esIngreso && tipo != 'SHARED_DEBT_PAYMENT';
          return true;
        }).toList();
        
        Map<String, List<dynamic>> historialAgrupado = _groupTransactionsByDate(historialFiltrado);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Movimientos (${snapshot.data!.length})", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.7))),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          tooltip: "Exportar PDF",
                          icon: Icon(Icons.picture_as_pdf_rounded, color: colorScheme.error, size: 20),
                          onPressed: () => ShareHelper.generarYCompartirPDFHistory(context, snapshot.data!, vaultAddress),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          tooltip: "Exportar Excel",
                          icon: Icon(Icons.download_rounded, color: colorScheme.primary, size: 20),
                          onPressed: () => ShareHelper.exportarHistorialCSV(context, snapshot.data!, vaultAddress),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onSeleccionarRango,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: fechaInicio != null ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_today_rounded, size: 20, color: fechaInicio != null ? colorScheme.onPrimary : onSurface.withOpacity(0.8)),
                    ),
                  ),
                  if (fechaInicio != null)
                    GestureDetector(
                      onTap: onLimpiarRango,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
                      ),
                    ),
                  ...['Todos', 'Aportes', 'Pagos', 'Pagos de ayudas'].map((opcion) {
                    bool isSelected = filtroHistorial == opcion;
                    return GestureDetector(
                      onTap: () => onFiltroChanged(opcion),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          opcion,
                          style: TextStyle(color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.8), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            Expanded(
              child: historialAgrupado.isEmpty
                  ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UIHelper.emptyState(context: context, icon: Icons.history_rounded, title: "Historial Vacío", message: "La bóveda no registra transacciones bajo este filtro.")))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historialAgrupado.keys.length,
                      itemBuilder: (context, index) {
                        String date = historialAgrupado.keys.elementAt(index);
                        List<dynamic> txs = historialAgrupado[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), 
                              child: Text(date.toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))
                            ),
                            ...txs.map((tx) => _buildGroupTransactionCard(tx, onSurface, context, vaultAddress)).toList(),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}