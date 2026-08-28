import 'package:dapp_movil/modules/business_groups/modals/business_group_member_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_group_service.dart';

class BusinessGroupMembersTab extends StatefulWidget {
  final dynamic group;
  final bool isEmployer;

  const BusinessGroupMembersTab({
    super.key,
    required this.group,
    required this.isEmployer,
  });

  @override
  State<BusinessGroupMembersTab> createState() => _BusinessGroupMembersTabState();
}

class _BusinessGroupMembersTabState extends State<BusinessGroupMembersTab> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final data = await service.getGroupMembers(widget.group['id']);
    
    if (mounted) {
      setState(() {
        _members = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(String memberWallet) async {
    final colorScheme = Theme.of(context).colorScheme;
    bool? confirm = await UIHelper.mostrarConfirmacion(
      context: context, 
      titulo: "Expulsar", 
      mensaje: "¿Seguro que deseas expulsar a este empleado del grupo?", 
      textoConfirmar: "Expulsar", 
      colorConfirmar: colorScheme.error
    );
    
    if (confirm != true) return;

    final service = Provider.of<BusinessGroupService>(context, listen: false);
    String res = await service.removeMember(widget.group['id'], memberWallet);
    
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar("Miembro expulsado exitosamente");
      _loadMembers();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_members.isEmpty) {
      return UIHelper.emptyState(
        context: context, 
        icon: Icons.group_off_rounded, 
        title: "Sin Miembros", 
        message: "No hay miembros activos en este grupo."
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _members.length,
      itemBuilder: (ctx, i) {
        final m = _members[i];
        
        // Verificamos si este usuario es el creador original
        bool isCreator = m['walletAddress'].toString().toLowerCase() == widget.group['creatorAddress'].toString().toLowerCase();

       return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(color: onSurface.withOpacity(0.05))
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.isEmployer ? () {
              // 🔥 NUEVO: Solo los empleadores abren el modal de detalles y auditoría IA
              BusinessGroupMemberDetailsModal.show(context, widget.group['id'], m, () {
                // Función vacía o callback para refrescar si es necesario
              });
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
              children: [
                SmartAvatar(address: m['walletAddress'], size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "@${m['alias'] ?? 'Usuario'}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCreator ? "Administrador" : "Empleado", 
                        style: TextStyle(color: isCreator ? colorScheme.primary : onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                
                // Opción de expulsar solo si yo soy empleador y el usuario destino no es el creador
                if (widget.isEmployer && !isCreator)
                  IconButton(
                    icon: Icon(Icons.person_remove_rounded, color: colorScheme.error.withOpacity(0.8)),
                    onPressed: () => _removeMember(m['walletAddress']),
                  ),
              ],
            ),
          ),
        )
       );
      },
    );
  }
}