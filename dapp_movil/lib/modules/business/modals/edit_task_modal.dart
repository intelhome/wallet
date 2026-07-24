import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';

class EditTaskModal {
  // static void show({
  //   required BuildContext context, 
  //   required Map<String, dynamic> task, 
  //   required List<dynamic> activeTeam, 
  //   required List<dynamic> departments, 
  //   required VoidCallback onSuccess
  // }) {
  //   final titleCtrl = TextEditingController(text: task['title']);
  //   final descCtrl = TextEditingController(text: task['description']);
  //   final budgetCtrl = TextEditingController(text: (task['allocatedResources'] ?? 0).toString());
  //   final hoursCtrl = TextEditingController(text: (task['estimatedHours'] ?? 0).toString());
    
  //   String urgency = task['urgency'] ?? "MEDIUM";
  //   bool assignToDept = task['departmentId'] != null; 
    
  //   String? selectedWallet = task['assignedWallet'];
  //   String? selectedDept = task['departmentId'];
    
  //   bool isProcessing = false;

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Theme.of(context).cardColor,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (ctx, setStateModal) => Padding(
  //         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
  //         child: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Center(child: Text("Editar Tarea", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
  //               const SizedBox(height: 16),
                
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   const Text("Asignar a: "),
  //                   Switch(
  //                     value: assignToDept,
  //                     onChanged: (val) {
  //                       if (val && departments.isEmpty) { UIHelper.showCustomSnackbar("No tienes áreas creadas.", isError: true); return; }
  //                       if (!val && activeTeam.isEmpty) { UIHelper.showCustomSnackbar("No tienes empleados directos.", isError: true); return; }
  //                       setStateModal(() => assignToDept = val);
  //                     },
  //                   ),
  //                   Text(assignToDept ? "Área" : "Empleado", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),

  //               if (assignToDept)
  //                 DropdownButtonFormField<String>(
  //                   value: departments.any((d) => d['id'] == selectedDept) ? selectedDept : (departments.isNotEmpty ? departments.first['id'] : null),
  //                   decoration: InputDecoration(labelText: "Selecciona el Área", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
  //                   items: departments.map<DropdownMenuItem<String>>((dept) => DropdownMenuItem(value: dept['id'], child: Text(dept['name']))).toList(),
  //                   onChanged: (val) => setStateModal(() => selectedDept = val),
  //                 )
  //               else
  //                 DropdownButtonFormField<String>(
  //                   value: activeTeam.any((m) => m['wallet'] == selectedWallet) ? selectedWallet : (activeTeam.isNotEmpty ? activeTeam.first['wallet'] : null),
  //                   decoration: InputDecoration(labelText: "Selecciona el Empleado", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
  //                   items: activeTeam.map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier']))).toList(),
  //                   onChanged: (val) => setStateModal(() => selectedWallet = val),
  //                 ),

  //               const SizedBox(height: 12),
  //               TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
  //               const SizedBox(height: 12),
  //               TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
  //               const SizedBox(height: 12),
                
  //               Row(
  //                 children: [
  //                   Expanded(child: TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Presupuesto (TTC)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
  //                   const SizedBox(width: 12),
  //                   Expanded(child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Horas Estimadas", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               DropdownButtonFormField<String>(
  //                 value: urgency,
  //                 decoration: InputDecoration(labelText: "Nivel de Urgencia", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
  //                 items: const [
  //                   DropdownMenuItem(value: "LOW", child: Text("🟢 Baja (Flexible)", style: TextStyle(color: Colors.green))),
  //                   DropdownMenuItem(value: "MEDIUM", child: Text("🟠 Media (Normal)", style: TextStyle(color: Colors.orange))),
  //                   DropdownMenuItem(value: "HIGH", child: Text("🔴 Alta (Prioritaria)", style: TextStyle(color: Colors.red))),
  //                   DropdownMenuItem(value: "URGENT", child: Text("🟣 Urgente (Inmediata)", style: TextStyle(color: Colors.deepPurple))),
  //                 ],
  //                 onChanged: (val) => setStateModal(() => urgency = val!),
  //               ),
  //               const SizedBox(height: 24),
  //               SizedBox(
  //                 width: double.infinity, height: 50,
  //                 child: ElevatedButton(
  //                   style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                   onPressed: isProcessing ? null : () async {
  //                     if (titleCtrl.text.isEmpty) return;
  //                     setStateModal(() => isProcessing = true);
                      
  //                     String res = await Provider.of<BusinessTaskService>(context, listen: false).editTask(task['id'], {
  //                       "assignedWallet": assignToDept ? null : selectedWallet, 
  //                       "departmentId": assignToDept ? selectedDept : null,     
  //                       "title": titleCtrl.text,
  //                       "description": descCtrl.text,
  //                       "urgency": urgency,
  //                       "allocatedResources": double.tryParse(budgetCtrl.text) ?? 0.0,
  //                       "estimatedHours": int.tryParse(hoursCtrl.text) ?? 0,
  //                     });

  //                     if (res == "SUCCESS") {
  //                       Navigator.pop(ctx);
  //                       UIHelper.showCustomSnackbar("Tarea actualizada y puesta en Pendiente");
  //                       onSuccess();
  //                     } else {
  //                       UIHelper.showCustomSnackbar(res, isError: true);
  //                       setStateModal(() => isProcessing = false);
  //                     }
  //                   },
  //                   child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
  //                 ),
  //               ),
  //               const SizedBox(height: 24),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  static void show({
    required BuildContext context, 
    required Map<String, dynamic> task, 
    required List<dynamic> activeTeam, 
    required List<dynamic> departments, 
    required VoidCallback onSuccess
  }) {
    final titleCtrl = TextEditingController(text: task['title']);
    final descCtrl = TextEditingController(text: task['description']);
    final budgetCtrl = TextEditingController(text: (task['allocatedResources'] ?? 0).toString());
    final hoursCtrl = TextEditingController(text: (task['estimatedHours'] ?? 0).toString());
    
    String urgency = task['urgency'] ?? "MEDIUM";
    String taskType = task['taskType'] ?? "STANDARD";
    bool assignToDept = task['departmentId'] != null; 
    
    String? selectedWallet = task['assignedWallet'];
    String? selectedDept = task['departmentId'];
    
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(ctx)),
                      const Expanded(child: Text("Editar Tarea", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      const SizedBox(width: 48), 
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ==============================
                  // CAJA 1: ASIGNACIÓN
                  // ==============================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Asignación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                        const SizedBox(height: 16),
                        Text(assignToDept ? "Seleccionar Área" : "Seleccionar Asignado", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (assignToDept)
                          DropdownButtonFormField<String>(
                            value: departments.any((d) => d['id'] == selectedDept) ? selectedDept : (departments.isNotEmpty ? departments.first['id'] : null),
                            decoration: InputDecoration(prefixIcon: Icon(Icons.domain_rounded, color: onSurface.withOpacity(0.5)), filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            items: departments.map<DropdownMenuItem<String>>((dept) => DropdownMenuItem(value: dept['id'], child: Text(dept['name']))).toList(),
                            onChanged: (val) => setStateModal(() => selectedDept = val),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: activeTeam.any((m) => m['wallet'] == selectedWallet) ? selectedWallet : (activeTeam.isNotEmpty ? activeTeam.first['wallet'] : null),
                            decoration: InputDecoration(prefixIcon: Icon(Icons.person_search_rounded, color: onSurface.withOpacity(0.5)), filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            items: activeTeam.map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier']))).toList(),
                            onChanged: (val) => setStateModal(() => selectedWallet = val),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==============================
                  // CAJA 2: DETALLES
                  // ==============================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Detalles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                        const SizedBox(height: 16),
                        
                        Text("Título de la Actividad", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(controller: titleCtrl, decoration: InputDecoration(filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.all(16))),
                        const SizedBox(height: 16),
                        
                        Text("Descripción", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.all(16))),
                        const SizedBox(height: 16),

                        Text("Tipo de Actividad", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: taskType,
                          decoration: InputDecoration(prefixIcon: Icon(Icons.category_outlined, color: onSurface.withOpacity(0.5)), filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), isDense: true, contentPadding: const EdgeInsets.all(16)),
                          items: const [
                            DropdownMenuItem(value: "STANDARD", child: Text("Estándar")),
                            DropdownMenuItem(value: "GPS", child: Text("Ubicación GPS")),
                            DropdownMenuItem(value: "MEET", child: Text("Reunión Virtual")),
                          ],
                          onChanged: (val) => setStateModal(() => taskType = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==============================
                  // CAJA 3: PRESUPUESTO
                  // ==============================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Presupuesto Asignado (TTC)", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: budgetCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 16, color: onSurface),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.payments_outlined, color: onSurface.withOpacity(0.5)),
                            suffixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text("Gasless", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            filled: true, fillColor: onSurface.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==============================
                  // CAJA 4: TIEMPOS
                  // ==============================
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Horas Est.", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: hoursCtrl, keyboardType: TextInputType.number, 
                                decoration: InputDecoration(prefixIcon: Icon(Icons.schedule_rounded, color: onSurface.withOpacity(0.5)), filled: true, fillColor: onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), isDense: true)
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Fecha Límite", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [Icon(Icons.calendar_month_outlined, color: onSurface.withOpacity(0.5)), const SizedBox(width: 8), Text("dd/mm/aaaa", style: TextStyle(color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold))]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==============================
                  // CAJA 5: URGENCIA
                  // ==============================
                  Text("Nivel de Urgencia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["LOW", "MEDIUM", "HIGH", "URGENT"].map((u) {
                      bool isSel = urgency == u;
                      String lbl = u == "LOW" ? "Bajo" : u == "MEDIUM" ? "Medio" : u == "HIGH" ? "Alto" : "Urgente";
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setStateModal(() => urgency = u),
                          child: Container(
                            margin: EdgeInsets.only(right: u != "URGENT" ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? colorScheme.primary.withOpacity(0.2) : Colors.transparent, 
                              borderRadius: BorderRadius.circular(20), 
                              border: Border.all(color: isSel ? colorScheme.primary : onSurface.withOpacity(0.2))
                            ),
                            child: Text(lbl, textAlign: TextAlign.center, style: TextStyle(color: isSel ? colorScheme.primary : onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // BOTÓN FINAL
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBAC3FF), foregroundColor: const Color(0xFF00218d), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 0),
                      onPressed: isProcessing ? null : () async {
                        if (titleCtrl.text.isEmpty) return;
                        setStateModal(() => isProcessing = true);
                        
                        String res = await Provider.of<BusinessTaskService>(context, listen: false).editTask(task['id'], {
                          "assignedWallet": assignToDept ? null : selectedWallet, 
                          "departmentId": assignToDept ? selectedDept : null,     
                          "title": titleCtrl.text,
                          "description": descCtrl.text,
                          "urgency": urgency,
                          "allocatedResources": double.tryParse(budgetCtrl.text) ?? 0.0,
                          "estimatedHours": int.tryParse(hoursCtrl.text) ?? 0,
                        });

                        if (res == "SUCCESS") {
                          Navigator.pop(ctx);
                          UIHelper.showCustomSnackbar("Tarea actualizada");
                          onSuccess();
                        } else {
                          UIHelper.showCustomSnackbar(res, isError: true);
                          setStateModal(() => isProcessing = false);
                        }
                      },
                      icon: isProcessing ? const SizedBox() : const Icon(Icons.save_rounded),
                      label: isProcessing ? const CircularProgressIndicator() : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}