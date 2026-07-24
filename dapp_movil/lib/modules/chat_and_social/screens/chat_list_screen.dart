import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/chat_and_social/modals/new_chat_modal.dart';
import 'package:dapp_movil/modules/chat_and_social/services/secure_chat_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_avatar.dart';
import '../../../core/helpers/route_helper.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  List<Map<String, dynamic>> _inbox = [];
bool _isLoadingInbox = true;

@override
  void initState() {
    super.initState();

    _loadInbox();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<SecureChatService>(context, listen: false);
      print("📡 [MOCK CHAT] Estado actual -> Conectado: ${chatService.isConnected}, Conectando: ${chatService.isConnecting}");
      
      if (!chatService.isConnected && !chatService.isConnecting) {
        print("🔧 [MOCK CHAT] El servicio está apagado. Forzando inicio...");
        chatService.initClient(); // 🔥 EL CAMBIO ESTÁ AQUÍ
      }
    });
  }


Future<void> _loadInbox() async {
  final cacheService = LocalCacheService();
  
  // A. Mostrar Caché al instante
  final cachedInbox = cacheService.getCachedInbox();
  if (cachedInbox.isNotEmpty && mounted) {
    setState(() { _inbox = cachedInbox; _isLoadingInbox = false; });
  }

  // B. Traer de red silenciosamente
  final chatService = Provider.of<SecureChatService>(context, listen: false);
  final freshInbox = await chatService.getConversations();
  
  if (mounted) {
    setState(() { _inbox = freshInbox; _isLoadingInbox = false; });
  }
}


//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final chatService = Provider.of<SecureChatService>(context);

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F1626), // Dark background matching the image
//       appBar: AppBar(
//         title: const Text("Mensajes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu_rounded),
//           onPressed: () {},
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search_rounded),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: !chatService.isConnected
//           ? Center(child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const CircularProgressIndicator(),
//                 const SizedBox(height: 16),
//                 Text("Conectando a nodos descentralizados...", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
//               ],
//             ))
//           : _isLoadingInbox 
//               ? const Center(child: CircularProgressIndicator())
//               : _inbox.isEmpty
//                   ? Center(child: Text("Aún no tienes chats.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))))
//                   : ListView.builder(
//                       itemCount: _inbox.length, // 🔥 Usamos _inbox
//                       itemBuilder: (context, index) {
//                         final convo = _inbox[index]; // 🔥 Usamos _inbox
//                         final peerAddress = convo['peerAddress']; 
//                         final alias = convo['alias'] ?? "Usuario";
//                         final lastMsg = convo['lastMessage'] ?? "";
//                         final time = convo['time'] ?? "";
                        
//                         // 🔥 ENVOLVEMOS EL LISTTILE EN UN DISMISSIBLE PARA DESLIZAR Y BORRAR
//                         return Dismissible(
//                           key: Key(peerAddress),
//                           direction: DismissDirection.endToStart,
//                           background: Container(
//                             alignment: Alignment.centerRight,
//                             padding: const EdgeInsets.only(right: 24),
//                             color: const Color(0xFFFFB4A9), // Light red/salmon for swipe delete
//                             child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8C1D18), size: 28),
//                           ),
//                           confirmDismiss: (direction) async {
//                         return await showDialog<bool>(
//                           context: context,
//                           builder: (ctx) => AlertDialog(
//                             backgroundColor: Theme.of(context).cardColor,
//                             title: Text("¿Eliminar chat con $alias?", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
//                             content: Text(
//                               "Si eliminas o vacías este chat, los mensajes se borrarán de este dispositivo y no podrás recuperarlos nuevamente.\n\n¿Estás seguro de que deseas continuar?",
//                               style: TextStyle(color: colorScheme.onSurface),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(ctx, false), // Cancela el borrado
//                                 child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
//                               ),
//                               ElevatedButton(
//                                 style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
//                                 onPressed: () => Navigator.pop(ctx, true), // Confirma el borrado
//                                 child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                       // 🔥 ACCIÓN SI EL USUARIO DICE QUE SÍ
//                     onDismissed: (direction) {
//                         final chatService = Provider.of<SecureChatService>(context, listen: false);
//                         chatService.deleteConversation(peerAddress);
                        
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text("Chat con $alias eliminado"), 
//                             backgroundColor: colorScheme.error,
//                             behavior: SnackBarBehavior.floating,
//                           ),
//                         );
//                       },
//                       // 🔥 REEMPLAZO: FutureBuilder para obtener el Alias Real
//                       child: FutureBuilder<Map<String, dynamic>?>(
//                         future: Provider.of<UserService>(context, listen: false).getUserByWallet(peerAddress),
//                         builder: (context, userSnapshot) {
                          
