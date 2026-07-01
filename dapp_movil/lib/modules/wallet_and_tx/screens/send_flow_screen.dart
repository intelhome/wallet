import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';
import 'package:flutter_paypal/flutter_paypal.dart';

import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../../debts_and_payments/services/debt_service.dart';
import '../screens/transaction_pending_screen.dart';
import '../modals/transaction_simulator_modal.dart';
import '../modals/transaction_details_modal.dart';
import '../screens/receipt_preview_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../modals/buy_modal.dart';

class SendFlowScreen extends StatefulWidget {
  final String balanceTTC;
  final VoidCallback onUpdateBalance;
  final void Function(String, {bool esError}) mostrarMensaje;
  final String? initialAddress;
  final String? debtId;
  final String? sharedDebtId;

  const SendFlowScreen({
    super.key,
    required this.balanceTTC,
    required this.onUpdateBalance,
    required this.mostrarMensaje,
    this.initialAddress,
    this.debtId,
    this.sharedDebtId,
  });

  @override
  State<SendFlowScreen> createState() => _SendFlowScreenState();
}

class _SendFlowScreenState extends State<SendFlowScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  String _destinationWallet = ""; 

  bool _isOffChain = false; 
  bool _isPaid = false; 
  bool _isProcessingPayment = false;
  
  Pay? _payClient;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarUsuario());
    }

    PaymentConfiguration.fromAsset('gpay_config.json').then((config) {
      _payClient = Pay({PayProvider.google_pay: config});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // ==========================================
  // PASO 1: BÚSQUEDA
  // ==========================================
  Future<void> _buscarUsuario() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    
    final userService = Provider.of<UserService>(context, listen: false);
    
    // BÚSQUEDA POR ALIAS
    if (query.startsWith("@")) {
      String cleanAlias = query.substring(1);
      final result = await userService.searchByAlias(cleanAlias);
      if (result != null) {
        setState(() {
          _foundUser = result;
          _destinationWallet = result['walletAddress'] ?? result['contactAddress'] ?? result['wallet'] ?? "";
          _isOffChain = true; 
        });
        _nextPage();
      } else {
        widget.mostrarMensaje("Usuario no encontrado. Revisa el alias.", esError: true);
      }
    } 
    // BÚSQUEDA POR WALLET DIRECTA ON-CHAIN
    else if (query.startsWith("0x") && query.length == 42) {
      setState(() {
        _foundUser = {
          "alias": "Billetera Externa",
          "walletAddress": query,
          "isExternal": true
        };
        _destinationWallet = query;
        _isOffChain = false; 
      });
      _nextPage();
    } else {
      widget.mostrarMensaje("Formato incorrecto. Usa @alias o una wallet 0x.", esError: true);
    }
    
    setState(() => _isSearching = false);
  }

  // ==========================================
  // VISTAS DEL PAGEVIEW
  // ==========================================

  Widget _buildStep1Search() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Icon(Icons.person_search_rounded, size: 80, color: colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text("¿A quién quieres enviar?", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Busca por @alias para transferencias ultrarrápidas y sin costo de red.", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 40),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Ingresa el @alias o wallet 0x...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.onSurface.withOpacity(0.05),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                onPressed: () async {
                  final scanned = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                  if (scanned != null) {
                    _searchController.text = scanned.trim();
                    _buscarUsuario();
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _buscarUsuario(),
          ),
          
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            onPressed: _isSearching ? null : _buscarUsuario,
            child: _isSearching 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Buscar Usuario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Verify() {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    
    String alias = _foundUser?['alias'] ?? "Desconocido";
    bool isExternal = _foundUser?['isExternal'] == true;

    // 🔥 CAMPOS ENRIQUECIDOS
    String? email = _foundUser?['email'];
    String? phone = _foundUser?['phoneNumber'];
    String? cedula = _foundUser?['cedula'] ?? _foundUser?['identifier'] ?? _foundUser?['ruc'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
              const Spacer(),
            ],
          ),
          SmartAvatar(address: _destinationWallet, size: 80),
          const SizedBox(height: 16),
          Text(isExternal ? "Billetera Externa" : "@$alias", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _isOffChain ? Colors.amber.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _isOffChain ? "⚡ Pago Instantáneo TTC Pay" : "🔗 Transferencia On-Chain",
              style: TextStyle(color: _isOffChain ? Colors.amber[700] : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 30),

          // 🔥 TARJETA DE VERIFICACIÓN DE IDENTIDAD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: onSurface.withOpacity(0.05))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detalles de Seguridad", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _buildVerificationRow(Icons.account_balance_wallet_rounded, "Billetera Pública", _destinationWallet, isMonospace: true),
                if (!isExternal) ...[
                  const Divider(height: 24),
                  _buildVerificationRow(Icons.badge_rounded, "Identificación (Cédula/RUC)", cedula ?? "Oculto por privacidad"),
                  const Divider(height: 24),
                  _buildVerificationRow(Icons.email_rounded, "Correo Electrónico", email ?? "Oculto por privacidad"),
                  const Divider(height: 24),
                  _buildVerificationRow(Icons.phone_rounded, "Teléfono Celular", phone ?? "Oculto por privacidad"),
                ]
              ],
            ),
          ),

          if (isExternal) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Billetera no verificada en el ecosistema TTC. Asegúrate de que la dirección sea correcta, las transacciones blockchain son irreversibles.", style: TextStyle(color: Colors.orange[800], fontSize: 12))),
                ],
              ),
            )
          ],
          
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _prevPage,
                  child: const Text("Volver a Buscar"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _nextPage,
                  child: const Text("Es Correcto", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(IconData icon, String label, String value, {bool isMonospace = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: isMonospace ? 'monospace' : null)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStep3Pay() {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
              Text("Enviar a @${_foundUser?['alias'] ?? 'Wallet'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // CAMPO DE MONTO
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              prefixText: "TTC ",
              filled: true, fillColor: onSurface.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
          Center(child: Padding(padding: const EdgeInsets.only(top: 8), child: Text("Saldo disponible: ${widget.balanceTTC} TTC", style: TextStyle(color: onSurface.withOpacity(0.6))))),
          
          const SizedBox(height: 24),

          // SWITCH COMERCIAL
          Container(
            decoration: BoxDecoration(color: _isPaid ? Colors.green.withOpacity(0.1) : onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isPaid ? Colors.green : Colors.transparent)),
            child: SwitchListTile(
              activeColor: Colors.green,
              title: const Text("Pago Comercial", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Actívalo si estás pagando un producto o servicio.", style: TextStyle(fontSize: 12)),
              value: _isPaid,
              onChanged: (val) => setState(() => _isPaid = val),
            ),
          ),
          
          if (!_isOffChain) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.primary.withOpacity(0.3))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.local_gas_station_rounded, color: colorScheme.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Comisión de Red (Gas)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        Row(children: [Text("0.005 AVAX", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), decoration: TextDecoration.lineThrough)), const SizedBox(width: 6), Text("0.00 TTC", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary))]),
                      ],
                    ),
                  ),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)), child: const Text("Patrocinado", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // BOTÓN PRINCIPAL DE CRYPTO
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOffChain ? colorScheme.secondary : colorScheme.primary,
              foregroundColor: _isOffChain ? colorScheme.onSecondary : colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isProcessingPayment ? null : _ejecutarPagoCrypto,
            child: _isProcessingPayment 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_isOffChain ? "Enviar Instantáneo" : "Firmar Envío Web3", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          if (!_isOffChain) ...[
            const SizedBox(height: 24),
            Row(children: [Expanded(child: Divider(color: onSurface.withOpacity(0.2))), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O PAGA CON FIAT")), Expanded(child: Divider(color: onSurface.withOpacity(0.2)))]),
            const SizedBox(height: 24),

            // BOTONES FIAT
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.g_mobiledata, color: Colors.blueAccent, size: 36),
              label: const Text("Pagar con Google Pay", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _isProcessingPayment ? null : _ejecutarPagoGPay,
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.paypal, color: Colors.white),
              label: const Text("Pagar con PayPal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _isProcessingPayment ? null : _ejecutarPagoPayPal,
            ),
          ]
        ],
      ),
    );
  }

  // ==========================================
  // FUNCIONES DE EJECUCIÓN 
  // ==========================================

  Future<void> _ejecutarPagoCrypto() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;

    double saldoActual = double.tryParse(widget.balanceTTC) ?? 0;
    if (monto > saldoActual) {
      widget.mostrarMensaje("Saldo insuficiente. Adquiere más TTC.", esError: true);
      // Aquí podrías llamar al Upsell Modal si lo deseas.
      return;
    }

    setState(() => _isProcessingPayment = true);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    bool proceedSimulation = await TransactionSimulatorModal.show(
      context: context, amount: monto, destination: _destinationWallet, currentBalance: saldoActual, isOffChain: _isOffChain,
    ) ?? false;

    if (!proceedSimulation) { setState(() => _isProcessingPayment = false); return; }

    String? signature;
    if (_isOffChain) {
      bool isAuth = await authCore.authenticateUser();
      if (!isAuth) { setState(() => _isProcessingPayment = false); return; }
    } else {
      BigInt amountWei = BigInt.from(monto * 1e18);
      signature = await authCore.generateDelegatedSignature("SEND", toAddress: _destinationWallet.toLowerCase(), amountWei: amountWei);
      if (signature == null) { setState(() => _isProcessingPayment = false); return; }
    }

    try {
      String txHash = "0x...";
      String tipoTx = _isOffChain ? 'BINANCE_PAY' : 'SEND';

      Future<dynamic> pendingFuture = Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
          customTitle: _isOffChain ? "Envío Instantáneo" : "Minando Envío", 
          customMessage: "Procesando transacción...", 
          recipientAddress: _destinationWallet, expectedTxType: tipoTx, onUpdateBalance: widget.onUpdateBalance 
      )));

      if (_isOffChain) {
        String aliasBackend = _foundUser!['alias'];
        final res = await txService.sendOffChainAlias(aliasBackend, monto);
        if (res.startsWith("Error")) { Navigator.pop(context); widget.mostrarMensaje(res, esError: true); return; }
        txHash = res.replaceAll("Exito: ", "").trim();
      } else {
        final res = await txService.sendTokensL2(_destinationWallet, monto, signature!);
        if (res.startsWith("Error")) { Navigator.pop(context); widget.mostrarMensaje(res, esError: true); return; }
        txHash = res.replaceAll("Exito: ", "").trim();
      }

      if (widget.debtId != null) await debtService.payPersonalDebt(widget.debtId!, monto, _destinationWallet);
      if (widget.sharedDebtId != null) await debtService.notifySharedDebtContribution(widget.sharedDebtId!, monto);

      final result = await pendingFuture;
      if (result == true) await _manejarFlujoPostPago(tipoTx, monto, txHash);

    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _manejarFlujoPostPago(String tipoTx, double monto, String txHash) async {
    // 🔥 CÓDIGO PARA ELIMINAR EL CACHÉ
    // final cacheService = LocalCacheService();
    // await cacheService.clearDashboardCache();
    // await cacheService.clearTransactionsCache();

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    //final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    dynamic mockTx = {
      'txType': tipoTx, 'amount': monto, 'txHash': txHash, 'senderAddress': authCore.publicAddress,
      'receiverAddress': _destinationWallet, 'status': 'COMPLETED', 'timestamp': DateTime.now().toIso8601String()
    };

    if (_isPaid) {
      bool? verComprobante = await UIHelper.mostrarConfirmacion(
        context: context, titulo: "Pago Exitoso",
        mensaje: "¿Deseas ver el comprobante para compartirlo al comercio?", textoConfirmar: "Ver Comprobante", colorConfirmar: Colors.green,
      );
      if (verComprobante == true) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
      }
      Navigator.pop(context); // Cierra el Flujo
    } else {
      List<dynamic> misContactos = await userService.getUserContacts();
      bool isKnown = misContactos.any((c) => c['contactAddress'].toString().toLowerCase() == _destinationWallet.toLowerCase());
      
      if (!isKnown && _foundUser?['isExternal'] == true) {
        TransactionDetailsModal.mostrarDialogoGuardarContacto(context, context, _destinationWallet, authCore.publicAddress);
      } else {
        UIHelper.showCustomSnackbar("Envío exitoso");
        Navigator.pop(context); // Cierra el Flujo
      }
    }
  }

  Future<void> _ejecutarPagoGPay() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;
    
    // ... Implementa la llamada a _payClient que tenías en SendModal ...
  }

  Future<void> _ejecutarPagoPayPal() async {
    double monto = double.tryParse(_amountController.text) ?? 0;
    if (monto <= 0) return;
    
    // ... Implementa el UsePaypal que tenías en SendModal ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1Search(),
            _buildStep2Verify(),
            _buildStep3Pay(),
          ],
        ),
      ),
    );
  }
}