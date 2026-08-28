import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';

class EditBusinessResourceModal {
  static void show(BuildContext context, String groupId, dynamic resource, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditResourceContent(groupId: groupId, resource: resource, onSuccess: onSuccess),
    );
  }
}

class _EditResourceContent extends StatefulWidget {
  final String groupId;
  final dynamic resource;
  final VoidCallback onSuccess;

  const _EditResourceContent({required this.groupId, required this.resource, required this.onSuccess});

  @override
  State<_EditResourceContent> createState() => _EditResourceContentState();
}

class _EditResourceContentState extends State<_EditResourceContent> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.resource['title']);
    _urlController = TextEditingController(text: widget.resource['urlOrHash']);
  }

  Future<void> _guardarCambios() async {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    String res = await service.updateResource(widget.groupId, widget.resource['id'], {
      "title": _titleController.text.trim(),
      "urlOrHash": _urlController.text.trim(),
    });

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Recurso actualizado");
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Editar Recurso", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _titleController, style: TextStyle(color: onSurface), decoration: InputDecoration(hintText: "Título", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          TextField(controller: _urlController, style: TextStyle(color: onSurface), decoration: InputDecoration(hintText: "URL", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
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
    );
  }
}