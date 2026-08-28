import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_group_service.dart';

class CreateBusinessGroupModal {
  static void show(BuildContext context, List<dynamic> departments, List<dynamic> activeTeam, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateBusinessGroupContent(departments: departments, activeTeam: activeTeam, onSuccess: onSuccess),
    );
  }
}

class _CreateBusinessGroupContent extends StatefulWidget {
  final List<dynamic> departments;
  final List<dynamic> activeTeam;
  final VoidCallback onSuccess;

  const _CreateBusinessGroupContent({required this.departments, required this.activeTeam, required this.onSuccess});

  @override
  State<_CreateBusinessGroupContent> createState() => _CreateBusinessGroupContentState();
}

class _CreateBusinessGroupContentState extends State<_CreateBusinessGroupContent> {
  int _tabIndex = 0; // 0 = Por Área, 1 = Personalizado
  bool _isCreating = false;

  final TextEditingController _nameController = TextEditingController();
  final List<dynamic> _selectedMembers = [];

  Future<void> _crearGrupo({required String areaName, required String groupName, required List<dynamic> members}) async {
    if (members.isEmpty) {
      UIHelper.showCustomSnackbar("El grupo debe tener al menos un miembro", isError: true);
      return;
    }
    setState(() => _isCreating = true);

    final bgService = Provider.of<BusinessGroupService>(context, listen: false);
    String res = await bgService.createAreaGroup(
      areaName: areaName, 
      groupName: groupName,
      members: members
    );

    if (res == "SUCCESS") {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Grupo corporativo creado exitosamente");
      widget.onSuccess();
    } else {
      setState(() => _isCreating = false);
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nuevo Grupo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
              IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          // TABS CUSTOMIZADAS
          Container(
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _tabIndex == 0 ? colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                      child: Text("Rápido por Área", textAlign: TextAlign.center, style: TextStyle(color: _tabIndex == 0 ? colorScheme.onPrimary : onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _tabIndex == 1 ? colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                      child: Text("Personalizado", textAlign: TextAlign.center, style: TextStyle(color: _tabIndex == 1 ? colorScheme.onPrimary : onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CONTENIDO DE LA TAB 0 (RÁPIDO POR ÁREA)
          if (_tabIndex == 0) ...[
            Text("Genera un grupo instantáneo con todos los empleados de un área específica.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: widget.departments.isEmpty
                ? Center(child: Text("No tienes áreas creadas.", style: TextStyle(color: colorScheme.error)))
                : ListView.builder(
                    itemCount: widget.departments.length,
                    itemBuilder: (ctx, i) {
                      final dept = widget.departments[i];
                      int count = (dept['memberWallets'] as List?)?.length ?? 0;
                      return Card(
                        color: theme.cardColor,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.domain_rounded, color: colorScheme.primary)),
                          title: Text(dept['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("$count empleados", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _isCreating ? null : () {
                              List<dynamic> areaMembers = widget.activeTeam.where((m) => (dept['memberWallets'] as List).contains(m['walletAddress'].toString().toLowerCase())).toList();
                              _crearGrupo(areaName: dept['name'], groupName: "Grupo ${dept['name']}", members: areaMembers);
                            },
                            child: _isCreating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Crear"),
                          ),
                        ),
                      );
                    },
                  ),
            )
          ],

          // CONTENIDO DE LA TAB 1 (PERSONALIZADO)
          if (_tabIndex == 1) ...[
            TextField(
              controller: _nameController,
              style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Nombre del grupo...",
                hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.groups_rounded, color: colorScheme.primary),
                filled: true, fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Seleccionar Integrantes", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                Text("${_selectedMembers.length} seleccionados", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.activeTeam.isEmpty
                ? Center(child: Text("No hay empleados activos.", style: TextStyle(color: onSurface.withOpacity(0.5))))
                : ListView.builder(
                    itemCount: widget.activeTeam.length,
                    itemBuilder: (ctx, i) {
                      final m = widget.activeTeam[i];
                      bool isSelected = _selectedMembers.contains(m);
                      return GestureDetector(
                        onTap: () => setState(() {
                          isSelected ? _selectedMembers.remove(m) : _selectedMembers.add(m);
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent, width: 1.5)
                          ),
                          child: Row(
                            children: [
                              SmartAvatar(address: m['walletAddress'] ?? m['identifier'], size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m['alias'] ?? "Usuario", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(m['role'] ?? "Empleado", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? colorScheme.primary : onSurface.withOpacity(0.2)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: _isCreating ? null : () => _crearGrupo(areaName: "General", groupName: _nameController.text.trim(), members: _selectedMembers),
                icon: _isCreating ? const SizedBox() : const Icon(Icons.add_task_rounded),
                label: _isCreating ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Crear Grupo Personalizado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}