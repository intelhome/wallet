import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai_assistant/services/ai_memory_service.dart';
import 'group_social_service.dart';

class AiTreasurerHandler {
  // 🔥 ESCUDO: Solo despierta a la IA si se usan estas palabras
  static final List<String> _keywords = [
    "pagué", "costó", "pongo", "dividamos", "tocamos a", "@tesorero", "compré", "deben", "pagar"
  ];

  static bool containsFinancialIntent(String text) {
    final lower = text.toLowerCase();
    return _keywords.any((word) => lower.contains(word));
  }

  static Future<bool> processGroupMessage(
    BuildContext context, String text, String groupId, String miWallet, int totalMembers
  ) async {
    final aiMemory = Provider.of<AiMemoryService>(context, listen: false);
    // (Asegúrate de importar e inyectar tu servicio de pagos grupales reales aquí)
    // final paymentService = Provider.of<GroupPaymentService>(context, listen: false);
    final chatService = Provider.of<GroupSocialService>(context, listen: false);

    String prompt = """
    Eres el Tesorero IA de un grupo. Alguien envió este mensaje: "$text".
    El grupo tiene $totalMembers miembros.
    Extrae la intención financiera. 
    Si el usuario pagó algo y quiere dividirlo, extrae el monto total numérico y el motivo.
    
    Responde SOLO con JSON (Sin texto afuera):
    {
       "action": "CREATE_SPLIT_BILL", // o "NONE" si no hay gasto real
       "totalAmount": 50.0,
       "description": "Pizzas y cervezas"
    }
    """;

    try {
      final response = await aiMemory.sendMessageWithMemory("El Tesorero está calculando...", prompt);
      
      if (response != null && response.containsKey('response')) {
        String cleanJson = response['response'].toString().replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> data = jsonDecode(cleanJson);

        if (data['action'] == 'CREATE_SPLIT_BILL') {
          double amount = double.tryParse(data['totalAmount'].toString()) ?? 0.0;
          String desc = data['description'] ?? "Gastos compartidos";
          double perPerson = amount / totalMembers;

          // 1. LLAMADA AL BACKEND PARA CREAR LA DEUDA (SPLITWISE)
          /* final resPago = await paymentService.createGroupRequest(
            groupId: groupId, requesterAddress: miWallet, destinationAddress: miWallet, 
            totalAmount: amount, description: desc, useGroupFunds: false 
          ); 
          */
          String simulatedSplitBillId = "DEBT_${DateTime.now().millisecondsSinceEpoch}";

          // 2. LA IA ENVÍA SU TARJETA INTERACTIVA AL CHAT GRUPAL
          await chatService.sendGroupMessage(
            groupId: groupId,
            senderWallet: "AI_TREASURER",
            senderAlias: "Tesorero IA",
            messageType: "SPLIT_BILL_CARD",
            content: jsonEncode({
              "text": "¡Anotado! He dividido $amount TTC por $desc. Les toca de a ${perPerson.toStringAsFixed(2)} TTC.",
              "splitBillId": simulatedSplitBillId, // El ID de la deuda generada
              "amountPerPerson": perPerson,
              "creatorWallet": miWallet
            }),
          );
          return true; // Resolvió la intención
        }
      }
    } catch (e) {
      debugPrint("Error IA Tesorero: $e");
    }
    return false; // No era intención financiera, sigue el flujo normal
  }
}