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
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    int numTareas = _aiReport != null && _aiReport!['evaluations'] != null ? (_aiReport!['evaluations'] as List).length : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("TTC Wallet Pro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: onSurface.withOpacity(0.7)),
            onPressed: () {}, // Configuración futura
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER & CONTROLS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Auditoría Cognitiva IA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface)),
                const SizedBox(height: 4),
                Text("Análisis automatizado de rendimiento y riesgos.", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: onSurface.withOpacity(0.1))
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedFilter,
                            dropdownColor: theme.cardColor,
                            icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                            items: _filtros.map((f) => DropdownMenuItem(
                              value: f, 
                              child: Text(f, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: onSurface))
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedFilter = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4361EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isAnalyzing ? null : _ejecutarAnalisisIA,
                      icon: _isAnalyzing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text("Analizar", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
          
          // 2. RESULTADOS DEL REPORTE
          Expanded(
            child: _aiReport == null 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      _isAnalyzing ? "El Agente está auditando el bloque de tareas...\nEsto puede tomar unos segundos." : "Selecciona un filtro y presiona Analizar para auditar las tareas.",
                      textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.5))
                    ),
                  )
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // RESUMEN EJECUTIVO (TARJETA PÚRPURA OSCURA)
                    if (_aiReport!['executive_summary'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0C3E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7209B7).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.psychology_rounded, color: const Color(0xFFC77DFF), size: 24),
                                const SizedBox(width: 10),
                                Text("Resumen Ejecutivo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFFC77DFF))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(_aiReport!['executive_summary'], style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                     // ALERTAS CRÍTICAS (DE RIESGO)
                    if (_aiReport!['expiring_warnings'] != null && (_aiReport!['expiring_warnings'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                          const SizedBox(width: 10),
                          Text("Alertas Críticas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...(_aiReport!['expiring_warnings'] as List).map((w) => Container(
                        margin: const EdgeInsets.only(bottom: 12), 
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.05), 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.2))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.toString(), style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.9), height: 1.4)),
                            const SizedBox(height: 8),
                            const Text("RIESGO ALTO", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 20),
                    ],
                    
                    // EVALUACIONES Y ACCIONES RÁPIDAS
                    if (_aiReport!['evaluations'] != null && (_aiReport!['evaluations'] as List).isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Acciones Recomendadas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.1))),
                            child: Text("$numTareas Tareas", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.7))),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...(_aiReport!['evaluations'] as List).map((eval) {
                        if (eval['recommended_action'] == 'NONE') return const SizedBox.shrink();
                        
                        bool isApprove = eval['recommended_action'] == 'APPROVED';
                        String taskId = eval['taskId']?.toString() ?? '';
                        var originalTask = widget.allTasks.firstWhere((t) => t['id'] == taskId, orElse: () => null);
                        if (originalTask == null) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: onSurface.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.push_pin_outlined, color: Colors.redAccent.withOpacity(0.8), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text("${originalTask['title']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.smart_toy_outlined, color: const Color(0xFFC77DFF), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.8), height: 1.4),
                                        children: [
                                          TextSpan(text: "Razonamiento: ", style: TextStyle(fontStyle: FontStyle.italic, color: const Color(0xFFC77DFF), fontWeight: FontWeight.w600)),
                                          TextSpan(text: "${eval['ai_reasoning']}"),
                                        ]
                                      )
                                    )
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: onSurface.withOpacity(0.03), 
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: onSurface.withOpacity(0.05))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.format_quote_rounded, color: Colors.orangeAccent, size: 16),
                                        const SizedBox(width: 6),
                                        Text(isApprove ? "FEEDBACK PRE-ESCRITO" : "SUGERENCIA IA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.orangeAccent)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text("\"${eval['employee_feedback']}\"", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: onSurface.withOpacity(0.9))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isApprove)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981), // Verde
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                    label: const Text("Aprobar y Pagar (1-Click)", style: TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () => _aplicarDecisionIA(taskId, eval['recommended_action'], eval['employee_feedback']),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: onSurface.withOpacity(0.8),
                                          side: BorderSide(color: onSurface.withOpacity(0.2)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        child: const Text("Rechazar", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => _aplicarDecisionIA(taskId, 'REJECTED', eval['employee_feedback']), 
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: onSurface.withOpacity(0.8),
                                          side: BorderSide(color: onSurface.withOpacity(0.2)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                        ),
                                        child: const Text("Revisar", style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => _aplicarDecisionIA(taskId, 'REWORK_REQUESTED', eval['employee_feedback']),
                                      ),
                                    ),
                                  ],
                                )
                            ],
                          ),
                        );
                      }),
                    ],

                   
                  ],
                ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
    
  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Auditoría Cognitiva IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       backgroundColor: theme.cardColor,
  //       elevation: 0,
  //     ),
  //     body: Column(
  //       children: [
  //         // 1. SELECTOR DE ENFOQUE
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           color: theme.cardColor,
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: DropdownButtonHideUnderline(
  //                   child: DropdownButton<String>(
  //                     isExpanded: true,
  //                     value: _selectedFilter,
  //                     items: _filtros.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
  //                     onChanged: (val) => setState(() => _selectedFilter = val!),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               ElevatedButton.icon(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
  //                 onPressed: _isAnalyzing ? null : _ejecutarAnalisisIA,
  //                 icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
  //                 label: const Text("Analizar"),
  //               )
  //             ],
  //           ),
  //         ),
          
  //         // 2. RESULTADOS DEL REPORTE
  //         Expanded(
  //           child: _aiReport == null 
  //             ? Center(
  //                 child: Text(
  //                   _isAnalyzing ? "El Agente está auditando el bloque de tareas...\nEsto puede tomar unos segundos." : "Selecciona un filtro y presiona Analizar.",
  //                   textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)
  //                 )
  //               )
  //             : ListView(
  //                 padding: const EdgeInsets.all(16),
  //                 children: [
  //                   // RESUMEN EJECUTIVO
  //                   if (_aiReport!['executive_summary'] != null)
  //                     Card(
  //                       color: Colors.deepPurpleAccent.withOpacity(0.05),
  //                       elevation: 0,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.2))),
  //                       child: Padding(
  //                         padding: const EdgeInsets.all(16.0),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             const Row(children: [Icon(Icons.insights_rounded, color: Colors.deepPurpleAccent), SizedBox(width: 8), Text("Resumen Ejecutivo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))]),
  //                             const SizedBox(height: 8),
  //                             Text(_aiReport!['executive_summary'], style: const TextStyle(height: 1.4)),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
                    
  //                   // ALERTAS (EXPIRACIONES)
  //                   if (_aiReport!['expiring_warnings'] != null && (_aiReport!['expiring_warnings'] as List).isNotEmpty) ...[
  //                     const SizedBox(height: 16),
  //                     const Text("⚠️ Alertas Críticas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
  //                     const SizedBox(height: 8),
  //                     ...(_aiReport!['expiring_warnings'] as List).map((w) => Container(
  //                       margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
  //                       decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
  //                       child: Text(w.toString(), style: const TextStyle(fontSize: 12, color: Colors.red)),
  //                     )),
  //                   ],

  //                   // EVALUACIONES Y ACCIONES RÁPIDAS
  //                   if (_aiReport!['evaluations'] != null && (_aiReport!['evaluations'] as List).isNotEmpty) ...[
  //                     const SizedBox(height: 24),
  //                     const Text("Acciones Recomendadas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                     const SizedBox(height: 8),
  //                     ...(_aiReport!['evaluations'] as List).map((eval) {
  //                       if (eval['recommended_action'] == 'NONE') return const SizedBox.shrink();
                        
  //                       bool isApprove = eval['recommended_action'] == 'APPROVED';
  //                       String taskId = eval['taskId']?.toString() ?? '';
  //                       // Buscamos el nombre real de la tarea para mostrarlo
  //                       var originalTask = widget.allTasks.firstWhere((t) => t['id'] == taskId, orElse: () => null);
  //                       if (originalTask == null) return const SizedBox.shrink();

  //                       return Card(
  //                         margin: const EdgeInsets.only(bottom: 12),
  //                         elevation: 0, color: theme.scaffoldBackgroundColor,
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(16),
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text("📌 ${originalTask['title']}", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                               const SizedBox(height: 8),
  //                               Text("🕵️ Razonamiento: ${eval['ai_reasoning']}", style: const TextStyle(fontSize: 12, color: Colors.deepPurple, fontStyle: FontStyle.italic)),
  //                               const SizedBox(height: 8),
  //                               Container(
  //                                 padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
  //                                 child: Text("✍️ Feedback pre-escrito:\n\"${eval['employee_feedback']}\"", style: const TextStyle(fontSize: 12)),
  //                               ),
  //                               const SizedBox(height: 12),
  //                               SizedBox(
  //                                 width: double.infinity,
  //                                 child: ElevatedButton.icon(
  //                                   style: ElevatedButton.styleFrom(
  //                                     backgroundColor: isApprove ? Colors.teal : Colors.orange,
  //                                     foregroundColor: Colors.white,
  //                                     elevation: 0
  //                                   ),
  //                                   icon: Icon(isApprove ? Icons.verified_rounded : Icons.refresh_rounded),
  //                                   label: Text(isApprove ? "Aprobar y Pagar (1-Click)" : "Exigir Rework (1-Click)"),
  //                                   onPressed: () => _aplicarDecisionIA(taskId, eval['recommended_action'], eval['employee_feedback']),
  //                                 ),
  //                               )
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }),
  //                   ]
  //                 ],
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}