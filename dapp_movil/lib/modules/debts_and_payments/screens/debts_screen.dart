import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/debts_to_collect_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/debts_to_pay_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/transaction_pending_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import '../../../config/api_config.dart';
import '../modals/create_debt_modal.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../modals/debt_details_modal.dart'; 

import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<dynamic> _todasLasDeudas = [];
  bool _isLoading = true;
  IOWebSocketChannel? _wsChannel;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  DebtService get debtService => Provider.of<DebtService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _cargarDeudas();
    _conectarWebSocket();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _cargarDeudas() async {
    setState(() => _isLoading = true);
    final fresh = await debtService.getUserDebts();
    if (mounted) {
      setState(() { _todasLasDeudas = fresh; _isLoading = false; });
    }
  }

  void _conectarWebSocket() {
    try {
      final wsUrl = "${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/ws/users/${authCore.publicAddress.toLowerCase()}";
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
      );
      _wsChannel!.stream.listen((message) {
        if (message == "UPDATE_DEBTS" && mounted) _cargarDeudas();
      });
    } catch (e) { print("Error WS: $e"); }
  }

  // 🔥 DETECTOR DE PAGOS DIVIDIDOS
  bool _esPagoDividido(Map<String, dynamic> d) {
    return d['isSplit'] == true || d['type'] == 'SPLIT' || d['splitBillId'] != null || d['groupId'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String miAddress = authCore.publicAddress.toLowerCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Gestión de Deudas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_principal',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () => CreateDebtModal.show(
          context: context, onSuccess: _cargarDeudas, 
          mostrarMensaje: (m, {esError = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: esError ? Colors.red : Colors.green))
        ),
        icon: const Icon(Icons.add), label: const Text("Cobrar"),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              isScrollable: true, 
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabAlignment: TabAlignment.start,
              tabs: const [ 
                Tab(text: "Deudas (Pagar)"), 
                Tab(text: "Cobros Directos"), 
                Tab(text: "Divididos (Pagar)"), 
                Tab(text: "Divididos (Cobrar)") 
              ],
            ),
            Expanded(
              child: _isLoading && _todasLasDeudas.isEmpty
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _todasLasDeudas.isEmpty
                  ? UIHelper.emptyState(
                      context: context, icon: Icons.sentiment_satisfied_alt_rounded,
                      title: "Todo al día", message: "No tienes deudas activas ni cobros pendientes.",
                    )
                  : (() {
                      // 1. Separamos por Deuda Normal vs Pago Dividido
                      List<dynamic> normales = _todasLasDeudas.where((d) => !_esPagoDividido(d)).toList();
                      List<dynamic> divididos = _todasLasDeudas.where((d) => _esPagoDividido(d)).toList();

                      // 2. Separamos por Rol (Deudor vs Acreedor)
                      List<dynamic> normalesPagar = normales.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
                      List<dynamic> normalesCobrar = normales.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();
                      
                      List<dynamic> divPagar = divididos.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
                      List<dynamic> divCobrar = divididos.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();

                      // 🔥 Llamamos a las pantallas hijas inyectando los datos
                      return TabBarView(
                        children: [
                          DebtsToPayScreen(lista: normalesPagar, emptyTitle: "Sin deudas", emptyMsg: "No tienes deudas directas por pagar.", onRefresh: _cargarDeudas),
                          DebtsToCollectScreen(lista: normalesCobrar, emptyTitle: "Sin cobros", emptyMsg: "No tienes cobros directos pendientes.", onRefresh: _cargarDeudas),
                          DebtsToPayScreen(lista: divPagar, emptyTitle: "Libre de cuotas", emptyMsg: "No tienes pagos grupales o divididos pendientes.", onRefresh: _cargarDeudas),
                          DebtsToCollectScreen(lista: divCobrar, emptyTitle: "Sin recolecciones", emptyMsg: "Nadie te debe dinero por pagos grupales.", onRefresh: _cargarDeudas),
                        ],
                      );
                    })(),
            ),
          ],
        ),
      ),
    );
  }
}

