import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../business/services/business_task_service.dart';
import '../../chat_and_social/services/secure_chat_service.dart';
import 'ai_memory_service.dart';

class AiAvatarResponse {
  bool _isProcessing = false;

  Future<void> evaluarEventoConIA({
    required AuthCoreService authCore,
    required SecureChatService chatService,
    required Map<String, dynamic> evento
  }) async {
    if (_isProcessing) return; 
    _isProcessing = true;

    final aiMemoryService = AiMemoryService(authCore);

    String tipoEvento = evento['type'] ?? ''; 
    String payloadStr = jsonEncode(evento['data']);

    String promptAutonomo = """
    Eres el Avatar Cognitivo Autónomo del usuario. Reaccionas por él basándote en su memoria y estilo.
    TIPO DE EVENTO: $tipoEvento
    DATOS DEL EVENTO: $payloadStr

    REGLAS ESTRICTAS E INQUEBRANTABLES:
    1. TAREAS (NEW_TASK): SOLO puedes auto-aceptar tareas si su 'taskType' es 'GPS' o 'OPINION'. Si es STANDARD, MEET, FORM, etc., decide "IGNORE".
    2. CHAT (CHAT_MESSAGE): Puedes generar una respuesta automática ("AUTO_REPLY") imitando EXACTAMENTE el estilo, tono y modismos del usuario en tu memoria.
    3. PREVENCIÓN DE BUCLES (¡MUY IMPORTANTE!): NUNCA respondas a mensajes de cortesía final como 'ok', 'gracias', 'saludos', 'de nada', 'listo', 'perfecto' o confirmaciones cortas. Si el mensaje no requiere una respuesta real o es una despedida, DEBES decidir "IGNORE".

    Responde ÚNICA Y ESTRICTAMENTE con este formato JSON:
    {
      "decision": "AUTO_ACCEPT" | "AUTO_REPLY" | "IGNORE",
      "justification": "Breve motivo de la decisión",
      "action_payload": {
         "reply_text": "texto de respuesta como si fueras el usuario"
      }
    }
    """;

  try {
      final res = await aiMemoryService.sendMessageWithMemory("Evalúa este evento", promptAutonomo);
      if (res != null && res['response'] != null) {
        
      
        String aiRawResponse = res['response'].toString();
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(aiRawResponse);
        
        if (match != null) {
          final String pureJson = match.group(0)!;
          final Map<String, dynamic> aiDecision = jsonDecode(pureJson);
          
          String decision = aiDecision['decision'] ?? 'IGNORE';
          String justificacion = aiDecision['justification'] ?? '';
          Map<String, dynamic> payload = aiDecision['action_payload'] ?? {};

          await _ejecutarDecisionAutonoma(authCore, chatService, decision, justificacion, payload, evento);
        } else {
          print("⚠️ [AVATAR] La IA no devolvió un JSON válido: $aiRawResponse");
        }
      }
    } catch (e) {
      print("⚠️ Error en el Avatar Autónomo: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _ejecutarDecisionAutonoma(
    AuthCoreService authCore, 
    SecureChatService chatService, 
    String decision, 
    String justificacion, 
    Map<String, dynamic> actionPayload, 
    Map<String, dynamic> originalEvent
  ) async {
    if (decision == "AUTO_ACCEPT") {
      final taskService = BusinessTaskService(authCore);
      String taskId = originalEvent['data']['taskId'] ?? '';
      if (taskId.isNotEmpty) {
        await taskService.updateTaskStatus(taskId, {"status": "IN_PROGRESS"});
        print("🤖 [AVATAR] Tarea auto-aceptada. Motivo: $justificacion");
      }
    } 
    else if (decision == "AUTO_REPLY") {
      String senderWallet = originalEvent['data']['senderWallet'] ?? '';
      String replyText = actionPayload['reply_text'] ?? '';
      
      if (senderWallet.isNotEmpty && replyText.isNotEmpty) {
        print("🤖 [AVATAR] Respondiendo a $senderWallet: $replyText");
        
        final String jsonPayload = jsonEncode({
          "type": "TEXT",
          "content": replyText,
          "isAi": true 
        });

        await chatService.sendMessage(senderWallet, jsonPayload);
      }
    } else {
      print("🛑 [AVATAR] Decidió IGNORAR. Motivo: $justificacion");
    }
  }
}