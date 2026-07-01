import 'package:flutter/material.dart';
import '../../modules/auth_and_security/screens/memberships_screen.dart';

class PremiumBlockerModal {
  static void show(BuildContext context, {required String planRequerido, required String featureName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Colors.purpleAccent, size: 60),
            const SizedBox(height: 16),
            Text("Función Exclusiva", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text(
              "Para usar '$featureName', necesitas tener la membresía $planRequerido o superior.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // Lo mandamos a la pantalla de compras
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipsScreen()));
                },
                child: const Text("Ver Planes Disponibles", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      )
    );
  }
}