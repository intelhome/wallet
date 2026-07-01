import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/business_service.dart';

class CreateDepartmentModal {
  static void show(BuildContext context, VoidCallback onSuccess, {
    String? initialName, 
    String? initialDescription, 
    String? initialBudget
  }) {
    final nameCtrl = TextEditingController(text: initialName ?? "");
    final descCtrl = TextEditingController(text: initialDescription ?? "");
    final budgetCtrl = TextEditingController(text: initialBudget ?? "");
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Crear Departamento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Nombre (Ej. IT, Ventas)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 12),
              TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Presupuesto Asignado (TTC)", prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: isProcessing ? null : () async {
                    if (nameCtrl.text.isEmpty) return;
                    setStateModal(() => isProcessing = true);
                    final service = Provider.of<BusinessService>(context, listen: false);
                    final auth = Provider.of<AuthCoreService>(context, listen: false);
                    
                    String res = await service.createDepartment({
                      "businessWallet": auth.publicAddress.toLowerCase(),
                      "name": nameCtrl.text,
                      "description": descCtrl.text,
                      "allocatedBudget": double.tryParse(budgetCtrl.text) ?? 0.0
                    });

                    if (res == "SUCCESS") {
                      Navigator.pop(ctx);
                      UIHelper.showCustomSnackbar("Departamento creado");
                      onSuccess();
                    } else {
                      UIHelper.showCustomSnackbar(res, isError: true);
                      setStateModal(() => isProcessing = false);
                    }
                  },
                  child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Crear Área", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}