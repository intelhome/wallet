import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../modals/paypal_modal.dart';
import 'package:pay/pay.dart';
import 'package:flutter_paypal/flutter_paypal.dart';

import '../screens/transaction_pending_screen.dart';

class BuyModal {
  static void show({
    required BuildContext context, // <-- Este es el contexto principal que NO se destruye
    //required BlockchainService service,
    required VoidCallback onUpdateBalance,
    required void Function(String, {bool esError}) mostrarMensaje,
    String? initialAmount,
    bool isGroupPayment = false,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final txService = Provider.of<TransactionService>(context, listen: false);
    // 🔥 FIX 1: Guardamos el contexto del Dashboard a salvo 🔥
    BuildContext rootContext = context; 

    Pay? payClient;
    PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
      payClient = Pay({ PayProvider.google_pay: config });
    });
    
    final TextEditingController montoController = TextEditingController(text: initialAmount ?? "");
    double montoIngresado = double.tryParse(initialAmount ?? '0') ?? 0.0;
    bool isProcessing = false;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx); // 🔥 REGLA 1
    final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          // 🔥 FIX 2: Le cambiamos el nombre a modalContext para no confundir a Flutter 🔥
          builder: (BuildContext modalContext, StateSetter setModalState) { 
            return Container(
              decoration: BoxDecoration(
               color: theme.cardColor,
             borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), // 🔥 REGLA 5: Top 24
              ),
              padding: EdgeInsets.only(
               bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),

                 Text("Comprar TTC Tokens", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text("1 USD = 1 TTC", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)), // 🔥 Reemplazamos verde por Primary
              const SizedBox(height: 32),

                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                   style: TextStyle(color: colorScheme.onSurface, fontSize: 36, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.2)),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.green, size: 30),
                      suffixText: "USD",
                     suffixStyle: TextStyle(color: colorScheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
                     filled: true,
                     fillColor: colorScheme.onSurface.withOpacity(0.05),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 REGLA 2: Inputs 16px
                      // enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2))),
                      // focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.green)),
                    ),
                    onChanged: (val) {
                      setModalState(() => montoIngresado = double.tryParse(val) ?? 0);
                    },
                  ),
                  const SizedBox(height: 30),

                  // 🔵 BOTÓN PAYPAL
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 REGLA 2
                    disabledBackgroundColor: Colors.indigo.withOpacity(0.3),
                      ),
                      icon:isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.paypal, color: Colors.white),
                      label: Text(
                       isProcessing ? "Procesando..." : (montoIngresado > 0 ? "Pagar \$${montoIngresado.toStringAsFixed(2)} con PayPal" : "Ingresa un monto"),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                     onPressed: (montoIngresado <= 0 || isProcessing) ? null : () async { 
                        setModalState(() => isProcessing = true); 

                        showDialog(context: rootContext, barrierDismissible: false, builder: (_) => TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella para comprar."));

                        HapticFeedback.mediumImpact();
                        
                        bool isAuth = await authCore.authenticateUser();

                       // Navigator.pop(rootContext);
                        
                        if (!isAuth) {
                          setModalState(() => isProcessing = false); 
                          Navigator.pop(rootContext);
                          mostrarMensaje("Autenticación cancelada", esError: true);
                          return;
                        }

                        Navigator.pop(rootContext); // Quita huella
                        Navigator.pop(ctx); // Cierra modal inferior

                        showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Conectando", message: "Abriendo pasarela segura..."));

                        String amountStr = montoIngresado.toStringAsFixed(2);
                        
                        // 🔥 FIX 1: Cerramos el BottomSheet ANTES de abrir PayPal
                        Navigator.pop(rootContext);
                        
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
                              // onSuccess: (Map params) {
                              //   // 🔥 FIX 2: NO hacemos "pop" aquí. Dejamos que PayPal se cierre solo.
                              //   // Esperamos 500ms a que termine su animación y luego ejecutamos la magia.
                              //   Future.delayed(const Duration(milliseconds: 500), () async {
                                  
                              //     // Mostramos carga en el Dashboard
                              //     showDialog(context: rootContext, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)));

                              //     String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
                              //     final res = await service.buyTokensFiat(orderId, montoIngresado);
                                  
                              //     // Quitamos la carga
                              //     Navigator.pop(rootContext);

                              //     if (res.startsWith("Error")) {
                              //       mostrarMensaje(res, esError: true);
                              //     } else {
                              //       Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                              //         service: service, 
                              //         customTitle: "Compra Exitosa", 
                              //         customMessage: "Acreditando tus fondos en la Blockchain...",
                              //         onUpdateBalance: onUpdateBalance 
                              //       )));
                              //     }
                              //   });
                              // },
                              onSuccess: (Map params) {
                                Future.delayed(const Duration(milliseconds: 500), () async {
                                  
                                  // 🔥 FIX 1: Abrimos la pantalla de espera PRIMERO para que escuche a la blockchain
                                 Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(customTitle: "Compra Exitosa", customMessage: "Acreditando tus fondos en la Blockchain...", isGroupPayment: isGroupPayment, onUpdateBalance: onUpdateBalance 
                                  )));

                                  // 🔥 FIX 2: LUEGO llamamos a Spring Boot
                                  String orderId = params['paymentId'] ?? "PAYPAL-ORDER"; 
                                  final res = await txService.buyTokensFiat(orderId, montoIngresado);

                                  // 🔥 FIX 3: Si Spring Boot falla, cerramos la pantalla y mostramos el error
                                 if (res.startsWith("Error")) {
                                    Navigator.pop(rootContext); 
                                    mostrarMensaje(res, esError: true);
                                  }
                                });
                              },
                              onError: (error) => mostrarMensaje("Error al procesar el pago", esError: true),
                              onCancel: (params) => mostrarMensaje("Pago cancelado por el usuario", esError: true),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
// 🟢 BOTÓN GOOGLE PAY CON MODO "FALLBACK / SIMULADOR"
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: montoIngresado > 0 ? colorScheme.onSurface.withOpacity(0.3) : colorScheme.onSurface.withOpacity(0.1), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                     icon: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2)) : Icon(Icons.g_mobiledata, color: montoIngresado > 0 ? Colors.blueAccent : Colors.white24, size: 36),
                      label: Text(
                        isProcessing ? "Procesando..." : "Pagar con Google Pay",
                        style: TextStyle(color: montoIngresado > 0 ? Colors.blueAccent : Colors.white24, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      onPressed: (montoIngresado <= 0 || isProcessing) ? null : () async { // 🔥 FIX: Bloqueo
                        setModalState(() => isProcessing = true);

                      showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella para comprar."));
                        bool isAuth = await authCore.authenticateUser();

                        //Navigator.pop(rootContext);

                        HapticFeedback.mediumImpact();

                        if (!isAuth) {
                          Navigator.pop(rootContext);
                          setModalState(() => isProcessing = false);
                          mostrarMensaje("Autenticación cancelada", esError: true);
                          return;
                        }

                       Navigator.pop(rootContext); 
                        Navigator.pop(ctx);

                        showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Conectando", message: "Cargando servicios de Google..."));

                        if (payClient == null) {
                          Navigator.pop(rootContext);
                          mostrarMensaje("Cargando servicios de Google, intenta de nuevo.", esError: true);
                          return;
                        }
                        
                        // 🔥 INICIO DEL FLUJO HÍBRIDO (REAL / SIMULADOR) 🔥
                        try {
                          // 1. Intentamos abrir la pasarela real de Google Pay
                          final result = await payClient!.showPaymentSelector(
                            PayProvider.google_pay, 
                            [ PaymentItem(label: 'TTC Tokens', amount: montoIngresado.toStringAsFixed(2), status: PaymentItemStatus.final_price) ],
                          );
                        } catch (e) {
                          // 2. 🔥 SI FALLA (Por falta de Wallet en el Emulador), ATRAPAMOS EL ERROR Y SIMULAMOS 🔥
                          print("Error nativo de GPay atrapado: $e");
                          mostrarMensaje("Billetera inactiva. Usando modo simulador de pago...");
                          await Future.delayed(const Duration(seconds: 2)); 
                          // No ponemos 'return' aquí para que el código siga avanzando hacia el backend
                        }

                        

                        try {
                          Navigator.pop(rootContext);
                          // ---> 3. FLUJO COMÚN (Para pagos Reales o Simulados) <---
                          // Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                          //   service: service, 
                          //   customTitle: "Minando Tokens", 
                          //   customMessage: "Acreditando tus fondos en la Blockchain...",
                          //   isGroupPayment: isGroupPayment,
                          //   onUpdateBalance: onUpdateBalance // 🔥 FIX: Pasa la recarga al Dashboard
                          // )));

                          // showDialog(
                          //   context: rootContext,
                          //   barrierDismissible: false,
                          //   builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                          // );

                          Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(customTitle: "Minando Tokens", customMessage: "Acreditando tus fondos en la Blockchain...", isGroupPayment: isGroupPayment, onUpdateBalance: onUpdateBalance 
                        )));
                          String orderId = "GPAY-${DateTime.now().millisecondsSinceEpoch}"; 
                          final res = await txService.buyTokensFiat(orderId, montoIngresado);

                          Navigator.pop(rootContext);
                          
                        if (res.startsWith("Error")) {
                            mostrarMensaje(res, esError: true);
                          } else {
                            Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                              customTitle: "Minando Tokens", 
                              customMessage: "Acreditando tus fondos en la Blockchain...",
                              isGroupPayment: isGroupPayment,
                              onUpdateBalance: onUpdateBalance 
                            )));
                          }
                        } catch (e) {
                          Navigator.pop(rootContext);
                          mostrarMensaje("Error al procesar la orden en el servidor.", esError: true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}