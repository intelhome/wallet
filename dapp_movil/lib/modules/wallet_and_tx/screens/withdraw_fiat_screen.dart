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
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Retirar a Banco Local", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA DE SALDO DISPONIBLE 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF9D00FF)], // Degradado púrpura de la imagen
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                          const SizedBox(width: 8),
                          Text("Saldo Disponible", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(widget.balanceTTC, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          const Text("TTC", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  // Marca de agua decorativa del banco (opcional pero le da el toque visual)
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Icon(Icons.account_balance_rounded, size: 100, color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Text("Detalles de la Transferencia", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // CONTENEDOR GRUPAL PARA EL FORMULARIO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: onSurface.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INSTITUCIÓN FINANCIERA
                  Text("Institución Financiera", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor, // Fondo oscuro interior
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: onSurface.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: cardColor,
                        value: _selectedBank,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: onSurface.withOpacity(0.6)),
                        style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                        items: _bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setState(() => _selectedBank = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NÚMERO DE CUENTA
                  Text("Número de Cuenta (Ahorros / Corriente)", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Ej: 2200...",
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFBAC3FF))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // MONTO A RETIRAR CON INDICADOR DE GAS
                  Text("Monto a Retirar (TTC)", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                    onChanged: (val) => setState(() => _montoIngresado = double.tryParse(val) ?? 0),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 14),
                        child: Text("\$", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text("0.00 Gas", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFFBAC3FF))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24, left: 24, right: 24, top: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: onSurface.withOpacity(0.05)))
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBAC3FF),
              foregroundColor: const Color(0xFF00218d),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onPressed: _isProcessing ? null : _ejecutarRetiro,
            icon: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00218d)))
                : const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(_isProcessing ? "Procesando..." : "Confirmar Retiro al Banco", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final onSurface = theme.colorScheme.onSurface;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Retirar a Banco Local"),
  //       centerTitle: true,
  //       elevation: 0,
  //     ),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.all(24.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // TARJETA DE SALDO DISPONIBLE
  //           Container(
  //             padding: const EdgeInsets.all(20),
  //             decoration: BoxDecoration(
  //               gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)]),
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
  //             ),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text("Saldo Disponible", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
  //                     const SizedBox(height: 5),
  //                     Text("${widget.balanceTTC} TTC", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
  //                   ],
  //                 ),
  //                 const Icon(Icons.account_balance, color: Colors.amber, size: 40),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 30),

  //           // FORMULARIO DE RETIRO
  //           Text("Detalles de la Transferencia", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 20),

  //           // Selector de Banco
  //           DropdownButtonFormField<String>(
  //             value: _selectedBank,
  //             dropdownColor: theme.cardColor,
  //             style: TextStyle(color: onSurface),
  //             decoration: InputDecoration(
  //               labelText: "Institución Financiera",
  //               prefixIcon: const Icon(Icons.business),
  //               filled: true,
  //               fillColor: onSurface.withOpacity(0.05),
  //               border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
  //             ),
  //             items: _bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
  //             onChanged: (val) => setState(() => _selectedBank = val!),
  //           ),
  //           const SizedBox(height: 15),

  //           // Número de Cuenta
  //           TextField(
  //             controller: _accountController,
  //             keyboardType: TextInputType.number,
  //             style: TextStyle(color: onSurface),
  //             decoration: InputDecoration(
  //               labelText: "Número de Cuenta (Ahorros / Corriente)",
  //               prefixIcon: const Icon(Icons.numbers),
  //               filled: true,
  //               fillColor: onSurface.withOpacity(0.05),
  //               border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
  //             ),
  //           ),
  //           const SizedBox(height: 15),

  //           // Monto a retirar
  //           TextField(
  //             controller: _amountController,
  //             keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //             style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
  //             onChanged: (val) => setState(() => _montoIngresado = double.tryParse(val) ?? 0),
  //             decoration: InputDecoration(
  //               labelText: "Monto a Retirar (TTC)",
  //               prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
  //               filled: true,
  //               fillColor: onSurface.withOpacity(0.05),
  //               border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
  //             ),
  //           ),

  //           // CONVERSOR VISUAL
  //           if (_montoIngresado > 0) ...[
  //             const SizedBox(height: 15),
  //             Container(
  //               padding: const EdgeInsets.all(15),
  //               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
  //               child: Row(
  //                 children: [
  //                   const Icon(Icons.currency_exchange, color: Colors.green),
  //                   const SizedBox(width: 10),
  //                   Expanded(
  //                     child: Text(
  //                       "Recibirás en tu cuenta:\n\$${_montoUSD.toStringAsFixed(2)} USD",
  //                       style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],

  //           const SizedBox(height: 40),

  //           // BOTÓN EJECUTAR
  //           SizedBox(
  //             width: double.infinity,
  //             height: 55,
  //             child: ElevatedButton.icon(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.blueAccent,
  //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //               ),
  //               icon: const Icon(Icons.send_to_mobile, color: Colors.white),
  //               label: const Text("Confirmar Retiro al Banco", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  //               onPressed: _isProcessing ? null : _ejecutarRetiro,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}