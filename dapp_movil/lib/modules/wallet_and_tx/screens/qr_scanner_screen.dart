import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(title: Text("Escanear Dirección", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: colorScheme.onSurface), elevation: 0),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final String code = barcode.rawValue!;
                  
                  if (code.contains("0x")) {
                    setState(() => _isScanned = true);
                    
                    String cleanAddress = "";
                    String amount = "";

                    // 🔥 SI ES FORMATO ERC-681 (Ej: ethereum:0x123...?amount=50)
                    if (code.startsWith("ethereum:")) {
                      Uri uri = Uri.parse(code);
                      cleanAddress = uri.path; // Saca la dirección
                      amount = uri.queryParameters['amount'] ?? ""; // Saca el monto
                    } else {
                      // Formato antiguo (Solo la dirección)
                      cleanAddress = "0x${code.split("0x")[1].substring(0, 40)}";
                    }

                    // Devolvemos un Diccionario (Map) con ambos datos
                    Navigator.pop(context, {
                      'address': cleanAddress.toLowerCase(),
                      'amount': amount
                    });
                    return;
                  }
                }
              }
            },
          ),
         Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: colorScheme.primary, width: 3), borderRadius: BorderRadius.circular(24)))), // 🔥 Primary y 24px
         Positioned(bottom: 50, left: 0, right: 0, child: Text("Apunta al código QR para leer la dirección", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface, fontSize: 16, backgroundColor: theme.cardColor.withOpacity(0.8))))
        ],
      ),
    );
  }
}