import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/business_groups/screens/business_group_members_tab.dart';
import 'package:dapp_movil/modules/business_groups/screens/business_group_productivity_tab.dart';
import 'package:dapp_movil/modules/business_groups/screens/business_group_resources_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../chat_and_social/screens/chat_room_screen.dart';
import '../../groups_and_social/screens/group_chat_screen.dart';
import '../services/business_group_service.dart';

class BusinessGroupDetailsScreen extends StatefulWidget {
  final dynamic group;
  final bool isEmployer;

  const BusinessGroupDetailsScreen({
    super.key,
    required this.group,
    required this.isEmployer,
  });

  @override
  State<BusinessGroupDetailsScreen> createState() => _BusinessGroupDetailsScreenState();
}

class _BusinessGroupDetailsScreenState extends State<BusinessGroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  IOWebSocketChannel? _wsChannel;
  Key _tabsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Preparando espacio para 3 tabs: Miembros, Recursos (próximamente), Métricas (próximamente)
    _tabController = TabController(length: 3, vsync: this);
    _conectarWebSocket();
  }

@override
  void dispose() {
    _wsChannel?.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  void _conectarWebSocket() {
    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = "$baseWsUrl/ws/business-groups/${widget.group['id']}";
      
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
      );

      _wsChannel!.stream.listen((message) {
        if (message == "UPDATE_BUSINESS_GROUP") {
          _refreshGroupData();
        }
      });
    } catch (_) {}
  }

  Future<void> _refreshGroupData() async {
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final updatedGroup = await service.getGroupById(widget.group['id']);
    if (updatedGroup != null && mounted) {
      setState(() {
        widget.group.addAll(updatedGroup); // Actualiza la data del grupo en memoria
        _tabsKey = UniqueKey(); // 🔥 Cambia la llave, forzando a las Tabs a repintarse
      });
    }
  }

  Future<void> _editarAnuncio() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    TextEditingController controller = TextEditingController(text: widget.group['pinnedAnnouncement'] ?? '');

    bool? guardado = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text("Fijar Anuncio", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Escribe las directrices o anuncio importante para el área...",
            filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final service = Provider.of<BusinessGroupService>(context, listen: false);
              String res = await service.updateAnnouncement(widget.group['id'], controller.text.trim());
              if (res == "SUCCESS") {
                setState(() => widget.group['pinnedAnnouncement'] = controller.text.trim());
                Navigator.pop(ctx, true);
              } else {
                UIHelper.showCustomSnackbar(res, isError: true);
              }
            },
            child: const Text("Fijar"),
          )
        ],
      ),
    );
    if (guardado == true) UIHelper.showCustomSnackbar("Anuncio actualizado");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.group['name'] ?? 'Espacio de Trabajo',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.forum_rounded, color: colorScheme.primary),
            tooltip: "Chat del Grupo",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    groupId: widget.group['id'],
                    groupName: widget.group['name'],
                    totalMembers: (widget.group['members'] as List?)?.length ?? 1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    body: Column(
        children: [
      
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2)
                  ),
                  child: SmartAvatar(address: widget.group['id'], size: 50),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Área: ${widget.group['area'] ?? 'General'}",
                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Creado por: @${widget.group['creatorAlias'] ?? 'Admin'}",
                        style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          
          _buildBudgetCard(theme, colorScheme, onSurface),
          
          const SizedBox(height: 12),
      
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: colorScheme.primary,
            unselectedLabelColor: onSurface.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_rounded), text: "Miembros"),
              Tab(icon: Icon(Icons.folder_shared_rounded), text: "Recursos"),
              Tab(icon: Icon(Icons.insights_rounded), text: "Productividad"),
            ],
          ),
          
        if (widget.group['pinnedAnnouncement'] != null || widget.isEmployer)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.secondary.withOpacity(0.3))
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.push_pin_rounded, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Anuncio Fijado", style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          widget.group['pinnedAnnouncement'] ?? 'Aún no hay anuncios fijados para el equipo.',
                          style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isEmployer)
                    GestureDetector(
                      onTap: _editarAnuncio,
                      child: Icon(Icons.edit_rounded, color: colorScheme.secondary, size: 18),
                    )
                ],
              ),
            ),

          const SizedBox(height: 8),

          
          Expanded(
            child: TabBarView(
              key: _tabsKey, 
              controller: _tabController,
              children: [
                BusinessGroupMembersTab(group: widget.group, isEmployer: widget.isEmployer),
                BusinessGroupResourcesTab(group: widget.group, isEmployer: widget.isEmployer),
                BusinessGroupProductivityTab(groupId: widget.group['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBudgetCard(ThemeData theme, ColorScheme colorScheme, Color onSurface) {
    // Parseamos los valores que ahora nos envía el backend de forma segura
    double totalAllocated = double.tryParse(widget.group['totalAllocatedBudget']?.toString() ?? '0') ?? 0.0;
    double usedBudget = double.tryParse(widget.group['usedBudget']?.toString() ?? '0') ?? 0.0;
    double remainingBudget = double.tryParse(widget.group['remainingBudget']?.toString() ?? '0') ?? 0.0;
    
    // Si el área aún no tiene presupuesto asignado en sus tareas, ocultamos la tarjeta
    if (totalAllocated <= 0 && usedBudget <= 0) return const SizedBox.shrink();

    double progress = totalAllocated > 0 ? (usedBudget / totalAllocated).clamp(0.0, 1.0) : 0.0;
    
    // Usamos colorScheme.error si el presupuesto está por agotarse, de lo contrario usamos primary
    Color progressColor = progress >= 0.9 ? colorScheme.error : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Presupuesto del Área", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: onSurface)),
              Text("${usedBudget.toStringAsFixed(0)} / ${totalAllocated.toStringAsFixed(0)} TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: progressColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Disponibilidad financiera: ${remainingBudget.toStringAsFixed(2)} TTC",
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