// class DebtsScreen extends StatefulWidget {
//   const DebtsScreen({super.key});

//   @override
//   State<DebtsScreen> createState() => _DebtsScreenState();
// }

// class _DebtsScreenState extends State<DebtsScreen> {
//  // Future<List<dynamic>>? _debtsFuture;
//  List<dynamic> _todasLasDeudas = [];
//   bool _isLoading = true;
//   IOWebSocketChannel? _wsChannel;

//   AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
//   DebtService get debtService => Provider.of<DebtService>(context, listen: false);
//   TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
//   GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);

//   // 🔥 ESTADOS PARA LOS 4 FILTROS INDEPENDIENTES
//   String _filtroPorPagar = "Todos";
//   String _filtroPorCobrar = "Todos";
//   String _filtroDivPagar = "Todos";
//   String _filtroDivCobrar = "Todos";

//   @override
//   void initState() {
//     super.initState();
//     _cargarDeudas();
//     _conectarWebSocket();
//   }

//   @override
//   void dispose() {
//     _wsChannel?.sink.close();
//     super.dispose();
//   }

//   // void _cargarDeudas() {
//   //   setState(() { _debtsFuture = debtService.getUserDebts(); });
//   // }

//   Future<void> _cargarDeudas() async {
//     final cacheService = LocalCacheService();
//     final wallet = authCore.publicAddress.toLowerCase();

//     // Caché Rápido
//     final cached = cacheService.getCachedUserDebts(wallet);
//     if (cached.isNotEmpty && mounted) {
//       setState(() { _todasLasDeudas = cached; _isLoading = false; });
//     } else {
//       if (mounted) setState(() => _isLoading = true);
//     }

//     // Red
//     final fresh = await debtService.getUserDebts();
//     if (mounted) {
//       setState(() { _todasLasDeudas = fresh; _isLoading = false; });
//     }
//   }

//   void _conectarWebSocket() {
//     try {
//       final wsUrl = "${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/ws/users/${authCore.publicAddress.toLowerCase()}";
//       _wsChannel = IOWebSocketChannel.connect(
//         Uri.parse(wsUrl),
//         headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
//       );
//       _wsChannel!.stream.listen((message) {
//         if (message == "UPDATE_DEBTS" && mounted) _cargarDeudas();
//       });
//     } catch (e) { print("Error WS: $e"); }
//   }

//   // 🔥 DETECTOR DE PAGOS DIVIDIDOS (Ajusta la clave según lo que envíe tu Spring Boot)
//   bool _esPagoDividido(Map<String, dynamic> d) {
//     return d['isSplit'] == true || d['type'] == 'SPLIT' || d['splitBillId'] != null || d['groupId'] != null;
//   }

//   Future<void> _responderDeuda(String debtId, bool accept) async {
//     bool? confirm = await UIHelper.mostrarConfirmacion(
//       context: context,
//       titulo: accept ? "Aceptar Deuda" : "Rechazar Deuda",
//       mensaje: accept ? "¿Confirmas que reconoces esta deuda y te comprometes a pagarla?" : "¿Estás seguro de rechazar este cobro?",
//       textoConfirmar: accept ? "Sí, aceptar" : "Rechazar",
//       colorConfirmar: accept ? Colors.green : Colors.red,
//     );
    
//     if (confirm != true || !mounted) return;

//     showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza esta acción."));
//     bool auth = await authCore.authenticateUser();
    
//     if (!mounted) return;
//     Navigator.pop(context); 

//     if (!auth) return;

//     showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando", message: "Actualizando registros..."));
//     String res = await debtService.respondDebtRequest(debtId, accept);
//     if (mounted) Navigator.pop(context);
    
//     if (res == "Exito") {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? "Deuda aceptada" : "Deuda rechazada"), backgroundColor: accept ? Colors.green : Colors.orange));
//       _cargarDeudas();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $res"), backgroundColor: Colors.red));
//     }
//   }

//   Future<void> _compartirDeudaModal(String debtId) async {
//     List<dynamic> grupos = await groupService.getUserGroups();
//     if (!mounted) return;

