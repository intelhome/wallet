import 'dart:math' as math;
import 'package:dapp_movil/modules/settings_and_profile/modals/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/smart_avatar.dart';

class Web3IdCardModal extends StatefulWidget {
  final String alias;
  final String address;
  final Function(String) onScanResult;

  const Web3IdCardModal({super.key, required this.alias, required this.address, required this.onScanResult});

  static void show({required BuildContext context, required String alias, required String address, required Function(String) onScanResult}) {
    showDialog(
      context: context,
      builder: (_) => Web3IdCardModal(alias: alias, address: address, onScanResult: onScanResult),
    );
  }

  @override
  State<Web3IdCardModal> createState() => _Web3IdCardModalState();
}

class _Web3IdCardModalState extends State<Web3IdCardModal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  Future<void> _abrirEscaner() async {
    Navigator.pop(context); // Cierra el modal actual
    
    // Abre la cámara a pantalla completa
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
    
    // Si escaneó algo, se lo pasamos al Dashboard
    if (result != null && result is String) {
      widget.onScanResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkPago = "ttcwallet://pay?to=${widget.alias}";

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 TARJETA 3D ANIMADA 🔥
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Lógica matemática para el giro 3D
                  final angle = _controller.value * math.pi;
                  final isFrontVisible = angle <= math.pi / 2;
                  
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspectiva 3D
                      ..rotateY(angle),
                    child: isFrontVisible
                        ? _buildFrontCard(theme)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi), // Endereza el reverso
                            child: _buildBackCard(theme, linkPago),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // 🔥 BOTÓN DEL ESCÁNER 🔥
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 10,
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
              label: const Text("Escanear Código", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: _abrirEscaner,
            ),
          ],
        ),
      ),
    );
  }

  // LADO A: Tarjeta de Presentación Elegante
  Widget _buildFrontCard(ThemeData theme) {
    return Container(
      width: 320, height: 420,
      decoration: BoxDecoration(
        color: theme.cardColor, borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SmartAvatar(address: widget.address, size: 120),
          const SizedBox(height: 24),
          Text(widget.alias, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              "${widget.address.substring(0, 8)}...${widget.address.substring(widget.address.length - 6)}",
              style: TextStyle(fontFamily: 'monospace', color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          Text("Toca para ver el QR", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  // LADO B: Código QR
  Widget _buildBackCard(ThemeData theme, String linkPago) {
    return Container(
      width: 320, height: 420,
      decoration: BoxDecoration(
        color: Colors.white, // El QR siempre debe tener fondo blanco por contraste
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: linkPago,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Text("Escanea para pagar", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}