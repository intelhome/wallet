import 'package:flutter/material.dart';

class ConfigurarPlanModal {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> plan,
    required List<String> todosLosModulos,
    required Function(Map<String, dynamic>) onSave,
  }) {
    List<String> activos = List<String>.from(plan['allowedFeatures'] ?? []);
    TextEditingController priceController = TextEditingController(text: plan['price'].toString());
    String tierName = (plan['tier'] ?? 'DESCONOCIDO').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final onSurface = theme.colorScheme.onSurface;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.90, // Casi pantalla completa
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.8)), onPressed: () => Navigator.pop(ctx)),
                      Expanded(
                        child: Text("Configurar Plan\n$tierName", textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFE0B0FF), height: 1.2)),
                      ),
                      const SizedBox(width: 48), // Espaciador para centrar
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Precio Mensual (\$)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.8))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.1))),
                            prefixIcon: Icon(Icons.attach_money_rounded, color: onSurface.withOpacity(0.6)),
                          ),
                          onChanged: (val) => plan['price'] = double.tryParse(val) ?? plan['price'],
                        ),
                        const SizedBox(height: 32),
                        
                        Text("Módulos Habilitados:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
                        const SizedBox(height: 16),
                        
                        // LISTA DE MÓDULOS TIPO CARD
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: onSurface.withOpacity(0.05)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: todosLosModulos.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: onSurface.withOpacity(0.05)),
                            itemBuilder: (context, index) {
                              final modulo = todosLosModulos[index];
                              bool isEnabled = activos.contains(modulo);
                              return SwitchListTile(
                                title: Text(modulo.replaceAll("_", " "), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onSurface.withOpacity(0.9))),
                                value: isEnabled,
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFFE0B0FF),
                                inactiveThumbColor: onSurface.withOpacity(0.4),
                                inactiveTrackColor: onSurface.withOpacity(0.1),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                onChanged: (bool val) {
                                  setModalState(() {
                                    if (val) activos.add(modulo);
                                    else activos.remove(modulo);
                                    plan['allowedFeatures'] = activos;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // BOTÓN STICKY
                Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: onSurface.withOpacity(0.05))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0B0FF), 
                        foregroundColor: const Color(0xFF5A2A7A), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        onSave(plan);
                        Navigator.pop(ctx);
                      },
                    ),
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