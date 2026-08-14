import 'package:flutter/material.dart';
import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/memberships_screen.dart';

class PremiumBlockerModal {
  static void show(BuildContext context, {required String planRequerido, required String featureName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        final onSurface = colorScheme.onSurface;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pequeña barra superior indicadora de BottomSheet
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),

              // ICONO CENTRAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB86B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, size: 48, color: Color(0xFFFFB86B)),
              ),
              const SizedBox(height: 24),

              // TÍTULO
              Text(
                "Función Premium",
                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // MENSAJE DINÁMICO
              Text(
                "La función de '$featureName' es exclusiva. Necesitas adquirir el plan $planRequerido o superior para desbloquearla.",
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 32),

              // BOTÓN PRINCIPAL: IR A MEMBRESÍAS
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4361EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Cerramos el modal primero
                    // Dirigimos al usuario a la pantalla para comprar/ver planes
                    Navigator.push(context, RouteHelper.slideUpRoute(const MembershipsScreen()));
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                  label: const Text("Ver Planes Disponibles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              // BOTÓN SECUNDARIO: CANCELAR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface.withOpacity(0.8),
                    side: BorderSide(color: onSurface.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Quizás más tarde", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}