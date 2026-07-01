import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';

class EditTaskModal {
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
    bool assignToDept = task['departmentId'] != null; 
    
    String? selectedWallet = task['assignedWallet'];
    String? selectedDept = task['departmentId'];
    
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
                const Center(child: Text("Editar Tarea", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Asignar a: "),
                    Switch(
                      value: assignToDept,
                      onChanged: (val) {
                        if (val && departments.isEmpty) { UIHelper.showCustomSnackbar("No tienes áreas creadas.", isError: true); return; }
                        if (!val && activeTeam.isEmpty) { UIHelper.showCustomSnackbar("No tienes empleados directos.", isError: true); return; }
                        setStateModal(() => assignToDept = val);
                      },
                    ),
                    Text(assignToDept ? "Área" : "Empleado", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),

                if (assignToDept)
                  DropdownButtonFormField<String>(
                    value: departments.any((d) => d['id'] == selectedDept) ? selectedDept : (departments.isNotEmpty ? departments.first['id'] : null),
                    decoration: InputDecoration(labelText: "Selecciona el Área", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    items: departments.map<DropdownMenuItem<String>>((dept) => DropdownMenuItem(value: dept['id'], child: Text(dept['name']))).toList(),
                    onChanged: (val) => setStateModal(() => selectedDept = val),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: activeTeam.any((m) => m['wallet'] == selectedWallet) ? selectedWallet : (activeTeam.isNotEmpty ? activeTeam.first['wallet'] : null),
                    decoration: InputDecoration(labelText: "Selecciona el Empleado", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    items: activeTeam.map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier']))).toList(),
                    onChanged: (val) => setStateModal(() => selectedWallet = val),
                  ),

                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(child: TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Presupuesto (TTC)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Horas Estimadas", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: InputDecoration(labelText: "Nivel de Urgencia", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: const [
                    DropdownMenuItem(value: "LOW", child: Text("🟢 Baja (Flexible)", style: TextStyle(color: Colors.green))),
                    DropdownMenuItem(value: "MEDIUM", child: Text("🟠 Media (Normal)", style: TextStyle(color: Colors.orange))),
                    DropdownMenuItem(value: "HIGH", child: Text("🔴 Alta (Prioritaria)", style: TextStyle(color: Colors.red))),
                    DropdownMenuItem(value: "URGENT", child: Text("🟣 Urgente (Inmediata)", style: TextStyle(color: Colors.deepPurple))),
                  ],
                  onChanged: (val) => setStateModal(() => urgency = val!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
                        UIHelper.showCustomSnackbar("Tarea actualizada y puesta en Pendiente");
                        onSuccess();
                      } else {
                        UIHelper.showCustomSnackbar(res, isError: true);
                        setStateModal(() => isProcessing = false);
                      }
                    },
                    child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}