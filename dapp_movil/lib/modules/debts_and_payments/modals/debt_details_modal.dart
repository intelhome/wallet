import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/share_helper.dart';

class DebtDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic debt,
  }) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final myAddress = authCore.publicAddress;

    double total = double.tryParse(debt['totalAmount'].toString()) ?? 0;
    double pagado = double.tryParse(debt['paidAmount'].toString()) ?? 0;
    double restante = total - pagado;
    if (restante < 0) restante = 0;
    
    String status = debt['status'] ?? 'UNKNOWN';
    String reason = debt['reason'] ?? 'Detalles de la operación';
    String debtor = debt['debtorAddress'] ?? '';
    String creditor = debt['creditorAddress'] ?? '';
    
    // Extracción de alias si existen en el objeto
    String debtorAlias = debt['debtorAlias'] ?? 'Usuario';
    String creditorAlias = debt['creditorAlias'] ?? 'Usuario';
    
    bool soyDeudor = debtor.toLowerCase() == myAddress.toLowerCase();
    bool isCompleted = status == "COMPLETED";
    bool isRejected = status == "REJECTED" || status == "FAILED";

    // Configuraciones de UI según estado
    Color statusColor = isCompleted ? const Color(0xFF10B981) : (isRejected ? Colors.redAccent : Colors.orangeAccent);
    IconData statusIcon = isCompleted ? Icons.check_circle_outline_rounded : (isRejected ? Icons.cancel_outlined : Icons.schedule_rounded);
    String statusText = isCompleted ? "COMPLETADA" : (isRejected ? "RECHAZADA" : (status == "PENDING_APPROVAL" ? "POR ACEPTAR" : "PENDIENTE"));
    IconData pagadoIcon = isCompleted ? Icons.check_circle_outline_rounded : Icons.schedule_rounded;

    String fecha = "Desconocida";
    if (debt['createdAt'] != null) {
      try {
        DateTime dt = DateTime.parse(debt['createdAt'].toString()).toLocal();
        fecha = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      } catch(e){}
    }

    int progressPercent = total > 0 ? ((pagado / total) * 100).toInt() : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;
        final cardColor = theme.cardColor;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 16),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(soyDeudor ? "Detalles de Deuda" : "Detalles de Cobro", style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.8)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ICONO CENTRAL
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(statusIcon, color: statusColor, size: 48),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(isCompleted ? "ESTADO: $statusText" : statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text(reason, style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                      const SizedBox(height: 32),

                      // TARJETA DE PROGRESO / MONTOS
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total a pagar", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text("$total TTC", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("Restante", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text("$restante TTC", style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? (pagado / total) : 0,
                                backgroundColor: onSurface.withOpacity(0.1),
                                color: statusColor,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(pagadoIcon, color: statusColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text("Pagado: $pagado TTC", style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text("$progressPercent%", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // TARJETA DE PARTICIPANTES
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("PARTICIPANTES", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 24),
                            
                            Text("DEUDOR", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            _buildParticipantBox(ctx, debtor, debtorAlias, onSurface, theme.scaffoldBackgroundColor),
                            
                            const SizedBox(height: 24),
                            
                            Text("ACREEDOR", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(height: 8),
                            _buildParticipantBox(ctx, creditor, creditorAlias, onSurface, theme.scaffoldBackgroundColor),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Divider(color: onSurface.withOpacity(0.1), height: 1),
                            ),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Fecha Creación", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                                Text(fecha, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // BOTÓN EXPORTAR STICKY
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBAC3FF),
                    foregroundColor: const Color(0xFF00218d),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: const Text("Exportar PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ShareHelper.generarYCompartirPDFDeuda(context, debt, myAddress);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 static Widget _buildParticipantBox(BuildContext context, String wallet, String fallbackAlias, Color onSurface, Color bgColor) {
  final userService = Provider.of<UserService>(context, listen: false);
  String shortWallet = wallet.length > 10 ? "${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}" : wallet;

  return FutureBuilder<Map<String, dynamic>?>(
    future: userService.getUserByWallet(wallet),
    builder: (context, snapshot) {
      String realAlias = fallbackAlias;
      if (snapshot.hasData && snapshot.data != null) {
        realAlias = snapshot.data!['alias'] ?? fallbackAlias;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: onSurface.withOpacity(0.05))),
        child: Row(
          children: [
            SmartAvatar(address: wallet, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("@$realAlias", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(shortWallet.toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: wallet));
              UIHelper.showCustomSnackbar("Billetera copiada");
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.copy_rounded, size: 18, color: onSurface.withOpacity(0.6)),
            ),
          )
       ],
        ),
      );
    }
  );
 }
}

