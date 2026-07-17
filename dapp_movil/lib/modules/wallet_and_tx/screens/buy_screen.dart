import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay/pay.dart';
import 'package:flutter_paypal/flutter_paypal.dart';

import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';

class BuyScreen extends StatefulWidget {
  final String? initialAmount;
  final VoidCallback onUpdateBalance;
  final void Function(String, {bool esError}) mostrarMensaje;
  final bool isGroupPayment;

  const BuyScreen({
    super.key,
    this.initialAmount,
    required this.onUpdateBalance,
    required this.mostrarMensaje,
    this.isGroupPayment = false,
  });

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  late TextEditingController _montoController;
  double _montoIngresado = 0.0;
  bool _isProcessing = false;
  String _selectedMethod = "PayPal";
  Pay? _payClient;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.initialAmount ?? "");
    _montoIngresado = double.tryParse(widget.initialAmount ?? '0') ?? 0.0;
    PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
      if (mounted) {
        setState(() {
          _payClient = Pay({ PayProvider.google_pay: config });
        });
      }
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _comprarPaypal() async {
    if (_montoIngresado <= 0 || _isProcessing) return;
    setState(() => _isProcessing = true);

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    BuildContext rootContext = context;

    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella para comprar."),
    );

    HapticFeedback.mediumImpact();
    bool isAuth = await authCore.authenticateUser();

    if (!isAuth) {
      setState(() => _isProcessing = false);
      if (mounted) Navigator.pop(rootContext);
      widget.mostrarMensaje("Autenticación cancelada", esError: true);
      return;
    }

    if (mounted) Navigator.pop(rootContext); // Quita huella

    if (!mounted) return;
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => const TransactionSkeleton(title: "Conectando", message: "Abriendo pasarela segura..."),
    );

    String amountStr = _montoIngresado.toStringAsFixed(2);
    
    if (mounted) Navigator.pop(rootContext); // cierra dialog
    
    if (!mounted) return;
    Navigator.of(rootContext).push(
      MaterialPageRoute(
        builder: (BuildContext contextPaypal) => UsePaypal(
          sandboxMode: true,
          clientId: "AW91VEGq61jntCQhvokYTUOaxCVcizMrknQfIkXklZtzlNDZdWN74Un4PIxng_hxrTot6_TuDyv1o24W", 
          secretKey: "ELBDqAKGPSxRGp-LutS9fgTiFIswAan_9wVyK5MqnGQcGfMllkUA9C1AyrJcXxXyPuoSTLl0EXwHAtoE", 
          returnURL: "https://sandbox.paypal.com/return",
          cancelURL: "https://sandbox.paypal.com/cancel",
          transactions: [
            {
              "amount": { "total": amountStr, "currency": "USD", "details": {"subtotal": amountStr, "shipping": '0', "shipping_discount": 0} },
              "description": "Compra de $amountStr TTC Tokens",
              "item_list": { "items": [ {"name": "TTC Token", "quantity": 1, "price": amountStr, "currency": "USD"} ] }
            }
          ],
          note: "Gracias por confiar en TTC Wallet.",
          onSuccess: (Map params) {
            Future.delayed(const Duration(milliseconds: 500), () async {
              // 🔥 FIX 1: Usamos 'push' normal para no destruir la pantalla de fondo
              Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                customTitle: "Compra Exitosa", 
                customMessage: "Acreditando tus fondos en la Blockchain...", 
                isGroupPayment: widget.isGroupPayment, 
                onUpdateBalance: widget.onUpdateBalance 
              )));

              String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
              final res = await txService.buyTokensFiat(orderId, _montoIngresado);

              if (res.startsWith("Error")) {
                if (mounted) Navigator.pop(rootContext); // 🔥 FIX 2: Cierra el PendingScreen si hay error
                widget.mostrarMensaje(res, esError: true);
              }
            });
          },
          onError: (error) {
            setState(() => _isProcessing = false);
            widget.mostrarMensaje("Error al procesar el pago", esError: true);
          },
          onCancel: (params) {
            setState(() => _isProcessing = false);
            widget.mostrarMensaje("Pago cancelado por el usuario", esError: true);
          }
        )
      )
    );
  }

  void _comprarGooglePay() async {
    if (_montoIngresado <= 0 || _isProcessing) return;
    setState(() => _isProcessing = true);

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    BuildContext rootContext = context;

    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella para comprar."),
    );

    HapticFeedback.mediumImpact();
    bool isAuth = await authCore.authenticateUser();

    if (!isAuth) {
      setState(() => _isProcessing = false);
      if (mounted) Navigator.pop(rootContext);
      widget.mostrarMensaje("Autenticación cancelada", esError: true);
      return;
    }

    if (mounted) Navigator.pop(rootContext);

    if (!mounted) return;
    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => const TransactionSkeleton(title: "Conectando", message: "Cargando servicios de Google..."),
    );

    if (_payClient == null) {
      setState(() => _isProcessing = false);
      if (mounted) Navigator.pop(rootContext);
      widget.mostrarMensaje("Cargando servicios de Google, intenta de nuevo.", esError: true);
      return;
    }

    try {
      await _payClient!.showPaymentSelector(
        PayProvider.google_pay, 
        [ PaymentItem(label: 'TTC Tokens', amount: _montoIngresado.toStringAsFixed(2), status: PaymentItemStatus.final_price) ],
      );
    } catch (e) {
      debugPrint("Error nativo de GPay atrapado: \$e");
      widget.mostrarMensaje("Billetera inactiva. Usando modo simulador de pago...");
      await Future.delayed(const Duration(seconds: 2));
    }

   if (mounted) Navigator.pop(rootContext); // Cerramos el dialogo de Google
    if (!mounted) return;

    // 🔥 FIX 3: Usamos 'push' normal
    Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
      customTitle: "Minando Tokens", 
      customMessage: "Acreditando tus fondos en la Blockchain...", 
      isGroupPayment: widget.isGroupPayment, 
      onUpdateBalance: widget.onUpdateBalance 
    )));

    // 🔥 FIX 4: Quitamos la barra invertida (\) que causaba el bloqueo por "Atentado Detectado"
    String orderId = "GPAY-${DateTime.now().millisecondsSinceEpoch}"; 
    final res = await txService.buyTokensFiat(orderId, _montoIngresado);

    if (res.startsWith("Error")) {
      Navigator.pop(rootContext); // 🔥 FIX 5: Cierra la pantalla de carga si falla
      widget.mostrarMensaje(res, esError: true);
    }
  }

  void _handleComprar() {
    if (_selectedMethod == "PayPal") {
      _comprarPaypal();
    } else if (_selectedMethod == "Google Pay") {
      _comprarGooglePay();
    } else {
      widget.mostrarMensaje("Método no implementado todavía", esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceColor = colorScheme.onSurface;
    final cardColor = theme.cardColor;

    double rewardTtc = _montoIngresado * 0.025;

    return Scaffold(
      appBar: AppBar(
        title: Text("Comprar TTC", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurfaceColor),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: onSurfaceColor.withOpacity(0.5)),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text("Monto a pagar", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _montoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: onSurfaceColor, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: "0.00",
                            prefixText: "\$ ",
                            prefixStyle: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.bold),
                            suffixText: " USD",
                            suffixStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          onChanged: (val) {
                            setState(() => _montoIngresado = double.tryParse(val) ?? 0);
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: onSurfaceColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz, size: 16, color: onSurfaceColor.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text("Equivale a ${_montoIngresado.toStringAsFixed(2)} TTC", style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exchange Rate Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: onSurfaceColor.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Tasa de cambio", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 14)),
                            Text("1 USD = 1 TTC", style: TextStyle(color: onSurfaceColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text("Comisión de red", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 14)),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 14, color: onSurfaceColor.withOpacity(0.4)),
                              ],
                            ),
                            Text("0.00 USD", style: TextStyle(color: onSurfaceColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: onSurfaceColor.withOpacity(0.1), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total a recibir", style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("${_montoIngresado.toStringAsFixed(2)} TTC", style: TextStyle(color: const Color(0xFF9EAEFF), fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reward Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9EAEFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF9EAEFF).withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.card_giftcard, color: Color(0xFF9EAEFF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("Estimated Reward", style: TextStyle(color: Color(0xFF9EAEFF), fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.info_outline, size: 14, color: const Color(0xFF9EAEFF).withOpacity(0.6)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("+${rewardTtc.toStringAsFixed(2)} TTC (2.5% Cashback en tu primera compra)", style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Metodos rapidos
                  Text("Métodos Rápidos", style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedMethod == "Google Pay" ? const Color(0xFF0079C1) : onSurfaceColor.withOpacity(0.1),
                            foregroundColor: _selectedMethod == "Google Pay" ? Colors.white : onSurfaceColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() => _selectedMethod = "Google Pay");
                          },
                          icon: Icon(Icons.g_mobiledata, size: 28, color: _selectedMethod == "Google Pay" ? Colors.white : onSurfaceColor),
                          label: const Text("Google Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedMethod == "PayPal" ? const Color(0xFF0079C1) : onSurfaceColor.withOpacity(0.1),
                            foregroundColor: _selectedMethod == "PayPal" ? Colors.white : onSurfaceColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setState(() => _selectedMethod = "PayPal");
                          },
                          icon: Icon(Icons.paypal, size: 20, color: _selectedMethod == "PayPal" ? Colors.white : onSurfaceColor),
                          label: const Text("PayPal", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Buy Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5C0FF),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: const Color(0xFFB5C0FF).withOpacity(0.3),
                      ),
                      onPressed: (_montoIngresado <= 0 || _isProcessing) ? null : () => _handleComprar(),
                      icon: _isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                        : const Icon(Icons.shopping_cart_outlined, size: 22),
                      label: Text(
                        _isProcessing ? "Procesando..." : "Comprar",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer secure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: onSurfaceColor.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text("SSL 256-bit", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 12, color: onSurfaceColor.withOpacity(0.2)),
                      const SizedBox(width: 16),
                      Icon(Icons.security, size: 14, color: onSurfaceColor.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text("PCI-DSS Secure", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: onSurfaceColor.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total a pagar", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text("\$${_montoIngresado.toStringAsFixed(2)} USD", style: TextStyle(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
