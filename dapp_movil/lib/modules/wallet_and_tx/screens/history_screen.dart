import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../modals/transaction_details_modal.dart';
import '../../../main.dart';
import '../../../core/services/smart_avatar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/helpers/share_helper.dart';

class HistoryScreen extends StatefulWidget {
 // final BlockchainService service;

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);


  List<dynamic> _allTransactions = [];
  Map<String, List<dynamic>> _groupedTransactions = {};
  bool _isLoading = true;
  String _selectedFilter = 'Todos';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

 Future<void> _loadHistory() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    // 1. Consulta única y directa al servidor
    final txs = await txService.getTransactionHistory();

    if (mounted) {
      setState(() {
        _allTransactions = txs.toList();
        _applyFilter();
        _isLoading = false; 
      });
    }
  }
  // 🔥 MÉTODOS DEL CALENDARIO DE RANGOS M3
  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023), // Cambia al año en que se creó tu app/moneda
      lastDate: DateTime.now(),
        locale: const Locale('es', 'ES'),

      // 🔥 2. TRADUCIR LOS BOTONES Y TEXTOS
      helpText: 'Seleccionar Rango',
      cancelText: 'CANCELAR',
      confirmText: 'GUARDAR',
      saveText: 'GUARDAR',
      fieldStartHintText: 'dd/mm/aaaa',
      fieldEndHintText: 'dd/mm/aaaa',
      fieldStartLabelText: 'Inicio',
      fieldEndLabelText: 'Fin',

      initialDateRange: _fechaInicio != null && _fechaFin != null 
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!) : null,
      builder: (context, child) {
        return Theme(
          // Hereda tu tema claro/oscuro automáticamente
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
        _applyFilter(); // Refresca la lista
      });
    }
  }

  void _limpiarFiltroFechas() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _applyFilter(); // Refresca la lista
    });
  }

  void _applyFilter() {
    final myAddress = authCore.publicAddress.toLowerCase().trim();

    List<dynamic> filtered = _allTransactions.where((tx) {

      if (_fechaInicio != null && _fechaFin != null && tx['timestamp'] != null) {
        try {
          DateTime txDate = DateTime.parse(tx['timestamp'].toString());
          // Ignoramos la hora para comparar solo el día
          DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
          DateTime start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
          DateTime end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);

          if (justDate.isBefore(start) || justDate.isAfter(end)) {
            return false; // Descartamos la transacción si no está en el rango
          }
        } catch (e) {
          return false;
        }
      }

      final type = (tx['txType'] ?? '').toString().toUpperCase().trim();
      final sender = (tx['senderAddress'] ?? '').toString().toLowerCase().trim();
      final receiver = (tx['receiverAddress'] ?? '').toString().toLowerCase().trim();
      final iAmReceiver = (receiver == myAddress);

      if (_selectedFilter == 'Todos') return true;
      if (_selectedFilter == 'Recibidos') {
        return (type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY' || type == 'RECOVERY'|| type == 'SCHEDULED_PAYMENT') && iAmReceiver;
      }
      if (_selectedFilter == 'Enviados') {
        return (type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY' || type == 'SCHEDULED_PAYMENT') && !iAmReceiver;
      }
      if (_selectedFilter == 'Compras') {
        return type == 'BUY' || type == 'BUY_FIAT';
      }
      if (_selectedFilter == 'Staking') {
        return type == 'STAKE' || type == 'UNSTAKE';
      }
      if (_selectedFilter == 'Cashback') {
        return type == 'CASHBACK_REWARD';
      }
      if (_selectedFilter == 'Fallidas') {
        final status = (tx['status'] ?? 'UNKNOWN').toString().toUpperCase();
        return status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
      }
      return false;
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
Future<void> _generarYCompartirPDF(List<dynamic> transacciones, String miBilletera) async {
    // Mostramos un mensaje de que empezó el proceso
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Estado de Cuenta...", style: TextStyle(color: Colors.white))));

    final pdf = pw.Document();

    // Diseño del documento
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- ENCABEZADO ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text("Estado de Cuenta Oficial", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text("Fecha: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // --- DATOS DEL CLIENTE ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Billetera del Titular:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(miBilletera, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text("Total de Movimientos Registrados: ${transacciones.length}"),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // --- TABLA DE TRANSACCIONES ---
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                // Cabeceras de la tabla
                <String>['Fecha', 'Tipo', 'Monto', 'Estado', 'Hash/ID'],
                
                // Mapeo dinámico de tus transacciones
                ...transacciones.map((tx) {
                  // Formatear fecha
                  String fecha = tx['timestamp']?.toString().substring(0, 10) ?? 'N/A';
                  
                  // Identificar si es ingreso o egreso para poner el signo
                  bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == miBilletera.toLowerCase();
                  String signo = esIngreso ? "+" : "-";
                  String monto = "$signo${tx['amount']} TTC";

                  // Extraer el tipo y estado
                  String tipo = tx['txType'] ?? 'Desconocido';
                  String estado = tx['status'] ?? 'Pendiente';
                  
                  // Acortar el Hash para que quepa en la tabla
                  String hashCompleto = tx['txHash'] ?? 'N/A';
                  String hashCorto = hashCompleto.length > 10 ? "${hashCompleto.substring(0, 6)}...${hashCompleto.substring(hashCompleto.length - 4)}" : hashCompleto;

                  return [fecha, tipo, monto, estado, hashCorto];
                }),
              ],
            ),
            
            pw.SizedBox(height: 40),
            
            // --- PIE DE PÁGINA ---
            pw.Divider(),
            pw.Text(
              "Este documento es un registro digital generado automáticamente por la Blockchain. Las transacciones marcadas como COMPLETED son inmutables.",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    // Guardar y disparar el menú nativo de compartir (WhatsApp, Correo, Guardar en Archivos)
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Estado_Cuenta_TTC.pdf');
  }


  @override
  Widget build(BuildContext context) {
   final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
    final filters = ['Todos', 'Recibidos', 'Enviados', 'Compras', 'Staking', 'Cashback', 'Fallidas'];


return DefaultTabController( 
  length: 2,
child:Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Historial de Actividad", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.deepOrangeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.deepOrangeAccent, size: 20),
              tooltip: "Descargar Estado de Cuenta",
              onPressed: () {
                if (_allTransactions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay transacciones para generar un reporte.")));
                  return;
                }
               ShareHelper.generarYCompartirPDFHistory(context, _allTransactions, authCore.publicAddress);
              },
            ),
          ),
          if (_allTransactions.isNotEmpty && !_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: const Color(0xFFB5C0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Color(0xFFB5C0FF), size: 20),
                tooltip: "Descargar Excel (CSV)",
                onPressed: () {
                  ShareHelper.exportarHistorialCSV(
                    context, 
                    _allTransactions, 
                    authCore.publicAddress 
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _seleccionarRangoFechas,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _fechaInicio != null ? const Color(0xFFB5C0FF) : colorScheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: _fechaInicio != null ? Colors.black87 : colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                
                if (_fechaInicio != null)
                  GestureDetector(
                    onTap: _limpiarFiltroFechas,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
                    ),
                  ),

                ...filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilter();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFB5C0FF) : colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ]
            ),
          ),
          Expanded(
            child: _isLoading
                //? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                ? UIHelper.buildSkeletonList(context)
                : _groupedTransactions.isEmpty
                 ? UIHelper.emptyState( // 🔥 2. Estado Vacío Premium
              context: context,
              icon: Icons.receipt_long_rounded,
              title: "Historial Vacío",
              message: "Aún no has realizado ninguna transacción de este tipo. Cuando envíes o recibas TTC, aparecerán aquí.",
              actionLabel: "Recibir mis primeros TTC",
              onAction: () {
                // Aquí abres el modal de recibir
              }
            )
          : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groupedTransactions.keys.length,
                        itemBuilder: (context, index) {
                          String date = _groupedTransactions.keys.elementAt(index);
                          List<dynamic> txs = _groupedTransactions[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                child: Text(date.toUpperCase(), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                              ),
                              ...txs.map((tx) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildTransactionCard(tx, colorScheme.onSurface, context),
                              )).toList(),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    ),
);
  }

  Widget _buildTransactionCard(dynamic tx, Color onSurfaceColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String type = (tx['txType'] ?? 'Unknown').toString().toUpperCase().trim();
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
    final bool esFantasma = tx['recovered'] == true || tx['isGhost'] == true;

    final String receiver = (tx['receiverAddress'] ?? '').toString();
    final String myAddress = authCore.publicAddress;
    final bool iAmReceiver = receiver.toLowerCase() == myAddress.toLowerCase();

    String title = 'Desconocido';
    IconData icon = Icons.help_outline_rounded;
    Color iconColor = const Color(0xFFB5C0FF);
    Color iconBgColor = onSurfaceColor.withOpacity(0.1);
    String prefix = "";
    Color amountColor = const Color(0xFFB5C0FF);

    if (type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY'|| type == 'SCHEDULED_PAYMENT') {
      if (iAmReceiver) {
        title = type == 'BINANCE_PAY' ? "Recibido Instantáneo" : (type == 'SCHEDULED_PAYMENT' ? "Cobro Programado" : "Recibido");
        icon = Icons.call_received_rounded;
        iconColor = const Color(0xFFB5C0FF);
        iconBgColor = const Color(0xFF5A49D3).withOpacity(0.3);
        amountColor = const Color(0xFFB5C0FF);
        prefix = "+";
      } else {
        title = type == 'BINANCE_PAY' ? "Envío Instantáneo" : (type == 'SCHEDULED_PAYMENT' ? "Pago Programado" : "Enviado");
        icon = Icons.arrow_outward_rounded;
        iconColor = const Color(0xFFB5C0FF);
        iconBgColor = const Color(0xFF5A49D3).withOpacity(0.3);
        amountColor = Colors.white;
        prefix = "-";
      }
    } else if (type == 'BUY' || type == 'BUY_FIAT') {
      title = "Compra";
      icon = Icons.add_shopping_cart_rounded;
      iconColor = const Color(0xFFB5C0FF);
      iconBgColor = const Color(0xFF5A49D3).withOpacity(0.3);
      amountColor = const Color(0xFFB5C0FF);
      prefix = "+";
    } else if (type == 'CASHBACK_REWARD') {
      title = "Cashback";
      icon = Icons.stars_rounded;
      iconColor = Colors.orangeAccent;
      iconBgColor = Colors.orangeAccent.withOpacity(0.2);
      amountColor = Colors.orangeAccent;
      prefix = "+";
    } else if (type == 'STAKE') {
      title = "Stake";
      icon = Icons.lock_outline_rounded;
      iconColor = Colors.orangeAccent;
      iconBgColor = Colors.orangeAccent.withOpacity(0.2);
      amountColor = Colors.white;
      prefix = "-";
    } else if (type == 'UNSTAKE' || type == 'WITHDRAW') {
      title = type == 'UNSTAKE' ? "Recompensa" : "Liquidación";
      icon = Icons.lock_open_rounded;
      iconColor = const Color(0xFFB5C0FF);
      iconBgColor = const Color(0xFF5A49D3).withOpacity(0.3);
      amountColor = const Color(0xFFB5C0FF);
      prefix = "+";
    } else {
      title = "Desconocido";
      icon = Icons.help_outline_rounded;
      iconColor = onSurfaceColor.withOpacity(0.7);
      iconBgColor = onSurfaceColor.withOpacity(0.1);
      amountColor = const Color(0xFFB5C0FF);
    }

    if (isFailed) {
      iconColor = colorScheme.error;
      iconBgColor = colorScheme.error.withOpacity(0.15);
      amountColor = colorScheme.error;
      prefix = "x";
    }

    String timeStr = "";
    if (tx['timestamp'] != null) {
      try {
        DateTime date = DateTime.parse(tx['timestamp'].toString());
        timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        timeStr = "--:--";
      }
    }

    Widget leadingWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isFailed ? Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () {
          TransactionDetailsModal.show(context: context, tx: tx);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (esFantasma) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.healing_rounded, color: Colors.orange, size: 14),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• ${isFailed ? 'Fallida' : 'Completada'} • $timeStr", 
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: ValueListenableBuilder<bool>(
                  valueListenable: discreetModeNotifier,
                  builder: (context, isDiscreet, _) {
                    if (esFantasma && amount == 0.0) {
                      return Text("---", style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 16));
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          isDiscreet ? "**** TTC" : "$prefix ${amount.toStringAsFixed(2)} TTC",
                          key: ValueKey<bool>(isDiscreet),
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
                            decoration: isFailed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}