import 'package:flutter/material.dart';

class SmartAvatar extends StatelessWidget {
  final String address;
  final double size;

  const SmartAvatar({super.key, required this.address, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // Generamos un hash basado en la dirección
    int hash = address.toLowerCase().hashCode;
    
    // Extraemos 3 colores únicos matemáticamente
    Color c1 = Color((hash & 0xFFFFFF) + 0xFF000000);
    Color c2 = Color(((hash >> 8) & 0xFFFFFF) + 0xFF000000);
    Color c3 = Color(((hash >> 16) & 0xFFFFFF) + 0xFF000000);

    // Ángulo de rotación único basado en la dirección
    double rotation = (hash % 360) * 3.14159 / 180;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [c1, c2, c3, c1],
          transform: GradientRotation(rotation),
        ),
        boxShadow: [
          BoxShadow(
            color: c3.withOpacity(0.3), 
            blurRadius: 4, 
            offset: const Offset(2, 2)
          ),
        ]
      ),
    );
  }
}