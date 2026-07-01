import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/ai_assistant/screens/ai_memory_screen.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_chat_handler.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_memory_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/burner_wallets/modals/create_burner_modal.dart';
import 'package:dapp_movil/modules/business/modals/create_task_modal.dart';
import 'package:dapp_movil/modules/business/services/business_service.dart';
import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:dapp_movil/modules/chat_and_social/screens/chat_room_screen.dart';
import 'package:dapp_movil/modules/crowdfunding/modals/create_crowdfunding_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/create_debt_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/split_bill_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/document_notary/modals/create_document_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/installments_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/plan_payment_modal.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/screens/vaults_screen.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_paypal_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../wallet_and_tx/modals/buy_modal.dart';
import '../../../config/api_config.dart';
import '../../../core/helpers/share_helper.dart'; 
import '../../vaults_and_savings/modals/stake_modal.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/services.dart';

 class AiAssistantDeepSeekScreen extends StatefulWidget {
   const AiAssistantDeepSeekScreen({super.key});

  @override
  State<AiAssistantDeepSeekScreen> createState() => _AiAssistantDeepSeekScreenState();
 }

// class _AiAssistantDeepSeekScreenState extends State<AiAssistantDeepSeekScreen> {

//   final TextEditingController _msgController = TextEditingController();
//   static final List<Map<String, dynamic>> _messages = [
//     {
//       "isUser": false,
//       "text": "¡Hola! Soy tu Asistente TTC (DeepSeek). Puedo enviar saldo/PayPal, dividir cuentas, invitar miembros a tu empresa, asignar tareas, crear ahorros o redactar contratos. ¿En qué te ayudo hoy?"
//     }
//   ];

//   String _contextoFinanciero = "";

//   final SpeechToText _speechToText = SpeechToText();
//   bool _isListening = false;
//   bool _hasText = false;
//   String _transcripcionTemporal = "";

//   @override
//   void initState() {
//     super.initState();
//     _initSpeech();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _cargarContextoFinanciero();
//     });
//   }

// void _initSpeech() async {
//     await _speechToText.initialize();
//     setState(() {});
//   }

//   Future<void> _cargarContextoFinanciero() async {
//     try {
//       final txService = Provider.of<TransactionService>(context, listen: false);
//       final debtService = Provider.of<DebtService>(context, listen: false); // Asumiendo que tienes este
//       final authCore = Provider.of<AuthCoreService>(context, listen: false);
      
//       String saldo = await txService.getBalance();
      
//       // 1. Historial corto
//       List<dynamic> historial = await txService.getTransactionHistory();
//       String ultimasTxs = "Ninguna";
//       if (historial.isNotEmpty) {
//          ultimasTxs = historial.take(2).map((tx) {
//            bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
//            return "${tx['txType']} ${esIngreso ? "+" : "-"}${tx['amount']}";
//          }).join(", ");
//       }

//       // 2. Extraer si tiene deudas pendientes rápidamente
//       // (Asumiendo que debtService tiene un método así, o lo adaptas)
//       int deudasPendientes = 0;
//       try {
//         final deudas = await debtService.getUserDebts();
//         deudasPendientes = deudas.length;
//       } catch(_) {}
      
//       if (mounted) {
//         setState(() {
//           _contextoFinanciero = """
// DATOS EN TIEMPO REAL DEL USUARIO:
// - Saldo: $saldo TTC
// - Últimas 2 Txs: $ultimasTxs
// - Deudas por cobrar/pagar: $deudasPendientes
// """;
//         });
//       }
//     } catch (e) {
//       print("Error cargando contexto RAG: $e");
//     }
//   }

  // Future<Map<String, String>?> _buscarBilleteraPorAlias(String aliasCrudo) async {
  //   String query = aliasCrudo.replaceAll("@", "").trim();
  //   if (query.isEmpty) return null;
    
  //   if (query.startsWith("0x") && query.length == 42) {
  //     return {"alias": query, "walletAddress": query};
  //   }

  //   try {
  //     final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //     final res = await http.get(Uri.parse(ApiConfig.searchAlias.replaceAll("{alias}", query)), headers: {
  //       "Content-Type": "application/json",
  //       if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
  //     });

  //     if (res.statusCode == 200) {
  //       final decoded = jsonDecode(res.body);
  //       Map<String, dynamic>? usuarioEncontrado;
        
  //       if (decoded is List && decoded.isNotEmpty) usuarioEncontrado = decoded.first;
  //       else if (decoded is Map<String, dynamic>) usuarioEncontrado = decoded;

  //       if (usuarioEncontrado != null) {
  //         return {
  //           "alias": usuarioEncontrado['alias'].toString(),
  //           "walletAddress": usuarioEncontrado['walletAddress'].toString().toLowerCase()
  //         };
  //       }
  //     }
  //   } catch (e) {
  //     print("Fallo al buscar alias: $e");
  //   }
  //   return null;
  // }

//   void _iniciarEscucha() async {
//     // Si el usuario da permiso y el micrófono está listo
//     if (await _speechToText.hasPermission) {
//       setState(() {
//         _isListening = true;
//         _transcripcionTemporal = "";
//       });
      
//       // Comenzamos a escuchar y guardamos las palabras en tiempo real
//       await _speechToText.listen(
//         onResult: (result) {
//           setState(() {
//             _transcripcionTemporal = result.recognizedWords;
//           });
//         },
//         localeId: "es_ES", // Opcional: fuerza español, o bórralo para usar el idioma del sistema
//       );
//     } else {
//       // Si no tiene permisos, intenta pedirlos inicializando de nuevo
//       await _speechToText.initialize();
//     }
//   }

//   void _detenerYEnviarAudio() async {
//     await _speechToText.stop();
//     setState(() => _isListening = false);

//     // Si detectó palabras, las pasamos al TextField y disparamos el envío a DeepSeek
//     if (_transcripcionTemporal.trim().isNotEmpty) {
//       _msgController.text = _transcripcionTemporal;
//     }
//     _transcripcionTemporal = "";
//   }

  
// Future<void> _sendMessage() async {
//     String userText = _msgController.text.trim();
//     if (userText.isEmpty) return;
    
//     setState(() {
//       _messages.add({"isUser": true, "text": userText});
//       _msgController.clear();
//       _hasText = false;
//       _messages.add({"isUser": false, "text": "Procesando de forma segura...", "isLoading": true});
//     });

//     try {
//       final authCore = Provider.of<AuthCoreService>(context, listen: false);
      
//       final String promptSistema = """
// Eres el núcleo de enrutamiento de la DApp TTC Wallet. NO eres un chatbot conversacional. Eres una API que traduce intenciones a JSON.
// $_contextoFinanciero

// REGLAS ESTRICTAS E INQUEBRANTABLES (Si las rompes el sistema falla):
// 1. FORMATO: Responde ÚNICA Y EXCLUSIVAMENTE con un JSON válido. Cero texto fuera del JSON.
// 2. RESPUESTAS CORTAS: El campo "message" debe tener MÁXIMO 1 oración. Prohibido saludar o dar explicaciones técnicas.
// 3. TAREAS CORPORATIVAS (CREATE_TASK): Si el usuario pide crear una tarea, debes extraer:
//    - 'title' y 'description'.
//    - 'task_type': (STANDARD, GPS, MEET, FORM, OPINION, READ_DOC, NOTARY, AGENDA). Usa STANDARD por defecto.
//    - 'budget': Monto en números (Pon 0 si no lo especifica).
//    - 'assignee': Alias del usuario o nombre del departamento.
//    - 'subtasks': Arreglo de strings con los pasos o subtareas a realizar. (Obligatorio enviar un arreglo, aunque sea vacío []).
// 4. EMPRESA Y DEPARTAMENTOS: 
//    - 'CREATE_DEPARTMENT' (Requiere 'dept_name').
//    - 'ADD_TO_DEPARTMENT' (Requiere 'dept_name' y 'member_alias').
//    - 'INVITE_MEMBER' (Requiere 'recipient').

