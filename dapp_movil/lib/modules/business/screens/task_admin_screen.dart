import 'dart:ui' as pw;

import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/business/screens/ai_task_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';
import '../services/business_task_service.dart';
import '../widgets/task_card.dart';
import '../modals/create_task_modal.dart';

class TaskAdminScreen extends StatefulWidget {
  const TaskAdminScreen({super.key});

  @override
  State<TaskAdminScreen> createState() => _TaskAdminScreenState();
}

class _TaskAdminScreenState extends State<TaskAdminScreen> {
  List<dynamic> _allTasks = [];
  List<dynamic> _teamMembers = [];
  List<dynamic> _departments = [];
  bool _isLoading = true;

  // Estados de Filtros Activos
  String? _selectedWallet;
  String? _selectedDepartmentId;
  String? _selectedStatus;
  DateTime? _selectedDate;

  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // Future<void> _loadAdminData() async {
  //   if (!mounted) return;
  //   setState(() => _isLoading = true);

  //   try {
  //     final bService = Provider.of<BusinessService>(context, listen: false);
  //     final taskService = Provider.of<BusinessTaskService>(context, listen: false);
      
  //     // Cargamos paralelamente todo el contexto operacional
  //     final tasksData = await taskService.getEmployerTasks();
  //     final deptsData = await bService.getDepartments();
  //     final teamData = await bService.getTeamWithDetails();

  //     if (mounted) {
  //       setState(() {
  //         _allTasks = tasksData;
  //         _departments = deptsData;
  //         _teamMembers = teamData;
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       UIHelper.showCustomSnackbar("Error cargando el ecosistema de tareas", isError: true);
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    final cacheService = LocalCacheService();

    // 1. Caché Rápido
    final cachedTasks = cacheService.getCachedEmployerTasks();
    final cachedDepts = cacheService.getCachedDepartments();
    final cachedTeam = cacheService.getCachedTeamWithDetails();

