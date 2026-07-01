import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/burner_wallets/modals/send_burner_modal.dart';
import 'package:dapp_movil/modules/burner_wallets/services/burner_service.dart';
import 'package:dapp_movil/modules/business/modals/edit_task_modal.dart';
import 'package:dapp_movil/modules/business/widgets/task_ui_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';

class TaskDetailsModal {
  static Color _getUrgencyColor(String urgency) {
    if (urgency == 'LOW') return Colors.green;
    if (urgency == 'MEDIUM') return Colors.orange;
    if (urgency == 'HIGH') return Colors.redAccent;
    if (urgency == 'URGENT') return Colors.deepPurpleAccent;
    return Colors.grey;
  }

 static void show({
    required BuildContext context, 
    required Map<String, dynamic> task, 
    required bool isEmployer, 
    required VoidCallback onRefresh,
    List<dynamic>? teamMembers,
    List<dynamic>? departments, // 🔥 Necesario para editar
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _getUrgencyColor(task['urgency'] ?? 'MEDIUM');
    final status = task['status'] ?? 'PENDING';
   final List<dynamic> subTasks = task['subTasks'] ?? []; // 🔥 AHORA SON SUB-TAREAS
    final ctrlAux = TextEditingController(); 
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 CABECERA CON POPUP MENU PARA EL JEFE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(Icons.assignment, color: color)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(task['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    if (isEmployer)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (val) async {
                          if (val == 'EDIT') {
                            Navigator.pop(ctx);
                            EditTaskModal.show(context: context, task: task, activeTeam: teamMembers ?? [], departments: departments ?? [], onSuccess: onRefresh);
                          } else if (val == 'DELETE') {
                            bool? conf = await UIHelper.mostrarConfirmacion(context: context, titulo: "Eliminar Tarea", mensaje: "¿Seguro que deseas eliminar esta tarea?", textoConfirmar: "Eliminar", colorConfirmar: Colors.red);
                            if (conf == true) {
                              await Provider.of<BusinessTaskService>(context, listen: false).deleteTask(task['id']);
                              Navigator.pop(ctx); onRefresh();
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'EDIT', child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blueAccent), SizedBox(width: 8), Text("Editar Tarea")])),
                          const PopupMenuItem(value: 'DELETE', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.redAccent), SizedBox(width: 8), Text("Eliminar Tarea", style: TextStyle(color: Colors.redAccent))])),
                        ],
                      )
                  ],
                ),
                
                if (task['assignedWallet'] == null && task['departmentId'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("Disponible para el Área", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                  ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Text(task['description'] ?? '', style: const TextStyle(fontSize: 16)),
                ),
                
              // if (task['burnerAddress'] != null && task['burnerAddress'].toString().isNotEmpty)
              //     FutureBuilder<List<dynamic>>(
              //       // 🔥 CORRECCIÓN 1: Consultamos las tarjetas del JEFE (Dueño de los fondos)
              //       future: Provider.of<BurnerService>(context, listen: false).getActiveBurners(task['businessWallet']),
              //       builder: (ctx, snap) {
              //         // 🔥 CORRECCIÓN 2: El saldo por defecto es el presupuesto asignado, no 0
              //         double realBalance = (task['allocatedResources'] ?? 0).toDouble();
              //         bool isLoaded = snap.connectionState == ConnectionState.done;
                      
              //         if (snap.hasData && snap.data!.isNotEmpty) {
              //           // Buscamos la tarjeta exacta atada a esta tarea
              //           final match = snap.data!.firstWhere(
              //             (b) => b['burnerAddress'].toString().toLowerCase() == task['burnerAddress'].toString().toLowerCase(), 
              //             orElse: () => null
              //           );
              //           if (match != null) {
              //             realBalance = double.tryParse(match['balance'].toString()) ?? 0.0;
              //           }
              //         }

              //         return Container(
              //           margin: const EdgeInsets.only(top: 16, bottom: 8),
              //           padding: const EdgeInsets.all(16),
              //           decoration: BoxDecoration(
              //             gradient: LinearGradient(colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade800]),
              //             borderRadius: BorderRadius.circular(20),
              //             boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              //           ),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               const Row(
              //                 children: [
              //                   Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
              //                   SizedBox(width: 8),
              //                   Text("Fondos de la Tarea (Burner)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              //                 ],
              //               ),
              //               const SizedBox(height: 12),
              //               Row(
              //                 children: [
              //                   Text("$realBalance TTC", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              //                   if (!isLoaded) ...[
              //                     const SizedBox(width: 12),
              //                     const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              //                   ]
              //                 ],
              //               ),
              //               Padding(
              //                 padding: const EdgeInsets.only(top: 4.0),
              //                 child: Text(task['burnerAddress'], style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
              //               ),
                            
              //               // Botón de pago corporativo
              //               if (!isEmployer && status == 'IN_PROGRESS' && realBalance > 0) ...[
              //                 const SizedBox(height: 16),
              //                 SizedBox(
              //                   width: double.infinity,
              //                   child: ElevatedButton.icon(
              //                     style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange),
              //                     onPressed: () {
              //                       SendBurnerModal.show(
              //                         context: context, 
              //                         burnerAddress: task['burnerAddress'], 
              //                         balanceTTC: realBalance.toString(), 
              //                         onUpdateBalance: () {
              //                           setStateModal(() {}); 
              //                           onRefresh(); 
              //                         }
              //                       );
              //                     }, 
              //                     icon: const Icon(Icons.payment_rounded), 
              //                     label: const Text("Pagar Gasto Corporativo", style: TextStyle(fontWeight: FontWeight.bold))
              //                   ),
              //                 )
              //               ]
              //             ],
              //           ),
              //         );
              //       }
              //     ),

              if (task['burnerAddress'] != null && task['burnerAddress'].toString().isNotEmpty)
                  if (status == 'COMPLETED' || status == 'CANCELLED') ...[
                    // ==========================================
                    // 🔥 1. VISTA ESTÁTICA (TAREA FINALIZADA)
                    // ==========================================
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1), // Apagado porque ya se quemó
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, color: Colors.grey),
                              SizedBox(width: 8),
                              Text("Presupuesto Original Asignado", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text("${task['allocatedResources']} TTC", style: const TextStyle(color: Colors.grey, fontSize: 28, fontWeight: FontWeight.w900)),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(task['burnerAddress'], style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ),
                    // 🔥 TARJETA DE REEMBOLSO
                    if (task['refundedResources'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.savings_rounded, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Fondos Devueltos a la Empresa", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text("+ ${task['refundedResources']} TTC", style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    // ==========================================
                    // 🔥 2. VISTA EN VIVO (TAREA EN PROGRESO)
                    // ==========================================
                    FutureBuilder<List<dynamic>>(
                      future: Provider.of<BurnerService>(context, listen: false).getActiveBurners(task['businessWallet']),
                      builder: (ctx, snap) {
                        double realBalance = (task['allocatedResources'] ?? 0).toDouble();
                        bool isLoaded = snap.connectionState == ConnectionState.done;
                        
                        if (snap.hasData && snap.data!.isNotEmpty) {
                          final match = snap.data!.firstWhere(
                            (b) => b['burnerAddress'].toString().toLowerCase() == task['burnerAddress'].toString().toLowerCase(), 
                            orElse: () => null
                          );
                          if (match != null) {
                            realBalance = double.tryParse(match['balance'].toString()) ?? 0.0;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade800]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Fondos de la Tarea (Burner)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text("$realBalance TTC", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                                  if (!isLoaded) ...[
                                    const SizedBox(width: 12),
                                    const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  ]
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(task['burnerAddress'], style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                              ),
                              
                              if (!isEmployer && status == 'IN_PROGRESS' && realBalance > 0) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepOrange),
                                    onPressed: () {
                                      SendBurnerModal.show(
                                        context: context, 
                                        burnerAddress: task['burnerAddress'], 
                                        balanceTTC: realBalance.toString(), 
                                        onUpdateBalance: () {
                                          setStateModal(() {}); 
                                          onRefresh(); 
                                        }
                                      );
                                    }, 
                                    icon: const Icon(Icons.payment_rounded), 
                                    label: const Text("Pagar Gasto Corporativo", style: TextStyle(fontWeight: FontWeight.bold))
                                  ),
                                )
                              ]
                            ],
                          ),
                        );
                      }
                    ),
                  ],

                if (task['estimatedHours'] != null && task['estimatedHours'] > 0)
                  Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("⏳ Tiempo Estimado: ${task['estimatedHours']} Horas")),
                const SizedBox(height: 16),

                // 🔥 FÁBRICA DINÁMICA DE INTERFACES (MEET, GPS, NOTARY)
                // 🔥 FÁBRICA DINÁMICA DE INTERFACES
                TaskUIFactory.buildWidget(context, task, isEmployer, onRefresh),
                if (task['taskType'] != 'STANDARD') const SizedBox(height: 16),
                // 🔥 OBJETIVOS (Progreso y Evidencias)
             if (subTasks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Progreso de Sub-Tareas", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${subTasks.where((o) => o['completed'] == true).length}/${subTasks.length}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: subTasks.where((o) => o['completed'] == true).length / subTasks.length,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...subTasks.map((obj) {
                    bool isDone = obj['completed'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDone ? Colors.green.withOpacity(0.5) : Colors.transparent)),
                      elevation: 0,
                      color: isDone ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isDone ? Colors.green : Colors.grey),
                        title: Row(
                            children: [
                              Expanded(child: Text(obj['title'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? Colors.green : null))),
                              if (obj['estimatedHours'] != null && obj['estimatedHours'] > 0)
                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text("${obj['estimatedHours']}h", style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          children: [
                            if (isDone)
                              Padding(
                                padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.link_rounded, size: 16, color: Colors.blueAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              final urlStr = obj['evidenceUrl'] ?? '';
                                              if (urlStr.isEmpty) return;
                                              
                                              // Asegurar que tenga http/https para que url_launcher lo procese bien
                                              final finalUrl = urlStr.startsWith('http') ? urlStr : 'https://$urlStr';
                                              final Uri url = Uri.parse(finalUrl);
                                              
                                              try {
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                              } catch (e) {
                                                UIHelper.showCustomSnackbar("No se pudo abrir el enlace", isError: true);
                                              }
                                            },
                                            child: Text(
                                              obj['evidenceUrl'] ?? '', 
                                              style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                                          tooltip: "Copiar enlace",
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: obj['evidenceUrl'] ?? ''));
                                            UIHelper.showCustomSnackbar("Enlace copiado al portapapeles");
                                          },
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(children: [const Icon(Icons.notes_rounded, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(obj['completionNotes'] ?? ''))]),
                                    if (!isEmployer && status == 'IN_PROGRESS')
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _abrirModalEvidencia(context, task['id'], obj, onRefresh, setStateModal), 
                                          icon: const Icon(Icons.edit_rounded, size: 16), label: const Text("Editar")
                                        ),
                                      )
                                  ],
                                ),
                              )
                            else if (!isEmployer && status == 'IN_PROGRESS')
                              Padding(
                                padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    onPressed: () => _abrirModalEvidencia(context, task['id'], obj, onRefresh, setStateModal),
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: const Text("Entregar Objetivo"),
                                  ),
                                ),
                              )
                            else 
                              const Padding(padding: EdgeInsets.all(16), child: Text("Esperando entrega...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // 🔥 ESTADOS ESPECIALES
                if (status == 'REJECTED') ...[
                  const Text("⚠️ Tarea Rechazada:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Text(task['appealReason'] ?? 'Sin motivo dado', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],
                if (status == 'IN_REVIEW' || status == 'NEEDS_INFO') ...[
                  const Text("🔎 Tarea en Revisión:", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  Text(task['infoRequestNotes'] ?? 'El empleado requiere asistencia o cambios.', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],
                if (status == 'COMPLETED') ...[
                  const Text("🏆 Prueba de Finalización Final:", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text(task['completionProof'] ?? 'Completado sin notas adicionales', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],

                // ==============================
                // 🔥 ZONA: EMPLEADO
                // ==============================
                if (!isEmployer) ...[
                  if (status == 'PENDING') ...[
                    TextField(controller: ctrlAux, decoration: InputDecoration(labelText: "Comentario para Rechazo / Revisión", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: isProcessing ? null : () async {
                          if (ctrlAux.text.isEmpty) { UIHelper.showCustomSnackbar("Escribe por qué necesitas revisión", isError: true); return; }
                          setStateModal(() => isProcessing = true);
                          await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "IN_REVIEW", "infoRequestNotes": ctrlAux.text});
                          Navigator.pop(ctx); onRefresh();
                        }, style: OutlinedButton.styleFrom(foregroundColor: Colors.orange), child: const Text("Poner en Revisión", textAlign: TextAlign.center))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: isProcessing ? null : () async {
                          if (ctrlAux.text.isEmpty) { UIHelper.showCustomSnackbar("Escribe el motivo del rechazo", isError: true); return; }
                          setStateModal(() => isProcessing = true);
                          await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "REJECTED", "appealReason": ctrlAux.text});
                          Navigator.pop(ctx); onRefresh();
                        }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Rechazar"))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isProcessing ? null : () async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza el inicio de esta actividad."));
                      HapticFeedback.mediumImpact();
                      bool isAuth = await Provider.of<AuthCoreService>(context, listen: false).authenticateUser();
                      Navigator.pop(context); // Cerrar skeleton
                      
                      if (!isAuth) return;

                      setStateModal(() => isProcessing = true);
                      // 🔥 Capturamos quién aceptó la tarea para asignársela si era de un departamento
                      String miWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();
                      await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "IN_PROGRESS", "acceptedByWallet": miWallet});
                      Navigator.pop(ctx); onRefresh();
                    }, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white), child: Text(task['assignedWallet'] == null ? "Tomar Actividad" : "Aceptar y Empezar"))),
                  ] else if (status == 'IN_PROGRESS') ...[
                    TextField(controller: ctrlAux, maxLines: 2, decoration: InputDecoration(labelText: "Notas finales o Comentario de Revisión", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: isProcessing ? null : () async {
                          if (ctrlAux.text.isEmpty) { UIHelper.showCustomSnackbar("Escribe por qué necesitas revisión", isError: true); return; }
                          setStateModal(() => isProcessing = true);
                          await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "IN_REVIEW", "infoRequestNotes": ctrlAux.text});
                          Navigator.pop(ctx); onRefresh();
                        }, style: OutlinedButton.styleFrom(foregroundColor: Colors.orange), child: const Text("Pedir Revisión", textAlign: TextAlign.center))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: isProcessing ? null : () async {
                            // 🔥 CORRECCIÓN: Usamos la nueva variable subTasks
                            bool faltanObjs = subTasks.any((o) => o['completed'] != true);
                            if (faltanObjs) { UIHelper.showCustomSnackbar("Aún faltan entregables.", isError: true); return; }
                            
                            setStateModal(() => isProcessing = true);
                            await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "COMPLETED", "completionProof": ctrlAux.text});
                            Navigator.pop(ctx); onRefresh();
                          },
                          child: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Finalizar"),
                        )),
                      ],
                    )
                  ],
                ],

                // ==============================
                // 🔥 ZONA: JEFE (EMPLOYER)
                // ==============================
                if (isEmployer) ...[
                  if (status == 'REJECTED' || status == 'IN_REVIEW' || status == 'NEEDS_INFO') ...[
                    const Text("Reasignar Tarea a otro miembro:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                      hint: const Text("Selecciona un empleado"),
                      items: (teamMembers ?? []).map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier']))).toList(),
                      onChanged: (newWallet) async {
                        if (newWallet == null) return;
                        setStateModal(() => isProcessing = true);
                        await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(task['id'], {"status": "REASSIGN", "newAssignedWallet": newWallet});
                        Navigator.pop(ctx); onRefresh();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

 // Modal interno para subir evidencia por objetivo (Actualización en Tiempo Real)
  static void _abrirModalEvidencia(BuildContext context, String taskId, Map<String, dynamic> obj, VoidCallback onRefresh, StateSetter setStateModal) {
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
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSaving ? null : () async {
                  if (urlCtrl.text.isEmpty) {
                    UIHelper.showCustomSnackbar("La URL de evidencia es obligatoria", isError: true);
                    return;
                  }
                  setStateInner(() => isSaving = true);
                  
                  // 🔥 Guardamos en Base de Datos
                 // 🔥 Guardamos en Base de Datos (SubTask)
                  await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(taskId, {
                    "status": "COMPLETE_SUBTASK",
                    "subTaskId": obj['id'],
                    "evidenceUrl": urlCtrl.text,
                    "completionNotes": noteCtrl.text
                  });
                  
                  // 🔥 ACTUALIZACIÓN EN TIEMPO REAL: Modificamos el objeto local
                  obj['completed'] = true;
                  obj['evidenceUrl'] = urlCtrl.text;
                  obj['completionNotes'] = noteCtrl.text;

                  Navigator.pop(ctx); // Cierra el modal de evidencia
                  setStateModal(() {}); // 🔥 Obliga al modal principal (TaskDetailsModal) a repintarse al instante
                  onRefresh(); // Actualiza la lista en la pantalla principal de fondo
                },
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Entregable"),
              )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}