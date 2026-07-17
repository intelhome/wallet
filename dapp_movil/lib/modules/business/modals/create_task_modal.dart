import 'package:dapp_movil/core/services/transaction_skeleton.dart';
import 'package:dapp_movil/modules/burner_wallets/services/burner_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/business_task_service.dart';

class CreateTaskModal {
  static void show(
   BuildContext context, 
    List<dynamic> rawActiveTeam, 
    List<dynamic> rawDepartments, 
    VoidCallback onSuccess, {
    String? initialTitle,
    String? initialDescription,
    String? initialAssigneeAlias,
    String? initialTaskType,
    double? initialBudget,
    List<String>? initialSubtasks,
    String? initialHours,
    String? initialUrgency,
    String? initialDeadline,
    double? initialGpsLat,
    double? initialGpsLon,
    String? initialMeetUrl,
    String? initialOpinionQuestion,
    List<String>? initialPollOptions,
    List<String>? initialFormFields,
  }){

//     final activeTeam = [];

//     final seenWallets = <String>{};
//     for (var m in rawActiveTeam) {
//       if (m['wallet'] != null && !seenWallets.contains(m['wallet'].toString())) {
//         seenWallets.add(m['wallet'].toString());
//         activeTeam.add(m);
//       }
//     }

//     final departments = [];
//     final seenDepts = <String>{};
//     for (var d in rawDepartments) {
//       if (d['id'] != null && !seenDepts.contains(d['id'].toString())) {
//         seenDepts.add(d['id'].toString());
//         departments.add(d);
//       }
//     }

//     if (activeTeam.isEmpty && departments.isEmpty) {
//       UIHelper.showCustomSnackbar("No tienes empleados o departamentos para asignar.", isError: true);
//       return;
//     }

// final titleCtrl = TextEditingController(text: initialTitle ?? '');
//     final descCtrl = TextEditingController(text: initialDescription ?? '');
//     final budgetCtrl = TextEditingController(text: initialBudget != null && initialBudget > 0 ? initialBudget.toString() : '');
//     final hoursCtrl = TextEditingController(text: initialHours ?? '');
    
//    List<Map<String, TextEditingController>> subTaskCtrls = initialSubtasks != null 
//         ? initialSubtasks.map((st) => {"title": TextEditingController(text: st), "hours": TextEditingController()}).toList()
//         : [];

//     final meetLinkCtrl = TextEditingController(text: initialMeetUrl ?? '');
//     final gpsLatCtrl = TextEditingController(text: initialGpsLat?.toString() ?? '');
//     final gpsLngCtrl = TextEditingController(text: initialGpsLon?.toString() ?? '');
//     final opinionQuestionCtrl = TextEditingController(text: initialOpinionQuestion ?? '');

//     List<TextEditingController> formFieldsCtrls = initialFormFields != null ? initialFormFields.map((e) => TextEditingController(text: e)).toList() : [];
//     List<TextEditingController> pollOptionsCtrls = initialPollOptions != null ? initialPollOptions.map((e) => TextEditingController(text: e)).toList() : [];
//     bool isPoll = pollOptionsCtrls.isNotEmpty;

//     final notaryHashCtrl = TextEditingController();
//     DateTime agendaDate = DateTime.now();
//     TimeOfDay agendaStart = TimeOfDay.now();
//     TimeOfDay agendaEnd = TimeOfDay.now();
//     final readDocUrlCtrl = TextEditingController();
//     //final opinionQuestionCtrl = TextEditingController();
//    // bool isPoll = false;
//     //List<TextEditingController> pollOptionsCtrls = [];
//     //List<TextEditingController> formFieldsCtrls = [];

//     // 🔥 3. SANITIZAR EL TIPO DE TAREA

//     String selectedTaskType = (initialTaskType ?? "STANDARD").toUpperCase();
//     const validTypes = ["STANDARD", "AGENDA", "MEET", "GPS", "NOTARY", "READ_DOC", "OPINION", "FORM"];
//     if (!validTypes.contains(selectedTaskType)) selectedTaskType = "STANDARD";
    
//     String urgency = initialUrgency ?? "MEDIUM";
//     DateTime selectedDeadline = initialDeadline != null ? DateTime.tryParse(initialDeadline) ?? DateTime.now().add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 1));

//     //String selectedTaskType = (initialTaskType ?? "STANDARD").toUpperCase();
//     //const validTypes = ["STANDARD", "AGENDA", "MEET", "GPS", "NOTARY", "READ_DOC", "OPINION", "FORM"];
//     if (!validTypes.contains(selectedTaskType)) selectedTaskType = "STANDARD";
    
//     //String urgency = "MEDIUM";
//     Map<String, dynamic>? employeeWorkload;
//     //DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));
    
//     // 🔥 4. SANITIZAR AL ASIGNADO Y EVITAR CRASH DEL DROPDOWN
//     String? selectedWallet;
//     bool assignToDept = departments.isNotEmpty && activeTeam.isEmpty; 

//     if (initialAssigneeAlias != null && initialAssigneeAlias.isNotEmpty && activeTeam.isNotEmpty) {
//       try {
//         selectedWallet = activeTeam.firstWhere((m) => 
//           (m['alias'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase() || 
//           (m['wallet'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase()
//         )['wallet'];
//         assignToDept = false;
//       } catch(e) {
//         selectedWallet = activeTeam.first['wallet']; // Si no lo encuentra, asigna al primero para evitar error
//       }
//     } else if (activeTeam.isNotEmpty) {
//       selectedWallet = activeTeam.first['wallet'];
//     }

//     String? selectedDept = departments.isNotEmpty ? departments.first['id'] : null;
//     bool isProcessing = false;

print("🛠️ CreateTaskModal.show -> Iniciando con ${rawActiveTeam.length} empleados crudos y ${rawDepartments.length} departamentos crudos.");

final activeTeam = [];
    final seenWallets = <String>{};
    
   for (var m in rawActiveTeam) {
      try {
        print("🛠️ Analizando empleado crudo: $m");
        Map<String, dynamic> memberCopy = Map<String, dynamic>.from(m);
        
        // 🔥 BÚSQUEDA PROFUNDA DE WALLET
        String? wallet = memberCopy['wallet']?.toString() ?? 
                         memberCopy['walletAddress']?.toString() ?? 
                         memberCopy['contactAddress']?.toString() ??
                         memberCopy['identifier']?.toString();
        
        if (wallet == null && memberCopy['user'] != null) {
          wallet = memberCopy['user']['wallet']?.toString() ?? memberCopy['user']['walletAddress']?.toString();
        }
        if (wallet == null && memberCopy['employee'] != null) {
          wallet = memberCopy['employee']['wallet']?.toString() ?? memberCopy['employee']['walletAddress']?.toString();
        }

        // 🔥 BÚSQUEDA PROFUNDA DE ALIAS (CON NULL SAFETY)
        String? rawAlias = memberCopy['alias']?.toString() ?? 
                           memberCopy['user']?['alias']?.toString() ?? 
                           memberCopy['employee']?['alias']?.toString();
        
        String finalAlias;
        if (rawAlias == null && wallet != null && wallet.length > 10) {
          finalAlias = "${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}";
        } else {
          finalAlias = rawAlias ?? 'Sin Alias';
        }
        
        print("🛠️ Resultado extracción -> Wallet: $wallet | Alias: $finalAlias");

        if (wallet != null && !seenWallets.contains(wallet)) {
          seenWallets.add(wallet);
          memberCopy['wallet'] = wallet; 
          memberCopy['alias'] = finalAlias; // Guardamos el alias final y seguro
          activeTeam.add(memberCopy);
          print("✅ Empleado agregado a activeTeam: $finalAlias");
        } else {
          print("❌ Empleado descartado (wallet nula o duplicada)");
        }
      } catch (e) {
        print("❌ Error parseando miembro en modal: $e");
      }
    }

    final departments = [];
    final seenDepts = <String>{};
    for (var d in rawDepartments) {
      print("🛠️ Analizando departamento crudo: $d");
      try {
        Map<String, dynamic> deptCopy = Map<String, dynamic>.from(d);
        String? id = deptCopy['id']?.toString() ?? deptCopy['_id']?.toString();
        print("🛠️ Resultado extracción -> ID Dept: $id");
        
        if (id != null && !seenDepts.contains(id)) {
          seenDepts.add(id);
          deptCopy['id'] = id;
          departments.add(deptCopy);
          print("✅ Departamento agregado: ${deptCopy['name']}");
        } else {
          print("❌ Departamento descartado (ID nulo o duplicado)");
        }
      } catch(e) {
         print("❌ Error parseando departamento en modal: $e");
      }
    }

    print("🛠️ FINAL: activeTeam (${activeTeam.length}), departments (${departments.length})");

    if (activeTeam.isEmpty && departments.isEmpty) {
      UIHelper.showCustomSnackbar("No tienes empleados o áreas para asignar.", isError: true);
      return;
    }

    // 🔥 2. CONTROLADORES PRE-LLENADOS
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');
    final budgetCtrl = TextEditingController(text: initialBudget != null && initialBudget > 0 ? initialBudget.toString() : '');
    final hoursCtrl = TextEditingController(text: initialHours ?? '');
    
    List<Map<String, TextEditingController>> subTaskCtrls = initialSubtasks != null 
        ? initialSubtasks.map((st) => {"title": TextEditingController(text: st), "hours": TextEditingController()}).toList()
        : []; 

    final meetLinkCtrl = TextEditingController(text: initialMeetUrl ?? '');
    final gpsLatCtrl = TextEditingController(text: initialGpsLat?.toString() ?? '');
    final gpsLngCtrl = TextEditingController(text: initialGpsLon?.toString() ?? '');
    final notaryHashCtrl = TextEditingController();
    DateTime agendaDate = DateTime.now();
    TimeOfDay agendaStart = TimeOfDay.now();
    TimeOfDay agendaEnd = TimeOfDay.now();
    final readDocUrlCtrl = TextEditingController();
    final opinionQuestionCtrl = TextEditingController(text: initialOpinionQuestion ?? '');
    
    List<TextEditingController> formFieldsCtrls = initialFormFields != null ? initialFormFields.map((e) => TextEditingController(text: e)).toList() : [];
    List<TextEditingController> pollOptionsCtrls = initialPollOptions != null ? initialPollOptions.map((e) => TextEditingController(text: e)).toList() : [];
    bool isPoll = pollOptionsCtrls.isNotEmpty;

    String selectedTaskType = (initialTaskType ?? "STANDARD").toUpperCase();
    const validTypes = ["STANDARD", "AGENDA", "MEET", "GPS", "NOTARY", "READ_DOC", "OPINION", "FORM"];
    if (!validTypes.contains(selectedTaskType)) selectedTaskType = "STANDARD";
    
    String urgency = initialUrgency ?? "MEDIUM";
    Map<String, dynamic>? employeeWorkload;
    DateTime selectedDeadline = initialDeadline != null ? DateTime.tryParse(initialDeadline) ?? DateTime.now().add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 1));
    
    // 🔥 3. AUTO-ASIGNACIÓN INTELIGENTE 100% LIBRE DE ERRORES
    bool assignToDept = false;
    
    if (activeTeam.isEmpty && departments.isNotEmpty) assignToDept = true;
    else if (activeTeam.isNotEmpty && departments.isEmpty) assignToDept = false;
    else if (initialAssigneeAlias != null && initialAssigneeAlias.isNotEmpty) {
      bool foundInDept = departments.any((d) => (d['name'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase());
      bool foundInTeam = activeTeam.any((m) => (m['alias'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase());
      if (foundInDept && !foundInTeam) assignToDept = true;
    }

    String? selectedWallet;
    if (activeTeam.isNotEmpty) {
      selectedWallet = activeTeam.first['wallet'];
      if (initialAssigneeAlias != null) {
        try {
          selectedWallet = activeTeam.firstWhere((m) => (m['alias'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase() || (m['wallet'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase())['wallet'];
        } catch(e) {}
      }
    }

    String? selectedDept;
    if (departments.isNotEmpty) {
      selectedDept = departments.first['id'];
      if (initialAssigneeAlias != null) {
        try {
          selectedDept = departments.firstWhere((d) => (d['name'] ?? '').toString().toLowerCase() == initialAssigneeAlias.toLowerCase())['id'];
        } catch(e) {}
      }
    }

    bool isProcessing = false;


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("Nueva Tarea / Actividad", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                
                // TIPO DE ASIGNACIÓN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Asignar a: "),
                    Switch(
                      value: assignToDept,
                      onChanged: (val) {
                        if (val && departments.isEmpty) {
                          UIHelper.showCustomSnackbar("No tienes áreas creadas.", isError: true);
                          return;
                        }
                        if (!val && activeTeam.isEmpty) {
                          UIHelper.showCustomSnackbar("No tienes empleados directos.", isError: true);
                          return;
                        }
                        setStateModal(() => assignToDept = val);
                      },
                    ),
                    Text(assignToDept ? "Área" : "Empleado", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),

              if (assignToDept && departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: InputDecoration(labelText: "Selecciona el Área", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    items: departments.map<DropdownMenuItem<String>>((dept) => DropdownMenuItem(value: dept['id'], child: Text(dept['name'] ?? 'Área'))).toList(),
                    onChanged: (val) => setStateModal(() => selectedDept = val),
                  )
                else if (activeTeam.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedWallet,
                    decoration: InputDecoration(labelText: "Selecciona el Empleado", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    items: activeTeam.map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier'] ?? 'Sin Nombre'))).toList(),
                    onChanged: (val) async {
                      setStateModal(() => selectedWallet = val);
                      if (val != null) {
                        var wl = await Provider.of<BusinessTaskService>(context, listen: false).getUserWorkload(val);
                        setStateModal(() => employeeWorkload = wl);
                      }
                    },
                  ),
                  if (employeeWorkload != null && employeeWorkload!['workloadStatus'] == 'OVERLOADED')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent), const SizedBox(width: 8), Expanded(child: Text("¡Advertencia! Este empleado ya tiene una carga de ${employeeWorkload!['workloadPercentage']}% (${employeeWorkload!['totalEstimatedHours']} horas activas).", style: const TextStyle(color: Colors.redAccent, fontSize: 12)))]))
                    )
                ],

                const SizedBox(height: 12),


             DropdownButtonFormField<String>(
                  value: selectedTaskType,
                  decoration: InputDecoration(labelText: "Tipo de Actividad Especial", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), filled: true, fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.05)),
                  items: const [
                    DropdownMenuItem(value: "STANDARD", child: Text("📋 Tarea Estándar / Operativa")),
                    DropdownMenuItem(value: "AGENDA", child: Text("📅 Agenda / Evento")),
                    DropdownMenuItem(value: "MEET", child: Text("📹 Reunión Virtual (Meet/Zoom)")),
                    DropdownMenuItem(value: "GPS", child: Text("📍 Ubicación GPS (Check-in)")),
                    DropdownMenuItem(value: "NOTARY", child: Text("🖋️ Firma Notarial (Contrato)")),
                    DropdownMenuItem(value: "READ_DOC", child: Text("📖 Leer Documento")),
                    DropdownMenuItem(value: "OPINION", child: Text("⭐ Opinión / Encuesta")),
                    DropdownMenuItem(value: "FORM", child: Text("📝 Formulario Dinámico")),
                  ],
                  onChanged: (val) => setStateModal(() => selectedTaskType = val!),
                ),
                const SizedBox(height: 12),
                
                // 🔥 CAMPOS DINÁMICOS SEGÚN EL TIPO
                if (selectedTaskType == "MEET")
                  Padding(padding: const EdgeInsets.only(bottom: 12.0), child: TextField(controller: meetLinkCtrl, decoration: InputDecoration(labelText: "Enlace de la Reunión", hintText: "https://zoom.us/j/...", prefixIcon: const Icon(Icons.video_call, color: Colors.blueAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                if (selectedTaskType == "GPS")
                  Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextField(controller: gpsLatCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: "Latitud", hintText: "-2.9001", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: gpsLngCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: "Longitud", hintText: "-79.0059", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: BorderSide(color: Colors.teal.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctxMap) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Row(children: [Icon(Icons.map_rounded, color: Colors.teal), SizedBox(width: 8), Text("Seleccionar Punto")]),
                                  content: SizedBox(
                                    width: double.maxFinite, height: 400,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      // 🔥 MAPA LIBRE (OPEN STREET MAP) - SIN API KEY 🔥
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: const LatLng(-2.900128, -79.005896), // Cuenca
                                          initialZoom: 14.0,
                                          onTap: (tapPosition, LatLng location) {
                                            setStateModal(() {
                                              gpsLatCtrl.text = location.latitude.toStringAsFixed(6);
                                              gpsLngCtrl.text = location.longitude.toStringAsFixed(6);
                                            });
                                            Navigator.pop(ctxMap);
                                            UIHelper.showCustomSnackbar("Coordenadas capturadas con éxito");
                                          },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.tuempresa.dapp_movil', // Cambia esto por el ID de tu app
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctxMap), child: const Text("Cancelar", style: TextStyle(color: Colors.grey)))],
                                )
                              );
                            },
                            icon: const Icon(Icons.place_rounded), label: const Text("Abrir Mapa Interactivo"),
                          ),
                        )
                      ],
                    ),
                  ),
                if (selectedTaskType == "NOTARY")
                  Padding(padding: const EdgeInsets.only(bottom: 12.0), child: TextField(controller: notaryHashCtrl, decoration: InputDecoration(labelText: "Hash del Documento", hintText: "0x...", prefixIcon: const Icon(Icons.verified, color: Colors.deepPurpleAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                
                if (selectedTaskType == "AGENDA")
                  Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      ListTile(title: const Text("Fecha del Evento"), trailing: Text("${agendaDate.day}/${agendaDate.month}/${agendaDate.year}"), onTap: () async { DateTime? d = await showDatePicker(context: context, initialDate: agendaDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))); if (d != null) setStateModal(() => agendaDate = d); }),
                      ListTile(title: const Text("Hora de Inicio"), trailing: Text(agendaStart.format(context)), onTap: () async { TimeOfDay? t = await showTimePicker(context: context, initialTime: agendaStart); if (t != null) setStateModal(() => agendaStart = t); }),
                      ListTile(title: const Text("Hora de Fin"), trailing: Text(agendaEnd.format(context)), onTap: () async { TimeOfDay? t = await showTimePicker(context: context, initialTime: agendaEnd); if (t != null) setStateModal(() => agendaEnd = t); }),
                    ]),
                  ),
                
                if (selectedTaskType == "READ_DOC")
                  Padding(padding: const EdgeInsets.only(bottom: 12.0), child: TextField(controller: readDocUrlCtrl, decoration: InputDecoration(labelText: "URL del Documento PDF", hintText: "https://drive.google.com/...", prefixIcon: const Icon(Icons.menu_book_rounded, color: Colors.brown), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                
                if (selectedTaskType == "OPINION")
                  Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      TextField(controller: opinionQuestionCtrl, decoration: InputDecoration(labelText: "Pregunta principal", hintText: "¿Qué te pareció el servicio?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      SwitchListTile(title: const Text("Convertir en Encuesta Cerrada"), subtitle: const Text("Muestra opciones en lugar de estrellas"), value: isPoll, onChanged: (v) => setStateModal(() => isPoll = v)),
                      if (isPoll) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Opciones:", style: TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () => setStateModal(() => pollOptionsCtrls.add(TextEditingController())), child: const Text("Añadir Opción"))]),
                        ...pollOptionsCtrls.map((ctrl) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: ctrl, decoration: InputDecoration(hintText: "Escribe una opción...", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))))
                      ]
                    ]),
                  ),
                  
                if (selectedTaskType == "FORM")
                  Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Campos a solicitar:", style: TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () => setStateModal(() => formFieldsCtrls.add(TextEditingController())), child: const Text("Añadir Campo"))]),
                      ...formFieldsCtrls.map((ctrl) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(controller: ctrl, decoration: InputDecoration(hintText: "Ej: Nombre del Cliente", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))))
                    ]),
                  ),

                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 12),
                
                Row(
                children: [
                  Expanded(child: TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Pto. Asignado (TTC)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Horas de Trabajo", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
                ],
              ),
              const SizedBox(height: 12),
              // 🔥 NUEVO: Selector de Fecha Límite
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(data: Theme.of(context), child: child!),
                  );
                  if (picked != null) setStateModal(() => selectedDeadline = picked);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      const Text("Fecha Límite: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text("${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}", textAlign: TextAlign.right)),
                    ],
                  ),
                ),
              ),
                const SizedBox(height: 12),

                // 🔥 SECCIÓN DE OBJETIVOS (NUEVO)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                   Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sub-Tareas / Entregables", style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline), label: const Text("Añadir"),
                            onPressed: () => setStateModal(() => subTaskCtrls.add({"title": TextEditingController(), "hours": TextEditingController()})),
                          )
                        ],
                      ),
                      ...subTaskCtrls.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: TextField(controller: entry.value['title'], decoration: InputDecoration(hintText: "Ej. Auditoría Local", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                            const SizedBox(width: 8),
                            Expanded(flex: 1, child: TextField(controller: entry.value['hours'], keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "Horas", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setStateModal(() => subTaskCtrls.removeAt(entry.key))),
                          ],
                        ),
                      ))
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: InputDecoration(labelText: "Nivel de Urgencia", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: const [
                    DropdownMenuItem(value: "LOW", child: Text("🟢 Baja (Flexible)", style: TextStyle(color: Colors.green))),
                    DropdownMenuItem(value: "MEDIUM", child: Text("🟠 Media (Normal)", style: TextStyle(color: Colors.orange))),
                    DropdownMenuItem(value: "HIGH", child: Text("🔴 Alta (Prioritaria)", style: TextStyle(color: Colors.red))),
                    DropdownMenuItem(value: "URGENT", child: Text("🟣 Urgente (Inmediata)", style: TextStyle(color: Colors.deepPurple))),
                  ],
                  onChanged: (val) => setStateModal(() => urgency = val!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
//                   onPressed: isProcessing ? null : () async {
//                       if (titleCtrl.text.isEmpty) return;

//                       //HUELLA OBLIGATORIA SIEMPRE AL CREAR
//                       FocusScope.of(context).unfocus();
//                       showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la asignación de la tarea."));
//                       HapticFeedback.mediumImpact();
//                       final auth = Provider.of<AuthCoreService>(context, listen: false);
//                       bool isAuth = await auth.authenticateUser();
//                       Navigator.pop(context); // Cerrar skeleton
                      
//                       if (!isAuth) return;

//                       setStateModal(() => isProcessing = true);
                      
//                       String? assignedBurnerAddress;
//                       double allocatedBudget = double.tryParse(budgetCtrl.text) ?? 0.0;
// if (allocatedBudget > 0) {
//                         final burnerService = Provider.of<BurnerService>(context, listen: false);
//                         String label = "Tarea: ${titleCtrl.text}";
                        
//                         print("🚀 [CREATE-TASK] Solicitando creación de Burner Wallet con $allocatedBudget TTC...");
                        
//                         // 🔥 FIX: Recibe correctamente el Map<String, dynamic>
//                         Map<String, dynamic> resBurner = await burnerService.createBurnerWallet(label, allocatedBudget);
                        
//                         if (resBurner["success"] == true) {
//                           print("✅ [CREATE-TASK] Burner Wallet creada en BD.");
//                           String newBurnerAddress = resBurner["data"]["burnerAddress"];
                          
//                           // 🔥 FIX: Fondeamos vía Web3 para que el contrato reciba los TTC reales
//                           print("💸 [CREATE-TASK] Fondeando $allocatedBudget TTC a $newBurnerAddress...");
//                           BigInt amountWei = BigInt.from(allocatedBudget * 1e18);
//                           String? signature = await auth.generateDelegatedSignature("SEND", toAddress: newBurnerAddress.toLowerCase(), amountWei: amountWei);
                          
//                           if (signature != null) {
//                             final txService = Provider.of<TransactionService>(context, listen: false);
//                             await txService.sendTokensL2(newBurnerAddress, allocatedBudget, signature);
//                             print("✅ [CREATE-TASK] Fondeo on-chain completado.");
//                           }

//                           // Obtenemos la última tarjeta creada para amarrarla a la tarea
//                           List<dynamic> burners = await burnerService.getActiveBurners();
//                           if (burners.isNotEmpty) {
//                             assignedBurnerAddress = burners.first['burnerAddress'];
//                             print("🔗 [CREATE-TASK] Tarjeta asignada a la tarea: $assignedBurnerAddress");
//                           }
//                         } else {
//                           String errorMsg = resBurner["error"] ?? "Error desconocido";
//                           print("❌ [CREATE-TASK] Falló la creación de la Burner: $errorMsg");
//                           UIHelper.showCustomSnackbar("Error al fondear presupuesto: $errorMsg", isError: true);
//                           setStateModal(() => isProcessing = false);
//                           return;
//                         }
//                       }
                      
//                       final service = Provider.of<BusinessTaskService>(context, listen: false);
                      
//                       Map<String, dynamic> meta = {};
//                       if (selectedTaskType == "MEET") meta = {"link": meetLinkCtrl.text};
//                       if (selectedTaskType == "GPS") meta = {"lat": double.tryParse(gpsLatCtrl.text), "lng": double.tryParse(gpsLngCtrl.text)};
//                       if (selectedTaskType == "NOTARY") meta = {"documentHash": notaryHashCtrl.text};
//                       if (selectedTaskType == "AGENDA") meta = {"date": agendaDate.toIso8601String(), "startTime": agendaStart.format(context), "endTime": agendaEnd.format(context)};
//                       if (selectedTaskType == "READ_DOC") meta = {"url": readDocUrlCtrl.text};
//                       if (selectedTaskType == "OPINION") meta = {"question": opinionQuestionCtrl.text, "isPoll": isPoll, "options": pollOptionsCtrls.map((c)=>c.text).toList()};
//                       if (selectedTaskType == "FORM") meta = {"fields": formFieldsCtrls.map((c)=>c.text).toList()};

//                       String res = await service.createTask({
//                         "businessWallet": auth.publicAddress.toLowerCase(),
//                         "assignedWallet": assignToDept ? null : selectedWallet, 
//                         "departmentId": assignToDept ? selectedDept : null,
//                         "taskType": selectedTaskType, 
//                         "typeMetadata": meta,         
//                         "title": titleCtrl.text,
//                         "description": descCtrl.text,
//                         "urgency": urgency,
//                         "allocatedResources": allocatedBudget,
//                         "burnerAddress": assignedBurnerAddress, // 🔥 AMARRAMOS LA TARJETA
//                         "estimatedHours": int.tryParse(hoursCtrl.text) ?? 0,
//                         "deadline": selectedDeadline.toIso8601String(),
//                         "subTasks": subTaskCtrls.where((c) => c['title']!.text.isNotEmpty).map((c) => {
//                           "title": c['title']!.text, 
//                           "estimatedHours": int.tryParse(c['hours']!.text) ?? 0
//                         }).toList()
//                       });

//                       if (res == "SUCCESS") {
//                         Navigator.pop(ctx);
//                         UIHelper.showCustomSnackbar("Tarea asignada y fondeada correctamente");
//                         onSuccess();
//                       } else {
//                         UIHelper.showCustomSnackbar(res, isError: true);
//                         setStateModal(() => isProcessing = false);
//                       }
//                     },

onPressed: isProcessing ? null : () async {
                      if (titleCtrl.text.isEmpty) return;
                      
                      final txService = Provider.of<TransactionService>(context, listen: false);
                      double allocatedBudget = double.tryParse(budgetCtrl.text) ?? 0.0;

                   
                      if (allocatedBudget > 0) {
                        String saldoRealStr = await txService.getBalance();
                        double saldoReal = double.tryParse(saldoRealStr) ?? 0.0;
                        if (allocatedBudget > saldoReal) {
                          UIHelper.showCustomSnackbar("Saldo insuficiente. Tienes ${saldoReal.toStringAsFixed(2)} TTC.", isError: true);
                          return;
                        }
                      }

                      // HUELLA OBLIGATORIA SIEMPRE AL CREAR
                      FocusScope.of(context).unfocus();
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la asignación de la tarea."));
                      HapticFeedback.mediumImpact();
                      final auth = Provider.of<AuthCoreService>(context, listen: false);
                      bool isAuth = await auth.authenticateUser();
                      Navigator.pop(context); 
                      
                      if (!isAuth) return;

                      setStateModal(() => isProcessing = true);
                      String? assignedBurnerAddress;
                      
                      if (allocatedBudget > 0) {
                        final burnerService = Provider.of<BurnerService>(context, listen: false);
                        String label = "Tarea: ${titleCtrl.text}";
                        
                        print("🚀 [CREATE-TASK] Creando Burner Wallet...");
                        Map<String, dynamic> resBurner = await burnerService.createBurnerWallet(label, allocatedBudget);
                        
                        if (resBurner["success"] == true) {
                          String newBurnerAddress = resBurner["data"]["burnerAddress"];
                          BigInt amountWei = BigInt.from(allocatedBudget * 1e18);
                          String? signature = await auth.generateDelegatedSignature("SEND", toAddress: newBurnerAddress.toLowerCase(), amountWei: amountWei);
                          
                          if (signature != null) {
                            print("💸 [CREATE-TASK] Ejecutando fondeo on-chain...");
                            final resFondeo = await txService.sendTokensL2(newBurnerAddress, allocatedBudget, signature);
                            
                            // 🔥 FIX 2: VALIDAR QUE EL FONDEO ON-CHAIN FUE EXITOSO
                            if (resFondeo.startsWith("Error")) {
                              UIHelper.showCustomSnackbar("Error al transferir presupuesto: $resFondeo", isError: true);
                              setStateModal(() => isProcessing = false);
                              return;
                            }
                            print("✅ [CREATE-TASK] Fondeo on-chain completado.");
                          }

                          List<dynamic> burners = await burnerService.getActiveBurners();
                          if (burners.isNotEmpty) {
                            assignedBurnerAddress = burners.first['burnerAddress'];
                          }
                        } else {
                          UIHelper.showCustomSnackbar("Error al crear billetera virtual", isError: true);
                          setStateModal(() => isProcessing = false);
                          return;
                        }
                      }
                      
                      final service = Provider.of<BusinessTaskService>(context, listen: false);
                      
                      Map<String, dynamic> payloadDTO = {
                        "businessWallet": auth.publicAddress.toLowerCase(),
                        "assignedWallet": assignToDept ? null : selectedWallet, 
                        "departmentId": assignToDept ? selectedDept : null,
                        "taskType": selectedTaskType, 
                        "title": titleCtrl.text,
                        "description": descCtrl.text,
                        "urgency": urgency,
                        "allocatedResources": allocatedBudget,
                        "burnerAddress": assignedBurnerAddress,
                        "estimatedHours": int.tryParse(hoursCtrl.text) ?? 0,
                        "deadline": selectedDeadline.toIso8601String(),
                        "subTasks": subTaskCtrls.where((c) => c['title']!.text.isNotEmpty).map((c) => {
                          "title": c['title']!.text, 
                          "estimatedHours": int.tryParse(c['hours']!.text) ?? 0
                        }).toList()
                      };

                      if (selectedTaskType == "MEET") payloadDTO["meetUrl"] = meetLinkCtrl.text;
                      if (selectedTaskType == "GPS") {
                        payloadDTO["gpsLat"] = double.tryParse(gpsLatCtrl.text);
                        payloadDTO["gpsLon"] = double.tryParse(gpsLngCtrl.text);
                      }
                      if (selectedTaskType == "OPINION") {
                        payloadDTO["opinionQuestion"] = opinionQuestionCtrl.text;
                        if (isPoll) payloadDTO["pollOptions"] = pollOptionsCtrls.map((c)=>c.text).toList();
                      }
                      // if (selectedTaskType == "FORM") payloadDTO["formFields"] = formFieldsCtrls.map((c)=>c.text).toList(); // Agrega esto si aplica

                      String res = await service.createTask(payloadDTO);

                      if (res == "SUCCESS") {
                        Navigator.pop(ctx);
                        UIHelper.showCustomSnackbar("Tarea asignada correctamente");
                        onSuccess();
                      } else {
                        UIHelper.showCustomSnackbar(res, isError: true);
                        setStateModal(() => isProcessing = false);
                      }
                    },
                    child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Asignar Actividad", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}