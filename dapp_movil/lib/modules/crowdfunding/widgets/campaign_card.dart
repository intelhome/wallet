import 'package:flutter/material.dart';
import '../modals/campaign_details_modal.dart';

class CampaignCard extends StatelessWidget {
  final dynamic campaign;
  final VoidCallback onRefresh;

  const CampaignCard({super.key, required this.campaign, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    double target = double.tryParse(campaign['targetAmount']?.toString() ?? "0") ?? 0;
    double raised = double.tryParse(campaign['raisedAmount']?.toString() ?? "0") ?? 0;
    double progress = target > 0 ? (raised / target) : 0;
    String status = campaign['status'] ?? "ACTIVE";

    // Data optimizada que viene del backend DTO
    int backers = campaign['totalDonors'] ?? 0; 
    
    int daysLeft = 0;
    if(campaign['deadline'] != null) {
        DateTime dl = DateTime.tryParse(campaign['deadline'].toString()) ?? DateTime.now();
        daysLeft = dl.difference(DateTime.now()).inDays;
        if(daysLeft < 0) daysLeft = 0;
    }

    return GestureDetector(
      onTap: () {
        CampaignDetailsModal.show(context: context, campaign: campaign, onRefresh: onRefresh);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor, // 🔥 Adaptable AppTheme
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text((campaign['category'] ?? "LOCAL").toUpperCase(), style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, color: onSurface.withOpacity(0.5), size: 14),
                        const SizedBox(width: 4),
                        Flexible(child: Text("${campaign['region'] ?? 'Global'}", overflow: TextOverflow.ellipsis, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(campaign['title'] ?? "Sin título", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded, color: onSurface.withOpacity(0.5), size: 16),
                      const SizedBox(width: 6),
                      Text("$backers donantes", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: onSurface.withOpacity(0.5), size: 16),
                      const SizedBox(width: 6),
                      Text("$daysLeft días rest.", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$raised TTC recaudados", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("Meta: $target TTC", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: onSurface.withOpacity(0.1),
                  color: status == "FAILED_REFUNDED" || status == "CANCELLED" ? colorScheme.error : (progress >= 1.0 ? Colors.green : colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}