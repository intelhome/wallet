import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:dapp_movil/core/services/user_card.dart';
import 'package:dapp_movil/modules/admin/modals/configurar_plan_modal.dart';
import 'package:dapp_movil/modules/admin/screens/admin_subscription_analytics_screen.dart';
import 'package:dapp_movil/modules/admin/screens/pending_businesses_screen.dart';
import 'package:dapp_movil/modules/admin/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../auth_and_security/screens/splash_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isLoading = true;
  List<dynamic> _planes = [];

 final List<String> _todosLosModulos = [
    "COMPRAR", "ENVIAR", "RECIBIR", "RETIRAR", "MINAR", "BOSILLOS",
    "CARTERA_TEMPORAL", "DEUDAS", "VALIDAR_DOCUMENTO", "VALIDAR_HASH",
    "OPCION_NEGOCIO", "IA", "GRUPOS", "NOTARIA", "INVITACIONES", 
    "PAGOS_DIVIDIDOS", "EMPRESAS", "PAYPAL"
  ];

  @override
  void initState() {
    super.initState();
   WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPlanes();
    });
  }


Future<void> _cargarPlanes() async {
    if (!mounted) return;
    final cacheService = LocalCacheService();

    // 1. Caché Rápido
    final cached = cacheService.getCachedAdminPlans();
    if (cached.isNotEmpty && mounted) {
      setState(() { _planes = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fresh = await adminService.getPlans();
      if (mounted) {
        setState(() { _planes = fresh; _isLoading = false; });
      }
    } catch (e) {
      print("🚨 Error cargando planes en AdminPanel: $e");
      if (mounted && _planes.isEmpty) {
        UIHelper.showCustomSnackbar("Error interno al cargar datos del Admin", isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarPlan(Map<String, dynamic> plan) async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    String res = await adminService.updatePlan(plan);
    
    if (res == "Exito") {
      UIHelper.showCustomSnackbar("Plan ${plan['tier']} actualizado");
      _cargarPlanes();
    } else {
      UIHelper.showCustomSnackbar(res, isError: true);
    }
  }

  // Future<void> _guardarPlan(Map<String, dynamic> plan) async {
  //   final adminService = Provider.of<AdminService>(context, listen: false);
  //   String res = await adminService.updatePlan(plan);
    
  //   if (res == "Exito") {
  //     UIHelper.showCustomSnackbar("Plan ${plan['tier']} actualizado");
  //     _cargarPlanes();
  //   } else {
  //     UIHelper.showCustomSnackbar(res, isError: true);
  //   }
  // }

  // void _abrirModalGestionPlan(Map<String, dynamic> plan) {
  //   List<String> activos = List<String>.from(plan['allowedFeatures']);
  //   TextEditingController priceController = TextEditingController(text: plan['price'].toString());

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) => StatefulBuilder( 
  //       builder: (ctx, setModalState) {
  //         return Container(
  //           height: MediaQuery.of(ctx).size.height * 0.85,
  //           decoration: BoxDecoration(
  //             color: Theme.of(ctx).scaffoldBackgroundColor,
  //             borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
  //           ),
  //           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
  //               Text("Gestionar Plan ${plan['tier']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.purpleAccent)),
  //               const SizedBox(height: 24),
                
  //               TextField(
  //                 controller: priceController,
  //                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //                 decoration: InputDecoration(
  //                   labelText: "Precio Mensual (\$)",
  //                   filled: true,
  //                   fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  //                   prefixIcon: const Icon(Icons.attach_money),
  //                 ),
  //                 onChanged: (val) => plan['price'] = double.tryParse(val) ?? plan['price'],
  //               ),
  //               const SizedBox(height: 24),
  //               const Text("Módulos Habilitados:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //               const SizedBox(height: 10),
                
  //               Expanded(
  //                 child: ListView.builder(
  //                   itemCount: _todosLosModulos.length,
  //                   itemBuilder: (context, index) {
  //                     final modulo = _todosLosModulos[index];
  //                     bool isEnabled = activos.contains(modulo);
  //                     return SwitchListTile(
  //                       title: Text(modulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
  //                       value: isEnabled,
  //                       activeColor: Colors.purpleAccent,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //                       onChanged: (bool val) {
  //                         setModalState(() {
  //                           if (val) activos.add(modulo);
  //                           else activos.remove(modulo);
  //                           plan['allowedFeatures'] = activos;
  //                         });
  //                       },
  //                     );
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 55,
  //                 child: ElevatedButton.icon(
  //                   style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  //                   icon: const Icon(Icons.cloud_upload_rounded),
  //                   label: const Text("Guardar en Base de Datos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                   onPressed: () {
  //                     _guardarPlan(plan);
  //                     Navigator.pop(ctx);
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(height: 24),
  //             ],
  //           ),
  //         );
  //       }
  //     ),
  //   );
  // }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: onSurface, size: 24),
            const SizedBox(width: 8),
            Text("Gestión de Membresías", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 20)),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            onPressed: () {
              authCore.deleteWallet();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InitialRouter()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBAC3FF)))
          : RefreshIndicator(
              onRefresh: _cargarPlanes,
              color: const Color(0xFFBAC3FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 INFO TEXTO DE LA IMAGEN
                    Text(
                      "Configura y administra los planes de acceso para los usuarios. Define los límites y módulos disponibles para cada nivel.",
                      style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 🔥 TARJETA DE USUARIO CONSERVADA
                    UserCard(
                      address: authCore.publicAddress, balanceTTC: "ADMIN", stakedTTC: "N/A",
                      currentTier: "ADMIN", isDiscreet: false, useAvatarColors: true,
                      onToggleDiscreet: () {},
                    ),
                    const SizedBox(height: 32),

                    // 🔥 LISTA DE PLANES (DISEÑO DASHBOARD ADMIN)
                    _planes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "No se encontraron planes registrados en la Base de Datos.",
                                style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 14),
                              ),
                            ),
                          )
                        : Column(
                            children: _planes.map((plan) {
                              final String tierName = plan['tier']?.toString().toUpperCase() ?? 'DESCONOCIDO';
                              final double rawPrice = (plan['price'] is int) ? (plan['price'] as int).toDouble() : (plan['price'] ?? 0.0);
                              final List allowedFeat = plan['allowedFeatures'] ?? [];

                              // Variables dinámicas para el diseño del plan
                              Color accentColor = onSurface.withOpacity(0.5); // Default FREE
                              Color buttonColor = Colors.transparent;
                              Color buttonTextColor = onSurface;
                              bool isSolidButton = false;
                              IconData tierIcon = Icons.check_box_outline_blank_rounded;

                              if (tierName == 'BASIC') {
                                accentColor = const Color(0xFFBAC3FF);
                                buttonColor = const Color(0xFFBAC3FF);
                                buttonTextColor = const Color(0xFF00218d);
                                isSolidButton = true;
                                tierIcon = Icons.bolt_rounded;
                              } else if (tierName == 'PREMIUM') {
                                accentColor = Colors.amber;
                                buttonTextColor = Colors.amber;
                                tierIcon = Icons.star_rounded;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: tierName == 'FREE' ? onSurface.withOpacity(0.1) : accentColor.withOpacity(0.3), width: 1.5),
                                  boxShadow: tierName == 'BASIC' ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)] : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. ÍCONO SUPERIOR
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: tierName == 'FREE' ? onSurface.withOpacity(0.05) : accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12)
                                      ),
                                      child: Icon(tierIcon, color: accentColor, size: 20),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // 2. NOMBRE DEL PLAN Y PRECIO
                                    Text(tierName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: 0.5)),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("\$${rawPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: onSurface)),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                                          child: Text("/ mes", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // 3. PÍLDORA DE MÓDULOS
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: tierName == 'FREE' ? onSurface.withOpacity(0.05) : accentColor.withOpacity(0.1), 
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: tierName == 'FREE' ? onSurface.withOpacity(0.1) : accentColor.withOpacity(0.3))
                                      ),
                                      child: Text("${allowedFeat.length} módulos activos", style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Colors.white10, height: 1)),
                                    
                                    // 4. LISTA DE BENEFICIOS (Resumen Visual)
                                    _buildFeatureRow(Icons.check_circle_outline_rounded, tierName == 'FREE' ? "Billetera Básica" : "Todo lo de ${tierName == 'PREMIUM' ? 'BASIC' : 'FREE'}", onSurface, accentColor),
                                    _buildFeatureRow(Icons.check_circle_outline_rounded, "Límite configurado por plan", onSurface, accentColor),
                                    _buildFeatureRow(tierName == 'PREMIUM' ? Icons.all_inclusive_rounded : Icons.check_circle_outline_rounded, "Acceso a ${allowedFeat.length} módulos registrados", onSurface, accentColor),
                                    
                                    const SizedBox(height: 32),

                                    // 5. BOTÓN DE CONFIGURAR
                                    SizedBox(
                                      width: double.infinity, height: 52,
                                      child: isSolidButton
                                        ? ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: buttonTextColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), elevation: 0),
                                            onPressed: () {
                                              // 🔥 SE LLAMA AL NUEVO MODAL AQUÍ
                                              ConfigurarPlanModal.show(
                                                context: context,
                                                plan: plan,
                                                todosLosModulos: _todosLosModulos,
                                                onSave: _guardarPlan,
                                              );
                                            },
                                            child: const Text("CONFIGURAR MÓDULOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                                          )
                                        : OutlinedButton(
                                            style: OutlinedButton.styleFrom(foregroundColor: buttonTextColor, side: BorderSide(color: tierName == 'FREE' ? onSurface.withOpacity(0.2) : accentColor.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                                            onPressed: () {
                                              // 🔥 SE LLAMA AL NUEVO MODAL AQUÍ
                                              ConfigurarPlanModal.show(
                                                context: context,
                                                plan: plan,
                                                todosLosModulos: _todosLosModulos,
                                                onSave: _guardarPlan,
                                              );
                                            },
                                            child: const Text("CONFIGURAR MÓDULOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
                                          ),
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // WIDGET HELPER PARA LOS CHECKMARKS DE LA CARD
  Widget _buildFeatureRow(IconData icon, String text, Color onSurface, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
  
// @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final authCore = Provider.of<AuthCoreService>(context, listen: false);

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Centro de Control", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
//           ],
//         ),
//         centerTitle: true,
//         leading: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: SmartAvatar(address: authCore.publicAddress, size: 40),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
//             onPressed: () {
//               authCore.deleteWallet();
//               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InitialRouter()));
//             },
//           )
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
//           : RefreshIndicator(
//               onRefresh: _cargarPlanes,
//               color: Colors.purpleAccent,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 16),
//                     UserCard(
//                       address: authCore.publicAddress, balanceTTC: "ADMIN", stakedTTC: "N/A",
//                       currentTier: "ADMIN", isDiscreet: false, useAvatarColors: true,
//                       onToggleDiscreet: () {},
//                     ),
//                     const SizedBox(height: 40),

//                     Text("Auditoría y Negocios", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
//                     const SizedBox(height: 16),
                    
//                     ListTile(
//                       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingBusinessesScreen())),
//                       tileColor: theme.cardColor,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                       leading: Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                         child: const Icon(Icons.storefront_rounded, color: Colors.orange),
//                       ),
//                       title: const Text("Solicitudes de Empresa", style: TextStyle(fontWeight: FontWeight.bold)),
//                       subtitle: const Text("Revisa y aprueba nuevas cuentas RUC"),
//                       trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
//                     ),
                    
//                     const SizedBox(height: 12),

//                     ListTile(
//                       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSubscriptionAnalyticsScreen())),
//                       tileColor: theme.cardColor,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                       leading: Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                         child: const Icon(Icons.pie_chart_rounded, color: Colors.purpleAccent),
//                       ),
//                       title: const Text("Analíticas de Suscripciones", style: TextStyle(fontWeight: FontWeight.bold)),
//                       subtitle: const Text("Ingresos y control de planes de usuarios"),
//                       trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
//                     ),
                    
//                     const SizedBox(height: 40),

//                     // SECCIÓN DE PLANES
//                     Text("Gestión de Membresías", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
//                     const SizedBox(height: 16),
//                     _planes.isEmpty
//                         ? Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             child: Center(
//                               child: Text(
//                                 "No se encontraron planes registrados en la Base de Datos.",
//                                 style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
//                               ),
//                             ),
//                           )
//                         : Wrap(
//                             spacing: 16,
//                             runSpacing: 16,
//                             children: _planes.map((plan) {
//                               final String tierName = plan['tier'] ?? 'Desconocido';
//                               final double rawPrice = (plan['price'] is int) 
//                                   ? (plan['price'] as int).toDouble() 
//                                   : (plan['price'] ?? 0.0);
//                               final List allowedFeat = plan['allowedFeatures'] ?? [];

//                               // Determinar el color según el plan
//                               Color planColor = Colors.grey; // Default para FREE
//                               if (tierName.toUpperCase() == 'BASIC') planColor = const Color(0xFF4361EE);
//                               if (tierName.toUpperCase() == 'PREMIUM') planColor = Colors.amber;

//                               return GestureDetector(
//                                 onTap: () => _abrirModalGestionPlan(plan),
//                                 child: Container(
//                                   width: (MediaQuery.of(context).size.width / 2) - 32,
//                                   padding: const EdgeInsets.all(20),
//                                   decoration: BoxDecoration(
//                                     color: theme.cardColor,
//                                     borderRadius: BorderRadius.circular(24),
//                                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(color: planColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
//                                         child: Icon(Icons.workspace_premium_rounded, color: planColor, size: 28),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Text(tierName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
//                                       const SizedBox(height: 4),
//                                       Text("\$$rawPrice / mes", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5))),
//                                       const SizedBox(height: 12),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                         decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
//                                         child: Text("${allowedFeat.length} módulos", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
//}