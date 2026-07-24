import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_memory_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';

class AiMemoryScreen extends StatefulWidget {
  const AiMemoryScreen({super.key});

  @override
  State<AiMemoryScreen> createState() => _AiMemoryScreenState();
}

class _AiMemoryScreenState extends State<AiMemoryScreen> {
  AiMemoryService get aiService => Provider.of<AiMemoryService>(context, listen: false);
  
  bool _isLoading = true;
  List<dynamic> _preferences = [];

  @override
  void initState() {
    super.initState();
    _cargarMemoria();
  }

  // Future<void> _cargarMemoria() async {
  //   final prefs = await aiService.getPreferences();
  //   if (mounted) {
  //     setState(() {
  //       _preferences = prefs;
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _cargarMemoria() async {
    final cacheService = LocalCacheService();
    final wallet = Provider.of<AuthCoreService>(context, listen: false).publicAddress.toLowerCase();

    // 1. Caché rápido
    final cached = cacheService.getCachedAiPreferences(wallet);
    if (cached.isNotEmpty && mounted) {
      setState(() { _preferences = cached; _isLoading = false; });
    } else {
      setState(() => _isLoading = true);
    }

    // 2. Red
    final prefs = await aiService.getPreferences();
    if (mounted) {
      setState(() { _preferences = prefs; _isLoading = false; });
    }
  }

