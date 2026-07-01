import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';
import '../widgets/task_card.dart';

class TaskEmployeeScreen extends StatefulWidget {
  const TaskEmployeeScreen({super.key});

  @override
  State<TaskEmployeeScreen> createState() => _TaskEmployeeScreenState();
}

class _TaskEmployeeScreenState extends State<TaskEmployeeScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  // Future<void> _loadEmployeeData() async {
  //   if (!mounted) return;
  //   setState(() => _isLoading = true);

  //   try {
  //     final taskService = Provider.of<BusinessTaskService>(context, listen: false);
  //     List<dynamic> tasksData = await taskService.getEmployeeTasks();

  //     // 🔥 ORDENAMIENTO CRÍTICO: Ponemos las tareas "REWORK_REQUESTED" siempre primero
  //     tasksData.sort((a, b) {
  //       if (a['status'] == 'REWORK_REQUESTED' && b['status'] != 'REWORK_REQUESTED') return -1;
  //       if (b['status'] == 'REWORK_REQUESTED' && a['status'] != 'REWORK_REQUESTED') return 1;
  //       return 0; // Conserva el orden original (por fecha) para el resto
  //     });

  //     if (mounted) {
  //       setState(() {
  //         _tasks = tasksData;
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       UIHelper.showCustomSnackbar("Error cargando tus actividades", isError: true);
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _loadEmployeeData() async {
    if (!mounted) return;
    final cacheService = LocalCacheService();

    // 1. Función interna de ordenamiento (reutilizable)
    void ordenarTareas(List<dynamic> lista) {
      lista.sort((a, b) {
        if (a['status'] == 'REWORK_REQUESTED' && b['status'] != 'REWORK_REQUESTED') return -1;
        if (b['status'] == 'REWORK_REQUESTED' && a['status'] != 'REWORK_REQUESTED') return 1;
        return 0;
      });
    }

    // 2. Caché Rápido
    final cachedTasks = cacheService.getCachedEmployeeTasks();
    if (cachedTasks.isNotEmpty) {
      ordenarTareas(cachedTasks);
      setState(() {
        _tasks = cachedTasks;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    // 3. Petición a Red
    try {
      final taskService = Provider.of<BusinessTaskService>(context, listen: false);
      List<dynamic> tasksData = await taskService.getEmployeeTasks();

      ordenarTareas(tasksData);

      if (mounted) {
        setState(() {
          _tasks = tasksData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _tasks.isEmpty) {
        UIHelper.showCustomSnackbar("Error cargando tus actividades", isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredTasks() {
    if (_selectedStatus == null) return _tasks;
    return _tasks.where((t) => t['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mis Actividades", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🛠️ BARRA DE FILTROS SIMPLIFICADA PARA EL EMPLEADO
                Container(
                  color: theme.cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text("Todas mis tareas", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              value: _selectedStatus,
                              items: const [
                                DropdownMenuItem(value: null, child: Text("Todas mis tareas")),
                                DropdownMenuItem(value: "PENDING", child: Text("Pendientes")),
                                DropdownMenuItem(value: "IN_PROGRESS", child: Text("En Progreso")),
                                DropdownMenuItem(value: "REWORK_REQUESTED", child: Text("⚠️ Por Corregir (Rework)")),
                                DropdownMenuItem(value: "COMPLETED", child: Text("En Revisión")),
                                DropdownMenuItem(value: "APPROVED", child: Text("Aprobadas")),
                              ],
                              onChanged: (val) => setState(() => _selectedStatus = val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📋 LISTADO DE TAREAS
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEmployeeData,
                    child: filteredTasks.isEmpty
                        ? UIHelper.emptyState(
                            context: context,
                            icon: Icons.task_alt_rounded,
                            title: "Todo al día",
                            message: "No tienes actividades pendientes por ahora.",
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTasks.length,
                            itemBuilder: (ctx, i) {
                              return TaskCard(
                                task: filteredTasks[i],
                                isEmployer: false, // 🔥 Modo Empleado
                                onRefresh: _loadEmployeeData,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}