// class DebtDetailsModal {
//   static void show({
//     required BuildContext context,
//     required dynamic debt,
//     //required String myAddress,
//   }) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final myAddress = authCore.publicAddress;

//     double total = double.tryParse(debt['totalAmount'].toString()) ?? 0;
//     double pagado = double.tryParse(debt['paidAmount'].toString()) ?? 0;
//     double restante = total - pagado;
    
//     String status = debt['status'] ?? 'UNKNOWN';
//     String reason = debt['reason'] ?? 'Sin motivo';
//     String debtor = debt['debtorAddress'] ?? '';
//     String creditor = debt['creditorAddress'] ?? '';
    
//     bool soyDeudor = debtor.toLowerCase() == myAddress.toLowerCase();
//     bool isCompleted = status == "COMPLETED";
//     bool isRejected = status == "REJECTED";

//     Color statusColor = isCompleted ? Colors.green : (isRejected ? colorScheme.error : Colors.orange);
//     IconData statusIcon = isCompleted ? Icons.check_circle_rounded : (isRejected ? Icons.cancel_rounded : Icons.pending_actions_rounded);
//     String statusText = isCompleted ? "Completada" : (isRejected ? "Rechazada" : (status == "PENDING_APPROVAL" ? "Por Aceptar" : "Activa / Pendiente"));

//     String fecha = "Desconocida";
//     if (debt['createdAt'] != null) {
//       try {
//         DateTime dt = DateTime.parse(debt['createdAt'].toString()).toLocal();
//         fecha = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
//       } catch(e){}
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => Container(
//         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 16),
//         decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
//             const SizedBox(height: 24),
            
//             CircleAvatar(radius: 32, backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor, size: 32)),
//             const SizedBox(height: 16),
            
//             Text(reason, style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
//             const SizedBox(height: 8),
            
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//               child: Text("Estado: $statusText", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
//             ),
//             const SizedBox(height: 24),

//             // Tarjeta de progreso
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("Total:", style: TextStyle(color: onSurface.withOpacity(0.6))),
//                       Text("$total TTC", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("Pagado:", style: TextStyle(color: onSurface.withOpacity(0.6))),
//                       Text("$pagado TTC", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
//                     ],
//                   ),
//                   const Divider(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text("Restante:", style: TextStyle(color: onSurface.withOpacity(0.6))),
//                       Text("$restante TTC", style: TextStyle(color: isCompleted ? Colors.green : colorScheme.error, fontWeight: FontWeight.bold, fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   LinearProgressIndicator(
//                     value: total > 0 ? (pagado / total) : 0,
//                     backgroundColor: onSurface.withOpacity(0.1),
//                     color: Colors.green,
//                     minHeight: 6,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),

//             _buildInfoRow("Deudor", debtor, onSurface, true),
//             _buildInfoRow("Acreedor", creditor, onSurface, true),
//             _buildInfoRow("Fecha Creación", fecha, onSurface, false),
            
//             const SizedBox(height: 30),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
//                     icon: const Icon(Icons.picture_as_pdf_rounded),
//                     label: const Text("Exportar PDF", style: TextStyle(fontWeight: FontWeight.bold)),
//                     onPressed: () {
//                       Navigator.pop(ctx);
//                       ShareHelper.generarYCompartirPDFDeuda(context, debt, myAddress);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: OutlinedButton(
//                     style: OutlinedButton.styleFrom(foregroundColor: onSurface, side: BorderSide(color: onSurface.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
//                     onPressed: () => Navigator.pop(ctx),
//                     child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   static Widget _buildInfoRow(String label, String value, Color onSurface, bool isWallet) {
//     String displayValue = value;
//     if (isWallet && value.length > 20) {
//       displayValue = "${value.substring(0, 8)}...${value.substring(value.length - 6)}";
//     }
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: onSurface.withOpacity(0.6))),
//           Row(
//             children: [
//               if (isWallet) ...[SmartAvatar(address: value, size: 18), const SizedBox(width: 6)],
//               Text(displayValue, style: TextStyle(color: onSurface, fontFamily: isWallet ? 'monospace' : null, fontWeight: FontWeight.bold)),
//               if (isWallet) ...[
//                 const SizedBox(width: 6),
//                 InkWell(
//                   onTap: () {
//                     HapticFeedback.lightImpact();
//                     Clipboard.setData(ClipboardData(text: value));
//                     UIHelper.showCustomSnackbar("Copiado");
//                   },
//                   child: const Icon(Icons.copy_rounded, size: 16, color: Colors.blueAccent),
//                 )
//               ]
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }