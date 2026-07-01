import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/helpers/share_helper.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final dynamic tx;
  final String myAddress;

  const ReceiptPreviewScreen({super.key, required this.tx, required this.myAddress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprobante de Pago"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: PdfPreview(
        build: (format) => ShareHelper.generarTransaccionPDFBytes(tx, myAddress),
        allowSharing: true, // Deja el botón de compartir
        allowPrinting: false, // Oculta imprimir
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: "Comprobante_TTC.pdf",
      ),
    );
  }
}