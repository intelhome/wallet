import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai_assistant/services/ai_memory_service.dart';

class AiTaskAdminHandler {
  
  // 🔥 NUEVO MOTOR: ANÁLISIS MASIVO Y GENERACIÓN DE REPORTES
  static Future<Map<String, dynamic>?> generarReporteMasivo(BuildContext context, List<dynamic> tasks, String tipoFiltro) async {
    final aiMemory = Provider.of<AiMemoryService>(context, listen: false);

    // 1. Limpiamos y optimizamos la data para no gastar tokens innecesarios
    List<Map<String, dynamic>> miniTasks = tasks.map((t) => {
      "id": t['id'],
      "title": t['title'],
      "status": t['status'],
      "deadline": t['deadline'],
      "assignedTo": t['assignedWallet'],
      "proof": t['completionProof'],
      "rework/reject_reason": t['feedback'] ?? t['appealReason'],
    }).toList();

    String hoy = DateTime.now().toString();

    String prompt = """
Eres el Director de Operaciones (COO) y Auditor de la empresa. Hoy es $hoy.
Analiza el siguiente lote de tareas bajo el enfoque: '$tipoFiltro'.

TAREAS A ANALIZAR:
${jsonEncode(miniTasks)}

REGLAS DE ANÁLISIS SEGÚN EL ENFOQUE:
- Si el enfoque es 'COMPLETADAS' o 'GENERAL': Audita las pruebas (proof) de las tareas 'COMPLETED'. Decide si apruebas o pides corrección. Genera un feedback para el empleado.
- Si el enfoque es 'EN CORRECCIÓN' o 'RECHAZADAS': Explica brevemente por qué están bloqueadas usando los campos de razón.
- Si el enfoque es 'PENDIENTES' o 'EN PROGRESO': Revisa si están a punto de expirar (deadline) y lanza advertencias.

FORMATO DE SALIDA OBLIGATORIO (SOLO JSON VÁLIDO, SIN TEXTO AFUERA):
{
  "executive_summary": "Escribe un párrafo corporativo resumiendo el estado general de este lote de tareas.",
  "expiring_warnings": ["Advertencia 1...", "Advertencia 2..."], // Array de strings con alertas urgentes
  "evaluations": [
    {
      "taskId": "ID_DE_LA_TAREA_AQUI",
      "recommended_action": "APPROVED", // o "REWORK_REQUESTED" o "NONE"
      "ai_reasoning": "Tu razonamiento privado para el gerente...",
      "employee_feedback": "El texto que se le enviará al empleado..."
    }
  ]
}
""";

    try {
      final response = await aiMemory.sendMessageWithMemory("Generando reporte $tipoFiltro...", prompt);
      if (response != null && response.containsKey('response')) {
        String cleanJsonStr = response['response'].toString().replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJsonStr);
      }
    } catch (e) {
      debugPrint("Error en IA Masiva: $e");
    }
    return null;
  }
}