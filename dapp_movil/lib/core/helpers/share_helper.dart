import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> exportarHistorialCSV(BuildContext context, List<dynamic> transactions, String miDireccion) async {
    try {
      String csvData = "Fecha y Hora,Tipo,Estado,Monto (TTC),Contraparte,ID Transaccion (Hash)\n";

      for (var tx in transactions) {
        String fechaRaw = tx['timestamp']?.toString() ?? "";
        String fecha = fechaRaw.length >= 19 ? fechaRaw.substring(0, 19).replaceAll("T", " ") : fechaRaw;

        String tipoRaw = tx['txType']?.toString() ?? "UNKNOWN";
        String estado = tx['status']?.toString() ?? "PENDING";
        double monto = double.tryParse(tx['amount']?.toString() ?? "0") ?? 0.0;
        
        String hash = tx['txHash']?.toString() ?? "";
        String sender = tx['senderAddress']?.toString().toLowerCase() ?? "";
        String receiver = tx['receiverAddress']?.toString().toLowerCase() ?? "";

        bool soySender = sender == miDireccion.toLowerCase();
        String contraparte = soySender ? receiver : sender;
        String tipoAmigable = tipoRaw;
        String prefijoMonto = soySender ? "-" : "+";

        if (tipoRaw == 'SEND' || tipoRaw == 'SEND_FIAT' || tipoRaw == 'BINANCE_PAY') {
          tipoAmigable = soySender ? "Enviado" : "Recibido";
        } else if (tipoRaw == 'BUY' || tipoRaw == 'BUY_FIAT') {
          tipoAmigable = "Compra / Recarga";
          contraparte = "Sistema";
          prefijoMonto = "+";
        } else if (tipoRaw == 'STAKE' || tipoRaw == 'UNSTAKE' || tipoRaw == 'WITHDRAW') {
          tipoAmigable = "Minería PoS";
          contraparte = "Smart Contract";
        }

        csvData += "\"$fecha\",\"$tipoAmigable\",\"$estado\",\"$prefijoMonto$monto\",\"$contraparte\",\"$hash\"\n";
      }

      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/Reporte_TTC_Wallet.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes mi reporte financiero de TTC Wallet.');
      
    } catch (e) {
      print("Error generando CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al generar el archivo Excel")));
    }
  }
  
  static Future<void> compartirTransaccionPDF(BuildContext context, dynamic tx, String myAddress) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando comprobante seguro...", style: TextStyle(color: Colors.white)))
    );
final String type = (tx['txType']?.toString() ?? 'Unknown').toUpperCase().trim();
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String txHash = tx['txHash']?.toString() ?? 'N/A';
    final String sender = (tx['senderAddress']?.toString() ?? '');
    final String receiver = (tx['receiverAddress']?.toString() ?? '');
    final bool iAmReceiver = receiver.toLowerCase() == myAddress.toLowerCase();
    final String status = tx['status']?.toString() ?? 'PENDING';
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';

    String titulo = "Comprobante de Transacción";
    PdfColor colorPrincipal = PdfColors.blue800;
    String signo = "";

    if (type == 'SEND' || type == 'SEND_FIAT') {
      if (iAmReceiver) {
        titulo = "Transferencia Recibida";
        colorPrincipal = PdfColors.green700;
        signo = "+";
      } else {
        titulo = "Envío Realizado";
        colorPrincipal = PdfColors.blue800;
        signo = "-";
      }
    } else if (type == 'BUY' || type == 'BUY_FIAT') {
      titulo = "Compra de Tokens";
      colorPrincipal = PdfColors.green700;
      signo = "+";
    } else if (type == 'STAKE' || type == 'UNSTAKE' || type == 'WITHDRAW') {
      titulo = "Movimiento de Minería PoS";
      colorPrincipal = PdfColors.orange700;
    }

if (isFailed) colorPrincipal = PdfColors.red700;

