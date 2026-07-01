import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/modals/payment_options_modal.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/subscription_settings_modal.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import 'pagoplux_checkout_screen.dart'; // La crearemos en el siguiente paso

class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({super.key});

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  bool _isLoading = false;
  bool _isAnnual = false; 

  @override
  void initState() {
    super.initState();
    // Refrescamos el estado al abrir la pantalla por si pagó en otro dispositivo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthCoreService>(context, listen: false).refreshTokenAndTier().then((_) => setState(() {}));
    });
  }

  void _iniciarPago(String planName, double amount) {
   
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PagoPluxCheckoutScreen(plan: planName, amount: amount),
      ),
    ).then((pagoExitoso) async {
      // Si el WebView devuelve true, significa que pagó
      if (pagoExitoso == true) {
        setState(() => _isLoading = true);
        // Esperamos 2 segundos para dar tiempo a que el Webhook de Spring Boot procese el pago
        await Future.delayed(const Duration(seconds: 2));
        
        final authCore = Provider.of<AuthCoreService>(context, listen: false);
        await authCore.refreshTokenAndTier(); // Descargamos el nuevo JWT Premium
        
        setState(() => _isLoading = false);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Bienvenido al plan ${authCore.currentTier}!"), backgroundColor: Colors.green)
        );
      }
    });
  }

  Future<void> _pagarConTokens(String planName, double amount, String cycle, bool autoRenew) async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final planService = Provider.of<PlanConfigService>(context, listen: false);
    
    try {
      String treasuryWallet = "0x12915381CFF3a4F710b8F3B6454f2f50A887D0B2"; 
      BigInt amountWei = BigInt.from(amount * 1e18);
      
      String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: treasuryWallet, amountWei: amountWei);
      if (signature == null) return;
      
      Future<dynamic> pendingFuture = Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
          customTitle: "Activando Plan",
          customMessage: "Procesando pago en la Blockchain...",
          recipientAddress: treasuryWallet,
          expectedTxType: "SEND",
          onUpdateBalance: () {} 
      )));
      await Future.delayed(const Duration(milliseconds: 500));
      
      String res = await planService.upgradePlanWithCrypto(authCore, planName, signature, cycle, autoRenew);
      
      if (res == "Exito") {
        Navigator.pop(context, true); 
        await authCore.refreshTokenAndTier(); 
        UIHelper.showCustomSnackbar("¡Felicidades! Ya eres $planName", isError: false);
        setState(() {}); 
      } else {
        Navigator.pop(context, false); 
        UIHelper.showCustomSnackbar("Rechazado: $res", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authCore = Provider.of<AuthCoreService>(context);

    final planService = Provider.of<PlanConfigService>(context);
    
    double basicPrice = planService.getPlanPrice("BASIC");
    double premiumPrice = planService.getPlanPrice("PREMIUM");
    String cycleStr = _isAnnual ? "ANNUAL" : "MONTHLY";
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Planes y Membresías", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (authCore.currentTier != "FREE")
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.purpleAccent),
              tooltip: "Gestionar Suscripción",
              onPressed: () => SubscriptionSettingsModal.show(context),
            )
        ],
      ),
     body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isAnnual = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: !_isAnnual ? Colors.purpleAccent : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                              child: Text("Mensual", style: TextStyle(color: !_isAnnual ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isAnnual = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: _isAnnual ? Colors.purpleAccent : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  Text("Anual", style: TextStyle(color: _isAnnual ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5)), child: const Text("-20%", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              // PLAN FREE
              _buildPlanCard(
                context: context,
                title: "FREE",
                price: "Gratis",
                features: ["Billetera básica", "Límite: \$500/día", "IA: 5 consultas/día"],
                isCurrentPlan: authCore.currentTier == "FREE",
                buttonColor: Colors.grey,
                onTap: null, // No se puede "comprar" lo gratis
              ),
              const SizedBox(height: 20),

            _buildPlanCard(
                context: context,
                title: "BASIC",
             price: _isAnnual ? "\$${basicPrice.toStringAsFixed(2)} / año" : "\$${basicPrice.toStringAsFixed(2)} / mes",
                features: ["Límite: \$2,000/día", "IA Ilimitada", "Notaría: 10 docs/mes"],
                isCurrentPlan: authCore.currentTier == "BASIC",
                buttonColor: Colors.blueAccent,
              onTap: () {
                      PaymentOptionsModal.show(
                        context: context, planName: "BASIC", amount: basicPrice, cycle: cycleStr,
                        onPayWithFiat: (autoRenew) => _iniciarPago("BASIC", basicPrice), // Modifica _iniciarPago si es necesario
                        onPayWithCrypto: (autoRenew) => _pagarConTokens("BASIC", basicPrice, cycleStr, autoRenew),
                      );
                    },
                  ),
              const SizedBox(height: 20),

              // PLAN PREMIUM
            _buildPlanCard(
                context: context,
                title: "PREMIUM",
               price: _isAnnual ? "\$${premiumPrice.toStringAsFixed(2)} / año" : "\$${premiumPrice.toStringAsFixed(2)} / mes",
                features: ["Límites VIP", "Modo TTC Business (POS)", "Notaría Ilimitada", "Soporte Prioritario"],
                isCurrentPlan: authCore.currentTier == "PREMIUM",
                buttonColor: Colors.purpleAccent,
                isHighlight: true,
               onTap: () {
                      PaymentOptionsModal.show(
                        context: context, planName: "PREMIUM", amount: premiumPrice, cycle: cycleStr,
                        onPayWithFiat: (autoRenew) => _iniciarPago("PREMIUM", premiumPrice),
                        onPayWithCrypto: (autoRenew) => _pagarConTokens("PREMIUM", premiumPrice, cycleStr, autoRenew),
                      );
                    },
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context, required String title, required String price, 
    required List<String> features, required bool isCurrentPlan, 
    required Color buttonColor, required VoidCallback? onTap, bool isHighlight = false
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlight ? buttonColor.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHighlight ? buttonColor : colorScheme.onSurface.withOpacity(0.1), width: isHighlight ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(10)),
              child: const Text("RECOMENDADO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isHighlight ? buttonColor : colorScheme.onSurface)),
          const SizedBox(height: 5),
          Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: isHighlight ? buttonColor : Colors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(f, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)))),
            ]),
          )).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: isCurrentPlan
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("Plan Actual", style: TextStyle(fontWeight: FontWeight.bold)),
                )
             : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onTap, // 🔥 FIX: Solo llamamos a onTap
                  child: const Text("Seleccionar Plan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
          )
        ],
      ),
    );
  }
}