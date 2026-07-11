import 'dart:async';

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/notifications/push_notification_service.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
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
  
  Timer? _deadlineTimer;
  final Set<String> _notifiedTasks = {}; // Evitar spam de la misma notificación

IOWebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    _iniciarRastreadorDeVencimientos();
    _conectarWebSocket();
  }

  void _conectarWebSocket() {
    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = "$baseWsUrl/ws/notifications/${authCore.publicAddress.toLowerCase()}";
      
      _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: authCore.authHeaders);
      _wsChannel!.stream.listen((message) {
        _loadEmployeeData();
        PushNotificationService.showLocalNotification("Actualización de Tarea 📋", "Tu empleador ha actualizado el estado de tus actividades.");
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _deadlineTimer?.cancel();
    super.dispose();
  }

  // 🔥 MOTOR DE ALERTAS GEORREFERENCIADAS / TIEMPO (2 HORAS ANTES)
  void _iniciarRastreadorDeVencimientos() {
    _deadlineTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();

      for (var task in _tasks) {
        // Solo alertamos de tareas activas
        if (task['status'] == 'PENDING' || task['status'] == 'IN_PROGRESS' || task['status'] == 'REWORK_REQUESTED') {
          if (task['deadline'] != null) {
            DateTime? deadline = DateTime.tryParse(task['deadline'].toString())?.toLocal();
            
            if (deadline != null) {
              final diff = deadline.difference(now);
              
              // Si faltan exactamente entre 1h 59m y 2h 00m, disparamos el Push
              if (diff.inMinutes <= 120 && diff.inMinutes > 118 && !_notifiedTasks.contains(task['id'])) {
                PushNotificationService.showLocalNotification(
                  "⏰ Actividad por vencer",
                  "Tu tarea '${task['title']}' vence en 2 horas. ¡Evita penalizaciones!",
                );
                _notifiedTasks.add(task['id'].toString());
              }
            }
          }
        }
      }
    });
  }

  Future<void> _loadEmployeeData() async {
    if (!mounted) return;
    final cacheService = LocalCacheService();

    // void ordenarTareas(List<dynamic> lista) {
    //   lista.sort((a, b) {
    //     if (a['status'] == 'REWORK_REQUESTED' && b['status'] != 'REWORK_REQUESTED') return -1;
    //     if (b['status'] == 'REWORK_REQUESTED' && a['status'] != 'REWORK_REQUESTED') return 1;
    //     return 0;
    //   });
    // }

void ordenarTareas(List<dynamic> lista) {
      lista.sort((a, b) {
        // 🔥 FIX: Orden lógico estricto
        int weight(String status) {
           if (status == 'PENDING') return 4;
           if (status == 'REWORK_REQUESTED') return 3;
           if (status == 'IN_PROGRESS') return 2;
           return 1;
        }
        int wA = weight(a['status'] ?? '');
        int wB = weight(b['status'] ?? '');
        if (wA != wB) return wB.compareTo(wA);
        
        // Si tienen la misma prioridad, las más recientes van arriba
        DateTime dA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dB.compareTo(dA);
      });
    }
    
    // 🔥 1. CACHÉ INSTANTÁNEO (Elimina los tiempos muertos de carga)
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

    // 2. PETICIÓN A RED
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
        UIHelper.showCustomSnackbar("Error sincronizando actividades", isError: true);
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

                // 📋 LISTADO DE TAREAS CON ANIMACIONES M3
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
                              // 🔥 ANIMACIÓN FLUIDA EN CASCADA
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (i * 100).clamp(0, 500)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: TaskCard(
                                  task: filteredTasks[i],
                                  isEmployer: false, 
                                  onRefresh: _loadEmployeeData,
                                ),
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