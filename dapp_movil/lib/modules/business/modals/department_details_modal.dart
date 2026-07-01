import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';

class DepartmentDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> department, List<dynamic> activeTeam, VoidCallback onRefresh) {
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          List<dynamic> membersWallets = department['memberWallets'] ?? [];
          
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(department['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Eliminar", mensaje: "¿Eliminar departamento?", textoConfirmar: "Eliminar", colorConfirmar: Colors.red);
                      if (confirm == true) {
                        await Provider.of<BusinessService>(context, listen: false).deleteDepartment(department['id']);
                        Navigator.pop(ctx); onRefresh();
                      }
                    })
                  ],
                ),
                Text(department['description'] ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [const Icon(Icons.monetization_on, color: Colors.green), const SizedBox(width: 8), Text("Presupuesto: ${department['allocatedBudget']} TTC", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                ),
                const SizedBox(height: 16),
                const Text("Añadir Miembro", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  hint: const Text("Selecciona un empleado"),
                  items: activeTeam.where((m) => !membersWallets.contains(m['wallet'])).map<DropdownMenuItem<String>>((member) => DropdownMenuItem(
                    value: member['wallet'], child: Text(member['alias'] ?? member['identifier']),
                  )).toList(),
                  onChanged: (newWallet) async {
                    if (newWallet == null) return;
                    setStateModal(() => isProcessing = true);
                    await Provider.of<BusinessService>(context, listen: false).addMemberToDepartment(department['id'], newWallet);
                    Navigator.pop(ctx); onRefresh();
                  },
                ),
                const SizedBox(height: 16),
                const Text("Miembros Actuales", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: isProcessing ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                    itemCount: membersWallets.length,
                    itemBuilder: (context, index) {
                      String w = membersWallets[index];
                      var userDetails = activeTeam.firstWhere((m) => m['wallet'] == w, orElse: () => {'alias': w, 'wallet': w});
                      return ListTile(
                        leading: SmartAvatar(address: w, size: 30),
                        title: Text(userDetails['alias'] ?? w),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () async {
                          setStateModal(() => isProcessing = true);
                          await Provider.of<BusinessService>(context, listen: false).removeMemberFromDepartment(department['id'], w);
                          Navigator.pop(ctx); onRefresh();
                        }),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}