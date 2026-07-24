import 'package:dapp_movil/core/services/smart_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';

class DepartmentDetailsModal {
 static void show(BuildContext context, Map<String, dynamic> department, List<dynamic> activeTeam, VoidCallback onRefresh) {
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;
          
          List<dynamic> membersWallets = department['memberWallets'] ?? [];
          
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABECERA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(department['name'], style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: onSurface, height: 1.1))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28), 
                      onPressed: () async {
                        bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Eliminar Área", mensaje: "¿Estás seguro de eliminar este departamento?", textoConfirmar: "Eliminar", colorConfirmar: Colors.red);
                        if (confirm == true) {
                          await Provider.of<BusinessService>(context, listen: false).deleteDepartment(department['id']);
                          Navigator.pop(ctx); onRefresh();
                        }
                      }
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(department['description'] ?? "Departamento clave de la organización.", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.4)),
                const SizedBox(height: 24),
                Divider(color: onSurface.withOpacity(0.1)),
                const SizedBox(height: 24),

                // TARJETA DE PRESUPUESTO
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0C3E), // Fondo oscuro violáceo
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF7209B7).withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PRESUPUESTO ASIGNADO", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(department['allocatedBudget'].toString(), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          const Text("TTC", style: TextStyle(color: Color(0xFFC77DFF), fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: const Text("Auditoría en regla", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CABECERA EQUIPO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded, color: onSurface.withOpacity(0.7), size: 24),
                        const SizedBox(width: 12),
                        Text("Miembros\nActuales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface, height: 1.1)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4361EE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text("Añadir\nMiembro", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        // Modal para elegir empleado sin ensuciar la UI principal
                        final available = activeTeam.where((m) => !membersWallets.contains(m['wallet'])).toList();
                        if (available.isEmpty) {
                          UIHelper.showCustomSnackbar("Todos los empleados ya están en este departamento.");
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: theme.cardColor,
                            title: const Text("Añadir al Área", style: TextStyle(fontWeight: FontWeight.bold)),
                            content: DropdownButtonFormField<String>(
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: onSurface.withOpacity(0.05)),
                              hint: const Text("Selecciona un empleado"),
                              items: available.map<DropdownMenuItem<String>>((member) => DropdownMenuItem(value: member['wallet'], child: Text(member['alias'] ?? member['identifier']))).toList(),
                              onChanged: (newWallet) async {
                                if (newWallet == null) return;
                                Navigator.pop(c);
                                setStateModal(() => isProcessing = true);
                                await Provider.of<BusinessService>(context, listen: false).addMemberToDepartment(department['id'], newWallet);
                                Navigator.pop(ctx); onRefresh();
                              },
                            ),
                          )
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // LISTA DE MIEMBROS
                Expanded(
                  child: isProcessing 
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) 
                    : membersWallets.isEmpty
                      ? const Center(child: Text("No hay miembros en esta área."))
                      : ListView.builder(
                          itemCount: membersWallets.length,
                          itemBuilder: (context, index) {
                            String w = membersWallets[index];
                            var userDetails = activeTeam.firstWhere((m) => m['wallet'] == w, orElse: () => {'alias': w, 'wallet': w, 'cedula': 'N/A', 'phoneNumber': 'N/A', 'email': 'N/A'});
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: onSurface.withOpacity(0.05))
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SmartAvatar(address: w, size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(userDetails['alias'] ?? "Usuario", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            Text("${w.substring(0,6)}...${w.substring(w.length-4)}".toUpperCase(), style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11, fontFamily: 'monospace')),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.person_remove_rounded, color: onSurface.withOpacity(0.4), size: 20), 
                                        onPressed: () async {
                                          bool? confirm = await UIHelper.mostrarConfirmacion(context: context, titulo: "Remover Miembro", mensaje: "¿Sacar a este usuario del departamento?", textoConfirmar: "Remover", colorConfirmar: Colors.red);
                                          if (confirm == true) {
                                            setStateModal(() => isProcessing = true);
                                            await Provider.of<BusinessService>(context, listen: false).removeMemberFromDepartment(department['id'], w);
                                            Navigator.pop(ctx); onRefresh();
                                          }
                                        }
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildGridInfo("CÉDULA", userDetails['cedula'] ?? "N/A", onSurface)),
                                      Expanded(child: _buildGridInfo("CELULAR", userDetails['phoneNumber'] ?? "N/A", onSurface)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildGridInfo("CORREO", userDetails['email'] ?? "N/A", onSurface),
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildGridInfo(String label, String value, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.5), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface)),
      ],
    );
  }
}