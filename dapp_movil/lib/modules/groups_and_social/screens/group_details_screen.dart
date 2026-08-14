import 'dart:convert';
import 'dart:async';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/group_chat_screen.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/group_helps_tab.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/group_history_tab.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/group_members_tab.DART';
import 'package:dapp_movil/modules/groups_and_social/screens/group_payments_tab.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/group_proposals_tab.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/screens/stake_screen.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/buy_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/modals/group_payment_details_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:dapp_movil/modules/vaults_and_savings/modals/stake_modal.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/settings_group_screen.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';

import 'package:dapp_movil/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../wallet_and_tx/screens/transaction_pending_screen.dart'; // 🔥 Importamos la pantalla de carga realista
import '../modals/request_group_payment_modal.dart';
import '../../../core/helpers/share_helper.dart'; // Ajusta la ruta si es necesario
import '../modals/transaction_group_details_modal.dart';

class GroupDetailsScreen extends StatefulWidget {
  //final BlockchainService service;
  final dynamic groupData;

  const GroupDetailsScreen({
    super.key,
    required this.groupData,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin{

  // 🔥 AGREGAR:
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  GroupSocialService get groupService => Provider.of<GroupSocialService>(context, listen: false);
  TransactionService get txService => Provider.of<TransactionService>(context, listen: false);
DebtService get debtService => Provider.of<DebtService>(context, listen: false);
SmartVaultService get vaultService => Provider.of<SmartVaultService>(context, listen: false);
  
  late TabController _tabController;
  bool _isLoading = false;
  late Map<String, dynamic> _group;
  String _miEstado = "";
  IOWebSocketChannel? _wsChannel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  double _saldoGrupo = 0.0;
  bool _usarFondoComun = false;
  Future<List<dynamic>>? _paymentsFuture;
  Future<List<dynamic>>? _ayudaFuture;
  Future<List<dynamic>>? _historialFuture;
  // 🔥 ESTADOS PARA LOS FILTROS DE LAS TABS
  String _filtroHistorial = "Todos";
  String _filtroCobros = "Todos";
  String _filtroAyudas = "Todos";
  String _filtroTipoCobro = "Todos";

  DateTime? _fechaInicioHistorial;
  DateTime? _fechaFinHistorial;

  @override
  void initState() {
    super.initState();
    _group = widget.groupData;
    _determinarMiEstado();
    _conectarWebSocketGrupo();
    _cargarSaldoGrupo();
    _cargarCobros();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
   if (!_tabController.indexIsChanging) {
    setState(() {}); 
  }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wsChannel?.sink.close();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarCobros() {
    setState(() {
      _paymentsFuture = groupService.getGroupPayments(_group['id']);
      _ayudaFuture = debtService.getGroupSharedDebts(_group['id']);
      _historialFuture = groupService.getGroupTransactionsHistory(_group['id']); // 🔥 2. GUARDAMOS EL HISTORIAL
    });
  }

 void _conectarWebSocketGrupo() {
    try {
      final wsUrl = "${ApiConfig.wsGroupUpdates}/${_group['id']}";
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
      );

      _wsChannel!.stream.listen((message) async {
        print("WS Evento Grupo: $message");
        if (mounted && (message == "UPDATE" || message == "COMPLETED")) {
          // 🔥 MAGIA RESTAURADA: Esto repinta todo en vivo
          await _actualizarGrupoLocal();
          await _cargarSaldoGrupo();
          _cargarCobros(); 
        }
      }, onError: (err) { print("WS Error: $err"); });
    } catch (e) {}
  }

  // 🔥 MÉTODOS DEL CALENDARIO Y AGRUPACIÓN
  Future<void> _seleccionarRangoFechasHistorial() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),

      // 🔥 2. TRADUCIR LOS BOTONES Y TEXTOS
      helpText: 'Seleccionar Rango',
      cancelText: 'CANCELAR',
      confirmText: 'GUARDAR',
      saveText: 'GUARDAR',
      fieldStartHintText: 'dd/mm/aaaa',
      fieldEndHintText: 'dd/mm/aaaa',
      fieldStartLabelText: 'Inicio',
      fieldEndLabelText: 'Fin',

      initialDateRange: _fechaInicioHistorial != null && _fechaFinHistorial != null 
          ? DateTimeRange(start: _fechaInicioHistorial!, end: _fechaFinHistorial!) : null,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (rango != null) {
      setState(() {
        _fechaInicioHistorial = rango.start;
        _fechaFinHistorial = rango.end;
      });
    }
  }

  void _limpiarFiltroFechasHistorial() {
    setState(() {
      _fechaInicioHistorial = null;
      _fechaFinHistorial = null;
    });
  }

  Map<String, List<dynamic>> _groupTransactionsByDate(List<dynamic> transactions) {
    Map<String, List<dynamic>> grouped = {};
    for (var tx in transactions) {
      String dateStr = "Fecha desconocida";
      if (tx['timestamp'] != null) {
        try {
          DateTime date = DateTime.parse(tx['timestamp'].toString());
          dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        } catch (e) {
          dateStr = "Fecha desconocida";
        }
      }
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }
    return grouped;
  }

  Future<void> _actualizarGrupoLocal() async {
    if (!mounted) return;
    try {
      List<dynamic> groups = await groupService.getUserGroups();
      var updated = groups.firstWhere(
        (g) => g['id'] == _group['id'],
        orElse: () => null,
      );
      if (updated != null && mounted) {
        setState(() {
          _group = updated;
          _determinarMiEstado();
        });
      }
    } catch (e) {
      // Ignorar errores de red
    }
  }

  void _determinarMiEstado() {
    String miAddress = authCore.publicAddress.toLowerCase();

    if (_group['creatorAddress'].toString().toLowerCase() == miAddress) {
      _miEstado = "CREATOR";
      return;
    }

    List<dynamic> members = _group['members'] ?? [];
    for (var m in members) {
      if (m['walletAddress'].toString().toLowerCase() == miAddress) {
        _miEstado = m['status']; // "PENDING", "ACCEPTED", o "REJECTED"
        return;
      }
    }
    _miEstado = "UNKNOWN";
  }

// Future<void> _abrirBuscadorContactos() async {
//     setState(() => _isLoading = true);
//     try {
//       String endpoint = ApiConfig.getContacts.replaceAll("{address}", authCore.publicAddress.toLowerCase());
//       final res = await http.get(Uri.parse(endpoint), headers: {
//         "Content-Type": "application/json",
//         if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
//       });

//       if (res.statusCode == 200) {
//         List<dynamic> misContactos = jsonDecode(res.body);
        
//         if (!mounted) return;
//         showModalBottomSheet(
//           context: context,
//           backgroundColor: Theme.of(context).cardColor,
//           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//           builder: (ctx) => Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Text("Selecciona a quién invitar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: misContactos.length,
//                   itemBuilder: (ctx, i) {
//                     var c = misContactos[i];
//                     return ListTile(
//                       leading: const CircleAvatar(child: Icon(Icons.person)),
//                       title: Text("@${c['alias']}"),
//                       subtitle: Text(c['contactAddress'].toString().substring(0, 10) + "..."),
//                       trailing: ElevatedButton(
//                         child: const Text("Invitar"),
//                         onPressed: () async {
//                           Navigator.pop(ctx);
//                           setState(() => _isLoading = true);
//                           String r = await groupService.addGroupMember(_group['id'], c['contactAddress'], c['alias']);
//                           if (r == "SUCCESS") {
//                             UIHelper.showCustomSnackbar("Invitación enviada");
//                             await _actualizarGrupoLocal();
//                             setState(() => _isLoading = false);
//                           } else {
//                             UIHelper.showCustomSnackbar(r, isError: true);
//                             setState(() => _isLoading = false);
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               )
//             ],
//           ),
//         );
//       }
//     } catch (e) {
//       UIHelper.showCustomSnackbar("Error cargando contactos", isError: true);
//     }
//     setState(() => _isLoading = false);
//   }
  
  Future<void> _aceptarConHuella() async {
    setState(() => _isLoading = true);

    // 1. Pedimos huella y firmamos el texto exacto
    String mensaje = "Acepto unirme al grupo ${_group['id']}";
    String? firmaHex = await authCore.signPlainTextMessage(mensaje);

    if (firmaHex == null) {
      setState(() => _isLoading = false);
      UIHelper.showCustomSnackbar("Firma cancelada", isError: true);
      return;
    }

    // 2. Enviamos la firma matemática a Spring Boot
    String result = await groupService.acceptGroupInvite(
      _group['id'],
      firmaHex,
    );

    if (result == "SUCCESS") {
      UIHelper.showCustomSnackbar("¡Firma validada! Bienvenido al grupo.");
      await _actualizarGrupoLocal(); // En lugar de regresar, actualizamos la vista localmente
    } else {
      UIHelper.showCustomSnackbar(result, isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _rechazar() async {
    setState(() => _isLoading = true);
    String result = await groupService.rejectGroupInvite(_group['id']);

    if (result == "SUCCESS") {
      UIHelper.showCustomSnackbar( "Invitación rechazada",isError: true
      );
      Navigator.pop(context, true);
    } else {
      UIHelper.showCustomSnackbar("Error al rechazar", isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }



Future<void> _pagarMiParte(String requestId, double monto, String destino) async {
    // 1. Obtener balance actual
    String balanceStr = await txService.getBalance();
    double balance = double.tryParse(balanceStr) ?? 0.0;

    // Validación de fondos antes de siquiera preguntar
    if (monto > balance) {
      _mostrarUpsellGrupo(monto - balance);
      return;
    }

    // 2. Modal de Confirmación Intermedio
    // Usamos '?? false' para manejar el caso donde el usuario cierra el modal tocando fuera
    bool confirm = await UIHelper.mostrarConfirmacion(
      context: context,
      titulo: "Confirmar Pago",
      mensaje: "Tienes $balanceStr TTC en tu billetera.\nVas a pagar tu parte de $monto TTC.\nTe quedarán ${(balance - monto).toStringAsFixed(2)} TTC.\n\n¿Deseas proceder?",
      textoConfirmar: "Pagar mi parte",
      colorConfirmar: Colors.green,
    ) ?? false;
    
    // Si el usuario canceló o cerró el modal, salimos sin error
    if (!confirm) return;

    // 3. Bloqueo de pantalla con Skeleton y Huella
    // 🔥 IMPORTANTE: Quitamos el 'const' de TransactionSkeleton
    // showDialog(
    //   context: context, 
    //   barrierDismissible: false, 
    //   builder: (_) => TransactionSkeleton(
    //     title: "Esperando Firma", 
    //     message: "Autoriza el pago de tu parte con tu huella."
    //   )
    // );
    
    // bool auth = await authCore.authenticateUser();
    
    // if (!mounted) return;
    // Navigator.pop(context); // Quitamos el skeleton de la huella

    // if (!auth) {
    //   UIHelper.showCustomSnackbar("Autenticación cancelada", isError: true);
    //   return;
    // }
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => TransactionSkeleton(
        title: "Esperando Firma", 
        message: "Autoriza el pago de tu parte con tu huella."
      )
    );
    
    BigInt amountWei = BigInt.from(monto * 1e18);
    String? signature = await authCore.generateDelegatedSignature("SEND", toAddress: destino, amountWei: amountWei);
    
    if (!mounted) return;
    Navigator.pop(context); // Quitamos el skeleton de la huella

    if (signature == null) {
      UIHelper.showCustomSnackbar("Autenticación o firma cancelada", isError: true);
      return;
    }

    // 4. Abrir Pantalla de Carga Realista (TransactionPendingScreen)
    // Pasamos el callback onUpdateBalance para que refresque la pantalla al terminar
    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
       recipientAddress: destino, 
       expectedTxType: "SEND", 
       isGroupPayment: true,
       customTitle: "Saldando Deuda", 
       customMessage: "Enviando tus TTC al contrato inteligente...",
       onUpdateBalance: () { 
         _cargarSaldoGrupo(); 
         _cargarCobros(); 
       }
    )));

    // 5. Ejecución del envío en la Blockchain
    try {
      String result = await txService.sendTokensL2(destino, monto, signature);

      if (result == "Exito") {
        // Notificamos al backend para que registre el pago en la base de datos
        await groupService.confirmGroupPaymentInBackend(requestId, "TX_CONFIRMED");
      } else {
        // Si falla la blockchain, debemos cerrar el TransactionPendingScreen manualmente
        if (mounted) Navigator.pop(context);
        UIHelper.showCustomSnackbar("Error en Blockchain: $result", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      UIHelper.showCustomSnackbar("Error inesperado: $e", isError: true);
    }
  }

  void _mostrarUpsellGrupo(double faltante) {
    final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Saldo Insuficiente"),
          ],
        ),
        content: Text("Te faltan ${faltante.toStringAsFixed(2)} TTC para saldar tu deuda en el grupo.\n\n¿Deseas recargar tu billetera?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            onPressed: () {
              Navigator.pop(ctx); // Cerramos alerta
              BuyModal.show(
                context: context, 
                //balanceTTC: "0", 
                onUpdateBalance: () {}, 
                mostrarMensaje: (msg, {bool esError = false}) {}
              );
            },
            child: const Text("Comprar TTC", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }



  Future<void> _cargarSaldoGrupo() async {
    // groupData es el mapa de tu grupo actual
    String groupWallet = widget.groupData['walletAddress'] ?? "";
    if (groupWallet.isNotEmpty) {

      
      double saldo = await groupService.getAnyWalletBalance(groupWallet);
      if (mounted) setState(() => _saldoGrupo = saldo);
    }
  }

  // Widget _BotonAccion({required IconData icono, required String texto, required VoidCallback onTap, required Color color}) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(12),
  //     child: Container(
  //       width: 75,
  //    padding: const EdgeInsets.symmetric(vertical: 8),
  //       decoration: BoxDecoration(
  //         color: color.withOpacity(0.15),
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(color: color.withOpacity(0.3)),
  //       ),
  //       child: Column(
  //         children: [
  //        Icon(icono, color: color, size: 20),
  //           const SizedBox(height: 8),
  //           Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _BotonAccion({required IconData icono, required String texto, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 12),
            Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfoRow(String label, String value, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: label == 'Wallet:' ? 'monospace' : null))),
        ],
      ),
    );
  }
  

