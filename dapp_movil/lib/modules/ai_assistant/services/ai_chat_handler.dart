import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dapp_movil/modules/business/modals/create_department_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/split_bill_modal.dart';
import 'package:dapp_movil/modules/vaults_and_savings/modals/create_vault_modal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/route_helper.dart';
import '../../../core/helpers/share_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../burner_wallets/modals/create_burner_modal.dart';
import '../../business/modals/create_task_modal.dart';
import '../../business/services/business_service.dart';
import '../../chat_and_social/screens/chat_room_screen.dart';
import '../../crowdfunding/modals/create_crowdfunding_modal.dart';
import '../../debts_and_payments/modals/create_debt_modal.dart';
import '../../debts_and_payments/modals/installments_modal.dart';
import '../../debts_and_payments/modals/plan_payment_modal.dart';
import '../../debts_and_payments/screens/split_bill_screen.dart';
import '../../document_notary/modals/create_document_modal.dart';
import '../../document_notary/services/notary_service.dart';
import '../../groups_and_social/services/group_social_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../vaults_and_savings/modals/stake_modal.dart';
import '../../vaults_and_savings/screens/vaults_screen.dart';
import '../../vaults_and_savings/services/smart_vault_service.dart';
import '../../wallet_and_tx/modals/buy_modal.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../wallet_and_tx/modals/send_paypal_modal.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import 'ai_memory_service.dart';

// class AiChatHandler {
//   String contextoFinanciero = "";

//   Future<void> cargarContextoFinanciero(BuildContext context) async {
//     try {
//       final txService = Provider.of<TransactionService>(context, listen: false);
//       final vaultService = Provider.of<SmartVaultService>(context, listen: false);
//       String saldo = await txService.getBalance();
//       String stake = await vaultService.getStakedBalance();
//       contextoFinanciero = "CONTEXTO DEL USUARIO:\n- Saldo disponible: $saldo TTC\n- Saldo en Staking: $stake TTC\n";
//     } catch (e) {
//       contextoFinanciero = "CONTEXTO DEL USUARIO:\n- Saldo disponible: 0 TTC\n";
//     }
//   }

//  Future<Map<String, dynamic>?> buscarBilleteraPorAlias(BuildContext context, String query) async {
//     String cleanQuery = query.replaceAll("@", "").trim();
//     if (cleanQuery.isEmpty) return null;
//     try {
//       final userService = Provider.of<UserService>(context, listen: false);
//       return await userService.searchByAlias(cleanQuery);
//     } catch (e) {
//       return null;
//     }
//   }

// Future<void> procesarMensaje({
//     required BuildContext context,
//     required String userText,
//     required Function(Map<String, dynamic>) onAddMessage,
//   }) async {
//     onAddMessage({"isUser": true, "text": userText});
//     onAddMessage({"isUser": false, "text": "Procesando de forma segura...", "isLoading": true});

//     try {
//       final authCore = Provider.of<AuthCoreService>(context, listen: false);
//       String hoy = DateTime.now().toIso8601String().substring(0, 10);
      
//       bool isBusiness = authCore.role == 'ROLE_BUSINESS' || authCore.role == 'ROLE_ADMIN';
//       String rolUsuario = isBusiness ? "EMPRESA" : "USUARIO NORMAL";

//       final String promptSistema = """
// Eres el núcleo de enrutamiento de TTC Wallet. 
// EL USUARIO ACTUAL TIENE EL ROL: $rolUsuario.
// HOY ES: $hoy
// $contextoFinanciero

// SI EL USUARIO ES NORMAL:
// - Usa: SEND, PAYPAL_SEND, SPLIT_PAYMENT, CREATE_VAULT, STAKE, CREATE_DEBT, PLAN_PAYMENT, INSTALLMENT_PAYMENT, CREATE_DOCUMENT, SEND_MESSAGE, CREATE_GROUP, ADD_TO_GROUP, REPORT, CREATE_CROWDFUNDING.
// - NO alucines tareas de empresa.
// SI EL USUARIO ES EMPRESA:
// - Acciones corporativas: CREATE_DEPARTMENT, ADD_TO_DEPARTMENT, INVITE_MEMBER, CREATE_TASK, CREATE_CROWDFUNDING, CREATE_BURNER, REPORT (corporativo).

// EXTRACCIÓN DE DATOS:
// - "CREATE_TASK": Extrae 'task_type' (STANDARD, GPS, MEET, FORM, OPINION), 'title', 'description', 'assignee', 'budget', 'estimated_hours', 'urgency', 'deadline', 'subtasks' (array). 
//   *Si es GPS: 'gps_lat' y 'gps_lon' (deduce las coordenadas del lugar). 
//   *Si es MEET: 'meet_url'. 
//   *Si es OPINION (encuesta): 'opinion_question' y 'poll_options' (array con las opciones, ej: ["Si", "No"]). 
//   *Si es FORM (formulario): 'form_fields' (array con nombres de campos a llenar).
// - "CREATE_DEPARTMENT": Extrae 'dept_name', 'description', 'budget'.
// - "SPLIT_PAYMENT": Dividir cuenta. Extrae 'amount', 'reason', 'split_with' (Array), 'destination' (Alias del comercio o persona destino).
// - "CREATE_VAULT": Ahorro. Extrae 'amount', 'vault_type', 'vault_name', 'target_amount', 'auto_save_amount', 'auto_save_frequency', 'duration_months'.
// - "CREATE_CROWDFUNDING": Vaca comunitaria. Extrae 'title', 'amount', 'duration_days'.

// REGLAS ESTRICTAS:
// 1. Responde EXCLUSIVAMENTE con JSON válido.
// 2. Si falta 'amount', pon 0. NUNCA preguntes.

