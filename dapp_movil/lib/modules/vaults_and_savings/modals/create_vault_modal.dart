import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/transaction_skeleton.dart';

class CreateVaultModal {
  static void show({
    required BuildContext context,
   // required BlockchainService service,
    required VoidCallback onCreated,
    String? initialAmount,
    String? initialType,
    String? initialName,
    String? initialTargetAmount,
    String? initialAutoSave,
    String? initialFrequency,
    int? initialDurationMonths,
  }) {

  final vaultService = Provider.of<SmartVaultService>(context, listen: false);
    final txService = Provider.of<TransactionService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);


    BuildContext rootContext = context;
    int tabIndex = (initialType == 'FIXED' || initialType == 'PLAZO FIJO') ? 1 : 0; 

   final nombreController = TextEditingController(text: initialName ?? '');
    final montoInicialController = TextEditingController(text: initialAmount ?? '');
    final autoAhorroController = TextEditingController(text: initialAutoSave ?? '');
    final metaController = TextEditingController(text: initialTargetAmount ?? '');
    
   String frecuencia = "NONE"; 
    if (initialFrequency != null && ['DAILY', 'WEEKLY', 'MONTHLY'].contains(initialFrequency.toUpperCase())) {
      frecuencia = initialFrequency.toUpperCase();
    }
    bool isProcessing = false;

    // 🔥 NUEVAS VARIABLES PARA SALDO Y FECHAS
    double saldoActual = 0.0;
    bool cargandoSaldo = true;
    bool saldoObtenido = false;

    int diasBloqueo = (initialDurationMonths ?? 6) * 30; 
    int tipoPlazo = (initialDurationMonths == 12) ? 1 : 0;