// LISTA EXACTA DE tx_type PERMITIDOS:
// SEND, BUY, STAKE, CREATE_GROUP, REPORT, PLAN_PAYMENT, INSTALLMENT_PAYMENT, CREATE_DEBT, CREATE_DOCUMENT, CREATE_UCHA, CREATE_BURNER, INVITE_MEMBER, CREATE_TASK, SEND_MESSAGE, SPLIT_PAYMENT, CREATE_VAULT, PAYPAL_SEND, CREATE_DEPARTMENT, ADD_TO_DEPARTMENT

// FORMATO DE SALIDA OBLIGATORIO:
// {
//   "type": "ACTION",
//   "message": "Ejecutando acción...",
//   "action_data": {
//       "tx_type": "CREATE_TASK",
//       "task_type": "STANDARD",
//       "budget": 50,
//       "assignee": "pp3",
//       "subtasks": ["Revisar inventario", "Limpiar local"]
//   }
// }
// """;

//       final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
//       final jsonResponse = await aiMemoryService.sendMessageWithMemory(userText, promptSistema);
      
//       if (!mounted) return;

//       if (jsonResponse != null && jsonResponse.containsKey('response')) {
//         final String aiResponseText = jsonResponse['response']; 
//         final String cleanJsonStr = aiResponseText.replaceAll('```json', '').replaceAll('```', '').trim();
//         final Map<String, dynamic> aiData = jsonDecode(cleanJsonStr);
        
//         setState(() {
//           _messages.removeWhere((msg) => msg["isLoading"] == true);
//           _messages.add({"isUser": false, "text": aiData['message'] ?? "No entendí bien."});
//         });

//         if (aiData['type'] == 'ACTION' && aiData['action_data'] != null) {
//           Map<String, dynamic> action = Map<String, dynamic>.from(aiData['action_data']);
          

//           // =========================================================
//           // FLUJOS QUE NO REQUIEREN DESTINATARIO OBLIGATORIO
//           // =========================================================
//           if (tipoTx == 'SPLIT_PAYMENT') {
//             Navigator.push(context, RouteHelper.slideUpRoute(SplitBillScreen(onBillSplitSuccess: () {})));
//             return;
//           } else if (tipoTx == 'CREATE_VAULT') {
//             Navigator.push(context, RouteHelper.slideUpRoute(const VaultsScreen()));
//             return;
//           } else if (tipoTx == 'PAYPAL_SEND') {
//             SendPaypalModal.show(context: context, onSuccess: () {});
//             return;
//           }

//         
//           if (tipoTx == 'CREATE_TASK') {
//             String title = action['title'] ?? "";
//             String taskType = action['task_type'] ?? "STANDARD";
//             double budget = double.tryParse(action['budget']?.toString() ?? "0") ?? 0.0;
//             String assigneeRaw = (action['assignee'] ?? action['recipient'] ?? action['to'] ?? "").toString().replaceAll("@", "").trim();
//             List<dynamic> subtasksRaw = action['subtasks'] ?? [];
//             List<String> subtasks = subtasksRaw.map((e) => e.toString()).toList();

//             setState(() => _messages.add({"isUser": false, "text": "¡Entendido! Te abriré el formulario con los datos listos para que lo confirmes."}));

//             final bService = Provider.of<BusinessService>(context, listen: false);
//             List<dynamic> activeTeam = []; 
//             List<dynamic> departments = [];
//             try {
//               activeTeam = await bService.getTeamMembers(); 
//               departments = await bService.getDepartments(); 
//             } catch(e) { print("Error cargando equipo: $e"); }
            
//             if (!mounted) return;
//             CreateTaskModal.show(
//                context, 
//                activeTeam, 
//                departments, 
//                () {}, 
//                initialTitle: title,
//                initialDescription: action['description'] ?? "",
//                initialAssigneeAlias: assigneeRaw,
//                initialTaskType: taskType,
//                initialBudget: budget,
//                initialSubtasks: subtasks,
//             );
//             return;
//           }
//           else if (tipoTx == 'CREATE_DEPARTMENT') {
//             String deptName = (action['dept_name'] ?? "Nueva Área").toString();
//             setState(() => _messages.add({"isUser": false, "text": "Abriendo el formulario para crear el área '$deptName'..."}));
//             UIHelper.showCustomSnackbar("Inserta aquí tu llamada al Modal de Crear Departamento con nombre: $deptName");
//             return;
//           }
//           else if (tipoTx == 'ADD_TO_DEPARTMENT' || tipoTx == 'INVITE_MEMBER') {
//             String alias = (action['recipient'] ?? action['member_alias'] ?? action['assignee'] ?? "").toString().replaceAll("@", "").trim();
//             setState(() => _messages.add({"isUser": false, "text": "Preparando invitación para @$alias..."}));
//             UIHelper.showCustomSnackbar("Inserta aquí tu llamada al Modal de Invitar Empleado con alias: $alias");
//             return;
//           }

