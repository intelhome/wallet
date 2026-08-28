import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../services/business_group_service.dart';

class BusinessGroupProductivityTab extends StatefulWidget {
  final String groupId;

  const BusinessGroupProductivityTab({super.key, required this.groupId});

  @override
  State<BusinessGroupProductivityTab> createState() => _BusinessGroupProductivityTabState();
}

class _BusinessGroupProductivityTabState extends State<BusinessGroupProductivityTab> {
  List<dynamic> _metrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductivity();
  }

  Future<void> _loadProductivity() async {
    final service = Provider.of<BusinessGroupService>(context, listen: false);
    final data = await service.getGroupProductivity(widget.groupId);
    if (mounted) {
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_metrics.isEmpty) {
      return UIHelper.emptyState(
        context: context, 
        icon: Icons.insights_rounded, 
        title: "Sin Datos", 
        message: "No hay tareas asignadas para evaluar la productividad."
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _metrics.length,
      itemBuilder: (ctx, i) {
        final m = _metrics[i];
        double score = (m['productivityScore'] as num).toDouble();
        int completed = m['completedTasks'] ?? 0;
        int pending = m['pendingTasks'] ?? 0;
        int totalHours = m['totalEstimatedHours'] ?? 0;

        Color scoreColor = score >= 80 ? Colors.green : (score >= 40 ? Colors.orange : colorScheme.error);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: theme.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Termómetro Circular
                SizedBox(
                  width: 60, height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100.0,
                        backgroundColor: onSurface.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeWidth: 6,
                      ),
                      Center(
                        child: Text(
                          "${score.toStringAsFixed(0)}%",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: scoreColor),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Detalles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SmartAvatar(address: m['memberWallet'], size: 20),
                          const SizedBox(width: 8),
                          Text("@${m['memberAlias']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text("$completed completadas", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.7))),
                          const SizedBox(width: 12),
                          Icon(Icons.pending_actions_rounded, size: 14, color: Colors.orange.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text("$pending pendientes", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.7))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Total estimado: $totalHours horas", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}