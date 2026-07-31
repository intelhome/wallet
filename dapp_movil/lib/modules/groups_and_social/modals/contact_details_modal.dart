import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/screens/user_more_details_screen.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../core/services/smart_avatar.dart';

class ContactDetailsModal {
  static void show({
    required BuildContext context,
    required dynamic contact,
   // required BlockchainService service,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final userService = Provider.of<UserService>(context, listen: false);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    String alias = contact['alias'] ?? 'Desconocido';
    String address = contact['contactAddress'] ?? '';
    String category = contact['category'] ?? 'Normal';
    bool isFavorite = contact['favorite'] == true; // Aseguramos el booleano

    IconData catIcon = Icons.person_outline_rounded;
    Color catColor = Colors.grey;
    if (category == 'Familiar') { catIcon = Icons.favorite_rounded; catColor = colorScheme.error; }
    else if (category == 'Comercial') { catIcon = Icons.storefront_rounded; catColor = colorScheme.primary; }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- CABECERA (Categoría y Favorito) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: Icon(catIcon, color: catColor, size: 16),
                  label: Text(category, style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: catColor.withOpacity(0.1),
                  side: BorderSide.none,
                ),
                if (isFavorite) const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
              ],
            ),
            const SizedBox(height: 10),

            // --- AVATAR Y ALIAS ---
            SmartAvatar(address: address, size: 80),
            const SizedBox(height: 16),
            Text("@$alias", style: TextStyle(color: onSurface, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 30),

            // --- CAJA COPIABLE DE BILLETERA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Billetera (Wallet Pública)", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(address, style: TextStyle(color: onSurface, fontFamily: 'monospace', fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: colorScheme.primary),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Clipboard.setData(ClipboardData(text: address));
                      UIHelper.showCustomSnackbar("Billetera copiada");
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- FETCH EN TIEMPO REAL: CORREO Y CELULAR ---
            FutureBuilder<http.Response>(
              future: http.get(
              Uri.parse(ApiConfig.getAliasWallet.replaceAll("{address}", address.toLowerCase())),
                headers: { if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" }
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                String email = "No registrado";
                String phone = "No registrado";
                
                if (snapshot.hasData && snapshot.data!.statusCode == 200) {
                  try {
                    var userData = jsonDecode(snapshot.data!.body);
                    email = userData['email'] ?? "No registrado";
                    phone = userData['phoneNumber'] ?? "No registrado";
                  } catch (e) {}
                }

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: colorScheme.secondary.withOpacity(0.1), child: Icon(Icons.email_rounded, color: colorScheme.secondary)),
                      title: Text("Correo Electrónico", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                      subtitle: Text(email, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.phone_rounded, color: Colors.green)),
                      title: Text("Celular", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12)),
                      subtitle: Text(phone, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 20),
            
            // --- BOTÓN CERRAR ---
           // --- BOTONES DE ACCIÓN ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSurface.withOpacity(0.8),
                      side: BorderSide(color: onSurface.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4361EE), // Azul profesional
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Cierra el modal actual
                      // Navega a la nueva pantalla pasando los datos
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => UserMoreDetailsScreen(wallet: address, alias: alias))
                      );
                    },
                    icon: const Icon(Icons.account_tree_rounded, size: 18),
                    label: const Text("Más Detalles", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}