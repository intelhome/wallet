import 'dart:convert';
import 'package:dapp_movil/modules/chat_and_social/services/secure_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatSendMoneyModal {
  static void show(BuildContext context, String aliasDestino, String addressDestino) {
    
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.send_to_mobile_rounded, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text("Enviar a $aliasDestino", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "0.00",
                  suffixText: "TTC",
                  filled: true,
                  fillColor: colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: msgCtrl,
                decoration: InputDecoration(
                  hintText: "Añade un mensaje (Opcional)",
                  prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text("Firmar y Enviar Pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () async {
                    if (amountCtrl.text.isEmpty) return;

                    // 🔥 AQUÍ CONECTAREMOS TU LOGICA BLOCKCHAIN REAL LUEGO 🔥
                    // Por ahora, simulamos el éxito y enviamos la burbuja verde al chat.

                    final chatService = Provider.of<SecureChatService>(context, listen: false);
                    
                    // Empaquetamos como tipo TRANSFER
                    final payload = jsonEncode({
                      "type": "TRANSFER",
                      "amount": amountCtrl.text,
                      "content": msgCtrl.text.isEmpty ? "Transferencia enviada" : msgCtrl.text,
                    });
                    
                    await chatService.sendMessage(addressDestino, payload);
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }
}