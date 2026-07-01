import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../../../core/services/smart_avatar.dart'; // Tu avatar inteligente

class TierUsersModal {
  static void show({required BuildContext context, required String tier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7, // 70% de la pantalla
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              Text("Usuarios Plan $tier", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
              const Divider(height: 30),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: Provider.of<AdminService>(context, listen: false).getUsersByTier(tier),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No hay usuarios en este plan."));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                     return ListTile(
                          leading: SmartAvatar(address: u['walletAddress'] ?? '', size: 40),
                          title: Text(u['alias'] ?? "Sin Alias", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(u['walletAddress'] ?? "", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}