    if (cachedTasks.isNotEmpty || cachedDepts.isNotEmpty || cachedTeam.isNotEmpty) {
      setState(() {
        _allTasks = cachedTasks;
        _departments = cachedDepts;
        _teamMembers = cachedTeam;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Petición a Red
    try {
      final bService = Provider.of<BusinessService>(context, listen: false);
      final taskService = Provider.of<BusinessTaskService>(context, listen: false);
      
      final tasksData = await taskService.getEmployerTasks();
      final deptsData = await bService.getDepartments();
      final teamData = await bService.getTeamWithDetails();

      if (mounted) {
        setState(() {
          _allTasks = tasksData;
          _departments = deptsData;
          _teamMembers = teamData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _allTasks.isEmpty) {
        UIHelper.showCustomSnackbar("Error cargando el ecosistema de tareas", isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔥 MOTOR DE FILTRADO EN TIEMPO REAL
  List<dynamic> _getFilteredTasks() {
    return _allTasks.where((task) {
      // 1. Filtro por Empleado Asignado
      if (_selectedWallet != null && task['assignedWallet'] != _selectedWallet) {
        return false;
      }
      // 2. Filtro por Departamento
      if (_selectedDepartmentId != null && task['departmentId'] != _selectedDepartmentId) {
        return false;
      }
      // 3. Filtro por Estado (PENDING, COMPLETED, REWORK_REQUESTED, etc.)
      if (_selectedStatus != null && task['status'] != _selectedStatus) {
        return false;
      }
      // 4. Filtro por Fecha (Mismo año, mes y día de entrega)
      if (_selectedDate != null) {
        if (task['deadline'] == null) return false;
        DateTime? taskDeadline = DateTime.tryParse(task['deadline'].toString());
        if (taskDeadline == null) return false;

        if (taskDeadline.year != _selectedDate!.year ||
            taskDeadline.month != _selectedDate!.month ||
            taskDeadline.day != _selectedDate!.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _selectedWallet = null;
      _selectedDepartmentId = null;
      _selectedStatus = null;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
        title: const Text("Panel de Administración", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: theme.cardColor,
        elevation: 0,
        actions: [
          // 🔥 NUEVO: BOTÓN DE EXPORTAR PDF
         IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "Exportar Reporte PDF",
            onPressed: () => _mostrarModalConfiguracionPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.grey),
            tooltip: "Limpiar Filtros",
            onPressed: _limpiarFiltros,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🛠️ SECCIÓN DE FILTROS AVANZADOS (ZONA HORIZONTAL SCROLL)
                Container(
                  color: theme.cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // FILTRO A: EMPLEADOS
                        _buildFilterDropdown<String>(
                          hint: "Filtrar Empleado",
                          value: _selectedWallet,
                          items: _teamMembers.map((m) {
                            String name = m['alias'] ?? m['name'] ?? 'Usuario';
                            String wallet = m['walletAddress'] ?? m['wallet'] ?? '';
                            return DropdownMenuItem<String>(
                              value: wallet.toLowerCase(),
                              child: Text("@$name", style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedWallet = val),
                        ),
                        const SizedBox(width: 8),

                        // FILTRO B: DEPARTAMENTOS
                        _buildFilterDropdown<String>(
                          hint: "Filtrar Área",
                          value: _selectedDepartmentId,
                          items: _departments.map((d) {
                            return DropdownMenuItem<String>(
                              value: d['id'].toString(),
                              child: Text(d['name'] ?? '', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedDepartmentId = val),
                        ),
                        const SizedBox(width: 8),

                        // FILTRO C: ESTADOS
                        _buildFilterDropdown<String>(
                          hint: "Filtrar Estado",
                          value: _selectedStatus,
                          items: const [
                            DropdownMenuItem(value: "PENDING", child: Text("Pendientes", style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: "IN_PROGRESS", child: Text("En Progreso", style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: "COMPLETED", child: Text("Completadas", style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: "REWORK_REQUESTED", child: Text("En Corrección", style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: "APPROVED", child: Text("Aprobadas", style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                        const SizedBox(width: 8),

                        // FILTRO D: CALENDARIO / FECHAS
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedDate != null ? colorScheme.primary : theme.scaffoldBackgroundColor,
                            foregroundColor: _selectedDate != null ? Colors.white : colorScheme.onSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.calendar_month_rounded, size: 16),
                          label: Text(
                            _selectedDate == null 
                                ? "Por Fecha" 
                                : "${_selectedDate!.day}/${_selectedDate!.month}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 📋 LISTADO DE RESULTADOS FILTRADOS
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAdminData,
                    child: filteredTasks.isEmpty
                        ? UIHelper.emptyState(
                            context: context,
                            icon: Icons.filter_list_off_rounded,
                            title: "Sin Tareas Coincidentes",
                            message: "Ninguna actividad cumple con los filtros seleccionados actualmente.",
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTasks.length,
                            itemBuilder: (ctx, i) {
                              return TaskCard(
                                task: filteredTasks[i],
                                isEmployer: true, // Modo Administración de Gerencia
                                onRefresh: _loadAdminData, // Acción de refresco al volver de los detalles
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // Importante para que no ocupe toda la pantalla
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🤖 OPCIONES DESPLEGADAS
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              heroTag: "btn_ai_audit",
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              onPressed: () {
                setState(() => _isFabExpanded = false); // Cerramos el menú al hacer clic
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => AiTaskReportScreen(
                    allTasks: _allTasks, 
                    onRefreshBack: _loadAdminData
                  ))
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text("Auditoría IA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            
            FloatingActionButton.extended(
              heroTag: "btn_new_task",
              onPressed: () {
                setState(() => _isFabExpanded = false); // Cerramos el menú al hacer clic
                CreateTaskModal.show(context, _teamMembers, _departments, _loadAdminData);
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text("Nueva Actividad"),
            ),
            const SizedBox(height: 12),
          ],
          
          // 🔥 BOTÓN PRINCIPAL (TOGGLE)
          FloatingActionButton(
            heroTag: "btn_main_toggle",
            backgroundColor: _isFabExpanded ? Colors.grey.shade700 : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            // Animación suave del ícono (Cambia de Menú a X)
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: child.key == const ValueKey('icon1') ? Tween<double>(begin: 1, end: 0.75).animate(anim) : Tween<double>(begin: 0.75, end: 1).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _isFabExpanded
                  ? const Icon(Icons.close_rounded, key: ValueKey('icon1'))
                  : const Icon(Icons.dashboard_customize_rounded, key: ValueKey('icon2')),
            ),
          ),
        ],
      ),
    );
  }


  // 🔥 MODAL FLOTANTE CON FILTROS EXCLUSIVOS PARA LA GENERACIÓN DEL REPORTE PDF
  void _mostrarModalConfiguracionPDF(BuildContext context) {
    // Variables locales para aislar los filtros del PDF de la UI trasera
    String? pdfWallet;
    String? pdfDepartmentId;
    String? pdfStatus;
    DateTime? pdfDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text("Configurar Reporte PDF", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Selecciona los criterios específicos que se incluirán en el documento final corporativo.", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const Divider(height: 24),

                  // 👥 SELECTOR DE EMPLEADO
                  const Text("Filtrar por Empleado", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Todos los empleados", style: TextStyle(fontSize: 13)),
                        value: pdfWallet,
                        items: _teamMembers.map((m) {
                          String name = m['alias'] ?? m['name'] ?? 'Usuario';
                          String wallet = m['walletAddress'] ?? m['wallet'] ?? '';
                          return DropdownMenuItem<String>(value: wallet.toLowerCase(), child: Text("@$name"));
                        }).toList(),
                        onChanged: (val) => setModalState(() => pdfWallet = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🏢 SELECTOR DE ÁREA / DEPARTAMENTO
                  const Text("Filtrar por Departamento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Todas las áreas", style: TextStyle(fontSize: 13)),
                        value: pdfDepartmentId,
                        items: _departments.map((d) {
                          return DropdownMenuItem<String>(value: d['id'].toString(), child: Text(d['name'] ?? ''));
                        }).toList(),
                        onChanged: (val) => setModalState(() => pdfDepartmentId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📊 SELECTOR DE ESTADO operacional
                  const Text("Filtrar por Estado", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text("Todos los estados", style: TextStyle(fontSize: 13)),
                        value: pdfStatus,
                        items: const [
                          DropdownMenuItem(value: "PENDING", child: Text("Pendientes")),
                          DropdownMenuItem(value: "IN_PROGRESS", child: Text("En Progreso")),
                          DropdownMenuItem(value: "COMPLETED", child: Text("En Revisión")),
                          DropdownMenuItem(value: "REWORK_REQUESTED", child: Text("En Corrección")),
                          DropdownMenuItem(value: "APPROVED", child: Text("Aprobadas")),
                        ],
                        onChanged: (val) => setModalState(() => pdfStatus = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📅 SELECCIÓN DE CRITERIO CRONOLÓGICO
                  const Text("Filtrar por Fecha de Entrega", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pdfDate == null 
                              ? "Cualquier fecha asignada" 
                              : "Fecha seleccionada: ${pdfDate!.day}/${pdfDate!.month}/${pdfDate!.year}",
                          style: TextStyle(fontSize: 13, color: pdfDate == null ? Colors.grey : Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(backgroundColor: Theme.of(context).scaffoldBackgroundColor),
                        icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.redAccent),
                        label: Text(pdfDate == null ? "Elegir" : "Cambiar", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => pdfDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 📄 BOTÓN MAESTRO DE ACCIÓN Y PROCESAMIENTO MATRICIAL
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("Generar Reporte PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () {
                        // Filtrar la lista total en base a los parámetros locales escogidos en el modal
                        final pdfFilteredList = _allTasks.where((task) {
                          if (pdfWallet != null && task['assignedWallet'] != pdfWallet) return false;
                          if (pdfDepartmentId != null && task['departmentId'] != pdfDepartmentId) return false;
                          if (pdfStatus != null && task['status'] != pdfStatus) return false;
                          if (pdfDate != null) {
                            if (task['deadline'] == null) return false;
                            DateTime? taskDeadline = DateTime.tryParse(task['deadline'].toString());
                            if (taskDeadline == null) return false;
                            if (taskDeadline.year != pdfDate!.year || taskDeadline.month != pdfDate!.month || taskDeadline.day != pdfDate!.day) return false;
                          }
                          return true;
                        }).toList();

                        if (pdfFilteredList.isEmpty) {
                          UIHelper.showCustomSnackbar("No se encontraron registros que coincidan con estos filtros específicos para el PDF.", isError: true);
                          return;
                        }

                        // Cerrar modal
                        Navigator.pop(ctx);

                        // Disparar renderizador de PDF
                        String subTituloReporte = "Criterio - Estado: ${pdfStatus ?? 'Todos'} | Área: ${pdfDepartmentId ?? 'Todas'}";
                        ShareHelper.exportarReporteTareasPDF(context, pdfFilteredList, subTituloReporte);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // HELPER PARA CONSTRUIR LOS DROPDOWNS COMPACTOS EN LA BARRA DE HERRAMIENTAS
  Widget _buildFilterDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null ? theme.colorScheme.primary.withOpacity(0.12) : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value != null ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(hint, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ),
      ),
    );
  }
}