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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

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
            children: [
              // HEADER VISUAL
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 2)
                      ),
                      child: const Icon(Icons.psychology_rounded, size: 64, color: Colors.purpleAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Memoria Dinámica (RAG)",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "La Inteligencia Artificial aprende de tus conversaciones para darte respuestas hiper personalizadas. Tú tienes el control absoluto de qué datos puede utilizar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6), height: 1.4),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // LISTA DE PREFERENCIAS
              Expanded(
                child: _preferences.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 48, color: onSurface.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              "Tu IA aún está aprendiendo.\nInteractúa con ella en el chat para que comience a memorizar tus gustos y preferencias.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _preferences.length,
                      itemBuilder: (context, index) {
                        final pref = _preferences[index];
                        final bool isActive = pref['active'] ?? false;
                        final String date = pref['discoveredAt']?.toString().split('T').first ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: theme.cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isActive ? Colors.purpleAccent.withOpacity(0.3) : onSurface.withOpacity(0.05))
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            activeColor: Colors.purpleAccent,
                            title: Text(
                              pref['content'] ?? '',
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? onSurface : onSurface.withOpacity(0.5),
                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough
                              ),
                            ),
                            subtitle: Text("Descubierto: $date", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.4))),
                            value: isActive,
                            onChanged: (val) => _toggleSwitch(index, val),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}