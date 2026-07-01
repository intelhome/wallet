import 'package:dapp_movil/modules/wallet_and_tx/screens/receipt_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/helpers/ui_helper.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../../wallet_and_tx/screens/qr_scanner_screen.dart';
import '../../wallet_and_tx/screens/transaction_pending_screen.dart';
import '../services/burner_service.dart';

class SendBurnerModal {
  static void show({
    required BuildContext context,
    required String burnerAddress,
    required String balanceTTC,
    required VoidCallback onUpdateBalance,
  }) {
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    final burnerService = Provider.of<BurnerService>(context, listen: false);
    BuildContext rootContext = context;

    final TextEditingController addressController = TextEditingController();
    final TextEditingController montoController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    
    String direccionDestino = "";
    double montoIngresado = 0;
    bool isProcessing = false;

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        
        // 🔥 COLORES CORPORATIVOS PARA LA BURNER WALLET (Naranja/Ámbar)
        final Color burnerColor = Colors.deepOrange;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: burnerColor.withOpacity(0.5), width: 2), // Contorno diferente
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, color: burnerColor),
                            const SizedBox(width: 8),
                            const Text("Pago Corporativo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.6)),
                          onPressed: () => Navigator.pop(ctx)
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // INDICADOR DE SALDO DISPONIBLE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: burnerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text("Presupuesto Disponible", style: TextStyle(color: burnerColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("$balanceTTC TTC", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: burnerColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: addressController,
                      onChanged: (val) => setStateModal(() => direccionDestino = val.trim()),
                      decoration: InputDecoration(
                        labelText: "Destino (Billetera 0x...)",
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                          onPressed: () async {
                            final scannedAddress = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
                            if (scannedAddress != null) {
                              setStateModal(() {
                                addressController.text = scannedAddress.trim();
                                direccionDestino = scannedAddress.trim();
                              });
                            }
                          },
                        ),
                        filled: true,
                        fillColor: colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setStateModal(() => montoIngresado = double.tryParse(val) ?? 0),
                      decoration: InputDecoration(
                        labelText: "Monto a pagar",
                        prefixIcon: const Icon(Icons.attach_money),
                        filled: true,
                        fillColor: colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextField(
                      controller: reasonController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Motivo del pago (Obligatorio)",
                        prefixIcon: const Icon(Icons.notes_rounded),
                        filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // 🔥 BOTÓN PRINCIPAL DE ENVÍO BURNER 🔥
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burnerColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (isProcessing || direccionDestino.isEmpty || montoIngresado <= 0) ? null : () async {
                          
                          double saldoActual = double.tryParse(balanceTTC) ?? 0.0;
                          if (montoIngresado > saldoActual) {
                            UIHelper.showCustomSnackbar("La tarjeta corporativa no tiene saldo suficiente. Saldo: $saldoActual TTC", isError: true);
                            return;
                          }

                          FocusScope.of(context).unfocus();
                          
                          showDialog(
                            context: rootContext, 
                            barrierDismissible: false, 
                            builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Coloca tu huella dactilar para autorizar el gasto corporativo.")
                          );
                          
                         bool isAuth = await authCore.authenticateUser();
                          
                          if (!isAuth) {
                            Navigator.pop(rootContext); // Cerramos el Skeleton de huella
                            UIHelper.showCustomSnackbar("Autenticación cancelada.", isError: true);
                            return; 
                          }
                          
                          Navigator.pop(rootContext); // Quitar Skeleton de Huella
                          // 🔥 OJO: Aquí NO debe haber ningún Navigator.pop(ctx) antes del try.

                         try {
                            Navigator.pop(ctx); // 1. Cerramos el modal inferior al instante

                            // 2. Abrimos la pantalla de carga normal a pantalla completa
                            Navigator.push(rootContext, MaterialPageRoute(builder: (_) => TransactionPendingScreen( 
                                customTitle: "Pago Corporativo", 
                                customMessage: "Procesando gasto con tarjeta virtual...", 
                                recipientAddress: direccionDestino, 
                                isGroupPayment: false, 
                                expectedTxType: 'SEND', 
                                onUpdateBalance: () {} // Aquí no hace refresh, lo forzaremos manualmente abajo
                            )));

                            // 3. Ejecutamos la petición en el backend
                            final res = await burnerService.sendFromBurnerWallet(burnerAddress, direccionDestino, montoIngresado, reasonController.text.trim());
                                
                            // 4. Forzamos el cierre de la pantalla de carga apenas el backend responda
                            if (rootContext.mounted) Navigator.pop(rootContext);

                            if (res.startsWith("Error")) { 
                              UIHelper.showCustomSnackbar(res, isError: true); 
                              return;
                            } 
                            
                            // 5. Si fue éxito, recargamos e informamos
                            String txHash = res.replaceAll("Exito:", "").trim();
                            onUpdateBalance(); 
                            UIHelper.showCustomSnackbar("Gasto corporativo realizado con éxito");

                            // 6. Preguntamos educadamente si desea ver el comprobante
                            if (rootContext.mounted) {
                              bool? verComprobante = await UIHelper.mostrarConfirmacion(
                                context: rootContext,
                                titulo: "Transacción Exitosa",
                                mensaje: "¿Deseas ver el comprobante de pago ahora para compartirlo al comercio?",
                                textoConfirmar: "Ver Comprobante",
                                colorConfirmar: Colors.green,
                              );

                              if (verComprobante == true) {
                                dynamic mockTx = {
                                  'txType': 'SEND',
                                  'amount': montoIngresado,
                                  'txHash': txHash,
                                  'senderAddress': burnerAddress,
                                  'receiverAddress': direccionDestino,
                                  'status': 'COMPLETED',
                                  'timestamp': DateTime.now().toIso8601String()
                                };
                                Navigator.push(rootContext, MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(tx: mockTx, myAddress: authCore.publicAddress)));
                              }
                            }

                          } catch (e) {
                            if (rootContext.mounted) Navigator.pop(rootContext); // Seguro anti-atascos
                            UIHelper.showCustomSnackbar("Error inesperado en el pago corporativo", isError: true);
                          } finally {
                            if (ctx.mounted) setStateModal(() => isProcessing = false);
                          }
                        },
                        child: isProcessing 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Autorizar Pago Corporativo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}