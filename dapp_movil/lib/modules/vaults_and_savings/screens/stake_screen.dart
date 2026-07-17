import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';

class StakeScreen extends StatefulWidget {
  final String balanceTTC;
  final String stakedTTC;
  final VoidCallback onUpdateBalance;
  final void Function(String, {bool esError}) mostrarMensaje;
  final String? initialAmount;
  final bool isGroupMode;
  final String? groupId;
  final String? vaultAddress;

  const StakeScreen({
    super.key,
    required this.balanceTTC,
    required this.stakedTTC,
    required this.onUpdateBalance,
    required this.mostrarMensaje,
    this.initialAmount,
    this.isGroupMode = false,
    this.groupId,
    this.vaultAddress,
  });

  @override
  State<StakeScreen> createState() => _StakeScreenState();
}

class _StakeScreenState extends State<StakeScreen> {
  late TextEditingController _montoController;
  double _montoIngresado = 0.0;
  
  bool _isProcessingStake = false;
  bool _isProcessingUnstake = false;

  late double _saldoActualTTC;
  late double _saldoActualStaked;
  double _montoPendiente = 0;
  int _unlockTimestamp = 0;
  String _tiempoRestanteTexto = "Calculando...";

  bool _inicializado = false;
  Timer? _countdownTimer;
  IOWebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.initialAmount ?? "");
    _montoIngresado = double.tryParse(widget.initialAmount ?? '0') ?? 0.0;
    _saldoActualTTC = double.tryParse(widget.balanceTTC) ?? 0.0;
    _saldoActualStaked = double.tryParse(widget.stakedTTC) ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_inicializado) {
        _inicializado = true;
        _cargarDatosEnVivo();

        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) => _actualizarReloj());

        final authCore = Provider.of<AuthCoreService>(context, listen: false);
        String wsAddress = (widget.isGroupMode && widget.vaultAddress != null) ? widget.vaultAddress! : authCore.publicAddress;
        try {
          _wsChannel = IOWebSocketChannel.connect(
            Uri.parse("${ApiConfig.wsTransactionsUpdates}/${wsAddress.toLowerCase()}"),
            headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
          );
          _wsChannel!.stream.listen((message) {
            if (message == "COMPLETED" || message == "UPDATE") {
              _cargarDatosEnVivo();
            }
          });
        } catch (e) {}
      }
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _countdownTimer?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _cargarDatosEnVivo() async {
    final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    try {
      final pendingData = (widget.isGroupMode && widget.vaultAddress != null)
          ? await vaultService.getAnyPendingWithdrawal(widget.vaultAddress!)
          : await vaultService.getPendingWithdrawal();
      
      final stakeData = (widget.isGroupMode && widget.vaultAddress != null)
          ? await vaultService.getAnyStakedBalance(widget.vaultAddress!)
          : await vaultService.getStakedBalance();

      final balanceData = (widget.isGroupMode && widget.vaultAddress != null)
          ? (await groupService.getAnyWalletBalance(widget.vaultAddress!)).toString()
          : await txService.getBalance();

      if (mounted) {
        setState(() {
          _montoPendiente = (pendingData['amount'] as num).toDouble();
          _unlockTimestamp = pendingData['unlockTime'] as int;
          _saldoActualStaked = double.tryParse(stakeData) ?? 0.0;
          _saldoActualTTC = double.tryParse(balanceData) ?? 0.0;
        });
        widget.onUpdateBalance();
      }
    } catch (e) {
      debugPrint("Error cargando datos en vivo: $e");
    }
  }

  void _actualizarReloj() {
    int ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int dif = _unlockTimestamp - ahora;
    if (dif <= 0) {
      if (_tiempoRestanteTexto != "LISTO") setState(() => _tiempoRestanteTexto = "LISTO");
    } else {
      Duration dur = Duration(seconds: dif);
      String hours = dur.inHours.toString().padLeft(2, '0');
      String minutes = (dur.inMinutes.remainder(60)).toString().padLeft(2, '0');
      String seconds = (dur.inSeconds.remainder(60)).toString().padLeft(2, '0');
      setState(() => _tiempoRestanteTexto = "$hours:$minutes:$seconds");
    }
  }

