import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../wallet_and_tx/services/transaction_service.dart'; 

class AiActionDispatcher {
  
  /// Recibe el JSON de DeepSeek y dispara la UI nativa (AHORA ES ASYNC)
  static Future<void> dispatch(BuildContext context, Map<String, dynamic> actionData) async {
    String actionName = actionData['action'] ?? '';
    Map<String, dynamic> params = actionData['params'] ?? {};

    switch (actionName) {
      case 'abrir_modal_transferencia':
        await _ejecutarTransferencia(context, params);
        break;
      
      // Agrega más 'cases' conforme añadas herramientas en Spring Boot
      default:
        UIHelper.showCustomSnackbar("La IA intentó una acción desconocida: $actionName", isError: true);
    }
  }

  static Future<void> _ejecutarTransferencia(BuildContext context, Map<String, dynamic> params) async {
    String aliasDestino = params['alias_destino'] ?? '';
    double monto = (params['monto'] as num?)?.toDouble() ?? 0.0;

    // Cerramos el teclado del chat de IA si está abierto
    FocusScope.of(context).unfocus();

    final txService = Provider.of<TransactionService>(context, listen: false);
    String saldoActual = await txService.getBalance();

    if (context.mounted) {
      SendModal.show(
        context: context,
        balanceTTC: saldoActual, 
        onUpdateBalance: () {}, // Vacío, la UI del chat de IA no necesita refrescar saldos
        mostrarMensaje: (msg, {bool esError = false}) {
          UIHelper.showCustomSnackbar(msg, isError: esError);
        },
        initialAlias: aliasDestino, 
        initialAmount: monto > 0 ? monto.toString() : null,
      );
    }
  }
}