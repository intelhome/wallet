import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';

class StakeModal {
  static void show({
    required BuildContext context,
    //required BlockchainService service,
    required String balanceTTC,
    required String stakedTTC,
    required VoidCallback onUpdateBalance,
    required void Function(String, {bool esError}) mostrarMensaje,
    String? initialAmount,
    bool isGroupMode = false,
    String? groupId,
    String? vaultAddress,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final vaultService = Provider.of<SmartVaultService>(context, listen: false);
final txService = Provider.of<TransactionService>(context, listen: false);
final groupService = Provider.of<GroupSocialService>(context, listen: false);

    BuildContext rootContext = context;

    final TextEditingController montoController = TextEditingController(text: initialAmount ?? "");
    double montoIngresado = double.tryParse(initialAmount ?? '0') ?? 0.0;
    bool isProcessingStake = false;
    bool isProcessingUnstake = false;

    // 🔥 FIX 1: Las variables de estado viven FUERA del builder para no resetearse
    double saldoActualTTC = double.tryParse(balanceTTC) ?? 0.0;
    double saldoActualStaked = double.tryParse(stakedTTC) ?? 0.0;
    double montoPendiente = 0;
    int unlockTimestamp = 0;
    String tiempoRestanteTexto = "Calculando...";

    bool inicializado = false;
    Timer? countdownTimer;
    IOWebSocketChannel? wsChannel;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final onSurfaceColor = Theme.of(ctx).colorScheme.onSurface;
        final cardColor = Theme.of(ctx).cardColor;

        return Container(
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {

              // 🔥 FIX 2: Función aislada para leer la blockchain sin romper la UI
              Future<void> cargarDatosEnVivo() async {
                try {
                  final pendingData = (isGroupMode && vaultAddress != null)
                      ? await vaultService.getAnyPendingWithdrawal(vaultAddress!)
                      : await vaultService.getPendingWithdrawal();
                  
                  final stakeData = (isGroupMode && vaultAddress != null)
                      ? await vaultService.getAnyStakedBalance(vaultAddress!)
                      : await vaultService.getStakedBalance();

                  final balanceData = (isGroupMode && vaultAddress != null)
                      ? (await groupService.getAnyWalletBalance(vaultAddress!)).toString()
                      : await txService.getBalance();

                  if (ctx.mounted) {
                    setModalState(() {
                      montoPendiente = (pendingData['amount'] as num).toDouble();
                      unlockTimestamp = pendingData['unlockTime'] as int;
                      saldoActualStaked = double.tryParse(stakeData) ?? 0.0;
                      saldoActualTTC = double.tryParse(balanceData) ?? 0.0;
                    });
                    onUpdateBalance(); // Avisamos a la pantalla de atrás
                  }
                } catch (e) {
                  print("Error cargando datos en vivo: $e");
                }
              }

              void actualizarReloj() {
                int ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                int dif = unlockTimestamp - ahora;
                if (dif <= 0) {
                  if (tiempoRestanteTexto != "LISTO") setModalState(() => tiempoRestanteTexto = "LISTO");
                } else {
                  Duration dur = Duration(seconds: dif);
                  String hours = dur.inHours.toString().padLeft(2, '0');
                  String minutes = (dur.inMinutes.remainder(60)).toString().padLeft(2, '0');
                  String seconds = (dur.inSeconds.remainder(60)).toString().padLeft(2, '0');
                  setModalState(() => tiempoRestanteTexto = "$hours:$minutes:$seconds");
                }
              }

              // 🔥 FIX 3: Inicializamos todo UNA SOLA VEZ al abrir el modal
              if (!inicializado) {
                inicializado = true;
                cargarDatosEnVivo(); // Primera lectura real de la blockchain

                countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) => actualizarReloj());

                String wsAddress = (isGroupMode && vaultAddress != null) ? vaultAddress! : authCore.publicAddress;
                try {
                  wsChannel = IOWebSocketChannel.connect(
                    Uri.parse("${ApiConfig.wsTransactionsUpdates}/${wsAddress.toLowerCase()}"),
                    headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
                  );
                  wsChannel!.stream.listen((message) {
                    // Si la transacción se aprueba o completa, leemos la blockchain de nuevo.
                    if (message == "COMPLETED" || message == "UPDATE") {
                      cargarDatosEnVivo();
                    }
                  });
                } catch (e) {}
              }

              // Lógica de UI dependiente de los saldos actualizados
              bool saldoInsuficiente = montoIngresado > saldoActualTTC;
              double saldoRestante = saldoActualTTC - montoIngresado;
              if (saldoRestante < 0) saldoRestante = 0;
              
              bool yaTieneStake = saldoActualStaked > 0;
              bool noTieneStake = saldoActualStaked <= 0;
              bool isAnyProcessing = isProcessingStake || isProcessingUnstake;
              bool tieneRetiroPendiente = montoPendiente > 0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Minería PoS (Staking)", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurfaceColor)),
                      IconButton(icon: Icon(Icons.close, color: onSurfaceColor.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    yaTieneStake ? "Tienes ${saldoActualStaked.toStringAsFixed(4)} TTC generando recompensas." : "Bloquea tus TTC para generar intereses", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: yaTieneStake ? Colors.green : onSurfaceColor.withOpacity(0.6), fontWeight: yaTieneStake ? FontWeight.bold : FontWeight.normal)
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: montoController,
                    enabled: !yaTieneStake && !isAnyProcessing && !tieneRetiroPendiente,
                    style: TextStyle(color: onSurfaceColor),
                    decoration: InputDecoration(
                      labelText: yaTieneStake ? "Ya tienes un Stake activo" : "Cantidad a bloquear (TTC)",
                      labelStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.lock, color: Colors.deepPurpleAccent),
                      errorText: saldoInsuficiente ? "Supera tu saldo disponible" : null,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.1))),
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                      suffixIcon: TextButton(
                        onPressed: (yaTieneStake || isAnyProcessing || tieneRetiroPendiente) ? null : () {
                          setModalState(() { montoController.text = saldoActualTTC.toString(); montoIngresado = saldoActualTTC; });
                        },
                        child: const Text("MAX", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) { setModalState(() => montoIngresado = double.tryParse(val) ?? 0); },
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Divider(color: onSurfaceColor.withOpacity(0.2), height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Saldo restante:", style: TextStyle(color: onSurfaceColor.withOpacity(0.6))),
                            Text("${saldoRestante.toStringAsFixed(4)} TTC", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (montoPendiente == 0 && saldoActualStaked == 0 && !inicializado) 
                    const Center(child: CircularProgressIndicator())
                  else if (tieneRetiroPendiente) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                      child: Column(
                        children: [
                          Text("Retiro en curso: ${montoPendiente.toStringAsFixed(4)} TTC", style: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            tiempoRestanteTexto == "LISTO" ? "¡Tus fondos ya pueden ser liberados!" : "Disponibles en: $tiempoRestanteTexto",
                            style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: tiempoRestanteTexto == "LISTO" ? Colors.green : Colors.grey, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: (tiempoRestanteTexto == "LISTO" && !isAnyProcessing) ? () async {
                          HapticFeedback.mediumImpact();
                                
                                // bool auth = await authCore.authenticateUser();
                                // if (!auth) { mostrarMensaje("Autenticación requerida", esError: true); return; }

                                // setModalState(() => isProcessingUnstake = true);
                                // Navigator.pop(ctx); 

                                String? signature = await authCore.generateDelegatedSignature("WITHDRAW");
                                if (signature == null) { mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

                                setModalState(() => isProcessingUnstake = true);
                                Navigator.pop(ctx);

                                if (isGroupMode && groupId != null) {
                                  String res = await groupService.proposeGroupDeFiAction(groupId, "withdraw");
                                  if (res == "SUCCESS") {
                                    mostrarMensaje("Propuesta de retiro enviada al grupo");
                                    onUpdateBalance();
                                  } else {
                                    mostrarMensaje(res, esError: true);
                                  }
                                } else {
                                  Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( customTitle: "Completando Retiro", customMessage: "Moviendo fondos a tu billetera principal...", expectedTxType: "WITHDRAW", onUpdateBalance: onUpdateBalance 
                                  )));
                                 // final res = await vaultService.withdrawTokensL2();
                                 final res = await vaultService.withdrawTokensL2(signature);
                                  if (res.startsWith("Error")) { Navigator.pop(rootContext); mostrarMensaje(res, esError: true); }
                                }
                              }
                            : null,
                        child: const Text("Completar Retiro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white60, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: Colors.deepPurple.withOpacity(0.5)),
                            onPressed: (montoIngresado <= 0 || saldoInsuficiente || isAnyProcessing || yaTieneStake || tieneRetiroPendiente)
                                ? null
                                : () async {
                                  HapticFeedback.mediumImpact();
                                    // bool auth = await authCore.authenticateUser();
                                    // if (!auth) { mostrarMensaje("Autenticación requerida", esError: true); return; }

                                    // setModalState(() => isProcessingStake = true);
                                    // Navigator.pop(ctx);

                                    BigInt amountWei = BigInt.from(montoIngresado * 1e18);
                                    String? signature = await authCore.generateDelegatedSignature("STAKE", amountWei: amountWei);
                                    if (signature == null) { mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

                                    setModalState(() => isProcessingStake = true);
                                    Navigator.pop(ctx);

                                  if (isGroupMode && groupId != null) {
                                      String res = await groupService.proposeGroupDeFiAction(groupId, "stake", amount: montoIngresado);
                                      if (res == "SUCCESS") {
                                        // // 🔥 CÓDIGO PARA ELIMINAR EL CACHÉ
                                        // await LocalCacheService().clearDashboardCache();
                                        // await LocalCacheService().clearVaultsCache();

                                        mostrarMensaje("Propuesta de Staking enviada al grupo");
                                        onUpdateBalance();
                                      } else {
                                        mostrarMensaje(res, esError: true);
                                      }
                                    } else {
                                      // Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( customTitle: "Iniciando Staking", customMessage: "Bloqueando fondos en el contrato inteligente...", expectedTxType: "STAKE", onUpdateBalance: onUpdateBalance
                                      // )));
                                      // final res = await vaultService.stakeTokensL2(montoIngresado);
                                      Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( customTitle: "Iniciando Staking", customMessage: "Bloqueando fondos en el contrato inteligente...", expectedTxType: "STAKE", onUpdateBalance: onUpdateBalance
                                      )));
                                      final res = await vaultService.stakeTokensL2(montoIngresado, signature);
                                      if (res.startsWith("Error")) { Navigator.pop(rootContext); mostrarMensaje(res, esError: true); }
                                    }
                                  },
                            child: const Text("Bloquear", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 15),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: Colors.grey.withOpacity(0.5)),
                            onPressed: (isProcessingStake || isProcessingUnstake || isAnyProcessing || noTieneStake || tieneRetiroPendiente)
                                ? null
                                : () async {
                                  HapticFeedback.mediumImpact();
                                    // bool auth = await authCore.authenticateUser();
                                    // if (!auth) { mostrarMensaje("Autenticación requerida", esError: true); return; }

                                    // setModalState(() => isProcessingUnstake = true);
                                    // Navigator.pop(ctx);

                                   String? signature = await authCore.generateDelegatedSignature("UNSTAKE");
                                    if (signature == null) { mostrarMensaje("Autenticación o firma requerida", esError: true); return; }

                                    setModalState(() => isProcessingUnstake = true);
                                    Navigator.pop(ctx);

                                  if (isGroupMode && groupId != null) {
                                      String res = await groupService.proposeGroupDeFiAction(groupId, "unstake");
                                      if (res == "SUCCESS") {
                                        mostrarMensaje("Propuesta de Desvinculación enviada al grupo");
                                        onUpdateBalance();
                                      } else {
                                        mostrarMensaje(res, esError: true);
                                      }
                                    } else {
                                      Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen(customTitle: "Retiro Solicitado", customMessage: "Moviendo fondos al período de espera seguro...", expectedTxType: "UNSTAKE", onUpdateBalance: onUpdateBalance
                                      )));
                                      final res = await vaultService.unstakeTokensL2(signature);
                                      if (res.startsWith("Error")) { Navigator.pop(rootContext); mostrarMensaje(res, esError: true); }
                                    }
                                  },
                            child: const Text("Reclamar Todo", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() { 
      countdownTimer?.cancel(); 
      wsChannel?.sink.close(); 
    });
  }
}