import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_pending_screen.dart';

class WithdrawFiatScreen extends StatefulWidget {
  //final BlockchainService service;
  final String balanceTTC;
  final VoidCallback onUpdateBalance;

  const WithdrawFiatScreen({
    super.key, 
    required this.balanceTTC,
    required this.onUpdateBalance
  });

  @override
  State<WithdrawFiatScreen> createState() => _WithdrawFiatScreenState();
}

class _WithdrawFiatScreenState extends State<WithdrawFiatScreen> {

  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  
  String _selectedBank = 'Banco Pichincha';
  final List<String> _bancos = [
    'Banco Pichincha', 
    'Banco de Guayaquil', 
    'Cooperativa JEP', 
    'Banco del Pacífico',
    'Produbanco'
  ];

  double _montoIngresado = 0;
  bool _isProcessing = false;

  // Tasa de conversión simulada (1 TTC = 1 USD)
  double get _montoUSD => _montoIngresado * 1.0; 

  void _ejecutarRetiro() async {
    if (_montoIngresado <= 0 || _accountController.text.length < 8) return;

    // 1. Validación de saldo en vivo
    double saldoActual = double.tryParse(widget.balanceTTC) ?? 0.0;
    if (_montoIngresado > saldoActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo insuficiente para el retiro."), backgroundColor: Colors.red)
      );
      return;
    }

    // 2. Autenticación Biométrica
    bool isAuth = await authCore.authenticateUser();
    if (!isAuth) return;

    setState(() => _isProcessing = true);

    // 3. Pantalla de carga inmersiva
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
      customTitle: "Procesando Retiro", 
      customMessage: "Conectando con la red SPI del Banco Central...\nTransfiriendo a $_selectedBank.",
      recipientAddress: "Cta: ${_accountController.text.replaceRange(0, _accountController.text.length - 4, "**** ")}", 
      expectedTxType: "WITHDRAW", 
      onUpdateBalance: widget.onUpdateBalance 
    )));

    // 4. Ejecución del servicio
    final res = await txService.withdrawToBank(_montoIngresado, _selectedBank, _accountController.text);
    
    if (res != "SUCCESS") {
      if (!mounted) return;
      Navigator.pop(context); // Cerramos pantalla de carga
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Retirar a Banco Local"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA DE SALDO DISPONIBLE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Saldo Disponible", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      const SizedBox(height: 5),
                      Text("${widget.balanceTTC} TTC", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.account_balance, color: Colors.amber, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // FORMULARIO DE RETIRO
            Text("Detalles de la Transferencia", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Selector de Banco
            DropdownButtonFormField<String>(
              value: _selectedBank,
              dropdownColor: theme.cardColor,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: "Institución Financiera",
                prefixIcon: const Icon(Icons.business),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: _bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBank = val!),
            ),
            const SizedBox(height: 15),

            // Número de Cuenta
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: "Número de Cuenta (Ahorros / Corriente)",
                prefixIcon: const Icon(Icons.numbers),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),

            // Monto a retirar
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
              onChanged: (val) => setState(() => _montoIngresado = double.tryParse(val) ?? 0),
              decoration: InputDecoration(
                labelText: "Monto a Retirar (TTC)",
                prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
                filled: true,
                fillColor: onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),

            // CONVERSOR VISUAL
            if (_montoIngresado > 0) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Recibirás en tu cuenta:\n\$${_montoUSD.toStringAsFixed(2)} USD",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // BOTÓN EJECUTAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.send_to_mobile, color: Colors.white),
                label: const Text("Confirmar Retiro al Banco", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _isProcessing ? null : _ejecutarRetiro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}