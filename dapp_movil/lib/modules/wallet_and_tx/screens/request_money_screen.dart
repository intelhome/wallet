import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/smart_avatar.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../settings_and_profile/services/user_service.dart';

class RequestMoneyScreen extends StatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  String _monto = "0.00";
  String _motivo = "";
  String _miAlias = "Cargando...";

  @override
  void initState() {
    super.initState();
    _cargarMiAlias();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _cargarMiAlias() async {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    
    final userData = await userService.getUserByWallet(authCore.publicAddress);
    if (mounted && userData != null && userData['alias'] != null) {
      setState(() {
        _miAlias = "@${userData['alias']}";
      });
    } else {
      if (mounted) {
        setState(() {
          _miAlias = "Mi Billetera";
        });
      }
    }
  }

  void _compartirEnlace(String publicAddress) {
    HapticFeedback.mediumImpact();
    double montoNum = double.tryParse(_monto) ?? 0.0;
    
    // Generación del Deep Link Mágico
    String deepLink = "ttcwallet://pay?to=$publicAddress";
    if (montoNum > 0) {
      deepLink += "&amount=${montoNum.toStringAsFixed(2)}";
    }
    
    String mensaje = "¡Hola! 👋\n";
    if (montoNum > 0) {
      mensaje += "Por favor, págame ${montoNum.toStringAsFixed(2)} TTC";
      if (_motivo.isNotEmpty) mensaje += " por '$_motivo'";
      mensaje += ".\n\n";
    } else {
      mensaje += "Aquí tienes mi enlace seguro para enviarme TTC.\n\n";
    }
    
    mensaje += "Paga rápido y sin comisiones abriendo este enlace en tu app:\n$deepLink";

    Share.share(mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final publicAddress = authCore.publicAddress;

    // Generamos QR en crudo (ERC-681 simplificado para compatibilidad)
    double montoNum = double.tryParse(_monto) ?? 0.0;
    String qrData = montoNum > 0 
        ? "ethereum:$publicAddress?amount=${montoNum.toStringAsFixed(2)}" 
        : publicAddress;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Solicitar Dinero", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. INPUT DE MONTO
              Text("¿Cuánto quieres cobrar?", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: colorScheme.primary),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle: TextStyle(color: onSurface.withOpacity(0.2)),
                  prefixText: "TTC ",
                  prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _monto = val),
              ),
              const SizedBox(height: 10),

              // 2. INPUT DE MOTIVO
              Container(
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _reasonController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: "¿Para qué es este cobro? (Opcional)",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (val) => setState(() => _motivo = val),
                ),
              ),
              const SizedBox(height: 40),

              // 3. TARJETA VISUAL PREVIA (El "Bizum/Venmo" look)
              Text("Vista previa de tu tarjeta de cobro:", style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: SmartAvatar(address: publicAddress, size: 48),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Pagar a", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(_miAlias, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // Mini QR decorativo y funcional
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: QrImageView(
                            data: qrData, 
                            version: QrVersions.auto, 
                            size: 50.0, 
                            backgroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          if (montoNum > 0) ...[
                            const Text("Monto solicitado", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("${montoNum.toStringAsFixed(2)} TTC", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          ] else ...[
                            const Text("Cobro Abierto", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text("El pagador decide el monto", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                          
                          if (_motivo.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 12),
                            Text('"$_motivo"', style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // 4. BOTÓN DE COMPARTIR
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 24),
                  label: const Text("Compartir Enlace por WhatsApp", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _compartirEnlace(publicAddress),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}