import 'package:flutter/material.dart';
import '../../../core/services/smart_avatar.dart';

class CallPlaceholderScreen extends StatefulWidget {
  final String alias;
  final String address;
  final String phoneNumber;

  const CallPlaceholderScreen({
    super.key,
    required this.alias,
    required this.address,
    required this.phoneNumber,
  });

  @override
  State<CallPlaceholderScreen> createState() => _CallPlaceholderScreenState();
}

class _CallPlaceholderScreenState extends State<CallPlaceholderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de latido suave para simular que está "llamando"
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // HEADER Y AVATAR
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Text("Llamando...", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),
                  
                  // Avatar con animación de pulso
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                      ),
                      child: SmartAvatar(address: widget.address, size: 140),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text(widget.alias, style: TextStyle(color: onSurface, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.phoneNumber, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 18, fontFamily: 'monospace')),
                ],
              ),
            ),

            // TARJETA DE PRÓXIMAMENTE
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.construction_rounded, color: colorScheme.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Las llamadas de voz cifradas y descentralizadas P2P estarán disponibles en la próxima actualización.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),

            // BOTÓN PARA COLGAR
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: colorScheme.error.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)
                    ]
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}