// FORMATO:
// {
//   "type": "ACTION",
//   "message": "Ejecutando...",
//   "action_data": {
//       "tx_type": "TIPO"
//   }
// }
// """;

//       final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
//       final jsonResponse = await aiMemoryService.sendMessageWithMemory(userText, promptSistema);
      
//       if (!context.mounted) return;

//       if (jsonResponse != null && jsonResponse.containsKey('response')) {
//         final String aiResponseText = jsonResponse['response']; 
//         final String cleanJsonStr = aiResponseText.replaceAll('```json', '').replaceAll('```', '').trim();
//         final Map<String, dynamic> aiData = jsonDecode(cleanJsonStr);
        
//         onAddMessage({"isUser": false, "text": aiData['message'] ?? "Entendido.", "replaceLoading": true});

//         if (aiData['action_data'] != null) {
//           Map<String, dynamic> action = Map<String, dynamic>.from(aiData['action_data']);
//           if (action.containsKey('params')) action.addAll(Map<String, dynamic>.from(action['params']));
          
//           String tipoTx = (action['tx_type'] ?? action['action'] ?? "").toString().toUpperCase();

//           // =========================================================
//        
//           // =========================================================
//           if (['CREATE_TASK', 'CREATE_DEPARTMENT', 'ADD_TO_DEPARTMENT', 'INVITE_MEMBER'].contains(tipoTx) && !isBusiness) {
//             onAddMessage({"isUser": false, "text": "Acción denegada: Solo cuentas de Empresa pueden usar esta función.", "replaceLoading": true});
//             return;
//           }

//           if (tipoTx == 'CREATE_TASK') {
//             String title = action['title'] ?? "";
//             String taskType = (action['task_type'] ?? "STANDARD").toString().toUpperCase();
//             double budget = double.tryParse(action['budget']?.toString() ?? "0") ?? 0.0;
//             String assigneeRaw = (action['assignee'] ?? action['recipient'] ?? "").toString().replaceAll("@", "").trim();
//             List<String> subtasks = (action['subtasks'] as List?)?.map((e) => e.toString()).toList() ?? [];
            
//             String hours = action['estimated_hours']?.toString() ?? "";
//             String urgency = (action['urgency'] ?? "MEDIUM").toString().toUpperCase();
//             String desc = action['description'] ?? "";
//             String deadline = action['deadline']?.toString() ?? "";
            
//             double? lat = double.tryParse(action['gps_lat']?.toString() ?? "");
//             double? lon = double.tryParse(action['gps_lon']?.toString() ?? "");
//             String meetUrl = action['meet_url']?.toString() ?? "";
//             String question = action['opinion_question']?.toString() ?? "";
//             List<String> polls = (action['poll_options'] as List?)?.map((e) => e.toString()).toList() ?? [];
//             List<String> forms = (action['form_fields'] as List?)?.map((e) => e.toString()).toList() ?? [];

//             final bService = Provider.of<BusinessService>(context, listen: false);
//             final userService = Provider.of<UserService>(context, listen: false);
//             List<dynamic> activeTeam = []; 
//             List<dynamic> departments = [];
            
//             try { 
//               activeTeam = (await bService.getTeamMembers()).map((e) => Map<String, dynamic>.from(e)).toList();
//               departments = (await bService.getDepartments()).map((e) => Map<String, dynamic>.from(e)).toList();

//               for (int i = 0; i < activeTeam.length; i++) {
//                 String? w = activeTeam[i]['identifier']?.toString() ?? activeTeam[i]['wallet']?.toString();
//                 if (w != null) {
//                   var userData = await userService.getUserByWallet(w);
//                   if (userData != null && userData['alias'] != null) {
//                     activeTeam[i]['alias'] = userData['alias']; // Ya no explota
//                   }
//                 }
//               }
//             } catch(e) { print("⚠️ Error IA cargando equipo: $e"); }
            
//             CreateTaskModal.show(
//               context, activeTeam, departments, () {}, 
//               initialTitle: title, initialDescription: desc, initialAssigneeAlias: assigneeRaw, 
//               initialTaskType: taskType, initialBudget: budget, initialSubtasks: subtasks,
//               initialHours: hours, initialUrgency: urgency, initialDeadline: deadline,
//               initialGpsLat: lat, initialGpsLon: lon, initialMeetUrl: meetUrl, 
//               initialOpinionQuestion: question, initialPollOptions: polls, initialFormFields: forms
//             );
//             return;
//           }
//           else if (tipoTx == 'CREATE_DEPARTMENT') {
//             String deptName = (action['dept_name'] ?? action['name'] ?? "Nueva Área").toString();
//             String desc = action['description']?.toString() ?? "";
//             String budget = action['budget']?.toString() ?? "";
//             CreateDepartmentModal.show(context, () {}, initialName: deptName, initialDescription: desc, initialBudget: budget);
//             return;
//           }
//           else if (tipoTx == 'INVITE_MEMBER') {
//             String alias = (action['recipient'] ?? action['member_alias'] ?? "").toString().replaceAll("@", "").trim();
//             final destino = await buscarBilleteraPorAlias(context, alias);
//             if (destino != null) {
//                 final bService = Provider.of<BusinessService>(context, listen: false);
//                 String res = await bService.inviteTeamMember(destino['alias'], "ALIAS", action['role'] ?? "CASHIER");
//                 onAddMessage({"isUser": false, "text": res == "SUCCESS" ? "Invitación corporativa enviada a @$alias." : "Error: $res", "replaceLoading": true});
//             } else {
//                 onAddMessage({"isUser": false, "text": "No encontré al usuario @$alias.", "replaceLoading": true});
//             }
//             return;
//           }
//           else if (tipoTx == 'ADD_TO_DEPARTMENT') {
//             String alias = (action['recipient'] ?? action['member_alias'] ?? "").toString().replaceAll("@", "").trim();
//             String deptName = (action['dept_name'] ?? "").toString();
//             final destino = await buscarBilleteraPorAlias(context, alias);
            
