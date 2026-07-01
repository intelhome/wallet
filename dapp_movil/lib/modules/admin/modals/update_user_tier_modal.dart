import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/admin_service.dart';

class UpdateUserTierModal {
  static void show({required BuildContext context, required VoidCallback onUpdateSuccess}) {
    final TextEditingController walletController = TextEditingController();
    String selectedTier = "BASIC";
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        
        return StatefulBuilder(
          builder: (BuildContext dialogCtx, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 40, color: Colors.purpleAccent),
                  const SizedBox(height: 10),
                  const Text("Gestionar Plan de Usuario", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: walletController,
                    decoration: InputDecoration(
                      labelText: "Billetera del Usuario (0x...)",
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: selectedTier,
                    decoration: InputDecoration(
                      labelText: "Nuevo Plan a Asignar",
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: ["FREE", "BASIC", "PREMIUM"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setStateModal(() => selectedTier = val!),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: isProcessing ? null : () async {
                        if (walletController.text.trim().isEmpty) return;
                        setStateModal(() => isProcessing = true);
                        
                        final adminService = Provider.of<AdminService>(context, listen: false);
                        String res = await adminService.updateUserTier(walletController.text.trim(), selectedTier);
                        
                        if (res == "Exito") {
                          Navigator.pop(ctx);
                          UIHelper.showCustomSnackbar("Plan de usuario actualizado a $selectedTier");
                          onUpdateSuccess();
                        } else {
                          setStateModal(() => isProcessing = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.redAccent));
                        }
                      },
                      child: isProcessing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Actualizar Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }
}