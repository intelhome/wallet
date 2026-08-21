import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/split_bill_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/modals/send_modal.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';

import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../chat_and_social/services/chat_media_service.dart';
import '../../chat_and_social/widgets/message_bubble.dart';
import '../modals/group_chat_profile_modal.dart';
import '../services/group_social_service.dart';
import '../services/ai_treasurer_handler.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int totalMembers;

  const GroupChatScreen({super.key, required this.groupId, required this.groupName, required this.totalMembers});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  bool _isRecording = false;
  bool _hasText = false;
  bool _showAttachmentMenu = false;
  bool _showMicTutorial = true;
  String? _audioPath;
  bool _isRecorderReady = false; 

  IOWebSocketChannel? _wsChannel;
  String? _typingUserAlias;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _conectarWebSocket(); 
    _initRecorder(); 

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showMicTutorial = false);
    });
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      _isRecorderReady = true;
    } catch (e) {
      debugPrint("Error inicializando micrófono: $e");
    }
  }

  @override
  void dispose() {
    _wsChannel?.sink.close(); 
    _typingTimer?.cancel();
    _msgController.dispose();
    _focusNode.dispose();
    if (_isRecorderReady) _audioRecorder.closeRecorder(); 
    super.dispose();
  }

  // void _conectarWebSocket() {
  //   try {
  //     final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //     final wsUrl = "${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/ws/groups/${widget.groupId}";
      
  //     _wsChannel = IOWebSocketChannel.connect(
  //       Uri.parse(wsUrl),
  //       headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
  //     );

  //     _wsChannel!.stream.listen((message) {
  //       if (message == "UPDATE" || message == "UPDATE_GROUP") {
  //         _loadHistory();
  //       } else {
  //         try {
  //           final data = jsonDecode(message);
  //           if (data['type'] == 'TYPING' && data['senderWallet'] != authCore.publicAddress.toLowerCase()) {
  //             setState(() => _typingUserAlias = data['senderAlias'] ?? "Alguien");
  //             _typingTimer?.cancel();
  //             _typingTimer = Timer(const Duration(seconds: 3), () {
  //               if (mounted) setState(() => _typingUserAlias = null);
  //             });
  //           }
  //         } catch (_) {}
  //       }
  //     });
  //   } catch (e) {}
  // }

  void _conectarWebSocket() {
    try {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      final wsUrl = "${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/ws/groups/${widget.groupId}";
      
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
      );

      _wsChannel!.stream.listen((message) {
        if (message == "UPDATE" || message == "UPDATE_GROUP") {
          // 🔥 Solo recargamos si no fuimos nosotros los que enviamos (Evita duplicados visuales)
          // (Si necesitas recargar todo el historial para asegurar consistencia, puedes hacerlo,
          // pero como ya inyectamos el nuestro localmente, es mejor recargar "silenciosamente"
          // o solo cuando envían otros).
          _loadHistory();
        } else {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'TYPING' && data['senderWallet'] != authCore.publicAddress.toLowerCase()) {
              setState(() => _typingUserAlias = data['senderAlias'] ?? "Alguien");
              _typingTimer?.cancel();
              _typingTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _typingUserAlias = null);
              });
            }
          } catch (_) {}
        }
      });
    } catch (e) {}
  }

  void _enviarEventoTyping() {
    if (_wsChannel != null) {
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      _wsChannel!.sink.add(jsonEncode({
        "type": "TYPING",
        "senderWallet": authCore.publicAddress.toLowerCase(),
        "senderAlias": "Un miembro" 
      }));
    }
  }

  Future<void> _loadHistory() async {
    final chatService = Provider.of<GroupSocialService>(context, listen: false);
    final history = await chatService.getGroupChatHistory(widget.groupId);
    if (mounted) setState(() { _messages = history; _isLoading = false; });
  }

  Future<void> _iniciarGrabacion() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) { UIHelper.showCustomSnackbar("Permiso denegado", isError: true); return; }
    final dir = await getApplicationDocumentsDirectory();
    _audioPath = "${dir.path}/group_audio_${DateTime.now().millisecondsSinceEpoch}.aac";
    await _audioRecorder.startRecorder(toFile: _audioPath);
    setState(() => _isRecording = true);
  }

  // Future<void> _detenerYEnviarAudio() async {
  //   if (!_isRecording) return; 
  //   final path = await _audioRecorder.stopRecorder();
  //   setState(() => _isRecording = false);
  //   if (path != null) {
  //     File audioFile = File(path);
  //     UIHelper.showCustomSnackbar("Cifrando nota de voz...");
  //     final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //     final uploadData = await ChatMediaService.encryptAndUpload(audioFile, authCore.jwtToken ?? "");
  //     if (uploadData != null) {
  //       final payload = jsonEncode({"remoteUrl": uploadData['remoteUrl'], "localPath": audioFile.path, "mediaKey": uploadData['mediaKey'], "mediaIv": uploadData['mediaIv']});
  //       await Provider.of<GroupSocialService>(context, listen: false).sendGroupMessage(groupId: widget.groupId, senderWallet: authCore.publicAddress.toLowerCase(), senderAlias: "Yo", content: payload, messageType: "AUDIO");
  //     }
  //   }
  // }

  Future<void> _detenerYEnviarAudio() async {
    if (!_isRecording) return; 
    final path = await _audioRecorder.stopRecorder();
    setState(() => _isRecording = false);
    if (path != null) {
      File audioFile = File(path);
      UIHelper.showCustomSnackbar("Cifrando nota de voz...");
      final authCore = Provider.of<AuthCoreService>(context, listen: false);
      final uploadData = await ChatMediaService.encryptAndUpload(audioFile, authCore.jwtToken ?? "");
      if (uploadData != null) {
        final payload = jsonEncode({"remoteUrl": uploadData['remoteUrl'], "localPath": audioFile.path, "mediaKey": uploadData['mediaKey'], "mediaIv": uploadData['mediaIv']});
        _ejecutarEnvioGrupal(payload, "AUDIO");
      }
    }
  }

  // Future<void> _enviarImagen() async {
  //   final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //   File? compressedImage = await ChatMediaService.pickAndCompressImage();
  //   if (compressedImage == null) return;
  //   UIHelper.showCustomSnackbar("Cifrando imagen...");
  //   final uploadData = await ChatMediaService.encryptAndUpload(compressedImage, authCore.jwtToken ?? "");
  //   if (uploadData != null) {
  //     final payload = jsonEncode({"remoteUrl": uploadData['remoteUrl'], "localPath": compressedImage.path, "mediaKey": uploadData['mediaKey'], "mediaIv": uploadData['mediaIv'], "caption": ""});
  //     await Provider.of<GroupSocialService>(context, listen: false).sendGroupMessage(groupId: widget.groupId, senderWallet: authCore.publicAddress.toLowerCase(), senderAlias: "Yo", content: payload, messageType: "IMAGE");
  //   }
  // }

  Future<void> _enviarImagen() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    File? compressedImage = await ChatMediaService.pickAndCompressImage();
    if (compressedImage == null) return;
    UIHelper.showCustomSnackbar("Cifrando imagen...");
    final uploadData = await ChatMediaService.encryptAndUpload(compressedImage, authCore.jwtToken ?? "");
    if (uploadData != null) {
      final payload = jsonEncode({"remoteUrl": uploadData['remoteUrl'], "localPath": compressedImage.path, "mediaKey": uploadData['mediaKey'], "mediaIv": uploadData['mediaIv'], "caption": ""});
      _ejecutarEnvioGrupal(payload, "IMAGE");
    }
  }

  // ==========================================================
  //  LÓGICA REFACTORIZADA DE PAGOS DIVIDIDOS (SPLIT BILL)
  // ==========================================================

  Future<void> _abrirSplitBillScreen() async {
    setState(() => _showAttachmentMenu = false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final groupService = Provider.of<GroupSocialService>(context, listen: false);
    
    UIHelper.showCustomSnackbar("Cargando miembros del grupo...", isError: false);
    
    // 1. Buscamos a los participantes del grupo para rellenarlos automáticamente
    List<dynamic> groups = await groupService.getUserGroups();
    var currentGroup;
    try { currentGroup = groups.firstWhere((g) => g['id'] == widget.groupId); } catch(e) {}

    List<Map<String, String>> participants = [];
    if (currentGroup != null && currentGroup['members'] != null) {
      for (var m in currentGroup['members']) {
        if (m['walletAddress'].toString().toLowerCase() != authCore.publicAddress.toLowerCase()) {
          participants.add({
            "alias": m['alias'] ?? "",
            "wallet": m['walletAddress'].toString().toLowerCase()
          });
        }
      }
    }

    if (!mounted) return;

    // 2. Navegamos a la Pantalla Oficial de Split Bill
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplitBillScreen(
          initialParticipants: participants, // 🔥 USUARIOS PRE-LLENADOS
          onBillSplitSuccess: () {},
          onBillSplitSuccessDetails: (total, reason, perPerson) async {
            // 3. Cuando el pago se divida, mandamos la tarjeta al grupo
            String simId = "DEBT_MANUAL_${DateTime.now().millisecondsSinceEpoch}";
            
            //  FIX: Usamos _ejecutarEnvioGrupal en lugar del servicio directo
            _ejecutarEnvioGrupal(
              jsonEncode({
                "text": "He dividido $total TTC por $reason. Nos toca de a ${perPerson.toStringAsFixed(2)} TTC.",
                "splitBillId": simId,
                "amountPerPerson": perPerson,
                "creatorWallet": authCore.publicAddress.toLowerCase()
              }),
              "SPLIT_BILL_CARD"
            );
          }
        )
      )
    );
  }

  // 🔥 NUEVA LÓGICA: GESTIONA LA ACEPTACIÓN O EL PAGO DESDE EL CHAT
  Future<void> _gestionarDeudaCard(Map<String, dynamic> cardData) async {
    final debtService = Provider.of<DebtService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    UIHelper.showCustomSnackbar("Buscando tu deuda en el sistema...", isError: false);
    
    List<dynamic> misDeudas = await debtService.getUserDebts();
    var myDebt;
    
    // Buscamos la deuda que coincida con el creador y que esté pendiente o activa
    try {
        myDebt = misDeudas.firstWhere((d) {
            bool matchCreditor = d['creditorAddress'].toString().toLowerCase() == cardData['creatorWallet'].toString().toLowerCase();
            bool matchDebtor = d['debtorAddress'].toString().toLowerCase() == authCore.publicAddress.toLowerCase();
            bool matchStatus = d['status'] == 'PENDING_APPROVAL' || d['status'] == 'ACTIVE';
            return matchCreditor && matchDebtor && matchStatus;
        });
    } catch(e) {
        UIHelper.showCustomSnackbar("No tienes deudas pendientes asociadas a este cobro.", isError: true);
        return;
    }

    String debtId = myDebt['id'];
    String status = myDebt['status'];

    if (status == 'PENDING_APPROVAL') {
        // 🔥 LÓGICA DE ACEPTAR DEUDA (Extraída de DebtsScreen)
        bool? confirm = await UIHelper.mostrarConfirmacion(
          context: context,
          titulo: "Aceptar Deuda",
          mensaje: "¿Reconoces esta deuda de ${cardData['amountPerPerson']} TTC y te comprometes a pagarla?",
          textoConfirmar: "Sí, aceptar",
          colorConfirmar: Colors.green,
        );
        if (confirm != true || !mounted) return;

        showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza la aceptación de la deuda."));
        bool auth = await authCore.authenticateUser();
        if (!mounted) return;
        Navigator.pop(context); 
        if (!auth) return;

        showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Procesando", message: "Actualizando estado..."));
        String res = await debtService.respondDebtRequest(debtId, true);
        if (!mounted) return;
        Navigator.pop(context);

        if (res == "Exito") {
            UIHelper.showCustomSnackbar("¡Deuda aceptada! Toca nuevamente para pagarla.", isError: false);
        } else {
            UIHelper.showCustomSnackbar("Error al aceptar: $res", isError: true);
        }

    } else if (status == 'ACTIVE') {
        // 🔥 LÓGICA DE PAGAR DEUDA ACTIVA (Con Modal Original)
        String miSaldo = await txService.getBalance();
        if (!mounted) return;
        
        SendModal.show(
            context: context, 
            balanceTTC: miSaldo, 
            initialAddress: cardData['creatorWallet'], 
            debtId: debtId, 
            onUpdateBalance: () {}, 
           mostrarMensaje: (msg, {bool esError = false}) { 
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: esError ? Colors.red : Colors.green)); 
                if (!esError) {
                    //  FIX: Usamos _ejecutarEnvioGrupal en lugar del servicio directo para que se pinte al instante
                    _ejecutarEnvioGrupal(
                        jsonEncode({"text": "✅ He pagado mi parte (${cardData['amountPerPerson']} TTC) de la cuenta dividida."}),
                        "TEXT"
                    );
                }
            }
        );
    }
  }

  Future<void> _enviarMensajeTexto() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    _msgController.clear();
    setState(() => _hasText = false);
    
    final miWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();
    
    if (AiTreasurerHandler.containsFinancialIntent(text)) {
      UIHelper.showCustomSnackbar("El Tesorero IA está calculando...");
      await AiTreasurerHandler.processGroupMessage(context, text, widget.groupId, miWallet, widget.totalMembers);
    }

    final payload = jsonEncode({ "text": text, "content": text, "type": "TEXT" });
    _ejecutarEnvioGrupal(payload, "TEXT");
  }

  Future<void> _ejecutarEnvioGrupal(String payloadJson, String messageType) async {
    final chatService = Provider.of<GroupSocialService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final miWallet = authCore.publicAddress.toLowerCase();
    
    // 1. Crear ID temporal y mensaje local para Lag-Zero
    String tempId = "TEMP_${DateTime.now().millisecondsSinceEpoch}";
    
    Map<String, dynamic> localMsg = {
      "id": tempId,
      "groupId": widget.groupId,
      "senderWallet": miWallet,
      "senderAlias": "Yo",
      "content": payloadJson,
      "messageType": messageType,
      "timestamp": DateTime.now().toIso8601String(),
      "status": "SENT" // Pendiente de ACK
    };

    setState(() {
      _messages.add(localMsg); // Insertamos en la UI al instante
    });

    // 2. Disparar petición HTTP real
    final ackData = await chatService.sendGroupMessage(
      groupId: widget.groupId, 
      senderWallet: miWallet, 
      senderAlias: "Yo", 
      content: payloadJson, 
      messageType: messageType,
      tempId: tempId
    );

    // 3. Procesar ACK del backend
    if (ackData != null && ackData['eventType'] == 'ACK') {
      String idTemporalDevuelto = ackData['tempId'];
      String idReal = ackData['realId'];

      setState(() {
        // Buscamos el mensaje temporal y lo "formalizamos"
        for (var msg in _messages) {
          if (msg['id'] == idTemporalDevuelto) {
            msg['id'] = idReal;
            msg['status'] = "DELIVERED"; // Dibuja el tick
            break;
          }
        }
      });
    } else {
      // Falló, lo quitamos de la UI
      setState(() {
        _messages.removeWhere((msg) => msg['id'] == tempId);
      });
      UIHelper.showCustomSnackbar("Error: El mensaje no pudo ser guardado.", isError: true);
    }
  }

  // Future<void> _enviarMensajeTexto() async {
  //   String text = _msgController.text.trim();
  //   if (text.isEmpty) return;
    
  //   setState(() { _isSending = true; }); 
    
  //   final chatService = Provider.of<GroupSocialService>(context, listen: false);
  //   final miWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();
    
  //   if (AiTreasurerHandler.containsFinancialIntent(text)) {
  //     UIHelper.showCustomSnackbar("El Tesorero IA está calculando...");
  //     await AiTreasurerHandler.processGroupMessage(context, text, widget.groupId, miWallet, widget.totalMembers);
  //   }

  //   final payload = jsonEncode({ "text": text, "content": text, "type": "TEXT" });
  //   bool success = await chatService.sendGroupMessage(
  //     groupId: widget.groupId, senderWallet: miWallet, senderAlias: "Yo", content: payload, messageType: "TEXT"
  //   );

  //   if (success) {
  //     _msgController.clear();
  //     setState(() { _hasText = false; });
  //   } else {
  //     UIHelper.showCustomSnackbar("Error del Servidor: El mensaje no pudo ser guardado.", isError: true);
  //   }
  //   setState(() => _isSending = false);
  // }

  // ==========================================================
  // CONSTRUCCIÓN DE UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final miWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded), 
          onPressed: () => Navigator.pop(context)
        ),
        title: GestureDetector(
          onTap: () => GroupChatProfileModal.show(context, widget.groupId, widget.groupName, widget.totalMembers),
          child: Row(
            children: [
              SmartAvatar(address: widget.groupId, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                    if (_typingUserAlias != null)
                      Text("$_typingUserAlias está escribiendo...", style: TextStyle(color: colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic))
                    else
                      Text("Toca para info del grupo", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6))),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // 🔥 FONDO DE CUADRÍCULA ESTILO MOCKUP
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(color: onSurface.withOpacity(0.04)),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[(_messages.length - 1) - index];
                        final isMe = msg['senderWallet']?.toString().toLowerCase() == miWallet;
                        
                        if (msg['messageType'] == 'SPLIT_BILL_CARD') {
                          return _buildSplitBillCard(jsonDecode(msg['content']), isMe);
                        }

                       Map<String, dynamic> parsedMap;
                        try {
                          parsedMap = jsonDecode(msg['content']);
                          parsedMap['type'] = msg['messageType'];
                          // Le pasamos el status para que pinte el ✓ si está 'DELIVERED'
                          parsedMap['status'] = msg['status']; 
                        } catch (_) {
                          parsedMap = {"type": msg['messageType'], "text": msg['content'], "content": msg['content'], "status": msg['status']};
                        }

                        return Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && msg['senderAlias'] != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 2, top: 8),
                                child: Text("@${msg['senderAlias']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary.withOpacity(0.8))),
                              ),
                            MessageBubble(message: parsedMap, isMe: isMe, peerAddress: msg['senderWallet'] ?? ''),
                          ],
                        );
                      },
                    ),
                  ),

                  // BARRA DE ENTRADA DE CHAT TIPO PÍLDORA
                  _buildInputArea(),
                ],
              ),

              if (_showAttachmentMenu)
                Positioned(
                  bottom: 80, 
                  left: 16, 
                  child: _buildAttachmentMenu()
                ),

              if (_showMicTutorial)
                Positioned(
                  bottom: 90, right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                      child: const Text("Mantén presionado para Audio 🎤", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 20),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: IconButton(
                  icon: AnimatedRotation(
                    turns: _showAttachmentMenu ? 0.125 : 0, 
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.attach_file_rounded, color: onSurface.withOpacity(0.6), size: 24),
                  ),
                  onPressed: () => setState(() { _showAttachmentMenu = !_showAttachmentMenu; _showMicTutorial = false; }),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _msgController, focusNode: _focusNode, maxLines: 5, minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: onSurface),
                  onChanged: (val) {
                    _enviarEventoTyping(); 
                    if (val.isNotEmpty && !_hasText) setState(() => _hasText = true);
                    else if (val.isEmpty && _hasText) setState(() => _hasText = false);
                    if (_showMicTutorial) setState(() => _showMicTutorial = false);
                  },
                  decoration: InputDecoration(
                    hintText: "Mensaje al grupo...", 
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 16),
                    border: InputBorder.none, 
                    contentPadding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 6),
                child: GestureDetector(
                  onTap: _hasText ? () { _enviarMensajeTexto(); setState(() => _showAttachmentMenu = false); } : null,
                  onLongPress: () async {
                    setState(() => _showMicTutorial = false);
                    if (!_hasText) { HapticFeedback.heavyImpact(); await _iniciarGrabacion(); }
                  },
                  onLongPressEnd: (details) async {
                    if (!_hasText) await _detenerYEnviarAudio();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_isRecording ? 12 : 10),
                    decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                    child: Icon(
                      _hasText ? Icons.send_rounded : (_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded), 
                      color: _hasText || _isRecording ? colorScheme.primary : onSurface.withOpacity(0.6), 
                      size: _isRecording ? 26 : 24
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call_split_rounded, color: Colors.green),
              tooltip: "Dividir Pago",
              onPressed: _abrirSplitBillScreen, 
            ),
            IconButton(
              icon: const Icon(Icons.image_rounded, color: Colors.blueAccent),
              tooltip: "Enviar Imagen",
              onPressed: () { setState(() => _showAttachmentMenu = false); _enviarImagen(); },
            ),
          ],
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final miWallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       backgroundColor: theme.cardColor,
  //       elevation: 1,
  //       titleSpacing: 0,
  //       title: GestureDetector(
  //         onTap: () => GroupChatProfileModal.show(context, widget.groupId, widget.groupName, widget.totalMembers),
  //         child: Row(
  //           children: [
  //             SmartAvatar(address: widget.groupId, size: 36),
  //             const SizedBox(width: 12),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                 if (_typingUserAlias != null)
  //                   Text("$_typingUserAlias está escribiendo...", style: TextStyle(color: colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic))
  //                 else
  //                   Text("Toca para info del grupo", style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     body: _isLoading 
  //       ? const Center(child: CircularProgressIndicator())
  //       : Stack(
  //           children: [
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Expanded(
  //                   child: ListView.builder(
  //                     padding: const EdgeInsets.symmetric(vertical: 20),
  //                     reverse: true,
  //                     itemCount: _messages.length,
  //                     itemBuilder: (context, index) {
  //                       final msg = _messages[(_messages.length - 1) - index];
  //                       final isMe = msg['senderWallet']?.toString().toLowerCase() == miWallet;
                        
  //                       if (msg['messageType'] == 'SPLIT_BILL_CARD') {
  //                         return _buildSplitBillCard(jsonDecode(msg['content']), isMe);
  //                       }

  //                       Map<String, dynamic> parsedMap;
  //                       try {
  //                         parsedMap = jsonDecode(msg['content']);
  //                         parsedMap['type'] = msg['messageType'];
  //                       } catch (_) {
  //                         parsedMap = {"type": msg['messageType'], "text": msg['content'], "content": msg['content']};
  //                       }

  //                       return Column(
  //                         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
  //                         children: [
  //                           if (!isMe && msg['senderAlias'] != null)
  //                             Padding(
  //                               padding: const EdgeInsets.only(left: 20, bottom: 2, top: 8),
  //                               child: Text("@${msg['senderAlias']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary.withOpacity(0.8))),
  //                             ),
  //                           MessageBubble(message: parsedMap, isMe: isMe, peerAddress: msg['senderWallet'] ?? ''),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //                 ),

  //                 if (_typingUserAlias != null)
  //                   Padding(
  //                     padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Text("$_typingUserAlias está escribiendo", style: TextStyle(color: colorScheme.primary, fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
  //                         Text("...", style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
  //                       ],
  //                     ),
  //                   ),

  //                 _buildInputArea(),
  //               ],
  //             ),

  //             if (_showAttachmentMenu)
  //               Positioned(bottom: 75, left: 5, child: _buildAttachmentMenu()),

  //             if (_showMicTutorial)
  //               Positioned(
  //                 bottom: 80, right: 15,
  //                 child: Material(
  //                   color: Colors.transparent,
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //                     decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(16)),
  //                     child: const Text("Mantén presionado para Audio 🎤", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //   );
  // }

  // // 🔥 TARJETA INTELIGENTE MEJORADA PARA ACEPTAR DEUDAS 
  Widget _buildSplitBillCard(Map<String, dynamic> cardData, bool isMe) {
    bool isMyDebt = cardData['creatorWallet'] == Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.deepPurpleAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent, size: 18), SizedBox(width: 8), Text("Tesorero IA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))]),
          const SizedBox(height: 8),
          Text(cardData['text'] ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          if (!isMyDebt) 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                icon: const Icon(Icons.touch_app_rounded),
                label: Text("Gestionar mi parte (${cardData['amountPerPerson']?.toStringAsFixed(2)} TTC)"),
                onPressed: () => _gestionarDeudaCard(cardData), // 🔥 LLAMA AL NUEVO MÉTODO INTELIGENTE
              ),
            )
        ],
      ),
    );
  }

  // Widget _buildInputArea() {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  //     decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, -4))]),
  //     child: SafeArea(
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.end,
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.only(bottom: 2),
  //             child: IconButton(
  //               icon: AnimatedRotation(
  //                 turns: _showAttachmentMenu ? 0.125 : 0, 
  //                 duration: const Duration(milliseconds: 200),
  //                 child: Icon(Icons.attach_file_rounded, color: colorScheme.primary, size: 28),
  //               ),
  //               onPressed: () => setState(() { _showAttachmentMenu = !_showAttachmentMenu; _showMicTutorial = false; }),
  //             ),
  //           ),
  //           Expanded(
  //             child: Container(
  //               decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.onSurface.withOpacity(0.1))),
  //               child: TextField(
  //                 controller: _msgController, focusNode: _focusNode, maxLines: 5, minLines: 1,
  //                 textCapitalization: TextCapitalization.sentences,
  //                 onChanged: (val) {
  //                   _enviarEventoTyping(); 
  //                   if (val.isNotEmpty && !_hasText) setState(() => _hasText = true);
  //                   else if (val.isEmpty && _hasText) setState(() => _hasText = false);
  //                   if (_showMicTutorial) setState(() => _showMicTutorial = false);
  //                 },
  //                 decoration: InputDecoration(hintText: "Mensaje al grupo...", border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Padding(
  //             padding: const EdgeInsets.only(bottom: 2),
  //             child: GestureDetector(
  //               onTap: _hasText ? () { _enviarMensajeTexto(); setState(() => _showAttachmentMenu = false); } : null,
  //               onLongPress: () async {
  //                 setState(() => _showMicTutorial = false);
  //                 if (!_hasText) { HapticFeedback.heavyImpact(); await _iniciarGrabacion(); }
  //               },
  //               onLongPressEnd: (details) async {
  //                 if (!_hasText) await _detenerYEnviarAudio();
  //               },
  //               child: AnimatedContainer(
  //                 duration: const Duration(milliseconds: 200),
  //                 padding: EdgeInsets.all(_isRecording ? 16 : 14),
  //                 decoration: BoxDecoration(color: _hasText ? colorScheme.primary : (_isRecording ? Colors.redAccent : colorScheme.primary), shape: BoxShape.circle),
  //                 child: Icon(_hasText ? Icons.send_rounded : (_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded), color: Colors.white, size: _isRecording ? 26 : 22),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildAttachmentMenu() {
  //   final theme = Theme.of(context);
  //   return Material(
  //     color: Colors.transparent,
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 10, left: 10),
  //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  //       decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)]),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           IconButton(
  //             icon: const Icon(Icons.call_split_rounded, color: Colors.green),
  //             tooltip: "Dividir Pago",
  //             onPressed: _abrirSplitBillScreen, // 🔥 AHORA ABRE LA PANTALLA OFICIAL
  //           ),
  //           IconButton(
  //             icon: const Icon(Icons.image_rounded, color: Colors.blueAccent),
  //             tooltip: "Enviar Imagen",
  //             onPressed: () { setState(() => _showAttachmentMenu = false); _enviarImagen(); },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double spacing = 30.0; // Espaciado de los cuadros

    // Líneas verticales
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Líneas horizontales
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}