//           // =========================================================
//         
//           // =========================================================
//           if (['PLAN_PAYMENT', 'INSTALLMENT_PAYMENT', 'CREATE_DEBT', 'SEND', 'SEND_MESSAGE'].contains(tipoTx)) {
//             // Se añadio assignee aquí también como red de seguridad por si otro tx_type lo usa
//             String rawRecipient = (action['assignee'] ?? action['recipient'] ?? action['to'] ?? action['receiver'] ?? "").toString().trim();
//             double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            
//             // ESCUDO 3: Corrector automático de Alias
//             if (rawRecipient.isNotEmpty && !rawRecipient.startsWith('0x') && !rawRecipient.startsWith('@')) {
//               rawRecipient = "@$rawRecipient";
//             }

//             if (rawRecipient.isEmpty) {
//               setState(() => _messages.add({"isUser": false, "text": "¿A quién debo dirigir esto? Por favor especifica el alias."}));
//               return;
//             }

//             final destino = await _buscarBilleteraPorAlias(rawRecipient);
//             if (destino == null) {
//               setState(() => _messages.add({"isUser": false, "text": "No pude encontrar al usuario '$rawRecipient' en el sistema."}));
//               return;
//             }

//             if (!mounted) return;

//             if (tipoTx == 'SEND_MESSAGE') {
//               Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(address: destino['walletAddress']!, alias: destino['alias']!)));
//             } else if (tipoTx == 'PLAN_PAYMENT') {
//               PlanPaymentModal.show(context: context, aliasDestino: destino['alias']!, addressDestino: destino['walletAddress']!);
//             } else if (tipoTx == 'INSTALLMENT_PAYMENT') {
//               InstallmentsModal.show(context: context, aliasDestino: destino['alias']!, addressDestino: destino['walletAddress']!);
//             } else if (tipoTx == 'CREATE_DEBT') {
//               CreateDebtModal.show(context: context, onSuccess: () {}, mostrarMensaje: (msg, {bool esError = false}) {
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green));
//               });
//             } else if (tipoTx == 'SEND') {
//               final txService = Provider.of<TransactionService>(context, listen: false);
//               String saldoRealStr = await txService.getBalance();
//               double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;

