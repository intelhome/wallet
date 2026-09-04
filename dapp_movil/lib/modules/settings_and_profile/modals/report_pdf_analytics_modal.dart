import 'package:flutter/material.dart';
import '../../../core/helpers/share_helper.dart';

class ReportPdfAnalyticsModal {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> analyticsData,
  }) {
    bool incIngresos = true;
    bool incGastos = true;
    bool incGraficaDiaria = true;

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
                          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.pie_chart_rounded, color: colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text("Reporte de Analíticas", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Selecciona los segmentos que deseas incluir en tu reporte financiero.", style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6))),
                    const SizedBox(height: 24),
                    Divider(color: onSurface.withOpacity(0.05), height: 1),
                    const SizedBox(height: 24),

                    // 📑 SECCIONES A INCLUIR
                    Text("Secciones del Documento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurface)),
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      title: const Text("Desglose de Ingresos", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Fuentes de ingreso y cashback"),
                      activeColor: colorScheme.primary,
                      value: incIngresos,
                      onChanged: (val) => setModalState(() => incIngresos = val),
                    ),
                    SwitchListTile(
                      title: const Text("Desglose de Gastos", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Salidas y transferencias"),
                      activeColor: colorScheme.primary,
                      value: incGastos,
                      onChanged: (val) => setModalState(() => incGastos = val),
                    ),
                    SwitchListTile(
                      title: const Text("Actividad Diaria", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Registro temporal de movimientos"),
                      activeColor: colorScheme.primary,
                      value: incGraficaDiaria,
                      onChanged: (val) => setModalState(() => incGraficaDiaria = val),
                    ),
                    const SizedBox(height: 32),

                    // 📄 BOTÓN MAESTRO
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text("Generar PDF de Finanzas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          // Clonamos la data para no afectar la UI principal
                          Map<String, dynamic> filteredData = Map.from(analyticsData);
                          
                          if (!incIngresos) {
                            filteredData['distribucionIngresos'] = {};
                            filteredData['totalIngresos'] = 0.0;
                          }
                          if (!incGastos) {
                            filteredData['distribucionGastos'] = {};
                            filteredData['totalEgresos'] = 0.0;
                          }
                          if (!incGraficaDiaria) {
                            filteredData['actividadDiaria'] = [];
                          }

                          Navigator.pop(ctx);
                          ShareHelper.generarYCompartirPDFAnaliticas(context, filteredData);
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