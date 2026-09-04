import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../../../core/services/smart_avatar.dart'; // Tu avatar inteligente

class TierUsersModal {
  static void show({required BuildContext context, required String tier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85, 
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Usuarios en Plan $tier", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE0B0FF))
                    )
                  ),
                  IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.6)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: Provider.of<AdminService>(context, listen: false).getUsersByTier(tier),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE0B0FF)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("No hay usuarios registrados en este plan.", style: TextStyle(color: onSurface.withOpacity(0.5))));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final u = users[index];
                        bool isBusiness = u['accountType'] == 'BUSINESS';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: theme.cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: onSurface.withOpacity(0.05))),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: SmartAvatar(address: u['walletAddress'] ?? '', size: 40),
                            title: Row(
                              children: [
                                Expanded(child: Text(u['alias'] ?? "Sin Alias", style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (isBusiness)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: const Text("Empresa", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(u['email'] ?? "Sin correo", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.8))),
                                const SizedBox(height: 2),
                                Text(u['walletAddress'] ?? "", style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
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