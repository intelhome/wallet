import 'package:flutter/material.dart';
import '../../../core/helpers/share_helper.dart';
import '../../../core/helpers/ui_helper.dart';

class ReportPdfHistoryModal {
  static void show({
    required BuildContext context,
    required List<dynamic> allTransactions,
    required String myAddress,
  }) {
    String? pdfType;
    String? pdfStatus;
    DateTime? pdfDate;

    // Categorías de movimiento
    final List<String> tipos = ['Recibidos', 'Enviados', 'Compras', 'Staking', 'Cashback'];

    // Mapa de estados
    final Map<String, Map<String, dynamic>> estados = {
      "COMPLETED": {"label": "Completadas", "color": Colors.green},
      "PENDING": {"label": "Pendientes", "color": Colors.orangeAccent},
      "FAILED": {"label": "Fallidas/Rechazadas", "color": Colors.redAccent},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final onSurface = colorScheme.onSurface;

            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.deepOrangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.deepOrangeAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text("Reporte de Transacciones", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Configura los filtros para tu estado de cuenta en formato PDF.", style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6))),
                    const SizedBox(height: 24),
                    Divider(color: onSurface.withOpacity(0.05), height: 1),
                    const SizedBox(height: 24),

                    // 📊 TIPO DE TRANSACCIÓN
                    Text("Tipo de Movimiento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          hint: Text("Todos los movimientos", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6))),
                          value: pdfType,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                          items: tipos.map((t) {
                            return DropdownMenuItem<String>(value: t, child: Text(t, style: TextStyle(color: onSurface)));
                          }).toList(),
                          onChanged: (val) => setModalState(() => pdfType = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🚦 ESTADO (CHIPS)
                    Text("Estado de la Operación", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: estados.entries.map((entry) {
                        bool isSelected = pdfStatus == entry.key;
                        Color chipColor = entry.value['color'];
                        return GestureDetector(
                          onTap: () => setModalState(() => pdfStatus = isSelected ? null : entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? chipColor.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? chipColor : onSurface.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(entry.value['label'], style: TextStyle(color: isSelected ? chipColor : onSurface, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 📅 FECHA
                    Text("Fecha Específica (Opcional)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pdfDate == null ? "Historial completo" : "Fecha: ${pdfDate!.day}/${pdfDate!.month}/${pdfDate!.year}",
                              style: TextStyle(fontSize: 14, color: pdfDate == null ? onSurface.withOpacity(0.6) : onSurface),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: onSurface.withOpacity(0.05), foregroundColor: onSurface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            label: Text(pdfDate == null ? "Elegir" : "Cambiar", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setModalState(() => pdfDate = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📄 BOTÓN MAESTRO
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text("Exportar Historial", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          final pdfFilteredList = allTransactions.where((tx) {
                            // Filtro Estado
                            final status = (tx['status'] ?? 'UNKNOWN').toString().toUpperCase();
                            if (pdfStatus != null) {
                              if (pdfStatus == 'FAILED' && status != 'FAILED' && status != 'REVERTED' && status != 'REJECTED') return false;
                              if (pdfStatus != 'FAILED' && status != pdfStatus) return false;
                            }
                            
                            // Filtro Tipo
                            if (pdfType != null) {
                              final type = (tx['txType'] ?? '').toString().toUpperCase().trim();
                              final receiver = (tx['receiverAddress'] ?? '').toString().toLowerCase().trim();
                              final iAmReceiver = (receiver == myAddress.toLowerCase());

                              if (pdfType == 'Recibidos' && !((type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY' || type == 'RECOVERY' || type == 'SCHEDULED_PAYMENT') && iAmReceiver)) return false;
                              if (pdfType == 'Enviados' && !((type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY' || type == 'SCHEDULED_PAYMENT') && !iAmReceiver)) return false;
                              if (pdfType == 'Compras' && !(type == 'BUY' || type == 'BUY_FIAT')) return false;
                              if (pdfType == 'Staking' && !(type == 'STAKE' || type == 'UNSTAKE')) return false;
                              if (pdfType == 'Cashback' && type != 'CASHBACK_REWARD') return false;
                            }

                            // Filtro Fecha
                            if (pdfDate != null && tx['timestamp'] != null) {
                              DateTime? txDate = DateTime.tryParse(tx['timestamp'].toString());
                              if (txDate == null || txDate.year != pdfDate!.year || txDate.month != pdfDate!.month || txDate.day != pdfDate!.day) return false;
                            }
                            return true;
                          }).toList();

                          if (pdfFilteredList.isEmpty) {
                            UIHelper.showCustomSnackbar("No hay transacciones con estos filtros.", isError: true);
                            return;
                          }

                          Navigator.pop(ctx);
                          ShareHelper.generarYCompartirPDFHistory(context, pdfFilteredList, myAddress);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}