    // Función para mostrar el Modal de Información
    void mostrarInfoIntereses(BuildContext ctx, ColorScheme colorScheme) {
      showDialog(
        context: ctx,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              const Text("¿Cómo funciona?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🔵 Ucha Flexible:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Ideal para metas cortas. Guardas tu dinero y lo retiras cuando quieras sin penalización ni tiempos de espera. No genera intereses.", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 15),
              const Text("🟣 Plazo Fijo:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Ideal para multiplicar tu capital. Tu dinero se bloquea en la blockchain y genera un 5% de interés anual (APY).", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Text("⚠️ Atención: Si rompes el Plazo Fijo antes de la fecha acordada, el contrato inteligente aplicará una penalización del 10% sobre tu capital por retiro anticipado.", 
                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        )
      );
    }

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            
            // Cargar saldo real al abrir el modal
            if (!saldoObtenido) {
              saldoObtenido = true;
              txService.getBalance().then((val) {
                if (context.mounted) {
                  setStateModal(() {
                    saldoActual = double.tryParse(val) ?? 0.0;
                    cargandoSaldo = false;
                  });
                }
              });
            }

            // Cálculos dinámicos
            double deposito = double.tryParse(montoInicialController.text) ?? 0.0;
            double restante = saldoActual - deposito;
            bool saldoInsuficiente = restante < 0;

            DateTime fechaFin = DateTime.now().add(Duration(days: diasBloqueo));

            // Selector interactivo de fecha
            Future<void> seleccionarFechaPersonalizada() async {
              DateTime initial = DateTime.now().add(Duration(days: diasBloqueo));
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                helpText: "Selecciona la fecha de retiro",
                cancelText: "Cancelar",
                confirmText: "Aceptar",
                // locale: const Locale('es', 'ES'), // Activar si tienes flutter_localizations configurado en main.dart
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: colorScheme,
                    ),
                    child: child!,
                  );
                }
              );

              if (picked != null) {
                setStateModal(() {
                  diasBloqueo = picked.difference(DateTime.now()).inDays;
                  tipoPlazo = 2; // Activa la pestaña "Personalizado"
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CABECERA CON BOTÓN DE INFO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40), // Espaciador
                        Text("Crear Bolsillo", style: TextStyle(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.help_outline_rounded, color: onSurfaceColor.withOpacity(0.5)),
                          onPressed: () => mostrarInfoIntereses(context, colorScheme),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // TABS UNIFICADOS
                    Row(
                      children: [
                        Expanded(
                          child: _buildTab(0, "Ucha Flexible", Icons.savings, tabIndex == 0, colorScheme, () {
                            setStateModal(() => tabIndex = 0);
                          })
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTab(1, "Plazo Fijo", Icons.lock_clock, tabIndex == 1, colorScheme, () {
                            setStateModal(() => tabIndex = 1);
                          })
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // FORMULARIO REUTILIZABLE
                    TextField(
                      controller: nombreController,
                      decoration: _inputDecoration("Nombre de tu meta (Ej. Viaje o Vet de Tobi)", Icons.flag, onSurfaceColor),
                    ),
                    

                    const SizedBox(height: 15),
    TextField(
      controller: metaController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: _inputDecoration("Meta final a alcanzar (Opcional)", Icons.flag_circle_rounded, onSurfaceColor),
    ),
    const SizedBox(height: 15),
                    
                    TextField(
                      controller: montoInicialController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], // 🔥 SOLO POSITIVOS
                      onChanged: (val) => setStateModal(() {}), // Actualiza el saldo en vivo
                      decoration: _inputDecoration("Depósito Inicial (TTC)", Icons.attach_money, onSurfaceColor),
                    ),
                    
                    // 🔥 TEXTO DE SALDO RESTANTE EN VIVO
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tienes: ${cargandoSaldo ? "..." : saldoActual.toStringAsFixed(2)} TTC", 
                            style: TextStyle(color: onSurfaceColor.withOpacity(0.5), fontSize: 12)),
                          Text("Te quedarán: ${restante.toStringAsFixed(2)} TTC", 
                            style: TextStyle(color: saldoInsuficiente ? Colors.redAccent : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔥 SOLO PARA PLAZO FIJO (SELECTOR HÍBRIDO DE FECHAS)
                    if (tabIndex == 1) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Selecciona la duración:", style: TextStyle(fontWeight: FontWeight.bold, color: onSurfaceColor)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ChoiceChip(
                            label: const Text("6 Meses"),
                            selected: tipoPlazo == 0,
                            onSelected: (val) => setStateModal(() { tipoPlazo = 0; diasBloqueo = 180; }),
                          ),
                          ChoiceChip(
                            label: const Text("1 Año"),
                            selected: tipoPlazo == 1,
                            onSelected: (val) => setStateModal(() { tipoPlazo = 1; diasBloqueo = 365; }),
                          ),
                          ChoiceChip(
                            label: const Text("Personalizado"),
                            selected: tipoPlazo == 2,
                            onSelected: (val) => seleccionarFechaPersonalizada(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      // Resumen de la fecha seleccionada
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.2))),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.purpleAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bloqueado por $diasBloqueo días", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("Finaliza el: ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 12)),
                                ],
                              ),
                            ),
                            if (tipoPlazo == 2)
                              IconButton(
                                icon: const Icon(Icons.edit_calendar_rounded, color: Colors.purpleAccent),
                                onPressed: seleccionarFechaPersonalizada,
                              )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // AUTO AHORRO (COMÚN PARA AMBOS)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Auto-Ahorro Automático", style: TextStyle(fontWeight: FontWeight.bold, color: onSurfaceColor)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: autoAhorroController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], // 🔥 SOLO POSITIVOS
                                  decoration: InputDecoration(hintText: "Monto TTC", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: frecuencia,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: "NONE", child: Text("No automático")),
                                  DropdownMenuItem(value: "DAILY", child: Text("Diario")),
                                  DropdownMenuItem(value: "WEEKLY", child: Text("Semanal")),
                                  DropdownMenuItem(value: "MONTHLY", child: Text("Mensual")),
                                ],
                                onChanged: (val) => setStateModal(() => frecuencia = val!),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // BOTÓN DE ACCIÓN CON BIOMETRÍA
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tabIndex == 0 ? Colors.blueAccent : Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: (isProcessing || saldoInsuficiente) ? null : () async {
                          HapticFeedback.mediumImpact();
                          if (nombreController.text.isEmpty || montoInicialController.text.isEmpty) {
                            UIHelper.showCustomSnackbar("Llenar los campos obligatorios", isError: true);
                            return;
                          }

                          FocusScope.of(context).unfocus();

                          // 🛡️ HUELLA DACTILAR
                          showDialog(context: rootContext, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Confirma la creación de tu bolsillo."));
                          bool isAuth = await authCore.authenticateUser();
                          Navigator.pop(rootContext); 

                          HapticFeedback.mediumImpact();

                          if (!isAuth) {
                            UIHelper.showCustomSnackbar("Operación cancelada", isError: true);
                            return;
                          }

                          setStateModal(() => isProcessing = true);
                          
                          try {
                            String res;
                            double initial = double.parse(montoInicialController.text);
                            double autoSave = double.tryParse(autoAhorroController.text) ?? 0.0;
                            double target = double.tryParse(metaController.text) ?? 0.0;

                           if (tabIndex == 0) {
      res = await vaultService.createFlexibleVault(
        goalName: nombreController.text, 
        initialAmount: initial, 
        targetAmount: target, // 🔥 Pasamos la meta
        autoSaveAmount: autoSave, 
        autoSaveFrequency: frecuencia
      );
                            } else {
                              res = await vaultService.createRestrictiveVault(
        goalName: nombreController.text, 
        initialAmount: initial, 
        targetAmount: target, // 🔥 Pasamos la meta
        autoSaveAmount: autoSave, 
        autoSaveFrequency: frecuencia, 
        lockDurationInSeconds: diasBloqueo * 86400
      );
                            }

                            if (res == "Exito") {
                              Navigator.pop(ctx);
                              UIHelper.showCustomSnackbar("¡Bolsillo creado exitosamente!", isError: false);
                              onCreated(); 
                            } else {
                              UIHelper.showCustomSnackbar(res, isError: true);
                            }
                          } finally {
                            if (ctx.mounted) setStateModal(() => isProcessing = false);
                          }
                        },
                        child: isProcessing 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : Text(saldoInsuficiente ? "Saldo Insuficiente" : "Firmar y Crear Bolsillo", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  static Widget _buildTab(int index, String title, IconData icon, bool isSelected, ColorScheme colorScheme, VoidCallback onTap) {
    Color activeColor = index == 0 ? Colors.blueAccent : Colors.purpleAccent;

    return GestureDetector(
      onTap: onTap, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : colorScheme.onSurface.withOpacity(0.1), width: 2)
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isSelected ? activeColor : colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String label, IconData icon, Color onSurface) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: onSurface.withOpacity(0.5)),
      filled: true,
      fillColor: onSurface.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}