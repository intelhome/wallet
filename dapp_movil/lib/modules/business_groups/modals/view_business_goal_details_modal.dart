// En view_business_goal_details_modal.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import 'add_goal_progress_modal.dart';

class ViewBusinessGoalDetailsModal {
  static void show(BuildContext context, String groupId, dynamic goal, VoidCallback onSuccess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        double target = (goal['targetValue'] as num).toDouble();
        double current = (goal['currentValue'] as num).toDouble();
        double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        bool isCompleted = current >= target;

        List<dynamic> history = goal['progressHistory'] ?? [];
        
        // Agrupamos aportes por usuario para ver quién aportó más
        Map<String, double> contributions = {};
        for (var p in history) {
          String wallet = p['addedByWallet'] ?? 'Admin';
          double amt = (p['amountAdded'] as num).toDouble();
          contributions[wallet] = (contributions[wallet] ?? 0) + amt;
        }

        var sortedContributions = contributions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Orden descendente

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(goal['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface))),
                  IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(goal['description'] ?? '', style: TextStyle(color: onSurface.withOpacity(0.6))),
              const SizedBox(height: 16),
              
              // BARRA MAESTRA
              Text("${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ${goal['unit']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: onSurface.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? colorScheme.tertiary : colorScheme.primary)),
              ),
              const SizedBox(height: 24),

              // RANKING DE APORTES (Si hay historial)
              if (sortedContributions.isNotEmpty) ...[
                Text("Mayores Aportantes", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sortedContributions.length,
                    itemBuilder: (c, i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Chip(
                          avatar: SmartAvatar(address: sortedContributions[i].key, size: 24),
                          label: Text("+${sortedContributions[i].value.toStringAsFixed(0)}"),
                          backgroundColor: theme.cardColor,
                          side: BorderSide(color: onSurface.withOpacity(0.1)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // HISTORIAL CRONOLÓGICO
              Text("Historial de Avances", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(
                child: history.isEmpty
                    ? Center(child: Text("Sin registros de avance aún.", style: TextStyle(color: onSurface.withOpacity(0.5))))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, i) {
                          // Invertimos para ver el más reciente primero
                          final p = history[history.length - 1 - i];
                          String dateStr = p['date']?.toString().substring(0, 10) ?? 'Desconocida';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: theme.cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: onSurface.withOpacity(0.05))),
                            child: ListTile(
                              leading: SmartAvatar(address: p['addedByWallet'] ?? '', size: 36),
                              title: Text("+${p['amountAdded']} ${goal['unit']}", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                              subtitle: Text("${p['description'] ?? 'Avance'}\n$dateStr", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                              trailing: p['proofUrl'] != null && p['proofUrl'].toString().isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.link_rounded, color: colorScheme.secondary),
                                    onPressed: () async {
                                      String url = p['proofUrl'].toString();
                                      if (!url.startsWith('http')) url = 'https://$url';
                                      try { await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault); } catch (e) { UIHelper.showCustomSnackbar("Error de enlace", isError: true); }
                                    },
                                  )
                                : null,
                            ),
                          );
                        },
                      ),
              ),

              // BOTÓN APORTAR
              if (!isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddGoalProgressModal.show(context, groupId, goal['id'], goal['unit'], onSuccess);
                    },
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text("Registrar Nuevo Avance", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
        );
      }
    );
  }
}