import 'package:dapp_movil/modules/groups_and_social/services/contact_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/route_helper.dart';
import '../screens/chat_room_screen.dart';

class NewChatModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NewChatContent(),
    );
  }
}

class _NewChatContent extends StatefulWidget {
  const _NewChatContent();

  @override
  State<_NewChatContent> createState() => _NewChatContentState();
}

class _NewChatContentState extends State<_NewChatContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _searchedUser;
  List<dynamic> _misContactos = [];

  @override
  void initState() {
    super.initState();
    _cargarContactos();
  }

  Future<void> _cargarContactos() async {
    final contactService = Provider.of<ContactService>(context, listen: false);
    final lista = await contactService.getContacts();
    if (mounted) setState(() => _misContactos = lista);
  }

  Future<void> _buscarUsuario(String query) async {
    if (query.isEmpty) {
      setState(() => _searchedUser = null);
      return;
    }
    
    setState(() => _isSearching = true);
    final userService = Provider.of<UserService>(context, listen: false);
    
    // Si parece una wallet
    if (query.startsWith("0x") && query.length == 42) {
      final user = await userService.getUserByWallet(query);
      setState(() {
        _searchedUser = user ?? {"alias": "Desconocido", "walletAddress": query};
        _isSearching = false;
      });
    } else {
      // Búsqueda por alias
      final user = await userService.searchByAlias(query);
      setState(() {
        _searchedUser = user;
        _isSearching = false;
      });
    }
  }

  void _abrirChat(String alias, String address) {
    Navigator.pop(context); // Cerramos el modal
    Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(
      alias: alias,
      address: address,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("Nuevo Mensaje", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // BUSCADOR
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: "Buscar por @Alias o Billetera (0x...)",
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => _buscarUsuario(_searchCtrl.text.trim()),
              ),
              filled: true,
              fillColor: colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onSubmitted: _buscarUsuario,
          ),
          const SizedBox(height: 20),

          // RESULTADO DE BÚSQUEDA
          if (_isSearching) const CircularProgressIndicator(),
          if (!_isSearching && _searchedUser != null) ...[
            const Align(alignment: Alignment.centerLeft, child: Text("Resultado de búsqueda", style: TextStyle(color: Colors.grey))),
            ListTile(
              leading: CircleAvatar(backgroundColor: colorScheme.primary, child: Text(_searchedUser!['alias'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
              title: Text("@${_searchedUser!['alias']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_searchedUser!['walletAddress'], maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_rounded),
                color: colorScheme.primary,
                onPressed: () => _abrirChat(_searchedUser!['alias'], _searchedUser!['walletAddress']),
              ),
            ),
            const Divider(),
          ],

          // LISTA DE CONTACTOS
          const Align(alignment: Alignment.centerLeft, child: Text("Tus Contactos", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Expanded(
            child: _misContactos.isEmpty
                ? const Center(child: Text("No tienes contactos guardados."))
                : ListView.builder(
                    itemCount: _misContactos.length,
                    itemBuilder: (ctx, i) {
                      final c = _misContactos[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(c['alias'] ?? "Contacto", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c['contactAddress'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _abrirChat(c['alias'] ?? "Contacto", c['contactAddress']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}