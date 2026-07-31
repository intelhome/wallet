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
  }) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    
    // Opciones: 0 = Últimos 30 días, 1 = Histórico, 2 = Rango Personalizado
    int _selectedOption = 0; 
    DateTime? _fechaInicio;
    DateTime? _fechaFin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (contextDialog, setStateDialog) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final onSurface = colorScheme.onSurface;
            final cardColor = theme.cardColor;

            Future<void> _seleccionarRango() async {
              final DateTimeRange? rango = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                helpText: 'Seleccionar Rango',
              );
              if (rango != null) {
                setStateDialog(() {
                  _selectedOption = 2; // Activa la 3ra opción automáticamente
                  _fechaInicio = rango.start;
                  _fechaFin = rango.end;
                });
              }
            }

            Future<void> procesarReporte() async {
              Navigator.pop(ctx); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recopilando transacciones...", style: TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent));

              try {
                String miAlias = "MiCartera";
                try {
                  String endpoint = ApiConfig.getAliasWallet.replaceAll("{address}", authCore.publicAddress.toLowerCase());
                  final res = await http.get(Uri.parse(endpoint), headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" });
                  if (res.statusCode == 200) miAlias = jsonDecode(res.body)['alias'] ?? "MiCartera";
                } catch(e) {}

                final historialCompleto = await txService.getTransactionHistory();
                final targetAddress = walletAddress.toLowerCase();
                
                List<dynamic> txFiltradas = historialCompleto.where((tx) {
                  final sender = (tx['senderAddress'] ?? '').toString().toLowerCase();
                  final receiver = (tx['receiverAddress'] ?? '').toString().toLowerCase();
                  return sender == targetAddress || receiver == targetAddress;
                }).toList();

                // FILTROS
                if (_selectedOption == 0) {
                  final limiteFecha = DateTime.now().subtract(const Duration(days: 30));
                  txFiltradas = txFiltradas.where((tx) {
                    if (tx['timestamp'] == null) return false;
                    try { return DateTime.parse(tx['timestamp'].toString()).isAfter(limiteFecha); } catch (e) { return false; }
                  }).toList();
                } else if (_selectedOption == 2 && _fechaInicio != null && _fechaFin != null) {
                  txFiltradas = txFiltradas.where((tx) {
                    if (tx['timestamp'] == null) return false;
                    try {
                      DateTime txDate = DateTime.parse(tx['timestamp'].toString());
                      DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
                      DateTime start = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
                      DateTime end = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day);
                      return !justDate.isBefore(start) && !justDate.isAfter(end);
                    } catch (e) { return false; }
                  }).toList();
                }

                if (txFiltradas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No hay transacciones en este periodo.", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
                  return;
                }

                await ShareHelper.generarYCompartirPDFContacto(context, txFiltradas, authCore.publicAddress, miAlias, walletAddress, aliasDestino);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
              }
            }

            // WIDGET HELPER PARA TARJETAS SELECCIONABLES
            Widget _buildOptionCard(int index, String title, String subtitle, IconData icon) {
              bool isSel = _selectedOption == index;
              return GestureDetector(
                onTap: () => setStateDialog(() => _selectedOption = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.05), width: isSel ? 2 : 1)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: const Color(0xFFBAC3FF), size: 24),
                            const SizedBox(height: 12),
                            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13, height: 1.4)),
                          ],
                        ),
                      ),
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSel ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.5), width: 2)),
                        child: isSel ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFBAC3FF), shape: BoxShape.circle))) : null,
                      )
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Reportes Financieros", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: const Color(0xFFC77DFF)),
                        const SizedBox(width: 6),
                        Text("Historial con ", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12)),
                        Text("@$aliasDestino", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildOptionCard(0, "Últimos 30 días", "Genera un resumen rápido del mes en curso. Ideal para cierres mensuales.", Icons.download_rounded),
                  _buildOptionCard(1, "Todo el historial (Histórico)", "Auditoría completa de todas las transacciones realizadas con este contacto.", Icons.download_rounded),

                  // TARJETA DE RANGO PERSONALIZADO
                  GestureDetector(
                    onTap: _seleccionarRango,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _selectedOption == 2 ? const Color(0xFFBAC3FF) : onSurface.withOpacity(0.05), width: _selectedOption == 2 ? 2 : 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, color: Color(0xFFBAC3FF), size: 24),
                              const SizedBox(width: 12),
                              Text("Rango Personalizado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Fecha de inicio", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.1))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fechaInicio != null ? "${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}" : "dd/mm/aaaa", style: TextStyle(color: _fechaInicio != null ? onSurface : onSurface.withOpacity(0.4))),
                                          Icon(Icons.calendar_today_rounded, size: 16, color: onSurface.withOpacity(0.4)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Fecha de fin", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: onSurface.withOpacity(0.1))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fechaFin != null ? "${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}" : "dd/mm/aaaa", style: TextStyle(color: _fechaFin != null ? onSurface : onSurface.withOpacity(0.4))),
                                          Icon(Icons.calendar_today_rounded, size: 16, color: onSurface.withOpacity(0.4)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBAC3FF), foregroundColor: const Color(0xFF00218d), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                      onPressed: () {
                        if (_selectedOption == 2 && (_fechaInicio == null || _fechaFin == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes seleccionar un rango de fechas")));
                          return;
                        }
                        procesarReporte();
                      }, 
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("Generar Reporte PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
//   static void show({
//     required BuildContext context,
//     required String aliasDestino,
//     required String walletAddress,
//     //required BlockchainService service, 
//   }) {
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);
// final txService = Provider.of<TransactionService>(context, listen: false);
//     showModalBottomSheet(
      
//       context: context,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (ctx) {
//         final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

//         // 🔥 FUNCIÓN QUE PROCESA Y GENERA EL NUEVO REPORTE 🔥
//         Future<void> procesarReporte(bool soloUltimos30Dias) async {
//           Navigator.pop(ctx); 
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Recopilando transacciones...", style: TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent)
//           );

//           try {
//             // 1. Obtenemos tu propio Alias haciendo una llamada rápida al backend
//             String miAlias = "MiCartera";
//             try {
//               String endpoint = ApiConfig.getAliasWallet.replaceAll("{address}", authCore.publicAddress.toLowerCase());
//               final res = await http.get(Uri.parse(endpoint), headers: {
//                 if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//               });
//               if (res.statusCode == 200) {
//                 miAlias = jsonDecode(res.body)['alias'] ?? "MiCartera";
//               }
//             } catch(e) {
//               print("No se pudo obtener el alias propio: $e");
//             }

//             // 2. Descargamos todo el historial del usuario
//             final historialCompleto = await txService.getTransactionHistory();

//             // 3. Filtramos SOLO las transacciones de este contacto específico
//             final targetAddress = walletAddress.toLowerCase();
//             List<dynamic> txFiltradas = historialCompleto.where((tx) {
//               final sender = (tx['senderAddress'] ?? '').toString().toLowerCase();
//               final receiver = (tx['receiverAddress'] ?? '').toString().toLowerCase();
//               return sender == targetAddress || receiver == targetAddress;
//             }).toList();

//             // 4. Aplicamos filtro de fecha si seleccionó "Últimos 30 días"
//             if (soloUltimos30Dias) {
//               final limiteFecha = DateTime.now().subtract(const Duration(days: 30));
//               txFiltradas = txFiltradas.where((tx) {
//                 if (tx['timestamp'] == null) return false;
//                 try {
//                   DateTime fechaTx = DateTime.parse(tx['timestamp'].toString());
//                   return fechaTx.isAfter(limiteFecha);
//                 } catch (e) {
//                   return false;
//                 }
//               }).toList();
//             }

//             // 5. Validamos si hay datos
//             if (txFiltradas.isEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text("No hay transacciones con @$aliasDestino en este periodo.", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
//               );
//               return;
//             }

//             // 🔥 6. ENVIAMOS AL NUEVO GENERADOR DE PDF AVANZADO 🔥
//             await ShareHelper.generarYCompartirPDFContacto(
//               context, 
//               txFiltradas, 
//               authCore.publicAddress,
//               miAlias,          // Tu Alias
//               walletAddress,    // Billetera del Contacto
//               aliasDestino      // Alias del Contacto
//             );

//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Error al generar reporte: $e", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
//             );
//           }
//         }

//         return Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.picture_as_pdf, size: 50, color: Colors.redAccent),
//               const SizedBox(height: 15),
//               Text("Generar Reporte PDF", style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 5),
//               Text("Historial con @$aliasDestino", style: TextStyle(color: onSurfaceColor.withOpacity(0.6))),
//               const SizedBox(height: 30),

//               ListTile(
//                 leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
//                 title: Text("Últimos 30 días", style: TextStyle(color: onSurfaceColor)),
//                 trailing: const Icon(Icons.download, color: Colors.blueAccent),
//                 onTap: () => procesarReporte(true), 
//               ),
//               Divider(color: Theme.of(context).dividerColor),
//               ListTile(
//                 leading: const Icon(Icons.date_range, color: Colors.blueAccent),
//                 title: Text("Todo el historial (Histórico)", style: TextStyle(color: onSurfaceColor)),
//                 trailing: const Icon(Icons.download, color: Colors.blueAccent),
//                 onTap: () => procesarReporte(false), 
//               ),
//             ],
//           ),
//         );
//       }
//     );
//   }
// }