//     String selectedGroupId = "";
//     final TextEditingController reasonController = TextEditingController();
//     bool isProcessing = false;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) {
//           final theme = Theme.of(ctx);
//           return Container(
//             decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
//             padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text("Pedir ayuda al Grupo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                     IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 const Text("Explica brevemente por qué necesitas que el grupo te ayude a saldar esta deuda.", style: TextStyle(color: Colors.grey, fontSize: 13)),
//                 const SizedBox(height: 16),
//                 TextField(controller: reasonController, decoration: InputDecoration(labelText: "Explicación para el grupo", prefixIcon: const Icon(Icons.campaign_rounded, color: Colors.orange), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   decoration: InputDecoration(labelText: "Selecciona tu Grupo", prefixIcon: const Icon(Icons.diversity_3_rounded, color: Colors.deepPurpleAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
//                   items: grupos.map<DropdownMenuItem<String>>((g) => DropdownMenuItem(value: g['id'], child: Text(g['name']))).toList(),
//                   onChanged: (val) => setModalState(() => selectedGroupId = val!),
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
//                   onPressed: isProcessing ? null : () async {
//                     if (selectedGroupId.isEmpty || reasonController.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Llena todos los campos"), backgroundColor: Colors.red)); return; }
//                     setModalState(() => isProcessing = true);

//                     showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu solicitud de ayuda."));
//                     bool auth = await authCore.authenticateUser();
//                     if (!mounted) return;
//                     Navigator.pop(context); 

//                     if (!auth) { setModalState(() => isProcessing = false); return; }

//                     Navigator.pop(ctx); // Cierra el modal
                    
//                     // Mostramos la pantalla de carga principal
//                     Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
//                       customTitle: "Enviando Petición", 
//                       customMessage: "Notificando a tu grupo...",
//                       expectedTxType: "SHARE_DEBT",
//                       onUpdateBalance: _cargarDeudas
//                     )));

//                     // 🔥 FIX: Aquí llamamos al servicio pasando la razón que escribió el usuario
//                     String res = await debtService.shareDebtToGroup(debtId, selectedGroupId, reasonController.text);
//                     if (mounted) Navigator.pop(context); // Cierra la pantalla de carga

//                     if (res == "Exito") { 
//                       UIHelper.showCustomSnackbar("Solicitud de ayuda enviada al grupo", isError: false);
//                       _cargarDeudas();
//                     } else { 
//                       UIHelper.showCustomSnackbar(res, isError: true); 
//                     }
//                   },
//                   icon: isProcessing ? const SizedBox() : const Icon(Icons.volunteer_activism_rounded),
//                   label: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Pedir ayuda", style: TextStyle(fontWeight: FontWeight.bold)),
//                 )
//               ],
//             ),
//           );
//         }
//       )
//     );
//   }
//   // Widget _buildFiltros(List<String> opciones, String seleccionado, Function(String) onSelect) {
//   //   final theme = Theme.of(context);
//   //   final colorScheme = theme.colorScheme;
//   //   return SingleChildScrollView(
//   //     scrollDirection: Axis.horizontal,
//   //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//   //     child: Row(
//   //       children: opciones.map((opcion) {
//   //         bool isSelected = seleccionado == opcion;
//   //         return Padding(
//   //           padding: const EdgeInsets.only(right: 8),
//   //           child: ChoiceChip(
//   //             label: Text(opcion),
//   //             labelStyle: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
//   //             selected: isSelected,
//   //             selectedColor: colorScheme.primary,
//   //             backgroundColor: theme.cardColor,
//   //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none), 
//   //             showCheckmark: false,
//   //             onSelected: (bool selected) { if (selected) onSelect(opcion); },
//   //           ),
//   //         );
//   //       }).toList(),
//   //     ),
//   //   );
//   // }

