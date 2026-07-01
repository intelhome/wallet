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
        
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: "Descargar Estado de Cuenta",
            onPressed: () {
              if (_allTransactions.isEmpty) { // 🔥 FIX: Cambiado a _allTransactions
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay transacciones para generar un reporte.")));
                return;
              }
              // 🔥 FIX: Pasamos _allTransactions a la función generadora
             // _generarYCompartirPDF(_allTransactions, widget.service.publicAddress); 
             ShareHelper.generarYCompartirPDFHistory(context, _allTransactions, authCore.publicAddress);
            },
          ),
          if (_allTransactions.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(Icons.download_rounded, color: colorScheme.primary),
                tooltip: "Descargar Excel (CSV)",
                style: IconButton.styleFrom(backgroundColor: colorScheme.primary.withOpacity(0.1)),
                onPressed: () {
                  ShareHelper.exportarHistorialCSV(
                    context, 
                    _allTransactions, 
                    authCore.publicAddress // Tu dirección para calcular si enviaste o recibiste
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    // avatar: Icon(
                    //   _fechaInicio != null ? Icons.calendar_month_rounded : Icons.date_range_rounded,
                    //   size: 18,
                    //   color: _fechaInicio != null ? colorScheme.onPrimary : colorScheme.primary,
                    // ),
                    // label: Text(
                    //   _fechaInicio != null 
                    //       ? "${_fechaInicio!.day}/${_fechaInicio!.month} - ${_fechaFin!.day}/${_fechaFin!.month}"
                    //       : "Fechas",
                    //   style: TextStyle(
                    //     color: _fechaInicio != null ? colorScheme.onPrimary : colorScheme.primary,
                    //     fontWeight: FontWeight.bold
                    //   )
                    // ),
                    label: Icon(
                      _fechaInicio != null ? Icons.calendar_month_rounded : Icons.date_range_rounded,
                      size: 20,
                      color: _fechaInicio != null ? colorScheme.onPrimary : colorScheme.primary,
                    ),
                    backgroundColor: _fechaInicio != null ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                    onPressed: _seleccionarRangoFechas,
                  ),
                ),
                
                // 🔥 BOTÓN DE ELIMINAR FECHA (Solo aparece si hay una seleccionada)
                if (_fechaInicio != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      // avatar: Icon(Icons.close_rounded, size: 16, color: colorScheme.error),
                      // label: Text("Quitar", style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      label: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      onPressed: _limpiarFiltroFechas,
                    )
                  ),

                ...filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(color: isSelected ? theme.cardColor: colorScheme.onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilter();
                        });
                      }
                    },
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
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(date, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              ...txs.map((tx) => _buildTransactionCard(tx, colorScheme.onSurface, context)).toList(),
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
    // 🔥 REGLA 1: Extraer ColorScheme
    final colorScheme = Theme.of(context).colorScheme;

    final String type = (tx['txType'] ?? 'Unknown').toString().toUpperCase().trim();
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
    final bool esFantasma = tx['recovered'] == true || tx['isGhost'] == true;

    final String sender = (tx['senderAddress'] ?? '').toString();
    final String receiver = (tx['receiverAddress'] ?? '').toString();
    final String myAddress = authCore.publicAddress;
    final bool iAmReceiver = receiver.toLowerCase() == myAddress.toLowerCase();

    String title = 'Desconocido';
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;
    String prefix = "";
    Color amountColor = onSurfaceColor;

    // 🔥 REGLA 3 Y 4: Mapeo de Colores Semánticos M3
    if (type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY'|| type == 'SCHEDULED_PAYMENT') {
      if (iAmReceiver) {
        title = type == 'BINANCE_PAY' ? "Recibido Instantáneo" : (type == 'SCHEDULED_PAYMENT' ? "Cobro Programado" : "Recibido");
        icon = type == 'BINANCE_PAY' ? Icons.flash_on_rounded : Icons.call_received_rounded;
        iconColor = type == 'BINANCE_PAY' ? colorScheme.secondary : Colors.green; // Secondary = Amber
        amountColor = Colors.green;
        prefix = "+";
      } else {
     title = type == 'BINANCE_PAY' ? "Envío Instantáneo" : (type == 'SCHEDULED_PAYMENT' ? "Pago Programado" : "Enviado");
        icon = type == 'BINANCE_PAY' ? Icons.flash_on_rounded : (type == 'SCHEDULED_PAYMENT' ? Icons.event_repeat_rounded : Icons.call_made_rounded);
        iconColor = type == 'BINANCE_PAY' ? colorScheme.secondary : colorScheme.primary; // Primary = Azul
        prefix = "-";
      }
    } else if (type == 'BUY' || type == 'BUY_FIAT') {
      title = "Compra";
      icon = Icons.add_shopping_cart_rounded;
      iconColor = Colors.green;
      amountColor = Colors.green;
      prefix = "+";
    } else if (type == 'CASHBACK_REWARD') {
      title = "Cashback";
      icon = Icons.stars_rounded;
      iconColor = colorScheme.secondary; // Secondary = Amber
      amountColor = colorScheme.secondary;
      prefix = "+";
    } else if (type == 'STAKE') {
      title = "Stake";
      icon = Icons.lock_outline_rounded;
      iconColor = Colors.orange; // Colores fijos suaves para estados específicos
      prefix = "-";
    } else if (type == 'UNSTAKE') {
      title = "Recompensa";
      icon = Icons.lock_open_rounded;
      iconColor = Colors.deepPurple;
      amountColor = Colors.deepPurple;
      prefix = "+";
    } else if (type == 'WITHDRAW') {
      title = "Liquidación de Stake";
      icon = Icons.lock_open_rounded;
      iconColor = Colors.green;
      amountColor = Colors.green;
      prefix = "+";
    } else if (type == 'RECOVERY') {
      title = "Recuperación";
      icon = Icons.healing_rounded;
      iconColor = Colors.orange;
      amountColor = Colors.orange;
    } else if (type == "STAKE_CONTRACT") {
      title = "Contrato de Staking";
      icon = Icons.build_circle_outlined;
      iconColor = Colors.orange;
    }

    if (isFailed) {
      iconColor = colorScheme.error; // 🔥 Error = Rojo M3
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

    // Avatar con color tonal transparente
    Widget leadingWidget = CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(icon, color: iconColor),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24), // 🔥 REGLA 2: Bordes 24px
        border: isFailed ? Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.5) : Border.all(color: Colors.transparent, width: 0),
      ),
      child: InkWell(
        onTap: () {
          TransactionDetailsModal.show(
            context: context,
            tx: tx,
          );
        },
        borderRadius: BorderRadius.circular(24), // 🔥 REGLA 2: Ripple alineado al borde
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Más padding = Más Premium
          leading: leadingWidget, 
          title: Row(
            children: [
              Text(title, style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold, fontSize: 16)),
              if (esFantasma) ...[
                const SizedBox(width: 6),
                const Icon(Icons.healing_rounded, color: Colors.orange, size: 14),
              ]
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(isFailed ? "Fallida" : "Completada", style: TextStyle(color: isFailed ? colorScheme.error : onSurfaceColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(timeStr, style: TextStyle(color: onSurfaceColor.withOpacity(0.4), fontSize: 11)),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: discreetModeNotifier,
                builder: (context, isDiscreet, _) {
                  if (esFantasma && amount == 0.0) {
                    return Text("---", style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 18));
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      isDiscreet ? "**** TTC" : "$prefix ${amount.toStringAsFixed(2)} TTC", // A 2 decimales para que se vea más a fiat
                      key: ValueKey<bool>(isDiscreet),
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w900, // Letra más gruesa para saldos
                        fontSize: 16,
                        letterSpacing: -0.5,
                        decoration: isFailed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}