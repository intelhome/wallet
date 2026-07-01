import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/groups_and_social/screens/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../modules/wallet_and_tx/screens/history_screen.dart';
import '../../modules/settings_and_profile/screens/settings_screen.dart';
import 'smart_avatar.dart';
import '../../modules/settings_and_profile/screens/analytics_screen.dart';

class AppDrawer extends StatelessWidget {
  //final String publicAddress;
  final String aliasUsuario;
  final VoidCallback onCopyAddress;
  final VoidCallback onDeleteWallet;
  const AppDrawer({
    super.key,
    //required this.service,
    //required this.publicAddress,
    required this.aliasUsuario,
    required this.onCopyAddress,
    required this.onDeleteWallet,
  });

  @override
  Widget build(BuildContext context) {

    final authCore = Provider.of<AuthCoreService>(context);
    final String publicAddress = authCore.publicAddress;
    
    String shortAddress = publicAddress.length > 10
        ? "${publicAddress.substring(0, 6)}...${publicAddress.substring(publicAddress.length - 4)}"
        : publicAddress;

        final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    return Drawer(
      //backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            currentAccountPicture: SmartAvatar(
              address: publicAddress, 
              size: 60,
            ),
            accountName: Text(
              aliasUsuario,
             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: onSurfaceColor),
            ),
            accountEmail: Text(
              shortAddress,
              style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
            ),
          ),
          ListTile(
           leading: Icon(Icons.vpn_key, color: onSurfaceColor.withOpacity(0.7)),
            title: Text("Tu public KEY", style: TextStyle(fontSize: 14, color: onSurfaceColor)),
          //  titleTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
            subtitle: Text(
              publicAddress,
              style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: onSurfaceColor),
            ),
          trailing: IconButton(
              icon: Icon(Icons.copy, color: onSurfaceColor.withOpacity(0.5), size: 20),
              onPressed: () {
                Navigator.pop(context); 
                Clipboard.setData(ClipboardData(text: publicAddress));
                Fluttertoast.showToast(msg: "Dirección copiada", backgroundColor: Colors.blueAccent);
              },
            ),
          ),

         Divider(color: Theme.of(context).dividerColor),

          ListTile(
            leading: Icon(Icons.history, color: onSurfaceColor.withOpacity(0.7)),
            title: Text("Historial de Transacciones", style: TextStyle(fontSize: 14, color: onSurfaceColor)),
           // titleTextStyle: const TextStyle(fontSize: 14, color: Colors.white),

            onTap: () {
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
            Divider(color: Theme.of(context).dividerColor),

          ListTile(
            leading: const Icon(Icons.pie_chart, color: Colors.blueAccent),
            title: const Text('Estadísticas y Analíticas'),
            onTap: () {
              Navigator.pop(context); // Cierra el Drawer
              Navigator.push(
                context,
                // MaterialPageRoute(
                //   builder: (context) => AnalyticsScreen(service: service),
                // ),
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
              Divider(color: Theme.of(context).dividerColor),
          ListTile(
           leading: Icon(Icons.contacts, color: onSurfaceColor.withOpacity(0.7)),
          title: Text("Contactos", style: TextStyle(fontSize: 14, color: onSurfaceColor)),
            //titleTextStyle: const TextStyle(fontSize: 14, color: Colors.white),

            onTap: () {
              Navigator.pop(context); 

              Navigator.push(
                context,
                // MaterialPageRoute(
                //   builder: (context) => ContactsScreen(service: service),
                // ),
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
              );
            },
          ),
          ListTile(
          leading: Icon(Icons.settings, color: onSurfaceColor.withOpacity(0.7)),
            title: Text("Configuración", style: TextStyle(fontSize: 14, color: onSurfaceColor)),
           // titleTextStyle: const TextStyle(fontSize: 14, color: Colors.white),

            onTap: () {
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),

          const Spacer(),

          Divider(color: Theme.of(context).dividerColor),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Borrar cartera", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              onDeleteWallet();
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _BuildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white60),
      title: Text(title),
      onTap: () {},
    );
  }
}

class _BotonMenu extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _BotonMenu(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: Colors.white60),
      title: Text(texto),
      onTap: () {
      },
    );
  }
}
