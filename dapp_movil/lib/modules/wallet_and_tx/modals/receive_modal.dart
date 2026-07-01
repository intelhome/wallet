import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/smart_avatar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

class ReceiveModal {
  static void show({
    required BuildContext context,
   // required String publicAddress,
  }) {

    final authCore = Provider.of<AuthCoreService>(context, listen: false);
final publicAddress = authCore.publicAddress;
    // 🔥 1. CAPTURAMOS EL BRILLO ACTUAL PARA RESTAURARLO DESPUÉS
    Future<void> setMaxBrightness() async {
      try {
        await ScreenBrightness().setScreenBrightness(1.0); // 100% de brillo
      } catch (e) {
        print("Fallo al subir el brillo: $e");
      }
    }

    Future<void> resetBrightness() async {
      try {
        await ScreenBrightness().resetScreenBrightness(); // Regresa al brillo del usuario
      } catch (e) {
        print("Fallo al restaurar el brillo: $e");
      }
    }

    // Subimos el brillo apenas se llama al modal
    setMaxBrightness();

    final TextEditingController montoController = TextEditingController();
    String montoIngresado = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) { 
        final theme = Theme.of(ctx); 
        final colorScheme = theme.colorScheme;
        final onSurfaceColor = colorScheme.onSurface;
        final cardColor = theme.cardColor;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            bool tieneMonto = montoIngresado.isNotEmpty && (double.tryParse(montoIngresado) ?? 0) > 0;

            // Formato ERC-681 estándar
            String qrData = tieneMonto 
                ? "ethereum:$publicAddress?amount=$montoIngresado" 
                : publicAddress;

            // Formato Deep Link
            String deepLink = tieneMonto
                ? "ttcwallet://pay?to=$publicAddress&amount=$montoIngresado"
                : "ttcwallet://pay?to=$publicAddress";

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20, right: 20, top: 16,
              ),
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: onSurfaceColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                  
                  // 🔥 MODO POS: Destacamos si hay un monto de cobro
                  if (tieneMonto) ...[
                    Text("Cobrando", style: TextStyle(color: onSurfaceColor.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("${double.parse(montoIngresado).toStringAsFixed(2)} TTC", style: TextStyle(color: colorScheme.primary, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(height: 10),
                  ] else ...[
                    Text("Recibir TTC", style: TextStyle(color: onSurfaceColor, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                  ],
                  
                  // 🔥 EL QR DE ALTO CONTRASTE 🔥
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, // Blanco inmaculado OBLIGATORIO para el contraste
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: colorScheme.primary.withOpacity(0.15), blurRadius: 30, spreadRadius: 5)
                      ]
                    ),
                    child: Column(
                      children: [
                        SmartAvatar(address: publicAddress, size: 40),
                        const SizedBox(height: 15),
                        QrImageView(
                          data: qrData, 
                          version: QrVersions.auto, 
                          size: 240.0, 
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 🔥 INPUT DE MONTO OPTIMIZADO PARA CAJEROS
                  TextField(
                    controller: montoController,
                    style: TextStyle(color: onSurfaceColor, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "Añadir monto a cobrar (Opcional)",
                      hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.4), fontSize: 16),
                      prefixIcon: Icon(Icons.point_of_sale_rounded, color: colorScheme.primary),
                      filled: true,
                      fillColor: onSurfaceColor.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() => montoIngresado = val),
                  ),
                  const SizedBox(height: 15),
                  
                  // BOTÓN COMPARTIR
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text("Compartir Enlace de Pago", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        String mensaje = tieneMonto
                            ? "¡Hola! Págame $montoIngresado TTC directamente desde este enlace:\n\n$deepLink"
                            : "¡Hola! Envíame TTC usando este enlace seguro:\n\n$deepLink";
                        Share.share(mensaje);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // DIRECCIÓN PÚBLICA COPIABLE
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: onSurfaceColor.withOpacity(0.6)),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(
                      "${publicAddress.substring(0, 12)}...${publicAddress.substring(publicAddress.length - 8)}", 
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: publicAddress));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Dirección copiada!"), backgroundColor: Colors.green));
                    },
                  ),
                ],
              ),
            );
          }
        );
      }
    ).whenComplete(() {
      // 🔥 2. CUANDO EL MODAL SE CIERRA, RESTAURAMOS EL BRILLO
      resetBrightness();
    });
  }
}