import 'package:dapp_movil/modules/business/screens/task_details_screen.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isEmployer; // 🔥 NUEVO: Saber si quien ve la tarjeta es el jefe
  final VoidCallback onRefresh; // 🔥 NUEVO: Callback de refresco obligatorio
  final VoidCallback? onTap;

  const TaskCard({
    super.key, 
    required this.task, 
    required this.isEmployer,
    required this.onRefresh,
    this.onTap,
  });

  Color _getUrgencyColor() {
    switch (task['urgency']) {
      case 'LOW': return Colors.green;
      case 'MEDIUM': return Colors.orange;
      case 'HIGH': return Colors.redAccent;
      case 'URGENT': return Colors.deepPurpleAccent;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'REWORK_REQUESTED') return Colors.orange;
    if (status == 'COMPLETED') return Colors.blue;
    if (status == 'APPROVED') return Colors.teal;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getUrgencyColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.5), width: 1.5)),
      child: ListTile(
        // 🔥 MAGIA: Si no le pasas onTap, por defecto navega a la nueva pantalla
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
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(Icons.assignment_rounded, color: color)),
        title: Text(task['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(task['urgency'] ?? '', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
               Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
  decoration: BoxDecoration(
    color: _getStatusColor(task['status'] ?? '').withOpacity(0.1), 
    borderRadius: BorderRadius.circular(8)
  ), 
  child: Text(
    task['status'] == 'REWORK_REQUESTED' ? 'CORRECCIÓN REQUERIDA' : (task['status'] ?? ''), 
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(task['status'] ?? ''))
  )
),
              ],
            )
          ],
        ),
      ),
    );
  }
}