import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';
import '../services/business_service.dart';
import '../widgets/task_card.dart';
import '../modals/task_details_modal.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  List<dynamic> _allTasks = [];
  List<dynamic> _team = [];
  List<dynamic> _departments = [];
  Map<String, List<dynamic>> _groupedTasks = {};
  
  bool _isLoading = true;
  String _selectedFilter = 'Todas';
  String? _selectedDeptId; // Null = Todos los departamentos
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Future<void> _loadData() async {
  //   setState(() => _isLoading = true);
  //   final tService = Provider.of<BusinessTaskService>(context, listen: false);
  //   final bService = Provider.of<BusinessService>(context, listen: false);

  //   var results = await Future.wait<dynamic>([
  //     tService.getEmployerTasks(),
  //     bService.getTeamWithDetails(),
  //     bService.getDepartments()
  //   ]);

  //   if (mounted) {
  //     setState(() {
  //       _allTasks = results[0];
  //       _team = results[1].where((m) => m['status'] == 'ACCEPTED').toList();
  //       _departments = results[2];
  //       _applyFilter();
  //       _isLoading = false;
  //     });
  //   }
  // }

Future<void> _loadData() async {
    final cacheService = LocalCacheService();

    // 1. Caché rápido
    final cachedTasks = cacheService.getCachedEmployerTasks();
    final cachedTeam = cacheService.getCachedTeamWithDetails();
    final cachedDepts = cacheService.getCachedDepartments();

    if (cachedTasks.isNotEmpty || cachedTeam.isNotEmpty || cachedDepts.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allTasks = cachedTasks;
          _team = cachedTeam.where((m) => m['status'] == 'ACCEPTED').toList();
          _departments = cachedDepts;
          _applyFilter();
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final tService = Provider.of<BusinessTaskService>(context, listen: false);
    final bService = Provider.of<BusinessService>(context, listen: false);

    var results = await Future.wait<dynamic>([
      tService.getEmployerTasks(),
      bService.getTeamWithDetails(),
      bService.getDepartments()
    ]);

    if (mounted) {
      setState(() {
        _allTasks = results[0];
        _team = results[1].where((m) => m['status'] == 'ACCEPTED').toList();
        _departments = results[2];
        _applyFilter();
        _isLoading = false;
      });
    }
  }
  
  // 🔥 CALENDARIO DE RANGOS M3
  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Incluimos futuro por fechas límite
      helpText: 'Seleccionar Rango',
      cancelText: 'CANCELAR',
      confirmText: 'GUARDAR',
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end;
        _applyFilter();
      });
    }
  }

  void _limpiarFiltroFechas() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _applyFilter();
    });
  }