//             if (destino != null) {
//                 final bService = Provider.of<BusinessService>(context, listen: false);
//                 List<dynamic> depts = await bService.getDepartments();
//                 var dept = depts.firstWhere((d) => d['name'].toString().toLowerCase() == deptName.toLowerCase(), orElse: () => null);
//                 if (dept != null) {
//                    String walletDestino = destino['contactAddress'] ?? destino['walletAddress'] ?? destino['wallet'] ?? "";
//                    String res = await bService.addMemberToDepartment(dept['id'], walletDestino);
//                    onAddMessage({"isUser": false, "text": res == "SUCCESS" ? "@$alias añadido al área $deptName." : "Error: $res", "replaceLoading": true});
//                 } else {
//                    onAddMessage({"isUser": false, "text": "No tienes un departamento llamado '$deptName'.", "replaceLoading": true});
//                 }
//             } else {
//                 onAddMessage({"isUser": false, "text": "Usuario @$alias no encontrado.", "replaceLoading": true});
//             }
//             return;
//           }

//           // =========================================================
//           // GRUPOS SOCIALES Y REPORTES
//           // =========================================================
//           if (tipoTx == 'ADD_TO_GROUP') {
//             String groupName = (action['group_name'] ?? "").toString();
//             String alias = (action['member_alias'] ?? action['recipient'] ?? "").toString().replaceAll("@", "").trim();
//             final destino = await buscarBilleteraPorAlias(context, alias);
            
//             if (destino != null) {
//               final groupService = Provider.of<GroupSocialService>(context, listen: false);
//               List<dynamic> myGroups = await groupService.getUserGroups();
//               var group = myGroups.firstWhere((g) => g['name'].toString().toLowerCase() == groupName.toLowerCase(), orElse: () => null);
              
//               if (group != null) {
//                 String walletDestino = destino['contactAddress'] ?? destino['walletAddress'] ?? destino['wallet'] ?? "";
//                 String res = await groupService.addGroupMember(group['id'], walletDestino, destino['alias']);
//                 onAddMessage({"isUser": false, "text": res == "SUCCESS" ? "Añadí a @$alias al grupo $groupName." : "Error: $res", "replaceLoading": true});
//               } else {
//                 onAddMessage({"isUser": false, "text": "No tienes un grupo llamado '$groupName'.", "replaceLoading": true});
//               }
//             } else {
//               onAddMessage({"isUser": false, "text": "Usuario @$alias no encontrado.", "replaceLoading": true});
//             }
//             return;
//           }
//           else if (tipoTx == 'REPORT') {
//             final txService = Provider.of<TransactionService>(context, listen: false);
//             List<dynamic> historial = await txService.getTransactionHistory();

//             String? startStr = action['start_date'] ?? action['date'];
//             String? endStr = action['end_date'] ?? action['date'];

//             if (startStr != null) {
//               historial = historial.where((tx) {
//                 String txD = tx['timestamp'].toString().substring(0, 10);
//                 return txD.compareTo(startStr) >= 0 && txD.compareTo(endStr ?? startStr) <= 0;
//               }).toList();
//             }

//             if (historial.isEmpty) {
//               onAddMessage({"isUser": false, "text": "No hay transacciones en esas fechas.", "replaceLoading": true});
//               return;
//             }
//             await ShareHelper.generarYCompartirPDFHistory(context, historial, authCore.publicAddress);
//             return;
//           }

//           // =========================================================
//           // FLUJOS SIN DESTINATARIO OBLIGATORIO
//           // =========================================================
//           if (tipoTx == 'CREATE_VAULT') {
//             double monto = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
//             String vType = (action['vault_type'] ?? action['type'] ?? "flexible").toString().toUpperCase();
//             String vName = (action['vault_name'] ?? action['name'] ?? "").toString();
//             String vTarget = (action['target_amount'] ?? "").toString();
//             String vAuto = (action['auto_save_amount'] ?? "").toString();
//             String vFreq = (action['auto_save_frequency'] ?? "NONE").toString().toUpperCase();
//             int vDuration = int.tryParse(action['duration_months']?.toString() ?? "6") ?? 6;

