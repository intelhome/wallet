import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/debt_service.dart';
import '../modals/debt_details_modal.dart';

class DebtsToCollectScreen extends StatefulWidget {
  final List<dynamic> lista;
  final String emptyTitle;
  final String emptyMsg;
  final VoidCallback onRefresh;

  const DebtsToCollectScreen({
    super.key,
    required this.lista,
    required this.emptyTitle,
    required this.emptyMsg,
    required this.onRefresh,
  });

  @override
  State<DebtsToCollectScreen> createState() => _DebtsToCollectScreenState();
}

class _DebtsToCollectScreenState extends State<DebtsToCollectScreen> {
  String _filtroActual = "Todos";

  Widget _buildFiltros() {
    final theme = Theme.of(context);
    final opciones = ["Todos", "Pendientes", "Completadas", "Fallidas"];
    
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
      if (_filtroActual == "Pendientes") return d['status'] == "ACTIVE" || d['status'] == "PENDING_APPROVAL";
      if (_filtroActual == "Completadas") return d['status'] == "COMPLETED";
      if (_filtroActual == "Fallidas") return d['status'] == "REJECTED";
      return true;
    }).toList();
  }

  void _mostrarModalRecordatorio(String debtId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enviar Recordatorio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("¿Cómo deseas notificar al deudor?", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.notifications_active_rounded, color: colorScheme.primary),
                title: const Text("Notificación Push", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Aparecerá en su celular al instante"),
                onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "PUSH"); },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.email_rounded, color: colorScheme.tertiary),
                title: const Text("Correo Electrónico", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Se enviará a su cuenta registrada"),
                onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "EMAIL"); },
              ),
              const Divider(height: 1),
              ListTile(
                // Verde WhatsApp estándar
                leading: const Icon(Icons.wechat_rounded, color: Color(0xFF22C55E)),
                title: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Abre la app de mensajería"),
                onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "WHATSAPP"); },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _enviarRecordatorio(String debtId, String method) async {
    final debtService = Provider.of<DebtService>(context, listen: false);
    UIHelper.showCustomSnackbar("Procesando...", isError: false);
    
    String res = await debtService.sendPaymentReminder(debtId, method);
    
    if (res == "Exito") {
      UIHelper.showCustomSnackbar("Recordatorio enviado con éxito por $method.");
    } else if (res.contains("WA_URL:")) {
      // 🔥 FIX: Atrapamos la URL del backend y abrimos WhatsApp
      String urlString = res.split("WA_URL:")[1].trim();
      final Uri url = Uri.parse(urlString);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        UIHelper.showCustomSnackbar("No se pudo abrir WhatsApp.", isError: true);
      }
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
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
            ? UIHelper.emptyState(context: context, icon: Icons.credit_score_rounded, title: widget.emptyTitle, message: widget.emptyMsg)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  var d = lista[i];
                  double total = double.tryParse(d['totalAmount'].toString()) ?? 0;
                  double pagado = double.tryParse(d['paidAmount'].toString()) ?? 0;
                  bool isPending = d['status'] == "PENDING_APPROVAL" || d['status'] == "ACTIVE";
                  bool isCompleted = d['status'] == "COMPLETED";
                  
                  Color statusBg = isCompleted ? const Color(0xFF4361EE) : (isPending ? const Color(0xFFD97706) : Colors.redAccent);
                  String statusText = d['status'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                Expanded(
                                  child: Text(
                                    d['reason'], 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                                    overflow: TextOverflow.ellipsis
                                  )
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("Deudor: ${d['debtorAddress'].toString().substring(0, 10)}...", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Pagado: $pagado / $total TTC", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 14)),
                            
                            // 🔥 Botón de recordar solo visible si la deuda está activa y eres el acreedor
                            if (isPending) ...[
                               const SizedBox(height: 16),
                               SizedBox(
                                 width: double.infinity,
                                 child: OutlinedButton.icon(
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: colorScheme.primary, 
                                     side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                   ),
                                   icon: const Icon(Icons.notifications_active_rounded, size: 18),
                                   label: const Text("Enviar Recordatorio de Pago", style: TextStyle(fontWeight: FontWeight.bold)),
                                   onPressed: () => _mostrarModalRecordatorio(d['id'])
                                 ),
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