Future<void> _handleStake() async {
    HapticFeedback.mediumImpact();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);
    
    // 🔥 FIX 1: Pedir biometría antes de generar la firma
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Verifica tu identidad para bloquear los fondos."));
    bool isAuth = await authCore.authenticateUser();
    Navigator.pop(context); // Cierra el skeleton

    if (!isAuth) {
      widget.mostrarMensaje("Autenticación cancelada", esError: true);
      return;
    }

    BigInt amountWei = BigInt.from(_montoIngresado * 1e18);
    String? signature = await authCore.generateDelegatedSignature("STAKE", amountWei: amountWei);
    if (signature == null) { widget.mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

    setState(() => _isProcessingStake = true);

    if (widget.isGroupMode && widget.groupId != null) {
      String res = await groupService.proposeGroupDeFiAction(widget.groupId!, "stake", amount: _montoIngresado);
      if (res == "SUCCESS") {
        widget.mostrarMensaje("Propuesta de Staking enviada al grupo");
        widget.onUpdateBalance();
      } else {
        widget.mostrarMensaje(res, esError: true);
      }
      setState(() => _isProcessingStake = false);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
        customTitle: "Iniciando Staking", customMessage: "Bloqueando fondos en el contrato inteligente...", expectedTxType: "STAKE", onUpdateBalance: widget.onUpdateBalance
      )));
      final res = await vaultService.stakeTokensL2(_montoIngresado, signature);
      if (res.startsWith("Error")) { 
        if (mounted) {
          setState(() => _isProcessingStake = false);
          // Navigator.pop(context);  <-- Nota: Comentado o ajustado si el pushReplacement ya destruyó el contexto
        }
        widget.mostrarMensaje(res, esError: true); 
      }
    }
  }

  Future<void> _handleUnstake() async {
    HapticFeedback.mediumImpact();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    String? signature = await authCore.generateDelegatedSignature("UNSTAKE");
    if (signature == null) { widget.mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

    setState(() => _isProcessingUnstake = true);

    if (widget.isGroupMode && widget.groupId != null) {
      String res = await groupService.proposeGroupDeFiAction(widget.groupId!, "unstake");
      if (res == "SUCCESS") {
        widget.mostrarMensaje("Propuesta de Desvinculación enviada al grupo");
        widget.onUpdateBalance();
      } else {
        widget.mostrarMensaje(res, esError: true);
      }
      setState(() => _isProcessingUnstake = false);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
        customTitle: "Retiro Solicitado", customMessage: "Moviendo fondos al período de espera seguro...", expectedTxType: "UNSTAKE", onUpdateBalance: widget.onUpdateBalance
      )));
      final res = await vaultService.unstakeTokensL2(signature);
      if (res.startsWith("Error")) { 
        if (mounted) {
          setState(() => _isProcessingUnstake = false);
          Navigator.pop(context); 
        }
        widget.mostrarMensaje(res, esError: true); 
      }
    }
  }