//             CreateVaultModal.show(context: context, onCreated: () {}, initialAmount: monto > 0 ? monto.toString() : null, initialType: vType, initialName: vName, initialTargetAmount: vTarget, initialAutoSave: vAuto, initialFrequency: vFreq, initialDurationMonths: vDuration);
//             return;
//           } else if (tipoTx == 'CREATE_CROWDFUNDING') {
//             String uchaName = (action['title'] ?? action['group_name'] ?? "Nueva Campaña").toString();
//             double meta = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
//             String duration = (action['duration_days'] ?? "30").toString();
//             CreateCrowdfundingModal.show(context: context, initialTitle: uchaName, initialTargetAmount: meta > 0 ? meta.toString() : null, initialDurationDays: duration, onSuccess: () {}, initialRegion: '', initialLat: 0, initialLon: 0);
//             return;
//           } else if (tipoTx == 'CREATE_BURNER') {
//             double fondeo = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
//             String name = (action['name'] ?? action['label'] ?? "").toString();
//             CreateBurnerModal.show(context: context, initialFundingAmount: fondeo > 0 ? fondeo.toString() : null, initialLabel: name, onSuccess: () {});
//             return;
//           } else if (tipoTx == 'CREATE_DOCUMENT') {
//             FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png']);
//             if (result != null && result.files.single.path != null) {
//               File file = File(result.files.single.path!);
//               List<int> fileBytes = await file.readAsBytes();
//               Digest docHash = sha256.convert(fileBytes);
//               String hashCompleto = "0x${docHash.toString()}";
//               if (context.mounted) {
//                 CreateDocumentModal.show(context: context, fileHash: hashCompleto, onConfirm: (titulo, firmantes) async {
//                   showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Registrando", message: "Inscribiendo en blockchain..."));
//                   final notaryService = Provider.of<NotaryService>(context, listen: false);
//                   String res = await notaryService.createDocumentDelegated(hashCompleto, titulo, "ipfs://Mock", firmantes);
//                   Navigator.pop(context); 
//                   onAddMessage({"isUser": false, "text": res.startsWith("Exito") ? "Contrato registrado." : "Error: $res", "replaceLoading": true});
//                 });
//               }
//             } else {
//               onAddMessage({"isUser": false, "text": "Selección de archivo cancelada.", "replaceLoading": true});
//             }
//             return;
//           } else if (tipoTx == 'BUY') {
//             BuyModal.show(context: context, initialAmount: action['amount']?.toString(), onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {}); return;
//           } else if (tipoTx == 'STAKE') {
//             final txService = Provider.of<TransactionService>(context, listen: false);
//             final vaultService = Provider.of<SmartVaultService>(context, listen: false);
//             String saldoReal = await txService.getBalance();
//             String stakedReal = await vaultService.getStakedBalance();
//             if (!context.mounted) return;
//             StakeModal.show(context: context, balanceTTC: saldoReal, stakedTTC: stakedReal, initialAmount: action['amount']?.toString(), onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
//             return;
//           } else if (tipoTx == 'CREATE_GROUP') { 
//             await _ejecutarCreacionDeGrupoPorIA(context, (action['group_name'] ?? "Nuevo Fondo").toString(), action['members'] ?? [], onAddMessage);
//             return;
//           }

//           // =========================================================
//           // FLUJOS QUE REQUIEREN DESTINATARIO
//           // =========================================================
//           if (['PLAN_PAYMENT', 'INSTALLMENT_PAYMENT', 'CREATE_DEBT', 'SEND', 'SEND_MESSAGE', 'SPLIT_PAYMENT'].contains(tipoTx)) {
//             String rawRecipient = (action['assignee'] ?? action['recipient'] ?? action['to'] ?? action['creditor'] ?? action['debtor'] ?? "").toString().trim();
//             double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
//             String reason = (action['reason'] ?? action['note'] ?? "").toString();
            
//             if (rawRecipient.isNotEmpty && !rawRecipient.startsWith('0x') && !rawRecipient.startsWith('@')) rawRecipient = "@$rawRecipient";

//             if (rawRecipient.isEmpty && tipoTx != 'SPLIT_PAYMENT') {
//               onAddMessage({"isUser": false, "text": "¿A quién debo dirigir esto? Especifica el alias.", "replaceLoading": true}); return;
//             }

//             final destino = rawRecipient.isNotEmpty ? await buscarBilleteraPorAlias(context, rawRecipient) : null;
//             if (destino == null && tipoTx != 'SPLIT_PAYMENT') {
//               onAddMessage({"isUser": false, "text": "No encontré al usuario '$rawRecipient'.", "replaceLoading": true}); return;
//             }

//             if (!context.mounted) return;

//             String walletReal = destino?['walletAddress'] ?? destino?['contactAddress'] ?? destino?['wallet'] ?? "";

//             if (tipoTx == 'SEND_MESSAGE') {
//               String textoMsj = (action['message'] ?? action['content'] ?? "").toString();
//               Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(address: walletReal, alias: destino!['alias']!, initialMessage: textoMsj)));
//             } else if (tipoTx == 'SPLIT_PAYMENT') {
//               List<String> splitters = [];
//               if (action['split_with'] is List) {
//                 splitters.addAll((action['split_with'] as List).map((e) => e.toString()));
//               } else if (action['split_with'] is String) {
//                 splitters.addAll(action['split_with'].toString().split(','));
//               }
//               if (rawRecipient.isNotEmpty) splitters.add(rawRecipient);

//               List<Map<String, String>> resolvedSplitters = [];
//               for (String s in splitters) {
//                 String cleanAlias = s.replaceAll('@', '').trim();
//                 if (cleanAlias.isEmpty) continue;
//                 final d = await buscarBilleteraPorAlias(context, cleanAlias);
//                 if (d != null) {
//                   String w = (d['walletAddress'] ?? d['contactAddress'] ?? d['wallet'] ?? d['identifier'] ?? '').toString();
//                   if (w.isNotEmpty && w.toLowerCase() != authCore.publicAddress.toLowerCase() && !resolvedSplitters.any((e) => e['wallet'] == w)) {
//                     resolvedSplitters.add({"alias": d['alias']?.toString() ?? cleanAlias, "wallet": w});
//                   }
//                 }
//               }
              
//               Navigator.push(context, RouteHelper.slideUpRoute(SplitBillScreen(
//                 onBillSplitSuccess: () {},
//                 initialAmount: montoReq > 0 ? montoReq.toString() : null,
//                 initialReason: reason,
//                 initialDestination: action['destination']?.toString(), // 🔥 NUEVO
//                 initialParticipants: resolvedSplitters,
//               )));
//             } else if (tipoTx == 'PLAN_PAYMENT') {
//               PlanPaymentModal.show(context: context, aliasDestino: destino!['alias']!, addressDestino: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason);
//             } else if (tipoTx == 'INSTALLMENT_PAYMENT') {
//               InstallmentsModal.show(context: context, aliasDestino: destino!['alias']!, addressDestino: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason, initialFrequency: action['frequency']?.toString(), initialInstallments: action['installments']?.toString());
//             } else if (tipoTx == 'CREATE_DEBT') {
//               CreateDebtModal.show(context: context, onSuccess: () {}, mostrarMensaje: (m, {bool esError=false}) {}, initialAlias: "@${destino!['alias']}", initialWallet: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason);
//             }
//           }
//         }
//       } 
//     } catch (e) {
//       onAddMessage({"isUser": false, "text": "Error de conexión con la IA.", "replaceLoading": true});
//     }
//   }

