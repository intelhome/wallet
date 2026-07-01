import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/share_helper.dart';

class GroupPaymentDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic req,
    required String groupName,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    String status = req['status'] ?? 'OPEN';
    bool isCompleted = status == 'COMPLETED';
    bool isPendingApproval = status == 'PENDING_APPROVAL';
    
    List<dynamic> debts = req['debts'] ?? [];
    List<dynamic> approvals = req['approvals'] ?? [];
    bool isVaultPayment = debts.isEmpty;

    double totalAmount = double.tryParse(req['totalAmount'].toString()) ?? 0.0;
    String destination = req['destinationAddress'] ?? 'N/A';
    String description = req['description'] ?? 'Cobro Grupal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 20, left: 20, right: 20, top: 16),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(description, style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900))),
                IconButton(icon: Icon(Icons.close, color: onSurface.withOpacity(0.5)), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text(isVaultPayment ? "Monto extraído de Bóveda" : "Monto Total a Recolectar", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("$totalAmount TTC", style: TextStyle(color: colorScheme.primary, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: (isCompleted ? Colors.green : (isPendingApproval ? Colors.orange : Colors.blueAccent)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(isCompleted ? "Completado" : (isPendingApproval ? "Esperando Firmas" : "En Recolección"), style: TextStyle(color: isCompleted ? Colors.green : (isPendingApproval ? Colors.orange : Colors.blueAccent), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            Text("Destino de los fondos:", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 16, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(destination, style: TextStyle(color: onSurface, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 30),

            if (isVaultPayment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Pagado con los TTC de la bóveda", 
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(isVaultPayment ? "Transacción aprobada por:" : "Aportes de Miembros:", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            Expanded(
              child: isVaultPayment
                // LISTA DE FIRMAS (BÓVEDA)
                ? ListView.builder(
                    itemCount: approvals.length,
                    itemBuilder: (context, index) {
                      String address = approvals[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SmartAvatar(address: address, size: 36),
                        title: Text(address.substring(0,10) + "...", style: const TextStyle(fontFamily: 'monospace')),
                        trailing: const Icon(Icons.verified_user_rounded, color: Colors.green),
                      );
                    },
                  )
                // LISTA DE DEUDAS (SPLITWISE)
                : ListView.builder(
                    itemCount: debts.length,
                    itemBuilder: (context, index) {
                      var d = debts[index];
                      bool pagado = d['status'] == 'PAID' || d['status'] == 'SETTLED_BY_ADMIN';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SmartAvatar(address: d['walletAddress'], size: 36),
                        title: Text("@${d['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${d['amountOwed']} TTC"),
                        trailing: pagado 
                          ? const Chip(label: Text("Pagado", style: TextStyle(color: Colors.green, fontSize: 10)), backgroundColor: Colors.transparent, side: BorderSide(color: Colors.green))
                          : const Chip(label: Text("Pendiente", style: TextStyle(color: Colors.orange, fontSize: 10)), backgroundColor: Colors.transparent, side: BorderSide(color: Colors.orange)),
                      );
                    },
                  ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text("Exportar Reporte PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ShareHelper.generarYCompartirPDFCobroGrupal(context, req, groupName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}