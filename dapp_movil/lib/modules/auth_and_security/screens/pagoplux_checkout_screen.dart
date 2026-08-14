import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class PagoPluxCheckoutScreen extends StatefulWidget {
  final String plan;
  final double amount;

  const PagoPluxCheckoutScreen({super.key, required this.plan, required this.amount});

  @override
  State<PagoPluxCheckoutScreen> createState() => _PagoPluxCheckoutScreenState();
}

class _PagoPluxCheckoutScreenState extends State<PagoPluxCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isGeneratingLink = true;
  String? _paymentUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1120))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          // Podemos interceptar la URL si PagoPlux redirige al terminar
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains("success") || request.url.contains("comprobante")) {
              // Si detectamos que finalizó, cerramos retornando true
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
      
    _fetchPaymentLink();
  }

 Future<void> _fetchPaymentLink() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final planService = Provider.of<PlanConfigService>(context, listen: false);

    try {
      // 🔥 Ahora esperamos el String directamente o una Excepción
      final url = await planService.generatePagoPluxLink(authCore, widget.plan, widget.amount);
      
      if (mounted) {
        setState(() {
          _paymentUrl = url;
          _isGeneratingLink = false;
        });
        _controller.loadRequest(Uri.parse(url)); // Cargamos la URL nativa de PagoPlux
      }
    } catch (e) {
      if (mounted) {
        // 🔥 Mostramos el error REAL que devolvió PagoPlux (Ej: "El ruc no se encuentra registrado")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5), // Un poco más de tiempo para poder leerlo
          )
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Pago Seguro: ${widget.plan}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          if (!_isGeneratingLink && _paymentUrl != null)
            WebViewWidget(controller: _controller),
            
          if (_isLoading || _isGeneratingLink)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4361EE)),
                  const SizedBox(height: 24),
                  Text(
                    _isGeneratingLink ? "Conectando con PagoPlux..." : "Cargando pasarela...",
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}