// Widget _buildFiltros(List<String> opciones, String seleccionado, Function(String) onSelect) {
//     final theme = Theme.of(context);
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: opciones.map((opcion) {
//           bool isSelected = seleccionado == opcion;
//           return Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: GestureDetector(
//               onTap: () => onSelect(opcion),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected ? const Color(0xFFB5C0FF) : theme.colorScheme.onSurface.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   opcion,
//                   style: TextStyle(
//                     color: isSelected ? Colors.black87 : theme.colorScheme.onSurface.withOpacity(0.8),
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   List<dynamic> _filtrarListaPorPagar(List<dynamic> base, String filtroActual) {
//     return base.where((d) {
//       if (filtroActual == "Todos") return true;
//       if (filtroActual == "Por Aceptar") return d['status'] == "PENDING_APPROVAL";
//       if (filtroActual == "Pendientes") return d['status'] == "ACTIVE";
//       if (filtroActual == "Pagados") return d['status'] == "COMPLETED";
//       return true;
//     }).toList();
//   }

//   List<dynamic> _filtrarListaPorCobrar(List<dynamic> base, String filtroActual) {
//     return base.where((d) {
//       if (filtroActual == "Todos") return true;
//       if (filtroActual == "Pendientes") return d['status'] == "ACTIVE" || d['status'] == "PENDING_APPROVAL";
//       if (filtroActual == "Completadas") return d['status'] == "COMPLETED";
//       if (filtroActual == "Fallidas") return d['status'] == "REJECTED";
//       return true;
//     }).toList();
//   }

//   // 🔥 WIDGET REUTILIZABLE PARA LISTAS "POR PAGAR" (Normales o Divididas)
//   // Widget _buildVistaPorPagar(List<dynamic> lista, String filtroActual, Function(String) onSelectFiltro, String emptyTitle, String emptyMsg) {
//   //   final colorScheme = Theme.of(context).colorScheme;
//   //   return Column(
//   //     children: [
//   //       _buildFiltros(["Todos", "Por Aceptar", "Pendientes", "Pagados"], filtroActual, onSelectFiltro),
//   //       Expanded(
//   //         child: lista.isEmpty
//   //           ? UIHelper.emptyState(context: context, icon: Icons.credit_card_off_rounded, title: emptyTitle, message: emptyMsg)
//   //           : ListView.builder(
//   //               padding: const EdgeInsets.symmetric(horizontal: 16),
//   //               itemCount: lista.length,
//   //               itemBuilder: (ctx, i) {
//   //                 var d = lista[i];
//   //                 double total = double.tryParse(d['totalAmount'].toString()) ?? 0;
//   //                 double pagado = double.tryParse(d['paidAmount'].toString()) ?? 0;
//   //                 double restante = total - pagado;
//   //                 bool isPending = d['status'] == "PENDING_APPROVAL";
//   //                 bool isActive = d['status'] == "ACTIVE";
//   //                 bool isCompleted = d['status'] == "COMPLETED";

//   //                 return Card(
//   //                   margin: const EdgeInsets.only(bottom: 12),
//   //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//   //                   child: InkWell(
//   //                     borderRadius: BorderRadius.circular(16),
//   //                     onTap: () => DebtDetailsModal.show(context: context, debt: d), 
//   //                     child: Padding(
//   //                       padding: const EdgeInsets.all(16),
//   //                       child: Column(
//   //                         crossAxisAlignment: CrossAxisAlignment.start,
//   //                         children: [
//   //                           Row(
//   //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //                             children: [
//   //                               Expanded(child: Text(d['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
//   //                               Chip(label: Text(d['status'], style: TextStyle(fontSize: 10, color: isCompleted ? Colors.green : (isPending ? Colors.orange : colorScheme.primary))), backgroundColor: isCompleted ? Colors.green.withOpacity(0.1) : (isPending ? Colors.orange.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1)), side: BorderSide.none),
//   //                             ],
//   //                           ),
//   //                           const SizedBox(height: 8),
//   //                           Text("Acreedor: ${d['creditorAddress'].toString().substring(0, 10)}..."),
//   //                           Text("Restante: $restante TTC", style: TextStyle(color: isCompleted ? Colors.green : colorScheme.error, fontWeight: FontWeight.bold)),
                            
//   //                           if (isPending) ...[
//   //                             const SizedBox(height: 16),
//   //                             Row(
//   //                               children: [
//   //                                 Expanded(child: OutlinedButton(onPressed: () => _responderDeuda(d['id'], false), child: const Text("Rechazar", style: TextStyle(color: Colors.red)))),
//   //                                 const SizedBox(width: 10),
//   //                                 Expanded(child: ElevatedButton(onPressed: () => _responderDeuda(d['id'], true), child: const Text("Aceptar"))),
//   //                               ],
//   //                             )
//   //                           ] else if (isActive) ...[
//   //                             const SizedBox(height: 16),
//   //                             Row(
//   //                               children: [
//   //                                 Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.groups_rounded, size: 18), label: const Text("Ayuda"), onPressed: () => _compartirDeudaModal(d['id']))),
//   //                                 const SizedBox(width: 10),
//   //                                 Expanded(child: ElevatedButton.icon(
//   //                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
//   //                                   icon: const Icon(Icons.payment_rounded, size: 18), label: const Text("Pagar"),
//   //                                   onPressed: () async {
//   //                                     String miSaldo = await txService.getBalance();
//   //                                     if (!mounted) return;
//   //                                     SendModal.show(
//   //                                       context: context, balanceTTC: miSaldo, initialAddress: d['creditorAddress'], debtId: d['id'], onUpdateBalance: _cargarDeudas, 
//   //                                       mostrarMensaje: (msg, {bool esError = false}) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green)); }
//   //                                     );
//   //                                   },
//   //                                 )),
//   //                               ],
//   //                             )
//   //                           ]
//   //                         ],
//   //                       ),
//   //                     ),
//   //                   ),
//   //                 );
//   //               },
//   //             ),
//   //       ),
//   //     ],
//   //   );
//   // }

//   Widget _buildVistaPorPagar(List<dynamic> lista, String filtroActual, Function(String) onSelectFiltro, String emptyTitle, String emptyMsg) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Column(
//       children: [
//         _buildFiltros(["Todos", "Por Aceptar", "Pendientes", "Pagados"], filtroActual, onSelectFiltro),
//         Expanded(
//           child: lista.isEmpty
//             ? UIHelper.emptyState(context: context, icon: Icons.credit_card_off_rounded, title: emptyTitle, message: emptyMsg)
//             : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: lista.length,
//                 itemBuilder: (ctx, i) {
//                   var d = lista[i];
//                   double total = double.tryParse(d['totalAmount'].toString()) ?? 0;
//                   double pagado = double.tryParse(d['paidAmount'].toString()) ?? 0;
//                   double restante = total - pagado;
//                   bool isPending = d['status'] == "PENDING_APPROVAL";
//                   bool isActive = d['status'] == "ACTIVE";
//                   bool isCompleted = d['status'] == "COMPLETED";

//                   Color statusBg = isCompleted ? const Color(0xFF4361EE) : (isPending ? const Color(0xFFD97706) : colorScheme.primary);
//                   String statusText = d['status'];

//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(16),
//                       onTap: () => DebtDetailsModal.show(context: context, debt: d), 
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     d['reason'], 
//                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
//                                     overflow: TextOverflow.ellipsis
//                                   )
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                   decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
//                                   child: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             Text("Acreedor: ${d['creditorAddress'].toString().substring(0, 10)}...", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
//                             const SizedBox(height: 4),
//                             Text("Restante: $restante TTC", style: TextStyle(color: isCompleted ? const Color(0xFFB5C0FF) : const Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 14)),
                            
//                             if (isPending) ...[
//                               const SizedBox(height: 16),
//                               Row(
//                                 children: [
//                                   Expanded(child: OutlinedButton(onPressed: () => _responderDeuda(d['id'], false), child: const Text("Rechazar", style: TextStyle(color: Colors.redAccent)))),
//                                   const SizedBox(width: 10),
//                                   Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white), onPressed: () => _responderDeuda(d['id'], true), child: const Text("Aceptar"))),
//                                 ],
//                               )
//                             ] else if (isActive) ...[
//                               const SizedBox(height: 16),
//                               Row(
//                                 children: [
//                                   Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.groups_rounded, size: 18), label: const Text("Ayuda"), onPressed: () => _compartirDeudaModal(d['id']))),
//                                   const SizedBox(width: 10),
//                                   Expanded(child: ElevatedButton.icon(
//                                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
//                                     icon: const Icon(Icons.payment_rounded, size: 18), label: const Text("Pagar"),
//                                     onPressed: () async {
//                                       String miSaldo = await txService.getBalance();
//                                       if (!mounted) return;
//                                       SendModal.show(
//                                         context: context, balanceTTC: miSaldo, initialAddress: d['creditorAddress'], debtId: d['id'], onUpdateBalance: _cargarDeudas, 
//                                         mostrarMensaje: (msg, {bool esError = false}) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green)); }
//                                       );
//                                     },
//                                   )),
//                                 ],
//                               )
//                             ]
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//         ),
//       ],
//     );
//   }

//   //  WIDGET REUTILIZABLE PARA LISTAS "POR COBRAR" (Normales o Divididas)
// Widget _buildVistaPorCobrar(List<dynamic> lista, String filtroActual, Function(String) onSelectFiltro, String emptyTitle, String emptyMsg) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return Column(
//       children: [
//         _buildFiltros(["Todos", "Pendientes", "Completadas", "Fallidas"], filtroActual, onSelectFiltro),
//         Expanded(
//           child: lista.isEmpty
//             ? UIHelper.emptyState(context: context, icon: Icons.credit_score_rounded, title: emptyTitle, message: emptyMsg)
//             : ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: lista.length,
//                 itemBuilder: (ctx, i) {
//                   var d = lista[i];
//                   double total = double.tryParse(d['totalAmount'].toString()) ?? 0;
//                   double pagado = double.tryParse(d['paidAmount'].toString()) ?? 0;
//                   bool isPending = d['status'] == "PENDING_APPROVAL" || d['status'] == "ACTIVE";
//                   bool isCompleted = d['status'] == "COMPLETED";
                  
//                   Color statusBg = isCompleted ? const Color(0xFF4361EE) : (isPending ? const Color(0xFFD97706) : Colors.redAccent);
//                   String statusText = d['status'];

//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(16),
//                       onTap: () => DebtDetailsModal.show(context: context, debt: d), 
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     d['reason'], 
//                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
//                                     overflow: TextOverflow.ellipsis
//                                   )
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                   decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
//                                   child: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             Text("Deudor: ${d['debtorAddress'].toString().substring(0, 10)}...", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
//                             const SizedBox(height: 4),
//                             Text("Pagado: $pagado / $total TTC", style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 14)),
                            
//                             // 🔥 NUEVO: Botón de recordar solo visible si la deuda está activa y eres el acreedor
//                             if (isPending) ...[
//                                const SizedBox(height: 16),
//                                SizedBox(
//                                  width: double.infinity,
//                                  child: OutlinedButton.icon(
//                                    style: OutlinedButton.styleFrom(
//                                      foregroundColor: colorScheme.primary, 
//                                      side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
//                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
//                                    ),
//                                    icon: const Icon(Icons.notifications_active_rounded, size: 18),
//                                    label: const Text("Enviar Recordatorio de Pago", style: TextStyle(fontWeight: FontWeight.bold)),
//                                    onPressed: () {
//                                      _mostrarModalRecordatorio(d['id']);
//                                    }
//                                  ),
//                                )
//                             ]
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//         ),
//       ],
//     );
//   }

//   void _mostrarModalRecordatorio(String debtId) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Theme.of(context).cardColor,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text("Enviar Recordatorio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               const Text("¿Cómo deseas notificar al deudor?", style: TextStyle(color: Colors.grey)),
//               const SizedBox(height: 24),
//               ListTile(
//                 leading: const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent),
//                 title: const Text("Notificación Push", style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: const Text("Aparecerá en su celular al instante"),
//                 onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "PUSH"); },
//               ),
//               const Divider(height: 1),
//               ListTile(
//                 leading: const Icon(Icons.email_rounded, color: Colors.orangeAccent),
//                 title: const Text("Correo Electrónico", style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: const Text("Se enviará a su cuenta registrada"),
//                 onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "EMAIL"); },
//               ),
//               const Divider(height: 1),
//               ListTile(
//                 leading: const Icon(Icons.wechat_rounded, color: Colors.green),
//                 title: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: const Text("Notificación mediante bot"),
//                 onTap: () { Navigator.pop(ctx); _enviarRecordatorio(debtId, "WHATSAPP"); },
//               ),
//             ],
//           ),
//         );
//       }
//     );
//   }

//   Future<void> _enviarRecordatorio(String debtId, String method) async {
//     UIHelper.showCustomSnackbar("Enviando recordatorio...", isError: false);
//     String res = await debtService.sendPaymentReminder(debtId, method);
    
//     if (res == "Exito") {
//       UIHelper.showCustomSnackbar("Recordatorio enviado con éxito al deudor por $method.");
//     } else {
//       UIHelper.showCustomSnackbar(res, isError: true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     String miAddress = authCore.publicAddress.toLowerCase();

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text("Gestión de Deudas", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         heroTag: 'fab_principal',
//         backgroundColor: colorScheme.primary,
//         foregroundColor: colorScheme.onPrimary,
//         onPressed: () => CreateDebtModal.show(
//           context: context, onSuccess: _cargarDeudas, 
//           mostrarMensaje: (m, {esError = false}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: esError ? Colors.red : Colors.green))
//         ),
//         icon: const Icon(Icons.add), label: const Text("Cobrar"),
//       ),
//       // 🔥 AHORA TENEMOS 4 TABS SCROLLABLES
//       body: DefaultTabController(
//         length: 4,
//         child: Column(
//           children: [
//             TabBar(
//               isScrollable: true, // Crucial para que quepan 4 tabs sin apretarse
//               indicatorColor: colorScheme.primary,
//               labelColor: colorScheme.primary,
//               unselectedLabelColor: Colors.grey,
//               tabAlignment: TabAlignment.start,
//               tabs: const [ 
//                 Tab(text: "Deudas (Pagar)"), 
//                 Tab(text: "Cobros Directos"), 
//                 Tab(text: "Divididos (Pagar)"), 
//                 Tab(text: "Divididos (Cobrar)") 
//               ],
//             ),
//             // Expanded(
//             //   child: FutureBuilder<List<dynamic>>(
//             //     future: _debtsFuture,
//             //     builder: (context, snapshot) {
//             //       if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
//             //       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             //         return UIHelper.emptyState(
//             //           context: context, icon: Icons.sentiment_satisfied_alt_rounded,
//             //           title: "Todo al día", message: "No tienes deudas activas ni cobros pendientes.",
//             //         );
//             //       }

//             //       // 1. Separamos por Deuda Normal vs Pago Dividido
//             //       List<dynamic> normales = snapshot.data!.where((d) => !_esPagoDividido(d)).toList();
//             //       List<dynamic> divididos = snapshot.data!.where((d) => _esPagoDividido(d)).toList();

//             //       // 2. Separamos por Rol (Deudor vs Acreedor)
//             //       List<dynamic> normalesPagar = normales.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
//             //       List<dynamic> normalesCobrar = normales.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();
                  
//             //       List<dynamic> divPagar = divididos.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
//             //       List<dynamic> divCobrar = divididos.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();

//             //       // 3. Aplicamos los filtros de los Chips
//             //       List<dynamic> normalesPagarFiltrado = _filtrarListaPorPagar(normalesPagar, _filtroPorPagar);
//             //       List<dynamic> normalesCobrarFiltrado = _filtrarListaPorCobrar(normalesCobrar, _filtroPorCobrar);
                  
//             //       List<dynamic> divPagarFiltrado = _filtrarListaPorPagar(divPagar, _filtroDivPagar);
//             //       List<dynamic> divCobrarFiltrado = _filtrarListaPorCobrar(divCobrar, _filtroDivCobrar);

//             //       return TabBarView(
//             //         children: [
//             //           // TAB 1: Deudas Normales por Pagar
//             //           _buildVistaPorPagar(normalesPagarFiltrado, _filtroPorPagar, (v) => setState(() => _filtroPorPagar = v), "Sin deudas", "No tienes deudas directas por pagar."),
                      
//             //           // TAB 2: Deudas Normales por Cobrar
//             //           _buildVistaPorCobrar(normalesCobrarFiltrado, _filtroPorCobrar, (v) => setState(() => _filtroPorCobrar = v), "Sin cobros", "No tienes cobros directos pendientes."),
                      
//             //           // TAB 3: Pagos Divididos por Pagar
//             //           _buildVistaPorPagar(divPagarFiltrado, _filtroDivPagar, (v) => setState(() => _filtroDivPagar = v), "Libre de cuotas", "No tienes pagos grupales o divididos pendientes."),
                      
//             //           // TAB 4: Pagos Divididos por Cobrar
//             //           _buildVistaPorCobrar(divCobrarFiltrado, _filtroDivCobrar, (v) => setState(() => _filtroDivCobrar = v), "Sin recolecciones", "Nadie te debe dinero por pagos grupales."),
//             //         ],
//             //       );
//             //     },
//             //   ),
//             // ),
//             Expanded(
//               child: _isLoading && _todasLasDeudas.isEmpty
//                 ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
//                 : _todasLasDeudas.isEmpty
//                   ? UIHelper.emptyState(
//                       context: context, icon: Icons.sentiment_satisfied_alt_rounded,
//                       title: "Todo al día", message: "No tienes deudas activas ni cobros pendientes.",
//                     )
//                   : (() {
//                       // 1. Separamos por Deuda Normal vs Pago Dividido
//                       List<dynamic> normales = _todasLasDeudas.where((d) => !_esPagoDividido(d)).toList();
//                       List<dynamic> divididos = _todasLasDeudas.where((d) => _esPagoDividido(d)).toList();

//                       // 2. Separamos por Rol (Deudor vs Acreedor)
//                       List<dynamic> normalesPagar = normales.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
//                       List<dynamic> normalesCobrar = normales.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();
                      
//                       List<dynamic> divPagar = divididos.where((d) => d['debtorAddress'].toString().toLowerCase() == miAddress).toList();
//                       List<dynamic> divCobrar = divididos.where((d) => d['creditorAddress'].toString().toLowerCase() == miAddress).toList();

//                       // 3. Aplicamos los filtros de los Chips
//                       List<dynamic> normalesPagarFiltrado = _filtrarListaPorPagar(normalesPagar, _filtroPorPagar);
//                       List<dynamic> normalesCobrarFiltrado = _filtrarListaPorCobrar(normalesCobrar, _filtroPorCobrar);
                      
//                       List<dynamic> divPagarFiltrado = _filtrarListaPorPagar(divPagar, _filtroDivPagar);
//                       List<dynamic> divCobrarFiltrado = _filtrarListaPorCobrar(divCobrar, _filtroDivCobrar);

//                       return TabBarView(
//                         children: [
//                           _buildVistaPorPagar(normalesPagarFiltrado, _filtroPorPagar, (v) => setState(() => _filtroPorPagar = v), "Sin deudas", "No tienes deudas directas por pagar."),
//                           _buildVistaPorCobrar(normalesCobrarFiltrado, _filtroPorCobrar, (v) => setState(() => _filtroPorCobrar = v), "Sin cobros", "No tienes cobros directos pendientes."),
//                           _buildVistaPorPagar(divPagarFiltrado, _filtroDivPagar, (v) => setState(() => _filtroDivPagar = v), "Libre de cuotas", "No tienes pagos grupales o divididos pendientes."),
//                           _buildVistaPorCobrar(divCobrarFiltrado, _filtroDivCobrar, (v) => setState(() => _filtroDivCobrar = v), "Sin recolecciones", "Nadie te debe dinero por pagos grupales."),
//                         ],
//                       );
//                     })(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }