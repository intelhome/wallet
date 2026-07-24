import 'package:flutter/material.dart';
import 'dart:math' as math;

class UserCard extends StatefulWidget {
  final String address;
  final String balanceTTC;
  final String stakedTTC;
  final String currentTier; // FREE, BASIC, PREMIUM
  final bool useAvatarColors;
  final VoidCallback onToggleDiscreet;
  final bool isDiscreet;
  final double presupuestoMensual;
  final double gastadoMes;

  const UserCard({
    super.key,
    required this.address,
    required this.balanceTTC,
    required this.stakedTTC,
    required this.currentTier,
    this.useAvatarColors = false,
    required this.onToggleDiscreet,
    required this.isDiscreet,
    this.presupuestoMensual = 0.0,
    this.gastadoMes = 0.0,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Lógica de colores idéntica al SmartAvatar
  List<Color> _getTierColors() {
    if (!widget.useAvatarColors) {
      return [const Color(0xFF0F62FE), const Color(0xFF3B82F6)];
    }

    int hash = widget.address.toLowerCase().hashCode;
    Color c1 = Color((hash & 0xFFFFFF) + 0xFF000000);
    Color c2 = Color(((hash >> 8) & 0xFFFFFF) + 0xFF000000);
    return [c1, c2];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getTierColors();
    bool isBasic = widget.currentTier == "BASIC";
    bool isPremium = widget.currentTier == "PREMIUM";

    // Configuraciones de borde según membresía
    BoxBorder? cardBorder;
    if (isBasic) cardBorder = Border.all(color: Colors.amber.shade400, width: 2);
    if (isPremium) cardBorder = Border.all(color: const Color(0xFFB9F2FF), width: 2.5);

    return Stack(
      clipBehavior: Clip.none, // Permite que el badge sobresalga
      children: [
        // CONTENEDOR PRINCIPAL DE LA TARJETA
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: cardBorder,
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (isPremium)
                const BoxShadow(
                  color: Color(0xFFB9F2FF),
                  blurRadius: 15,
                  spreadRadius: -5,
                )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // EFECTO DE LÍNEAS DE BRILLO (ANIMADO)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Positioned(
                     left: -800 + (_controller.value * 2500), 
                      top: -100,
                      child: Transform.rotate(
                        angle: 0.5,
                        child: Container(
                          width: 150,
                          height: 400,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // CONTENIDO DE LA TARJETA
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Balance Disponible",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: widget.onToggleDiscreet,
                            child: Icon(
                              widget.isDiscreet ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          widget.isDiscreet ? "**** TTC" : "${widget.balanceTTC} TTC",
                          key: ValueKey<bool>(widget.isDiscreet),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                widget.isDiscreet ? "Stake: ****" : "Stake: ${widget.stakedTTC} TTC",
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.amberAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "1 TTC = \$1",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (widget.presupuestoMensual > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "PRESUPUESTO",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "${widget.gastadoMes.toStringAsFixed(0)} / ${widget.presupuestoMensual.toStringAsFixed(0)} TTC",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (widget.gastadoMes / widget.presupuestoMensual).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // BADGE DE MEMBRESÍA (SOBRESALE)
        if (isBasic || isPremium)
          Positioned(
            top: -15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFF1A1A1A) : Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPremium ? const Color(0xFFB9F2FF) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPremium ? const Color(0xFFB9F2FF) : Colors.black).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPremium ? Icons.diamond : Icons.military_tech,
                      color: isPremium ? const Color(0xFFB9F2FF) : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPremium ? "PREMIUM" : "BASIC",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}