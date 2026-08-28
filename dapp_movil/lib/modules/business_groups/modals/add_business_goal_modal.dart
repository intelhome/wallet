import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';

class AddBusinessGoalModal {
  static void show(BuildContext context, String groupId, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGoalContent(groupId: groupId, onSuccess: onSuccess),
    );
  }
}

class _AddGoalContent extends StatefulWidget {
  final String groupId;
  final VoidCallback onSuccess;

  const _AddGoalContent({required this.groupId, required this.onSuccess});

  @override
  State<_AddGoalContent> createState() => _AddGoalContentState();
}

class _AddGoalContentState extends State<_AddGoalContent> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  bool _isSaving = false;

  Future<void> _guardarMeta() async {
    if (_titleController.text.trim().isEmpty || _targetController.text.trim().isEmpty || _unitController.text.trim().isEmpty) {
      UIHelper.showCustomSnackbar("Llena los campos obligatorios", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final service = Provider.of<BusinessGroupService>(context, listen: false);

    String res = await service.addGoal(widget.groupId, {
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "targetValue": double.tryParse(_targetController.text.trim()) ?? 0.0,
      "currentValue": 0.0,
      "unit": _unitController.text.trim(),
    });

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("KPI / Meta creada exitosamente");
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
                Text("Nuevo KPI del Área", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(hintText: "Título (Ej. Ventas del Mes)", prefixIcon: Icon(Icons.flag_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(hintText: "Descripción (Opcional)", prefixIcon: Icon(Icons.notes_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(hintText: "Objetivo (Ej. 1000)", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _unitController,
                    style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(hintText: "Unidad (USD, %)", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: _isSaving ? null : _guardarMeta,
                icon: _isSaving ? const SizedBox() : const Icon(Icons.save_rounded),
                label: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Crear Meta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}