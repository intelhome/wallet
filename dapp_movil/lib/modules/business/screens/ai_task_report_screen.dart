import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/ai_task_admin_handler.dart';
import '../services/business_task_service.dart';

class AiTaskReportScreen extends StatefulWidget {
  final List<dynamic> allTasks;
  final VoidCallback onRefreshBack;

  const AiTaskReportScreen({super.key, required this.allTasks, required this.onRefreshBack});

  @override
  State<AiTaskReportScreen> createState() => _AiTaskReportScreenState();
}

class _AiTaskReportScreenState extends State<AiTaskReportScreen> {
  String _selectedFilter = 'GENERAL';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiReport;

  final List<String> _filtros = [
    'GENERAL', 
    'COMPLETADAS (Auditoría)', 
    'PENDIENTES (Riesgos)', 
    'EN CORRECCIÓN (Análisis)', 
    'CANCELADAS', 
    'EN PROGRESO'
  ];

  Future<void> _ejecutarAnalisisIA() async {
    setState(() {
      _isAnalyzing = true;
      _aiReport = null;
    });

    // Filtramos localmente antes de enviar para ahorrar tokens
    List<dynamic> targetTasks = [];
    if (_selectedFilter.contains('GENERAL')) targetTasks = widget.allTasks;
    else if (_selectedFilter.contains('COMPLETADAS')) targetTasks = widget.allTasks.where((t) => t['status'] == 'COMPLETED').toList();
    else if (_selectedFilter.contains('PENDIENTES')) targetTasks = widget.allTasks.where((t) => t['status'] == 'PENDING').toList();
    else if (_selectedFilter.contains('CORRECCIÓN')) targetTasks = widget.allTasks.where((t) => t['status'] == 'REWORK_REQUESTED').toList();
    else if (_selectedFilter.contains('CANCELADAS')) targetTasks = widget.allTasks.where((t) => t['status'] == 'CANCELLED').toList();
    else if (_selectedFilter.contains('PROGRESO')) targetTasks = widget.allTasks.where((t) => t['status'] == 'IN_PROGRESS').toList();

    if (targetTasks.isEmpty) {
      UIHelper.showCustomSnackbar("No hay tareas en esta categoría para analizar.", isError: true);
      setState(() => _isAnalyzing = false);
      return;
    }

    final reporte = await AiTaskAdminHandler.generarReporteMasivo(context, targetTasks, _selectedFilter);
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _aiReport = reporte;
      });
      if (reporte == null) UIHelper.showCustomSnackbar("La IA no pudo completar el análisis.", isError: true);
      else HapticFeedback.heavyImpact();
    }
  }

  // 🔥 Aplica la decisión de la IA directamente a la base de datos
  Future<void> _aplicarDecisionIA(String taskId, String status, String feedback) async {
    final taskService = Provider.of<BusinessTaskService>(context, listen: false);
    String res = await taskService.updateTaskStatus(taskId, {
      "status": status,
      "feedback": feedback
    });
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Decisión aplicada con éxito.");
      widget.onRefreshBack();
      // Quitamos de la vista
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
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Auditoría Cognitiva IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. SELECTOR DE ENFOQUE
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFilter,
                      items: _filtros.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _selectedFilter = val!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                  onPressed: _isAnalyzing ? null : _ejecutarAnalisisIA,
                  icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                  label: const Text("Analizar"),
                )
              ],
            ),
          ),
          
          // 2. RESULTADOS DEL REPORTE
          Expanded(
            child: _aiReport == null 
              ? Center(
                  child: Text(
                    _isAnalyzing ? "El Agente está auditando el bloque de tareas...\nEsto puede tomar unos segundos." : "Selecciona un filtro y presiona Analizar.",
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)
                  )
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // RESUMEN EJECUTIVO
                    if (_aiReport!['executive_summary'] != null)
                      Card(
                        color: Colors.deepPurpleAccent.withOpacity(0.05),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.2))),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.insights_rounded, color: Colors.deepPurpleAccent), SizedBox(width: 8), Text("Resumen Ejecutivo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))]),
                              const SizedBox(height: 8),
                              Text(_aiReport!['executive_summary'], style: const TextStyle(height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    
                    // ALERTAS (EXPIRACIONES)
                    if (_aiReport!['expiring_warnings'] != null && (_aiReport!['expiring_warnings'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text("⚠️ Alertas Críticas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      const SizedBox(height: 8),
                      ...(_aiReport!['expiring_warnings'] as List).map((w) => Container(
                        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(w.toString(), style: const TextStyle(fontSize: 12, color: Colors.red)),
                      )),
                    ],

                    // EVALUACIONES Y ACCIONES RÁPIDAS
                    if (_aiReport!['evaluations'] != null && (_aiReport!['evaluations'] as List).isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text("Acciones Recomendadas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...(_aiReport!['evaluations'] as List).map((eval) {
                        if (eval['recommended_action'] == 'NONE') return const SizedBox.shrink();
                        
                        bool isApprove = eval['recommended_action'] == 'APPROVED';
                        String taskId = eval['taskId']?.toString() ?? '';
                        // Buscamos el nombre real de la tarea para mostrarlo
                        var originalTask = widget.allTasks.firstWhere((t) => t['id'] == taskId, orElse: () => null);
                        if (originalTask == null) return const SizedBox.shrink();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0, color: theme.scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📌 ${originalTask['title']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text("🕵️ Razonamiento: ${eval['ai_reasoning']}", style: const TextStyle(fontSize: 12, color: Colors.deepPurple, fontStyle: FontStyle.italic)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text("✍️ Feedback pre-escrito:\n\"${eval['employee_feedback']}\"", style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isApprove ? Colors.teal : Colors.orange,
                                      foregroundColor: Colors.white,
                                      elevation: 0
                                    ),
                                    icon: Icon(isApprove ? Icons.verified_rounded : Icons.refresh_rounded),
                                    label: Text(isApprove ? "Aprobar y Pagar (1-Click)" : "Exigir Rework (1-Click)"),
                                    onPressed: () => _aplicarDecisionIA(taskId, eval['recommended_action'], eval['employee_feedback']),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                    ]
                  ],
                ),
          ),
        ],
      ),
    );
  }
}