//               if (montoReq > saldoReal) {
//                 double faltante = montoReq - saldoReal;
//                 setState(() => _messages.add({"isUser": false, "text": "Tu saldo es insuficiente. Te abriré la pasarela para comprar los ${faltante.toStringAsFixed(2)} TTC que te faltan."}));
//                 BuyModal.show(context: context, initialAmount: faltante.toStringAsFixed(2), onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError = false}) {});
//               } else {
//                 SendModal.show(
//                   context: context, balanceTTC: saldoRealStr, 
//                   initialAddress: "@${destino['alias']}", 
//                   initialAmount: montoReq > 0 ? montoReq.toString() : null, 
//                   onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError = false}) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: esError ? Colors.red : Colors.green)); },
//                 );
//               }
//             }
//           } 
//           // =========================================================
//           // OTRAS FUNCIONALIDADES EXISTENTES (Notaría, Stake, Ucha, Burner)
//           // =========================================================
//           else if (tipoTx == 'CREATE_DOCUMENT') {
//             FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png']);
//             if (result != null && result.files.single.path != null) {
//               File file = File(result.files.single.path!);
//               List<int> fileBytes = await file.readAsBytes();
//               Digest docHash = sha256.convert(fileBytes);
//               String hashCompleto = "0x${docHash.toString()}";
//               if (mounted) {
//                 CreateDocumentModal.show(context: context, fileHash: hashCompleto, onConfirm: (titulo, firmantes) async {
//                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Registrando", message: "Inscribiendo en blockchain..."));
//                   final notaryService = Provider.of<NotaryService>(context, listen: false);
//                   String res = await notaryService.createDocumentDelegated(hashCompleto, titulo, "ipfs://Mock", firmantes);
//                   Navigator.pop(context); 
//                   setState(() => _messages.add({"isUser": false, "text": res.startsWith("Exito") ? "Contrato '$titulo' registrado." : "Error: $res"}));
//                 });
//               }
//             }
//           }
//           else if (tipoTx == 'CREATE_GROUP') { 
//             String groupName = (action['group_name'] ?? action['title'] ?? "Nuevo Fondo").toString();
//             List<dynamic> members = action['members'] ?? [];
//             _ejecutarCreacionDeGrupoPorIA(groupName, members);
//           }
//           else if (tipoTx == 'CREATE_UCHA') {
//             String uchaName = (action['title'] ?? action['group_name'] ?? "Nueva Campaña").toString();
//             double meta = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
//             CreateCrowdfundingModal.show(context: context, initialTitle: uchaName, initialTargetAmount: meta > 0 ? meta.toString() : null, onSuccess: () {}, initialRegion: '', initialLat: 0, initialLon: 0);
//           }
//           else if (tipoTx == 'BUY') {
//             String rawAmount = (action['amount'] ?? action['cantidad'] ?? "").toString();
//             BuyModal.show(context: context, initialAmount: rawAmount, onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
//           }
//           else if (tipoTx == 'STAKE') {
//             final txService = Provider.of<TransactionService>(context, listen: false);
//             final vaultService = Provider.of<SmartVaultService>(context, listen: false);
            
//             String saldoRealStr = await txService.getBalance();
//             double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;
//             double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;

//             if (montoReq > saldoReal) {
//               double faltante = montoReq - saldoReal;
//               setState(() => _messages.add({"isUser": false, "text": "Fondos insuficientes para Stake. Adquiere los ${faltante.toStringAsFixed(2)} TTC faltantes."}));
//               BuyModal.show(context: context, initialAmount: faltante.toStringAsFixed(2), onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
//             } else {
//               String stakedRealStr = await vaultService.getStakedBalance();
//               if (!mounted) return;
//               StakeModal.show(context: context, balanceTTC: saldoRealStr, stakedTTC: stakedRealStr, initialAmount: montoReq > 0 ? montoReq.toString() : null, onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
//             }
//           }
//           else if (tipoTx == 'REPORT') {
//             final txService = Provider.of<TransactionService>(context, listen: false);
//             final authCore = Provider.of<AuthCoreService>(context, listen: false);
//             String formato = action['report_format'] ?? "PDF";
//             String? fechaStr = action['report_date']; 
            
//             List<dynamic> historial = await txService.getTransactionHistory();

//             if (fechaStr != null && fechaStr.isNotEmpty) {
//               historial = historial.where((tx) {
//                 String txDate = tx['timestamp']?.toString().substring(0, 10) ?? "";
//                 return txDate == fechaStr;
//               }).toList();
//             }

//             if (historial.isEmpty) {
//               setState(() => _messages.add({"isUser": false, "text": "No encontré transacciones para generar un reporte."}));
//               return;
//             }

//             if (formato == "CSV") {
//               await ShareHelper.exportarHistorialCSV(context, historial, authCore.publicAddress);
//             } else {
//               await ShareHelper.generarYCompartirPDFHistory(context, historial, authCore.publicAddress);
//             }
//           }
//           else if (tipoTx == 'CREATE_BURNER') {
//             double fondeo = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            
//             final txService = Provider.of<TransactionService>(context, listen: false);
//             String saldoRealStr = await txService.getBalance();
//             double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;

//             if (!mounted) return;

