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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatService = Provider.of<SecureChatService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Mensajes Encriptados", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: !chatService.isConnected
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Conectando a nodos descentralizados...", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
              ],
            ))
          : _isLoadingInbox 
              ? const Center(child: CircularProgressIndicator())
              : _inbox.isEmpty
                  ? Center(child: Text("Aún no tienes chats.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))))
                  : ListView.builder(
                      itemCount: _inbox.length, // 🔥 Usamos _inbox
                      itemBuilder: (context, index) {
                        final convo = _inbox[index]; // 🔥 Usamos _inbox
                        final peerAddress = convo['peerAddress']; 
                        final alias = convo['alias'] ?? "Usuario";
                        final lastMsg = convo['lastMessage'] ?? "";
                        final time = convo['time'] ?? "";
                        
                        // 🔥 ENVOLVEMOS EL LISTTILE EN UN DISMISSIBLE PARA DESLIZAR Y BORRAR
                        return Dismissible(
                          key: Key(peerAddress),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: colorScheme.error,
                            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).cardColor,
                            title: Text("¿Eliminar chat con $alias?", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                            content: Text(
                              "Si eliminas o vacías este chat, los mensajes se borrarán de este dispositivo y no podrás recuperarlos nuevamente.\n\n¿Estás seguro de que deseas continuar?",
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false), // Cancela el borrado
                                child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                                onPressed: () => Navigator.pop(ctx, true), // Confirma el borrado
                                child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      // 🔥 ACCIÓN SI EL USUARIO DICE QUE SÍ
                    onDismissed: (direction) {
                        final chatService = Provider.of<SecureChatService>(context, listen: false);
                        chatService.deleteConversation(peerAddress);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Chat con $alias eliminado"), 
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      // 🔥 REEMPLAZO: FutureBuilder para obtener el Alias Real
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: Provider.of<UserService>(context, listen: false).getUserByWallet(peerAddress),
                        builder: (context, userSnapshot) {
                          
                          // 🔥 Sacamos el alias real de la base de datos
                          String aliasReal = alias;
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            aliasReal = userSnapshot.data!['alias'] ?? alias;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: SmartAvatar(address: peerAddress, size: 54),
                            title: Text(aliasReal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(
                              lastMsg, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            onTap: () {
                              Navigator.push(context, RouteHelper.slideUpRoute(ChatRoomScreen(
                                alias: aliasReal, // Pasamos el alias real a la pantalla de chat
                                address: peerAddress,
                              )));
                            },
                            onLongPress: () {
                               _mostrarOpcionesDeChat(context, peerAddress, aliasReal);
                   },
                          ); // Cierra el ListTile
                        } // Cierra el builder del FutureBuilder del Avatar
                      ), // Cierra el FutureBuilder del Avatar
                    ); // Cierra el Dismissible
                  }, // Cierra el itemBuilder del ListView
                ), // Cierra el
      floatingActionButton: FloatingActionButton(
       onPressed: () => NewChatModal.show(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.message_rounded),
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