  Future<void> _toggleSwitch(int index, bool newValue) async {
    final pref = _preferences[index];
    final String prefId = pref['id'];

    // Optimistic UI update (Cambia visualmente al instante)
    setState(() => _preferences[index]['active'] = newValue);

    // Llamada al servidor
    bool success = await aiService.togglePreference(prefId, newValue);

    if (!success) {
      // Revertir si falla la conexión
      if (mounted) {
        setState(() => _preferences[index]['active'] = !newValue);
        UIHelper.showCustomSnackbar("Error al sincronizar con el servidor", isError: true);
      }
    } else {
      UIHelper.showCustomSnackbar(newValue ? "Recuerdo activado" : "Dato excluido del análisis");
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final onSurface = colorScheme.onSurface;

  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: const Text("Cerebro IA", style: TextStyle(fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       centerTitle: true,
  //     ),
  //     body: _isLoading 
  //       ? const Center(child: CircularProgressIndicator())
  //       : Column(
  //           children: [
  //             // HEADER VISUAL
  //             Container(
  //               padding: const EdgeInsets.all(24),
  //               child: Column(
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(20),
  //                     decoration: BoxDecoration(
  //                       color: Colors.purpleAccent.withOpacity(0.1),
  //                       shape: BoxShape.circle,
  //                       border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 2)
  //                     ),
  //                     child: const Icon(Icons.psychology_rounded, size: 64, color: Colors.purpleAccent),
  //                   ),
  //                   const SizedBox(height: 16),
  //                   Text(
  //                     "Memoria Dinámica (RAG)",
  //                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text(
  //                     "La Inteligencia Artificial aprende de tus conversaciones para darte respuestas hiper personalizadas. Tú tienes el control absoluto de qué datos puede utilizar.",
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6), height: 1.4),
  //                   ),
  //                 ],
  //               ),
  //             ),
              
  //             const Divider(height: 1),
              
  //             // LISTA DE PREFERENCIAS
  //             Expanded(
  //               child: _preferences.isEmpty
  //                 ? Center(
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(32.0),
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.auto_awesome_rounded, size: 48, color: onSurface.withOpacity(0.2)),
  //                           const SizedBox(height: 16),
  //                           Text(
  //                             "Tu IA aún está aprendiendo.\nInteractúa con ella en el chat para que comience a memorizar tus gustos y preferencias.",
  //                             textAlign: TextAlign.center,
  //                             style: TextStyle(color: onSurface.withOpacity(0.5)),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   )
  //                 : ListView.builder(
  //                     itemCount: _preferences.length,
  //                     itemBuilder: (context, index) {
  //                       final pref = _preferences[index];
  //                       final bool isActive = pref['active'] ?? false;
  //                       final String date = pref['discoveredAt']?.toString().split('T').first ?? '';

  //                       return Card(
  //                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  //                         color: theme.cardColor,
  //                         elevation: 0,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(16),
  //                           side: BorderSide(color: isActive ? Colors.purpleAccent.withOpacity(0.3) : onSurface.withOpacity(0.05))
  //                         ),
  //                         child: SwitchListTile(
  //                           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //                           activeColor: Colors.purpleAccent,
  //                           title: Text(
  //                             pref['content'] ?? '',
  //                             style: TextStyle(
  //                               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
  //                               color: isActive ? onSurface : onSurface.withOpacity(0.5),
  //                               decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough
  //                             ),
  //                           ),
  //                           subtitle: Text("Descubierto: $date", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.4))),
  //                           value: isActive,
  //                           onChanged: (val) => _toggleSwitch(index, val),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    // Separamos la memoria en dos listas reactivas
    final activeMemories = _preferences.where((p) => p['active'] == true).toList();
    final inactiveMemories = _preferences.where((p) => p['active'] == false).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Cerebro IA", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER VISUAL EXACTO A LA IMAGEN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0C3E), // Fondo violáceo
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7209B7).withOpacity(0.3), width: 1)
                      ),
                      child: const Icon(Icons.settings, size: 40, color: Color(0xFFC77DFF)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Memoria Dinámica (RAG)",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurface),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "La Inteligencia Artificial aprende de tus conversaciones para darte respuestas hiper personalizadas. Tú tienes el control absoluto de qué datos puede utilizar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.7), height: 1.5),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: onSurface.withOpacity(0.1), height: 30),
              ),

              // LISTA DIVIDIDA CON DISMISSIBLE
              Expanded(
                child: _preferences.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "Interactúa con la IA en el chat para que comience a memorizar.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withOpacity(0.5)),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // SECCIÓN 1: HABILITADOS
                        if (activeMemories.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
                            child: Row(
                              children: [
                                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.rectangle)),
                                const SizedBox(width: 12),
                                Text("ENTORNO PERSONAL (HABILITADOS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: onSurface.withOpacity(0.8))),
                              ],
                            ),
                          ),
                          ...activeMemories.map((pref) => _buildMemoryCard(pref, true, theme, onSurface)),
                        ],

                        const SizedBox(height: 24),

                        // SECCIÓN 2: DESHABILITADOS
                        if (inactiveMemories.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 12),
                            child: Row(
                              children: [
                                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.rectangle)),
                                const SizedBox(width: 12),
                                const Text("PRODUCTOS RELEVANTES (DESHABILITADOS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFC77DFF))),
                              ],
                            ),
                          ),
                          ...inactiveMemories.map((pref) => _buildMemoryCard(pref, false, theme, onSurface)),
                        ],
                      ],
                    ),
              ),
            ],
          ),
    );
  }

  // WIDGET HELPER PARA CONSTRUIR CADA TARJETA CON SWIPE
  Widget _buildMemoryCard(Map<String, dynamic> pref, bool isActive, ThemeData theme, Color onSurface) {
    int originalIndex = _preferences.indexWhere((p) => p['id'] == pref['id']);
    String date = pref['discoveredAt']?.toString().split('T').first ?? '';
    String content = pref['content'] ?? '';
    
    // Determinar icono
    IconData icon = Icons.person_rounded;
    if (content.toLowerCase().contains("producto")) icon = Icons.shopping_cart_rounded;
    if (content.toLowerCase().contains("llama")) icon = Icons.badge_rounded;

    return Dismissible(
      key: Key(pref['id']),
      // Habilitado -> Desliza a la izquierda para deshabilitar
      // Deshabilitado -> Desliza a la derecha para habilitar
      direction: isActive ? DismissDirection.endToStart : DismissDirection.startToEnd,
      onDismissed: (direction) {
        _toggleSwitch(originalIndex, !isActive);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.visibility_rounded, color: Colors.green),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.visibility_off_rounded, color: Colors.redAccent),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: onSurface.withOpacity(isActive ? 0.1 : 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF7209B7).withOpacity(0.3) : onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isActive ? Colors.white : onSurface.withOpacity(0.4), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isActive ? onSurface : onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text("Descubierto: $date", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}