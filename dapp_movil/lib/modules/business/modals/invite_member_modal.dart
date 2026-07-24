import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../services/business_service.dart';

class InviteMemberModal {
  static void show(BuildContext context, VoidCallback onRefresh) {
    final identifierController = TextEditingController();
    String type = "ALIAS";
    String role = "CASHIER"; // Mantengo tu lógica de roles aunque el UI sugiera Área

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final onSurface = colorScheme.onSurface;

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 32),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ICONO CABECERA
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.person_add_alt_1_rounded, size: 60, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Invitar Empleado", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface)),
                const SizedBox(height: 8),
                Text(
                  "Envía una oferta de trabajo para unirse a tu equipo. Puedes buscarlos por su alias de TTC, número de cédula o dirección de billetera.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: onSurface.withOpacity(0.05))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Método de Búsqueda", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
                      const SizedBox(height: 8),
                      // TABS PERSONALIZADOS (ESTILO MOCKUP)
                      Container(
                        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: ["ALIAS", "CEDULA", "WALLET"].map((t) {
                            bool isSelected = type == t;
                            String label = t == "ALIAS" ? "Alias" : t == "CEDULA" ? "Cédula" : "Billetera";
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => type = t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF7209B7) : Colors.transparent, // Púrpura del mockup
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text("Identificación", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: identifierController,
                        style: TextStyle(color: onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: type == "ALIAS" ? "Ingresa el alias ej: @juanperez" : type == "CEDULA" ? "Ej: 0987654321" : "Ej: 0x...",
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                          prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                          filled: true, fillColor: theme.scaffoldBackgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text("Rol en la Empresa", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.6))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: role,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.work_outline_rounded, color: onSurface.withOpacity(0.5)),
                          filled: true, fillColor: theme.scaffoldBackgroundColor, 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                        ),
                        items: const [
                          DropdownMenuItem(value: "CASHIER", child: Text("Cajero (Solo cobrar)", style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: "ADMIN", child: Text("Administrador (Todos los permisos)", style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (v) => setModalState(() => role = v!),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBAC3FF), 
                            foregroundColor: const Color(0xFF00218d),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text("Enviar Oferta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: () async {
                            if (identifierController.text.isEmpty) return;
                            Navigator.pop(ctx);
                            UIHelper.showCustomSnackbar("Enviando invitación...", isError: false);
                            final bService = Provider.of<BusinessService>(context, listen: false);
                            String res = await bService.inviteTeamMember(identifierController.text.trim(), type, role);
                            if (res == "SUCCESS") {
                              UIHelper.showCustomSnackbar("¡Invitación enviada!");
                              onRefresh(); 
                            } else {
                              UIHelper.showCustomSnackbar(res, isError: true);
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}