import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/create_debt_modal.dart';
import 'package:dapp_movil/modules/document_notary/modals/create_document_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/installments_modal.dart';
import 'package:dapp_movil/modules/debts_and_payments/modals/plan_payment_modal.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../wallet_and_tx/modals/send_modal.dart';
import '../../wallet_and_tx/modals/buy_modal.dart';
import '../../../config/api_config.dart';
import '../../../core/helpers/share_helper.dart'; 
import '../../vaults_and_savings/modals/stake_modal.dart';

class AiAssistantScreen extends StatefulWidget {

  
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {

 final TextEditingController _msgController = TextEditingController();
  static final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "¡Hola! Soy tu Asistente. Puedo preparar envíos, programar pagos a cuotas, cobrar deudas o redactar contratos en la Notaría. ¿Qué haremos hoy?"
    }
  ];

  String _contextoFinanciero = "";

  @override
  void initState() {
    super.initState();
   WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarContextoFinanciero();
    });
  }

  Future<void> _cargarContextoFinanciero() async {
    try {

      final txService = Provider.of<TransactionService>(context, listen: false);
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      
     String saldo = await txService.getBalance();
      List<dynamic> historial = await txService.getTransactionHistory();
      String ultimasTxs = "Ninguna";
      
      if (historial.isNotEmpty) {
         ultimasTxs = historial.take(3).map((tx) {
           bool esIngreso = tx['receiverAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
           String signo = esIngreso ? "+" : "-";
           return "${tx['txType']} $signo${tx['amount']} TTC";
         }).join(", ");
      }
      
      if (mounted) {
        setState(() {
          _contextoFinanciero = "DATOS EN TIEMPO REAL DEL USUARIO:\n- Saldo disponible: $saldo TTC\n- Últimas 3 transacciones: $ultimasTxs";
        });
      }
    } catch (e) {
      print("Error cargando contexto RAG: $e");
    }
  }

  Future<Map<String, String>?> _buscarBilleteraPorAlias(String aliasCrudo) async {
    String query = aliasCrudo.replaceAll("@", "").trim();
    if (query.isEmpty) return null;
    
    // Si ya envió una dirección completa (0x...)
    if (query.startsWith("0x") && query.length == 42) {
      return {"alias": query, "walletAddress": query};
    }

    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      final res = await http.get(Uri.parse(ApiConfig.searchAlias.replaceAll("{alias}", query)), headers: {
        "Content-Type": "application/json",
        if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
      });

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        Map<String, dynamic>? usuarioEncontrado;
        
        if (decoded is List && decoded.isNotEmpty) usuarioEncontrado = decoded.first;
        else if (decoded is Map<String, dynamic>) usuarioEncontrado = decoded;

        if (usuarioEncontrado != null) {
          return {
            "alias": usuarioEncontrado['alias'].toString(),
            "walletAddress": usuarioEncontrado['walletAddress'].toString().toLowerCase()
          };
        }
      }
    } catch (e) {
      print("Fallo al buscar alias: $e");
    }
    return null;
  }

  Future<void> _sendMessage() async {
    String userText = _msgController.text.trim();
    if (userText.isEmpty) return;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    setState(() {
      _messages.add({"isUser": true, "text": userText});
      _msgController.clear();
      _messages.add({"isUser": false, "text": "Procesando...", "isLoading": true});
    });

    try {
      final apiKey = '';
      final url = '';

      final String promptSistema = """
Eres el Asistente TTC. $_contextoFinanciero
Responde SIEMPRE en un JSON estrictamente estructurado sin usar formato markdown.

Estructura obligatoria:
{
  "type": "CHAT" o "ACTION",
  "message": "Tu respuesta corta de 1 o 2 oraciones",
  "action_data": {
      "tx_type": "SEND" o "BUY" o "CREATE_GROUP" o "STAKE" o "REPORT" o "PLAN_PAYMENT" o "INSTALLMENT_PAYMENT" o "CREATE_DEBT" o "CREATE_DOCUMENT",
      "amount": (número decimal o null),
      "recipient": "alias o null",
      "group_name": "nombre del grupo o null",
      "members": ["alias1"] o null,
      "report_format": "PDF" o "CSV" o null,
      "report_filter": "EXPENSE" o "INCOME" o "ALL" o null,
      "report_date": "YYYY-MM-DD" o null
  }
}
REGLAS DE NUEVAS ACCIONES:
- PLAN_PAYMENT: Programar pago para un día específico (extrae amount y recipient).
- INSTALLMENT_PAYMENT: Pagar a cuotas/suscripción (extrae amount y recipient).
- CREATE_DEBT: Cobrar dinero o crear una deuda a alguien (extrae amount y recipient).
- CREATE_DOCUMENT: Para crear un contrato en la notaría (no requiere datos extra).
""";

      List<Map<String, dynamic>> historialGemini = [];
      String lastRole = "";
      
      var mensajesValidos = _messages.where((m) => m["isLoading"] != true).toList();
      if (mensajesValidos.length > 10) mensajesValidos = mensajesValidos.sublist(mensajesValidos.length - 10);

      for (var msg in mensajesValidos) {
        String role = msg["isUser"] == true ? "user" : "model";
        if (historialGemini.isEmpty && role == "model") continue; 
        if (role == lastRole) {
          historialGemini.last["parts"][0]["text"] += "\n" + msg["text"]; 
        } else {
          historialGemini.add({ "role": role, "parts": [{"text": msg["text"]}] });
          lastRole = role;
        }
      }

      final requestBody = jsonEncode({
        "systemInstruction": { "parts": [{"text": promptSistema}] },
        "contents": historialGemini, 
        "generationConfig": { "responseMimeType": "application/json" }
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String aiResponseText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> aiData = jsonDecode(aiResponseText);
        
        setState(() {
          _messages.removeWhere((msg) => msg["isLoading"] == true);
          _messages.add({
            "isUser": false, 
            "text": aiData['message'] ?? "No entendí bien.", 
          });
        });

        if (aiData['type'] == 'ACTION' && aiData['action_data'] != null) {
          final action = aiData['action_data'];
          String tipoTx = action['tx_type'];
          
          // ----------------------------------------------------
         
          // (Planificados, Cuotas, Cobros y Envíos normales)
          // ----------------------------------------------------
          if (tipoTx == 'PLAN_PAYMENT' || tipoTx == 'INSTALLMENT_PAYMENT' || tipoTx == 'CREATE_DEBT' || tipoTx == 'SEND') {
            
            String rawRecipient = action['recipient']?.toString().trim() ?? "";
            double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;
            
            if (rawRecipient.isEmpty) {
              setState(() => _messages.add({"isUser": false, "text": "¿A quién debo dirigir esto? Por favor especifica el alias."}));
              return;
            }

            // Buscamos la billetera real en MongoDB
            final destino = await _buscarBilleteraPorAlias(rawRecipient);
            
            if (destino == null) {
              setState(() => _messages.add({"isUser": false, "text": "No pude encontrar al usuario '$rawRecipient' en el sistema."}));
              return;
            }

            if (!mounted) return;

            if (tipoTx == 'PLAN_PAYMENT') {
              PlanPaymentModal.show(context: context, aliasDestino: destino['alias']!, addressDestino: destino['walletAddress']!);
            } 
            else if (tipoTx == 'INSTALLMENT_PAYMENT') {
              InstallmentsModal.show(context: context, aliasDestino: destino['alias']!, addressDestino: destino['walletAddress']!);
            } 
            else if (tipoTx == 'CREATE_DEBT') {
              CreateDebtModal.show(
                context: context, 
                onSuccess: () {}, // Vacío porque estamos en el chat
                mostrarMensaje: (msg, {bool esError = false}) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green));
                }
              );
            } 
            else if (tipoTx == 'SEND') {
              final txService = Provider.of<TransactionService>(context, listen: false);
              String saldoRealStr = await txService.getBalance();
              double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;

              if (montoReq > saldoReal) {
                double faltante = montoReq - saldoReal;
                setState(() => _messages.add({"isUser": false, "text": "Tu saldo es insuficiente. Te abriré la pasarela para comprar los ${faltante.toStringAsFixed(2)} TTC que te faltan."}));
                BuyModal.show(context: context, initialAmount: faltante.toStringAsFixed(2), onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
              } else {
                SendModal.show(
                  context: context, balanceTTC: saldoRealStr, 
                  initialAddress: "@${destino['alias']}", initialAmount: montoReq > 0 ? montoReq.toString() : null, 
                  onUpdateBalance: () {}, 
                  mostrarMensaje: (msg, {bool esError = false}) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green));
                  },
                );
              }
            }
          }
          
          // ----------------------------------------------------
          //  BLOQUE 2: NOTARÍA BLOCKCHAIN (Generación de Documentos)
          // ----------------------------------------------------
          else if (tipoTx == 'CREATE_DOCUMENT') {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'], 
            );

            if (result != null && result.files.single.path != null) {
              File file = File(result.files.single.path!);
              List<int> fileBytes = await file.readAsBytes();
              Digest docHash = sha256.convert(fileBytes);
              String hashCompleto = "0x${docHash.toString()}";

              if (mounted) {
                CreateDocumentModal.show(
                  context: context, 
                  fileHash: hashCompleto, 
                  //service: widget.service, 
                  onConfirm: (titulo, firmantes) async {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Registrando Contrato", message: "Inscribiendo huella criptográfica..."));
                    
                    // Aquí asumimos IPFS si lo configuraste, o mock
                    String urlMock = "ipfs://QmMockHash"; 
                    final notaryService = Provider.of<NotaryService>(context, listen: false);
                    String res = await notaryService.createDocumentDelegated(hashCompleto, titulo, urlMock, firmantes);
                    
                    Navigator.pop(context); // Cierra skeleton
                    
                    if (res.startsWith("Exito")) {
                      setState(() => _messages.add({"isUser": false, "text": "¡El contrato '$titulo' fue registrado en la Notaría exitosamente!"}));
                    } else {
                      setState(() => _messages.add({"isUser": false, "text": "Hubo un error al registrar: $res"}));
                    }
                  }
                );
              }
            } else {
              setState(() => _messages.add({"isUser": false, "text": "Cancelaste la selección del documento."}));
            }
          }

          // ----------------------------------------------------
          //  BLOQUE 3: EL RESTO (Staking, Reportes, Grupos, Compra)
          // ----------------------------------------------------
          else if (tipoTx == 'BUY') {
            BuyModal.show(context: context, initialAmount: action['amount']?.toString() ?? "", onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
          }
          else if (tipoTx == 'STAKE') {
            final txService = Provider.of<TransactionService>(context, listen: false);
            final vaultService = Provider.of<SmartVaultService>(context, listen: false);
            
          String saldoRealStr = await txService.getBalance();
            double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;
            double montoReq = double.tryParse(action['amount']?.toString() ?? "0") ?? 0.0;

            if (montoReq > saldoReal) {
              double faltante = montoReq - saldoReal;
              setState(() => _messages.add({"isUser": false, "text": "Fondos insuficientes para Stake. Adquiere los ${faltante.toStringAsFixed(2)} TTC faltantes."}));
              BuyModal.show(context: context, initialAmount: faltante.toStringAsFixed(2), onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
            } else {
              String stakedRealStr = await vaultService.getStakedBalance();
              if (!mounted) return;
              StakeModal.show(context: context, balanceTTC: saldoRealStr, stakedTTC: stakedRealStr, initialAmount: action['amount']?.toString(), onUpdateBalance: () {}, mostrarMensaje: (msg, {bool esError = false}) {});
            }
          }
          else if (tipoTx == 'REPORT') {
            final txService = Provider.of<TransactionService>(context, listen: false);
            final authCore = Provider.of<AuthCoreService>(context, listen: false);
            String formato = action['report_format'] ?? "PDF";
            String filtro = action['report_filter'] ?? "ALL";
            String? fechaStr = action['report_date']; 
            
          List<dynamic> historial = await txService.getTransactionHistory();
            String miBilletera = authCore.publicAddress.toLowerCase();

            if (fechaStr != null && fechaStr.isNotEmpty) {
              historial = historial.where((tx) {
                String txDate = tx['timestamp']?.toString().substring(0, 10) ?? "";
                return txDate == fechaStr;
              }).toList();
            }

            if (filtro == "INCOME") {
              historial = historial.where((tx) => tx['receiverAddress'].toString().toLowerCase() == miBilletera).toList();
            } else if (filtro == "EXPENSE") {
              historial = historial.where((tx) => tx['senderAddress'].toString().toLowerCase() == miBilletera && tx['receiverAddress'].toString().toLowerCase() != miBilletera).toList();
            }

            if (historial.isEmpty) {
              setState(() => _messages.add({"isUser": false, "text": "No encontré transacciones para esos filtros."}));
              return;
            }

            if (formato == "CSV") {
              await ShareHelper.exportarHistorialCSV(context, historial, authCore.publicAddress);
            } else {
              await ShareHelper.generarYCompartirPDFHistory(context, historial, authCore.publicAddress);
            }
          }
          else if (tipoTx == 'CREATE_GROUP') {
            String groupName = action['group_name'] ?? "Nuevo Grupo";
            List<dynamic> membersAliases = action['members'] ?? [];
            _ejecutarCreacionDeGrupoPorIA(groupName, membersAliases);
          }
        }
      } else {
        throw Exception("Error HTTP ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg["isLoading"] == true);
        _messages.add({"isUser": false, "text": "Ups, tuve un error de conexión con la IA."});
      });
    }
  }

  Future<void> _ejecutarCreacionDeGrupoPorIA(String groupName, List<dynamic> aliases) async {
    List<Map<String, dynamic>> miembrosConfirmados = [];

    if (aliases.isNotEmpty) {
      for (String alias in aliases) {
        final data = await _buscarBilleteraPorAlias(alias);
        if (data != null) {
          miembrosConfirmados.add(data);
        }
      }

      if (miembrosConfirmados.isEmpty) {
        setState(() => _messages.add({"isUser": false, "text": "No encontré a esos usuarios en el sistema. ¿Están bien escritos sus alias?"}));
        return; 
      }
    }

   final groupService = Provider.of<GroupSocialService>(context, listen: false);
    String resultado = await groupService.createGroup(groupName, "Admin", miembrosConfirmados);
    
    if (resultado == "SUCCESS") {
      setState(() {
        if (miembrosConfirmados.isEmpty) {
           _messages.add({"isUser": false, "text": "Fondo común '$groupName' creado vacío."});
        } else {
           _messages.add({"isUser": false, "text": "Fondo común '$groupName' creado. Se enviaron invitaciones a ${miembrosConfirmados.length} miembro(s)."});
        }
      });
    } else {
      setState(() => _messages.add({"isUser": false, "text": "Error al guardar el grupo: $resultado"}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceColor = theme.scaffoldBackgroundColor;
    final botBubbleColor = theme.cardColor;
    final userBubbleColor = colorScheme.primary; 
    final onSurface = colorScheme.onSurface; 

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondary,
                  radius: 18,
                  child: Icon(Icons.smart_toy_rounded, color: colorScheme.onSurface, size: 24),
                ),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: surfaceColor, width: 2)),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Text("Asistente TTC", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                return _buildChatBubble(msg["text"], msg["isUser"], botBubbleColor, userBubbleColor, onSurface, colorScheme.onPrimary);
              },
            ),
          ),
          _buildInputArea(theme.cardColor, onSurface, colorScheme.primary, colorScheme.onPrimary),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, Color botColor, Color userColor, Color textColor, Color onPrimaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondary, radius: 12, child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? userColor : botColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0), bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser ? null : Border.all(color: textColor.withOpacity(0.05)), 
              ),
              child: Text(text, style: TextStyle(color: isUser ? onPrimaryColor : textColor, fontSize: 15)),
            ),
          ),
          if (isUser) const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color cardColor, Color textColor, Color primaryColor, Color onPrimaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: Icon(Icons.mic_none, color: textColor.withOpacity(0.6)), onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Págale 20 a Contacto a cuotas...",
                  hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  filled: true, fillColor: textColor.withOpacity(0.05), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle), 
              child: IconButton(icon: Icon(Icons.send_rounded, color: onPrimaryColor), onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }
}