//   Future<void> _ejecutarCreacionDeGrupoPorIA(BuildContext context, String groupName, List<dynamic> aliases, Function(Map<String, dynamic>) onAddMessage) async {
//     List<Map<String, dynamic>> miembrosConfirmados = [];

//     if (aliases.isNotEmpty) {
//       for (String alias in aliases) {
//         final data = await buscarBilleteraPorAlias(context, alias);
//         if (data != null) {
//           miembrosConfirmados.add(data);
//         }
//       }
//       if (miembrosConfirmados.isEmpty) {
//         onAddMessage({"isUser": false, "text": "No encontré a esos usuarios. ¿Están bien escritos?", "replaceLoading": true});
//         return; 
//       }
//     }

//     final groupService = Provider.of<GroupSocialService>(context, listen: false);
//     String resultado = await groupService.createGroup(groupName, "Admin", miembrosConfirmados);
    
//     if (resultado == "SUCCESS") {
//       onAddMessage({"isUser": false, "text": miembrosConfirmados.isEmpty ? "Fondo común '$groupName' creado vacío." : "Fondo común '$groupName' creado. Invitaciones enviadas.", "replaceLoading": true});
//     } else {
//       onAddMessage({"isUser": false, "text": "Error al guardar el grupo: $resultado", "replaceLoading": true});
//     }
//   }
// }

class AiChatHandler extends ChangeNotifier {
  String contextoFinanciero = "";
  
  Map<String, dynamic>? _lastActionData;

  List<Map<String, dynamic>> messages = [
    {"isUser": false, "text": "Hola, soy el núcleo financiero de TTC. Puedo realizar transferencias, reportes de gastos, configurar pagos recurrentes, gestionar tu empresa y analizar tus datos financieros en un solo lugar. ¿Qué necesitas?"}
  ];

  void reiniciarChat() {
    messages = [
      {"isUser": false, "text": "Chat reiniciado de forma segura. ¿En qué te puedo ayudar ahora?"}
    ];
    _lastActionData = null;
    notifyListeners();
  }

  Future<void> cargarContextoFinanciero(BuildContext context) async {
    try {
      final txService = Provider.of<TransactionService>(context, listen: false);
      String saldo = await txService.getBalance();
      contextoFinanciero = "CONTEXTO DEL USUARIO:\n- Saldo disponible: $saldo TTC\n";
    } catch (e) {
      contextoFinanciero = "CONTEXTO DEL USUARIO:\n- Saldo disponible: 0 TTC\n";
    }
  }

