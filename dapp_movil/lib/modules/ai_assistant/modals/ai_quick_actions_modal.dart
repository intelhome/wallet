import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import 'package:provider/provider.dart';

class AiQuickActionsModal {
  
  // Lista maestra unificada. La bandera 'isBusinessOnly' determinará si se muestra o no.
  static final List<Map<String, dynamic>> allActions = [
    // --- ACCIONES GENERALES (Para todos) ---
    {"id": "TRANSFER", "isBusinessOnly": false, "icon": Icons.swap_horiz_rounded, "label": "Transferir", "prompt": "Quiero transferir fondos."},
    {"id": "PAYPAL", "isBusinessOnly": false, "icon": Icons.paypal_rounded, "label": "Enviar PayPal", "prompt": "Quiero enviar dinero por PayPal."},
    {"id": "SPLIT", "isBusinessOnly": false, "icon": Icons.call_split_rounded, "label": "Dividir Cuenta", "prompt": "Quiero dividir un pago en grupo."},
    {"id": "DEBT", "isBusinessOnly": false, "icon": Icons.request_quote_rounded, "label": "Crear Deuda", "prompt": "Quiero crear un acuerdo de deuda."},
    {"id": "INSTALLMENTS", "isBusinessOnly": false, "icon": Icons.calendar_today_rounded, "label": "Pago en Cuotas", "prompt": "Quiero configurar un pago en cuotas."},
    {"id": "SCHEDULE", "isBusinessOnly": false, "icon": Icons.schedule_send_rounded, "label": "Pago Programado", "prompt": "Quiero programar un pago para el futuro."},
    {"id": "VAULT", "isBusinessOnly": false, "icon": Icons.savings_rounded, "label": "Crear Ucha", "prompt": "Quiero ahorrar dinero en una Ucha o Bolsillo."},
    {"id": "STAKE", "isBusinessOnly": false, "icon": Icons.lock_clock_rounded, "label": "Hacer Staking", "prompt": "Quiero bloquear TTC en Staking."},
    {"id": "BUY", "isBusinessOnly": false, "icon": Icons.add_shopping_cart_rounded, "label": "Comprar TTC", "prompt": "Quiero comprar saldo TTC."},
    {"id": "CROWDFUND", "isBusinessOnly": false, "icon": Icons.volunteer_activism_rounded, "label": "Recaudación", "prompt": "Quiero crear una campaña de recaudación."},
    {"id": "GROUP", "isBusinessOnly": false, "icon": Icons.groups_rounded, "label": "Crear Fondo", "prompt": "Quiero crear un fondo común o grupo compartido."},
    {"id": "NOTARY", "isBusinessOnly": false, "icon": Icons.verified_rounded, "label": "Notariar Doc.", "prompt": "Quiero firmar y notariar un documento en blockchain."},
    {"id": "BURNER", "isBusinessOnly": false, "icon": Icons.local_fire_department_rounded, "label": "Billetera Desechable", "prompt": "Quiero crear una tarjeta prepago desechable."},
    {"id": "CHAT", "isBusinessOnly": false, "icon": Icons.chat_bubble_rounded, "label": "Enviar Mensaje", "prompt": "Quiero enviarle un mensaje por chat a alguien."},
    {"id": "REPORT", "isBusinessOnly": false, "icon": Icons.analytics_rounded, "label": "Reporte de Gastos", "prompt": "Genera mi reporte de gastos financieros."},
    
    // --- ACCIONES CORPORATIVAS (Solo Empresa/Admin) ---
    {"id": "TASK", "isBusinessOnly": true, "icon": Icons.assignment_rounded, "label": "Crear Tarea", "prompt": "Quiero asignar una tarea a un empleado."},
    {"id": "DEPT", "isBusinessOnly": true, "icon": Icons.domain_rounded, "label": "Crear Área", "prompt": "Quiero crear un nuevo departamento o área."},
    {"id": "ADD_EMP", "isBusinessOnly": true, "icon": Icons.person_add_rounded, "label": "Añadir a Área", "prompt": "Quiero añadir a un empleado a un departamento."},
    {"id": "INVITE_EMP", "isBusinessOnly": true, "icon": Icons.work_outline_rounded, "label": "Invitar Empleado", "prompt": "Quiero invitar a alguien a unirse a mi empresa."},
  ];

  static void show(BuildContext context, List<String> currentActiveIds, Function(List<String>) onSave) {
    // 1. Verificamos el rol del usuario para filtrar la lista
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final bool isBusiness = authCore.role == 'ROLE_BUSINESS' || authCore.role == 'ROLE_ADMIN';

    // 2. Filtramos las acciones. Si NO es empresa, quitamos las que tengan isBusinessOnly = true
    final List<Map<String, dynamic>> availableActions = allActions.where((action) {
      if (action['isBusinessOnly'] == true && !isBusiness) return false;
      return true;
    }).toList();

    // 3. Limpiamos las seleccionadas por si quedó alguna basura en caché de un cambio de cuenta
    List<String> selectedIds = currentActiveIds.where((id) {
      return availableActions.any((action) => action['id'] == id);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final onSurface = colorScheme.onSurface;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85, // Modal más alto para la lista
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFC77DFF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFFC77DFF), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text("Personalizar Acciones", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.5)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Selecciona hasta 5 comandos rápidos. Tienes ${selectedIds.length}/5.", style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6))),
                  const SizedBox(height: 16),

                  // LISTA DE ACCIONES CON CHECKBOXES
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableActions.length,
                      itemBuilder: (ctxList, i) {
                        final action = availableActions[i];
                        final isSelected = selectedIds.contains(action['id']);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFC77DFF).withOpacity(0.1) : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? const Color(0xFFC77DFF) : onSurface.withOpacity(0.05)),
                          ),
                          child: CheckboxListTile(
                            secondary: Icon(action['icon'], color: isSelected ? const Color(0xFFC77DFF) : onSurface.withOpacity(0.5)),
                            title: Text(action['label'], style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(action['prompt'], style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11)),
                            value: isSelected,
                            activeColor: const Color(0xFFC77DFF),
                            checkColor: theme.cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onChanged: (bool? val) {
                              setModalState(() {
                                if (val == true) {
                                  if (selectedIds.length >= 5) {
                                    UIHelper.showCustomSnackbar("Has alcanzado el límite de 5 acciones.", isError: true);
                                    return;
                                  }
                                  selectedIds.add(action['id']);
                                } else {
                                  selectedIds.remove(action['id']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC77DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Guardar Preferencias", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        if (selectedIds.isEmpty) {
                          UIHelper.showCustomSnackbar("Debes seleccionar al menos 1 acción.", isError: true);
                          return;
                        }
                        
                        // Guardar localmente
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('ai_quick_actions', selectedIds);
                        
                        onSave(selectedIds);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}