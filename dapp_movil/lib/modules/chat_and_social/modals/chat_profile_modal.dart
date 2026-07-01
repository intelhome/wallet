import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_avatar.dart';

class ChatProfileModal {
  static void show(BuildContext context, String address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: Provider.of<UserService>(context, listen: false).getUserByWallet(address),
        builder: (context, snapshot) {
          final colorScheme = Theme.of(context).colorScheme;
          final onSurface = colorScheme.onSurface;

          String alias = "Cargando...";
          if (snapshot.connectionState == ConnectionState.done) {
            alias = snapshot.data?['alias'] ?? "Desconocido";
          }

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                SmartAvatar(address: address, size: 100),
                const SizedBox(height: 16),
                Text("@$alias", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(address, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(Icons.shield_rounded, color: Colors.greenAccent.shade400),
                  title: Text("Cifrado Extremo a Extremo", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text("Nadie fuera de este chat puede leer los mensajes.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}