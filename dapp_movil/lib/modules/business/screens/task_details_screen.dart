import 'dart:convert';

import 'package:dapp_movil/modules/business/modals/edit_task_modal.dart';
import 'package:dapp_movil/modules/business/services/ai_task_admin_handler.dart';
import 'package:dapp_movil/modules/business/services/business_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';
import '../widgets/task_ui_factory.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final bool isEmployer;
  final VoidCallback onRefresh;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.isEmployer,
    required this.onRefresh,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _reworkHoursController = TextEditingController();
  final TextEditingController _reworkBudgetController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isProcessing = false;
  late Map<String, dynamic> _currentTask;

  bool _isAiAuditing = false;
  String? _aiReasoning;
  String? _aiRecommendedStatus;

  

  @override
  void initState() {
    super.initState();
    _currentTask = Map<String, dynamic>.from(widget.task);
    _reworkHoursController.text = (_currentTask['estimatedHours'] ?? '0').toString();
    _reworkBudgetController.text = (_currentTask['allocatedResources'] ?? '0.0').toString();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _reworkHoursController.dispose();
    _reworkBudgetController.dispose();
    super.dispose();
  }



  Color _getUrgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'LOW': return Colors.green;
      case 'MEDIUM': return Colors.orange;
      case 'HIGH': return Colors.redAccent;
      case 'URGENT': return Colors.deepPurpleAccent;
      default: return Colors.grey;
    }
  }

  Future<void> _cambiarEstadoTarea(String nuevoEstado, Map<String, dynamic> datosAdicionales) async {
    setState(() => _isProcessing = true);
    final taskService = Provider.of<BusinessTaskService>(context, listen: false);

    Map<String, dynamic> payload = {
      "status": nuevoEstado,
      ...datosAdicionales
    };

    String res = await taskService.updateTaskStatus(_currentTask['id'], payload);

    if (res == "SUCCESS") {
      HapticFeedback.heavyImpact();
      UIHelper.showCustomSnackbar("Estado de actividad actualizado a: $nuevoEstado");
      widget.onRefresh();
      Navigator.pop(context); // Volvemos a la lista de tareas
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
      setState(() => _isProcessing = false);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
    
  //   String status = _currentTask['status'] ?? 'PENDING';
  //   String urgency = _currentTask['urgency'] ?? 'MEDIUM';
  //   String taskType = _currentTask['taskType'] ?? 'STANDARD';
  //   List<dynamic> subTasks = _currentTask['subTasks'] ?? [];

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //    appBar: AppBar(
  //       title: Text(_currentTask['title'] ?? 'Detalle de Actividad', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       backgroundColor: theme.cardColor,
  //       elevation: 0,
  //       // 🔥 BOTONES DE EDICIÓN Y ELIMINACIÓN (SOLO EMPRESA)
  //       actions: widget.isEmployer && (status == 'PENDING' || status == 'IN_PROGRESS' || status == 'NEEDS_INFO' || status == 'REJECTED') ? [
  //         IconButton(
  //           icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
  //           tooltip: "Editar Tarea",
  //           onPressed: _abrirModalEdicion,
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
  //           tooltip: "Cancelar y Eliminar",
  //           onPressed: _eliminarTarea,
  //         ),
  //       ] : null,
  //     ),
  //     body: _isProcessing 
  //         ? const Center(child: CircularProgressIndicator())
  //         : SingleChildScrollView(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // 1. CARD DE CABECERA METADATA
  //                 Card(
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //                   elevation: 0,
  //                   color: theme.cardColor,
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(16.0),
  //                     child: Column(
  //                       children: [
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                           children: [
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                               decoration: BoxDecoration(
  //                                 color: _getUrgencyColor(urgency).withOpacity(0.1),
  //                                 borderRadius: BorderRadius.circular(12),
  //                               ),
  //                               child: Text("Prioridad: $urgency", style: TextStyle(color: _getUrgencyColor(urgency), fontWeight: FontWeight.bold, fontSize: 12)),
  //                             ),
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                               decoration: BoxDecoration(
  //                                 color: colorScheme.primary.withOpacity(0.1),
  //                                 borderRadius: BorderRadius.circular(12),
  //                               ),
  //                               child: Text(status, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
  //                             ),
  //                           ],
  //                         ),
  //                         const Divider(height: 24),
  //                         Row(
  //                           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                           children: [
  //                             _buildMetaItem(Icons.payments_rounded, "Fondos", "${_currentTask['allocatedResources'] ?? 0} TTC"),
  //                             _buildMetaItem(Icons.hourglass_top_rounded, "Horas Est.", "${_currentTask['estimatedHours'] ?? 0}h"),
  //                             _buildMetaItem(Icons.layers_rounded, "Tipo", taskType),
  //                           ],
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),

  //                 // 2. DESCRIPCIÓN
  //                 Text("Descripción de la Actividad", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 8),
  //                 Text(_currentTask['description'] ?? 'Sin descripción proporcionada.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
  //                 const SizedBox(height: 20),

  //                 if (_currentTask['infoRequestNotes'] != null && status == 'NEEDS_INFO') ...[
  //                   Container(
  //                     padding: const EdgeInsets.all(12),
  //                     decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18), SizedBox(width:8), Text("Información Solicitada:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
  //                         const SizedBox(height: 4),
  //                         Text(_currentTask['infoRequestNotes'].toString(), style: TextStyle(color: colorScheme.onSurface)),
  //                       ]
  //                     )
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],

  //                 if (_currentTask['appealReason'] != null && status == 'REJECTED') ...[
  //                   Container(
  //                     padding: const EdgeInsets.all(12),
  //                     decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         const Row(children: [Icon(Icons.cancel_rounded, color: Colors.red, size: 18), SizedBox(width:8), Text("Motivo de Rechazo:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
  //                         const SizedBox(height: 4),
  //                         Text(_currentTask['appealReason'].toString(), style: TextStyle(color: colorScheme.onSurface)),
  //                       ]
  //                     )
  //                   ),
  //                   const SizedBox(height: 16),
  //                 ],

  //                 // ====================================================================
  //                 // 🔥 PANEL DEL EMPLEADO (ACCIONES INICIALES - PENDIENTE)
  //                 // ====================================================================
  //                 if (!widget.isEmployer && status == 'PENDING') ...[
  //                   const Divider(height: 30),
  //                   const Text("Acciones requeridas", style: TextStyle(fontWeight: FontWeight.bold)),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
  //                           icon: const Icon(Icons.check_circle_rounded, size: 18),
  //                           label: const Text("Aceptar y Empezar", style: TextStyle(fontWeight: FontWeight.bold)),
  //                           onPressed: () => _cambiarEstadoTarea("IN_PROGRESS", {"acceptedByWallet": _currentTask['assignedWallet']}), // Simula firma del empleado
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: OutlinedButton.icon(
  //                           style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
  //                           icon: const Icon(Icons.info_outline_rounded, size: 18),
  //                           label: const Text("Pedir Info", style: TextStyle(fontSize: 12)),
  //                           onPressed: () => _showReasonDialog("Falta Información", "¿Qué detalles adicionales necesitas para empezar?", "NEEDS_INFO", "infoRequestNotes"),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       Expanded(
  //                         child: OutlinedButton.icon(
  //                           style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
  //                           icon: const Icon(Icons.cancel_rounded, size: 18),
  //                           label: const Text("Rechazar", style: TextStyle(fontSize: 12)),
  //                           onPressed: () => _showReasonDialog("Rechazar Tarea", "¿Por qué rechazas esta actividad?", "REJECTED", "appealReason"),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                 ],

  //                 // ====================================================================
  //                 // 🔥 PANEL DEL EMPLEADOR (BOTÓN DE REASIGNACIÓN)
  //                 // ====================================================================
  //                 if (widget.isEmployer && (status == 'PENDING' || status == 'NEEDS_INFO' || status == 'REJECTED')) ...[
  //                    OutlinedButton.icon(
  //                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
  //                      icon: const Icon(Icons.swap_horiz_rounded),
  //                      label: const Text("Reasignar / Transferir Tarea", style: TextStyle(fontWeight: FontWeight.bold)),
  //                      onPressed: _reasignarTarea,
  //                    ),
  //                    const SizedBox(height: 20),
  //                 ],

  //                 // 3. COMPONENTE DINÁMICO DE INTERACCIÓN (MAPAS, FORMULARIOS, ENCUESTAS)
  //                 TaskUIFactory.buildWidget(context, _currentTask, widget.isEmployer, () {
  //                   widget.onRefresh();
  //                 }),
  //                 const SizedBox(height: 20),

  //                 // 4. SUBTAREAS / CHECKLIST SECUNDARIO
  //                 if (subTasks.isNotEmpty) ...[
  //                   Text("Hitos y Entregables (${subTasks.length})", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  //                   const SizedBox(height: 8),
  //                   ...subTasks.map((sub) {
  //                     bool isDone = sub['completed'] == true;
  //                     return Card(
  //                       elevation: 0,
  //                       color: theme.cardColor.withOpacity(0.6),
  //                       margin: const EdgeInsets.only(bottom: 8),
  //                       child: ListTile(
  //                         leading: Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isDone ? Colors.teal : Colors.grey),
  //                         title: Text(sub['title'] ?? '', style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null)),
  //                         subtitle: sub['evidenceUrl'] != null ? Text("Evidencia: ${sub['evidenceUrl']}", style: const TextStyle(fontSize: 11, color: Colors.blue)) : null,
  //                       ),
  //                     );
  //                   }),
  //                   const SizedBox(height: 20),
  //                 ],

  //                 // 5. VISUALIZADOR DE PRUEBAS DE COMPLETADO (REVISIÓN DE EVIDENCIAS)
  //                if (_currentTask['completionProof'] != null) ...[
  //                   _buildSectionTitle(Icons.fact_check_rounded, "Entregables Enviados"),
  //                   const SizedBox(height: 8),
  //                   Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.all(16),
  //                     decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.teal.withOpacity(0.2))),
  //                     // 🔥 Usamos nuestro nuevo Helper en lugar de texto plano
  //                     child: _buildCompletionProofUI(_currentTask['completionProof'].toString()),
  //                   ),
  //                   const SizedBox(height: 20),
  //                 ],

  //                 // 🔥 6. VISUALIZADOR DE RETROALIMENTACIÓN / REWORK (Visible para ambos)
  //                 if (_currentTask['feedback'] != null && _currentTask['feedback'].toString().isNotEmpty) ...[
  //                   _buildSectionTitle(Icons.feedback_rounded, "Retroalimentación / Correcciones"),
  //                   const SizedBox(height: 8),
  //                   Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.all(16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.orange.withOpacity(0.1), 
  //                       borderRadius: BorderRadius.circular(16), 
  //                       border: Border.all(color: Colors.orange.withOpacity(0.5))
  //                     ),
  //                   child: Text(
  //                       _currentTask['feedback'].toString(), 
  //                       style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onSurface),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                 ],

  //                 // ====================================================================
  //                 // 🔥 PANEL DEL SUPERVISOR (ACCIONES DE EVALUACIÓN E INYECCIÓN IA) 🔥
  //                 // ====================================================================
  //                 if (widget.isEmployer && (status == 'COMPLETED' || status == 'IN_PROGRESS')) ...[
  //                   const Divider(height: 30),
                    
  //                  // =======================================================
  //                   // 🔥 AVISO DE AUDITORÍA MASIVA (IA)
  //                   // =======================================================
  //                   Container(
  //                     padding: const EdgeInsets.all(12),
  //                     decoration: BoxDecoration(
  //                       color: Colors.deepPurpleAccent.withOpacity(0.08), 
  //                       borderRadius: BorderRadius.circular(12), 
  //                       border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3))
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent),
  //                         const SizedBox(width: 12),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text("Auditoría Cognitiva IA", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
  //                               const SizedBox(height: 4),
  //                               const Text("Recuerda que puedes auditar y aprobar múltiples tareas a la vez usando el botón flotante de IA en el panel principal de administración.", style: TextStyle(fontSize: 11, color: Colors.black54)),
  //                             ],
  //                           ),
  //                         )
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   // Container(
  //                   //   padding: const EdgeInsets.all(12),
  //                   //   decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3))),
  //                   //   child: Row(
  //                   //     children: [
  //                   //       const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent),
  //                   //       const SizedBox(width: 12),
  //                   //       Expanded(
  //                   //         child: Column(
  //                   //           crossAxisAlignment: CrossAxisAlignment.start,
  //                   //           children: [
  //                   //             Text("Supervisor Cognitivo Activo", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
  //                   //             const SizedBox(height: 4),
  //                   //             const Text("El agente autónomo interceptará las fotos y notas de prueba para validar criterios de aceptación automáticamente.", style: TextStyle(fontSize: 11, color: Colors.black54)),
  //                   //           ],
  //                   //         ),
  //                   //       )
  //                   //     ],
  //                   //   ),
  //                   // ),
  //                   // const SizedBox(height: 20),

  //                   Text("Retroalimentación de la Gerencia", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
  //                   const SizedBox(height: 8),
  //                   TextField(
  //                     controller: _feedbackController,
  //                     maxLines: 3,
  //                     textCapitalization: TextCapitalization.sentences,
  //                     decoration: InputDecoration(
  //                       hintText: "Escribe comentarios de aprobación o razones detalladas del rechazo / rehacer...",
  //                       fillColor: theme.cardColor,
  //                       filled: true,
  //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 16),

  //                   // BOTONES DE ACCIÓN PRINCIPAL (APROBAR / EXIGIR REHACER)
  //                   Row(
  //                     children: [
  //                       // BOTÓN SOLICITAR REHACER (REWORK)
  //                       Expanded(
  //                         child: OutlinedButton.icon(
  //                           style: OutlinedButton.styleFrom(
  //                             foregroundColor: Colors.orange, 
  //                             padding: const EdgeInsets.symmetric(vertical: 14),
  //                             side: const BorderSide(color: Colors.orange),
  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                           ),
  //                           icon: const Icon(Icons.refresh_rounded),
  //                           label: const Text("Exigir Rework", style: TextStyle(fontWeight: FontWeight.bold)),
  //                           onPressed: () {
  //                             if (_feedbackController.text.trim().isEmpty) {
  //                               UIHelper.showCustomSnackbar("Debes ingresar una justificación en la retroalimentación para solicitar Rework.", isError: true);
  //                               return;
  //                             }
  //                             _mostrarModalReajusteParametros();
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 12),
                        
  //                       // BOTÓN LIQUIDAR Y APROBAR FONDEO
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Colors.teal, 
  //                             foregroundColor: Colors.white,
  //                             padding: const EdgeInsets.symmetric(vertical: 14),
  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                           ),
  //                           icon: const Icon(Icons.verified_rounded),
  //                           label: const Text("Aprobar y Pagar", style: TextStyle(fontWeight: FontWeight.bold)),
  //                           onPressed: () => _cambiarEstadoTarea("APPROVED", {
  //                             "feedback": _feedbackController.text.trim()
  //                           }),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 30),
  //                 ],
  //               ],
  //             ),
  //           ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    
    String status = _currentTask['status'] ?? 'PENDING';
    String urgency = _currentTask['urgency'] ?? 'MEDIUM';
    String taskType = _currentTask['taskType'] ?? 'STANDARD';
    List<dynamic> subTasks = _currentTask['subTasks'] ?? [];
    
    String statusText = status.replaceAll("_", " ");
    Color urgencyColor = _getUrgencyColor(urgency);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalles de Tarea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: widget.isEmployer && (status == 'PENDING' || status == 'IN_PROGRESS' || status == 'NEEDS_INFO' || status == 'REJECTED') ? [
          IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.grey), onPressed: _abrirModalEdicion),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey), onPressed: _eliminarTarea),
        ] : null,
      ),
      body: _isProcessing 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. CABECERA METADATA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: urgencyColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text(urgency, style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusText, style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${_currentTask['allocatedResources'] ?? '0.00'} TTC", style: TextStyle(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w900)),
                          Text("Est. ${_currentTask['estimatedHours'] ?? 0} Hours", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_currentTask['title'] ?? 'Sin Título', style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 4),
                  Text("$taskType • TAREA ID: #TTC-${_currentTask['id'].toString().substring(0, 4)}", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 24),

                  // 2. DESCRIPCIÓN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Descripción", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(_currentTask['description'] ?? 'Sin descripción proporcionada.', style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. ENTREGABLES (SUBTAREAS)
                  if (subTasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Entregables", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("${subTasks.where((o) => o['completed'] == true).length}/${subTasks.length}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: subTasks.where((o) => o['completed'] == true).length / subTasks.length,
                              minHeight: 4,
                              backgroundColor: onSurface.withOpacity(0.1),
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...subTasks.map((sub) {
                            bool isDone = sub['completed'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                              child: ExpansionTile(
                                leading: Icon(isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isDone ? colorScheme.primary : onSurface.withOpacity(0.5), size: 20),
                                title: Text(sub['title'] ?? '', style: TextStyle(color: onSurface.withOpacity(isDone ? 0.5 : 0.9), decoration: isDone ? TextDecoration.lineThrough : null, fontSize: 14)),
                                children: [
                                  if (isDone)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.link_rounded, size: 16, color: Colors.blueAccent),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(sub['evidenceUrl'] ?? '', style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline, fontSize: 12))),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(children: [const Icon(Icons.notes_rounded, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(sub['completionNotes'] ?? '', style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12)))]),
                                          if (!widget.isEmployer && status == 'IN_PROGRESS')
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                onPressed: () => _abrirModalEvidencia(context, _currentTask['id'], sub), 
                                                icon: const Icon(Icons.edit_rounded, size: 16), label: const Text("Editar")
                                              ),
                                            )
                                        ],
                                      ),
                                    )
                                  else if (!widget.isEmployer && status == 'IN_PROGRESS')
                                    Padding(
                                      padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, elevation: 0),
                                          onPressed: () => _abrirModalEvidencia(context, _currentTask['id'], sub),
                                          icon: const Icon(Icons.upload_file_rounded),
                                          label: const Text("Entregar Objetivo"),
                                        ),
                                      ),
                                    )
                                  else 
                                    const Padding(padding: EdgeInsets.all(16), child: Text("Esperando entrega...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // COMPONENTE DINÁMICO
                  TaskUIFactory.buildWidget(context, _currentTask, widget.isEmployer, () => widget.onRefresh()),
                  const SizedBox(height: 16),

                  // 4. REPORTE IA (SOLO SI APLICA O ESTÁ REVISADO)
                  if (status == 'COMPLETED' || status == 'APPROVED') ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Auditoria AI", style: TextStyle(color: colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(8)), child: const Text("VERIFIED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_aiReasoning ?? "Análisis automático pendiente de ejecución en las entregas enviadas. Se validarán las pruebas criptográficas.", style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // =======================================================
                  // 5. SECCIÓN DE ACCIONES: JEFE (EMPLOYER)
                  // =======================================================
                  if (widget.isEmployer && (status == 'COMPLETED' || status == 'IN_PROGRESS')) ...[
                    Text("Comentarios del Revisor", style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        style: TextStyle(color: onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Agregar comentarios o solicitar cambios...",
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (_feedbackController.text.trim().isEmpty) {
                                UIHelper.showCustomSnackbar("Debes ingresar feedback para Rework.", isError: true);
                                return;
                              }
                              _mostrarModalReajusteParametros();
                            },
                            child: const Text("Pedir revision", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _cambiarEstadoTarea("APPROVED", {"feedback": _feedbackController.text.trim()}),
                            child: const Text("Aprobar y Pagar", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // =======================================================
                  // 6. SECCIÓN DE ACCIONES: EMPLEADO
                  // =======================================================
                  if (!widget.isEmployer) ...[
                    if (status == 'PENDING') ...[
                      // EMPLEADO ACEPTA O RECHAZA TAREA INICIAL
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 16)), 
                              onPressed: () => _showReasonDialog("Rechazar Tarea", "¿Por qué rechazas esta actividad?", "REJECTED", "appealReason"), 
                              child: const Text("Rechazar tarea")
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 16)), 
                              onPressed: () => _cambiarEstadoTarea("IN_PROGRESS", {"acceptedByWallet": _currentTask['assignedWallet']}), 
                              child: const Text("Aceptar tarea")
                            )
                          ),
                        ],
                      ),
                    ] else if (status == 'IN_PROGRESS') ...[
                      // EMPLEADO ENVÍA LA TAREA COMPLETADA
                      Text("Notas de Finalización", style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                        child: TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          style: TextStyle(color: onSurface, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Agregar notas finales o pruebas de entrega...",
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: BorderSide(color: Colors.orange.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 16)), 
                              onPressed: () {
                                if (_reasonController.text.trim().isEmpty) { UIHelper.showCustomSnackbar("Escribe por qué necesitas revisión", isError: true); return; }
                                _cambiarEstadoTarea("IN_REVIEW", {"infoRequestNotes": _reasonController.text});
                              }, 
                              child: const Text("Solicitar Revisión")
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 16)), 
                              onPressed: () {
                                bool faltanObjs = subTasks.any((o) => o['completed'] != true);
                                if (faltanObjs) { UIHelper.showCustomSnackbar("Aún faltan entregables por marcar.", isError: true); return; }
                                _cambiarEstadoTarea("COMPLETED", {"completionProof": _reasonController.text});
                              }, 
                              child: const Text("Enviar Entrega")
                            )
                          ),
                        ],
                      )
                    ],
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  //  NUEVO: Modal Interno para que el empleado adjunte la evidencia a un SubTask
  void _abrirModalEvidencia(BuildContext context, String taskId, Map<String, dynamic> obj) {
    final urlCtrl = TextEditingController(text: obj['evidenceUrl'] ?? '');
    final noteCtrl = TextEditingController(text: obj['completionNotes'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Entregar: ${obj['title']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextField(controller: urlCtrl, decoration: InputDecoration(labelText: "URL Evidencia (Foto/Video/Doc)", hintText: "https://drive.google.com/...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: InputDecoration(labelText: "Notas de entrega", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50, 
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: isSaving ? null : () async {
                    if (urlCtrl.text.isEmpty) {
                      UIHelper.showCustomSnackbar("La URL de evidencia es obligatoria", isError: true);
                      return;
                    }
                    setStateInner(() => isSaving = true);
                    
                    await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(taskId, {
                      "status": "COMPLETE_SUBTASK",
                      "subTaskId": obj['id'],
                      "evidenceUrl": urlCtrl.text,
                      "completionNotes": noteCtrl.text
                    });
                    
                    // Actualización local para repintar
                    setState(() {
                      obj['completed'] = true;
                      obj['evidenceUrl'] = urlCtrl.text;
                      obj['completionNotes'] = noteCtrl.text;
                    });

                    Navigator.pop(ctx);
                    widget.onRefresh(); 
                  },
                  child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Entregable"),
                )
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  void _showReasonDialog(String title, String label, String newStatus, String payloadKey) {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: _reasonController,
          decoration: InputDecoration(labelText: label),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newStatus == 'REJECTED' ? Colors.red : Colors.orange),
            onPressed: () {
              if (_reasonController.text.trim().isEmpty) {
                UIHelper.showCustomSnackbar("Este campo es obligatorio", isError: true);
                return;
              }
              Navigator.pop(ctx);
              _cambiarEstadoTarea(newStatus, {payloadKey: _reasonController.text.trim()});
            },
            child: const Text("Enviar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalEdicion() async {
    setState(() => _isProcessing = true);
    try {
      final bService = Provider.of<BusinessService>(context, listen: false);
      final team = await bService.getTeamWithDetails();
      final depts = await bService.getDepartments();
      setState(() => _isProcessing = false);
      
      if (!mounted) return;
      EditTaskModal.show(
        context: context, 
        task: _currentTask, 
        activeTeam: team, 
        departments: depts, 
        onSuccess: () {
          widget.onRefresh();
          Navigator.pop(context); // Cierra y refresca
        }
      );
    } catch(e) {
      setState(() => _isProcessing = false);
      UIHelper.showCustomSnackbar("Error al abrir edición", isError: true);
    }
  }

  void _eliminarTarea() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: const Text("Cancelar Tarea"),
      content: const Text("¿Estás seguro de que deseas cancelar y eliminar esta tarea? Los fondos asignados serán devueltos a tu cuenta corporativa."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Volver", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(ctx);
            _cambiarEstadoTarea("CANCELLED", {}); 
          }, 
          child: const Text("Sí, Eliminar", style: TextStyle(color: Colors.white)),
        )
      ]
    ));
  }

  void _mostrarModalReajusteParametros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajustar Parámetros de Rework", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            const Text("Si es necesario, modifica el presupuesto asignado o las horas estimadas para que el empleado cumpla la corrección.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _reworkBudgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Presupuesto Ajustado (TTC)", prefixIcon: Icon(Icons.payments)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reworkHoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nuevas Horas Estimadas", prefixIcon: Icon(Icons.schedule)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () {
                  Navigator.pop(ctx);
                  _cambiarEstadoTarea("REWORK_REQUESTED", {
                    "feedback": _feedbackController.text.trim(),
                    "allocatedResources": double.tryParse(_reworkBudgetController.text) ?? _currentTask['allocatedResources'],
                    "estimatedHours": int.tryParse(_reworkHoursController.text) ?? _currentTask['estimatedHours']
                  });
                },
                child: const Text("Enviar a Corrección", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

