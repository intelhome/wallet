import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/PremiumBlockerModal.dart';
import 'package:dapp_movil/modules/business/modals/create_department_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/split_bill_modal.dart';
import 'package:dapp_movil/modules/vaults_and_savings/modals/create_vault_modal.dart';
import 'package:dapp_movil/modules/vaults_and_savings/screens/stake_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/buy_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
import '../../vaults_and_savings/screens/vaults_screen.dart';
import '../../vaults_and_savings/services/smart_vault_service.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../wallet_and_tx/modals/send_paypal_modal.dart';
import '../../wallet_and_tx/services/transaction_service.dart';
import 'ai_memory_service.dart';

class AiChatHandler extends ChangeNotifier {
  String contextoFinanciero = "";
  
  // 🔥 MEMORIA DE CORTO PLAZO PARA COMANDOS RELATIVOS
  Map<String, dynamic>? _lastActionData;

  // 🔥 LA LISTA DE MENSAJES AHORA VIVE AQUÍ Y ES PERSISTENTE
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

      // 🔥 INYECCIÓN DE MEMORIA DE LA ACCIÓN ANTERIOR DIRECTO AL PROMPT SISTEMA
     String contextoAccionAnterior = _lastActionData != null
          ? "MEMORIA DE LA ACCIÓN ANTERIOR (SI EL USUARIO DICE 'haz lo mismo', 'repite', 'ahora con X monto', 'a él/ella', usa estos datos de base):\n${jsonEncode(_lastActionData)}\n"
          : "";

//    final String promptSistema = """
// Eres el núcleo de enrutamiento de TTC Wallet. Tu propósito es ejecutar acciones dentro de la aplicación basándote en la petición del usuario, o responder cordialmente si no se requiere ninguna acción.
// NO ERES un asesor financiero general. NO ERES un conversador casual extenso. NO DEBES mencionar criptomonedas externas (Ethereum, Bitcoin, etc.), exchanges, ni redes ajenas a TTC.

// EL USUARIO ACTUAL TIENE EL ROL: $rolUsuario.
// HOY ES: $hoy
// $contextoFinanciero
// $contextoAccionAnterior

// REGLAS DE SEGUIMIENTO CONTEXTUAL:
// - Si el usuario pide repetir o modificar la acción anterior (ej. "haz lo mismo pero con 10ttc"), busca en la MEMORIA DE LA ACCIÓN ANTERIOR y reemplaza ÚNICAMENTE el dato solicitado.

// 🔥 REGLAS PARA CUANDO NO HAY ACCIÓN QUE EJECUTAR (¡MUY IMPORTANTE!):
// Si el usuario dice su nombre, saluda, hace una pregunta general que no requiere transferir, crear tareas, ni nada que esté en la lista de tx_type permitidos, DEBES responder con formato "MESSAGE". No inventes acciones.

// 🔥 REGLAS DE EXTRACCIÓN DE DATOS (DENTRO DE 'action_data'):
// - "CREATE_TASK": Extrae 'task_type' (STANDARD, GPS, MEET, FORM, OPINION), 'title' (Resumen), 'description', 'assignee' (Alias SIN '@'), 'budget', 'estimated_hours', 'urgency' (BAJA, NORMAL, ALTA, URGENTE), 'deadline', 'subtasks' (array).
//   * Lugar/ciudad: 'task_type' -> 'GPS', deduce 'gps_lat' y 'gps_lon'.
//   * Reunión: 'task_type' -> 'MEET'.
//   * Encuesta: 'task_type' -> 'OPINION', extrae 'opinion_question' y 'poll_options'.
//   * Formulario: 'task_type' -> 'FORM', extrae 'form_fields'.
// - "SPLIT_PAYMENT": Extrae 'amount', 'reason', 'split_with' (Array), 'destination'.
// - "CREATE_CROWDFUNDING": Extrae 'title', 'amount', 'duration_days'.
// - "CREATE_VAULT": Extrae 'amount', 'vault_type', 'vault_name', 'target_amount'.

// LISTA ESTRICTA DE tx_type PERMITIDOS:
// SEND, BUY, STAKE, CREATE_GROUP, ADD_TO_GROUP, REPORT, PLAN_PAYMENT, INSTALLMENT_PAYMENT, CREATE_DEBT, CREATE_DOCUMENT, CREATE_CROWDFUNDING, CREATE_BURNER, INVITE_MEMBER, CREATE_TASK, SEND_MESSAGE, SPLIT_PAYMENT, CREATE_VAULT

// FORMATO DE SALIDA OBLIGATORIO (SOLO JSON, NADA DE TEXTO ADICIONAL):
// Si SE REQUIERE una acción financiera o corporativa:
// {
//   "type": "ACTION",
//   "message": "Un mensaje BREVE y directo confirmando la acción a realizar.",
//   "action_data": {
//       "tx_type": "TIPO_DE_ACCION",
//       // ... Datos extraídos según la acción
//   }
// }
// Si NO SE REQUIERE ninguna acción (Ej. charla, saludos, decir su nombre):
// {
//   "type": "MESSAGE",
//   "message": "Tu respuesta corta y amigable al usuario."
// }
// """;


final String promptSistema = """
Eres el núcleo de enrutamiento de TTC Wallet. Tu propósito es ejecutar acciones dentro de la aplicación basándote en la petición del usuario, o responder cordialmente si no se requiere ninguna acción.
NO ERES un asesor financiero general. NO ERES un conversador casual extenso. NO DEBES mencionar criptomonedas externas (Ethereum, Bitcoin, etc.), exchanges, ni redes ajenas a TTC.

EL USUARIO ACTUAL TIENE EL ROL: $rolUsuario.
HOY ES: $hoy
$contextoFinanciero
$contextoAccionAnterior

REGLAS DE SEGUIMIENTO CONTEXTUAL:
- Si el usuario pide repetir o modificar la acción anterior (ej. "haz lo mismo pero con 10ttc"), busca en la MEMORIA DE LA ACCIÓN ANTERIOR y reemplaza ÚNICAMENTE el dato solicitado.

🔥 REGLAS DE VALIDACIÓN DE DATOS (FALTAN DATOS OBLIGATORIOS):
Si el usuario solicita una acción pero NO proporciona la información MÍNIMA obligatoria (quién, cuánto, qué), ESTÁ ESTRICTAMENTE PROHIBIDO generar una acción. Responde ÚNICAMENTE con formato "MESSAGE" pidiendo la información exacta y dándole un ejemplo claro.
EJEMPLOS DE CÓMO DEBES RESPONDER SI FALTAN DATOS:
- SEND / PAY / CREATE_DEBT: "No me has enviado los datos necesarios. Envíame algo como: 'Realiza un envío a usuario(alias de tu contacto) de 30 TTC(cantidad a enviar)'."
- CREATE_TASK: "No me has enviado los datos necesarios. Envíame algo como: 'Crea una tarea para (alias) con presupuesto de 50 TTC(cantidad)'."
- SPLIT_PAYMENT: "Faltan datos para dividir la cuenta. Envíame algo como: 'Divide 100 TTC(cantidad) de la cena con (alias 1) y (alias 2)'."
- CREATE_VAULT: "Faltan datos para tu bolsillo. Envíame algo como: 'Crea una ucha flexible llamada Viaje(nombre) con 50 TTC(cantidad)'."
- PLAN_PAYMENT / INSTALLMENT_PAYMENT: "Faltan datos para programar. Envíame algo como: 'Programa un pago a (alias) de 50 TTC(cantidad)'."

🔥 REGLAS PARA CUANDO NO HAY ACCIÓN QUE EJECUTAR:
Si el usuario saluda, hace una pregunta general o FALTAN DATOS para una acción (como se indicó arriba), DEBES responder con formato "MESSAGE". No inventes acciones.

🔥 REGLAS DE EXTRACCIÓN DE DATOS (DENTRO DE 'action_data'):
- "CREATE_TASK": Extrae 'task_type' (STANDARD, GPS, MEET, FORM, OPINION), 'title' (Resumen), 'description', 'assignee' (Alias SIN '@'), 'budget', 'estimated_hours', 'urgency' (BAJA, NORMAL, ALTA, URGENTE), 'deadline', 'subtasks' (array).
  * Lugar/ciudad: 'task_type' -> 'GPS', deduce 'gps_lat' y 'gps_lon'.
  * Reunión: 'task_type' -> 'MEET'.
  * Encuesta: 'task_type' -> 'OPINION', extrae 'opinion_question' y 'poll_options'.
  * Formulario: 'task_type' -> 'FORM', extrae 'form_fields'.
- "SPLIT_PAYMENT": Extrae 'amount', 'reason', 'split_with' (Array), 'destination'.
- "CREATE_CROWDFUNDING": Extrae 'title', 'amount', 'duration_days'.
- "CREATE_VAULT": Extrae 'amount', 'vault_type', 'vault_name', 'target_amount'.

LISTA ESTRICTA DE tx_type PERMITIDOS:
SEND, BUY, STAKE, CREATE_GROUP, ADD_TO_GROUP, REPORT, PLAN_PAYMENT, INSTALLMENT_PAYMENT, CREATE_DEBT, CREATE_DOCUMENT, CREATE_CROWDFUNDING, CREATE_BURNER, INVITE_MEMBER, CREATE_TASK, SEND_MESSAGE, SPLIT_PAYMENT, CREATE_VAULT

FORMATO DE SALIDA OBLIGATORIO (SOLO JSON, NADA DE TEXTO ADICIONAL):
Si SE REQUIERE una acción financiera o corporativa Y ESTÁN TODOS LOS DATOS COMPLETOS:
{
  "type": "ACTION",
  "message": "Un mensaje BREVE y directo confirmando la acción a realizar.",
  "action_data": {
      "tx_type": "TIPO_DE_ACCION",
      // ... Datos extraídos según la acción
  }
}
Si NO SE REQUIERE ninguna acción O FALTAN DATOS (Ej. charla, saludos o error de validación):
{
  "type": "MESSAGE",
  "message": "Tu respuesta corta indicando lo que falta y el ejemplo de cómo pedirlo, o el saludo correspondiente."
}
""";

