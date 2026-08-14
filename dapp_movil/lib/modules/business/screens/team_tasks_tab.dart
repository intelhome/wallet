import 'package:flutter/material.dart';
import '../../../core/helpers/ui_helper.dart';
import '../modals/create_task_modal.dart';
import '../widgets/task_card.dart';

class TeamTasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final List<dynamic> activeTeam;
  final List<dynamic> departments;
  final VoidCallback onRefresh;

  const TeamTasksTab({
    super.key,
    required this.tasks,
    required this.activeTeam,
    required this.departments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: tasks.isEmpty
          ? UIHelper.emptyState(context: context, icon: Icons.assignment_turned_in_rounded, title: "Sin Tareas", message: "No has asignado ninguna tarea.")
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (ctx, i) => TaskCard(
                task: tasks[i], 
                isEmployer: true, 
                onRefresh: onRefresh,
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateTaskModal.show(context, activeTeam, departments, onRefresh),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text("Nueva Tarea", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
    );
  }
}