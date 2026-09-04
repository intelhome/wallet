import 'package:dapp_movil/modules/business_groups/screens/business_group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/helpers/route_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/business_group_service.dart';

class BusinessGroupsScreen extends StatefulWidget {
  final bool isEmployer;
  const BusinessGroupsScreen({super.key, required this.isEmployer});

  @override
  State<BusinessGroupsScreen> createState() => _BusinessGroupsScreenState();
}

class _BusinessGroupsScreenState extends State<BusinessGroupsScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;
  String _selectedArea = "Todas";

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final data = await service.getBusinessGroups(widget.isEmployer);
    if (mounted) setState(() { _groups = data; _isLoading = false; });
  }

  List<dynamic> get _filteredGroups {
    if (_selectedArea == "Todas") return _groups;
    return _groups.where((g) => g['area'] == _selectedArea).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // Extraer áreas únicas para los filtros
    Set<String> areas = {"Todas"};
    for (var g in _groups) { if (g['area'] != null) areas.add(g['area']); }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Grupos Corporativos", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (areas.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: areas.map((area) {
                      bool isSelected = _selectedArea == area;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(area, style: TextStyle(color: isSelected ? colorScheme.onPrimary : onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          backgroundColor: onSurface.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                          showCheckmark: false,
                          onSelected: (val) { if (val) setState(() => _selectedArea = area); },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              Expanded(
                child: _filteredGroups.isEmpty
                  ? UIHelper.emptyState(context: context, icon: Icons.groups_rounded, title: "Sin Grupos", message: "No se encontraron grupos corporativos.")
                  : RefreshIndicator( // 🔥 NUEVO: Recarga al deslizar
                      onRefresh: _loadGroups,
                      child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredGroups.length,
                          itemBuilder: (ctx, i) {
                            final g = _filteredGroups[i];
                            
                            // 🔥 Usamos la variable optimizada totalMembers del DTO Backend
                            int membersCount = g['totalMembers'] ?? 0;
                            int goalsCount = g['totalGoals'] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                              elevation: 0,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                  child: Icon(Icons.home_work_rounded, color: colorScheme.primary),
                                ),
                                title: Text(g['name'] ?? 'Grupo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text("Área: ${g['area'] ?? 'General'} • $membersCount miembros • $goalsCount Metas", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                trailing: Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.4)),
                                onTap: () async {
                                  // Cuando el usuario entra al grupo, se lanza la segunda petición pesada
                                  await Navigator.push(context, RouteHelper.slideUpRoute(BusinessGroupDetailsScreen(group: g, isEmployer: widget.isEmployer)));
                                  _loadGroups(); // Refrescar al volver
                                },
                              ),
                            );
                          }
                        ),
                  ),
              )
            ],
          )
    );
  }
}