void _seleccionarDepartamento() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 FIX 1: Permite que el modal tome el tamaño necesario
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return Padding(
          // 🔥 FIX 2: Usamos viewInsets y padding bottom seguro para evitar cortes
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 24, 
            left: 16, right: 16, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🔥 FIX 3: Solo toma el espacio que necesita
            children: [
              // HEADER CON TÍTULO Y BOTÓN DE CERRAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filtrar por Área", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: onSurface.withOpacity(0.1), height: 16),
              
              // OPCIONES DE ÁREAS (EN TARJETA UNIFICADA Y SCROLLABLE)
              Flexible( // 🔥 FIX 4: Evita el desbordamiento de altura
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: onSurface.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.business_rounded, color: onSurface.withOpacity(0.5)),
                          title: Text("Todas las Áreas / Empleados", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() { _selectedDeptId = null; _applyFilter(); });
                            Navigator.pop(ctx);
                          },
                        ),
                        Divider(color: onSurface.withOpacity(0.05), height: 1, indent: 56),
                        ..._departments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final dept = entry.value;
                          final isLast = index == _departments.length - 1;
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.work_outline_rounded, color: onSurface.withOpacity(0.5)),
                                title: Text(dept['name'], style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                                onTap: () {
                                  setState(() { _selectedDeptId = dept['id']; _applyFilter(); });
                                  Navigator.pop(ctx);
                                },
                              ),
                              if (!isLast) Divider(color: onSurface.withOpacity(0.05), height: 1, indent: 56),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
  void _applyFilter() {
    List<dynamic> filtered = _allTasks.where((task) {
      // 1. FILTRO POR FECHA (Usamos la fecha de creación)
      if (_fechaInicio != null && _fechaFin != null && task['createdAt'] != null) {
        try {
          DateTime txDate = DateTime.parse(task['createdAt'].toString());
          DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
          DateTime start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
          DateTime end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
          if (justDate.isBefore(start) || justDate.isAfter(end)) return false;
        } catch (e) { return false; }
      }

      // 2. FILTRO POR DEPARTAMENTO
      if (_selectedDeptId != null && task['departmentId'] != _selectedDeptId) {
        return false;
      }

      // 3. FILTRO POR ESTADO
      final status = (task['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'Todas') return true;
      if (_selectedFilter == 'Pendientes') return status == 'PENDING';
      if (_selectedFilter == 'En Progreso') return status == 'IN_PROGRESS';
      if (_selectedFilter == 'Completadas') return status == 'COMPLETED';
      if (_selectedFilter == 'Atención') return status == 'REJECTED' || status == 'CANCELLED'; // Falta de aceptación / Apeladas
      
      return false;
    }).toList();

    _groupedTasks = _groupTasksByDate(filtered);
  }

  Map<String, List<dynamic>> _groupTasksByDate(List<dynamic> tasks) {
    Map<String, List<dynamic>> grouped = {};
    for (var task in tasks) {
      String dateStr = "Sin Fecha";
      if (task['createdAt'] != null) {
        try {
          DateTime date = DateTime.parse(task['createdAt'].toString());
          dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        } catch (e) { }
      }
      if (!grouped.containsKey(dateStr)) grouped[dateStr] = [];
      grouped[dateStr]!.add(task);
    }
    return grouped;
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final filters = ['Todas', 'Pendientes', 'En Progreso', 'Completadas', 'Atención'];

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Historial de Actividades", style: TextStyle(fontWeight: FontWeight.bold)),
  //     ),
  //     body: Column(
  //       children: [
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //           child: Row(
  //             children: [
  //               // BOTÓN FECHAS
  //               Padding(
  //                 padding: const EdgeInsets.only(right: 8),
  //                 child: ActionChip(
  //                   label: Icon(
  //                     _fechaInicio != null ? Icons.calendar_month_rounded : Icons.date_range_rounded,
  //                     size: 20, color: _fechaInicio != null ? colorScheme.onPrimary : colorScheme.primary,
  //                   ),
  //                   backgroundColor: _fechaInicio != null ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                   onPressed: _seleccionarRangoFechas,
  //                 ),
  //               ),
  //               if (_fechaInicio != null)
  //                 Padding(
  //                   padding: const EdgeInsets.only(right: 8),
  //                   child: ActionChip(
  //                     label: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
  //                     backgroundColor: colorScheme.error.withOpacity(0.1),
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                     onPressed: _limpiarFiltroFechas,
  //                   )
  //                 ),

  //               // BOTÓN DEPARTAMENTOS
  //               Padding(
  //                 padding: const EdgeInsets.only(right: 8),
  //                 child: ActionChip(
  //                   label: Row(
  //                     children: [
  //                       Icon(Icons.domain_rounded, size: 18, color: _selectedDeptId != null ? colorScheme.onPrimary : colorScheme.secondary),
  //                       if (_selectedDeptId != null) ...[
  //                         const SizedBox(width: 4),
  //                         Text(_departments.firstWhere((d) => d['id'] == _selectedDeptId, orElse: () => {'name': ''})['name'], style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12))
  //                       ]
  //                     ],
  //                   ),
  //                   backgroundColor: _selectedDeptId != null ? colorScheme.secondary : colorScheme.secondary.withOpacity(0.1),
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                   onPressed: _seleccionarDepartamento,
  //                 ),
  //               ),
  //               if (_selectedDeptId != null)
  //                 Padding(
  //                   padding: const EdgeInsets.only(right: 8),
  //                   child: ActionChip(
  //                     label: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
  //                     backgroundColor: colorScheme.error.withOpacity(0.1),
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                     onPressed: () { setState(() { _selectedDeptId = null; _applyFilter(); }); },
  //                   )
  //                 ),

  //               // FILTROS DE ESTADO
  //               ...filters.map((filter) {
  //                 final isSelected = _selectedFilter == filter;
  //                 return Padding(
  //                   padding: const EdgeInsets.only(right: 8),
  //                   child: ChoiceChip(
  //                     label: Text(filter, style: TextStyle(color: isSelected ? theme.cardColor : colorScheme.onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
  //                     selected: isSelected,
  //                     selectedColor: colorScheme.primary,
  //                     backgroundColor: colorScheme.onSurface.withOpacity(0.05),
  //                     onSelected: (selected) {
  //                       if (selected) setState(() { _selectedFilter = filter; _applyFilter(); });
  //                     },
  //                   ),
  //                 );
  //               }).toList(),
  //             ]
  //           ),
  //         ),

  //         // LISTA DE TAREAS
  //         Expanded(
  //           child: _isLoading
  //               ? UIHelper.buildSkeletonList(context)
  //               : _groupedTasks.isEmpty
  //                 ? UIHelper.emptyState(
  //                     context: context,
  //                     icon: Icons.assignment_turned_in_rounded,
  //                     title: "Historial Vacío",
  //                     message: "No se encontraron actividades con estos filtros.",
  //                   )
  //                 : ListView.builder(
  //                     padding: const EdgeInsets.all(16),
  //                     itemCount: _groupedTasks.keys.length,
  //                     itemBuilder: (context, index) {
  //                       String date = _groupedTasks.keys.elementAt(index);
  //                       List<dynamic> dayTasks = _groupedTasks[date]!;
  //                       return Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Padding(
  //                             padding: const EdgeInsets.symmetric(vertical: 10),
  //                             child: Text(date, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14)),
  //                           ),
  //                          ...dayTasks.map((task) => TaskCard(
  //                             task: task,
  //                             isEmployer: true, 
  //                             onRefresh: _loadData,
  //                           )).toList(),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final filters = ['Todas', 'Pendientes', 'En Proceso', 'Completadas', 'Atención'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Historial de Actividades", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILTROS SUPERIORES (CHIPS ESTILO PÍLDORA)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ...filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _selectedFilter = filter; _applyFilter(); });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4361EE) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.transparent : onSurface.withOpacity(0.2)),
                        ),
                        child: Text(
                          filter, 
                          style: TextStyle(
                            color: isSelected ? Colors.white : onSurface.withOpacity(0.8), 
                            fontWeight: FontWeight.bold,
                            fontSize: 13
                          )
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ]
            ),
          ),
          
          // FILTROS AVANZADOS (FECHA Y ÁREA OPCIONAL)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // BOTÓN FECHAS
                ActionChip(
                  label: Icon(
                    _fechaInicio != null ? Icons.calendar_month_rounded : Icons.date_range_rounded,
                    size: 20, color: _fechaInicio != null ? colorScheme.onPrimary : onSurface.withOpacity(0.6),
                  ),
                  backgroundColor: _fechaInicio != null ? colorScheme.primary : theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: onSurface.withOpacity(0.1))),
                  onPressed: _seleccionarRangoFechas,
                ),
                if (_fechaInicio != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: Icon(Icons.close_rounded, size: 18, color: colorScheme.error),
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      onPressed: _limpiarFiltroFechas,
                    )
                  ),

                const SizedBox(width: 8),
                // BOTÓN DEPARTAMENTOS
                ActionChip(
                  label: Row(
                    children: [
                      Icon(Icons.domain_rounded, size: 18, color: _selectedDeptId != null ? colorScheme.onPrimary : onSurface.withOpacity(0.6)),
                      if (_selectedDeptId != null) ...[
                        const SizedBox(width: 4),
                        Text(_departments.firstWhere((d) => d['id'] == _selectedDeptId, orElse: () => {'name': ''})['name'], style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12))
                      ]
                    ],
                  ),
                  backgroundColor: _selectedDeptId != null ? colorScheme.primary : theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: onSurface.withOpacity(0.1))),
                  onPressed: _seleccionarDepartamento,
                ),
                if (_selectedDeptId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: Icon(Icons.close_rounded, size: 18, color: colorScheme.error),
                      backgroundColor: colorScheme.error.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      onPressed: () { setState(() { _selectedDeptId = null; _applyFilter(); }); },
                    )
                  ),
              ],
            ),
          ),

          // LISTA DE TAREAS AGRUPADAS
          Expanded(
            child: _isLoading
                ? UIHelper.buildSkeletonList(context)
                : _groupedTasks.isEmpty
                  ? UIHelper.emptyState(
                      context: context,
                      icon: Icons.assignment_turned_in_rounded,
                      title: "Historial Vacío",
                      message: "No se encontraron actividades con estos filtros.",
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groupedTasks.keys.length,
                      itemBuilder: (context, index) {
                        String date = _groupedTasks.keys.elementAt(index);
                        List<dynamic> dayTasks = _groupedTasks[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER DE FECHA ESTILO MOCKUP
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: const Color(0xFFBAC3FF), size: 18),
                                  const SizedBox(width: 8),
                                  Text(date, style: const TextStyle(color: Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                           ...dayTasks.map((task) => TaskCard(
                              task: task,
                              isEmployer: true, 
                              onRefresh: _loadData,
                            )).toList(),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}