      // final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
      // final jsonResponse = await aiMemoryService.sendMessageWithMemory(userText, promptSistema);

      final aiMemoryService = Provider.of<AiMemoryService>(context, listen: false);
      
      // Creamos una copia del historial SIN el último globo de "Procesando..." para no ensuciar la IA
      final historialParaIA = messages.where((m) => m["isLoading"] != true).toList();

      final jsonResponse = await aiMemoryService.sendMessageWithMemory(
        userText, 
        promptSistema,
        history: historialParaIA 
      );

      
      if (!context.mounted) return;

      // Quitamos el globo de carga
      messages.removeWhere((m) => m["isLoading"] == true);

   if (jsonResponse != null) {
 
        if (jsonResponse.containsKey('error') && jsonResponse['error'] == 'QUOTA_EXCEEDED') {
          messages.add({"isUser": false, "text": "Has alcanzado tu límite de consultas IA. Mejora tu plan para seguir chateando."});
          notifyListeners();
          PremiumBlockerModal.show(context, planRequerido: "BASIC", featureName: "Más consultas IA");
          return;
        }

        if (jsonResponse.containsKey('response')) {
          final String aiResponseText = jsonResponse['response']; 
          final String cleanJsonStr = aiResponseText.replaceAll('```json', '').replaceAll('```', '').trim();
          final Map<String, dynamic> aiData = jsonDecode(cleanJsonStr);
          
          messages.add({"isUser": false, "text": aiData['message'] ?? "Entendido."});
          notifyListeners();

        if (aiData['action_data'] != null) {
          Map<String, dynamic> action = Map<String, dynamic>.from(aiData['action_data']);
          if (action.containsKey('params')) action.addAll(Map<String, dynamic>.from(action['params']));
          
          String tipoTx = (action['tx_type'] ?? action['action'] ?? "").toString().toUpperCase();

          // 🔥 GUARDAMOS LA ACCIÓN EXITOSA EN LA MEMORIA DE LARGO PLAZO DE ESTA SESIÓN
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
            
            // 🔥 FIX: ESCUDO ANTI-ALUCINACIONES PARA EL DROPDOWN DE URGENCIA
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
            Navigator.push(
              context,
              RouteHelper.slideUpRoute(
                BuyScreen(
                  initialAmount: action['amount']?.toString(),
                  onUpdateBalance: () {},
                  mostrarMensaje: (m, {bool esError = false}) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m), backgroundColor: esError ? Colors.red : Colors.green)
                    );
                  },
                )
              )
            );
          } else if (tipoTx == 'STAKE') {
            final txService = Provider.of<TransactionService>(context, listen: false);
            final vaultService = Provider.of<SmartVaultService>(context, listen: false);
            String saldoReal = await txService.getBalance();
            String stakedReal = await vaultService.getStakedBalance();
            
            Navigator.push(
              context,
              RouteHelper.slideUpRoute(
                StakeScreen(
                  balanceTTC: saldoReal,
                  stakedTTC: stakedReal,
                  initialAmount: action['amount']?.toString(),
                  onUpdateBalance: () {},
                  mostrarMensaje: (m, {bool esError = false}) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m), backgroundColor: esError ? Colors.red : Colors.green)
                    );
                  },
                )
              )
            );
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