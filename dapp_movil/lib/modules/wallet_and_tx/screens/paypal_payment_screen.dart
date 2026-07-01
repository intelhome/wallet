import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../settings_and_profile/services/user_service.dart';

class PaypalPaymentScreen extends StatefulWidget {
  final String targetIdentifier; 
  final double amount;
  final String reason;
  final String targetWallet;

  const PaypalPaymentScreen({
    super.key,
    required this.targetIdentifier,
    required this.amount,
    required this.reason,
    required this.targetWallet,
  });

  @override
  State<PaypalPaymentScreen> createState() => _PaypalPaymentScreenState();
}

class _PaypalPaymentScreenState extends State<PaypalPaymentScreen> {
  bool _isCreatingOrder = true;
  bool _isWaitingApproval = false;
  bool _isCapturing = false;
  String _orderId = "";
  String _approveUrl = "";

  @override
  void initState() {
    super.initState();
    _iniciarFlujoPayPal();
  }

  Future<void> _iniciarFlujoPayPal() async {
    final userService = Provider.of<UserService>(context, listen: false);
    
    // 1. Crear Orden v2 en el Servidor inyectando el Payee encriptado
    final orderData = await userService.createPayPalP2POrder(
      widget.targetIdentifier, 
      widget.amount, 
      widget.reason
    );

    if (orderData == null || orderData['id'] == null) {
      UIHelper.showCustomSnackbar("No se pudo estructurar la orden de PayPal", isError: true);
      if (mounted) Navigator.pop(context);
      return;
    }

    _orderId = orderData['id'];
    List<dynamic> links = orderData['links'] ?? [];
    for (var link in links) {
      if (link['rel'] == 'approve') {
        _approveUrl = link['href'];
        break;
      }
    }

    if (_approveUrl.isEmpty) {
      UIHelper.showCustomSnackbar("Falta el enlace de aprobación de PayPal", isError: true);
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) {
      setState(() {
        _isCreatingOrder = false;
        _isWaitingApproval = true;
      });
    }

    // 2. Redirección externa al login seguro de PayPal Inc.
    final Uri url = Uri.parse(_approveUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _verificarYCapturarPago() async {
    setState(() {
      _isWaitingApproval = false;
      _isCapturing = true;
    });

    final userService = Provider.of<UserService>(context, listen: false);
    
    // 3. Captura S2S en Spring Boot y escritura en Historial
    bool success = await userService.capturePayPalP2POrder(_orderId, widget.targetWallet, widget.amount);

    if (success) {
      UIHelper.showCustomSnackbar("¡Transferencia Fiat por PayPal procesada con éxito! 🎉");
    } else {
      UIHelper.showCustomSnackbar("No se pudo verificar la captura. Revisa tu saldo en PayPal.", isError: true);
    }

    if (mounted) {
      Navigator.pop(context); // Cierra la pantalla y vuelve al Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: SmartAvatar(address: widget.targetWallet, size: 90),
              ),
              const SizedBox(height: 24),
              Text(
                "Enviando \$${widget.amount.toStringAsFixed(2)} USD",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.blueAccent),
              ),
              Text(
                "Destinatario: ${widget.targetIdentifier}",
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 15),
              ),
              const SizedBox(height: 40),
              
              if (_isCreatingOrder) ...[
                const Center(child: CircularProgressIndicator(color: Colors.blue)),
                const SizedBox(height: 16),
                const Text("Estableciendo conexión encriptada con PayPal...", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
              ],

              if (_isWaitingApproval) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_browser_rounded, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(child: Text("Por favor, completa el inicio de sesión y pago seguro en la ventana de PayPal.", style: TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 16), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: _verificarYCapturarPago,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text("Ya completé mi pago en PayPal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar Operación", style: TextStyle(color: Colors.grey)),
                )
              ],

              if (_isCapturing) ...[
                const Center(child: CircularProgressIndicator(color: Colors.green)),
                const SizedBox(height: 16),
                const Text("Verificando clearing bancario y registrando en el historial...", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              ],
              
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("Cifrado End-to-End PayPal Inc.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}