import 'dart:convert';

import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../document_notary/modals/document_details_modal.dart';

class TaskUIFactory {
  // static Widget buildWidget(BuildContext context, Map<String, dynamic> task, bool isEmployer, VoidCallback onRefresh) {
  //   String type = task['taskType'] ?? 'STANDARD';
  //   Map<String, dynamic> meta = task['typeMetadata'] ?? {};

  //   if (type == 'STANDARD') return const SizedBox.shrink();

  //   // 1. TIPOS SIMPLES (Sin interacción de guardado complejo)
  //   if (type == 'MEET' || type == 'GPS' || type == 'NOTARY' || type == 'AGENDA') {
  //     return _buildSimpleTypes(context, type, meta);
  //   }

  //   // 2. TIPOS INTERACTIVOS (Requieren respuesta del empleado y guardado)
  //   if (type == 'READ_DOC') return _ReadDocWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);
  //   if (type == 'OPINION') return _OpinionWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);
  //   if (type == 'FORM') return _FormWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);

  //   return const SizedBox.shrink();
  // }

  static Widget buildWidget(BuildContext context, Map<String, dynamic> task, bool isEmployer, VoidCallback onRefresh) {
    String type = task['taskType'] ?? 'STANDARD';
    
    // 🔥 FIX: Manejamos el objeto Map que Spring Boot devuelve en `typeMetadata`
    Map<String, dynamic> meta = {};
    if (task['typeMetadata'] != null && task['typeMetadata'] is Map) {
      meta = Map<String, dynamic>.from(task['typeMetadata']);
    }

    if (type == 'STANDARD') return const SizedBox.shrink();

    // 1. TIPOS SIMPLES (Sin interacción de guardado complejo)
    if (type == 'MEET' || type == 'GPS' || type == 'NOTARY' || type == 'AGENDA') {
      return _buildSimpleTypes(context, type, meta);
    }

    // 2. TIPOS INTERACTIVOS (Requieren respuesta del empleado y guardado)
    if (type == 'READ_DOC') return _ReadDocWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);
    if (type == 'OPINION') return _OpinionWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);
    if (type == 'FORM') return _FormWidget(task: task, meta: meta, isEmployer: isEmployer, onRefresh: onRefresh);

    return const SizedBox.shrink();
  }

  static Widget _buildSimpleTypes(BuildContext context, String type, Map<String, dynamic> meta) {
    if (type == 'AGENDA') {
      return Card(
        color: Colors.blueGrey.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [Icon(Icons.calendar_month, color: Colors.blueGrey), SizedBox(width: 8), Text("Bloque de Agenda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))]),
              const SizedBox(height: 12),
              Text("📅 Fecha: ${meta['date'] != null ? DateTime.parse(meta['date']).toString().substring(0,10) : ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("⏰ Horario: ${meta['startTime']} - ${meta['endTime']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    // ... (Mantén aquí tu código original para MEET, GPS y NOTARY)
    if (type == 'MEET') {
      String link = meta['link'] ?? '';
      return Card(color: Colors.blueAccent.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.video_camera_front_rounded, color: Colors.blueAccent), SizedBox(width: 8), Text("Reunión Virtual Programada", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white), onPressed: () async { if (link.isEmpty) return; final finalUrl = link.startsWith('http') ? link : 'https://$link'; try { await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication); } catch (e) { UIHelper.showCustomSnackbar("No se pudo abrir el enlace", isError: true); } }, icon: const Icon(Icons.link_rounded), label: const Text("Unirse a la Llamada")))])));
    }
    if (type == 'GPS') {
      double lat = (meta['lat'] ?? 0).toDouble();
      double lng = (meta['lng'] ?? 0).toDouble();
      
      return Card(
        color: Colors.teal.withOpacity(0.1), 
        elevation: 0, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        child: Padding(
          padding: const EdgeInsets.all(16.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Row(children: [Icon(Icons.location_on_rounded, color: Colors.teal), SizedBox(width: 8), Text("Check-in Georeferenciado Requerido", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))]), 
              const SizedBox(height: 12), 
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), 
                  onPressed: () async { 
                    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng"; 
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
                  }, 
                  icon: const Icon(Icons.map_rounded), 
                  label: const Text("Ver Ubicación en Mapa")
                )
              )
            ]
          )
        )
      );
    }
    if (type == 'NOTARY') {
      String hash = meta['documentHash'] ?? '';
      return Card(color: Colors.deepPurpleAccent.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.verified_rounded, color: Colors.deepPurpleAccent), SizedBox(width: 8), Text("Firma en Contrato Inteligente", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white), onPressed: () { DocumentDetailsModal.show(context: context, docHash: hash); }, icon: const Icon(Icons.draw_rounded), label: const Text("Revisar y Firmar Documento")))])));
    }
    return const SizedBox.shrink();
  }
}

