import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/request_group_payment_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';

class GroupHelpsTab extends StatelessWidget {
  final Future<List<dynamic>>? ayudaFuture;
  final Map<String, dynamic> group;
  final String miEstado;
  final double saldoGrupo;
  final String filtroAyudas;
  final ValueChanged<String> onFiltroAyudasChanged;
  final VoidCallback onRecargar;

  const GroupHelpsTab({
    super.key,
    required this.ayudaFuture,
    required this.group,
    required this.miEstado,
    required this.saldoGrupo,
    required this.filtroAyudas,
    required this.onFiltroAyudasChanged,
    required this.onRecargar,
  });

  void _mostrarOpcionesAporteAyuda(BuildContext context, dynamic ayuda) {
    double meta = double.tryParse(ayuda['requestedAmount'].toString()) ?? 0;
    double recaudado = double.tryParse(ayuda['raisedAmount'].toString()) ?? 0;
    double restante = meta - recaudado;
    if (restante <= 0) return;

    final TextEditingController amountController = TextEditingController(text: restante.toString());
    double montoIngresado = restante;
    
    final txService = Provider.of<TransactionService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalCtx) {
        final theme = Theme.of(modalCtx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;
        
        return StatefulBuilder(
          builder: (BuildContext innerCtx, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(innerCtx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Aportar a La Ayuda", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                      IconButton(icon: Icon(Icons.close, color: onSurface.withOpacity(0.7)), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Faltan $restante TTC para completar la meta.", style: TextStyle(color: colorScheme.tertiary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      labelText: "¿Cuánto deseas aportar? (TTC)",
                      labelStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.monetization_on_rounded, color: colorScheme.primary),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => montoIngresado = double.tryParse(val) ?? 0.0,
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: colorScheme.primary),
                            foregroundColor: colorScheme.primary
                          ),
                          icon: const Icon(Icons.account_balance_wallet_rounded),
                          label: const Text("Mis TTC", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            if (montoIngresado <= 0 || montoIngresado > restante) {
                              UIHelper.showCustomSnackbar("Monto inválido. Máximo $restante TTC", isError: true);
                              return;
                            }
                            
                            Navigator.pop(modalCtx); 
                            await Future.delayed(const Duration(milliseconds: 100));

                            String miSaldo = await txService.getBalance();
                            if (!context.mounted) return;
                            
                            SendModal.show(
                              context: context,  
                              balanceTTC: miSaldo, 
                              initialAddress: ayuda['creditorAddress'],
                              initialAmount: montoIngresado.toString(),
                              sharedDebtId: ayuda['id'],
                              isGroupPayment: true,
                              onUpdateBalance: onRecargar, 
                              mostrarMensaje: (msg, {bool esError = false}) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? colorScheme.error : colorScheme.primary));
                              }
                            );
                          }
                        )
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary, 
                            foregroundColor: colorScheme.onPrimary, 
                            padding: const EdgeInsets.symmetric(vertical: 16), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0
                          ),
                          icon: const Icon(Icons.diversity_3_rounded),
                          label: const Text("Usar Bóveda", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            if (montoIngresado <= 0 || montoIngresado > restante) {
                              UIHelper.showCustomSnackbar("Monto inválido.", isError: true);
                              return;
                            }
                            
                            if (miEstado != "CREATOR") {
                              UIHelper.showCustomSnackbar("Solo el administrador puede autorizar fondos de la bóveda.", isError: true);
                              return;
                            }

                            Navigator.pop(modalCtx); 
                            
                            RequestGroupPaymentModal.show(
                              context: context, 
                              groupId: group['id'], 
                              isCreator: true,
                              saldoGrupo: saldoGrupo,
                              customTitle: "Pagar Ayuda con Bóveda",
                              initialDesc: "Aporte: ${ayuda['reason']}",
                              initialDest: ayuda['creditorAddress'],
                              initialAmount: montoIngresado.toString(),
                              lockDest: true,
                              forceVault: true,
                              sharedDebtId: ayuda['id'],
                              onSuccess: onRecargar
                            );
                          }
                        )
                      ),
                    ]
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    return FutureBuilder<List<dynamic>>(
      future: ayudaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No hay nadie pidiendo ayuda.", style: TextStyle(color: onSurface.withOpacity(0.5))));
        
        List<dynamic> ayudasFiltradas = snapshot.data!.where((ayuda) {
          String status = (ayuda['status'] ?? '').toString().toUpperCase();
          if (filtroAyudas == 'Todos') return true;
          if (filtroAyudas == 'Pendientes de aprobar') return status == 'PENDING_VOTE';
          if (filtroAyudas == 'Aprobados') return status == 'APPROVED';
          if (filtroAyudas == 'Pendientes') return status == 'FUNDING';
          if (filtroAyudas == 'Completados') return status == 'COMPLETED';
          if (filtroAyudas == 'Fallidos') return status == 'FAILED' || status == 'REJECTED';
          return true;
        }).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['Todos', 'Pendientes de aprobar', 'Aprobados', 'Pendientes', 'Completados', 'Fallidos'].map((opcion) {
                  bool isSelected = filtroAyudas == opcion;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onFiltroAyudasChanged(opcion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isSelected ? Colors.transparent : onSurface.withOpacity(0.1)),
                        ),
                        child: Text(
                          opcion, 
                          style: TextStyle(
                            color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.8), 
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                            fontSize: 13
                          )
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: ayudasFiltradas.isEmpty 
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(), 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20), 
                        child: UIHelper.emptyState(context: context, icon: Icons.volunteer_activism_rounded, title: "Sin Ayudas", message: "No hay solicitudes de ayuda con este estado.")
                      )
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: ayudasFiltradas.length,
                      itemBuilder: (ctx, i) {
                        var ayuda = ayudasFiltradas[i];
                        double meta = double.tryParse(ayuda['requestedAmount'].toString()) ?? 0;
                        double recaudado = double.tryParse(ayuda['raisedAmount'].toString()) ?? 0;
                        double progreso = meta > 0 ? (recaudado / meta) : 0;
                        
                        bool isPendingVote = ayuda['status'] == "PENDING_VOTE";
                        bool isFunding = ayuda['status'] == "FUNDING";
                        bool isCompleted = ayuda['status'] == "COMPLETED";
                        
                        List<dynamic> votos = ayuda['groupApprovals'] ?? [];
                        bool yaVote = votos.contains(authCore.publicAddress.toLowerCase());

                        String shortAddress = ayuda['debtorAddress'].toString();
                        shortAddress = shortAddress.length > 10 ? "${shortAddress.substring(0,8)}...${shortAddress.substring(shortAddress.length-4)}" : shortAddress;
                        
                        Color statusColor = isCompleted ? colorScheme.primary : colorScheme.secondary;
                        String statusText = isCompleted ? "COMPLETADO" : (isPendingVote ? "VOTACIÓN" : "PENDIENTE");
                        Color progressColor = isCompleted ? colorScheme.primary : colorScheme.tertiary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: onSurface.withOpacity(0.08)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isFunding ? () => _mostrarOpcionesAporteAyuda(context, ayuda) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.tertiary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: colorScheme.tertiary.withOpacity(0.3))
                                        ),
                                        child: Icon(Icons.campaign_rounded, color: colorScheme.tertiary, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(ayuda['reason'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Text("Solicitado por $shortAddress", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progreso,
                                      backgroundColor: onSurface.withOpacity(0.05),
                                      color: progressColor,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("${recaudado.toStringAsFixed(1)} TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface)),
                                      Text("Meta: ${meta.toStringAsFixed(1)} TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface.withOpacity(0.7))),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  if (isCompleted)
                                    Center(child: Text("Meta alcanzada. El grupo completó la ayuda.", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 13)))
                                  else if (isFunding)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "Aportar ahora", 
                                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)
                                      ),
                                    )
                                  else if (isPendingVote)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: yaVote ? onSurface.withOpacity(0.1) : colorScheme.primary,
                                          foregroundColor: yaVote ? onSurface.withOpacity(0.5) : colorScheme.onPrimary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 12)
                                        ),
                                        onPressed: yaVote ? null : () async {
                                          showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu voto para ayudar."));
                                          bool auth = await authCore.authenticateUser();
                                          if (context.mounted) Navigator.pop(context);
                                          if (!auth) return;
                                          if (context.mounted) {
                                            showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando Voto", message: "Registrando en la DAO..."));
                                          }
                                          String res = await debtService.voteToHelpSharedDebt(ayuda['id']);
                                          if (context.mounted) Navigator.pop(context); 
                                          if (res == "Exito") { onRecargar(); } else { UIHelper.showCustomSnackbar("Error al votar: $res", isError: true); }
                                        },
                                        icon: const Icon(Icons.how_to_vote_rounded, size: 18), 
                                        label: Text(yaVote ? "Voto registrado" : "Aprobar ayuda", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
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