import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/contact_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/share_helper.dart';

class TransactionDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic tx,
   // required String myAddress,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final myAddress = authCore.publicAddress;
    // 🔥 Guardamos el contexto raíz de toda la app
    BuildContext rootContext = context;

    final String type = tx['txType'] ?? 'Unknown';
    final double amount = tx['amount'] != null
        ? (tx['amount'] as num).toDouble()
        : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final isFailed =
        status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';
    final bool esFantasma = tx['recovered'] == true || tx['isGhost'] == true;
    final String txHash = tx['txHash'] ?? 'N/A';
    final String sender = tx['senderAddress'] ?? 'N/A';
    final String receiver = tx['receiverAddress'] ?? 'N/A';
    final bool iAmReceiver = receiver.toLowerCase() == myAddress.toLowerCase();

    String title = 'Detalle de transacción';
    IconData mainIcon = Icons.swap_horiz;
    Color iconColor = Colors.white;
    String prefix = "";

    if (type == 'SEND') {
      if (iAmReceiver) {
        title = "Transferencia Recibida";
        mainIcon = Icons.call_received;
        iconColor = Colors.greenAccent;
        prefix = "+";
      } else {
        title = "Envío Realizado";
        mainIcon = Icons.call_made;
        iconColor = Colors.blueAccent;
        prefix = "-";
      }
    } else if (type == 'BUY') {
      title = "Compra de Tokens";
      mainIcon = Icons.account_balance_wallet;
      iconColor = Colors.greenAccent;
      prefix = "+";
    } else if (type == 'STAKE') {
      title = "Stake bloqueado";
      mainIcon = Icons.lock_outline;
      iconColor = Colors.orangeAccent;
      prefix = "-";
    } else if (type == 'UNSTAKE') {
      title = "Recompensa reclamada";
      mainIcon = Icons.lock_open;
      iconColor = Colors.purpleAccent;
      prefix = "+";
    } else if (type == 'WITHDRAW') {
      title = "Recompensa Reclamada con Éxito";
      mainIcon = Icons.lock_open;
      iconColor = Colors.greenAccent;
      prefix = "+";
    } else if (type == 'RECOVERY') {
      String tipoRecuperado = "";
      if (iAmReceiver) {
        tipoRecuperado = (sender.contains("ecosystem") || sender.isEmpty)
            ? "BUY / UNSTAKE"
            : "RECEIVE";
      } else {
        tipoRecuperado = "SEND / STAKE";
      }
      String tipoReal = tx['originalType'] ?? tipoRecuperado;
      title = "Transacción $tipoReal (Recuperada)";
      mainIcon = Icons.healing;
      iconColor = Colors.orangeAccent;
      prefix = "";
    }

    if (isFailed) {
      iconColor = Colors.redAccent;
      prefix = "x";
    }

    String statusMessage = "";
    if (isFailed) {
      // 1. Intentamos leer la razón del error desde el backend (si existe un campo 'reason' o 'errorMessage')
      String backendReason = tx['reason'] ?? tx['errorMessage'] ?? "";

      // 2. Si el backend no envió razón, inferimos por el tipo de transacción
      if (backendReason.isNotEmpty) {
        statusMessage = "Motivo: $backendReason";
      } else if (type == 'SEND' || type == 'SEND_FIAT') {
        statusMessage =
            "El envío fue rechazado. Posible saldo insuficiente o error en red.";
      } else if (type == 'BUY' || type == 'BUY_FIAT') {
        statusMessage = "La compra no se procesó. Verifica tu método de pago.";
      } else if (type == 'STAKE') {
        statusMessage = "Error al bloquear fondos en el contrato inteligente.";
      } else {
        statusMessage = "Transacción revertida por la Blockchain.";
      }
    } else {
      // Si fue exitosa
      if (type == 'SEND' || type == 'SEND_FIAT') {
        statusMessage = iAmReceiver
            ? "Los fondos han sido acreditados en tu billetera."
            : "El destinatario ha recibido los fondos correctamente.";
      } else if (type == 'BUY' || type == 'BUY_FIAT') {
        statusMessage = "¡Compra exitosa! Tus TTC ya están disponibles.";
      } else if (type == 'STAKE') {
        statusMessage = "Tus fondos están bloqueados generando recompensas.";
      } else if (type == 'UNSTAKE' || type == 'WITHDRAW') {
        statusMessage = "Tus recompensas han sido liberadas exitosamente.";
      } else {
        statusMessage = "La transacción se registró en la red.";
      }
    }

    String dateLabel = "Fecha desconocida";
    if (tx['timestamp'] != null) {
      try {
        DateTime parseDate = DateTime.parse(tx['timestamp'].toString());
        dateLabel =
            "${parseDate.day.toString().padLeft(2, '0')}/${parseDate.month.toString().padLeft(2, '0')}/${parseDate.year} a las ${parseDate.hour.toString().padLeft(2, '0')}:${parseDate.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        dateLabel = tx['timestamp'].toString();
      }
    }

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        // 🔥 Este es el contexto propio del modal inferior
        final theme = Theme.of(bottomSheetContext);
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;
        final cardColor = theme.cardColor;

        Color successColor = Colors.green.shade600;
        Color failColor = colorScheme.error;
        Color pendingColor = Colors.orange.shade600;

        Color currentColor = isFailed
            ? failColor
            : (type == 'STAKE' ? pendingColor : successColor);
        if (iconColor == Colors.blueAccent) iconColor = colorScheme.primary;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ), // 🔥 Bordes más redondeados M3
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(
                    bottomSheetContext,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 32,
                backgroundColor: currentColor.withOpacity(0.1),
                child: Icon(mainIcon, color: currentColor, size: 32),
              ),
              const SizedBox(height: 16),

              (esFantasma && amount == 0.0)
                  ? Text(
                      "---",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    )
                  : Text(
                      "$prefix ${amount.toStringAsFixed(4)} TTC",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isFailed
                            ? Theme.of(bottomSheetContext).colorScheme.error
                            : onSurfaceColor,
                        decoration: isFailed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: onSurfaceColor.withOpacity(0.7),
                    ),
                  ),
                  if (esFantasma) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: "Recuperada por el Indexer",
                      child: Icon(Icons.healing, color: pendingColor, size: 18),
                    ),
                  ],
                ],
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isFailed
                          ? "Fallida / Rechazada"
                          : "Completada Exitosamente",
                      style: TextStyle(
                        color: currentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onSurfaceColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: onSurfaceColor.withOpacity(0.1)),
              const SizedBox(height: 12),

              _DetailRow(
                label: "Fecha",
                value: dateLabel,
                copyable: false,
                rootContext: rootContext,
                bottomSheetContext: bottomSheetContext,
              ),
              _DetailRow(
                label: "De",
                value: sender,
                copyable:
                    sender != "ECOSYSTEM_CONTRACT" &&
                    sender != "SYSTEM_REWARD" &&
                    sender != "PAYPAL_ONRAMP",
                rootContext: rootContext,
                bottomSheetContext: bottomSheetContext,
                myAddress: myAddress,
              ),
              _DetailRow(
                label: "Para",
                value: receiver,
                copyable: receiver != "ECOSYSTEM_CONTRACT",
                rootContext: rootContext,
                bottomSheetContext: bottomSheetContext,
                myAddress: myAddress,
              ),
              _DetailRow(
                label: "Hash",
                value: txHash,
                copyable: true,
                rootContext: rootContext,
                bottomSheetContext: bottomSheetContext,
              ),
              _DetailRow(
                label: "Red",
                value: "Ethereum L2 (Local)",
                copyable: false,
                rootContext: rootContext,
                bottomSheetContext: bottomSheetContext,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary, // 🔥 Botón principal M3
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "Compartir",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      //onPressed: () => ShareHelper.compartirTransaccionTexto(tx, myAddress),
                      onPressed: () {
                        // Opcional: Si quieres que el modal se cierre automáticamente al darle a compartir
                        Navigator.pop(bottomSheetContext);

                        ShareHelper.compartirTransaccionPDF(
                          rootContext,
                          tx,
                          myAddress,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      // 🔥 Botón secundario M3
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onSurfaceColor,
                        side: BorderSide(
                          color: onSurfaceColor.withOpacity(0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: const Text(
                        "Cerrar",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  //   static void mostrarDialogoGuardarContacto(BuildContext rootContext, BuildContext bottomSheetContext, String addressToSave, String myAddress) {
  //   // 1. Cerramos el modal inferior de manera segura usando su propio contexto
  //   Navigator.pop(bottomSheetContext);

  //   // 2. Abrimos el dialog usando el contexto raíz que sigue vivo
  //   showDialog(
  //     context: rootContext,
  //     builder: (dialogCtx) => FutureBuilder(
  //       future: http.get(Uri.parse(ApiConfig.getAliasWallet.replaceAll("{address}", addressToSave.toLowerCase()))),
  //       builder: (ctx, AsyncSnapshot<http.Response> snapshot) {
          
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return AlertDialog(
  //             backgroundColor: Theme.of(rootContext).cardColor,
  //             content: const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.blueAccent))),
  //           );
  //         }

  //         String aliasEncontrado = "Desconocido";
  //         if (snapshot.hasData && snapshot.data!.statusCode == 200) {
  //           aliasEncontrado = jsonDecode(snapshot.data!.body)['alias'] ?? "Desconocido";
  //         }

  //         bool guardando = false;

  //         return StatefulBuilder(
  //           builder: (context, setState) => AlertDialog(
  //             backgroundColor: Theme.of(rootContext).cardColor,
  //             title: Text("Guardar Contacto", style: TextStyle(color: Theme.of(rootContext).colorScheme.onSurface, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 CircleAvatar(
  //                   radius: 30,
  //                   backgroundColor: Colors.blueAccent.withOpacity(0.2),
  //                   child: Text(aliasEncontrado != "Desconocido" && aliasEncontrado.isNotEmpty ? aliasEncontrado[0].toUpperCase() : "?", style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
  //                 ),
  //                 const SizedBox(height: 15),
  //                 Text("@$aliasEncontrado", style: TextStyle(color: Theme.of(rootContext).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 10),
  //                Text(addressToSave.length > 18 ? "${addressToSave.substring(0, 10)}...${addressToSave.substring(addressToSave.length - 8)}" : addressToSave, style: TextStyle(color: Theme.of(rootContext).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontFamily: 'monospace')),
  //                // Text("${addressToSave.substring(0, 10)}...${addressToSave.substring(addressToSave.length - 8)}", style: TextStyle(color: Theme.of(rootContext).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontFamily: 'monospace')),
  //               ],
  //             ),
  //             actionsAlignment: MainAxisAlignment.center,
  //             actions: [
  //               TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
  //                 onPressed: guardando ? null : () async {
  //                   setState(() => guardando = true);
  //                   try {
  //                     final res = await http.post(
  //                       Uri.parse(ApiConfig.addContact),
  //                       headers: {"Content-Type": "application/json"},
  //                       body: jsonEncode({
  //                         "ownerAddress": myAddress.toLowerCase(),
  //                         "contactAddress": addressToSave.toLowerCase(),
  //                         "alias": aliasEncontrado,
  //                       }),
  //                     );
  //                     Navigator.pop(dialogCtx);
  //                     if (res.statusCode == 200) {
  //                       UIHelper.showCustomSnackbar("¡Contacto guardado exitosamente!", isError: false);
  //                     } else {
  //                       UIHelper.showCustomSnackbar("Este contacto ya existe", isError: true);
  //                     }
  //                   } catch (e) {
  //                     UIHelper.showCustomSnackbar("Error al guardar", isError: true);
  //                   }
  //                 },
  //                 child: guardando ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Confirmar"),
  //               )
  //             ]
  //           )
  //         );
  //       }
  //     )
  //   );
  // }

  static void mostrarDialogoGuardarContacto(BuildContext contextModal, BuildContext rootContext, String contactAddress, String myAddress) {
    String alias = "";
    bool isSaving = false;

    showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // 🔥 Usamos dialogContext como contexto seguro
        return StatefulBuilder(
          builder: (BuildContext stfContext, StateSetter setStateModal) {
            
            // 🔥 FIX 1: Usamos 'dialogContext' en lugar de 'stfContext' para que no choque si se desmonta
            final theme = Theme.of(dialogContext); 
            final colorScheme = theme.colorScheme;
            final onSurfaceColor = colorScheme.onSurface;

            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text("Nuevo Contacto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Has transferido a una nueva billetera. ¿Deseas guardarla en tus contactos rápidos?", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (val) => alias = val,
                    decoration: InputDecoration(
                      labelText: "¿Cómo se llama?",
                      prefixIcon: const Icon(Icons.badge_rounded),
                      filled: true,
                      fillColor: onSurfaceColor.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("No guardar", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: (isSaving) ? null : () async {
                    if (alias.trim().isEmpty) {
                      // 🔥 FIX 2: Usar dialogContext para ScaffoldMessenger temporal
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Ingresa un nombre para el contacto"), backgroundColor: Colors.redAccent)
                      );
                      return;
                    }

                    setStateModal(() => isSaving = true);

              try {
                      // 🔥 FIX: Usamos ContactService y le pasamos la categoría "GENERAL" o "RECENTS"
                      final contactService = Provider.of<ContactService>(dialogContext, listen: false);
                      String result = await contactService.addContact(contactAddress, alias.trim(), "GENERAL");

                      if (result == "Exito") {
                        Navigator.pop(dialogContext);
                        
                        await Future.delayed(const Duration(milliseconds: 300));
                        UIHelper.showCustomSnackbar("¡Contacto '$alias' guardado!");
                        
                      } else {
                        setStateModal(() => isSaving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(result), backgroundColor: Colors.redAccent)
                        );
                      }
                    } catch (e) {
                      setStateModal(() => isSaving = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Error al guardar el contacto"), backgroundColor: Colors.redAccent)
                      );
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Guardar Contacto"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final BuildContext rootContext;
  final BuildContext bottomSheetContext;
  final String? myAddress;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.copyable,
    required this.rootContext,
    required this.bottomSheetContext,
    this.myAddress,
  });

  @override
  Widget build(BuildContext ctx) {
    String dysplayValue = value;
    if (value.length > 25 && value.startsWith('0x')) {
      dysplayValue =
          "${value.substring(0, 10)}... ${value.substring(value.length - 8)}";
    }

    final onSurfaceColor = Theme.of(ctx).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: onSurfaceColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (value.startsWith('0x') && value.length == 42) ...[
                  SmartAvatar(address: value, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    dysplayValue,
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (copyable) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: value));
                      UIHelper.showCustomSnackbar("¡Copiado al portapapeles!", isError: false);
                    },
                    child: const Icon(
                      Icons.copy,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ),

                  // 🔥 EL BOTÓN MÁGICO 🔥
                  if (value.startsWith('0x') &&
                      myAddress != null &&
                      value.toLowerCase() != myAddress!.toLowerCase()) ...[
                    const SizedBox(width: 15),
                    InkWell(
                      onTap: () {
                        TransactionDetailsModal.mostrarDialogoGuardarContacto(rootContext, bottomSheetContext, value, myAddress!);
                      },
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 22,
                      ), // 🔥 M3
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
