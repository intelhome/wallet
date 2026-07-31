import 'package:flutter/material.dart';
import '../../../core/helpers/share_helper.dart';
import '../../../core/helpers/ui_helper.dart';

class ReportPdfTaskModal {
  static void show({
    required BuildContext context,
    required List<dynamic> allTasks,
    required List<dynamic> teamMembers,
    required List<dynamic> departments,
  }) {
    String? pdfWallet;
    String? pdfDepartmentId;
    String? pdfStatus;
    DateTime? pdfDate;

    // Mapa de estados para los chips
    final Map<String, Map<String, dynamic>> estados = {
      "PENDING": {"label": "Pendientes", "color": Colors.orangeAccent},
      "IN_PROGRESS": {"label": "En Progreso", "color": const Color(0xFFC77DFF)},
      "COMPLETED": {"label": "En Revisión", "color": Colors.blueAccent},
      "REWORK_REQUESTED": {"label": "En Corrección", "color": Colors.redAccent},
      "APPROVED": {"label": "Aprobadas", "color": Colors.greenAccent},
    };

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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFBAC3FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.analytics_outlined, color: Color(0xFFBAC3FF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text("Configurar Reporte PDF", style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Selecciona los criterios específicos que se incluirán en el documento final corporativo.", style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6))),
                    const SizedBox(height: 24),
                    Divider(color: onSurface.withOpacity(0.05), height: 1),
                    const SizedBox(height: 24),

                    // 👥 EMPLEADO
                    Text("Filtrar por Empleado", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          hint: Text("Todos los empleados", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6))),
                          value: pdfWallet,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                          items: teamMembers.map((m) {
                            String name = m['alias'] ?? m['name'] ?? 'Usuario';
                            String wallet = m['walletAddress'] ?? m['wallet'] ?? '';
                            return DropdownMenuItem<String>(value: wallet.toLowerCase(), child: Text("@$name", style: TextStyle(color: onSurface)));
                          }).toList(),
                          onChanged: (val) => setModalState(() => pdfWallet = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🏢 DEPARTAMENTO
                    Text("Filtrar por Departamento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: theme.cardColor,
                          hint: Text("Todas las áreas", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6))),
                          value: pdfDepartmentId,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: onSurface.withOpacity(0.5)),
                          items: departments.map((d) {
                            return DropdownMenuItem<String>(value: d['id'].toString(), child: Text(d['name'] ?? '', style: TextStyle(color: onSurface)));
                          }).toList(),
                          onChanged: (val) => setModalState(() => pdfDepartmentId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 📊 ESTADO (CHIPS)
                    Text("Filtrar por Estado", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: estados.entries.map((entry) {
                        bool isSelected = pdfStatus == entry.key;
                        Color chipColor = entry.value['color'];
                        return GestureDetector(
                          onTap: () => setModalState(() => pdfStatus = isSelected ? null : entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? chipColor.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? chipColor : onSurface.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(entry.value['label'], style: TextStyle(color: isSelected ? chipColor : onSurface, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 📅 FECHA
                    Text("Filtrar por Fecha de Entrega", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pdfDate == null ? "Cualquier fecha asignada" : "Fecha seleccionada: ${pdfDate!.day}/${pdfDate!.month}/${pdfDate!.year}",
                              style: TextStyle(fontSize: 14, color: pdfDate == null ? onSurface.withOpacity(0.6) : onSurface),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: onSurface.withOpacity(0.05), foregroundColor: onSurface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            label: Text(pdfDate == null ? "Elegir" : "Cambiar", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (picked != null) setModalState(() => pdfDate = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📄 BOTÓN MAESTRO
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC3FF),
                          foregroundColor: const Color(0xFF00218d),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text("Generar Reporte PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          final pdfFilteredList = allTasks.where((task) {
                            if (pdfWallet != null && task['assignedWallet'] != pdfWallet) return false;
                            if (pdfDepartmentId != null && task['departmentId'] != pdfDepartmentId) return false;
                            if (pdfStatus != null && task['status'] != pdfStatus) return false;
                            if (pdfDate != null) {
                              if (task['deadline'] == null) return false;
                              DateTime? taskDeadline = DateTime.tryParse(task['deadline'].toString());
                              if (taskDeadline == null) return false;
                              if (taskDeadline.year != pdfDate!.year || taskDeadline.month != pdfDate!.month || taskDeadline.day != pdfDate!.day) return false;
                            }
                            return true;
                          }).toList();

                          if (pdfFilteredList.isEmpty) {
                            UIHelper.showCustomSnackbar("No se encontraron registros que coincidan con estos filtros específicos.", isError: true);
                            return;
                          }

                          Navigator.pop(ctx);
                          String subTituloReporte = "Criterio - Estado: ${pdfStatus ?? 'Todos'} | Área: ${pdfDepartmentId ?? 'Todas'}";
                          ShareHelper.exportarReporteTareasPDF(context, pdfFilteredList, subTituloReporte);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}