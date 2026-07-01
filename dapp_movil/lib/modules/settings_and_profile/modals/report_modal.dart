import 'dart:convert';

import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/helpers/share_helper.dart';

class ReportModal {
  static void show({
    required BuildContext context,
    required String aliasDestino,
    required String walletAddress,
    //required BlockchainService service, 
  }) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final txService = Provider.of<TransactionService>(context, listen: false);
    showModalBottomSheet(
      
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

        // 🔥 FUNCIÓN QUE PROCESA Y GENERA EL NUEVO REPORTE 🔥
        Future<void> procesarReporte(bool soloUltimos30Dias) async {
          Navigator.pop(ctx); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recopilando transacciones...", style: TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent)
          );

          try {
            // 1. Obtenemos tu propio Alias haciendo una llamada rápida al backend
            String miAlias = "MiCartera";
            try {
              String endpoint = ApiConfig.getAliasWallet.replaceAll("{address}", authCore.publicAddress.toLowerCase());
              final res = await http.get(Uri.parse(endpoint), headers: {
                if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
              });
              if (res.statusCode == 200) {
                miAlias = jsonDecode(res.body)['alias'] ?? "MiCartera";
              }
            } catch(e) {
              print("No se pudo obtener el alias propio: $e");
            }

            // 2. Descargamos todo el historial del usuario
            final historialCompleto = await txService.getTransactionHistory();

            // 3. Filtramos SOLO las transacciones de este contacto específico
            final targetAddress = walletAddress.toLowerCase();
            List<dynamic> txFiltradas = historialCompleto.where((tx) {
              final sender = (tx['senderAddress'] ?? '').toString().toLowerCase();
              final receiver = (tx['receiverAddress'] ?? '').toString().toLowerCase();
              return sender == targetAddress || receiver == targetAddress;
            }).toList();

            // 4. Aplicamos filtro de fecha si seleccionó "Últimos 30 días"
            if (soloUltimos30Dias) {
              final limiteFecha = DateTime.now().subtract(const Duration(days: 30));
              txFiltradas = txFiltradas.where((tx) {
                if (tx['timestamp'] == null) return false;
                try {
                  DateTime fechaTx = DateTime.parse(tx['timestamp'].toString());
                  return fechaTx.isAfter(limiteFecha);
                } catch (e) {
                  return false;
                }
              }).toList();
            }

            // 5. Validamos si hay datos
            if (txFiltradas.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No hay transacciones con @$aliasDestino en este periodo.", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
              );
              return;
            }

            // 🔥 6. ENVIAMOS AL NUEVO GENERADOR DE PDF AVANZADO 🔥
            await ShareHelper.generarYCompartirPDFContacto(
              context, 
              txFiltradas, 
              authCore.publicAddress,
              miAlias,          // Tu Alias
              walletAddress,    // Billetera del Contacto
              aliasDestino      // Alias del Contacto
            );

          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error al generar reporte: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, size: 50, color: Colors.redAccent),
              const SizedBox(height: 15),
              Text("Generar Reporte PDF", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("Historial con @$aliasDestino", style: TextStyle(color: onSurfaceColor.withOpacity(0.6))),
              const SizedBox(height: 30),

              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                title: Text("Últimos 30 días", style: TextStyle(color: onSurfaceColor)),
                trailing: const Icon(Icons.download, color: Colors.blueAccent),
                onTap: () => procesarReporte(true), 
              ),
              Divider(color: Theme.of(context).dividerColor),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.blueAccent),
                title: Text("Todo el historial (Histórico)", style: TextStyle(color: onSurfaceColor)),
                trailing: const Icon(Icons.download, color: Colors.blueAccent),
                onTap: () => procesarReporte(false), 
              ),
            ],
          ),
        );
      }
    );
  }
}