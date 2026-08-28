import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_group_service.dart';

class BusinessGroupMemberDetailsModal {
  static void show(BuildContext context, String groupId, dynamic member, VoidCallback onRefresh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberDetailsContent(groupId: groupId, member: member, onRefresh: onRefresh),
    );
  }
}

class _MemberDetailsContent extends StatefulWidget {
  final String groupId;
  final dynamic member;
  final VoidCallback onRefresh;

  const _MemberDetailsContent({required this.groupId, required this.member, required this.onRefresh});

  @override
  State<_MemberDetailsContent> createState() => _MemberDetailsContentState();
}

class _MemberDetailsContentState extends State<_MemberDetailsContent> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiReport;

  Future<void> _realizarAuditoria() async {
    setState(() {
      _isAnalyzing = true;
      _aiReport = null;
    });

    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final report = await service.auditEmployee(widget.groupId, widget.member['walletAddress']);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _aiReport = report;
      });
      if (report == null) {
        UIHelper.showCustomSnackbar("La IA no pudo completar el análisis.", isError: true);
      } else {
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _aplicarDecision(String taskId, String status, String feedback) async {
    final taskService = Provider.of<BusinessTaskService>(context, listen: false);
    String res = await taskService.updateTaskStatus(taskId, {
      "status": status,
      "feedback": feedback
    });
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Decisión aplicada con éxito.");
      widget.onRefresh();
      setState(() {
        (_aiReport!['evaluations'] as List).removeWhere((e) => e['taskId'] == taskId);
      });
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Detalles del Empleado", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // TARJETA DE PERFIL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
            child: Row(
              children: [
                SmartAvatar(address: widget.member['walletAddress'], size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("@${widget.member['alias'] ?? 'Usuario'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("Billetera: ${widget.member['walletAddress'].toString().substring(0,6)}...", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // BOTÓN AUDITORÍA
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: _isAnalyzing ? null : _realizarAuditoria,
              icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology_rounded),
              label: Text(_isAnalyzing ? "Analizando Patrones..." : "Realizar Auditoría IA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),

          // RESULTADOS DEL REPORTE
          Expanded(
            child: _aiReport == null
                ? Center(child: Text(_isAnalyzing ? "" : "Presiona el botón para auditar las tareas y la carga de trabajo del empleado.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.5))))
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // RESUMEN Y CONSEJOS IA
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.primary.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.insights_rounded, color: colorScheme.primary, size: 24),
                                const SizedBox(width: 10),
                                Text("Resumen de IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_aiReport!['executive_summary'] ?? '', style: TextStyle(color: onSurface.withOpacity(0.9), height: 1.5, fontSize: 14)),
                            const SizedBox(height: 16),
                            Divider(color: colorScheme.primary.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text("💡 Consejo de Carga de Trabajo:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.secondary)),
                            const SizedBox(height: 4),
                            Text(_aiReport!['workload_advice'] ?? '', style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // LISTA DE EVALUACIONES
                      if (_aiReport!['evaluations'] != null && (_aiReport!['evaluations'] as List).isNotEmpty) ...[
                        Text("Acciones en Tareas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                        const SizedBox(height: 16),
                        ...(_aiReport!['evaluations'] as List).map((eval) {
                          bool isApprove = eval['recommended_action'] == 'APPROVED';
                          String taskId = eval['taskId']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ID Tarea: ${taskId.substring(0, 10)}...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.smart_toy_outlined, color: colorScheme.secondary, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.8), height: 1.4),
                                          children: [
                                            TextSpan(text: "Razón: ", style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.secondary, fontWeight: FontWeight.bold)),
                                            TextSpan(text: "${eval['ai_reasoning']}"),
                                          ]
                                        )
                                      )
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: onSurface.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                                  child: Text("\"${eval['employee_feedback']}\"", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: onSurface.withOpacity(0.9))),
                                ),
                                const SizedBox(height: 16),
                                if (isApprove)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                      label: const Text("Aprobar y Pagar", style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () => _aplicarDecision(taskId, eval['recommended_action'], eval['employee_feedback']),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: onSurface.withOpacity(0.8), side: BorderSide(color: onSurface.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: const Text("Rechazar"),
                                          onPressed: () => _aplicarDecision(taskId, 'REJECTED', eval['employee_feedback']), 
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, side: BorderSide(color: colorScheme.error.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: const Text("Revisar"),
                                          onPressed: () => _aplicarDecision(taskId, 'REWORK_REQUESTED', eval['employee_feedback']),
                                        ),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        Center(child: Text("La IA no encontró tareas pendientes de auditoría.", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)))
                      ]
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}