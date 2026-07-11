import 'package:dapp_movil/modules/business/screens/task_details_screen.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isEmployer;
  final VoidCallback onRefresh; 
  final VoidCallback? onTap;

  const TaskCard({
    super.key, 
    required this.task, 
    required this.isEmployer,
    required this.onRefresh,
    this.onTap,
  });

  Color _getUrgencyColor() {
    switch (task['urgency']?.toString().toUpperCase()) {
      case 'LOW': return Colors.green;
      case 'MEDIUM': return Colors.orange;
      case 'HIGH': return Colors.redAccent;
      case 'URGENT': return Colors.deepPurpleAccent;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'REWORK_REQUESTED') return Colors.deepOrange;
    if (status == 'IN_PROGRESS') return Colors.blueAccent;
    if (status == 'COMPLETED') return Colors.purple;
    if (status == 'APPROVED') return Colors.teal;
    return Colors.grey;
  }

  IconData _getTaskTypeIcon() {
    switch (task['taskType']?.toString().toUpperCase()) {
      case 'GPS': return Icons.location_on_rounded;
      case 'MEET': return Icons.videocam_rounded;
      case 'FORM': return Icons.checklist_rtl_rounded;
      case 'OPINION': return Icons.poll_rounded;
      default: return Icons.assignment_rounded;
    }
  }

  String _getTaskTypeName() {
    switch (task['taskType']?.toString().toUpperCase()) {
      case 'GPS': return 'En Sitio (GPS)';
      case 'MEET': return 'Reunión Virtual';
      case 'FORM': return 'Formulario';
      case 'OPINION': return 'Encuesta';
      default: return 'Estándar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getUrgencyColor();
    final statusColor = _getStatusColor(task['status'] ?? 'PENDING');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5)
      ),
      color: theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(
                task: task,
                isEmployer: isEmployer,
                onRefresh: onRefresh,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Icon(_getTaskTypeIcon(), color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] ?? 'Sin Título', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task['description'] ?? '', 
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ETIQUETAS INFERIORES HORIZONTALES
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 1. Urgencia
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.flag_rounded, color: color, size: 14),
                          const SizedBox(width: 4),
                          Text(task['urgency'] ?? 'MEDIUM', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 2. Tipo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_getTaskTypeName(), style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    // 3. Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
                      child: Text(
                        task['status'] == 'REWORK_REQUESTED' ? '⚠️ POR CORREGIR' : (task['status'] ?? 'PENDING'), 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)
                      )
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}