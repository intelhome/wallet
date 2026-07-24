import 'dart:convert';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Future<void> _fetchNotifications() async {
  //   final authCore = Provider.of<AuthCoreService>(context, listen: false);
  //   try {
  //     final res = await http.get(Uri.parse(ApiConfig.getNotifications), headers: authCore.authHeaders);
  //     if (res.statusCode == 200) {
  //       setState(() {
  //         _notifications = jsonDecode(res.body);
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _fetchNotifications() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final cacheService = LocalCacheService();

    // 1. Mostrar Caché Rápido
    final cached = cacheService.getCachedNotifications();
    if (cached.isNotEmpty && mounted) {
      setState(() { _notifications = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Traer de red fresca en segundo plano
    try {
      final res = await http.get(Uri.parse(ApiConfig.getNotifications), headers: authCore.authHeaders).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await cacheService.saveNotifications(data); // Guardamos la data fresca
        if (mounted) {
          setState(() { _notifications = data; _isLoading = false; });
        }
      }
    } catch (e) {
      print("🚨 Error cargando notificaciones: $e");
      if (mounted && _notifications.isEmpty) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (_notifications[index]['read'] == true) return; // Ya está leída
    
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    setState(() => _notifications[index]['read'] = true); // Actualización optimista

    try {
      await http.put(Uri.parse(ApiConfig.markNotificationRead.replaceAll("{id}", id)), headers: authCore.authHeaders);
    } catch (e) {
      print("Error marcando como leída: $e");
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'TRANSACTION': return Icons.monetization_on_rounded;
      case 'CHAT': return Icons.chat_bubble_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type, ColorScheme scheme) {
    switch (type) {
      case 'TRANSACTION': return Colors.green;
      case 'CHAT': return scheme.primary;
      default: return Colors.orange;
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //     ),
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : _notifications.isEmpty
  //             ? Center(child: Text("No tienes notificaciones", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))))
  //             : ListView.builder(
  //                 itemCount: _notifications.length,
  //                 itemBuilder: (context, index) {
  //                   final notif = _notifications[index];
  //                   final isRead = notif['read'] ?? false;
  //                   final type = notif['type'] ?? 'SYSTEM';
                    
  //                   // Formatear la fecha simple
  //                   final rawDate = notif['timestamp']?.toString().substring(0, 10) ?? "";

  //                   return Container(
  //                     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //                     decoration: BoxDecoration(
  //                       color: isRead ? theme.cardColor : colorScheme.primary.withOpacity(0.1),
  //                       borderRadius: BorderRadius.circular(16),
  //                       border: Border.all(color: isRead ? Colors.transparent : colorScheme.primary.withOpacity(0.3)),
  //                     ),
  //                     child: ListTile(
  //                       onTap: () => _markAsRead(notif['id'], index),
  //                       leading: CircleAvatar(
  //                         backgroundColor: _getColorForType(type, colorScheme).withOpacity(0.2),
  //                         child: Icon(_getIconForType(type), color: _getColorForType(type, colorScheme)),
  //                       ),
  //                       title: Text(notif['title'] ?? "", style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, color: colorScheme.onSurface)),
  //                       subtitle: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           const SizedBox(height: 4),
  //                           Text(notif['body'] ?? "", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
  //                           const SizedBox(height: 6),
  //                           Text(rawDate, style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.4))),
  //                         ],
  //                       ),
  //                       trailing: isRead 
  //                           ? null 
  //                           : Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
  //                     ),
  //                   );
  //                 },
  //               ),
  //   );
  // }
 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // 🔥 1. Lógica para agrupar las notificaciones por fecha[cite: 28]
    Map<String, List<Map<String, dynamic>>> groupedNotifs = {
      "HOY": [],
      "AYER": [],
      "ANTERIOR": [],
    };

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    for (int i = 0; i < _notifications.length; i++) {
      var notif = _notifications[i];
      if (notif['timestamp'] == null) continue;

      DateTime notifDate = DateTime.parse(notif['timestamp'].toString()).toLocal();
      DateTime notifDay = DateTime(notifDate.year, notifDate.month, notifDate.day);

      // Guardamos la notificación junto con su índice original para la función _markAsRead[cite: 28]
      Map<String, dynamic> notifData = {
        "data": notif,
        "originalIndex": i,
      };

      if (notifDay == today) {
        groupedNotifs["HOY"]!.add(notifData);
      } else if (notifDay == yesterday) {
        groupedNotifs["AYER"]!.add(notifData);
      } else {
        groupedNotifs["ANTERIOR"]!.add(notifData);
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("TTC Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("No tienes notificaciones", style: TextStyle(color: onSurface.withOpacity(0.5))))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Notificaciones", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface)),
                          const SizedBox(height: 4),
                          Text("Mantente al tanto de tu actividad.", style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 🔥 2. Reemplazamos el ListView.builder por un ListView que itera sobre los grupos[cite: 28]
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          for (String groupKey in ["HOY", "AYER", "ANTERIOR"])
                            if (groupedNotifs[groupKey]!.isNotEmpty) ...[
                              // Título del grupo (HOY, AYER, ANTERIOR)
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
                                child: Text(
                                  groupKey,
                                  style: TextStyle(
                                    color: onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              // Lista de tarjetas dentro del grupo
                              ...groupedNotifs[groupKey]!.map((item) {
                                final notif = item["data"];
                                final int originalIndex = item["originalIndex"];
                                final isRead = notif['read'] ?? false;
                                final type = notif['type'] ?? 'SYSTEM';
                                
                                // Extraer solo la hora si es de "HOY", o la fecha completa si es "ANTERIOR"[cite: 28]
                                final rawDate = notif['timestamp']?.toString() ?? "";
                                String displayDate = "";
                                if (rawDate.length >= 16) {
                                   displayDate = groupKey == "HOY" 
                                    ? "Hoy a las ${rawDate.substring(11, 16)}" 
                                    : rawDate.substring(0, 16);
                                }

                                Color iconBg = type == 'TRANSACTION' ? Colors.teal.withOpacity(0.1) : 
                                                type == 'CHAT' ? Colors.purple.withOpacity(0.1) : 
                                                Colors.orange.withOpacity(0.1);
                                Color iconColor = type == 'TRANSACTION' ? Colors.teal : 
                                                  type == 'CHAT' ? Colors.purpleAccent : 
                                                  Colors.orangeAccent;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: onSurface.withOpacity(0.05)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    onTap: () => _markAsRead(notif['id'], originalIndex),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                                      child: Icon(_getIconForType(type), color: iconColor, size: 24),
                                    ),
                                    title: Text(
                                      notif['title'] ?? "", 
                                      style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 16)
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text(notif['body'] ?? "", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
                                        const SizedBox(height: 8),
                                        Text(displayDate, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.4))),
                                      ],
                                    ),
                                    trailing: isRead 
                                        ? const SizedBox(width: 10) 
                                        : Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF72585), shape: BoxShape.circle)),
                                  ),
                                );
                              }),
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}