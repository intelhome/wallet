import 'dart:ui' as pw;

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/share_helper.dart';
import 'package:dapp_movil/core/notifications/push_notification_service.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/business/screens/ai_task_report_screen.dart';
import 'package:dapp_movil/modules/business/screens/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
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

  IOWebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _conectarWebSocket();
  }

  void _conectarWebSocket() {
    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = "$baseWsUrl/ws/notifications/${authCore.publicAddress.toLowerCase()}";
      
      _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: authCore.authHeaders);
      _wsChannel!.stream.listen((message) {
        _loadAdminData();
        PushNotificationService.showLocalNotification("Alerta Operativa 📋", "Un empleado ha interactuado con una tarea asignada.");
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    super.dispose();
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

  // MOTOR DE FILTRADO EN TIEMPO REAL
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

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final filteredTasks = _getFilteredTasks();

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //   appBar: AppBar(
  //       title: const Text("Panel de Administración", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  //       backgroundColor: theme.cardColor,
  //       elevation: 0,
  //       actions: [
  //         // 🔥 NUEVO: BOTÓN DE EXPORTAR PDF
  //        IconButton(
  //           icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
  //           tooltip: "Exportar Reporte PDF",
  //           onPressed: () => _mostrarModalConfiguracionPDF(context),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.grey),
  //           tooltip: "Limpiar Filtros",
  //           onPressed: _limpiarFiltros,
  //         ),
  //       ],
  //     ),
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : Column(
  //             children: [
  //               // 🛠️ SECCIÓN DE FILTROS AVANZADOS (ZONA HORIZONTAL SCROLL)
  //               Container(
  //                 color: theme.cardColor,
  //                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: Row(
  //                     children: [
  //                       // FILTRO A: EMPLEADOS
  //                       _buildFilterDropdown<String>(
  //                         hint: "Filtrar Empleado",
  //                         value: _selectedWallet,
  //                         items: _teamMembers.map((m) {
  //                           String name = m['alias'] ?? m['name'] ?? 'Usuario';
  //                           String wallet = m['walletAddress'] ?? m['wallet'] ?? '';
  //                           return DropdownMenuItem<String>(
  //                             value: wallet.toLowerCase(),
  //                             child: Text("@$name", style: const TextStyle(fontSize: 13)),
  //                           );
  //                         }).toList(),
  //                         onChanged: (val) => setState(() => _selectedWallet = val),
  //                       ),
  //                       const SizedBox(width: 8),

  //                       // FILTRO B: DEPARTAMENTOS
  //                       _buildFilterDropdown<String>(
  //                         hint: "Filtrar Área",
  //                         value: _selectedDepartmentId,
  //                         items: _departments.map((d) {
  //                           return DropdownMenuItem<String>(
  //                             value: d['id'].toString(),
  //                             child: Text(d['name'] ?? '', style: const TextStyle(fontSize: 13)),
  //                           );
  //                         }).toList(),
  //                         onChanged: (val) => setState(() => _selectedDepartmentId = val),
  //                       ),
  //                       const SizedBox(width: 8),

  //                       // FILTRO C: ESTADOS
  //                       _buildFilterDropdown<String>(
  //                         hint: "Filtrar Estado",
  //                         value: _selectedStatus,
  //                         items: const [
  //                           DropdownMenuItem(value: "PENDING", child: Text("Pendientes", style: TextStyle(fontSize: 13))),
  //                           DropdownMenuItem(value: "IN_PROGRESS", child: Text("En Progreso", style: TextStyle(fontSize: 13))),
  //                           DropdownMenuItem(value: "COMPLETED", child: Text("Completadas", style: TextStyle(fontSize: 13))),
  //                           DropdownMenuItem(value: "REWORK_REQUESTED", child: Text("En Corrección", style: TextStyle(fontSize: 13))),
  //                           DropdownMenuItem(value: "APPROVED", child: Text("Aprobadas", style: TextStyle(fontSize: 13))),
  //                         ],
  //                         onChanged: (val) => setState(() => _selectedStatus = val),
  //                       ),
  //                       const SizedBox(width: 8),

  //                       // FILTRO D: CALENDARIO / FECHAS
  //                       ElevatedButton.icon(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: _selectedDate != null ? colorScheme.primary : theme.scaffoldBackgroundColor,
  //                           foregroundColor: _selectedDate != null ? Colors.white : colorScheme.onSurface,
  //                           elevation: 0,
  //                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                         ),
  //                         icon: const Icon(Icons.calendar_month_rounded, size: 16),
  //                         label: Text(
  //                           _selectedDate == null 
  //                               ? "Por Fecha" 
  //                               : "${_selectedDate!.day}/${_selectedDate!.month}",
  //                           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  //                         ),
  //                         onPressed: () async {
  //                           DateTime? picked = await showDatePicker(
  //                             context: context,
  //                             initialDate: DateTime.now(),
  //                             firstDate: DateTime(2020),
  //                             lastDate: DateTime(2030),
  //                           );
  //                           if (picked != null) {
  //                             setState(() => _selectedDate = picked);
  //                           }
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),

  //               // 📋 LISTADO DE RESULTADOS FILTRADOS
  //               Expanded(
  //                 child: RefreshIndicator(
  //                   onRefresh: _loadAdminData,
  //                   child: filteredTasks.isEmpty
  //                       ? UIHelper.emptyState(
  //                           context: context,
  //                           icon: Icons.filter_list_off_rounded,
  //                           title: "Sin Tareas Coincidentes",
  //                           message: "Ninguna actividad cumple con los filtros seleccionados actualmente.",
  //                         )
  //                       : ListView.builder(
  //                           padding: const EdgeInsets.all(16),
  //                           itemCount: filteredTasks.length,
  //                           itemBuilder: (ctx, i) {
  //                             return TaskCard(
  //                               task: filteredTasks[i],
  //                               isEmployer: true, // Modo Administración de Gerencia
  //                               onRefresh: _loadAdminData, // Acción de refresco al volver de los detalles
  //                             );
  //                           },
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //   floatingActionButton: Column(
  //       mainAxisSize: MainAxisSize.min, // Importante para que no ocupe toda la pantalla
  //       crossAxisAlignment: CrossAxisAlignment.end,
  //       children: [
  //         // 🤖 OPCIONES DESPLEGADAS
  //         if (_isFabExpanded) ...[
  //           FloatingActionButton.extended(
  //             heroTag: "btn_ai_audit",
  //             backgroundColor: Colors.deepPurpleAccent,
  //             foregroundColor: Colors.white,
  //             onPressed: () {
  //               setState(() => _isFabExpanded = false); // Cerramos el menú al hacer clic
  //               Navigator.push(
  //                 context, 
  //                 MaterialPageRoute(builder: (_) => AiTaskReportScreen(
  //                   allTasks: _allTasks, 
  //                   onRefreshBack: _loadAdminData
  //                 ))
  //               );
  //             },
  //             icon: const Icon(Icons.auto_awesome_rounded),
  //             label: const Text("Auditoría IA", style: TextStyle(fontWeight: FontWeight.bold)),
  //           ),
  //           const SizedBox(height: 12),
            
  //           FloatingActionButton.extended(
  //             heroTag: "btn_new_task",
  //             onPressed: () {
  //               setState(() => _isFabExpanded = false); // Cerramos el menú al hacer clic
  //               CreateTaskModal.show(context, _teamMembers, _departments, _loadAdminData);
  //             },
  //             icon: const Icon(Icons.add_task_rounded),
  //             label: const Text("Nueva Actividad"),
  //           ),
  //           const SizedBox(height: 12),
  //         ],
          
  //         // 🔥 BOTÓN PRINCIPAL (TOGGLE)
  //         FloatingActionButton(
  //           heroTag: "btn_main_toggle",
  //           backgroundColor: _isFabExpanded ? Colors.grey.shade700 : Theme.of(context).colorScheme.primary,
  //           foregroundColor: Colors.white,
  //           onPressed: () {
  //             setState(() {
  //               _isFabExpanded = !_isFabExpanded;
  //             });
  //           },
  //           // Animación suave del ícono (Cambia de Menú a X)
  //           child: AnimatedSwitcher(
  //             duration: const Duration(milliseconds: 200),
  //             transitionBuilder: (child, anim) => RotationTransition(
  //               turns: child.key == const ValueKey('icon1') ? Tween<double>(begin: 1, end: 0.75).animate(anim) : Tween<double>(begin: 0.75, end: 1).animate(anim),
  //               child: ScaleTransition(scale: anim, child: child),
  //             ),
  //             child: _isFabExpanded
  //                 ? const Icon(Icons.close_rounded, key: ValueKey('icon1'))
  //                 : const Icon(Icons.dashboard_customize_rounded, key: ValueKey('icon2')),
  //           ),
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
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SmartAvatar(
            address: Provider.of<AuthCoreService>(context, listen: false).publicAddress, 
            size: 36
          ),
        ),
        title: const Text("Panel de actividades", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf_outlined, color: onSurface.withOpacity(0.7)),
            tooltip: "Exportar Reporte PDF",
            onPressed: () => _mostrarModalConfiguracionPDF(context),
          ),
          IconButton(
            icon: Icon(Icons.filter_list_off_rounded, color: onSurface.withOpacity(0.7)),
            tooltip: "Limpiar Filtros",
            onPressed: _limpiarFiltros,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🛠️ FILTROS (DISEÑO UNIFICADO OSCURO)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // ESTADO
                        _buildFilterDropdown<String>(
                          hint: "Estado: Todos",
                          value: _selectedStatus,
                          items: const [
                            DropdownMenuItem(value: "PENDING", child: Text("Pendientes")),
                            DropdownMenuItem(value: "IN_PROGRESS", child: Text("En Progreso")),
                            DropdownMenuItem(value: "COMPLETED", child: Text("En Revisión")),
                            DropdownMenuItem(value: "REWORK_REQUESTED", child: Text("En Corrección")),
                            DropdownMenuItem(value: "APPROVED", child: Text("Aprobadas")),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                        const SizedBox(width: 12),

                        // ÁREA (Sustituye al de prioridad de la imagen para mantener tu funcionalidad)
                        _buildFilterDropdown<String>(
                          hint: "Área: Todas",
                          value: _selectedDepartmentId,
                          items: _departments.map((d) {
                            return DropdownMenuItem<String>(
                              value: d['id'].toString(),
                              child: Text(d['name'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedDepartmentId = val),
                        ),
                        const SizedBox(width: 12),

                        // FECHA (Estilizado como dropdown)
                        InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: onSurface.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedDate == null 
                                      ? "Fecha: Todas" 
                                      : "Fecha: ${_selectedDate!.day}/${_selectedDate!.month}",
                                  style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.6), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Divider(color: onSurface.withOpacity(0.05), height: 1),
                const SizedBox(height: 16),

                // 📋 CABECERA DE LOGS
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Envolvemos el título en un Expanded para evitar el overflow en pantallas pequeñas
                      Expanded(
                        child: Text(
                          "Registro de Auditoría", 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Mostrando ${filteredTasks.length} de ${_allTasks.length} registros", 
                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LISTA DE AUDITORÍA (NUEVO DISEÑO DE CARDS)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAdminData,
                    child: filteredTasks.isEmpty
                        ? UIHelper.emptyState(context: context, icon: Icons.filter_list_off_rounded, title: "Sin Resultados", message: "Ninguna actividad cumple con los filtros.")
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredTasks.length,
                            itemBuilder: (ctx, i) {
                              final task = filteredTasks[i];
                              final urgency = task['urgency'] ?? 'MEDIUM';
                              final status = task['status'] ?? 'PENDING';
                              final title = task['title'] ?? 'Operación de Sistema';
                              final desc = task['description'] ?? 'Detalles no proporcionados.';
                              final type = task['taskType'] ?? 'STANDARD';
                              
                              // Formateo de fecha
                              final rawDate = task['createdAt']?.toString() ?? '';
                              String dateStr = "Reciente";
                              if (rawDate.length >= 16) {
                                dateStr = "${rawDate.substring(8, 10)}/${rawDate.substring(5, 7)}, ${rawDate.substring(11, 16)}";
                              }

                              // Colores e Íconos Dinámicos
                              Color indicatorColor = urgency == 'URGENT' || urgency == 'HIGH' ? Colors.redAccent : urgency == 'MEDIUM' ? Colors.orangeAccent : onSurface.withOpacity(0.5);
                              IconData iconLog = urgency == 'URGENT' || urgency == 'HIGH' ? Icons.warning_amber_rounded : urgency == 'MEDIUM' ? Icons.account_balance_rounded : Icons.sync_rounded;
                              
                              // Traducción de Urgencia
                              String urgencyText = urgency == 'URGENT' ? 'URGENCIA EXTREMA' : urgency == 'HIGH' ? 'URGENCIA ALTA' : urgency == 'MEDIUM' ? 'URGENCIA MEDIA' : 'URGENCIA BAJA';
                              
                              // Traducción de Estado
                              String statusText = status == 'PENDING' ? 'Pendiente' : status == 'IN_PROGRESS' ? 'En Progreso' : status == 'COMPLETED' ? 'En Revisión' : status == 'REWORK_REQUESTED' ? 'En Corrección' : 'Aprobada';
                              IconData statusIcon = status == 'APPROVED' ? Icons.verified_rounded : status == 'COMPLETED' ? Icons.fact_check_rounded : Icons.pending_actions_rounded;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                color: theme.cardColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: onSurface.withOpacity(0.05)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                 onTap: () {
                                    // Abrimos la pantalla de detalles de la tarea
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailsScreen(
                                          task: task,
                                          isEmployer: true,
                                          onRefresh: _loadAdminData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(border: Border(left: BorderSide(color: indicatorColor, width: 4))),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: indicatorColor.withOpacity(0.1), 
                                                borderRadius: BorderRadius.circular(8), 
                                                border: Border.all(color: indicatorColor.withOpacity(0.3))
                                              ),
                                              child: Icon(iconLog, color: indicatorColor, size: 24),
                                            ),
                                            Text(dateStr, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            // Badge Urgencia
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                              decoration: BoxDecoration(
                                                color: indicatorColor.withOpacity(0.1), 
                                                borderRadius: BorderRadius.circular(6), 
                                                border: Border.all(color: indicatorColor.withOpacity(0.3))
                                              ), 
                                              child: Text(urgencyText, style: TextStyle(color: indicatorColor, fontSize: 10, fontWeight: FontWeight.bold))
                                            ),
                                            const SizedBox(width: 8),
                                            // Badge Tipo de Tarea
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                              decoration: BoxDecoration(
                                                color: onSurface.withOpacity(0.05), 
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: onSurface.withOpacity(0.1))
                                              ), 
                                              child: Text(type.toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold))
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(desc, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 16),
                                        // Badge de Estado Final
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary.withOpacity(0.1), 
                                            borderRadius: BorderRadius.circular(6), 
                                            border: Border.all(color: colorScheme.primary.withOpacity(0.3))
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, size: 14, color: colorScheme.primary),
                                              const SizedBox(width: 6),
                                              Text(statusText, style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🤖 OPCIONES DESPLEGADAS
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              heroTag: "btn_ai_audit",
              backgroundColor: const Color(0xFFBAC3FF), // Color claro acorde al tema
              foregroundColor: const Color(0xFF00218d),
              onPressed: () {
                setState(() => _isFabExpanded = false);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => AiTaskReportScreen(allTasks: _allTasks, onRefreshBack: _loadAdminData))
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text("Auditoría IA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            
            FloatingActionButton.extended(
              heroTag: "btn_new_task",
              backgroundColor: const Color(0xFFBAC3FF),
              foregroundColor: const Color(0xFF00218d),
              onPressed: () {
                setState(() => _isFabExpanded = false);
                CreateTaskModal.show(context, _teamMembers, _departments, _loadAdminData);
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text("Nueva Actividad", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
          
          // 🔥 BOTÓN PRINCIPAL (TOGGLE)
          FloatingActionButton(
            heroTag: "btn_main_toggle",
            backgroundColor: _isFabExpanded ? onSurface.withOpacity(0.2) : const Color(0xFFBAC3FF),
            foregroundColor: _isFabExpanded ? onSurface : const Color(0xFF00218d),
            elevation: 0,
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: child.key == const ValueKey('icon1') ? Tween<double>(begin: 1, end: 0.75).animate(anim) : Tween<double>(begin: 0.75, end: 1).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _isFabExpanded
                  ? const Icon(Icons.close_rounded, key: ValueKey('icon1'))
                  : const Icon(Icons.fact_check_outlined, key: ValueKey('icon2')),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER REFACTORIZADO PARA LOS DROPDOWNS DEL HEADER
  Widget _buildFilterDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(hint, style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold)),
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.bold),
          icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.6), size: 20),
        ),
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
  // Widget _buildFilterDropdown<T>({
  //   required String hint,
  //   required T? value,
  //   required List<DropdownMenuItem<T>> items,
  //   required ValueChanged<T?> onChanged,
  // }) {
  //   final theme = Theme.of(context);
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12),
  //     decoration: BoxDecoration(
  //       color: value != null ? theme.colorScheme.primary.withOpacity(0.12) : theme.scaffoldBackgroundColor,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: value != null ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.08)),
  //     ),
  //     child: DropdownButtonHideUnderline(
  //       child: DropdownButton<T>(
  //         hint: Text(hint, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
  //         value: value,
  //         items: items,
  //         onChanged: onChanged,
  //         style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
  //         icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
  //       ),
  //     ),
  //   );
  // }
}