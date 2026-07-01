import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_task_service.dart';
import '../services/business_service.dart';
import '../widgets/task_card.dart';
import '../modals/task_details_modal.dart';

class BusinessCalendarScreen extends StatefulWidget {
  final bool isEmployer; // Para saber si cargamos tareas de Jefe o de Empleado
  const BusinessCalendarScreen({super.key, required this.isEmployer});

  @override
  State<BusinessCalendarScreen> createState() => _BusinessCalendarScreenState();
}

class _BusinessCalendarScreenState extends State<BusinessCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _allTasks = [];
  List<dynamic> _team = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tService = Provider.of<BusinessTaskService>(context, listen: false);
    final bService = Provider.of<BusinessService>(context, listen: false);

    var results = await Future.wait<dynamic>([
      widget.isEmployer ? tService.getEmployerTasks() : tService.getEmployeeTasks(),
      if (widget.isEmployer) bService.getTeamWithDetails() else Future.value([]),
    ]);

    if (mounted) {
      setState(() {
        _allTasks = results[0];
        if (widget.isEmployer) {
          _team = results[1].where((m) => m['status'] == 'ACCEPTED').toList();
        }
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getTasksForDate(DateTime date) {
    return _allTasks.where((task) {
      if (task['deadline'] == null) return false;
      try {
        DateTime taskDate = DateTime.parse(task['deadline'].toString()).toLocal();
        return taskDate.year == date.year && taskDate.month == date.month && taskDate.day == date.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasksToday = _getTasksForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEmployer ? "Calendario de Empresa" : "Mi Agenda Laboral", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 📅 CALENDARIO NATIVO M3
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 años al futuro
                    onDateChanged: (newDate) {
                      setState(() => _selectedDate = newDate);
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Vencen el ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary)
                    ),
                  ),
                ),

                // 📋 LISTA DE TAREAS DEL DÍA
                Expanded(
                  child: tasksToday.isEmpty
                      ? UIHelper.emptyState(
                          context: context, 
                          icon: Icons.event_available_rounded, 
                          title: "Agenda Libre", 
                          message: "No hay tareas ni actividades que venzan en esta fecha."
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: tasksToday.length,
                      itemBuilder: (ctx, i) => TaskCard(
                            task: tasksToday[i],
                            isEmployer: widget.isEmployer, 
                            onRefresh: _loadData,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}