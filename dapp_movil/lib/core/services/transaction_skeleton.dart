import 'package:flutter/material.dart';

class TransactionSkeleton extends StatelessWidget {
  final String title;
  final String message;
  
  const TransactionSkeleton({super.key, required this.title, required this.message});


@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9), // Fondo oscuro semitransparente
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Anillo de carga con punto central
                  SizedBox(
                    height: 80, width: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFBAC3FF), shape: BoxShape.circle)),
                        const CircularProgressIndicator(color: Color(0xFF1E2336), strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A2E3D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  
                  // Píldora de instrucción
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2336),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fingerprint_rounded, color: Colors.pinkAccent.shade100, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message.toUpperCase(), 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: Colors.pinkAccent.shade100, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
    
  //   return PopScope(
  //     canPop: false, // Bloquea el botón de retroceso nativo
  //     child: Scaffold(
  //       backgroundColor: theme.scaffoldBackgroundColor,
  //       body: Center(
  //         child: Padding(
  //           padding: const EdgeInsets.all(24.0),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               SizedBox(
  //                 height: 80, width: 80,
  //                 child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 6),
  //               ),
  //               const SizedBox(height: 40),
  //               Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  //               const SizedBox(height: 15),
  //               Container(
  //                 padding: const EdgeInsets.all(20),
  //                 decoration: BoxDecoration(
  //                   color: theme.colorScheme.secondary.withOpacity(0.1),
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
  //                 ),
  //                 child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}