//                           // 🔥 Sacamos el alias real de la base de datos
//                           String aliasReal = alias;
//                           if (userSnapshot.hasData && userSnapshot.data != null) {
//                             aliasReal = userSnapshot.data!['alias'] ?? alias;
//                           }

//                           // Mock unread count if it's the first element to match the image
//                           final int unreadCount = convo['unread'] ?? (index == 0 ? 2 : 0);

//                           return InkWell(
//                             onTap: () {
//                               Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(
//                                 alias: aliasReal, 
//                                 address: peerAddress,
//                               )));
//                             },
//                             onLongPress: () {
//                                _mostrarOpcionesDeChat(context, peerAddress, aliasReal);
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               child: Row(
//                                 children: [
//                                   Stack(
//                                     children: [
//                                       SmartAvatar(address: peerAddress, size: 54),
//                                       Positioned(
//                                         bottom: 0,
//                                         right: 0,
//                                         child: Container(
//                                           width: 14,
//                                           height: 14,
//                                           decoration: BoxDecoration(
//                                             color: Colors.green,
//                                             shape: BoxShape.circle,
//                                             border: Border.all(color: const Color(0xFF0F1626), width: 2),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Text(aliasReal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
//                                             const SizedBox(width: 4),
//                                             Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white.withOpacity(0.6)),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           lastMsg, 
//                                           maxLines: 1, 
//                                           overflow: TextOverflow.ellipsis,
//                                           style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       Text(time, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
//                                       const SizedBox(height: 6),
//                                       if (unreadCount > 0)
//                                         Container(
//                                           padding: const EdgeInsets.all(6),
//                                           decoration: const BoxDecoration(
//                                             color: Color(0xFFB5C0FF),
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: Text(
//                                             unreadCount.toString(),
//                                             style: const TextStyle(color: Color(0xFF001F44), fontSize: 11, fontWeight: FontWeight.bold),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         } // Cierra el builder del FutureBuilder del Avatar
//                       ), // Cierra el FutureBuilder del Avatar
//                     ); // Cierra el Dismissible
//                   }, // Cierra el itemBuilder del ListView
//                 ), // Cierra el
//       floatingActionButton: FloatingActionButton(
//        onPressed: () => NewChatModal.show(context),
//         backgroundColor: const Color(0xFFB5C0FF), // Light blue from design
//         foregroundColor: const Color(0xFF001F44), // Dark icon color
//         child: const Icon(Icons.edit_outlined),
//       ),
//     );
//   }
// }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatService = Provider.of<SecureChatService>(context);
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mensajes", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          // 🔍 BARRA DE BÚSQUEDA ESTILO MOCKUP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: onSurface.withOpacity(0.05)),
              ),
              child: TextField(
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: "Buscar mensajes...",
                  hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (val) {
                  // Opcional: Implementa lógica de filtrado rápido si lo deseas
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // LISTA DE CHATS
          Expanded(
            child: !chatService.isConnected
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text("Conectando a nodos descentralizados...", style: TextStyle(color: onSurface.withOpacity(0.5))),
                    ],
                  ))
                : _isLoadingInbox 
                    ? const Center(child: CircularProgressIndicator())
                    : _inbox.isEmpty
                        ? Center(child: Text("Aún no tienes chats.", style: TextStyle(color: onSurface.withOpacity(0.5))))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _inbox.length,
                            itemBuilder: (context, index) {
                              final convo = _inbox[index];
                              final peerAddress = convo['peerAddress']; 
                              final alias = convo['alias'] ?? "Usuario";
                              final lastMsg = convo['lastMessage'] ?? "";
                              final time = convo['time'] ?? "Reciente";
                              
                              return Dismissible(
                                key: Key(peerAddress),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(color: const Color(0xFFFFB4A9), borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8C1D18), size: 28),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.cardColor,
                                      title: Text("¿Eliminar chat con $alias?", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                                      content: Text(
                                        "Si eliminas este chat, los mensajes se borrarán de este dispositivo y no podrás recuperarlos nuevamente.\n\n¿Estás seguro de que deseas continuar?",
                                        style: TextStyle(color: onSurface),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  final chatService = Provider.of<SecureChatService>(context, listen: false);
                                  chatService.deleteConversation(peerAddress);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Chat con $alias eliminado"), backgroundColor: colorScheme.error, behavior: SnackBarBehavior.floating),
                                  );
                                },
                                child: FutureBuilder<Map<String, dynamic>?>(
                                  future: Provider.of<UserService>(context, listen: false).getUserByWallet(peerAddress),
                                  builder: (context, userSnapshot) {
                                    String aliasReal = alias;
                                    if (userSnapshot.hasData && userSnapshot.data != null) {
                                      aliasReal = userSnapshot.data!['alias'] ?? alias;
                                    }

                                    final int unreadCount = convo['unread'] ?? (index == 0 ? 2 : 0);

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(
                                              alias: aliasReal, 
                                              address: peerAddress,
                                            )));
                                          },
                                          onLongPress: () => _mostrarOpcionesDeChat(context, peerAddress, aliasReal),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              children: [
                                                // AVATAR CON INDICADOR ACTIVO VERDE
                                                Stack(
                                                  children: [
                                                    SmartAvatar(address: peerAddress, size: 56),
                                                    Positioned(
                                                      bottom: 2,
                                                      right: 2,
                                                      child: Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          color: Colors.greenAccent,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // INFORMACIÓN CENTRAL (ALIAS + MENSAJE)
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(aliasReal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface)),
                                                          const SizedBox(width: 6),
                                                          Icon(Icons.lock_outline_rounded, size: 12, color: onSurface.withOpacity(0.5)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        lastMsg, 
                                                        maxLines: 1, 
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                
                                                // HORA Y BADGE DE NO LEÍDOS
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(time, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), fontWeight: FontWeight.w500)),
                                                    const SizedBox(height: 8),
                                                    if (unreadCount > 0)
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFBAC3FF),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Text(
                                                          unreadCount.toString(),
                                                          style: const TextStyle(color: Color(0xFF00218d), fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(color: onSurface.withOpacity(0.05), height: 1),
                                      ],
                                    );
                                  }
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NewChatModal.show(context),
        backgroundColor: const Color(0xFFBAC3FF), 
        foregroundColor: const Color(0xFF00218d),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

void _mostrarOpcionesDeChat(BuildContext context, String peerAddress, String alias) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Opciones del chat", style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
              title: Text("Vaciar y Eliminar Chat", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx); // Cierra el menú inferior
                
                // Muestra la misma alerta roja de confirmación
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text("¿Eliminar chat con $alias?", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                    content: Text(
                      "Si eliminas o vacías este chat, los mensajes se borrarán de este dispositivo y no podrás recuperarlos nuevamente.\n\n¿Estás seguro de que deseas continuar?",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                        onPressed: () {
                          Navigator.pop(dialogCtx); // Cierra la alerta
                          final chatService = Provider.of<SecureChatService>(context, listen: false);
                          chatService.deleteConversation(peerAddress);
                        },
                        child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }