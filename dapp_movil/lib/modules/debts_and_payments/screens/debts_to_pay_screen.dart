import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../groups_and_social/services/group_social_service.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../services/debt_service.dart';
import '../modals/debt_details_modal.dart';

class DebtsToPayScreen extends StatefulWidget {
  final List<dynamic> lista;
  final String emptyTitle;
  final String emptyMsg;
  final VoidCallback onRefresh;

  const DebtsToPayScreen({
    super.key,
    required this.lista,
    required this.emptyTitle,
    required this.emptyMsg,
    required this.onRefresh,
  });

  @override
  State<DebtsToPayScreen> createState() => _DebtsToPayScreenState();
}

class _DebtsToPayScreenState extends State<DebtsToPayScreen> {
  String _filtroActual = "Todos";

  Widget _buildFiltros() {
    final theme = Theme.of(context);
    final opciones = ["Todos", "Por Aceptar", "Pendientes", "Pagados"];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: opciones.map((opcion) {
          bool isSelected = _filtroActual == opcion;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _filtroActual = opcion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB5C0FF) : theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  opcion,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<dynamic> get _listaFiltrada {
    return widget.lista.where((d) {
      if (_filtroActual == "Todos") return true;
      if (_filtroActual == "Por Aceptar") return d['status'] == "PENDING_APPROVAL";
      if (_filtroActual == "Pendientes") return d['status'] == "ACTIVE";
      if (_filtroActual == "Pagados") return d['status'] == "COMPLETED";
      return true;
    }).toList();
  }

  Future<void> _responderDeuda(String debtId, bool accept) async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    bool? confirm = await UIHelper.mostrarConfirmacion(
      context: context,
      titulo: accept ? "Aceptar Deuda" : "Rechazar Deuda",
      mensaje: accept ? "¿Confirmas que reconoces esta deuda y te comprometes a pagarla?" : "¿Estás seguro de rechazar este cobro?",
      textoConfirmar: accept ? "Sí, aceptar" : "Rechazar",
      colorConfirmar: accept ? Colors.green : Colors.red,
    );
    
    if (confirm != true || !mounted) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza esta acción."));
    bool auth = await authCore.authenticateUser();
    if (!mounted) return;
    Navigator.pop(context); 

    if (!auth) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando", message: "Actualizando registros..."));
    String res = await debtService.respondDebtRequest(debtId, accept);
    if (mounted) Navigator.pop(context);
    
    if (res == "Exito") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? "Deuda aceptada" : "Deuda rechazada"), backgroundColor: accept ? Colors.green : Colors.orange));
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $res"), backgroundColor: Colors.red));
    }
  }

  Future<void> _compartirDeudaModal(String debtId) async {
    final groupService = Provider.of<GroupSocialService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final debtService = Provider.of<DebtService>(context, listen: false);

    List<dynamic> grupos = await groupService.getUserGroups();
    if (!mounted) return;

    String selectedGroupId = "";
    final TextEditingController reasonController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Pedir ayuda al Grupo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Explica brevemente por qué necesitas ayuda.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(controller: reasonController, decoration: InputDecoration(labelText: "Explicación", prefixIcon: const Icon(Icons.campaign_rounded, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Selecciona tu Grupo", prefixIcon: const Icon(Icons.diversity_3_rounded, color: Colors.deepPurpleAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: grupos.map<DropdownMenuItem<String>>((g) => DropdownMenuItem(value: g['id'], child: Text(g['name']))).toList(),
                  onChanged: (val) => setModalState(() => selectedGroupId = val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: isProcessing ? null : () async {
                    if (selectedGroupId.isEmpty || reasonController.text.isEmpty) return;
                    setModalState(() => isProcessing = true);

                    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu solicitud."));
                    bool auth = await authCore.authenticateUser();
                    if (!mounted) return;
                    Navigator.pop(context); 

                    if (!auth) { setModalState(() => isProcessing = false); return; }

                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                      customTitle: "Enviando Petición", 
                      customMessage: "Notificando a tu grupo...",
                      expectedTxType: "SHARE_DEBT",
                      onUpdateBalance: widget.onRefresh
                    )));

                    String res = await debtService.shareDebtToGroup(debtId, selectedGroupId, reasonController.text);
                    if (mounted) Navigator.pop(context);

                    if (res == "Exito") { 
                      UIHelper.showCustomSnackbar("Solicitud de ayuda enviada al grupo");
                      widget.onRefresh();
                    } else { 
                      UIHelper.showCustomSnackbar(res, isError: true); 
                    }
                  },
                  icon: isProcessing ? const SizedBox() : const Icon(Icons.volunteer_activism_rounded),
                  label: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Pedir ayuda", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    List<dynamic> lista = _listaFiltrada;

    return Column(
      children: [
        _buildFiltros(),
        Expanded(
          child: lista.isEmpty
            ? UIHelper.emptyState(context: context, icon: Icons.credit_card_off_rounded, title: widget.emptyTitle, message: widget.emptyMsg)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var d = lista[i];
                  double total = double.tryParse(d['totalAmount'].toString()) ?? 0;
                  double pagado = double.tryParse(d['paidAmount'].toString()) ?? 0;
                  double restante = total - pagado;
                  bool isPending = d['status'] == "PENDING_APPROVAL";
                  bool isActive = d['status'] == "ACTIVE";
                  bool isCompleted = d['status'] == "COMPLETED";

                  Color statusBg = isCompleted ? const Color(0xFF4361EE) : (isPending ? const Color(0xFFD97706) : colorScheme.primary);
                  String statusText = d['status'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => DebtDetailsModal.show(context: context, debt: d), 
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(d['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("Acreedor: ${d['creditorAddress'].toString().substring(0, 10)}...", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Restante: $restante TTC", style: TextStyle(color: isCompleted ? const Color(0xFFB5C0FF) : const Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 14)),
                            
                            if (isPending) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: OutlinedButton(onPressed: () => _responderDeuda(d['id'], false), child: const Text("Rechazar", style: TextStyle(color: Colors.redAccent)))),
                                  const SizedBox(width: 10),
                                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white), onPressed: () => _responderDeuda(d['id'], true), child: const Text("Aceptar"))),
                                ],
                              )
                            ] else if (isActive) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.groups_rounded, size: 18), label: const Text("Ayuda"), onPressed: () => _compartirDeudaModal(d['id']))),
                                  const SizedBox(width: 10),
                                  Expanded(child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.payment_rounded, size: 18), label: const Text("Pagar"),
                                    onPressed: () async {
                                      final txService = Provider.of<TransactionService>(context, listen: false);
                                      String miSaldo = await txService.getBalance();
                                      if (!mounted) return;
                                      SendModal.show(
                                        context: context, balanceTTC: miSaldo, initialAddress: d['creditorAddress'], debtId: d['id'], onUpdateBalance: widget.onRefresh, 
                                        mostrarMensaje: (msg, {bool esError = false}) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green)); }
                                      );
                                    },
                                  )),
                                ],
                              )
                            ]
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
  }
}