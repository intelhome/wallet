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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Crear Departamento", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 8),
                  Text("Configura una nueva área y asígnale un presupuesto inicial en TTC.", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.4)),
                  const SizedBox(height: 24),

                  // CAJA PRINCIPAL
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: onSurface.withOpacity(0.05))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nombre del Área", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl, 
                          decoration: InputDecoration(
                            hintText: "Ej. Marketing, Desarrollo...",
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                            prefixIcon: Icon(Icons.domain_rounded, color: onSurface.withOpacity(0.5)),
                            filled: true, fillColor: onSurface.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),
                        const SizedBox(height: 20),

                        Text("Descripción", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descCtrl, maxLines: 3, 
                          decoration: InputDecoration(
                            hintText: "Breve descripción del propósito del área...",
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 32.0),
                              child: Icon(Icons.description_outlined, color: onSurface.withOpacity(0.5)),
                            ),
                            filled: true, fillColor: onSurface.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),
                        const SizedBox(height: 20),

                        Text("Presupuesto Asignado (TTC)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: budgetCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: onSurface.withOpacity(0.5)),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF7209B7), borderRadius: BorderRadius.circular(6)),
                              child: const Text("TTC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            filled: true, fillColor: onSurface.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                          )
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: onSurface.withOpacity(0.5)),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Este presupuesto será bloqueado en el contrato inteligente del área.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: onSurface.withOpacity(0.05)),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBAC3FF), 
                              foregroundColor: const Color(0xFF00218d), 
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                            ),
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
                            icon: isProcessing ? const SizedBox() : const Icon(Icons.add_circle_rounded),
                            label: isProcessing ? const CircularProgressIndicator() : const Text("Crear Área", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ],
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