String statusMessage = "";
    if (isFailed) {
      String backendReason = tx['reason'] ?? tx['errorMessage'] ?? "";
      if (backendReason.isNotEmpty) statusMessage = "Motivo del rechazo: $backendReason";
      else if (type == 'SEND' || type == 'SEND_FIAT') statusMessage = "Transacción declinada (Fondos insuficientes o error de red).";
      else if (type == 'BUY' || type == 'BUY_FIAT') statusMessage = "El cargo no pudo ser procesado.";
      else statusMessage = "Transacción revertida por el Smart Contract.";
    } else {
      if (type == 'SEND' || type == 'SEND_FIAT') statusMessage = iAmReceiver ? "Fondos acreditados correctamente a su favor." : "Los fondos fueron entregados al destinatario.";
      else if (type == 'BUY' || type == 'BUY_FIAT') statusMessage = "Compra validada. Tokens acreditados.";
      else if (type == 'STAKE') statusMessage = "Fondos asegurados en el protocolo de staking.";
      else if (type == 'UNSTAKE' || type == 'WITHDRAW') statusMessage = "Recompensas liberadas a la billetera principal.";
      else statusMessage = "Operación validada en Blockchain.";
    }

    String fecha = "Fecha desconocida";
    if (tx['timestamp'] != null) {
      try {
        DateTime date = DateTime.parse(tx['timestamp'].toString());
        fecha = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        fecha = tx['timestamp'].toString();
      }
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, 
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: colorPrincipal)),
                pw.SizedBox(height: 5),
                pw.Text(titulo, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 15),

                pw.Text("$signo${amount.toStringAsFixed(4)} TTC", style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: colorPrincipal)),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: status == 'COMPLETED' ? PdfColors.green100 : PdfColors.red100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))
                  ),
                  child: pw.Text("Estado: $status", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: status == 'COMPLETED' ? PdfColors.green800 : PdfColors.red800)),
                ),
                pw.SizedBox(height: 20),
                pw.Text(statusMessage, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 15),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfRow("Fecha:", fecha),
                      pw.SizedBox(height: 8),
                      _buildPdfRow("De:", sender),
                      pw.SizedBox(height: 8),
                      _buildPdfRow("Para:", receiver),
                      pw.SizedBox(height: 8),
                      _buildPdfRow("Red:", "Avalanche L2 (Web3)"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                pw.Text("Verificar en Blockchain", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: txHash,
                  width: 90,
                  height: 90,
                ),
                pw.SizedBox(height: 10),
                pw.Text(txHash, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                
                pw.Spacer(),
                
                pw.Divider(thickness: 1, color: PdfColors.grey300, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 10),
                pw.Text("Documento generado automáticamente por TTC Wallet", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ],
            ),
          );
        },
      ),
    );

    String shortHash = txHash.length > 10 ? txHash.substring(0, 8) : "Tx";
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Comprobante_TTC_$shortHash.pdf');
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    String displayValue = value;
    if (value.length > 25 && value.startsWith('0x')) {
      displayValue = "${value.substring(0, 10)}...${value.substring(value.length - 8)}";
    }
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey800)),
        pw.Text(displayValue, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
      ]
    );
  }

  static Future<void> generarYCompartirPDFCobroGrupal(
    BuildContext context, 
    dynamic req, 
    String groupName
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generando Reporte Grupal...", style: TextStyle(color: Colors.white)))
    );

    final String description = req['description']?.toString() ?? 'Cobro Grupal';
    final double totalAmount = req['totalAmount'] != null ? double.parse(req['totalAmount'].toString()) : 0.0;
    final String status = req['status']?.toString() ?? 'OPEN';
    final String destinationAddress = req['destinationAddress']?.toString() ?? 'Desconocido';
    final String reqId = req['_id']?.toString() ?? req['id']?.toString() ?? 'ID_DESCONOCIDO';
    final List<dynamic> debts = req['debts'] ?? [];

    double recolectado = 0;
    for (var d in debts) {
      if (d['status'] == 'PAID' || d['status'] == 'SETTLED_BY_ADMIN') {
        recolectado += double.parse(d['amountOwed'].toString());
      }
    }

    String fecha = "Fecha desconocida";
    if (req['createdAt'] != null) {
      try {
        DateTime date = DateTime.parse(req['createdAt'].toString());
        fecha = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      } catch (e) {}
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Text("Reporte de Cobro Grupal", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ]),
              pw.Text("Fecha: $fecha", style: const pw.TextStyle(fontSize: 12)),
            ]),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.grey300)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("Grupo: $groupName", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 5),
                pw.Text("Motivo: $description", style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 2),
                pw.Text("Destino de fondos: $destinationAddress", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Monto Total: ${totalAmount.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text("Recolectado: ${recolectado.toStringAsFixed(2)} TTC", style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text("Estado: $status", style: pw.TextStyle(color: status == 'COMPLETED' ? PdfColors.green700 : PdfColors.orange700, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ]
                )
              ]),
            ),
            pw.SizedBox(height: 30),

            pw.Text("Detalle de Aportes", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Usuario', 'Billetera', 'Cuota', 'Estado', 'Fecha Pago'],
                ...debts.map<List<String>>((d) {
                  String alias = "@${d['alias']?.toString() ?? 'Desconocido'}";
                  String wallet = d['walletAddress']?.toString() ?? 'N/A';
                  String walletCorto = wallet.length > 10 ? "${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}" : wallet;
                  String monto = "${d['amountOwed']} TTC";
                  String estadoDeuda = d['status']?.toString() ?? 'PENDING';
                  
                  String fechaPago = "Pendiente";
                  if (d['paidAt'] != null) {
                    try {
                      DateTime dp = DateTime.parse(d['paidAt'].toString());
                      fechaPago = "${dp.day.toString().padLeft(2, '0')}/${dp.month.toString().padLeft(2, '0')} ${dp.hour.toString().padLeft(2, '0')}:${dp.minute.toString().padLeft(2, '0')}";
                    } catch(e){}
                  }

                  return <String>[alias, walletCorto, monto, estadoDeuda, fechaPago];
                }),
              ],
            ),

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("ID de Solicitud (Auditoría Blockchain)", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.SizedBox(height: 5),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: "TTC-GROUP-PAYMENT:$reqId",
                    width: 80,
                    height: 80,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(reqId, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500)),
                ]
              )
            ),
            pw.SizedBox(height: 15),
            pw.Divider(thickness: 1, color: PdfColors.grey300, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 10),
            pw.Text("Este documento es un registro digital de cuentas compartidas generado por TTC Wallet.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
          ];
        },
      ),
    );

    String safeGroupName = groupName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_${safeGroupName}_TTC.pdf');
  }

  static Future<void> generarYCompartirPDFHistory(BuildContext context, List<dynamic> transacciones, String miBilletera) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Estado de Cuenta...", style: TextStyle(color: Colors.white))));
    final pdf = pw.Document();
    
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40), build: (pw.Context context) {
      return [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Estado de Cuenta Oficial", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ]),
          pw.Text("Fecha: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 12)),
        ]),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(10), decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("Billetera del Titular:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(miBilletera, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text("Total de Movimientos Registrados: ${transacciones.length}"),
          ]),
        ),
        pw.SizedBox(height: 30),
        pw.TableHelper.fromTextArray(
          context: context, headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800), headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))), cellAlignment: pw.Alignment.centerLeft,
          data: <List<String>>[
            <String>['Fecha', 'Tipo', 'Monto', 'Estado', 'Hash/ID'],
            
            ...transacciones.map<List<String>>((tx) {
              String fechaRaw = tx['timestamp']?.toString() ?? 'N/A';
              String fecha = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : fechaRaw;
              
              String recAddress = tx['receiverAddress']?.toString() ?? '';
              bool esIngreso = recAddress.toLowerCase() == miBilletera.toLowerCase();
              
              String signo = esIngreso ? "+" : "-";
              String montoRaw = tx['amount']?.toString() ?? '0.0';
              String monto = "$signo$montoRaw TTC";
              
              String tipo = tx['txType']?.toString() ?? 'Desconocido';
              String estado = tx['status']?.toString() ?? 'Pendiente';
              
              String hashCompleto = tx['txHash']?.toString() ?? 'N/A';
              String hashCorto = hashCompleto.length > 10 
                  ? "${hashCompleto.substring(0, 6)}...${hashCompleto.substring(hashCompleto.length - 4)}" 
                  : hashCompleto;
                  
              return <String>[fecha, tipo, monto, estado, hashCorto];
            }),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.Text("Este documento es un registro digital generado automáticamente por la Blockchain. Las transacciones marcadas como COMPLETED son inmutables.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
      ];
    }));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Estado_Cuenta_TTC.pdf');
  }

  static Future<void> generarYCompartirPDFContacto(
    BuildContext context, 
    List<dynamic> transacciones, 
    String miBilletera, 
    String miAlias, 
    String contactoBilletera, 
    String contactoAlias
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Reporte de Contacto...", style: TextStyle(color: Colors.white))));
    
    double totalEnviado = 0;
    double totalRecibido = 0;
    
    for(var tx in transacciones) {
      double amt = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
      String recAddress = tx['receiverAddress']?.toString() ?? '';
      bool esIngreso = recAddress.toLowerCase() == miBilletera.toLowerCase();
      if (esIngreso) {
        totalRecibido += amt;
      } else {
        totalEnviado += amt;
      }
    }

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40), build: (pw.Context context) {
      return [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Reporte de Actividad de Contacto", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ]),
          pw.Text("Fecha: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 12)),
        ]),
        pw.SizedBox(height: 25),
        
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12), 
                decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.blue200)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("TU CUENTA (TITULAR)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text("@$miAlias", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 2),
                  pw.Text(miBilletera, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ]),
              )
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12), 
                decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.green200)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("CONTACTO ASOCIADO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text("@$contactoAlias", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 2),
                  pw.Text(contactoBilletera, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ]),
              )
            ),
          ]
        ),
        pw.SizedBox(height: 20),

        pw.Container(
          padding: const pw.EdgeInsets.all(16), 
          decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Text("Total Transacciones", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text("${transacciones.length}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Column(children: [
                pw.Text("Total Enviado", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text("-${totalEnviado.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              ]),
              pw.Column(children: [
                pw.Text("Total Recibido", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text("+${totalRecibido.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              ])
            ]
          )
        ),

        pw.SizedBox(height: 30),
        
        pw.TableHelper.fromTextArray(
          context: context, 
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800), 
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), 
          rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))), 
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
          data: <List<String>>[
            <String>['Fecha', 'Dirección', 'Monto', 'Estado', 'Hash/ID'],
            
            ...transacciones.map<List<String>>((tx) {
              String fechaRaw = tx['timestamp']?.toString() ?? 'N/A';
              String fecha = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : fechaRaw;
              
              String recAddress = tx['receiverAddress']?.toString() ?? '';
              bool esIngreso = recAddress.toLowerCase() == miBilletera.toLowerCase();
              String direccion = esIngreso ? "Recibido de" : "Enviado a";
              String signo = esIngreso ? "+" : "-";
              
              String montoRaw = tx['amount']?.toString() ?? '0.0';
              String monto = "$signo$montoRaw TTC";
              
              String estado = tx['status']?.toString() ?? 'Pendiente';
              String hashCompleto = tx['txHash']?.toString() ?? 'N/A';
              String hashCorto = hashCompleto.length > 10 
                  ? "${hashCompleto.substring(0, 6)}...${hashCompleto.substring(hashCompleto.length - 4)}" 
                  : hashCompleto;
                  
              return <String>[fecha, direccion, monto, estado, hashCorto];
            }),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.Text("Este documento es un registro digital generado automáticamente por la Blockchain. Las transacciones marcadas como COMPLETED son inmutables.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
      ];
    }));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_${contactoAlias}_TTC.pdf');
  }

  static Future<void> generarYCompartirPDFAnaliticas(BuildContext context, Map<String, dynamic> analyticsData) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Reporte de Analíticas...", style: TextStyle(color: Colors.white))));

    final double totalIngresos = analyticsData['totalIngresos'] != null ? (analyticsData['totalIngresos'] as num).toDouble() : 0.0;
    final double totalEgresos = analyticsData['totalEgresos'] != null ? (analyticsData['totalEgresos'] as num).toDouble() : 0.0;
    final double totalCashback = analyticsData['totalCashback'] != null ? (analyticsData['totalCashback'] as num).toDouble() : 0.0;
    
    final Map<String, dynamic> distGastos = analyticsData['distribucionGastos'] ?? {};
    final Map<String, dynamic> distIngresos = analyticsData['distribucionIngresos'] ?? {};

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40), build: (pw.Context context) {
      return [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Reporte de Analíticas y Finanzas", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ]),
          pw.Text("Fecha: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 12)),
        ]),
        pw.SizedBox(height: 20),

        pw.Container(
          padding: const pw.EdgeInsets.all(16), 
          decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Text("Ingresos Totales", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Text("+${totalIngresos.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              ]),
              pw.Column(children: [
                pw.Text("Egresos Totales", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Text("-${totalEgresos.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
              ]),
              pw.Column(children: [
                pw.Text("Cashback", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                pw.Text("${totalCashback.toStringAsFixed(2)} TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.amber700)),
              ])
            ]
          )
        ),
        pw.SizedBox(height: 30),

        pw.Text("Distribución de Ingresos", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        distIngresos.isEmpty ? pw.Text("No hay datos de ingresos registrados.", style: const pw.TextStyle(color: PdfColors.grey)) :
        pw.TableHelper.fromTextArray(
          context: context, 
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green700), 
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12), 
          data: <List<String>>[
            <String>['Categoría/Tipo', 'Monto (TTC)'],
            ...distIngresos.entries.map<List<String>>((e) => <String>[e.key, "+${(e.value as num).toDouble().toStringAsFixed(2)}"])
          ],
        ),
        
        pw.SizedBox(height: 30),

        pw.Text("Distribución de Egresos", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        distGastos.isEmpty ? pw.Text("No hay datos de egresos registrados.", style: const pw.TextStyle(color: PdfColors.grey)) :
        pw.TableHelper.fromTextArray(
          context: context, 
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red700), 
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12), 
          data: <List<String>>[
            <String>['Categoría/Tipo', 'Monto (TTC)'],
            ...distGastos.entries.map<List<String>>((e) => <String>[e.key, "-${(e.value as num).toDouble().toStringAsFixed(2)}"])
          ],
        ),

        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.Text("Este reporte ha sido generado automáticamente por TTC Wallet y refleja información procesada a partir de la Blockchain.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
      ];
    }));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Analiticas_TTC.pdf');
  }

  static Future<void> generarYCompartirPDFDeuda(BuildContext context, dynamic debt, String myAddress) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Contrato de Deuda...", style: TextStyle(color: Colors.white))));

    double total = double.tryParse(debt['totalAmount'].toString()) ?? 0;
    double pagado = double.tryParse(debt['paidAmount'].toString()) ?? 0;
    String status = debt['status'] ?? 'UNKNOWN';
    String reason = debt['reason'] ?? 'Acuerdo Financiero';
    String debtor = debt['debtorAddress'] ?? '';
    String creditor = debt['creditorAddress'] ?? '';
    String debtId = debt['id'] ?? 'N/A';

    String fecha = "Fecha desconocida";
    if (debt['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(debt['createdAt'].toString()).toLocal();
        fecha = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      } catch(e){}
    }

    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40), build: (pw.Context context) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.Text("Acuerdo de Deuda (I.O.U)", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ]),
          pw.Text("Fecha de emisión: $fecha", style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.SizedBox(height: 30),

        pw.Container(
          padding: const pw.EdgeInsets.all(16), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("Concepto: $reason", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            _buildPdfRow("Acreedor (Quien cobra):", creditor),
            pw.SizedBox(height: 5),
            _buildPdfRow("Deudor (Quien paga):", debtor),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text("Estado Actual:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(status, style: pw.TextStyle(color: status == 'COMPLETED' ? PdfColors.green700 : PdfColors.orange700, fontWeight: pw.FontWeight.bold)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 30),

        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          pw.Column(children: [ pw.Text("Monto Total", style: const pw.TextStyle(color: PdfColors.grey700)), pw.Text("$total TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)) ]),
          pw.Column(children: [ pw.Text("Monto Pagado", style: const pw.TextStyle(color: PdfColors.grey700)), pw.Text("$pagado TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)) ]),
          pw.Column(children: [ pw.Text("Restante", style: const pw.TextStyle(color: PdfColors.grey700)), pw.Text("${total - pagado} TTC", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)) ]),
        ]),
        pw.SizedBox(height: 50),

        pw.Center(child: pw.Column(children: [
          pw.Text("ID de Auditoría Blockchain", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: "TTC-DEBT:$debtId", width: 100, height: 100),
          pw.SizedBox(height: 5),
          pw.Text(debtId, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ])),
      ]);
    }));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Acuerdo_Deuda_$debtId.pdf');
  }

  static Future<void> generarYCompartirCertificadoNotarial(BuildContext context, Map<String, dynamic> docInfo, String myAddress) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Certificado Blockchain...", style: TextStyle(color: Colors.white))));

    String title = docInfo['title'] ?? 'Documento Notariado';
    String hash = docInfo['docHash'] ?? 'N/A';
    bool fullySigned = docInfo['fullySigned'] ?? false;
    String creator = docInfo['creatorAddress']?.toString().toLowerCase() ?? 'N/A';
    List<dynamic> requiredSigners = docInfo['requiredSigners'] ?? [];
    List<dynamic> signedBy = docInfo['signedBy'] ?? [];

    String fecha = "Fecha desconocida";
    if (docInfo['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(docInfo['createdAt'].toString()).toLocal();
        fecha = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      } catch(e){}
    }

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.Text("Certificado de Firma Notarial", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            ]),
            pw.Text("Fecha de registro: $fecha", style: const pw.TextStyle(fontSize: 10)),
          ]),
          pw.SizedBox(height: 30),

          pw.Container(
            padding: const pw.EdgeInsets.all(16), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("Acuerdo: $title", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              _buildPdfRow("Creado por:", creator),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Estado de Firmas:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(fullySigned ? "EJECUTADO E INMUTABLE" : "PENDIENTE", style: pw.TextStyle(color: fullySigned ? PdfColors.green700 : PdfColors.orange700, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ),
          pw.SizedBox(height: 30),

          pw.Text("Registro de Firmantes", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            data: <List<String>>[
              <String>['Dirección Billetera', 'Estado'],
              ...requiredSigners.map<List<String>>((signer) {
                String addr = signer.toString().toLowerCase();
                bool hasSigned = signedBy.map((e) => e.toString().toLowerCase()).contains(addr);
                String addrFormat = addr == myAddress.toLowerCase() ? "$addr (Tú)" : addr;
                String estado = hasSigned ? "FIRMADO ON-CHAIN" : "Pendiente";
                return <String>[addrFormat, estado];
              }),
            ],
          ),
          pw.SizedBox(height: 40),

          pw.Center(child: pw.Column(children: [
            pw.Text("Hash SHA-256 (Identificador Criptográfico)", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: hash, width: 100, height: 100),
            pw.SizedBox(height: 5),
            pw.Text(hash, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ])),
          pw.SizedBox(height: 30),
          pw.Divider(thickness: 1, color: PdfColors.grey300, borderStyle: pw.BorderStyle.dashed),
          pw.SizedBox(height: 10),
          pw.Text("Este certificado demuestra que la huella digital (Hash) del archivo original fue inscrita y validada en la blockchain de TTC por las partes mencionadas.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
        ];
      }
    ));
    
    // Limpiamos el "0x" para el nombre del archivo si es muy largo
    String safeHash = hash.length > 15 ? hash.substring(2, 10) : "Doc";
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Certificado_Blockchain_$safeHash.pdf');
  }

  static Future<Uint8List> generarTransaccionPDFBytes(dynamic tx, String myAddress) async {
    final String type = (tx['txType']?.toString() ?? 'Unknown').toUpperCase().trim();
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String txHash = tx['txHash']?.toString() ?? 'N/A';
    final String sender = (tx['senderAddress']?.toString() ?? '');
    final String receiver = (tx['receiverAddress']?.toString() ?? '');
    final bool iAmReceiver = receiver.toLowerCase() == myAddress.toLowerCase();
    final String status = tx['status']?.toString() ?? 'COMPLETED';
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';

    String titulo = "Comprobante de Transacción";
    PdfColor colorPrincipal = PdfColors.blue800;
    String signo = "";

    if (type == 'SEND' || type == 'SEND_FIAT' || type == 'BINANCE_PAY') {
      if (iAmReceiver) {
        titulo = "Transferencia Recibida";
        colorPrincipal = PdfColors.green700;
        signo = "+";
      } else {
        titulo = "Envío Realizado";
        colorPrincipal = PdfColors.blue800;
        signo = "-";
      }
    } 

    if (isFailed) colorPrincipal = PdfColors.red700;

    String statusMessage = isFailed ? "Transacción declinada o revertida." : "Operación validada exitosamente en la red.";
    String fecha = tx['timestamp'] != null ? tx['timestamp'].toString().replaceAll("T", " ").substring(0, 16) : DateTime.now().toString().substring(0, 16);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5, 
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: colorPrincipal)),
                pw.SizedBox(height: 5),
                pw.Text(titulo, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 15),

                pw.Text("$signo${amount.toStringAsFixed(4)} TTC", style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: colorPrincipal)),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: status == 'COMPLETED' ? PdfColors.green100 : PdfColors.red100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))
                  ),
                  child: pw.Text("Estado: $status", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: status == 'COMPLETED' ? PdfColors.green800 : PdfColors.red800)),
                ),
                pw.SizedBox(height: 20),
                pw.Text(statusMessage, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 15),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfRow("Fecha:", fecha),
                      pw.SizedBox(height: 8),
                      _buildPdfRow("De:", sender),
                      pw.SizedBox(height: 8),
                      _buildPdfRow("Para:", receiver),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                pw.Text("Validador Criptográfico (Hash)", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: txHash, width: 90, height: 90),
                pw.SizedBox(height: 10),
                pw.Text(txHash, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<void> exportarReporteTareasPDF(BuildContext context, List<dynamic> tasks, String tituloFiltro) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // 1. CABECERA DEL REPORTE
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Reporte de Actividades", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                        pw.SizedBox(height: 4),
                        pw.Text("Generado el: ${DateTime.now().toString().substring(0, 16)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ]
                    ),
                    pw.Text(tituloFiltro, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),

              // 2. TABLA DE TAREAS
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerHeight: 30,
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                headers: ['Título de la Tarea', 'Asignado a', 'Estado', 'Vencimiento', 'Presupuesto'],
                data: tasks.map((t) {
                  String title = t['title']?.toString() ?? 'Sin título';
                  // Limitar longitud del título si es muy largo
                  if (title.length > 30) title = "${title.substring(0, 27)}...";
                  
                  String assigned = t['assignedWallet'] != null ? "@${t['assignedWallet'].toString().substring(0,6)}..." : "Sin asignar";
                  String status = t['status']?.toString() ?? 'PENDING';
                  String deadline = t['deadline'] != null && t['deadline'].toString().length >= 10 
                      ? t['deadline'].toString().substring(0, 10) 
                      : "N/A";
                  String budget = "${t['allocatedResources']?.toString() ?? "0"} TTC";

                  return [title, assigned, status, deadline, budget];
                }).toList(),
              ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Text("Total de actividades en este reporte: ${tasks.length}", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ];
          },
        ),
      );

      

      final bytes = await pdf.save();
      // Compartir o Guardar
      await Printing.sharePdf(bytes: bytes, filename: 'Reporte_Tareas_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      debugPrint("Error generando PDF de tareas: $e");
    }
  }

  static Future<void> generarYCompartirPDFAdminAnalytics(BuildContext context, Map<String, dynamic> analyticsData) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Reporte Ejecutivo...", style: TextStyle(color: Colors.white))));

    final int totalUsers = analyticsData['totalUsers'] ?? 0;
    final int newUsers = analyticsData['newUsersThisMonth'] ?? 0;
    final double growth = double.tryParse(analyticsData['userGrowthPercentage']?.toString() ?? '0') ?? 0.0;
    final double revenue = double.tryParse(analyticsData['estimatedMonthlyRevenueUSD']?.toString() ?? '0') ?? 0.0;
    final Map<String, dynamic> plans = analyticsData['plans'] ?? {};
    final List<dynamic> recentUsers = analyticsData['recentUsers'] ?? [];

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // --- ENCABEZADO ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("TTC WALLET", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
                  pw.Text("Reporte Ejecutivo de Administración", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ]),
                pw.Text("Fecha: ${DateTime.now().toString().substring(0, 10)}", style: const pw.TextStyle(fontSize: 12)),
              ]
            ),
            pw.SizedBox(height: 30),

            // --- KPIS RESUMEN ---
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildAdminKpi("Total Usuarios", "$totalUsers"),
                  _buildAdminKpi("Nuevos (Mes)", "+$newUsers"),
                  _buildAdminKpi("Crecimiento", "${growth > 0 ? '+' : ''}$growth%", color: growth >= 0 ? PdfColors.green700 : PdfColors.red700),
                  _buildAdminKpi("Ingresos Est.", "\$${revenue.toStringAsFixed(2)}"),
                ]
              )
            ),
            pw.SizedBox(height: 30),

            // --- TABLA DE DISTRIBUCIÓN DE PLANES ---
            pw.Text("Distribución de Membresías", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              data: <List<String>>[
                <String>['Plan', 'Usuarios', 'Porcentaje', 'Ingresos Estimados'],
                ...plans.entries.map((e) {
                  final data = e.value as Map<String, dynamic>;
                  return <String>[
                    e.key,
                    data['count']?.toString() ?? '0',
                    "${double.tryParse(data['percentageOfTotal']?.toString() ?? '0')?.toStringAsFixed(1)}%",
                    "\$${double.tryParse(data['estimatedRevenue']?.toString() ?? '0')?.toStringAsFixed(2)}"
                  ];
                })
              ],
            ),
            pw.SizedBox(height: 30),

            // --- TABLA DE USUARIOS RECIENTES ---
            pw.Text("Últimos Usuarios Registrados", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            recentUsers.isEmpty 
              ? pw.Text("No hay usuarios recientes.", style: const pw.TextStyle(color: PdfColors.grey))
              : pw.TableHelper.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  data: <List<String>>[
                    <String>['Alias', 'Email', 'Plan', 'Tipo', 'Fecha Registro'],
                    ...recentUsers.map((u) {
                      String date = u['createdAt'] != null ? u['createdAt'].toString().substring(0, 10) : "N/A";
                      return <String>[
                        u['alias'] ?? 'N/A',
                        u['email'] ?? 'N/A',
                        u['membershipTier'] ?? 'FREE',
                        u['accountType'] ?? 'PERSONAL',
                        date
                      ];
                    })
                  ]
                ),

            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text(
              "Documento generado automáticamente por el panel de control de TTC Wallet.", 
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), 
              textAlign: pw.TextAlign.center
            ),
          ];
        }
      )
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_Ejecutivo_Admin_TTC.pdf');
  }

  // Helper privado para los KPIs del PDF Admin
  static pw.Widget _buildAdminKpi(String label, String value, {PdfColor color = PdfColors.black}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ]
    );
  }
}