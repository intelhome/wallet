import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';

class EditBusinessGoalModal {
  static void show(BuildContext context, String groupId, dynamic goal, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditGoalContent(groupId: groupId, goal: goal, onSuccess: onSuccess),
    );
  }
}

class _EditGoalContent extends StatefulWidget {
  final String groupId;
  final dynamic goal;
  final VoidCallback onSuccess;

  const _EditGoalContent({required this.groupId, required this.goal, required this.onSuccess});

  @override
  State<_EditGoalContent> createState() => _EditGoalContentState();
}

class _EditGoalContentState extends State<_EditGoalContent> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal['title']);
    _descController = TextEditingController(text: widget.goal['description']);
    _targetController = TextEditingController(text: widget.goal['targetValue'].toString());
    _unitController = TextEditingController(text: widget.goal['unit']);
  }

  Future<void> _guardarCambios() async {
    if (_titleController.text.trim().isEmpty || _targetController.text.trim().isEmpty || _unitController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    String res = await service.updateGoal(widget.groupId, widget.goal['id'], {
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "targetValue": double.tryParse(_targetController.text.trim()) ?? 0.0,
      "unit": _unitController.text.trim(),
    });

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("KPI actualizado");
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
                Text("Editar KPI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
                IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, style: TextStyle(color: onSurface), decoration: InputDecoration(hintText: "Título", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: _descController, style: TextStyle(color: onSurface), decoration: InputDecoration(hintText: "Descripción", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: TextField(controller: _targetController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: onSurface, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: "Objetivo", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: TextField(controller: _unitController, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: "Unidad", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: _isSaving ? null : _guardarCambios,
                icon: _isSaving ? const SizedBox() : const Icon(Icons.save_rounded),
                label: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}