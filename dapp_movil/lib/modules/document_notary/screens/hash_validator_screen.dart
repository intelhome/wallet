import 'dart:convert';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../wallet_and_tx/screens/qr_scanner_screen.dart';
import '../../wallet_and_tx/screens/receipt_preview_screen.dart';

class HashValidatorScreen extends StatefulWidget {
  //final BlockchainService service;
  const HashValidatorScreen({super.key});

  @override
  State<HashValidatorScreen> createState() => _HashValidatorScreenState();
}

class _HashValidatorScreenState extends State<HashValidatorScreen> {
  final TextEditingController _hashController = TextEditingController();
  bool _isLoading = false;

  // 🔥 AGREGAR:
  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  Future<void> _validarHash() async {
    String hash = _hashController.text.trim();
    if (hash.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final tx = await txService.getTransactionByHash(hash);

    if (mounted) setState(() => _isLoading = false);

    if (tx != null) {
      // 🔥 MOSTRAR CERTIFICADO DE TRANSACCIÓN
      _mostrarResultadoExitoso(tx);
    } else {
      // ❌ MOSTRAR REGLA DE ORO
      _mostrarAlertaDeFraude();
    }
  }

  void _mostrarResultadoExitoso(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final onSurface = colorScheme.onSurface;
        
        String fecha = tx['timestamp'] != null ? DateTime.parse(tx['timestamp']).toLocal().toString().substring(0, 16) : "Fecha desconocida";
        double amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.shield_rounded, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 16),
              const Text("¡Transacción Legítima!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
              Text("El dinero fue movido exitosamente en la red.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),

              // DATOS DE LA TRANSACCIÓN (M3 Tonal Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Fecha", fecha, Icons.access_time_rounded, colorScheme.primary),
                    const Divider(height: 15),
                    _buildInfoRow("Monto Total", "$amount TTC", Icons.attach_money_rounded, Colors.green),
                    const Divider(height: 15),
                    
                    const Text("Enviado por:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(tx['senderAddress'] ?? "Desconocido", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 10),
                    
                    const Text("Recibido por:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(tx['receiverAddress'] ?? "Desconocido", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11)),
                    const Divider(height: 15),
                    
                    Row(
                      children: [
                        Icon(Icons.tag_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text("Hash:"),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tx['txHash'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: tx, myAddress: authCore.publicAddress)));
                  },
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text("Previsualizar Recibo PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void _mostrarAlertaDeFraude() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
        title: const Text("Transacción Inexistente", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "El Hash o código QR proporcionado no arrojó ningún resultado en nuestro explorador de bloques.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.5))),
              child: Column(
                children: [
                  const Text("REGLA DE ORO", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    "«Don't trust, verify»\n(No confíes, verifica)",
                    style: TextStyle(color: Colors.orange[800], fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Si una transacción no está registrada en la Blockchain, simplemente no existe. Por favor exige un Hash válido al remitente.",
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: iconColor == Colors.green ? Colors.green : null)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Validador de Hash", style: TextStyle(fontWeight: FontWeight.bold)), elevation: 0, backgroundColor: Colors.transparent, centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.barcode_reader, size: 80, color: Colors.deepPurpleAccent),
            ),
            const SizedBox(height: 30),
            const Text("Comprobación de Pagos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(
              "Verifica la autenticidad de un comprobante escaneando su QR o pegando el Hash SHA-256.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _hashController,
              decoration: InputDecoration(
                labelText: "Hash de Transacción (0x...)",
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.deepPurpleAccent),
                  onPressed: () async {
                    final scanned = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
                    if (scanned != null) {
                      _hashController.text = scanned;
                      _validarHash();
                    }
                  },
                ),
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: _isLoading ? null : _validarHash,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Verificar en Blockchain", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}