import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/business_group_service.dart';

class AddGoalProgressModal {
  static void show(BuildContext context, String groupId, String goalId, String unit, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddProgressContent(groupId: groupId, goalId: goalId, unit: unit, onSuccess: onSuccess),
    );
  }
}

class _AddProgressContent extends StatefulWidget {
  final String groupId;
  final String goalId;
  final String unit;
  final VoidCallback onSuccess;

  const _AddProgressContent({required this.groupId, required this.goalId, required this.unit, required this.onSuccess});

  @override
  State<_AddProgressContent> createState() => _AddProgressContentState();
}

class _AddProgressContentState extends State<_AddProgressContent> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isSaving = false;

  Future<void> _guardarAvance() async {
    if (_amountController.text.trim().isEmpty) {
      UIHelper.showCustomSnackbar("Ingresa la cantidad aportada", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    String res = await service.addGoalProgress(widget.groupId, widget.goalId, {
      "amountAdded": double.tryParse(_amountController.text.trim()) ?? 0.0,
      "description": _descController.text.trim(),
      "proofUrl": _urlController.text.trim(),
      "addedByWallet": authCore.publicAddress.toLowerCase()
    });

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Avance registrado exitosamente");
      widget.onSuccess();
    } else {
      setState(() => _isSaving = false);
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Registrar Avance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
              decoration: InputDecoration(hintText: "Cantidad lograda (${widget.unit})", prefixIcon: Icon(Icons.add_chart_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(hintText: "Descripción del trabajo...", prefixIcon: Icon(Icons.notes_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(hintText: "Enlace de prueba (Opcional)", prefixIcon: Icon(Icons.link_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: _isSaving ? null : _guardarAvance,
                icon: _isSaving ? const SizedBox() : const Icon(Icons.save_rounded),
                label: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Registrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}