// ========================================================
// WIDGETS INTERACTIVOS CON ESTADO (Para guardar respuestas)
// ========================================================

class _ReadDocWidget extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> meta;
  final bool isEmployer;
  final VoidCallback onRefresh;
  const _ReadDocWidget({required this.task, required this.meta, required this.isEmployer, required this.onRefresh});
  @override
  State<_ReadDocWidget> createState() => _ReadDocWidgetState();
}
class _ReadDocWidgetState extends State<_ReadDocWidget> {
  bool _isChecked = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    bool isCompleted = widget.task['status'] == 'COMPLETED';
    String url = widget.meta['url'] ?? '';

    return Card(
      color: Colors.brown.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.menu_book_rounded, color: Colors.brown), SizedBox(width: 8), Text("Lectura Requerida", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown))]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(url.startsWith('http') ? url : 'https://$url'), mode: LaunchMode.externalApplication),
              child: Text(url, style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 16),
            if (isCompleted)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.done_all_rounded, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text("Leído y comprendido por el empleado: ${widget.task['completionProof'] ?? ''}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))]))
            else if (!widget.isEmployer && widget.task['status'] == 'IN_PROGRESS') ...[
              CheckboxListTile(
                title: const Text("He leído y comprendido este documento en su totalidad."),
                value: _isChecked,
                onChanged: (v) => setState(() => _isChecked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.brown,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  onPressed: (!_isChecked || _isSaving) ? null : () async {
                    setState(() => _isSaving = true);
                    String time = DateTime.now().toIso8601String();
                    await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(widget.task['id'], {"status": "COMPLETED", "completionProof": "Confirmación de lectura registrada a las $time"});
                    widget.onRefresh();
                    Navigator.pop(context);
                  },
                  icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded),
                  label: const Text("Confirmar Lectura y Finalizar"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _OpinionWidget extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> meta;
  final bool isEmployer;
  final VoidCallback onRefresh;
  const _OpinionWidget({required this.task, required this.meta, required this.isEmployer, required this.onRefresh});
  @override
  State<_OpinionWidget> createState() => _OpinionWidgetState();
}
class _OpinionWidgetState extends State<_OpinionWidget> {
  int _stars = 0;
  String _selectedOption = "";
  final _textCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    bool isCompleted = widget.task['status'] == 'COMPLETED';
    bool isPoll = widget.meta['isPoll'] == true;
    List<dynamic> options = widget.meta['options'] ?? [];

    return Card(
      color: Colors.orange.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(isPoll ? Icons.poll_rounded : Icons.star_rate_rounded, color: Colors.orange), const SizedBox(width: 8), Text(isPoll ? "Encuesta" : "Solicitud de Opinión", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
            const SizedBox(height: 12),
            Text(widget.meta['question'] ?? 'Sin pregunta', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
           if (isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), 
                child: Builder(
                  builder: (context) {
                    try {
                      final data = jsonDecode(widget.task['completionProof'] ?? '{}');
                      if (data.containsKey('respuesta')) {
                        // Vista para Encuesta
                        return Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text("Opción elegida: ${data['respuesta']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))]);
                      } else {
                        // Vista para Estrellas + Comentario
                        int stars = data['estrellas'] ?? 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: List.generate(5, (i) => Icon(i < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.orange, size: 24))),
                            const SizedBox(height: 12),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.format_quote_rounded, color: Colors.grey, size: 20), const SizedBox(width: 8), Expanded(child: Text(data['comentario'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)))]),
                          ],
                        );
                      }
                    } catch (e) {
                      return Text(widget.task['completionProof'] ?? '{}'); // Fallback por si acaso
                    }
                  }
                )
              )
            else if (!widget.isEmployer && widget.task['status'] == 'IN_PROGRESS') ...[
              if (isPoll)
                ...options.map((opt) => RadioListTile<String>(title: Text(opt), value: opt, groupValue: _selectedOption, activeColor: Colors.orange, onChanged: (v) => setState(() => _selectedOption = v!)))
              else ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(icon: Icon(index < _stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.orange, size: 36), onPressed: () => setState(() => _stars = index + 1)))),
                // 🔥 FONDO REPARADO M3
                TextField(controller: _textCtrl, maxLines: 2, decoration: InputDecoration(hintText: "Escribe tu feedback detallado...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05))),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: _isSaving ? null : () async {
                    if (isPoll && _selectedOption.isEmpty) return;
                    if (!isPoll && (_stars == 0 || _textCtrl.text.isEmpty)) return;
                    
                    setState(() => _isSaving = true);
                    Map<String, dynamic> result = isPoll ? {"respuesta": _selectedOption} : {"estrellas": _stars, "comentario": _textCtrl.text};
                    await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(widget.task['id'], {"status": "COMPLETED", "completionProof": jsonEncode(result)});
                    widget.onRefresh();
                    Navigator.pop(context);
                  },
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Enviar Respuesta y Finalizar"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _FormWidget extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> meta;
  final bool isEmployer;
  final VoidCallback onRefresh;
  const _FormWidget({required this.task, required this.meta, required this.isEmployer, required this.onRefresh});
  @override
  State<_FormWidget> createState() => _FormWidgetState();
}
class _FormWidgetState extends State<_FormWidget> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    List<dynamic> fields = widget.meta['fields'] ?? [];
    for (var f in fields) {
      _controllers[f.toString()] = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = widget.task['status'] == 'COMPLETED';
    List<dynamic> fields = widget.meta['fields'] ?? [];

    return Card(
      color: Colors.teal.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.dynamic_form_rounded, color: Colors.teal), SizedBox(width: 8), Text("Formulario de Recolección", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))]),
            const SizedBox(height: 16),
            
           if (isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), 
                child: Builder(
                  builder: (context) {
                    try {
                      final Map<String, dynamic> data = jsonDecode(widget.task['completionProof'] ?? '{}');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_rounded, size: 18, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text("${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 15))),
                            ],
                          ),
                        )).toList(),
                      );
                    } catch (e) {
                      return Text(widget.task['completionProof'] ?? '{}');
                    }
                  }
                )
              )
            else if (!widget.isEmployer && widget.task['status'] == 'IN_PROGRESS') ...[
              // 🔥 FONDO REPARADO M3
              ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _controllers[f], decoration: InputDecoration(labelText: f, filled: true, fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))))),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: _isSaving ? null : () async {
                    setState(() => _isSaving = true);
                    Map<String, String> result = {};
                    _controllers.forEach((k, v) => result[k] = v.text);
                    await Provider.of<BusinessTaskService>(context, listen: false).updateTaskStatus(widget.task['id'], {"status": "COMPLETED", "completionProof": jsonEncode(result)});
                    widget.onRefresh();
                    Navigator.pop(context);
                  },
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Datos y Finalizar"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}