Future<void> _handleWithdraw() async {
    HapticFeedback.mediumImpact();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    // 🔥 FIX 3: Pedir biometría para Completar Retiro
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Verifica tu identidad para completar el retiro."));
    bool isAuth = await authCore.authenticateUser();
    Navigator.pop(context);

    if (!isAuth) {
      widget.mostrarMensaje("Autenticación cancelada", esError: true);
      return;
    }

    String? signature = await authCore.generateDelegatedSignature("WITHDRAW");
    if (signature == null) { widget.mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

    setState(() => _isProcessingUnstake = true);

    if (widget.isGroupMode && widget.groupId != null) {
      String res = await groupService.proposeGroupDeFiAction(widget.groupId!, "withdraw");
      if (res == "SUCCESS") {
        widget.mostrarMensaje("Propuesta de retiro enviada al grupo");
        widget.onUpdateBalance();
      } else {
        widget.mostrarMensaje(res, esError: true);
      }
      setState(() => _isProcessingUnstake = false);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
        customTitle: "Completando Retiro", customMessage: "Moviendo fondos a tu billetera principal...", expectedTxType: "WITHDRAW", onUpdateBalance: widget.onUpdateBalance 
      )));
      final res = await vaultService.withdrawTokensL2(signature);
      if (res.startsWith("Error")) { 
        if (mounted) {
          setState(() => _isProcessingUnstake = false);
        }
        widget.mostrarMensaje(res, esError: true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;

    bool saldoInsuficiente = _montoIngresado > _saldoActualTTC;
    bool yaTieneStake = _saldoActualStaked > 0;
    bool noTieneStake = _saldoActualStaked <= 0;
    bool isAnyProcessing = _isProcessingStake || _isProcessingUnstake;
    bool tieneRetiroPendiente = _montoPendiente > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Minería PoS", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gradient Card (TTC EN STAKE)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A49D3), Color(0xFF9016CD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TTC EN STAKE", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.trending_up, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text("8.5% APY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_saldoActualStaked.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1.1)),
                            const SizedBox(width: 8),
                            Text("TTC", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Progreso de Época", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                            const Text("75%", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: Colors.black.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.redeem, size: 18, color: Colors.orangeAccent),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Intereses Acumulados", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12, height: 1.1))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text("1,402.50", style: TextStyle(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text("~ \$1,204.00", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 18, color: const Color(0xFFB5C0FF)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Próxima Liquidación", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12, height: 1.1))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text("14h 22m", style: TextStyle(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text("Época #442", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Cantidad a\nbloquear", style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 14)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Saldo\nDisponible:", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                            Text("${_saldoActualTTC.toStringAsFixed(0)}\nTTC", style: TextStyle(color: onSurfaceColor, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: onSurfaceColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _montoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: onSurfaceColor, fontSize: 32, fontWeight: FontWeight.w900),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: "0.00",
                                  ),
                                  enabled: !yaTieneStake && !isAnyProcessing && !tieneRetiroPendiente,
                                  onChanged: (val) {
                                    setState(() => _montoIngresado = double.tryParse(val) ?? 0);
                                  },
                                ),
                              ),
                              Text("TTC", style: TextStyle(color: onSurfaceColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: (yaTieneStake || isAnyProcessing || tieneRetiroPendiente) ? null : () {
                                  setState(() { 
                                    _montoController.text = _saldoActualTTC.toString(); 
                                    _montoIngresado = _saldoActualTTC; 
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: onSurfaceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text("MAX", style: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.electric_bolt, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text("Transacción Gasless (0.00 Gas)", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (saldoInsuficiente)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text("Supera tu saldo disponible", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (tieneRetiroPendiente)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                      child: Column(
                        children: [
                          Text("Retiro en curso: ${_montoPendiente.toStringAsFixed(4)} TTC", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            _tiempoRestanteTexto == "LISTO" ? "¡Tus fondos ya pueden ser liberados!" : "Disponibles en: $_tiempoRestanteTexto",
                            style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // How it works card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("¿Cómo funciona la Minería PoS?", style: TextStyle(color: onSurfaceColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), shape: BoxShape.circle),
                              child: Icon(Icons.lock_clock, size: 20, color: onSurfaceColor.withOpacity(0.8)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bloqueo Seguro", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("Tus fondos aseguran la red. Puedes retirarlos en cualquier momento sin penalizaciones.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 13, height: 1.3)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), shape: BoxShape.circle),
                              child: Icon(Icons.verified_user, size: 20, color: onSurfaceColor.withOpacity(0.8)), // Note: Placeholder icon, matches styling
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Auditoría Constante", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: Text("Contratos inteligentes auditados por IA.", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 13, height: 1.3))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9016CD),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text("AI-\nAUDITED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: onSurfaceColor.withOpacity(0.05))),
            ),
            child: (tieneRetiroPendiente)
              ? SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _tiempoRestanteTexto == "LISTO" ? Colors.green : Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                    onPressed: (_tiempoRestanteTexto == "LISTO" && !isAnyProcessing) ? () => _handleWithdraw() : null,
                    child: _isProcessingUnstake 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Completar Retiro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB5C0FF),
                            side: const BorderSide(color: Color(0xFFB5C0FF), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: (isAnyProcessing || noTieneStake || tieneRetiroPendiente) ? null : () => _handleUnstake(),
                          child: const Text("Reclamar Intereses", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB5C0FF),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            disabledBackgroundColor: const Color(0xFFB5C0FF).withOpacity(0.3),
                          ),
                          onPressed: (_montoIngresado <= 0 || saldoInsuficiente || isAnyProcessing || yaTieneStake || tieneRetiroPendiente) ? null : () => _handleStake(),
                          child: _isProcessingStake 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                            : const Text("Bloquear TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
          )
        ],
      ),
    );
  }
}
