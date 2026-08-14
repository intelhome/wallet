import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';

class GroupProposalsTab extends StatelessWidget {
  final Future<List<dynamic>>? paymentsFuture;
  final VoidCallback onRecargar;

  const GroupProposalsTab({super.key, required this.paymentsFuture, required this.onRecargar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);

    return FutureBuilder<List<dynamic>>(
      future: paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        List<dynamic> propuestas = (snapshot.data ?? []).where((r) => r['status'] == "PENDING_APPROVAL").toList();
        if (propuestas.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.how_to_vote_rounded, title: "Sin Propuestas", message: "No hay votaciones pendientes en este momento en la DAO.");
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: propuestas.length,
          itemBuilder: (ctx, i) {
            var req = propuestas[i];
            List<dynamic> approvals = req['approvals'] ?? [];
            bool yaVote = approvals.contains(authCore.publicAddress.toLowerCase());
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: theme.cardColor,
              child: ListTile(
                leading: CircleAvatar(backgroundColor: colorScheme.secondary.withOpacity(0.1), child: Icon(Icons.how_to_vote_rounded, color: colorScheme.secondary)),
                title: Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(req['requestType'] == 'CONFIG_CHANGE' ? "Ajuste de DAO" : "DeFi o Multisig", style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                trailing: !yaVote 
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                      label: const Text("Aprobar"),
                      onPressed: () async {
                        bool auth = await authCore.authenticateUser();
                        if (!auth) return;
                        if (!context.mounted) return;
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        String res = await groupService.approveMultisigPayment(req['id']);
                        if (context.mounted) Navigator.pop(context);
                        if (res == "SUCCESS") { UIHelper.showCustomSnackbar("Voto registrado exitosamente", isError: false); onRecargar(); } else { UIHelper.showCustomSnackbar(res, isError: true); }
                      },
                    )
                  : Chip(label: const Text("Aprobado", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: colorScheme.secondary.withOpacity(0.1), labelStyle: TextStyle(color: colorScheme.secondary), side: BorderSide.none),
              ),
            );
          },
        );
      },
    );
  }
}