import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/scheduled_details_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../config/api_config.dart';

class ScheduledPaymentsScreen extends StatefulWidget {
  const ScheduledPaymentsScreen({super.key});

  @override
  State<ScheduledPaymentsScreen> createState() => _ScheduledPaymentsScreenState();
}

class _ScheduledPaymentsScreenState extends State<ScheduledPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  ScheduledPaymentService get scheduledService => Provider.of<ScheduledPaymentService>(context, listen: false);
  
  List<dynamic> _misPagos = [];
  List<dynamic> _misClientes = []; 
  
  IOWebSocketChannel? _txChannel; // WS Original para recibos On-Chain
  IOWebSocketChannel? _scheduledChannel; // 🔥 NUEVO: WS para el Cron y Acuerdos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
    _connectWebSockets();
  }

  void _connectWebSockets() {
    try {
      final headers = {if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"};
      
      // 1. Escucha Transacciones Regulares (El WS que ya tenías)
      final wsTxUrl = "${ApiConfig.wsTransactionsUpdates}/${authCore.publicAddress.toLowerCase()}";
      _txChannel = IOWebSocketChannel.connect(Uri.parse(wsTxUrl), headers: headers);
      _txChannel!.stream.listen((message) {
        if (mounted && (message == "COMPLETED" || message == "SCHEDULED_EXECUTED" || message == "SUBSCRIPTION_FAILED")) {
          _loadAllData(silent: true);
        }
      });

      // 2. 🔥 NUEVO: Escucha el Cron y Creación/Cancelación de planes
      String baseWsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final wsSchedUrl = "$baseWsUrl/ws/scheduled/${authCore.publicAddress.toLowerCase()}";
      _scheduledChannel = IOWebSocketChannel.connect(Uri.parse(wsSchedUrl), headers: headers);
      _scheduledChannel!.stream.listen((message) {
        print("📲 WS Scheduled Event: $message");
        if (mounted) _loadAllData(silent: true); // Recarga instantánea
      }, onError: (err) {
        print("❌ WS Scheduled Error: $err");
      });

    } catch (e) {
      print("Error conectando WS: $e");
    }
  }

  @override
  void dispose() {
    _txChannel?.sink.close();
    _scheduledChannel?.sink.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool silent = false}) async {
    final cacheService = LocalCacheService();
    final wallet = authCore.publicAddress.toLowerCase();

    if (!silent) {
      final cachedPagos = cacheService.getCachedScheduledPayments(wallet);
      if (cachedPagos.isNotEmpty && mounted) {
        setState(() { _misPagos = cachedPagos; _isLoading = false; });
      } else {
        setState(() => _isLoading = true);
      }
    }

    final results = await Future.wait([
      scheduledService.getMyScheduledPayments(),
      scheduledService.getMerchantSubscriptions()
    ]);

    if (mounted) {
      setState(() {
        _misPagos = results[0];
        _misClientes = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Suscripciones y Pagos", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: onSurface.withOpacity(0.5),
          tabs: const [
            Tab(text: "Mis Pagos", icon: Icon(Icons.outbox_rounded)),
            Tab(text: "Mis Clientes", icon: Icon(Icons.storefront_rounded)), 
          ],
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMisPagosTab(colorScheme, onSurface),
              _buildMerchantTab(colorScheme, onSurface),
            ],
          ),
    );
  }

  // =========================================================================
  // 💸 TAB 1: LO QUE YO PAGO 
  // =========================================================================
  // Widget _buildMisPagosTab(ColorScheme colorScheme, Color onSurface) {
  //   if (_misPagos.isEmpty) {
  //     return Center(child: Text("No tienes pagos automáticos activos", style: TextStyle(color: onSurface.withOpacity(0.5))));
  //   }

  //   return RefreshIndicator(
  //     onRefresh: () async => _loadAllData(),
  //     child: ListView.builder(
  //       padding: const EdgeInsets.all(20),
  //       itemCount: _misPagos.length,
  //       itemBuilder: (context, i) {
  //         final p = _misPagos[i];
  //         bool isSubscription = p['totalInstallments'] >= 999;
  //         bool isFailed = p['status'] == 'FAILED_FUNDS';
  //         bool isCompleted = p['status'] == 'COMPLETED';

  //         return Card(
  //           margin: const EdgeInsets.only(bottom: 16),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(24),
  //             side: isFailed ? BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1.5) : BorderSide.none,
  //           ),
  //           elevation: 0,
  //           color: onSurface.withOpacity(0.03),
  //           child: ListTile(
  //             contentPadding: const EdgeInsets.all(16),
  //             leading: CircleAvatar(
  //               radius: 24,
  //               backgroundColor: isCompleted ? Colors.green.withOpacity(0.1) : (isFailed ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1)),
  //               child: Icon(
  //                 isCompleted ? Icons.check_circle_rounded : (isFailed ? Icons.error_outline_rounded : (isSubscription ? Icons.sync_rounded : Icons.calendar_month_rounded)), 
  //                 color: isCompleted ? Colors.green : (isFailed ? colorScheme.error : colorScheme.primary)
  //               ),
  //             ),
  //             title: Text(p['paymentReason'] ?? "Pago Programado", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
  //             subtitle: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const SizedBox(height: 4),
  //               Text(
  //                   "A: ${p['aliasDestino'] != null ? '@${p['aliasDestino']}' : '0x${p['toAddress'].toString().substring(2, 6)}...'}", 
  //                   style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)
  //                 ),
  //                 Text("${p['amountPerPayment']} TTC - ${p['frequency']}", style: TextStyle(color: onSurface.withOpacity(0.8))),
  //                 const SizedBox(height: 4),
  //                 _buildDateText(p['nextExecutionDate'], isCompleted, isFailed, colorScheme, onSurface),
  //               ],
  //             ),
  //             trailing: isCompleted ? null : PopupMenuButton<String>(
  //               icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.5)),
  //               onSelected: (val) { if (val == 'eliminar') _confirmarCancelacion(p['id'], false); },
  //               itemBuilder: (context) => [
  //                 PopupMenuItem(value: 'eliminar', child: Text('Cancelar Plan', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold))),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  // // =========================================================================
  // // 🏢 TAB 2: PANEL MERCHANT (LO QUE ME PAGAN)
  // // =========================================================================
  // Widget _buildMerchantTab(ColorScheme colorScheme, Color onSurface) {
  //   if (_misClientes.isEmpty) {
  //     return Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.storefront_rounded, size: 60, color: onSurface.withOpacity(0.2)),
  //           const SizedBox(height: 16),
  //           Text("No tienes suscriptores activos.", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16)),
  //           const SizedBox(height: 8),
  //           Text("Comparte tu alias para que\notros te paguen automáticamente.", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 14)),
  //         ],
  //       )
  //     );
  //   }

  //   return RefreshIndicator(
  //     onRefresh: () async => _loadAllData(),
  //     child: ListView.builder(
  //       padding: const EdgeInsets.all(20),
  //       itemCount: _misClientes.length,
  //       itemBuilder: (context, i) {
  //         final client = _misClientes[i];
          
  //         String statusText;
  //         Color statusColor;
  //         IconData statusIcon;
  //         bool isMoroso = false;
  //         bool isCompleted = false;

  //         if (client['status'] == 'COMPLETED') {
  //           statusText = "Completado";
  //           statusColor = Colors.green;
  //           statusIcon = Icons.done_all_rounded;
  //           isCompleted = true;
  //         } else if (client['status'] == 'FAILED_FUNDS') {
  //           statusText = "No pagado";
  //           statusColor = colorScheme.error; 
  //           statusIcon = Icons.warning_rounded;
  //           isMoroso = true;
  //         } else {
  //           statusText = "Al día - Pendiente";
  //           statusColor = colorScheme.primary; 
  //           statusIcon = Icons.pending_actions_rounded;
  //         }
          
  //         return Card(
  //           margin: const EdgeInsets.only(bottom: 16),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(24),
  //             side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5)
  //           ),
  //           elevation: 0,
  //           color: statusColor.withOpacity(0.05),
  //           child: Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   children: [
  //                     CircleAvatar(
  //                       radius: 20,
  //                       backgroundColor: statusColor.withOpacity(0.2),
  //                       child: Icon(statusIcon, color: statusColor, size: 20),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text("@${client['aliasOrigen']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                           Text("Paga: ${client['amountPerPayment']} TTC / ${client['frequency']}", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13)),
  //                         ],
  //                       ),
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                       decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
  //                       child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
  //                     )
  //                   ],
  //                 ),
  //                 const Divider(height: 24),
  //                 Text("Servicio: ${client['paymentReason']}", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 const SizedBox(height: 5),
                  
  //                 if (!isCompleted)
  //                   _buildDateText(client['nextExecutionDate'], false, isMoroso, colorScheme, onSurface),
                  
  //                 if (isMoroso) ...[
  //                   const SizedBox(height: 15),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: Colors.orange.withOpacity(0.15),
  //                             foregroundColor: Colors.orange[800],
  //                             elevation: 0,
  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
  //                           ),
  //                           icon: const Icon(Icons.notifications_active_rounded, size: 18),
  //                           label: const Text("Notificar Deuda", style: TextStyle(fontWeight: FontWeight.bold)),
  //                           onPressed: () => _enviarRecordatorioPush(client['walletOrigen'], client['aliasOrigen']),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 10),
  //                       IconButton(
  //                         style: IconButton.styleFrom(backgroundColor: colorScheme.error.withOpacity(0.1)),
  //                         icon: Icon(Icons.block_rounded, color: colorScheme.error),
  //                         tooltip: "Suspender Servicio",
  //                         onPressed: () => _confirmarCancelacion(client['id'], true), 
  //                       )
  //                     ],
  //                   )
  //                 ]
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildMisPagosTab(ColorScheme colorScheme, Color onSurface) {
    if (_misPagos.isEmpty) {
      return Center(child: Text("No tienes pagos automáticos activos", style: TextStyle(color: onSurface.withOpacity(0.5))));
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _misPagos.length,
        itemBuilder: (context, i) {
          final p = _misPagos[i];
          bool isSubscription = p['totalInstallments'] >= 999;
          bool isFailed = p['status'] == 'FAILED_FUNDS';
          bool isCompleted = p['status'] == 'COMPLETED';

          String statusText = isCompleted ? "FINALIZADA" : (isFailed ? "FALLIDA" : "ACTIVA");
          Color statusBg = onSurface.withOpacity(0.1);
          Color statusTextCol = onSurface.withOpacity(0.8);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias, // 🔥 Permite que el efecto ripple de InkWell no se salga de los bordes
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isFailed ? BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1.0) : BorderSide(color: onSurface.withOpacity(0.05)),
            ),
            elevation: 0,
            color: Theme.of(context).cardColor,
            child: InkWell(
              onTap: () {
                // 🔥 Abrir Modal y adaptar las llaves del JSON
                ScheduledDetailsModal.show(context, {
                  ...p,
                  'amount': p['amountPerPayment'],
                  'executionDate': p['nextExecutionDate'],
                  'receiverAlias': p['aliasDestino'],
                  'receiverAddress': p['toAddress'],
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                          child: Icon(isSubscription ? Icons.ondemand_video_rounded : Icons.calendar_today_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p['paymentReason'] ?? "Pago Programado", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                          child: Text(statusText, style: TextStyle(color: statusTextCol, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: onSurface.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("DESTINATARIO", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  p['aliasDestino'] != null ? '@${p['aliasDestino']}' : '0x${p['toAddress'].toString().substring(2, 6)}...${p['toAddress'].toString().substring(p['toAddress'].toString().length - 4)}',
                                  style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.content_copy_rounded, size: 16, color: onSurface.withOpacity(0.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 18, color: onSurface.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            Text("${p['amountPerPayment']} TTC • ${p['frequency']}", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        if (!isCompleted)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.5)),
                            onSelected: (val) { if (val == 'eliminar') _confirmarCancelacion(p['id'], false); },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'eliminar', child: Text('Cancelar Plan', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold))),
                            ],
                          ),
                      ],
                    ),
                    if (!isCompleted && !isFailed) ...[
                      const SizedBox(height: 8),
                      _buildDateText(p['nextExecutionDate'], false, false, colorScheme, onSurface),
                    ],
                    if (isFailed) ...[
                      const SizedBox(height: 8),
                      _buildDateText(p['nextExecutionDate'], false, true, colorScheme, onSurface),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMerchantTab(ColorScheme colorScheme, Color onSurface) {
    if (_misClientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 60, color: onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text("No tienes suscriptores activos.", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16)),
          ],
        )
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _misClientes.length,
        itemBuilder: (context, i) {
          final client = _misClientes[i];
          bool isMoroso = client['status'] == 'FAILED_FUNDS';
          bool isCompleted = client['status'] == 'COMPLETED';

          String statusText = isCompleted ? "FINALIZADA" : (isMoroso ? "FALLIDA" : "ACTIVA");
          Color statusBg = onSurface.withOpacity(0.1);
          Color statusTextCol = onSurface.withOpacity(0.8);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isMoroso ? BorderSide(color: colorScheme.error.withOpacity(0.5), width: 1.0) : BorderSide(color: onSurface.withOpacity(0.05)),
            ),
            elevation: 0,
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                        child: Icon(isCompleted ? Icons.done_all_rounded : (isMoroso ? Icons.warning_rounded : Icons.storefront_rounded), color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(client['paymentReason'] ?? "Suscripción", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(statusText, style: TextStyle(color: statusTextCol, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: onSurface.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DEUDOR / CLIENTE", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                client['aliasOrigen'] != null ? '@${client['aliasOrigen']}' : '0x${client['walletOrigen'].toString().substring(2, 6)}...${client['walletOrigen'].toString().substring(client['walletOrigen'].toString().length - 4)}',
                                style: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.content_copy_rounded, size: 16, color: onSurface.withOpacity(0.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 18, color: onSurface.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text("${client['amountPerPayment']} TTC • ${client['frequency']}", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      if (!isCompleted)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: onSurface.withOpacity(0.5)),
                          onSelected: (val) {
                            if (val == 'notificar') _enviarRecordatorioPush(client['walletOrigen'], client['aliasOrigen'] ?? 'Cliente');
                            if (val == 'suspender') _confirmarCancelacion(client['id'], true);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'notificar', child: Text('Notificar Deuda', style: TextStyle(fontWeight: FontWeight.bold))),
                            PopupMenuItem(value: 'suspender', child: Text('Suspender Servicio', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold))),
                          ],
                        ),
                    ],
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    _buildDateText(client['nextExecutionDate'], false, isMoroso, colorScheme, onSurface),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 🛠️ MÉTODOS AUXILIARES
  // =========================================================================
  
  Widget _buildDateText(String rawDate, bool isCompleted, bool isFailed, ColorScheme colorScheme, Color onSurface) {
    if (isCompleted) return const Text("Suscripción Finalizada", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12));
    if (isFailed) return Text("Atención: El último cobro falló", style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold));

    if (!rawDate.endsWith('Z')) rawDate += 'Z'; 
    DateTime localDt = DateTime.parse(rawDate).toLocal();
    String fecha = localDt.toString().substring(0, 16).replaceAll(' ', ' a las ');
    
    return Text("Próximo cobro: $fecha", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12));
  }

  Future<void> _enviarRecordatorioPush(String addressMoroso, String alias) async {
    bool ok = await scheduledService.sendMerchantReminder(addressMoroso); 
    if (ok) {
      UIHelper.showCustomSnackbar("Push enviado a @$alias");
    } else {
      UIHelper.showCustomSnackbar("Error enviando notificación", isError: true);
    }
  }

  void _confirmarCancelacion(String id, bool isMerchant) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isMerchant ? "¿Suspender suscripción?" : "¿Cancelar plan?", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w900)),
        content: Text(
          isMerchant 
            ? "Se dejará de cobrar automáticamente a este cliente." 
            : "Se detendrán todos los cobros automáticos asociados a este registro.", 
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Volver", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () async {
              Navigator.pop(ctx);
              bool ok = await scheduledService.cancelScheduledPayment(id);
              if (ok) {
                UIHelper.showCustomSnackbar(isMerchant ? "Cliente suspendido" : "Plan eliminado");
                _loadAllData();
              }
            }, 
            child: const Text("Confirmar", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}