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

  @override
  void initState() {
    super.initState();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    // 🔥 HTML MÁGICO: Ahora con jQuery, Tailwind CSS y Diseño Dark Mode 🔥
    String payboxHtml = '''
      <!DOCTYPE html>
      <html lang="es">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          
          <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
          
          <script src="https://sandbox-paybox.pagoplux.com/paybox/index.js"></script>
          
          <script src="https://cdn.tailwindcss.com"></script>
          
          <style>
              /* Ajustamos los colores al tema oscuro de tu app (main.dart) */
              body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; 
                background-color: #0B1120; 
                color: #F8FAFC; 
              }
              .glass-card { 
                background: #1E293B; 
                border-radius: 24px; 
                border: 1px solid rgba(255,255,255,0.05); 
                box-shadow: 0 20px 40px -10px rgba(0,0,0,0.5); 
              }
          </style>
      </head>
      <body class="flex flex-col items-center justify-center min-h-screen p-6">
          
          <div class="glass-card w-full max-w-sm p-8 text-center">
              
              <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-600/20 text-blue-500 mb-6">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
              </div>

              <h2 class="text-sm font-bold text-gray-400 uppercase tracking-widest mb-1">Membresía</h2>
              <h1 class="text-3xl font-black text-white mb-2">${widget.plan}</h1>
              
              <div class="flex items-end justify-center gap-1 mb-8">
                  <span class="text-5xl font-black text-blue-500">\$${widget.amount}</span>
                  <span class="text-gray-400 font-medium pb-1">/ mes</span>
              </div>

              <div class="space-y-4 text-left mb-8">
                  <div class="flex items-center">
                      <div class="flex-shrink-0 w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center text-green-400 mr-3">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
                      </div>
                      <span class="text-sm text-gray-300">Renovación automática segura</span>
                  </div>
                  <div class="flex items-center">
                      <div class="flex-shrink-0 w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center text-green-400 mr-3">
                          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
                      </div>
                      <span class="text-sm text-gray-300">Cancela en cualquier momento</span>
                  </div>
              </div>

              <button id="btn-pagoplux" class="w-full bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-bold py-4 px-6 rounded-2xl text-lg transition duration-200 shadow-lg shadow-blue-500/30 flex justify-center items-center">
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>
                  Pagar de forma segura
              </button>
              
              <p class="mt-5 text-xs text-gray-500 flex justify-center items-center">
                  <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
                  Pagos procesados por PagoPlux
              </p>
          </div>

         <script>
              // Esperamos a que la página y los scripts externos terminen de cargar
              window.onload = function() {
                  // Pequeño retraso de seguridad
                  setTimeout(function() {
                      if (typeof PagoPlux !== 'undefined') {
                          var data = {
                              PayboxRemail: "tu_correo@empresa.com",
                              PayboxSendmail: "tu_correo@empresa.com",
                              PayboxRename: "TTC Wallet DApp",
                              PayboxSendname: "TTC Wallet",
                              PayboxBase0: "0",
                              PayboxBase12: "${widget.amount}",
                              PayboxDescription: "Suscripcion ${widget.plan}",
                              PayboxLanguage: "es",
                              PayboxDirection: "Ecuador",
                              PayboxClientIdentification: "${authCore.publicAddress}",
                              PayboxClientName: "Usuario TTC",
                              clientTransactionId: "${widget.plan}" 
                          };

                          PagoPlux.init(data, "btn-pagoplux");

                          PagoPlux.onComplete(function(response) {
                              Print.postMessage("SUCCESS");
                          });
                      } else {
                          console.error("El script de PagoPlux no pudo cargar.");
                          // Si falla, avisamos a Flutter para manejar el error
                          Print.postMessage("ERROR_LOAD"); 
                      }
                  }, 800); 
              };
          </script>
      </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1120)) // Fondo oscuro M3
      ..addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == "SUCCESS") {
            Navigator.pop(context, true);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
          if (mounted) {
  setState(() {
    _isLoading = false; 
  });
}
          },
          // Evitar que abra navegadores externos
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(payboxHtml);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Resumen de Compra", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20)
                ),
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}