//             if (fondeo > saldoReal) {
//               double faltante = fondeo - saldoReal;
//               setState(() => _messages.add({"isUser": false, "text": "Tu saldo es insuficiente para recargar la Burner Wallet. Te abriré la pasarela para comprar los ${faltante.toStringAsFixed(2)} TTC que te faltan."}));
//               BuyModal.show(context: context, initialAmount: faltante.toStringAsFixed(2), onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
//             } else {
//               setState(() => _messages.add({"isUser": false, "text": "¡Perfecto! Creando tu Billetera Desechable con un saldo inicial de $fondeo TTC..."}));
//               CreateBurnerModal.show(context: context, initialFundingAmount: fondeo > 0 ? fondeo.toString() : null, onSuccess: () {});
//             }
//           }
//         }
//       } else {
//         throw Exception("Error de respuesta del servidor RAG");
//       }
//     } catch (e) {
//       setState(() {
//         _messages.removeWhere((msg) => msg["isLoading"] == true);
//         _messages.add({"isUser": false, "text": "Ups, tuve un error de conexión con el servidor IA."});
//       });
//     }
//   }

//   Future<void> _ejecutarCreacionDeGrupoPorIA(String groupName, List<dynamic> aliases) async {
//     List<Map<String, dynamic>> miembrosConfirmados = [];

//     if (aliases.isNotEmpty) {
//       for (String alias in aliases) {
//         final data = await _buscarBilleteraPorAlias(alias);
//         if (data != null) {
//           miembrosConfirmados.add(data);
//         }
//       }

//       if (miembrosConfirmados.isEmpty) {
//         setState(() => _messages.add({"isUser": false, "text": "No encontré a esos usuarios en el sistema. ¿Están bien escritos sus alias?"}));
//         return; 
//       }
//     }

//     final groupService = Provider.of<GroupSocialService>(context, listen: false);
//     String resultado = await groupService.createGroup(groupName, "Admin", miembrosConfirmados);
    
//     if (resultado == "SUCCESS") {
//       setState(() {
//         if (miembrosConfirmados.isEmpty) {
//            _messages.add({"isUser": false, "text": "Fondo común '$groupName' creado vacío."});
//         } else {
//            _messages.add({"isUser": false, "text": "Fondo común '$groupName' creado. Se enviaron invitaciones a ${miembrosConfirmados.length} miembro(s)."});
//         }
//       });
//     } else {
//       setState(() => _messages.add({"isUser": false, "text": "Error al guardar el grupo: $resultado"}));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final surfaceColor = theme.scaffoldBackgroundColor;
//     final botBubbleColor = theme.cardColor;
//     final userBubbleColor = colorScheme.primary; 
//     final onSurface = colorScheme.onSurface; 

//     return Scaffold(
//       backgroundColor: surfaceColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent, 
//         elevation: 0,
//         iconTheme: IconThemeData(color: onSurface),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 CircleAvatar(
//                   backgroundColor: colorScheme.secondary,
//                   radius: 18,
//                   child: Icon(Icons.smart_toy_rounded, color: colorScheme.onSurface, size: 24),
//                 ),
//                 Container(
//                   width: 10, height: 10,
//                   decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 2)),
//                 ),
//               ],
//             ),
//             const SizedBox(width: 10),
//             Flexible(
//               child: Text(
//                 "Asistente TTC (DeepSeek)", 
//                 style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
//                 overflow: TextOverflow.ellipsis, // Si no cabe, mostrará "Asistente TTC..."
//               ),
//             ),
//           ],
         
//         ),
//         centerTitle: true,

