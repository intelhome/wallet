import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/modules/business/modals/task_details_modal.dart';
import 'package:dapp_movil/modules/business/screens/business_calendar_screen.dart';
import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:dapp_movil/modules/business/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';


class JobInvitesScreen extends StatefulWidget {
  const JobInvitesScreen({super.key});
  @override
  State<JobInvitesScreen> createState() => _JobInvitesScreenState();
}

class _JobInvitesScreenState extends State<JobInvitesScreen> {
  List<dynamic> _invites = [];
  List<dynamic> _tasks = [];
  List<dynamic> _employers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Future<void> _cargarDatos() async {
  //   setState(() => _isLoading = true);
  //   final bService = Provider.of<BusinessService>(context, listen: false);
  //   final tService = Provider.of<BusinessTaskService>(context, listen: false);
    
  //   var results = await Future.wait<dynamic>([
  //     bService.getMyPendingInvites(),
  //     tService.getEmployeeTasks(),
  //     bService.getMyEmployers()
  //   ]);

  //   _invites = results[0];
  //   _tasks = results[1];
  //   _employers = results[2];
    
  //   if (mounted) setState(() => _isLoading = false);
  // }

  Future<void> _cargarDatos() async {
    final cacheService = LocalCacheService();

    // 1. Caché rápido
    final cachedInvites = cacheService.getCachedPendingInvites();
    final cachedTasks = cacheService.getCachedEmployeeTasks();
    final cachedEmployers = cacheService.getCachedMyEmployers();

    if (cachedInvites.isNotEmpty || cachedTasks.isNotEmpty || cachedEmployers.isNotEmpty) {
      if (mounted) setState(() {
        _invites = cachedInvites;
        _tasks = cachedTasks;
        _employers = cachedEmployers;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final bService = Provider.of<BusinessService>(context, listen: false);
    final tService = Provider.of<BusinessTaskService>(context, listen: false);
    
    var results = await Future.wait<dynamic>([
      bService.getMyPendingInvites(),
      tService.getEmployeeTasks(),
      bService.getMyEmployers()
    ]);

    if (mounted) {
      setState(() {
        _invites = results[0];
        _tasks = results[1];
        _employers = results[2];
        _isLoading = false;
      });
    }
  }

  Future<void> _responder(String wallet, bool aceptar) async {
    setState(() => _isLoading = true);
    final res = await Provider.of<BusinessService>(context, listen: false).respondToInvite(wallet, aceptar);
    if (res == "SUCCESS") {
      UIHelper.showCustomSnackbar(aceptar ? "¡Bienvenido al equipo!" : "Invitación rechazada");
      _cargarDatos();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Portal Laboral", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: "Mi Agenda Laboral",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessCalendarScreen(isEmployer: false)));
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.business_center_rounded), text: "Mis Empleos"),
              Tab(icon: Icon(Icons.work_rounded), text: "Invitaciones"), 
              Tab(icon: Icon(Icons.assignment_ind_rounded), text: "Mis Tareas")
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: MIS EMPLEOS (EMPRESAS)
            RefreshIndicator(
              onRefresh: _cargarDatos,
              child: _employers.isEmpty
                ? UIHelper.emptyState(context: context, icon: Icons.domain_disabled_rounded, title: "Sin Empleos", message: "No formas parte de ninguna empresa.")
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _employers.length,
                    itemBuilder: (ctx, i) {
                      var emp = _employers[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SmartAvatar(address: emp['wallet'], size: 50),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(emp['businessName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text("RUC: ${emp['ruc']}", style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Row(children: [const Icon(Icons.email, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(emp['email'] ?? "N/A")]),
                              const SizedBox(height: 8),
                              Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(emp['phoneNumber'] ?? "N/A")]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),

            // TAB 2: INVITACIONES PENDIENTES
            RefreshIndicator(
              onRefresh: _cargarDatos,
              child: _invites.isEmpty
                ? UIHelper.emptyState(context: context, icon: Icons.inbox_rounded, title: "Sin invitaciones", message: "No tienes ofertas de trabajo pendientes.")
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invites.length,
                    itemBuilder: (ctx, i) {
                      final inv = _invites[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 40),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text(inv['businessName'] ?? 'Empresa', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: OutlinedButton(onPressed: () => _responder(inv['businessWallet'], false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Rechazar"))),
                                  const SizedBox(width: 10),
                                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _responder(inv['businessWallet'], true), child: const Text("Aceptar Puesto"))),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),

            // TAB 3: MIS TAREAS
            RefreshIndicator(
              onRefresh: _cargarDatos,
              child: _tasks.isEmpty
                ? UIHelper.emptyState(context: context, icon: Icons.celebration_rounded, title: "Todo al día", message: "No tienes tareas pendientes.")
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                   itemBuilder: (ctx, i) => TaskCard(
                      task: _tasks[i], 
                      isEmployer: false, 
                      onRefresh: _cargarDatos,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
// class JobInvitesScreen extends StatefulWidget {
//   const JobInvitesScreen({super.key});

//   @override
//   State<JobInvitesScreen> createState() => _JobInvitesScreenState();
// }

// class _JobInvitesScreenState extends State<JobInvitesScreen> {
//   List<dynamic> _invites = [];
//   List<dynamic> _employers = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _cargarDatosLaborales();
//   }

//   Future<void> _cargarDatosLaborales() async {
//     setState(() => _isLoading = true);
//     final service = Provider.of<BusinessService>(context, listen: false);
    
//     // Ejecutamos ambas peticiones al mismo tiempo para mayor rapidez
//     var results = await Future.wait([
//       service.getMyPendingInvites(),
//       service.getMyEmployers(),
//     ]);

//     _invites = results[0];
//     _employers = results[1];
    
//     if (mounted) setState(() => _isLoading = false);
//   }

//   Future<void> _responder(String wallet, bool aceptar) async {
//     setState(() => _isLoading = true);
//     final service = Provider.of<BusinessService>(context, listen: false);
//     String res = await service.respondToInvite(wallet, aceptar);
    
//     if (res == "SUCCESS") {
//       UIHelper.showCustomSnackbar(aceptar ? "¡Felicidades por tu nuevo empleo!" : "Invitación rechazada");
//       _cargarDatosLaborales();
//     } else {
//       UIHelper.showCustomSnackbar(res, isError: true);
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Gestión de Empleo", style: TextStyle(fontWeight: FontWeight.bold)),
//           bottom: const TabBar(
//             tabs: [
//               Tab(icon: Icon(Icons.work_rounded), text: "Mis Empleadores"),
//               Tab(icon: Icon(Icons.local_post_office_rounded), text: "Ofertas"),
//             ],
//           ),
//         ),
//         body: _isLoading 
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               children: [
//                 // TAB 1: MIS EMPLEADORES (Empresas a las que pertenezco)
//                 RefreshIndicator(
//                   onRefresh: _cargarDatosLaborales,
//                   child: _employers.isEmpty
//                     ? UIHelper.emptyState(context: context, icon: Icons.domain_disabled_rounded, title: "Sin Empleos", message: "Actualmente no formas parte del equipo comercial de ninguna empresa.")
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: _employers.length,
//                         itemBuilder: (ctx, i) {
//                           var emp = _employers[i];
//                           return Card(
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(20),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       SmartAvatar(address: emp['wallet'], size: 50),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(emp['businessName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                                             Text("RUC: ${emp['ruc']}", style: const TextStyle(color: Colors.grey)),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const Divider(height: 30),
//                                   Row(children: [const Icon(Icons.email, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(emp['email'] ?? "N/A")]),
//                                   const SizedBox(height: 8),
//                                   Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(emp['phoneNumber'] ?? "N/A")]),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                 ),

//                 // TAB 2: OFERTAS PENDIENTES
//                 RefreshIndicator(
//                   onRefresh: _cargarDatosLaborales,
//                   child: _invites.isEmpty
//                     ? UIHelper.emptyState(context: context, icon: Icons.work_off_rounded, title: "Sin ofertas", message: "No tienes invitaciones de empresas pendientes.")
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: _invites.length,
//                         itemBuilder: (ctx, i) {
//                           var inv = _invites[i];
//                           return Card(
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 children: [
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 40),
//                                       const SizedBox(width: 16),
//                                       Expanded(child: Text(inv['businessName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     children: [
//                                       Expanded(child: OutlinedButton(onPressed: () => _responder(inv['businessWallet'], false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Rechazar"))),
//                                       const SizedBox(width: 10),
//                                       Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _responder(inv['businessWallet'], true), child: const Text("Aceptar Puesto"))),
//                                     ],
//                                   )
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                 ),
//               ],
//             ),
//       ),
//     );
//   }
// }