// 🔥 EL NUEVO MODAL DE APORTE A LA AYUDA CORREGIDO
  void _mostrarOpcionesAporteAyuda(dynamic ayuda) {
    double meta = double.tryParse(ayuda['requestedAmount'].toString()) ?? 0;
    double recaudado = double.tryParse(ayuda['raisedAmount'].toString()) ?? 0;
    double restante = meta - recaudado;
    if (restante <= 0) return;

    final TextEditingController amountController = TextEditingController(text: restante.toString());
    double montoIngresado = restante;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 🔥 FIX 1: Cambiamos los nombres de los contextos (modalCtx y innerCtx) para no borrar el 'context' principal de la pantalla
      builder: (BuildContext modalCtx) {
        final theme = Theme.of(modalCtx);
        final colorScheme = theme.colorScheme;
        
        return StatefulBuilder(
          builder: (BuildContext innerCtx, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(innerCtx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Aportar a La Ayuda", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Faltan $restante TTC para completar la meta.", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "¿Cuánto deseas aportar? (TTC)",
                      prefixIcon: const Icon(Icons.monetization_on_rounded, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (val) => montoIngresado = double.tryParse(val) ?? 0.0,
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      // 🔥 OPCIÓN 1: PAGA CON SU PROPIO DINERO (Abre el SendModal)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
                          label: const Text("Mis TTC", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            if (montoIngresado <= 0 || montoIngresado > restante) {
                              UIHelper.showCustomSnackbar("Monto inválido. Máximo $restante TTC", isError: true);
                              return;
                            }
                            
                            // 🔥 FIX 2: Cierra el modal inferior correctamente
                            Navigator.pop(modalCtx); 

                            await Future.delayed(const Duration(milliseconds: 100));

                            String miSaldo = await txService.getBalance();
                            if (!mounted) return;
                            
                            // 🔥 FIX 3: Pasamos el 'context' puro de la pantalla, no el destruido
                            SendModal.show(
                              context: context,  
                              balanceTTC: miSaldo, 
                              initialAddress: ayuda['creditorAddress'], // Va directo al que cobra
                              initialAmount: montoIngresado.toString(),
                              sharedDebtId: ayuda['id'], // Le inyectamos el ID de la ayuda
                              isGroupPayment: true,
                              onUpdateBalance: () { _cargarSaldoGrupo(); _cargarCobros(); }, 
                              mostrarMensaje: (msg, {bool esError = false}) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green));
                              }
                            );
                          }
                        )
                      ),
                      const SizedBox(width: 12),
                      
                      // 🔥 OPCIÓN 2: PIDE QUE PAGUE LA BÓVEDA DEL GRUPO (Votación o Pago Directo)
                     Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          icon: const Icon(Icons.diversity_3_rounded),
                          label: const Text("Usar Bóveda", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            if (montoIngresado <= 0 || montoIngresado > restante) {
                              UIHelper.showCustomSnackbar("Monto inválido.", isError: true);
                              return;
                            }
                            
                            // 🔥 Solo el creador puede usar la bóveda
                            if (_miEstado != "CREATOR") {
                              UIHelper.showCustomSnackbar("Solo el administrador puede autorizar fondos de la bóveda.", isError: true);
                              return;
                            }

                            Navigator.pop(modalCtx); // Cierra el modal de opciones actual
                            
                            // 🔥 Abrimos la "Navaja Suiza" configurada para pago obligatorio
                            RequestGroupPaymentModal.show(
                              context: context, 
                              groupId: _group['id'], 
                              isCreator: true, // Ya validamos que lo es
                              saldoGrupo: _saldoGrupo,
                              customTitle: "Pagar Ayuda con Bóveda",
                              initialDesc: "Aporte: ${ayuda['reason']}",
                              initialDest: ayuda['creditorAddress'],
                              
                              initialAmount: montoIngresado.toString(),
                              lockDest: true,   // 🔒 Bloquea el destino y el QR
                              forceVault: true, // 🔒 Fuerza a que el switch de bóveda esté encendido
                              sharedDebtId: ayuda['id'],
                              onSuccess: () {
                                _cargarCobros();
                                _cargarSaldoGrupo();
                              }
                            );
                          }
                        )
                      ),
                    ]
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  // 🔥 WIDGET DE FILTROS (CHIPS M3)
  Widget _buildFiltros(List<String> opciones, String seleccionado, Function(String) onSelect) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: opciones.map((opcion) {
          bool isSelected = seleccionado == opcion;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opcion, style: TextStyle(
                color: isSelected ? theme.cardColor : colorScheme.onSurface.withOpacity(0.7), 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.onSurface.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none), // 🔥 M3 Chip
              showCheckmark: false,
              onSelected: (bool selected) {
                if (selected) onSelect(opcion);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupTransactionCard(dynamic tx, Color onSurfaceColor, BuildContext context, String vaultAddress) {
    final colorScheme = Theme.of(context).colorScheme;
    
    bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
    final double amount = tx['amount'] != null ? (tx['amount'] as num).toDouble() : 0.0;
    final String status = (tx['status'] ?? 'Unknown').toString().toUpperCase();
    final bool isFailed = status == 'FAILED' || status == 'REVERTED' || status == 'REJECTED';

    String title = esIngreso ? "Aporte Recibido" : "Pago Enviado";
    IconData icon = esIngreso ? Icons.call_received_rounded : Icons.arrow_outward_rounded;
    Color iconColor = const Color(0xFFB5C0FF);
    Color iconBgColor = const Color(0xFF5A49D3).withOpacity(0.3);
    Color amountColor = esIngreso ? const Color(0xFFB5C0FF) : Colors.white;
    String prefix = esIngreso ? "+" : "-";

    if (isFailed) {
      iconColor = colorScheme.error;
      iconBgColor = colorScheme.error.withOpacity(0.15);
      amountColor = colorScheme.error;
      prefix = "x";
    }

    String timeStr = "--:--";
    if (tx['timestamp'] != null) {
      try {
        DateTime d = DateTime.parse(tx['timestamp'].toString());
        timeStr = "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isFailed ? Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () => TransactionGroupDetailsModal.show(context: context, tx: tx, vaultAddress: vaultAddress),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text("• ${isFailed ? 'Fallida' : 'Completada'} • $timeStr", style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(
                "$prefix ${amount.toStringAsFixed(2)} TTC",
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5, decoration: isFailed ? TextDecoration.lineThrough : null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 LÓGICA DE TRANSFORMACIÓN DEL BOTÓN
// Widget? _construirFABGrupo() {
//     // Pestaña 0: Miembros
//     if (_tabController.index == 0) {
//       return FloatingActionButton.extended(
//         key: const ValueKey('fab_invitar'),
//         heroTag: 'fab_principal',
//         backgroundColor: const Color(0xFFBAC3FF), // Color M3 del mockup
//         foregroundColor: const Color(0xFF00218d),
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         onPressed: () async {
//           final groupService = Provider.of<GroupSocialService>(context, listen: false);
//           await groupService.openContactSearchModal(
//             context, _group['id'], _actualizarGrupoLocal, (bool loading) {
//               if (mounted) setState(() => _isLoading = loading);
//             }
//           );
//         },
//         icon: const Icon(Icons.person_add_alt_1_rounded),
//         label: const Text("Invitar miembro", style: TextStyle(fontWeight: FontWeight.bold)),
//       );
//     }
//     // Pestaña 2: Cobros
//     else if (_tabController.index == 2) {
//       return FloatingActionButton.extended(
//         key: const ValueKey('fab_cobro'),
//         heroTag: 'fab_principal',
//         backgroundColor: const Color(0xFFBAC3FF),
//         foregroundColor: const Color(0xFF00218d),
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         onPressed: () {
//           RequestGroupPaymentModal.show(context: context, groupId: _group['id'], isCreator: true, saldoGrupo: _saldoGrupo, onSuccess: () => _cargarCobros());
//         },
//         icon: const Icon(Icons.request_quote_rounded),
//         label: const Text("Nuevo Pago / Cobro", style: TextStyle(fontWeight: FontWeight.bold)),
//       );
//     }
//     return null; 
//   }

Widget? _construirFABGrupo() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        heroTag: 'fab_principal',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final groupService = Provider.of<GroupSocialService>(context, listen: false);
          await groupService.openContactSearchModal(
            context, _group['id'], _actualizarGrupoLocal, (bool loading) {
              if (mounted) setState(() => _isLoading = loading);
            }
          );
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Invitar miembro", style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        heroTag: 'fab_principal',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          RequestGroupPaymentModal.show(
            context: context, groupId: _group['id'], isCreator: true, saldoGrupo: _saldoGrupo, onSuccess: () => _cargarCobros()
          );
        },
        icon: const Icon(Icons.request_quote_rounded),
        label: const Text("Nuevo Pago / Cobro", style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return null; 
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final cardColor = theme.cardColor;
    List<dynamic> members = _group['members'] ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_group['name'], style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_rounded, color: Color(0xFFC77DFF)),
            tooltip: "Abrir Sala de Chat",
            onPressed: () {
              int totalMembers = (_group['members'] as List?)?.length ?? 1;
              Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: _group['id'], groupName: _group['name'], totalMembers: totalMembers + 1)));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsGroupScreen(group: _group, isAdmin: _miEstado == "CREATOR"))),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    SmartAvatar(address: _group['walletAddress'] ?? "", size: 24),
                    const SizedBox(width: 8),
                    Icon(Icons.settings_outlined, size: 20, color: onSurface.withOpacity(0.8)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _miEstado == "CREATOR" ? _construirFABGrupo() : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // ==============================================
                // PANTALLA DE INVITACIÓN
                // ==============================================
                if (_miEstado == "PENDING") ...[
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: onSurface.withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.group_add_rounded, size: 40, color: onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 24),
                        Text("Invitación a Grupo", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(
                          "@${_group['creatorAlias']} te ha invitado a unirte a este fondo común para dividir gastos.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            onPressed: _aceptarConHuella,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: onSurface.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            onPressed: _rechazar,
                            child: Text("Rechazar", style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                // ==============================================
                // DASHBOARD DEL GRUPO
                // ==============================================
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_rounded, size: 14, color: onSurface.withOpacity(0.6)),
                              const SizedBox(width: 8),
                           FutureBuilder<Map<String, dynamic>?>(
                                future: Provider.of<UserService>(context, listen: false).getUserByWallet(_group['creatorAddress'] ?? ""),
                                builder: (context, snapshot) {
                                  String adminAlias = _group['creatorAlias'] ?? "Desconocido";
                                  if (snapshot.hasData && snapshot.data != null) {
                                    adminAlias = snapshot.data!['alias'] ?? adminAlias;
                                  }
                                  return Text("Administrador: @$adminAlias", style: TextStyle(color: onSurface.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 12));
                                }
                              ),
                            ]
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text("Bóveda: ${_saldoGrupo.toStringAsFixed(2)} TTC", style: TextStyle(color: onSurface, fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BotonAccion(
                              icono: Icons.account_balance_wallet_outlined, texto: "Aportar", color: colorScheme.primary,
                              onTap: () async {
                                String groupWallet = widget.groupData['walletAddress'] ?? "";
                                if (groupWallet.isEmpty) return;
                                String miSaldoReal = await txService.getBalance();
                                if (!context.mounted) return;
                                SendModal.show(context: context, balanceTTC: miSaldoReal, initialAddress: groupWallet, isGroupPayment: true, onUpdateBalance: _cargarSaldoGrupo, mostrarMensaje: (msg, {bool esError = false}) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? colorScheme.error : colorScheme.primary));
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            _BotonAccion(
                              icono: Icons.auto_graph_rounded, texto: "Minar PoS", color: colorScheme.secondary,
                              onTap: () async {
                                String groupWallet = widget.groupData['walletAddress'] ?? "";
                                if (groupWallet.isEmpty) return;
                                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                String stakedBalance = await vaultService.getAnyStakedBalance(groupWallet);
                                if (mounted) Navigator.pop(context);
                                
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => StakeScreen(
                                      balanceTTC: _saldoGrupo.toString(), stakedTTC: stakedBalance, isGroupMode: true, groupId: _group['id'], vaultAddress: groupWallet,
                                      onUpdateBalance: () async { await _cargarSaldoGrupo(); _cargarCobros(); },
                                      mostrarMensaje: (msg, {bool esError = false}) { UIHelper.showCustomSnackbar(msg, isError: esError); },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: colorScheme.primary,
                          indicatorWeight: 3,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: onSurface.withOpacity(0.5),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          tabs: const [
                            Tab(icon: Icon(Icons.people_alt_rounded), text: "Miembros"),
                            Tab(icon: Icon(Icons.how_to_vote_rounded), text: "Propuestas"),
                            Tab(icon: Icon(Icons.receipt_long_rounded), text: "Cobros"),
                            Tab(icon: Icon(Icons.savings_rounded), text: "Ayudas"),
                            Tab(icon: Icon(Icons.history_rounded), text: "Historial"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              GroupMembersTab(
                                group: _group,
                                miEstado: _miEstado,
                                searchQuery: _searchQuery,
                                onSearchChanged: (val) => setState(() => _searchQuery = val),
                                onActualizarGrupo: _actualizarGrupoLocal,
                              ),
                              GroupProposalsTab(
                                paymentsFuture: _paymentsFuture,
                                onRecargar: _cargarCobros,
                              ),
                              GroupPaymentsTab(
                                paymentsFuture: _paymentsFuture,
                                group: _group,
                                filtroTipoCobro: _filtroTipoCobro,
                                filtroCobros: _filtroCobros,
                                onFiltroTipoChanged: (val) => setState(() => _filtroTipoCobro = val),
                                onFiltroCobroChanged: (val) => setState(() => _filtroCobros = val),
                                onRecargar: () { _cargarSaldoGrupo(); _cargarCobros(); },
                              ),
                              GroupHelpsTab(
                                ayudaFuture: _ayudaFuture,
                                group: _group,
                                miEstado: _miEstado,
                                saldoGrupo: _saldoGrupo,
                                filtroAyudas: _filtroAyudas,
                                onFiltroAyudasChanged: (val) => setState(() => _filtroAyudas = val),
                                onRecargar: () { _cargarSaldoGrupo(); _cargarCobros(); },
                              ),
                              GroupHistoryTab(
                                historialFuture: _historialFuture,
                                group: _group,
                                filtroHistorial: _filtroHistorial,
                                fechaInicio: _fechaInicioHistorial,
                                fechaFin: _fechaFinHistorial,
                                onSeleccionarRango: _seleccionarRangoFechasHistorial,
                                onLimpiarRango: _limpiarFiltroFechasHistorial,
                                onFiltroChanged: (val) => setState(() => _filtroHistorial = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     _BotonAccion(
                        //       icono: Icons.account_balance_wallet_outlined, texto: "Aportar", color: const Color(0xFFC77DFF),
                        //       onTap: () async {
                        //         String groupWallet = widget.groupData['walletAddress'] ?? "";
                        //         if (groupWallet.isEmpty) return;
                        //         String miSaldoReal = await txService.getBalance();
                        //         if (!context.mounted) return;
                        //         SendModal.show(context: context, balanceTTC: miSaldoReal, initialAddress: groupWallet, isGroupPayment: true, onUpdateBalance: _cargarSaldoGrupo, mostrarMensaje: (msg, {bool esError = false}) {
                        //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? colorScheme.error : Colors.green));
                        //         });
                        //       },
                        //     ),
                        //     const SizedBox(width: 16),
                        //    _BotonAccion(
                        //       icono: Icons.auto_graph_rounded, 
                        //       texto: "Minar PoS", 
                        //       color: const Color(0xFF10B981),
                        //       onTap: () async {
                        //         String groupWallet = widget.groupData['walletAddress'] ?? "";
                        //         if (groupWallet.isEmpty) return;

                        //         showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                        //         String stakedBalance = await vaultService.getAnyStakedBalance(groupWallet);
                        //         if (mounted) Navigator.pop(context);
                                
                        //         // Navegamos directamente a la pantalla completa de Stake
                        //         Navigator.push(
                        //           context, 
                        //           MaterialPageRoute(
                        //             builder: (_) => StakeScreen(
                        //               balanceTTC: _saldoGrupo.toString(),
                        //               stakedTTC: stakedBalance,
                        //               isGroupMode: true,
                        //               groupId: _group['id'],
                        //               vaultAddress: groupWallet,
                        //               onUpdateBalance: () async { 
                        //                 await _cargarSaldoGrupo(); 
                        //                 _cargarCobros(); 
                        //               },
                        //               mostrarMensaje: (msg, {bool esError = false}) { 
                        //                 UIHelper.showCustomSnackbar(msg, isError: esError); 
                        //               },
                        //             ),
                        //           ),
                        //         );
                        //       },
                        //     ),
                        //   ],
                        // ),
                  //     ],
                  //   ),
                  // ),
                  // Expanded(
                  //   child: Column(
                  //     children: [
                  //       TabBar(
                  //         controller: _tabController,
                  //         isScrollable: true,
                  //         indicatorColor: const Color(0xFF4361EE),
                  //         indicatorWeight: 3,
                  //         labelColor: const Color(0xFF4361EE),
                  //         unselectedLabelColor: onSurface.withOpacity(0.5),
                  //         labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  //         tabs: const [
                  //           Tab(icon: Icon(Icons.people_alt_rounded), text: "Miembros"),
                  //           Tab(icon: Icon(Icons.how_to_vote_rounded), text: "Propuestas"),
                  //           Tab(icon: Icon(Icons.receipt_long_rounded), text: "Cobros"),
                  //           Tab(icon: Icon(Icons.savings_rounded), text: "Ayudas"),
                  //           Tab(icon: Icon(Icons.history_rounded), text: "Historial"),
                  //         ],
                  //       ),
                  //       Expanded(
                  //         child: TabBarView(
                  //           controller: _tabController,
                  //           children: [
                  //             // ==============================================
                  //             // TAB 1: MIEMBROS (IMAGEN: dashboard grupos)
                  //             // ==============================================
                  //             Column(
                  //               children: [
                  //                 Padding(
                  //                   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  //                   child: TextField(
                  //                     controller: _searchController,
                  //                     style: TextStyle(color: onSurface),
                  //                     decoration: InputDecoration(
                  //                       hintText: "Buscar alias o wallet...",
                  //                       hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                  //                       prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                  //                       filled: true,
                  //                       fillColor: cardColor,
                  //                       contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  //                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  //                     ),
                  //                     onChanged: (val) => setState(() => _searchQuery = val),
                  //                   ),
                  //                 ),
                  //                 Expanded(
                  //                   child: Builder(
                  //                     builder: (context) {
                  //                       final filteredMembers = members.where((m) {
                  //                         final alias = m['alias'].toString().toLowerCase();
                  //                         final wallet = m['walletAddress'].toString().toLowerCase();
                  //                         final query = _searchQuery.toLowerCase();
                  //                         return alias.contains(query) || wallet.contains(query);
                  //                       }).toList();

                  //                       if (filteredMembers.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.group_off_rounded, title: "Sin resultados", message: "No se encontraron miembros.");
                  //                       return ListView.builder(
                  //                         padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  //                         itemCount: filteredMembers.length,
                  //                         itemBuilder: (ctx, i) {
                  //                           var m = filteredMembers[i];
                  //                           bool isPending = m['status'] == "PENDING";
                  //                           final userService = Provider.of<UserService>(context, listen: false);

                  //                           return FutureBuilder<Map<String, dynamic>?>(
                  //                             future: userService.getUserByWallet(m['walletAddress']),
                  //                             builder: (context, snapshot) {
                  //                               String cedulaReal = "No registrada";
                  //                               String celularReal = "No registrado";
                  //                               String aliasReal = m['alias'] ?? "Desconocido";

                  //                               if (snapshot.hasData && snapshot.data != null) {
                  //                                 cedulaReal = snapshot.data!['cedula'] ?? "No registrada";
                  //                                 celularReal = snapshot.data!['phoneNumber'] ?? "No registrado";
                  //                                 aliasReal = snapshot.data!['alias'] ?? aliasReal;
                  //                               }

                  //                             return Container(
                  //                                 margin: const EdgeInsets.only(bottom: 12),
                  //                                 padding: const EdgeInsets.all(16),
                  //                                 decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                  //                                 child: Column(
                  //                                   children: [
                  //                                     Row(
                  //                                       children: [
                  //                                         SmartAvatar(address: m['walletAddress'] ?? '', size: 48),
                  //                                         const SizedBox(width: 12),
                  //                                         Expanded(
                  //                                           child: Column(
                  //                                             crossAxisAlignment: CrossAxisAlignment.start,
                  //                                             children: [
                  //                                               // 🔥 Aquí cargamos el Alias Real obtenido del backend
                  //                                               Text("@$aliasReal", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                  //                                               const SizedBox(height: 4),
                  //                                               Container(
                  //                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  //                                                 decoration: BoxDecoration(color: isPending ? Colors.orange.withOpacity(0.2) : const Color(0xFF4361EE).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  //                                                 child: Text(m['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.orange : const Color(0xFFBAC3FF))),
                  //                                               ),
                  //                                             ],
                  //                                           ),
                  //                                         ),
                  //                                         if (_miEstado == "CREATOR") ...[
                  //                                           Icon(Icons.settings_outlined, color: onSurface.withOpacity(0.5), size: 20),
                  //                                           const SizedBox(width: 12),
                  //                                           if (m['walletAddress'].toString().toLowerCase() != authCore.publicAddress.toLowerCase())
                  //                                             GestureDetector(
                  //                                               onTap: () async {
                  //                                                 setState(() => _isLoading = true);
                  //                                                 String res = await groupService.removeGroupMember(_group['id'], m['walletAddress']);
                  //                                                 if (res == "SUCCESS") { await _actualizarGrupoLocal(); setState(() => _isLoading = false); } else { UIHelper.showCustomSnackbar(res, isError: true); setState(() => _isLoading = false); }
                  //                                               },
                  //                                               child: Icon(Icons.person_remove_outlined, color: onSurface.withOpacity(0.5), size: 20),
                  //                                             ),
                  //                                         ]
                  //                                       ],
                  //                                     ),
                  //                                     const SizedBox(height: 16),
                  //                                     Divider(color: onSurface.withOpacity(0.05), height: 1),
                  //                                     const SizedBox(height: 12),
                  //                                     _buildMemberInfoRow("Cédula:", cedulaReal, onSurface),
                  //                                     _buildMemberInfoRow("Wallet:", "${m['walletAddress'].toString().substring(0,6)}...${m['walletAddress'].toString().substring(m['walletAddress'].toString().length-3)}", onSurface),
                  //                                     _buildMemberInfoRow("Celular:", celularReal, onSurface),
                  //                                   ],
                  //                                 ),
                  //                               );
                  //                             }
                  //                           );
                  //                         },
                  //                       );
                  //                     },
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),

                  //             // --- TAB 2: PROPUESTAS ---
                  //             FutureBuilder<List<dynamic>>(
                  //               future: _paymentsFuture,
                  //               builder: (context, snapshot) {
                  //                 if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  //                 List<dynamic> propuestas = (snapshot.data ?? []).where((r) => r['status'] == "PENDING_APPROVAL").toList();
                  //                 if (propuestas.isEmpty) return UIHelper.emptyState(context: context, icon: Icons.how_to_vote_rounded, title: "Sin Propuestas", message: "No hay votaciones pendientes en este momento en la DAO.");
                  //                 return ListView.builder(
                  //                   padding: const EdgeInsets.all(16),
                  //                   itemCount: propuestas.length,
                  //                   itemBuilder: (ctx, i) {
                  //                     var req = propuestas[i];
                  //                     List<dynamic> approvals = req['approvals'] ?? [];
                  //                     bool yaVote = approvals.contains(authCore.publicAddress.toLowerCase());
                  //                     return Card(
                  //                       margin: const EdgeInsets.only(bottom: 12),
                  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  //                       child: ListTile(
                  //                         leading: CircleAvatar(backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1), child: const Icon(Icons.how_to_vote_rounded, color: Colors.deepPurpleAccent)),
                  //                         title: Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  //                         subtitle: Text(req['requestType'] == 'CONFIG_CHANGE' ? "Ajuste de DAO" : "DeFi o Multisig", style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                  //                         trailing: !yaVote 
                  //                           ? ElevatedButton.icon(
                  //                               style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  //                               icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                  //                               label: const Text("Aprobar"),
                  //                               onPressed: () async {
                  //                                 bool auth = await authCore.authenticateUser();
                  //                                 if (!auth) return;
                  //                                 showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  //                                 String res = await groupService.approveMultisigPayment(req['id']);
                  //                                 if (mounted) Navigator.pop(context);
                  //                                 if (res == "SUCCESS") { UIHelper.showCustomSnackbar("Voto registrado exitosamente", isError: false); _cargarCobros(); } else { UIHelper.showCustomSnackbar(res, isError: true); }
                  //                               },
                  //                             )
                  //                           : Chip(label: const Text("Aprobado", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1), labelStyle: const TextStyle(color: Colors.deepPurpleAccent), side: BorderSide.none),
                  //                       ),
                  //                     );
                  //                   },
                  //                 );
                  //               },
                  //             ),

                  //             // ==============================================
                  //             // TAB 3: COBROS 
                  //             // ==============================================
                  //             FutureBuilder<List<dynamic>>(
                  //               future: _paymentsFuture,
                  //               builder: (context, snapshot) {
                  //                 if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  //                 List<dynamic> cobros = (snapshot.data ?? []).where((r) => r['status'] != "PENDING_APPROVAL").toList();
                  //                 List<dynamic> cobrosFiltrados = cobros.where((req) {
                  //                   String status = (req['status'] ?? '').toString().toUpperCase();
                  //                   bool pasaEstado = true;
                  //                   if (_filtroCobros == 'Pendientes') pasaEstado = status == 'OPEN' || status == 'PENDING_APPROVAL';
                  //                   else if (_filtroCobros == 'Completadas') pasaEstado = status == 'COMPLETED'; // Ajuste 'Completadas' para coincidir con la imagen
                  //                   else if (_filtroCobros == 'Fallidas') pasaEstado = status == 'FAILED' || status == 'REJECTED';
                  //                   if (!pasaEstado) return false;

                  //                   bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
                  //                   if (_filtroTipoCobro == 'Divididos' && isVaultPayment) return false;
                  //                   if (_filtroTipoCobro == 'Bóveda' && !isVaultPayment) return false;
                  //                   return true;
                  //                 }).toList();

                  //                 return Column(
                  //                   children: [
                  //                     SingleChildScrollView(
                  //                       scrollDirection: Axis.horizontal,
                  //                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //                       child: Row(
                  //                         children: [
                  //                           PopupMenuButton<String>(
                  //                             initialValue: _filtroTipoCobro,
                  //                             color: cardColor,
                  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  //                             onSelected: (String newValue) => setState(() => _filtroTipoCobro = newValue),
                  //                             itemBuilder: (BuildContext context) => const [
                  //                               PopupMenuItem<String>(value: 'Todos', child: Text('Todos los tipos')),
                  //                               PopupMenuItem<String>(value: 'Divididos', child: Text('Pagos Divididos')),
                  //                               PopupMenuItem<String>(value: 'Bóveda', child: Text('Pagos de Bóveda')),
                  //                             ],
                  //                             child: Container(
                  //                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //                               decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.1))),
                  //                               child: Row(
                  //                                 mainAxisSize: MainAxisSize.min,
                  //                                 children: [
                  //                                   Icon(Icons.filter_list_rounded, size: 16, color: onSurface.withOpacity(0.7)),
                  //                                   const SizedBox(width: 6),
                  //                                   Text("Tipo", style: TextStyle(color: onSurface.withOpacity(0.8))),
                  //                                   const SizedBox(width: 4),
                  //                                   Icon(Icons.arrow_drop_down_rounded, size: 16, color: onSurface.withOpacity(0.7)),
                  //                                 ],
                  //                               ),
                  //                             ),
                  //                           ),
                  //                           const SizedBox(width: 8),
                  //                           ...['Todos', 'Pendientes', 'Completadas', 'Fallidas'].map((opcion) {
                  //                             bool isSelected = _filtroCobros == opcion;
                  //                             return Padding(
                  //                               padding: const EdgeInsets.only(right: 8),
                  //                               child: GestureDetector(
                  //                                 onTap: () => setState(() => _filtroCobros = opcion),
                  //                                 child: Container(
                  //                                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //                                   decoration: BoxDecoration(
                  //                                     color: isSelected ? const Color(0xFFBAC3FF) : Colors.transparent,
                  //                                     borderRadius: BorderRadius.circular(20),
                  //                                     border: Border.all(color: isSelected ? Colors.transparent : onSurface.withOpacity(0.2))
                  //                                   ),
                  //                                   child: Text(opcion, style: TextStyle(color: isSelected ? const Color(0xFF00218d) : onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  //                                 ),
                  //                               ),
                  //                             );
                  //                           }).toList(),
                  //                         ],
                  //                       ),
                  //                     ),

                  //                     Expanded(
                  //                       child: cobrosFiltrados.isEmpty 
                  //                         ? SingleChildScrollView(
                  //                               physics: const BouncingScrollPhysics(),
                  //                               child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UIHelper.emptyState(context: context, icon: Icons.receipt_long_rounded, title: "Sin Cobros", message: "No hay cobros o pagos grupales que coincidan con este filtro.")),
                  //                             )
                  //                           : ListView.builder(
                  //                         padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                  //                         itemCount: cobrosFiltrados.length,
                  //                         itemBuilder: (ctx, i) {
                  //                           var req = cobrosFiltrados[i];
                  //                           bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
                  //                           var miDeuda = (req['debts'] as List?)?.firstWhere((d) => d['walletAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase(), orElse: () => null);
                                            
                  //                           if (!isVaultPayment && miDeuda == null) return const SizedBox(); 

                  //                           bool pendiente = miDeuda != null && miDeuda['status'] == "PENDING";
                  //                           bool completado = req['status'] == "COMPLETED";
                  //                           bool fallida = req['status'] == "FAILED" || req['status'] == "REJECTED";

                  //                           Color statusColor = completado ? Colors.green : (fallida ? colorScheme.error : const Color(0xFFC77DFF));
                  //                           IconData statusIcon = completado ? Icons.check_rounded : (fallida ? Icons.priority_high_rounded : Icons.schedule_rounded);
                  //                           String montoStr = isVaultPayment ? req['totalAmount'].toString() : miDeuda!['amountOwed'].toString();

                  //                           return Card(
                  //                             margin: const EdgeInsets.only(bottom: 12),
                  //                             color: cardColor,
                  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: statusColor.withOpacity(0.2))),
                  //                             child: InkWell(
                  //                               onTap: () => GroupPaymentDetailsModal.show(context: context, req: req, groupName: _group['name']),
                  //                               borderRadius: BorderRadius.circular(16),
                  //                               child: Padding(
                  //                                 padding: const EdgeInsets.all(16),
                  //                                 child: Row(
                  //                                   children: [
                  //                                     Container(
                  //                                       padding: const EdgeInsets.all(8),
                  //                                       decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                  //                                       child: Icon(statusIcon, color: statusColor, size: 20),
                  //                                     ),
                  //                                     const SizedBox(width: 16),
                  //                                     Expanded(
                  //                                       child: Column(
                  //                                         crossAxisAlignment: CrossAxisAlignment.start,
                  //                                         children: [
                  //                                           Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  //                                           const SizedBox(height: 4),
                  //                                           Row(
                  //                                             children: [
                  //                                               Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  //                                               const SizedBox(width: 6),
                  //                                               Text(completado ? "Completada" : (fallida ? "Fallida" : "Pendiente"), style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
                  //                                               Text(" • 12:00", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13)), // placeholder
                  //                                             ],
                  //                                           )
                  //                                         ],
                  //                                       ),
                  //                                     ),
                  //                                     Column(
                  //                                       crossAxisAlignment: CrossAxisAlignment.end,
                  //                                       children: [
                  //                                         Text(completado ? "+ $montoStr TTC" : "$montoStr TTC", style: TextStyle(color: completado ? Colors.green : onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                  //                                         if (pendiente && !fallida) ...[
                  //                                           const SizedBox(height: 8),
                  //                                           ElevatedButton(
                  //                                             style: ElevatedButton.styleFrom(
                  //                                               backgroundColor: Colors.green, foregroundColor: Colors.white,
                  //                                               minimumSize: const Size(60, 30),
                  //                                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  //                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  //                                             ),
                  //                                             onPressed: () => _pagarMiParte(req['id'], double.parse(miDeuda!['amountOwed'].toString()), req['destinationAddress']),
                  //                                             child: const Text("Pagar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  //                                           )
                  //                                         ]
                  //                                       ],
                  //                                     )
                  //                                   ],
                  //                                 )
                  //                               )
                  //                             )
                  //                           );
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ],
                  //                 );
                  //               },
                  //             ),

                  //             // --- TAB 4: LA AYUDA ---
                  //         FutureBuilder<List<dynamic>>(
                  //               future: _ayudaFuture,
                  //               builder: (context, snapshot) {
                  //                 if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  //                 if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No hay nadie pidiendo ayuda.", style: TextStyle(color: onSurface.withOpacity(0.5))));
                                  
                  //                 // LÓGICA DE FILTRADO COMPLETA
                  //                 List<dynamic> ayudasFiltradas = snapshot.data!.where((ayuda) {
                  //                   String status = (ayuda['status'] ?? '').toString().toUpperCase();
                  //                   if (_filtroAyudas == 'Todos') return true;
                  //                   if (_filtroAyudas == 'Pendientes de aprobar') return status == 'PENDING_VOTE';
                  //                   if (_filtroAyudas == 'Aprobados') return status == 'APPROVED';
                  //                   if (_filtroAyudas == 'Pendientes') return status == 'FUNDING';
                  //                   if (_filtroAyudas == 'Completados') return status == 'COMPLETED';
                  //                   if (_filtroAyudas == 'Fallidos') return status == 'FAILED' || status == 'REJECTED';
                  //                   return true;
                  //                 }).toList();

                  //                 return Column(
                  //                   children: [
                  //                     // 1. FILTROS ESTILO MOCKUP CON TODAS LAS OPCIONES
                  //                     SingleChildScrollView(
                  //                       scrollDirection: Axis.horizontal,
                  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  //                       child: Row(
                  //                         children: ['Todos', 'Pendientes de aprobar', 'Aprobados', 'Pendientes', 'Completados', 'Fallidos'].map((opcion) {
                  //                           bool isSelected = _filtroAyudas == opcion;
                  //                           return Padding(
                  //                             padding: const EdgeInsets.only(right: 8),
                  //                             child: GestureDetector(
                  //                               onTap: () => setState(() => _filtroAyudas = opcion),
                  //                               child: Container(
                  //                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //                                 decoration: BoxDecoration(
                  //                                   color: isSelected ? const Color(0xFFBAC3FF) : Colors.transparent,
                  //                                   borderRadius: BorderRadius.circular(24),
                  //                                   border: Border.all(color: isSelected ? Colors.transparent : onSurface.withOpacity(0.1)),
                  //                                 ),
                  //                                 child: Text(
                  //                                   opcion, 
                  //                                   style: TextStyle(
                  //                                     color: isSelected ? const Color(0xFF00218d) : onSurface.withOpacity(0.8), 
                  //                                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                  //                                     fontSize: 13
                  //                                   )
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                           );
                  //                         }).toList(),
                  //                       ),
                  //                     ),

                  //                     // 2. LISTA DE AYUDAS REDISEÑADA
                  //                     Expanded(
                  //                       child: ayudasFiltradas.isEmpty 
                  //                           ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UIHelper.emptyState(context: context, icon: Icons.volunteer_activism_rounded, title: "Sin Ayudas", message: "No hay solicitudes de ayuda con este estado.")))
                  //                           : ListView.builder(
                  //                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //                               physics: const BouncingScrollPhysics(),
                  //                               itemCount: ayudasFiltradas.length,
                  //                               itemBuilder: (ctx, i) {
                  //                                 var ayuda = ayudasFiltradas[i];
                  //                                 double meta = double.tryParse(ayuda['requestedAmount'].toString()) ?? 0;
                  //                                 double recaudado = double.tryParse(ayuda['raisedAmount'].toString()) ?? 0;
                  //                                 double progreso = meta > 0 ? (recaudado / meta) : 0;
                                                  
                  //                                 bool isPendingVote = ayuda['status'] == "PENDING_VOTE";
                  //                                 bool isFunding = ayuda['status'] == "FUNDING";
                  //                                 bool isCompleted = ayuda['status'] == "COMPLETED";
                                                  
                  //                                 List<dynamic> votos = ayuda['groupApprovals'] ?? [];
                  //                                 bool yaVote = votos.contains(authCore.publicAddress.toLowerCase());

                  //                                 // Variables visuales dinámicas
                  //                                 String shortAddress = ayuda['debtorAddress'].toString();
                  //                                 shortAddress = shortAddress.length > 10 ? "${shortAddress.substring(0,8)}...${shortAddress.substring(shortAddress.length-4)}" : shortAddress;
                                                  
                  //                                 Color statusColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFBAC3FF);
                  //                                 String statusText = isCompleted ? "COMPLETADO" : (isPendingVote ? "VOTACIÓN" : "PENDIENTE");
                  //                                 Color progressColor = isCompleted ? Colors.orangeAccent : const Color(0xFFBAC3FF);

                  //                                 return Container(
                  //                                   margin: const EdgeInsets.only(bottom: 16),
                  //                                   decoration: BoxDecoration(
                  //                                     color: theme.cardColor,
                  //                                     borderRadius: BorderRadius.circular(16),
                  //                                     border: Border.all(color: onSurface.withOpacity(0.08)),
                  //                                   ),
                  //                                   child: InkWell(
                  //                                     borderRadius: BorderRadius.circular(16),
                  //                                     onTap: isFunding ? () => _mostrarOpcionesAporteAyuda(ayuda) : null,
                  //                                     child: Padding(
                  //                                       padding: const EdgeInsets.all(20),
                  //                                       child: Column(
                  //                                         crossAxisAlignment: CrossAxisAlignment.start,
                  //                                         children: [
                  //                                           // CABECERA (Icono, Título y Badge)
                  //                                           Row(
                  //                                             crossAxisAlignment: CrossAxisAlignment.start,
                  //                                             children: [
                  //                                               Container(
                  //                                                 padding: const EdgeInsets.all(12),
                  //                                                 decoration: BoxDecoration(
                  //                                                   color: onSurface.withOpacity(0.05),
                  //                                                   borderRadius: BorderRadius.circular(12),
                  //                                                   border: Border.all(color: const Color(0xFFBAC3FF).withOpacity(0.3))
                  //                                                 ),
                  //                                                 child: const Icon(Icons.campaign_rounded, color: Colors.orangeAccent, size: 24),
                  //                                               ),
                  //                                               const SizedBox(width: 12),
                  //                                               Expanded(
                  //                                                 child: Column(
                  //                                                   crossAxisAlignment: CrossAxisAlignment.start,
                  //                                                   children: [
                  //                                                     Text(ayuda['reason'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  //                                                     const SizedBox(height: 4),
                  //                                                     Text("Solicitado por $shortAddress", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                  //                                                   ],
                  //                                                 ),
                  //                                               ),
                  //                                               Container(
                  //                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //                                                 decoration: BoxDecoration(
                  //                                                   color: statusColor.withOpacity(0.1),
                  //                                                   borderRadius: BorderRadius.circular(8),
                  //                                                 ),
                  //                                                 child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  //                                               ),
                  //                                             ],
                  //                                           ),
                  //                                           const SizedBox(height: 20),

                  //                                           // BARRA DE PROGRESO
                  //                                           ClipRRect(
                  //                                             borderRadius: BorderRadius.circular(10),
                  //                                             child: LinearProgressIndicator(
                  //                                               value: progreso,
                  //                                               backgroundColor: onSurface.withOpacity(0.05),
                  //                                               color: progressColor,
                  //                                               minHeight: 6,
                  //                                             ),
                  //                                           ),
                  //                                           const SizedBox(height: 10),

                  //                                           // MONTOS
                  //                                           Row(
                  //                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //                                             children: [
                  //                                               Text("${recaudado.toStringAsFixed(1)} TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface)),
                  //                                               Text("Meta: ${meta.toStringAsFixed(1)} TTC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onSurface.withOpacity(0.7))),
                  //                                             ],
                  //                                           ),

                  //                                           const SizedBox(height: 16),

                  //                                           // ÁREA DE ACCIÓN INFERIOR
                  //                                           if (isCompleted)
                  //                                             const Center(child: Text("¡Meta alcanzada! El grupo salvó el día.", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 13)))
                  //                                           else if (isFunding)
                  //                                             Align(
                  //                                               alignment: Alignment.centerRight,
                  //                                               child: Text(
                  //                                                 "Aportar ahora", 
                  //                                                 style: TextStyle(color: const Color(0xFFBAC3FF), fontWeight: FontWeight.bold, fontSize: 14)
                  //                                               ),
                  //                                             )
                  //                                           else if (isPendingVote)
                  //                                             SizedBox(
                  //                                               width: double.infinity,
                  //                                               child: ElevatedButton.icon(
                  //                                                 style: ElevatedButton.styleFrom(
                  //                                                   backgroundColor: yaVote ? onSurface.withOpacity(0.1) : const Color(0xFF4361EE),
                  //                                                   foregroundColor: yaVote ? onSurface.withOpacity(0.5) : Colors.white,
                  //                                                   elevation: 0,
                  //                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //                                                   padding: const EdgeInsets.symmetric(vertical: 12)
                  //                                                 ),
                  //                                                 onPressed: yaVote ? null : () async {
                  //                                                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu voto para ayudar."));
                  //                                                   bool auth = await authCore.authenticateUser();
                  //                                                   if (mounted) Navigator.pop(context);
                  //                                                   if (!auth) return;
                  //                                                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando Voto", message: "Registrando en la DAO..."));
                  //                                                   String res = await debtService.voteToHelpSharedDebt(ayuda['id']);
                  //                                                   if (mounted) Navigator.pop(context); 
                  //                                                   if (res == "Exito") { _cargarCobros(); } else { UIHelper.showCustomSnackbar("Error al votar: $res", isError: true); }
                  //                                                 },
                  //                                                 icon: const Icon(Icons.how_to_vote_rounded, size: 18), 
                  //                                                 label: Text(yaVote ? "Voto registrado" : "Aprobar ayuda", style: const TextStyle(fontWeight: FontWeight.bold)),
                  //                                               ),
                  //                                             )
                  //                                         ],
                  //                                       ),
                  //                                     ),
                  //                                   ),
                  //                                 );
                  //                               },
                  //                             ),
                  //                     ),
                  //                   ],
                  //                 );
                  //               },
                  //             ),
                  //             // --- TAB 5: HISTORIAL ---
                  //            FutureBuilder<List<dynamic>>(
                  //               future: _historialFuture,
                  //               builder: (context, snapshot) {
                  //                 if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  //                 if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("La bóveda no tiene movimientos.", style: TextStyle(color: onSurface.withOpacity(0.5))));
                                  
                  //                 String vaultAddress = _group['walletAddress']?.toString().toLowerCase() ?? "";
                                  
                  //                 List<dynamic> historialFiltrado = snapshot.data!.where((tx) {
                  //                   if (_fechaInicioHistorial != null && _fechaFinHistorial != null && tx['timestamp'] != null) {
                  //                     try {
                  //                       DateTime txDate = DateTime.parse(tx['timestamp'].toString());
                  //                       DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
                  //                       DateTime start = DateTime(_fechaInicioHistorial!.year, _fechaInicioHistorial!.month, _fechaInicioHistorial!.day);
                  //                       DateTime end = DateTime(_fechaFinHistorial!.year, _fechaFinHistorial!.month, _fechaFinHistorial!.day);
                  //                       if (justDate.isBefore(start) || justDate.isAfter(end)) return false;
                  //                     } catch (e) { return false; }
                  //                   }
                  //                   String tipo = (tx['txType'] ?? '').toString().toUpperCase();
                  //                   bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
                  //                   if (_filtroHistorial == 'Todos') return true;
                  //                   if (_filtroHistorial == 'Aportes') return esIngreso;
                  //                   if (_filtroHistorial == 'Pagos de ayudas') return tipo == 'SHARED_DEBT_PAYMENT';
                  //                   if (_filtroHistorial == 'Pagos') return !esIngreso && tipo != 'SHARED_DEBT_PAYMENT';
                  //                   return true;
                  //                 }).toList();
                                  
                  //                 Map<String, List<dynamic>> historialAgrupado = _groupTransactionsByDate(historialFiltrado);

                  //                 return Column(
                  //                   children: [
                  //                     Padding(
                  //                       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  //                       child: Row(
                  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //                         children: [
                  //                           Text("Movimientos (${snapshot.data!.length})", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.7))),
                  //                           Row(
                  //                             children: [
                  //                               Container(
                  //                                 margin: const EdgeInsets.only(right: 8),
                  //                                 decoration: BoxDecoration(color: Colors.deepOrangeAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  //                                 child: IconButton(
                  //                                   tooltip: "Exportar PDF",
                  //                                   icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.deepOrangeAccent, size: 20),
                  //                                   onPressed: () => ShareHelper.generarYCompartirPDFHistory(context, snapshot.data!, vaultAddress),
                  //                                 ),
                  //                               ),
                  //                               Container(
                  //                                 decoration: BoxDecoration(color: const Color(0xFFB5C0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  //                                 child: IconButton(
                  //                                   tooltip: "Exportar Excel",
                  //                                   icon: const Icon(Icons.download_rounded, color: Color(0xFFB5C0FF), size: 20),
                  //                                   onPressed: () => ShareHelper.exportarHistorialCSV(context, snapshot.data!, vaultAddress),
                  //                                 ),
                  //                               ),
                  //                             ],
                  //                           )
                  //                         ],
                  //                       ),
                  //                     ),
                                      
                  //                     SingleChildScrollView(
                  //                       scrollDirection: Axis.horizontal,
                  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  //                       child: Row(
                  //                         children: [
                  //                           GestureDetector(
                  //                             onTap: _seleccionarRangoFechasHistorial,
                  //                             child: Container(
                  //                               margin: const EdgeInsets.only(right: 12),
                  //                               padding: const EdgeInsets.all(10),
                  //                               decoration: BoxDecoration(
                  //                                 color: _fechaInicioHistorial != null ? const Color(0xFFB5C0FF) : colorScheme.onSurface.withOpacity(0.08),
                  //                                 borderRadius: BorderRadius.circular(12),
                  //                               ),
                  //                               child: Icon(Icons.calendar_today_rounded, size: 20, color: _fechaInicioHistorial != null ? Colors.black87 : colorScheme.onSurface.withOpacity(0.8)),
                  //                             ),
                  //                           ),
                  //                           if (_fechaInicioHistorial != null)
                  //                             GestureDetector(
                  //                               onTap: _limpiarFiltroFechasHistorial,
                  //                               child: Container(
                  //                                 margin: const EdgeInsets.only(right: 12),
                  //                                 padding: const EdgeInsets.all(10),
                  //                                 decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  //                                 child: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
                  //                               ),
                  //                             ),
                  //                           ...['Todos', 'Aportes', 'Pagos', 'Pagos de ayudas'].map((opcion) {
                  //                             bool isSelected = _filtroHistorial == opcion;
                  //                             return GestureDetector(
                  //                               onTap: () => setState(() => _filtroHistorial = opcion),
                  //                               child: Container(
                  //                                 margin: const EdgeInsets.only(right: 12),
                  //                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //                                 decoration: BoxDecoration(
                  //                                   color: isSelected ? const Color(0xFFB5C0FF) : colorScheme.onSurface.withOpacity(0.08),
                  //                                   borderRadius: BorderRadius.circular(12),
                  //                                 ),
                  //                                 child: Text(
                  //                                   opcion,
                  //                                   style: TextStyle(color: isSelected ? Colors.black87 : colorScheme.onSurface.withOpacity(0.8), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                  //                                 ),
                  //                               ),
                  //                             );
                  //                           }).toList(),
                  //                         ],
                  //                       ),
                  //                     ),
                                      
                  //                     Expanded(
                  //                       child: historialAgrupado.isEmpty
                  //                           ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UIHelper.emptyState(context: context, icon: Icons.history_rounded, title: "Historial Vacío", message: "La bóveda no registra transacciones bajo este filtro.")))
                  //                           : ListView.builder(
                  //                               padding: const EdgeInsets.all(16),
                  //                               itemCount: historialAgrupado.keys.length,
                  //                               itemBuilder: (context, index) {
                  //                                 String date = historialAgrupado.keys.elementAt(index);
                  //                                 List<dynamic> txs = historialAgrupado[date]!;
                  //                                 return Column(
                  //                                   crossAxisAlignment: CrossAxisAlignment.start,
                  //                                   children: [
                  //                                     Padding(
                  //                                       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), 
                  //                                       child: Text(date.toUpperCase(), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))
                  //                                     ),
                  //                                     ...txs.map((tx) => _buildGroupTransactionCard(tx, colorScheme.onSurface, context, vaultAddress)).toList(),
                  //                                   ],
                  //                                 );
                  //                               },
                  //                             ),
                  //                     ),
                  //                   ],
                  //                 );
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ],
            ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final onSurface = colorScheme.onSurface;
  //   final cardColor = theme.cardColor;
  //   List<dynamic> members = _group['members'] ?? [];

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor, // 🔥 REGLA DE SCAFFOLD
  //    appBar: AppBar(
  //       title: Text(_group['name'], style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       iconTheme: IconThemeData(color: onSurface),
  //       actions: [
  //         // 🔥 NUEVO: BOTÓN DE CHAT GRUPAL CON TESORERO IA
  //         IconButton(
  //           icon: const Icon(Icons.forum_rounded, color: Colors.deepPurpleAccent),
  //           tooltip: "Abrir Sala de Chat",
  //           onPressed: () {
  //             int totalMembers = (_group['members'] as List?)?.length ?? 1;
  //             Navigator.push(
  //               context, 
  //               MaterialPageRoute(
  //                 builder: (_) => GroupChatScreen(
  //                   groupId: _group['id'], 
  //                   groupName: _group['name'],
  //                   totalMembers: totalMembers + 1 // Contando al admin
  //                 )
  //               )
  //             );
  //           },
  //         ),
          
  //         // TU BOTÓN ORIGINAL DE AJUSTES INTACTO
  //         Padding(
  //           padding: const EdgeInsets.only(right: 12.0),
  //           child: InkWell(
  //             onTap: () => Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => SettingsGroupScreen(
  //                   group: _group,
  //                   isAdmin: _miEstado == "CREATOR",
  //                 ),
  //               ),
  //             ),
  //             borderRadius: BorderRadius.circular(30),
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: onSurface.withOpacity(0.05),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Row(
  //                 children: [
  //                   // El avatar único de la bóveda
  //                   SmartAvatar(
  //                     address: _group['walletAddress'] ?? "", 
  //                     size: 24
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Icon(Icons.settings_rounded, size: 20, color: onSurface.withOpacity(0.7)),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),

  //     floatingActionButton: _miEstado == "CREATOR" ? _construirFABGrupo() : null,

  //     body: _isLoading
  //         ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) // 🔥 M3 Primary
  //         : Column(
  //             children: [
  //               // --- PANTALLA DE INVITACIÓN (SI ESTÁ PENDIENTE) ---
  //               if (_miEstado == "PENDING") ...[
  //                 Container(
  //                   margin: const EdgeInsets.all(20),
  //                   padding: const EdgeInsets.all(24),
  //                   decoration: BoxDecoration(
  //                     color: cardColor,
  //                     borderRadius: BorderRadius.circular(24), // 🔥 Bordes M3
  //                     border: Border.all(color: colorScheme.primary.withOpacity(0.3)), // Sutil
  //                   ),
  //                   child: Column(
  //                     children: [
  //                       Container(
  //                         padding: const EdgeInsets.all(16),
  //                         decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
  //                         child: Icon(Icons.group_add_rounded, size: 50, color: colorScheme.primary),
  //                       ),
  //                       const SizedBox(height: 20),
  //                       Text("Invitación a Grupo", style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
  //                       const SizedBox(height: 10),
  //                       Text(
  //                         "@${_group['creatorAlias']} te ha invitado a unirte a este fondo común para dividir gastos.",
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 15),
  //                       ),
  //                       const SizedBox(height: 32),

  //                       Row(
  //                         children: [
  //                           Expanded(
  //                             child: OutlinedButton(
  //                               style: OutlinedButton.styleFrom(
  //                                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                                 side: BorderSide(color: colorScheme.error.withOpacity(0.5)), // 🔥 Error color
  //                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde botón
  //                               ),
  //                               onPressed: _rechazar,
  //                               child: Text("Rechazar", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 16),
  //                           Expanded(
  //                             child: ElevatedButton.icon(
  //                               style: ElevatedButton.styleFrom(
  //                                 backgroundColor: colorScheme.primary, // 🔥 Primary color
  //                                 foregroundColor: colorScheme.onPrimary,
  //                                 elevation: 0,
  //                                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                               ),
  //                               onPressed: _aceptarConHuella,
  //                               icon: const Icon(Icons.fingerprint_rounded),
  //                               label: const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold)),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ]
  //               // --- DASHBOARD DEL GRUPO (SI YA ES MIEMBRO O CREADOR) ---
  //               else ...[
  //                 Padding(
  //                 padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
  //                   child: Column(
  //                     children: [
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           CircleAvatar(
  //                       radius: 14,
  //                         backgroundColor: colorScheme.primary.withOpacity(0.1),
  //                         child: Icon(Icons.diversity_3_rounded, size: 14, color: colorScheme.primary),
  //                       ),
  //                       const SizedBox(width: 8),
  //                           // 🔥 Mostramos el alias real de la BD
  //                           Text("Administrador: @${_group['creatorAlias'] ?? 'Desconocido'}", style: TextStyle(color: onSurface.withOpacity(0.6), fontWeight: FontWeight.w500, fontSize: 13)),
  //                         ]
  //                       ),
                        
  //                       const SizedBox(height: 8),
  //                       Text("Bóveda: ${_saldoGrupo.toStringAsFixed(2)} TTC", style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
  //                       const SizedBox(height: 8),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                          _BotonAccion(
  //                             icono: Icons.account_balance_wallet_rounded,
  //                             texto: "Aportar",
  //                             color: colorScheme.secondary,
  //                             onTap: () async {
  //                               String groupWallet = widget.groupData['walletAddress'] ?? "";
  //                               if (groupWallet.isEmpty) return;
  //                               String miSaldoReal = await txService.getBalance();
  //                               if (!context.mounted) return;
  //                               SendModal.show(context: context, balanceTTC: miSaldoReal, initialAddress: groupWallet, isGroupPayment: true, onUpdateBalance: _cargarSaldoGrupo, mostrarMensaje: (msg, {bool esError = false}) {
  //                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? colorScheme.error : Colors.green));
  //                               });
  //                             },
  //                           ),
  //                           const SizedBox(width: 15),
  //                           _BotonAccion(
  //                             icono: Icons.auto_graph_rounded,
  //                             texto: "Minar PoS",
  //                             color: const Color(0xFF10B981), // Verde Éxito
  //                             onTap: () async {
  //                               String groupWallet = widget.groupData['walletAddress'] ?? "";
  //                               if (groupWallet.isEmpty) return;
  //                               showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  //                               String stakedBalance = await vaultService.getAnyStakedBalance(groupWallet);
  //                               if (mounted) Navigator.pop(context);

  //                               StakeModal.show(context: context, balanceTTC: _saldoGrupo.toString(), stakedTTC: stakedBalance, isGroupMode: true, groupId: _group['id'], vaultAddress: groupWallet, onUpdateBalance: () async {
  //                                   await _cargarSaldoGrupo(); _cargarCobros();
  //                                 }, mostrarMensaje: (msg, {bool esError = false}) {
  //                                   UIHelper.showCustomSnackbar(msg, isError: esError);
  //                               });
  //                             },
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                Expanded(
  //                   //child: DefaultTabController(
  //                     //length: 5,
  //                     child: Column(
  //                       children: [
  //                         TabBar(
  //                           controller: _tabController,
  //                           isScrollable: true,
  //                           indicatorColor: colorScheme.primary,
  //                           indicatorWeight: 3,
  //                           labelColor: colorScheme.primary,
  //                           unselectedLabelColor: onSurface.withOpacity(0.5),
  //                           labelStyle: const TextStyle(fontWeight: FontWeight.bold),
  //                           tabs: const [
  //                             Tab(icon: Icon(Icons.people_alt_rounded), text: "Miembros"),
  //                             Tab(icon: Icon(Icons.how_to_vote_rounded), text: "Propuestas"), // Solo Pendientes
  //                             Tab(icon: Icon(Icons.receipt_long_rounded), text: "Cobros"), // Solo Completadas/Activas
  //                             Tab(icon: Icon(Icons.savings_rounded), text: "Ayudas"),
  //                             Tab(icon: Icon(Icons.history_rounded), text: "Historial"),
  //                           ],
  //                         ),
  //                         Expanded(
  //                           child: TabBarView(
  //                             controller: _tabController,
  //                             children: [
  //                               // --- TAB 1: MIEMBROS ---
  //                               Column(
  //                                 children: [
  //                                   // if (_miEstado == "CREATOR")
  //                                   //   Padding(
  //                                   //     padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
  //                                   //     child: ElevatedButton.icon(
  //                                   //       style: ElevatedButton.styleFrom(
  //                                   //         backgroundColor: colorScheme.primary.withOpacity(0.1),
  //                                   //         foregroundColor: colorScheme.primary,
  //                                   //         elevation: 0,
  //                                   //         minimumSize: const Size(double.infinity, 50),
  //                                   //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                                   //       ),
  //                                   //       onPressed: _abrirBuscadorContactos,
  //                                   //       icon: const Icon(Icons.person_add_alt_1_rounded),
  //                                   //       label: const Text("Invitar nuevo miembro", style: TextStyle(fontWeight: FontWeight.bold)),
  //                                   //     ),
  //                                   //   ),
  //                                   Padding(
  //                                     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  //                                     child: TextField(
  //                                       controller: _searchController,
  //                                       style: TextStyle(color: onSurface),
  //                                       decoration: InputDecoration(
  //                                         hintText: "Buscar alias o wallet...",
  //                                         hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
  //                                         prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
  //                                         filled: true,
  //                                         fillColor: onSurface.withOpacity(0.05),
  //                                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                                       ),
  //                                       onChanged: (val) => setState(() => _searchQuery = val),
  //                                     ),
  //                                   ),
  //                                   Expanded(
  //                                     child: Builder(
  //                                       builder: (context) {
  //                                         final filteredMembers = members.where((m) {
  //                                           final alias = m['alias'].toString().toLowerCase();
  //                                           final wallet = m['walletAddress'].toString().toLowerCase();
  //                                           final query = _searchQuery.toLowerCase();
  //                                           return alias.contains(query) || wallet.contains(query);
  //                                         }).toList();

  //                                         if (filteredMembers.isEmpty) return UIHelper.emptyState(
  //                                           context: context, 
  //                                           icon: Icons.group_off_rounded, 
  //                                           title: "Búsqueda sin resultados", 
  //                                           message: "No se encontraron miembros con ese alias o wallet."
  //                                         );
  //                                         return ListView.builder(
  //                                           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  //                                           itemCount: filteredMembers.length,
  //                                           itemBuilder: (ctx, i) {
  //                                             var m = filteredMembers[i];
  //                                             bool isPending = m['status'] == "PENDING";
  //                                             bool isRejected = m['status'] == "REJECTED";

  //                                             return ListTile(
  //                                               leading: CircleAvatar(
  //                                                backgroundColor: isRejected ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
  //                                                child: Icon(Icons.person_rounded, color: isRejected ? colorScheme.error : colorScheme.primary),
  //                                               ),
  //                                               title: Text(
  //                                                 "@${m['alias']}",
  //                                                 style: TextStyle(color: onSurface, decoration: isRejected ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold),
  //                                               ),
  //                                               subtitle: Text(m['walletAddress'].toString().substring(0, 10) + "...", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
  //                                               trailing: Row(
  //                                                 mainAxisSize: MainAxisSize.min,
  //                                                 children: [
  //                                                   Container(
  //                                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //                                                     decoration: BoxDecoration(
  //                                                       color: isPending ? Colors.orange.withOpacity(0.2) : (isRejected ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
  //                                                       borderRadius: BorderRadius.circular(10),
  //                                                     ),
  //                                                     child: Text(
  //                                                       m['status'],
  //                                                       style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.orange : (isRejected ? Colors.red : Colors.green)),
  //                                                     ),
  //                                                   ),
  //                                                   if (_miEstado == "CREATOR" && m['walletAddress'].toString().toLowerCase() != authCore.publicAddress.toLowerCase())
  //                                                     IconButton(
  //                                                      icon: Icon(Icons.person_remove_rounded, color: colorScheme.error, size: 20),
  //                                                       onPressed: () async {
  //                                                         setState(() => _isLoading = true);
  //                                                         String res = await groupService.removeGroupMember(_group['id'], m['walletAddress']);
  //                                                         if (res == "SUCCESS") {
  //                                                           await _actualizarGrupoLocal();
  //                                                           setState(() => _isLoading = false);
  //                                                         } else {
  //                                                           UIHelper.showCustomSnackbar(res, isError: true);
  //                                                           setState(() => _isLoading = false);
  //                                                         }
  //                                                       },
  //                                                     ),
  //                                                 ],
  //                                               ),
  //                                             );
  //                                           },
  //                                         );
  //                                       },
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),    // --- TAB 4: LA AYUDA ---

  //                               // --- TAB 2: PROPUESTAS (Pendientes de Votar) ---
  //                               FutureBuilder<List<dynamic>>(
  //                                 future: _paymentsFuture,
  //                                 builder: (context, snapshot) {
  //                                   if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                                    
  //                                   List<dynamic> propuestas = (snapshot.data ?? []).where((r) => r['status'] == "PENDING_APPROVAL").toList();

  //                                   if (propuestas.isEmpty) return UIHelper.emptyState(
  //                                       context: context, 
  //                                       icon: Icons.how_to_vote_rounded, 
  //                                       title: "Sin Propuestas", 
  //                                       message: "No hay votaciones pendientes en este momento en la DAO."
  //                                     );
  //                                   return ListView.builder(
  //                                     padding: const EdgeInsets.all(16),
  //                                     itemCount: propuestas.length,
  //                                     itemBuilder: (ctx, i) {
  //                                       var req = propuestas[i];
  //                                       List<dynamic> approvals = req['approvals'] ?? [];
  //                                       bool yaVote = approvals.contains(authCore.publicAddress.toLowerCase());

  //                                       return Card(
  //                                         margin: const EdgeInsets.only(bottom: 12),
  //                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //                                         child: ListTile(
  //                                           leading: CircleAvatar(backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1), child: const Icon(Icons.how_to_vote_rounded, color: Colors.deepPurpleAccent)),
  //                                           title: Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
  //                                           subtitle: Text(req['requestType'] == 'CONFIG_CHANGE' ? "Ajuste de DAO" : "DeFi o Multisig", style: TextStyle(color: colorScheme.primary, fontSize: 12)),
  //                                           trailing: !yaVote 
  //                                             ? ElevatedButton.icon(
  //                                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //                                                 icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
  //                                                 label: const Text("Aprobar"),
  //                                                 onPressed: () async {
  //                                                   bool auth = await authCore.authenticateUser();
  //                                                   if (!auth) return;
  //                                                   showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  //                                                   String res = await groupService.approveMultisigPayment(req['id']);
  //                                                   if (mounted) Navigator.pop(context);
  //                                                   if (res == "SUCCESS") { UIHelper.showCustomSnackbar("Voto registrado exitosamente", isError: false); _cargarCobros(); } 
  //                                                   else { UIHelper.showCustomSnackbar(res, isError: true); }
  //                                                 },
  //                                               )
  //                                             : Chip(label: const Text("Aprobado", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1), labelStyle: const TextStyle(color: Colors.deepPurpleAccent), side: BorderSide.none),
  //                                         ),
  //                                       );
  //                                     },
  //                                   );
  //                                 },
  //                               ),

  //                               // --- TAB 3: COBROS (Splitwise y Completados) ---
  //                               FutureBuilder<List<dynamic>>(
  //                                 future: _paymentsFuture,
  //                                 builder: (context, snapshot) {
  //                                   if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                                    
  //                                   List<dynamic> cobros = (snapshot.data ?? []).where((r) => r['status'] != "PENDING_APPROVAL").toList();

  //                                   // List<dynamic> cobrosFiltrados = cobros.where((req) {
  //                                   //   String status = (req['status'] ?? '').toString().toUpperCase();
  //                                   //   bool pasaEstado = true;
  //                                   //   if (_filtroCobros == 'Todos') return true;
  //                                   //   if (_filtroCobros == 'Pendientes') return status == 'OPEN' || status == 'PENDING_APPROVAL';
  //                                   //   if (_filtroCobros == 'Completados') return status == 'COMPLETED';
  //                                   //   if (_filtroCobros == 'Fallidos') return status == 'FAILED' || status == 'REJECTED';

  //                                   //   if (!pasaEstado) return false;

  //                                   //   // Filtro de Tipo (Bóveda o Dividido)
  //                                   //   bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
  //                                   //   if (_filtroTipoCobro == 'Divididos' && isVaultPayment) return false;
  //                                   //   if (_filtroTipoCobro == 'Bóveda' && !isVaultPayment) return false;

  //                                   //   return true;
  //                                   // }).toList();

  //                                   // 🔥 FILTROS CORREGIDOS
  //                                   List<dynamic> cobrosFiltrados = cobros.where((req) {
  //                                     String status = (req['status'] ?? '').toString().toUpperCase();
                                      
  //                                     // 1. Validar el Estado primero
  //                                     bool pasaEstado = true;
  //                                     if (_filtroCobros == 'Pendientes') pasaEstado = status == 'OPEN' || status == 'PENDING_APPROVAL';
  //                                     else if (_filtroCobros == 'Completados') pasaEstado = status == 'COMPLETED';
  //                                     else if (_filtroCobros == 'Fallidos') pasaEstado = status == 'FAILED' || status == 'REJECTED';

  //                                     if (!pasaEstado) return false;

  //                                     // 2. Validar el Tipo (Solo llega aquí si pasó la prueba del estado)
  //                                     bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
  //                                     if (_filtroTipoCobro == 'Divididos' && isVaultPayment) return false;
  //                                     if (_filtroTipoCobro == 'Bóveda' && !isVaultPayment) return false;

  //                                     return true;
  //                                   }).toList();

  //                                   return Column(
  //                                     children: [
  //                                       // if (_miEstado == "CREATOR")
  //                                       //   Padding(
  //                                       //     padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 5),
  //                                       //     child: ElevatedButton.icon(
  //                                       //       style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary.withOpacity(0.1), foregroundColor: colorScheme.primary, elevation: 0, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colorScheme.primary.withOpacity(0.3)))),
  //                                       //       onPressed: () {
  //                                       //         RequestGroupPaymentModal.show(context: context, service: widget.service, groupId: _group['id'], isCreator: _miEstado == "CREATOR", saldoGrupo: _saldoGrupo, onSuccess: () => _cargarCobros());
  //                                       //       },
  //                                       //       icon: const Icon(Icons.request_quote_rounded),
  //                                       //       label: const Text("Nuevo Pago o Cobro", style: TextStyle(fontWeight: FontWeight.bold)),
  //                                       //     ),
  //                                       //   ),

  //                                       // _buildFiltros(['Todos', 'Divididos', 'Bóveda'], _filtroTipoCobro, (val) => setState(() => _filtroTipoCobro = val)),
                                        
  //                                       //  _buildFiltros(['Todos', 'Pendientes', 'Completados', 'Fallidos'], _filtroCobros, (val) => setState(() => _filtroCobros = val)),

  //                                       // 🔥 BARRA DE FILTROS UNIFICADA (CHIP DESPLEGABLE + CHIPS DE ESTADO)
  //                                       SingleChildScrollView(
  //                                         scrollDirection: Axis.horizontal,
  //                                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                                         child: Row(
  //                                           children: [
  //                                             // 1. CHIP DESPLEGABLE PARA EL TIPO DE COBRO
  //                                             PopupMenuButton<String>(
  //                                               initialValue: _filtroTipoCobro,
  //                                               color: theme.cardColor,
  //                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                                               onSelected: (String newValue) => setState(() => _filtroTipoCobro = newValue),
  //                                               itemBuilder: (BuildContext context) => const [
  //                                                 PopupMenuItem<String>(value: 'Todos', child: Text('Todos los tipos')),
  //                                                 PopupMenuItem<String>(value: 'Divididos', child: Text('Pagos Divididos')),
  //                                                 PopupMenuItem<String>(value: 'Bóveda', child: Text('Pagos de Bóveda')),
  //                                               ],
  //                                               child: Chip(
  //                                                 avatar: Icon(Icons.filter_list_rounded, size: 18, color: _filtroTipoCobro != 'Todos' ? colorScheme.onPrimary : colorScheme.primary),
  //                                                 label: Row(
  //                                                   mainAxisSize: MainAxisSize.min,
  //                                                   children: [
  //                                                     Text(
  //                                                       _filtroTipoCobro == 'Todos' ? 'Tipo' : _filtroTipoCobro,
  //                                                       style: TextStyle(color: _filtroTipoCobro != 'Todos' ? colorScheme.onPrimary : colorScheme.primary, fontWeight: FontWeight.bold),
  //                                                     ),
  //                                                     Icon(Icons.arrow_drop_down_rounded, size: 18, color: _filtroTipoCobro != 'Todos' ? colorScheme.onPrimary : colorScheme.primary),
  //                                                   ],
  //                                                 ),
  //                                                 backgroundColor: _filtroTipoCobro != 'Todos' ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
  //                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                                                 padding: EdgeInsets.zero,
  //                                               ),
  //                                             ),
  //                                             const SizedBox(width: 8),

  //                                             // 2. CHIPS DE ESTADO NORMALES
  //                                             ...['Todos', 'Pendientes', 'Completados', 'Fallidos'].map((opcion) {
  //                                               bool isSelected = _filtroCobros == opcion;
  //                                               return Padding(
  //                                                 padding: const EdgeInsets.only(right: 8),
  //                                                 child: ChoiceChip(
  //                                                   label: Text(opcion, style: TextStyle(
  //                                                     color: isSelected ? theme.cardColor : colorScheme.onSurface.withOpacity(0.7), 
  //                                                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
  //                                                   )),
  //                                                   selected: isSelected,
  //                                                   selectedColor: colorScheme.primary,
  //                                                   backgroundColor: colorScheme.onSurface.withOpacity(0.05),
  //                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                                                   showCheckmark: false,
  //                                                   onSelected: (selected) {
  //                                                     if (selected) setState(() => _filtroCobros = opcion);
  //                                                   },
  //                                                 ),
  //                                               );
  //                                             }).toList(),
  //                                           ],
  //                                         ),
  //                                       ),

  //                                       Expanded(
  //                                         child: cobrosFiltrados.isEmpty 
                                  
  //                                           ? SingleChildScrollView( // 🔥 FIX: Evita el overflow permitiendo scroll
  //                                                 physics: const BouncingScrollPhysics(),
  //                                                 child: Padding(
  //                                                   padding: const EdgeInsets.symmetric(vertical: 20),
  //                                                   child: UIHelper.emptyState(
  //                                                     context: context, 
  //                                                     icon: Icons.receipt_long_rounded, 
  //                                                     title: "Sin Cobros", 
  //                                                     message: "No hay cobros o pagos grupales que coincidan con este filtro."
  //                                                   ),
  //                                                 ),
  //                                               )
  //                                             :ListView.builder(
  //                                           padding: const EdgeInsets.all(16),
  //                                           itemCount: cobrosFiltrados.length,
  //                                           itemBuilder: (ctx, i) {
  //                                             var req = cobrosFiltrados[i];
  //                                             bool isVaultPayment = (req['debts'] as List?)?.isEmpty ?? false;
  //                                             var miDeuda = (req['debts'] as List?)?.firstWhere((d) => d['walletAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase(), orElse: () => null);
                                              
  //                                             if (!isVaultPayment && miDeuda == null) return const SizedBox(); 

  //                                             bool pendiente = miDeuda != null && miDeuda['status'] == "PENDING";
  //                                             bool completado = req['status'] == "COMPLETED";

  //                                             Color iconColor = pendiente ? Colors.orange : Colors.green;
  //                                             IconData mainIcon = pendiente ? Icons.receipt_long_rounded : Icons.check_circle_rounded;

  //                                             return Card(
  //                                               margin: const EdgeInsets.only(bottom: 12),
  //                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //                                               // 🔥 FIX: Hacemos que la tarjeta sea clickeable
  //                                               child: InkWell(
  //                                                 borderRadius: BorderRadius.circular(20),
  //                                                 onTap: () {
  //                                                   GroupPaymentDetailsModal.show(
  //                                                     context: context, 
  //                                                     req: req, 
  //                                                     groupName: _group['name']
  //                                                   );
  //                                                 },
  //                                                 child: ListTile(
  //                                                   leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(mainIcon, color: iconColor)),
  //                                                   title: Text(req['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
  //                                                   subtitle: Text(isVaultPayment ? "Monto Total: ${req['totalAmount']} TTC" : "Tu parte: ${miDeuda['amountOwed']} TTC"),
  //                                                   trailing: completado ? const Icon(Icons.check_circle_rounded, color: Colors.green) 
  //                                                   : ElevatedButton(
  //                                                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //                                                       onPressed: () => _pagarMiParte(req['id'], double.parse(miDeuda!['amountOwed'].toString()), req['destinationAddress']),
  //                                                       child: const Text("Pagar", style: TextStyle(fontWeight: FontWeight.bold)),
  //                                                     ),
  //                                                 ),
  //                                               ),
  //                                             );
  //                                           },
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   );
  //                                 },
  //                               ),

  //                               // --- TAB 4: LA AYUDA (Deudas Socializadas) ---
  //                          FutureBuilder<List<dynamic>>(
  //                               future: _ayudaFuture,
  //                                 builder: (context, snapshot) {
  //                                   if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
  //                                   if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No hay nadie pidiendo ayuda.", style: TextStyle(color: onSurface.withOpacity(0.5))));

  //                                   // 🔥 FILTRO APLICADO PARA LA AYUDA
  //                                   List<dynamic> ayudasFiltradas = snapshot.data!.where((ayuda) {
  //                                     String status = (ayuda['status'] ?? '').toString().toUpperCase();
  //                                     if (_filtroAyudas == 'Todos') return true;
  //                                     if (_filtroAyudas == 'Pendientes de aprobar') return status == 'PENDING_VOTE';
  //                                     if (_filtroAyudas == 'Aprobados') return status == 'APPROVED';
  //                                     if (_filtroAyudas == 'Pendientes') return status == 'FUNDING';
  //                                     if (_filtroAyudas == 'Completados') return status == 'COMPLETED';
  //                                     if (_filtroAyudas == 'Fallidos') return status == 'FAILED' || status == 'REJECTED';
  //                                     return true;
  //                                   }).toList();
                                    
  //                                   return Column(
  //                                     children: [
  //                                       // 🔥 WIDGET DE CHIPS M3
  //                                      _buildFiltros(['Todos', 'Completados','Pendientes', 'Pendientes de aprobar', 'Fallidos'], _filtroAyudas, (val) => setState(() => _filtroAyudas = val)),

  //                                       Expanded(
  //                                         child: ayudasFiltradas.isEmpty 
  //                                             // ? UIHelper.emptyState(
  //                                             //       context: context, 
  //                                             //       icon: Icons.volunteer_activism_rounded, 
  //                                             //       title: "Sin Ayudas", 
  //                                             //       message: "No hay vacas o solicitudes de ayuda con este estado."
  //                                             //     )

  //                                             ? SingleChildScrollView( // 🔥 FIX: Evita el overflow permitiendo scroll
  //                                                 physics: const BouncingScrollPhysics(),
  //                                                 child: Padding(
  //                                                   padding: const EdgeInsets.symmetric(vertical: 20),
  //                                                   child: UIHelper.emptyState(
  //                                                     context: context, 
  //                                                       icon: Icons.volunteer_activism_rounded,
  //                                                      title: "Sin Ayudas", 
  //                                                     message: "No hay vacas o solicitudes de ayuda con este estado."
  //                                                   ),
  //                                                 ),
  //                                               )
  //                                             : ListView.builder(
  //                                                 padding: const EdgeInsets.all(16),
  //                                                 itemCount: ayudasFiltradas.length,
  //                                                 itemBuilder: (ctx, i) {
  //                                                   var ayuda = ayudasFiltradas[i];
  //                                                   double meta = double.tryParse(ayuda['requestedAmount'].toString()) ?? 0;
  //                                                   double recaudado = double.tryParse(ayuda['raisedAmount'].toString()) ?? 0;
  //                                                   double progreso = meta > 0 ? (recaudado / meta) : 0;
                                                    
  //                                                   bool isPendingVote = ayuda['status'] == "PENDING_VOTE";
  //                                                   bool isFunding = ayuda['status'] == "FUNDING";
  //                                                   bool isCompleted = ayuda['status'] == "COMPLETED";
                                                    
  //                                                   List<dynamic> votos = ayuda['groupApprovals'] ?? [];
  //                                                   bool yaVote = votos.contains(authCore.publicAddress.toLowerCase());

  //                                                   return Card(
  //                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.orange.withOpacity(0.3))),
  //                                                     child: Padding(
  //                                                       padding: const EdgeInsets.all(16),
  //                                                       child: Column(
  //                                                         crossAxisAlignment: CrossAxisAlignment.start,
  //                                                         children: [
  //                                                           Row(
  //                                                             children: [
  //                                                               const Icon(Icons.campaign_rounded, color: Colors.orange),
  //                                                               const SizedBox(width: 8),
  //                                                               Expanded(child: Text(ayuda['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
  //                                                             ],
  //                                                           ),
  //                                                           const SizedBox(height: 10),
  //                                                           Text("Ayuda solicitada por: ${ayuda['debtorAddress'].toString().substring(0, 8)}..."),
                                                            
  //                                                           if (!isPendingVote) ...[
  //                                                             const SizedBox(height: 16),
  //                                                             LinearProgressIndicator(value: progreso, backgroundColor: Colors.grey.withOpacity(0.2), color: Colors.orange, minHeight: 8, borderRadius: BorderRadius.circular(10)),
  //                                                             const SizedBox(height: 4),
  //                                                             Row(
  //                                                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                                               children: [
  //                                                                 Text("$recaudado TTC recaudados", style: const TextStyle(fontSize: 12)),
  //                                                                 Text("Meta: $meta TTC", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  //                                                               ],
  //                                                             ),
  //                                                           ],

  //                                                           const SizedBox(height: 16),
  //                                                           if (isPendingVote)
  //                                                             SizedBox(
  //                                                               width: double.infinity,
  //                                                               child: ElevatedButton.icon(
  //                                                                 style: ElevatedButton.styleFrom(backgroundColor: yaVote ? Colors.grey : Colors.deepPurpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //                                                                onPressed: yaVote ? null : () async {
  //                                                                   // 1. Mostrar Skeleton para bloquear la pantalla
  //                                                                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza tu voto para ayudar."));
                                                                    
  //                                                                   // 2. Pedir huella
  //                                                                   bool auth = await authCore.authenticateUser();
                                                                    
  //                                                                   // 3. Quitar Skeleton de firma
  //                                                                   if (mounted) Navigator.pop(context);
  //                                                                   if (!auth) return;

  //                                                                   // 4. Mostrar Skeleton de procesamiento
  //                                                                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando Voto", message: "Registrando en la DAO..."));
                                                                    
  //                                                                   String res = await debtService.voteToHelpSharedDebt(ayuda['id']);
                                                                    
  //                                                                   if (mounted) Navigator.pop(context); // Quitar skeleton de proceso
                                                                    
  //                                                                   if (res == "Exito") {
  //                                                                      _cargarCobros(); // Refresca las listas
  //                                                                   } else {
  //                                                                      UIHelper.showCustomSnackbar("Error al votar: $res", isError: true);
  //                                                                   }
  //                                                                 },
                                                                  
  //                                                                 icon: const Icon(Icons.thumb_up_alt_rounded), label: Text(yaVote ? "Ya votaste" : "Aprobar ayuda"),
  //                                                               ),
  //                                                             )
  //                                                           else if (isFunding)
  //                                                             SizedBox(
  //                                                               width: double.infinity,
  //                                                               child: ElevatedButton.icon(
  //                                                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  //                                                                 onPressed: () => _mostrarOpcionesAporteAyuda(ayuda),
  //                                                                 icon: const Icon(Icons.volunteer_activism_rounded), label: const Text("Aportar a la ayuda"),
  //                                                               ),
  //                                                             )
  //                                                           else if (isCompleted)
  //                                                             const Center(child: Text("¡Meta alcanzada! El grupo salvó el día.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
  //                                                         ],
  //                                                       ),
  //                                                     ),
  //                                                   );
  //                                                 },
  //                                               ),
  //                                       ),
  //                                     ],
  //                                   );
  //                                 },
  //                               ),

  //                               // --- TAB 5: HISTORIAL DE LA BÓVEDA ---
  //                            FutureBuilder<List<dynamic>>(
  //                               future: _historialFuture,
  //                                 builder: (context, snapshot) {
  //                                   if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorScheme.primary));
  //                                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //                                     return Center(child: Text("La bóveda no tiene movimientos.", style: TextStyle(color: onSurface.withOpacity(0.5))));
  //                                   }

  //                                   String vaultAddress = _group['walletAddress']?.toString().toLowerCase() ?? "";

  //                                   // 🔥 FILTRO APLICADO PARA EL HISTORIAL DE LA BÓVEDA
  //                                   List<dynamic> historialFiltrado = snapshot.data!.where((tx) {

  //                                     if (_fechaInicioHistorial != null && _fechaFinHistorial != null && tx['timestamp'] != null) {
  //                                       try {
  //                                         DateTime txDate = DateTime.parse(tx['timestamp'].toString());
  //                                         DateTime justDate = DateTime(txDate.year, txDate.month, txDate.day);
  //                                         DateTime start = DateTime(_fechaInicioHistorial!.year, _fechaInicioHistorial!.month, _fechaInicioHistorial!.day);
  //                                         DateTime end = DateTime(_fechaFinHistorial!.year, _fechaFinHistorial!.month, _fechaFinHistorial!.day);

  //                                         if (justDate.isBefore(start) || justDate.isAfter(end)) return false;
  //                                       } catch (e) { return false; }
  //                                     }

  //                                     String tipo = (tx['txType'] ?? '').toString().toUpperCase();
  //                                     bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
                                      
  //                                     if (_filtroHistorial == 'Todos') return true;
  //                                     if (_filtroHistorial == 'Aportes') return esIngreso;
  //                                     if (_filtroHistorial == 'Pagos de ayudas') return tipo == 'SHARED_DEBT_PAYMENT';
  //                                     if (_filtroHistorial == 'Pagos') return !esIngreso && tipo != 'SHARED_DEBT_PAYMENT';
  //                                     return true;
  //                                   }).toList();

  //                                   Map<String, List<dynamic>> historialAgrupado = _groupTransactionsByDate(historialFiltrado);

  //                                   return Column(
  //                                     children: [
  //                                       Padding(
  //                                         padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  //                                         child: Row(
  //                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                           children: [
  //                                             Text("Movimientos (${snapshot.data!.length})", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.7))),
  //                                             Row(
  //                                               children: [
  //                                                 IconButton(
  //                                                   tooltip: "Exportar PDF",
  //                                                   icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
  //                                                   onPressed: () => ShareHelper.generarYCompartirPDFHistory(context, snapshot.data!, vaultAddress),
  //                                                 ),
  //                                                 IconButton(
  //                                                   tooltip: "Exportar Excel",
  //                                                   icon: Icon(Icons.table_view_rounded, color: Colors.green.shade600),
  //                                                   onPressed: () => ShareHelper.exportarHistorialCSV(context, snapshot.data!, vaultAddress),
  //                                                 ),
  //                                               ],
  //                                             )
  //                                           ],
  //                                         ),
  //                                       ),

  //                                       SingleChildScrollView(
  //                                         scrollDirection: Axis.horizontal,
  //                                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
  //                                         child: Row(
  //                                           children: [
  //                                             // Botón Fechas
  //                                             Padding(
  //                                               padding: const EdgeInsets.only(right: 8),
  //                                               child: ActionChip(
  //                                                 label: Icon(
  //                                                   _fechaInicioHistorial != null ? Icons.calendar_month_rounded : Icons.date_range_rounded, 
  //                                                   size: 20, // Puedes subirlo a 20 ya que no hay texto
  //                                                   color: _fechaInicioHistorial != null ? colorScheme.onPrimary : colorScheme.primary
  //                                                 ),
  //                                                 backgroundColor: _fechaInicioHistorial != null ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
  //                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                                                 onPressed: _seleccionarRangoFechasHistorial,
  //                                               ),
  //                                             ),
  //                                             // Botón Quitar Filtro Fecha
  //                                             if (_fechaInicioHistorial != null)
  //                                               Padding(
  //                                                 padding: const EdgeInsets.only(right: 8),
  //                                                 child: ActionChip(
  //                                                   //avatar: Icon(Icons.close_rounded, size: 16, color: colorScheme.error),
  //                                                   //label: Text("Quitar", style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
  //                                                   label: Icon(
  //                                                     Icons.close_rounded, size: 20, color: colorScheme.error,
  //                                                   ),
  //                                                   backgroundColor: colorScheme.error.withOpacity(0.1),
  //                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                                                   onPressed: _limpiarFiltroFechasHistorial,
  //                                                 )
  //                                               ),
  //                                       // Chips de Categorías
  //                                             ...['Todos', 'Aportes', 'Pagos', 'Pagos de ayudas'].map((opcion) {
  //                                               bool isSelected = _filtroHistorial == opcion;
  //                                               return Padding(
  //                                                 padding: const EdgeInsets.only(right: 8),
  //                                                 child: ChoiceChip(
  //                                                   label: Text(opcion, style: TextStyle(color: isSelected ? theme.cardColor : colorScheme.onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
  //                                                   selected: isSelected,
  //                                                   selectedColor: colorScheme.primary,
  //                                                   backgroundColor: colorScheme.onSurface.withOpacity(0.05),
  //                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
  //                                                   showCheckmark: false,
  //                                                   onSelected: (selected) { if (selected) setState(() => _filtroHistorial = opcion); },
  //                                                 ),
  //                                               );
  //                                             }).toList(),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                       // 🔥 WIDGET DE CHIPS M3 (Para el historial)
  //                                     // _buildFiltros(['Todos', 'Aportes', 'Pagos', 'Pagos de ayudas'], _filtroHistorial, (val) => setState(() => _filtroHistorial = val)),

  //                                      Expanded(
  //                                         child: historialAgrupado.isEmpty
  //                                             ? SingleChildScrollView( 
  //                                                 physics: const BouncingScrollPhysics(),
  //                                                 child: Padding(
  //                                                   padding: const EdgeInsets.symmetric(vertical: 20),
  //                                                   child: UIHelper.emptyState(
  //                                                     context: context, 
  //                                                     icon: Icons.history_rounded, 
  //                                                     title: "Historial Vacío", 
  //                                                     message: "La bóveda no registra transacciones bajo este filtro."
  //                                                   ),
  //                                                 ),
  //                                               )
  //                                             : ListView.builder(
  //                                                 padding: const EdgeInsets.all(16),
  //                                                 itemCount: historialAgrupado.keys.length,
  //                                                 itemBuilder: (context, index) {
  //                                                   String date = historialAgrupado.keys.elementAt(index);
  //                                                   List<dynamic> txs = historialAgrupado[date]!;
                                                    
  //                                                   return Column(
  //                                                     crossAxisAlignment: CrossAxisAlignment.start,
  //                                                     children: [
  //                                                       // Cabecera del Día
  //                                                       Padding(
  //                                                         padding: const EdgeInsets.symmetric(vertical: 10),
  //                                                         child: Text(date, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14)),
  //                                                       ),
  //                                                       // Transacciones del Día
  //                                                       ...txs.map((tx) {
  //                                                         bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == vaultAddress;
  //                                                         String monto = "${esIngreso ? '+' : '-'}${tx['amount']} TTC";
  //                                                         Color colorMonto = esIngreso ? Colors.green : colorScheme.error;
  //                                                         IconData icono = esIngreso ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
                                                          
  //                                                         // Mostrar solo la hora para las transacciones agrupadas
  //                                                         String hora = "";
  //                                                         try {
  //                                                           DateTime d = DateTime.parse(tx['timestamp'].toString());
  //                                                           hora = "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  //                                                         } catch (e) {
  //                                                           hora = "--:--";
  //                                                         }

  //                                                         return Card(
  //                                                           margin: const EdgeInsets.only(bottom: 12),
  //                                                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //                                                           child: ListTile(
  //                                                             leading: CircleAvatar(backgroundColor: colorMonto.withOpacity(0.1), child: Icon(icono, color: colorMonto)),
  //                                                             title: Text(esIngreso ? "Aporte Recibido" : "Pago Enviado", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                                                             subtitle: Text(hora),
  //                                                             trailing: Text(monto, style: TextStyle(color: colorMonto, fontWeight: FontWeight.bold, fontSize: 16)),
  //                                                             onTap: () {
  //                                                               TransactionGroupDetailsModal.show(context: context, tx: tx, vaultAddress: vaultAddress);
  //                                                             }
  //                                                           ),
  //                                                         );
  //                                                       }).toList(),
  //                                                     ],
  //                                                   );
  //                                                 },
  //                                               ),
  //                                       ),
  //                                     ],
  //                                   );
  //                                 },
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //   );
  // }
}
