import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/group_payment_details_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';

class GroupPaymentsTab extends StatelessWidget {
  final Future<List<dynamic>>? paymentsFuture;
  final Map<String, dynamic> group;
  final String filtroTipoCobro;
  final String filtroCobros;
  final ValueChanged<String> onFiltroTipoChanged;
  final ValueChanged<String> onFiltroCobroChanged;
  final VoidCallback onRecargar;

  const GroupPaymentsTab({super.key, required this.paymentsFuture, required this.group, required this.filtroTipoCobro, required this.filtroCobros, required this.onFiltroTipoChanged, required this.onFiltroCobroChanged, required this.onRecargar});

  Future<void> _pagarMiParte(BuildContext context, String requestId, double monto, String destino) async {
    final txService = Provider.of<TransactionService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    String balanceStr = await txService.getBalance();
    double balance = double.tryParse(balanceStr) ?? 0.0;

    if (monto > balance) {
      UIHelper.showCustomSnackbar("Saldo insuficiente. Te faltan ${(monto - balance).toStringAsFixed(2)} TTC", isError: true);
      return;
    }

    bool confirm = await UIHelper.mostrarConfirmacion(
      context: context,
      titulo: "Confirmar Pago",
      mensaje: "Tienes $balanceStr TTC en tu billetera.\nVas a pagar tu parte de $monto TTC.\nTe quedarán ${(balance - monto).toStringAsFixed(2)} TTC.\n\n¿Deseas proceder?",
      textoConfirmar: "Pagar mi parte",
    ) ?? false;
    
    if (!confirm) return;

    if (!context.mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Esperando Firma", message: "Autoriza el pago de tu parte con tu huella."));
    
    BigInt amountWei = BigInt.from(monto * 1e18);
    String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: destino, amountWei: amountWei);
    
    if (!context.mounted) return;
    Navigator.pop(context);

    if (signature == null) {
      UIHelper.showCustomSnackbar("Autenticación cancelada", isError: true);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
       recipientAddress: destino, expectedTxType: "SEND", isGroupPayment: true, customTitle: "Saldando Deuda", customMessage: "Enviando tus TTC al contrato inteligente...",
       onUpdateBalance: onRecargar
    )));

    try {
      String result = await txService.sendTokensL2(destino, monto, signature);
      if (result == "Exito") {
        await groupService.confirmGroupPaymentInBackend(requestId, "TX_CONFIRMED");
      } else {
        if (context.mounted) Navigator.pop(context);
        UIHelper.showCustomSnackbar("Error en Blockchain: $result", isError: true);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Error inesperado: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    return FutureBuilder<List<dynamic>>(
      future: paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        List<dynamic> cobros = (snapshot.data ?? []).where((r) => r['status'] != "PENDING_APPROVAL").toList();
        
        List<dynamic> cobrosFiltrados = cobros.where((req) {
          String status = (req['status'] ?? '').toString().toUpperCase();
          bool pasaEstado = true;
          if (filtroCobros == 'Pendientes') pasaEstado = status == 'OPEN' || status == 'PENDING_APPROVAL';
          else if (filtroCobros == 'Completadas') pasaEstado = status == 'COMPLETED';
          else if (filtroCobros == 'Fallidas') pasaEstado = status == 'FAILED' || status == 'REJECTED';

          if (!pasaEstado) return false;

          bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
          if (filtroTipoCobro == 'Divididos' && isVaultPayment) return false;
          if (filtroTipoCobro == 'Bóveda' && !isVaultPayment) return false;
          return true;
        }).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    initialValue: filtroTipoCobro,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: onFiltroTipoChanged,
                    itemBuilder: (BuildContext context) => const [
                      PopupMenuItem<String>(value: 'Todos', child: Text('Todos los tipos')),
                      PopupMenuItem<String>(value: 'Divididos', child: Text('Pagos Divididos')),
                      PopupMenuItem<String>(value: 'Bóveda', child: Text('Pagos de Bóveda')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.1))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_rounded, size: 16, color: onSurface.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text("Tipo", style: TextStyle(color: onSurface.withOpacity(0.8))),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: onSurface.withOpacity(0.7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...['Todos', 'Pendientes', 'Completadas', 'Fallidas'].map((opcion) {
                    bool isSelected = filtroCobros == opcion;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onFiltroCobroChanged(opcion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? Colors.transparent : onSurface.withOpacity(0.2))
                          ),
                          child: Text(opcion, style: TextStyle(color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            Expanded(
              child: cobrosFiltrados.isEmpty 
                ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UIHelper.emptyState(context: context, icon: Icons.receipt_long_rounded, title: "Sin Cobros", message: "No hay cobros o pagos grupales que coincidan con este filtro.")))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    itemCount: cobrosFiltrados.length,
                    itemBuilder: (ctx, i) {
                      var req = cobrosFiltrados[i];
                      bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
                      var miDeuda = (req['debts'] as List?)?.firstWhere((d) => d['walletAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase(), orElse: () => null);
                      
                      if (!isVaultPayment && miDeuda == null) return const SizedBox(); 

                      bool pendiente = miDeuda != null && miDeuda['status'] == "PENDING";
                      bool completado = req['status'] == "COMPLETED";
                      bool fallida = req['status'] == "FAILED" || req['status'] == "REJECTED";

                      Color statusColor = completado ? colorScheme.primary : (fallida ? colorScheme.error : colorScheme.secondary);
                      IconData statusIcon = completado ? Icons.check_rounded : (fallida ? Icons.priority_high_rounded : Icons.schedule_rounded);
                      String montoStr = isVaultPayment ? req['totalAmount'].toString() : miDeuda!['amountOwed'].toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: statusColor.withOpacity(0.2))),
                        child: InkWell(
                          onTap: () => GroupPaymentDetailsModal.show(context: context, req: req, groupName: group['name']),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(statusIcon, color: statusColor, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Text(completado ? "Completada" : (fallida ? "Fallida" : "Pendiente"), style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(completado ? "+ $montoStr TTC" : "$montoStr TTC", style: TextStyle(color: completado ? colorScheme.primary : onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                                    if (pendiente && !fallida) ...[
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary,
                                          minimumSize: const Size(60, 30),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                        ),
                                        onPressed: () => _pagarMiParte(context, req['id'], double.parse(miDeuda!['amountOwed'].toString()), req['destinationAddress']),
                                        child: const Text("Pagar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      )
                                    ]
                                  ],
                                )
                              ],
                            )
                          )
                        )
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}