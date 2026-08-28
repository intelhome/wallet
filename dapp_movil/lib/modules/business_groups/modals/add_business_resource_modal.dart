import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/business_group_service.dart';

class AddBusinessResourceModal {
  static void show(BuildContext context, String groupId, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddResourceContent(groupId: groupId, onSuccess: onSuccess),
    );
  }
}

class _AddResourceContent extends StatefulWidget {
  final String groupId;
  final VoidCallback onSuccess;

  const _AddResourceContent({required this.groupId, required this.onSuccess});

  @override
  State<_AddResourceContent> createState() => _AddResourceContentState();
}

class _AddResourceContentState extends State<_AddResourceContent> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isSaving = false;

  Future<void> _guardarRecurso() async {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) {
      UIHelper.showCustomSnackbar("Todos los campos son obligatorios", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    String res = await service.addResource(widget.groupId, {
      "title": _titleController.text.trim(),
      "type": "LINK",
      "urlOrHash": _urlController.text.trim(),
      "addedBy": authCore.publicAddress.toLowerCase()
    });

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Recurso agregado al equipo");
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
              Text("Nuevo Recurso", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(hintText: "Título (Ej. Carpeta de Drive)", prefixIcon: Icon(Icons.title_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(hintText: "URL (https://...)", prefixIcon: Icon(Icons.link_rounded, color: colorScheme.primary), filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              onPressed: _isSaving ? null : _guardarRecurso,
              icon: _isSaving ? const SizedBox() : const Icon(Icons.save_rounded),
              label: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Guardar Enlace", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}