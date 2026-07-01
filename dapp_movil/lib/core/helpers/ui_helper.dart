import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UIHelper {
  // ----------------------------------------------------------------
  // 1. MODALES DE CONFIRMACIÓN
  // ----------------------------------------------------------------
  static Future<bool> mostrarConfirmacion({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    required String textoConfirmar,
    Color? colorConfirmar,
  }) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(mensaje, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorConfirmar ?? Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),

            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(textoConfirmar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
   return result ?? false;
  }

  // ----------------------------------------------------------------
  // 2. SKELETONS (CARGAS FANTASMA)
  // ----------------------------------------------------------------
  static Widget buildSkeletonList(BuildContext context, {int itemCount = 5}) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.onSurface.withOpacity(0.05);
    final highlightColor = colorScheme.onSurface.withOpacity(0.02);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Row(
              children: [
                Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildDashboardSkeleton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withOpacity(0.05),
      highlightColor: colorScheme.onSurface.withOpacity(0.02),
      child: Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 3. ESTADOS VACÍOS (EMPTY STATES PREMIUM)
  // ----------------------------------------------------------------
  static Widget emptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(icon, size: 80, color: colorScheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.4)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onAction,
                child: Text(actionLabel, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
      ),
    );
  }
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showCustomSnackbar(String message, {bool isError = false}) {
    // Usamos la llave global en lugar del ScaffoldMessenger.of(context)
    messengerKey.currentState?.hideCurrentSnackBar();

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}