import 'package:flutter/material.dart';

class TransactionSkeleton extends StatelessWidget {
  final String title;
  final String message;
  
  const TransactionSkeleton({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false, // Bloquea el botón de retroceso nativo
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80, width: 80,
                  child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 6),
                ),
                const SizedBox(height: 40),
                Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                  ),
                  child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}