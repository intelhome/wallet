import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';

class WelcomeTrialModal {
  static void show(BuildContext context, String? alias) {
    final planService = Provider.of<PlanConfigService>(context, listen: false);
    double basicPrice = planService.getPlanPrice("BASIC");
    double premiumPrice = planService.getPlanPrice("PREMIUM");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Obligamos a que toque el botón para cerrarlo
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final onSurface = theme.colorScheme.onSurface;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.90, // Ocupa el 90% de la pantalla
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // CABECERA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFFB86B).withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Color(0xFFFFB86B)),
                    ),
                    const SizedBox(height: 20),
                    Text("¡Bienvenido, @${alias ?? 'Usuario'}!", style: TextStyle(color: onSurface, fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Text(
                      "Te hemos regalado 15 DÍAS DE PRUEBA GRATIS en el plan PREMIUM. Tienes todos los módulos y límites desbloqueados.",
                      style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CARRUSEL
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildPlanCard(ctx, "FREE", "\$0", "Para empezar", ["Billetera básica", "Límite: \$500/día", "IA: 5 consultas/día"], false),
                      const SizedBox(width: 16),
                      _buildPlanCard(ctx, "BASIC", "\$${basicPrice.toStringAsFixed(0)}", "Uso frecuente", ["Límite: \$2,000/día", "IA Ilimitada", "Notaría: 10 docs/mes"], false),
                      const SizedBox(width: 16),
                      _buildPlanCard(ctx, "PREMIUM", "\$${premiumPrice.toStringAsFixed(0)}", "Todo desbloqueado", ["Límites VIP", "Modo Business (POS)", "Notaría Ilimitada", "Soporte Prioritario"], true),
                    ],
                  ),
                ),
              ),

              // BOTÓN CERRAR
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24, left: 24, right: 24, top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4361EE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx), // 🔥 Solo cerramos el modal y revelamos el Dashboard
                    icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                    label: const Text("Comenzar a explorar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static Widget _buildPlanCard(BuildContext context, String title, String price, String subtitle, List<String> features, bool isHighlight) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHighlight ? const Color(0xFFFFB86B) : onSurface.withOpacity(0.08), width: isHighlight ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFFB86B).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text("TU PLAN DE PRUEBA", style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(width: 6),
              Text("/ mes", style: TextStyle(fontSize: 16, color: onSurface.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.7))),
          const SizedBox(height: 16),
          Divider(color: onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: onSurface.withOpacity(0.8), size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f, style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}