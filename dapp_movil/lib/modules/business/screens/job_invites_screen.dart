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
                      String empName = emp['businessName'] ?? "Empresa";
                      String firstLetter = empName.isNotEmpty ? empName[0].toUpperCase() : "E";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        color: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                           Row(
                                children: [
                                  // 🔥 FIX: Avatar Inteligente en lugar de inicial
                                  SmartAvatar(address: emp['wallet'] ?? '', size: 65),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(empName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(emp['industry'] ?? "Tecnología y Software", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.withOpacity(0.2)),
                              const SizedBox(height: 20),
                              
                              _buildInfoRow(Icons.fingerprint_rounded, "RUC", emp['ruc'] ?? "N/A"),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.location_on_outlined, "UBICACIÓN", emp['location'] ?? "Cuenca, Ecuador"),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.email_outlined, "EMAIL", emp['email'] ?? "N/A"),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.phone_outlined, "TELÉFONO", emp['phoneNumber'] ?? "N/A"),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.language_rounded, "SITIO WEB", emp['website'] ?? "No disponible"),
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
                      String empName = inv['businessName'] ?? 'Empresa';
                      String firstLetter = empName.isNotEmpty ? empName[0].toUpperCase() : "E";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        color: Theme.of(context).cardColor,
                        elevation: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             Row(
                                children: [
                                  
                                  SmartAvatar(address: inv['businessWallet'] ?? '', size: 54),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(empName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Te ha invitado a unirte a su equipo comercial.", 
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _responder(inv['businessWallet'], false), 
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ), 
                                      child: const Text("Rechazar", style: TextStyle(fontWeight: FontWeight.bold))
                                    )
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4361EE), 
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 0,
                                      ), 
                                      onPressed: () => _responder(inv['businessWallet'], true), 
                                      child: const Text("Aceptar Puesto", style: TextStyle(fontWeight: FontWeight.bold))
                                    )
                                  ),
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

Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
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