  Future<Map<String, dynamic>?> buscarBilleteraPorAlias(BuildContext context, String query) async {
    String cleanQuery = query.replaceAll("@", "").trim();
    if (cleanQuery.isEmpty) return null;
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      return await userService.searchByAlias(cleanQuery);
    } catch (e) {
      return null;
    }
  }

  Future<void> procesarMensaje({
    required BuildContext context,
    required String userText,
  }) async {
    // Agregamos globos e informamos a la UI
    messages.add({"isUser": true, "text": userText});
    messages.add({"isUser": false, "text": "Procesando de forma segura...", "isLoading": true});
    notifyListeners();

    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      String hoy = DateTime.now().toIso8601String().substring(0, 10);
      
      bool isBusiness = authCore.role == 'ROLE_BUSINESS' || authCore.role == 'ROLE_ADMIN';
      String rolUsuario = isBusiness ? "EMPRESA" : "USUARIO NORMAL";

     String contextoAccionAnterior = _lastActionData != null
          ? "MEMORIA DE LA ACCIÓN ANTERIOR (SI EL USUARIO DICE 'haz lo mismo', 'repite', 'ahora con X monto', 'a él/ella', usa estos datos de base):\n${jsonEncode(_lastActionData)}\n"
          : "";

      final String promptSistema = """
Eres el núcleo de enrutamiento de TTC Wallet. Traduce intenciones a JSON.
EL USUARIO ACTUAL TIENE EL ROL: $rolUsuario.
HOY ES: $hoy
$contextoFinanciero
$contextoAccionAnterior

REGLAS DE SEGUIMIENTO CONTEXTUAL:
- Si el usuario dice "haz lo mismo pero con 10ttc" o similar, busca en la MEMORIA DE LA ACCIÓN ANTERIOR el destinatario, tipo, motivo, etc., y reemplaza únicamente lo solicitado.

🔥 REGLAS DE EXTRACCIÓN DE DATOS (DEBES PONER ESTO DENTRO DE 'action_data'):
- "CREATE_TASK": Extrae 'task_type' (STANDARD, GPS, MEET, FORM, OPINION), 'title' (Resume de qué trata), 'description' (Genera una si el usuario no la da), 'assignee' (Alias del empleado sin el @), 'budget', 'estimated_hours', 'urgency' (Baja, Normal, Alta, Urgente), 'deadline', 'subtasks' (array).
  * 📍 Si menciona un lugar o ciudad (ej. Cuenca): Pon 'task_type' en 'GPS' y deduce aprox 'gps_lat' y 'gps_lon'.
  * 🤝 Si menciona reunión/meet: Pon 'task_type' en 'MEET'.
  * 📝 Si es encuesta: Pon 'task_type' en 'OPINION' y extrae 'opinion_question' y 'poll_options' (array).
  * 📋 Si es formulario: Pon 'task_type' en 'FORM' y extrae 'form_fields' (array).
- "SPLIT_PAYMENT": Extrae 'amount', 'reason', 'split_with' (Array), 'destination' (Alias o comercio destino).
- "CREATE_CROWDFUNDING": Extrae 'title', 'amount', 'duration_days'.
- "CREATE_VAULT": Extrae 'amount', 'vault_type', 'vault_name', 'target_amount'.

LISTA DE tx_type PERMITIDOS:
SEND, BUY, STAKE, CREATE_GROUP, ADD_TO_GROUP, REPORT, PLAN_PAYMENT, INSTALLMENT_PAYMENT, CREATE_DEBT, CREATE_DOCUMENT, CREATE_CROWDFUNDING, CREATE_BURNER, INVITE_MEMBER, CREATE_TASK, SEND_MESSAGE, SPLIT_PAYMENT, CREATE_VAULT

FORMATO DE SALIDA COMPULSORIO (NO AGREGUES TEXTO FUERA DEL JSON):
{
  "type": "ACTION",
  "message": "Mensaje amigable confirmando lo que vas a hacer...",
  "action_data": {
      "tx_type": "TIPO_DE_ACCION",
      // ... AQUÍ VAN TODOS LOS DATOS EXTRAÍDOS (assignee, title, gps_lat, etc.)
  }
}
""";

      final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
      final jsonResponse = await aiMemoryService.sendMessageWithMemory(userText, promptSistema);
      
      if (!context.mounted) return;

      // Quitamos el globo de carga
      messages.removeWhere((m) => m["isLoading"] == true);

      if (jsonResponse != null && jsonResponse.containsKey('response')) {
        final String aiResponseText = jsonResponse['response']; 
        final String cleanJsonStr = aiResponseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> aiData = jsonDecode(cleanJsonStr);
        
        messages.add({"isUser": false, "text": aiData['message'] ?? "Entendido."});
        notifyListeners();

        if (aiData['action_data'] != null) {
          Map<String, dynamic> action = Map<String, dynamic>.from(aiData['action_data']);
          if (action.containsKey('params')) action.addAll(Map<String, dynamic>.from(action['params']));
          
          String tipoTx = (action['tx_type'] ?? action['action'] ?? "").toString().toUpperCase();

          _lastActionData = action;

          if (['CREATE_TASK', 'CREATE_DEPARTMENT', 'ADD_TO_DEPARTMENT', 'INVITE_MEMBER'].contains(tipoTx) && !isBusiness) {
            messages.add({"isUser": false, "text": "Acción denegada: Solo cuentas de Empresa pueden usar esta función."});
            notifyListeners();
            return;
          }

          // =========================================================
          // ACCIONES
          // =========================================================
          if (tipoTx == 'CREATE_TASK') {
            String title = action['title'] ?? "";
           String taskType = (action['task_type'] ?? "STANDARD").toString().toUpperCase();
            if (!['STANDARD', 'GPS', 'MEET', 'FORM', 'OPINION'].contains(taskType)) {
              taskType = 'STANDARD'; // Si la IA inventa algo como "NORMAL", forzamos STANDARD
            }

            double budget = double.tryParse(action['budget']?.toString() ?? "0") ?? 0.0;
            String assigneeRaw = (action['assignee'] ?? action['recipient'] ?? "").toString().replaceAll("@", "").trim();
            List<String> subtasks = (action['subtasks'] as List?)?.map((e) => e.toString()).toList() ?? [];
            
            String hours = action['estimated_hours']?.toString() ?? "";
            
        String urgencyRaw = (action['urgency'] ?? "MEDIUM").toString().trim().toUpperCase();
            String urgency = "MEDIUM"; // Fallback maestro predeterminado (Equivale a Normal en tu UI)
            
            if (urgencyRaw.contains("BAJA") || urgencyRaw.contains("LOW")) {
              urgency = "LOW";
            } else if (urgencyRaw.contains("ALTA") || urgencyRaw.contains("HIGH")) {
              urgency = "HIGH";
            } else if (urgencyRaw.contains("URGENTE") || urgencyRaw.contains("URGENT") || urgencyRaw.contains("ASAP")) {
              urgency = "URGENT";
            }
            String desc = action['description'] ?? "";
            String deadline = action['deadline']?.toString() ?? "";
            
            double? lat = double.tryParse(action['gps_lat']?.toString() ?? "");
            double? lon = double.tryParse(action['gps_lon']?.toString() ?? "");
            String meetUrl = action['meet_url']?.toString() ?? "";
            String question = action['opinion_question']?.toString() ?? "";
            List<String> polls = (action['poll_options'] as List?)?.map((e) => e.toString()).toList() ?? [];
            List<String> forms = (action['form_fields'] as List?)?.map((e) => e.toString()).toList() ?? [];

            final bService = Provider.of<BusinessService>(context, listen: false);
            final userService = Provider.of<UserService>(context, listen: false);
            List<dynamic> activeTeam = []; 
            List<dynamic> departments = [];
            
            try { 
              activeTeam = (await bService.getTeamMembers()).map((e) => Map<String, dynamic>.from(e)).toList();
              departments = (await bService.getDepartments()).map((e) => Map<String, dynamic>.from(e)).toList();

              for (int i = 0; i < activeTeam.length; i++) {
                String? w = activeTeam[i]['identifier']?.toString() ?? activeTeam[i]['wallet']?.toString();
                if (w != null) {
                  var userData = await userService.getUserByWallet(w);
                  if (userData != null && userData['alias'] != null) {
                    activeTeam[i]['alias'] = userData['alias'];
                  }
                }
              }
            } catch(e) {}
            
            CreateTaskModal.show(
              context, activeTeam, departments, () {}, 
              initialTitle: title, initialDescription: desc, initialAssigneeAlias: assigneeRaw, 
              initialTaskType: taskType, initialBudget: budget, initialSubtasks: subtasks,
              initialHours: hours, initialUrgency: urgency, initialDeadline: deadline,
              initialGpsLat: lat, initialGpsLon: lon, initialMeetUrl: meetUrl, 
              initialOpinionQuestion: question, initialPollOptions: polls, initialFormFields: forms
            );
          }
          else if (tipoTx == 'ADD_TO_GROUP') {
            String groupName = (action['group_name'] ?? "").toString();
            String alias = (action['member_alias'] ?? action['recipient'] ?? "").toString().replaceAll("@", "").trim();
            final destino = await buscarBilleteraPorAlias(context, alias);
            
            if (destino != null) {
              final groupService = Provider.of<GroupSocialService>(context, listen: false);
              List<dynamic> myGroups = await groupService.getUserGroups();
              var group = myGroups.firstWhere((g) => g['name'].toString().toLowerCase() == groupName.toLowerCase(), orElse: () => null);
              
              if (group != null) {
                String walletDestino = destino['contactAddress'] ?? destino['walletAddress'] ?? destino['wallet'] ?? destino['identifier'] ?? "";
                String res = await groupService.addGroupMember(group['id'], walletDestino, destino['alias']);
                messages.add({"isUser": false, "text": res == "SUCCESS" ? "Añadí a @$alias al grupo $groupName." : "Error: $res"});
              } else {
                messages.add({"isUser": false, "text": "No tienes un grupo llamado '$groupName'."});
              }
            } else {
              messages.add({"isUser": false, "text": "Usuario @$alias no encontrado."});
            }
            notifyListeners();
          }
          else if (tipoTx == 'REPORT') {
            final txService = Provider.of<TransactionService>(context, listen: false);
            List<dynamic> historial = await txService.getTransactionHistory();
            String? startStr = action['start_date'] ?? action['date'];
            String? endStr = action['end_date'] ?? action['date'];

            if (startStr != null) {
              historial = historial.where((tx) {
                String txD = tx['timestamp'].toString().substring(0, 10);
                return txD.compareTo(startStr) >= 0 && txD.compareTo(endStr ?? startStr) <= 0;
              }).toList();
            }

            if (historial.isEmpty) {
              messages.add({"isUser": false, "text": "No hay transacciones en esas fechas."});
              notifyListeners();
              return;
            }
            await ShareHelper.generarYCompartirPDFHistory(context, historial, authCore.publicAddress);
          }
          else if (tipoTx == 'CREATE_VAULT') {
            double monto = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            String vType = (action['vault_type'] ?? action['type'] ?? "flexible").toString().toUpperCase();
            String vName = (action['vault_name'] ?? action['name'] ?? "").toString();
            String vTarget = (action['target_amount'] ?? "").toString();
            String vAuto = (action['auto_save_amount'] ?? "").toString();
            String vFreq = (action['auto_save_frequency'] ?? "NONE").toString().toUpperCase();
            int vDuration = int.tryParse(action['duration_months']?.toString() ?? "6") ?? 6;

            CreateVaultModal.show(context: context, onCreated: () {}, initialAmount: monto > 0 ? monto.toString() : null, initialType: vType, initialName: vName, initialTargetAmount: vTarget, initialAutoSave: vAuto, initialFrequency: vFreq, initialDurationMonths: vDuration);
          } else if (tipoTx == 'CREATE_CROWDFUNDING') {
            String uchaName = (action['title'] ?? action['group_name'] ?? "Nueva Campaña").toString();
            double meta = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            String duration = (action['duration_days'] ?? "30").toString();
            CreateCrowdfundingModal.show(context: context, initialTitle: uchaName, initialTargetAmount: meta > 0 ? meta.toString() : null, initialDurationDays: duration, onSuccess: () {}, initialRegion: '', initialLat: 0, initialLon: 0);
          } else if (tipoTx == 'CREATE_BURNER') {
            double fondeo = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            String name = (action['name'] ?? action['label'] ?? "").toString();
            CreateBurnerModal.show(context: context, initialFundingAmount: fondeo > 0 ? fondeo.toString() : null, initialLabel: name, onSuccess: () {});
          } else if (tipoTx == 'CREATE_DOCUMENT') {
            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png']);
            if (result != null && result.files.single.path != null) {
              File file = File(result.files.single.path!);
              List<int> fileBytes = await file.readAsBytes();
              Digest docHash = sha256.convert(fileBytes);
              String hashCompleto = "0x${docHash.toString()}";
              CreateDocumentModal.show(context: context, fileHash: hashCompleto, onConfirm: (titulo, firmantes) async {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Registrando", message: "Inscribiendo en blockchain..."));
                final notaryService = Provider.of<NotaryService>(context, listen: false);
                String res = await notaryService.createDocumentDelegated(hashCompleto, titulo, "ipfs://Mock", firmantes);
                Navigator.pop(context); 
                messages.add({"isUser": false, "text": res.startsWith("Exito") ? "Contrato registrado." : "Error: $res"});
                notifyListeners();
              });
            }
          } else if (tipoTx == 'BUY') {
            BuyModal.show(context: context, initialAmount: action['amount']?.toString(), onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
          } else if (tipoTx == 'STAKE') {
            final txService = Provider.of<TransactionService>(context, listen: false);
            final vaultService = Provider.of<SmartVaultService>(context, listen: false);
            String saldoReal = await txService.getBalance();
            String stakedReal = await vaultService.getStakedBalance();
            StakeModal.show(context: context, balanceTTC: saldoReal, stakedTTC: stakedReal, initialAmount: action['amount']?.toString(), onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
          } else if (tipoTx == 'CREATE_GROUP') { 
            await _ejecutarCreacionDeGrupoPorIA(context, (action['group_name'] ?? "Nuevo Fondo").toString(), action['members'] ?? []);
          }

          // =========================================================
          // FLUJOS CON DESTINATARIO
          // =========================================================
          if (['PLAN_PAYMENT', 'INSTALLMENT_PAYMENT', 'CREATE_DEBT', 'SEND', 'SEND_MESSAGE', 'SPLIT_PAYMENT'].contains(tipoTx)) {
            String rawRecipient = (action['assignee'] ?? action['recipient'] ?? action['to'] ?? action['creditor'] ?? action['debtor'] ?? "").toString().trim();
            double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            String reason = (action['reason'] ?? action['note'] ?? "").toString();
            
            if (rawRecipient.isNotEmpty && !rawRecipient.startsWith('0x') && !rawRecipient.startsWith('@')) rawRecipient = "@$rawRecipient";

            if (rawRecipient.isEmpty && tipoTx != 'SPLIT_PAYMENT') {
              messages.add({"isUser": false, "text": "¿A quién debo dirigir esto? Especifica el alias."});
              notifyListeners();
              return;
            }

            final destino = rawRecipient.isNotEmpty ? await buscarBilleteraPorAlias(context, rawRecipient) : null;
            if (destino == null && tipoTx != 'SPLIT_PAYMENT') {
              messages.add({"isUser": false, "text": "No encontré al usuario '$rawRecipient'."});
              notifyListeners();
              return;
            }

            String walletReal = destino?['walletAddress'] ?? destino?['contactAddress'] ?? destino?['wallet'] ?? destino?['identifier'] ?? "";

            if (tipoTx == 'SEND_MESSAGE') {
              String textoMsj = (action['message'] ?? action['content'] ?? "").toString();
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(address: walletReal, alias: destino!['alias']!, initialMessage: textoMsj)));
            } else if (tipoTx == 'SPLIT_PAYMENT') {
              List<String> splitters = [];
              if (action['split_with'] is List) {
                splitters.addAll((action['split_with'] as List).map((e) => e.toString()));
              } else if (action['split_with'] is String) {
                splitters.addAll(action['split_with'].toString().split(','));
              }
              if (rawRecipient.isNotEmpty) splitters.add(rawRecipient);

              List<Map<String, String>> resolvedSplitters = [];
              for (String s in splitters) {
                String cleanAlias = s.replaceAll('@', '').trim();
                if (cleanAlias.isEmpty) continue;
                final d = await buscarBilleteraPorAlias(context, cleanAlias);
                if (d != null) {
                  String w = (d['walletAddress'] ?? d['contactAddress'] ?? d['wallet'] ?? d['identifier'] ?? '').toString();
                  if (w.isNotEmpty && w.toLowerCase() != authCore.publicAddress.toLowerCase() && !resolvedSplitters.any((e) => e['wallet'] == w)) {
                    resolvedSplitters.add({"alias": d['alias']?.toString() ?? cleanAlias, "wallet": w});
                  }
                }
              }
              Navigator.push(context, RouteHelper.slideUpRoute(SplitBillScreen(
                onBillSplitSuccess: () {},
                initialAmount: montoReq > 0 ? montoReq.toString() : null,
                initialReason: reason,
                initialDestination: action['destination']?.toString(),
                initialParticipants: resolvedSplitters,
              )));
            } else if (tipoTx == 'PLAN_PAYMENT') {
              PlanPaymentModal.show(context: context, aliasDestino: destino!['alias']!, addressDestino: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason);
            } else if (tipoTx == 'INSTALLMENT_PAYMENT') {
              InstallmentsModal.show(context: context, aliasDestino: destino!['alias']!, addressDestino: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason, initialFrequency: action['frequency']?.toString(), initialInstallments: action['installments']?.toString());
            } else if (tipoTx == 'CREATE_DEBT') {
              CreateDebtModal.show(context: context, onSuccess: () {}, mostrarMensaje: (m, {bool esError=false}) {}, initialAlias: "@${destino!['alias']}", initialWallet: walletReal, initialAmount: montoReq > 0 ? montoReq.toString() : null, initialReason: reason);
            } else if (tipoTx == 'SEND') {
              String saldoRealStr = await Provider.of<TransactionService>(context, listen: false).getBalance();
              SendModal.show(context: context, balanceTTC: saldoRealStr, initialAddress: "@${destino!['alias']}", initialAmount: montoReq > 0 ? montoReq.toString() : null, onUpdateBalance: () {}, mostrarMensaje: (m, {bool esError=false}) {});
            }
          }
        }
      } else {
        messages.add({"isUser": false, "text": "Disculpa, el nodo de IA no devolvió una estructura comprensible."});
        notifyListeners();
      }
    } catch (e) {
      messages.removeWhere((m) => m["isLoading"] == true);
      messages.add({"isUser": false, "text": "Ups, tuve un error de conexión con el servidor IA."});
      notifyListeners();
    }
  }

  Future<void> _ejecutarCreacionDeGrupoPorIA(BuildContext context, String groupName, List<dynamic> aliases) async {
    List<Map<String, dynamic>> miembrosConfirmados = [];
    if (aliases.isNotEmpty) {
      for (String alias in aliases) {
        final data = await buscarBilleteraPorAlias(context, alias);
        if (data != null) miembrosConfirmados.add(data);
      }
    }
    final groupService = Provider.of<GroupSocialService>(context, listen: false);
    String resultado = await groupService.createGroup(groupName, "Admin", miembrosConfirmados);
    messages.add({"isUser": false, "text": resultado == "SUCCESS" ? "Fondo común '$groupName' creado con éxito." : "Error: $resultado"});
    notifyListeners();
  }
}