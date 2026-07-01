import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../debts_and_payments/services/debt_service.dart';
import '../../settings_and_profile/services/user_service.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../../core/services/smart_avatar.dart';

class SplitBillModal {
  static void show({
    required BuildContext context,
    required VoidCallback onSuccess,
    required void Function(String, {bool esError}) mostrarMensaje,
    String? initialAmount,
    String? initialReason,
    List<Map<String, String>>? initialParticipants, // 🔥 NUEVO
  }) {
    final debtService = Provider.of<DebtService>(context, listen: false);
    final authCore = Provider.of<AuthCoreService>(context, listen: false);

    final TextEditingController amountController = TextEditingController(text: initialAmount ?? '');
    final TextEditingController reasonController = TextEditingController(text: initialReason ?? '');
    final TextEditingController aliasController = TextEditingController();
    
    // Lista para guardar a los amigos añadidos: { "alias": "juan", "wallet": "0x123..." }
   List<Map<String, String>> participants = initialParticipants ?? [];
    bool isSearchingAlias = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final onSurface = theme.colorScheme.onSurface;
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            
            // Lógica matemática reactiva
            double totalAmount = double.tryParse(amountController.text) ?? 0.0;
            // La cuenta se divide entre los participantes añadidos MÁS el usuario actual (+1)
            int totalPeople = participants.length + 1; 
            double perPerson = totalPeople > 1 ? (totalAmount / totalPeople) : 0.0;

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.90, // Ocupa casi toda la pantalla
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dividir Cuenta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface)),
                      IconButton(icon: Icon(Icons.close, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1. DATOS DE LA CUENTA
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => setModalState(() {}), // Refresca el cálculo matemático
                    decoration: InputDecoration(
                      labelText: "Total de la cuenta (TTC)",
                      prefixIcon: const Icon(Icons.receipt_long_rounded, color: Colors.green),
                      filled: true, fillColor: onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: "¿De qué fue la cuenta? (Ej: Pizza)",
                      prefixIcon: const Icon(Icons.fastfood_rounded, color: Colors.orange),
                      filled: true, fillColor: onSurface.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. AGREGAR AMIGOS
                  Text("¿Con quién divides?", style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aliasController,
                          decoration: InputDecoration(
                            hintText: "@alias",
                            filled: true, fillColor: onSurface.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                        ),
                        onPressed: isSearchingAlias ? null : () async {
                          HapticFeedback.lightImpact();
                          String query = aliasController.text.trim().replaceAll("@", "");
                          if (query.isEmpty) return;

                          // Evitar agregar al mismo usuario
                          if (participants.any((p) => p['alias'] == query)) {
                            mostrarMensaje("El usuario ya está en la lista", esError: true);
                            return;
                          }

                          setModalState(() => isSearchingAlias = true);
                          
                          try {
                            String endpoint = ApiConfig.searchAlias.replaceAll("{alias}", query);
                            final res = await http.get(Uri.parse(endpoint), headers: {
                              "Content-Type": "application/json",
                              if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
                            });

                            if (res.statusCode == 200) {
                              var data = jsonDecode(res.body);
                              String wallet = "";
                              if (data is List && data.isNotEmpty) wallet = data.first['walletAddress'] ?? "";
                              else if (data is Map) wallet = data['walletAddress'] ?? "";

                              if (wallet.isNotEmpty) {
                                setModalState(() {
                                  participants.add({"alias": query, "wallet": wallet});
                                  aliasController.clear();
                                });
                              } else {
                                mostrarMensaje("Usuario no encontrado", esError: true);
                              }
                            } else {
                              mostrarMensaje("Usuario no encontrado", esError: true);
                            }
                          } catch (e) {
                            mostrarMensaje("Error de red al buscar", esError: true);
                          }
                          setModalState(() => isSearchingAlias = false);
                        },
                        child: isSearchingAlias 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Añadir", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. LISTA DE PARTICIPANTES AÑADIDOS
                  Expanded(
                    child: participants.isEmpty
                      ? Center(child: Text("Añade a tus amigos para dividir la cuenta", style: TextStyle(color: onSurface.withOpacity(0.4))))
                      : ListView.builder(
                          itemCount: participants.length,
                          itemBuilder: (ctxList, i) {
                            final p = participants[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: SmartAvatar(address: p['wallet']!, size: 36),
                              title: Text("@${p['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${perPerson.toStringAsFixed(2)} TTC", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setModalState(() => participants.removeAt(i));
                                },
                              ),
                            );
                          },
                        ),
                  ),

                  // 4. RESUMEN Y BOTÓN FINAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Tu parte:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${perPerson.toStringAsFixed(2)} TTC", style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: participants.isEmpty || totalAmount <= 0 ? null : () async {
                        if (reasonController.text.isEmpty) {
                          mostrarMensaje("Falta el motivo de la cuenta", esError: true);
                          return;
                        }

                        // 1. Huella Dactilar
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Firma Requerida", message: "Autoriza estos cobros."));
                        bool auth = await authCore.authenticateUser();
                        if (context.mounted) Navigator.pop(context); // Quita skeleton
                        if (!auth) return;

                        // 2. Cerramos modal y mostramos pantalla de carga
                        Navigator.pop(ctx); 
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPendingScreen(
                          customTitle: "Dividiendo Cuenta", 
                          customMessage: "Enviando solicitudes de cobro a ${participants.length} amigos...",
                          expectedTxType: "SPLIT_BILL", 
                          onUpdateBalance: onSuccess 
                        )));

                        // 3. 🔥 LA MAGIA: Bucle para enviar las deudas al backend
                        bool allSuccess = true;
                        for (var p in participants) {
                          String res = await debtService.createDebtRequest(
                            p['wallet']!, 
                            perPerson, // Cobramos solo la parte dividida
                            "${reasonController.text} (División de cuenta)"
                          );
                          if (res != "Exito") allSuccess = false;
                        }

                        if (context.mounted) Navigator.pop(context); // Quita pantalla pending
                        
                        if (allSuccess) {
                           mostrarMensaje("Cobros divididos enviados exitosamente", esError: false);
                           onSuccess(); // Recarga la pantalla de deudas
                        } else {
                          mostrarMensaje("Algunos cobros no se pudieron enviar", esError: true);
                          onSuccess();
                        }
                      },
                      child: Text("Cobrar ${perPerson.toStringAsFixed(2)} a ${participants.length} personas", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}