//          actions: [
//           IconButton(
//             icon: Icon(Icons.settings_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
//             tooltip: "Ocultar sección",
//             onPressed: () {
//               Navigator.push(
//   context,
//   MaterialPageRoute(builder: (_) => const AiMemoryScreen()),
// );
//             },
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (ctx, i) {
//                 final msg = _messages[i];
//                 return _buildChatBubble(msg["text"], msg["isUser"] ?? false, botBubbleColor, userBubbleColor, onSurface, colorScheme.onPrimary);
//               },
//             ),
//           ),
//           _buildInputArea(theme.cardColor, onSurface, colorScheme.primary, colorScheme.onPrimary),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatBubble(String text, bool isUser, Color botColor, Color userColor, Color textColor, Color onPrimaryColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isUser) ...[
//             CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondary, radius: 12, child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14)),
//             const SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: isUser ? userColor : botColor,
//                 borderRadius: BorderRadius.only(
//                   topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
//                   bottomLeft: Radius.circular(isUser ? 20 : 0), bottomRight: Radius.circular(isUser ? 0 : 20),
//                 ),
//                 border: isUser ? null : Border.all(color: textColor.withOpacity(0.05)), 
//               ),
//               child: Text(text, style: TextStyle(color: isUser ? onPrimaryColor : textColor, fontSize: 15)),
//             ),
//           ),
//           if (isUser) const SizedBox(width: 20),
//         ],
//       ),
//     );
//   }

class _AiAssistantDeepSeekScreenState extends State<AiAssistantDeepSeekScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  
  bool _isListening = false;
  bool _hasText = false;
  String _transcripcionTemporal = "";

  @override
  void initState() {
    super.initState();
    _initAudio();
    
    // Cargamos balances en el Handler persistente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AiChatHandler>(context, listen: false).cargarContextoFinanciero(context);
    });

    _msgController.addListener(() {
      setState(() {
        _hasText = _msgController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _initAudio() async {
    await Permission.microphone.request();
    await _audioRecorder.openRecorder();
  }

  Future<void> _iniciarEscucha() async {
    if (await Permission.microphone.isGranted) {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/ai_audio.aac';
      await _audioRecorder.startRecorder(toFile: path);
      setState(() {
        _isListening = true;
        _transcripcionTemporal = "Escuchando voz...";
      });
    } else {
      UIHelper.showCustomSnackbar("Permiso de micrófono denegado", isError: true);
    }
  }

  Future<void> _detenerYEnviarAudio() async {
    if (!_isListening) return;
    await _audioRecorder.stopRecorder();
    setState(() => _isListening = false);
    UIHelper.showCustomSnackbar("El dictado por voz de la IA está en optimización.", isError: false);
  }

  Future<void> _sendMessage() async {
    String userText = _msgController.text.trim();
    if (userText.isEmpty) return;
    
    _msgController.clear();
    setState(() => _hasText = false);
    
    final handler = Provider.of<AiChatHandler>(context, listen: false);
    await handler.procesarMensaje(
      context: context,
      userText: userText,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildInputArea(Color cardColor, Color textColor, Color primaryColor, Color onPrimaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _isListening
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _transcripcionTemporal,
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            )
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _msgController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Págale 20 a pp4 o divide la cuenta...",
                        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        filled: true, fillColor: textColor.withOpacity(0.05), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: const ValueKey('ai_boton_micro'),
              onTap: _hasText ? _sendMessage : null, 
              onLongPress: !_hasText ? _iniciarEscucha : null,
              onLongPressEnd: !_hasText ? (details) => _detenerYEnviarAudio() : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(_isListening ? 16 : 12),
                decoration: BoxDecoration(
                  color: _hasText ? primaryColor : (_isListening ? Colors.redAccent : primaryColor), 
                  shape: BoxShape.circle
                ),
                child: Icon(
                  _hasText ? Icons.send_rounded : (_isListening ? Icons.mic_rounded : Icons.mic_none_rounded), 
                  color: Colors.white, size: _isListening ? 24 : 20
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistente Ejecutivo IA"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
            tooltip: "Reiniciar Chat",
            onPressed: () => Provider.of<AiChatHandler>(context, listen: false).reiniciarChat(),
          ),
          IconButton(
            icon: const Icon(Icons.memory_rounded),
            onPressed: () => Navigator.push(context, RouteHelper.slideUpRoute(const AiMemoryScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AiChatHandler>(
              builder: (context, handler, child) {
                // Auto scroll al recibir mensajes nuevos
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: handler.messages.length,
                  itemBuilder: (context, index) {
                    final msg = handler.messages[index];
                    final isUser = msg["isUser"];
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                          ]
                        ),
                        child: msg["isLoading"] == true
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSurface)),
                                  const SizedBox(width: 12),
                                  Text(msg["text"], style: TextStyle(color: colorScheme.onSurface)),
                                ],
                              )
                            : Text(
                                msg["text"],
                                style: TextStyle(color: isUser ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 15),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(theme.cardColor, colorScheme.onSurface, colorScheme.primary, colorScheme.onPrimary),
        ],
      ),
    );
  }
}