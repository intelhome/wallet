import 'package:dapp_movil/modules/document_notary/screens/hash_validator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../config/api_config.dart';
import '../../auth_and_security/services/auth_core_service.dart';
import '../services/transaction_service.dart';
import '../../../core/helpers/ui_helper.dart';

// 🔥 IMPORTACIONES MODULARES
import '../modals/change_calculator_modal.dart';
import '../modals/standard_calculator_modal.dart';

class TTCBusinessScreen extends StatefulWidget {
  const TTCBusinessScreen({super.key});

  @override
  State<TTCBusinessScreen> createState() => _TTCBusinessScreenState();
}

class _TTCBusinessScreenState extends State<TTCBusinessScreen> {
  String _amount = "0";

  @override
  void initState() {
    super.initState();
    _listenToPayments();
  }

  void _listenToPayments() {
    final txService = Provider.of<TransactionService>(context, listen: false);
    txService.listenToTransfers((isReceiver, fromAddress) {
      if (isReceiver && mounted) {
        HapticFeedback.heavyImpact();
        UIHelper.showCustomSnackbar("¡PAGO RECIBIDO EXITOSAMENTE!");
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          setState(() => _amount = "0");
        }
      }
    });
  }

 
  void _abrirCalculadoraEstandar() async {
    HapticFeedback.mediumImpact();
    double? result = await StandardCalculatorModal.show(context);
    
    if (result != null && result > 0) {
      setState(() {
        // Si no tiene decimales, lo mostramos entero, si no, con 2 decimales
        _amount = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
      });
    }
  }

 
  void _abrirCalculadoraVueltos() {
    double total = double.tryParse(_amount) ?? 0.0;
    if (total <= 0) {
      UIHelper.showCustomSnackbar("Ingresa un monto para calcular el vuelto", isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    ChangeCalculatorModal.show(context: context, totalToPay: total);
  }

  void _onKeyPressed(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == "C") {
        _amount = "0";
      } else if (value == "<") {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = "0";
        }
      } else if (value == ".") {
        if (!_amount.contains(".")) _amount += ".";
      } else {
        if (_amount == "0") {
          _amount = value;
        } else {
          if (_amount.length < 10) _amount += value;
        }
      }
    });
  }

  // --- MODAL DE QR REUTILIZADO ---
  void _showQRModal() async {
    if (_amount == "0" || _amount == "0.") return;
    HapticFeedback.mediumImpact();
    final authCore = Provider.of<AuthCoreService>(context, listen: false);
    
    try { await ScreenBrightness().setScreenBrightness(1.0); } catch (e) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Fondo oscuro
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 40, top: 40, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("PAGO DIGITAL TTC", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text("$_amount TTC", style: const TextStyle(color: Color(0xFFBAC3FF), fontSize: 56, fontWeight: FontWeight.w900)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, // Contenedor blanco para el QR
                borderRadius: BorderRadius.circular(24),
              ),
              child: QrImageView(
                data: "ttc://pay?address=${authCore.publicAddress}&amount=$_amount",
                version: QrVersions.auto,
                size: 240.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text("El cliente debe escanear este código para\ntransferir los fondos.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5, fontSize: 15)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).whenComplete(() {
      try { ScreenBrightness().resetScreenBrightness(); } catch (e) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btnColor = const Color(0xFF2A2E3D); 
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 20), 
        title: const Text("TTC BUSINESS POS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFFFA3A3)), 
            onPressed: () => isBusinessModeGlobal.value = false,
          ),
        ],
      ),
      body: Column(
        children: [
          // PANTALLA DE MONTO GIGANTE
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("\$$_amount", style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w300)),
              ),
            ),
          ),

          // LOS 3 BOTONES PASTEL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calculate_outlined,
                    label: "SUMAR\nPRODUCTOS",
                    bgColor: const Color(0xFFF0D0FF), 
                    iconColor: const Color(0xFF5A2A7A), 
                    onTap: _abrirCalculadoraEstandar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.price_change_rounded,
                    label: "CALCULAR\nVUELTOS",
                    bgColor: const Color(0xFFD0FFD0), 
                    iconColor: const Color(0xFF1E501E),
                    onTap: _abrirCalculadoraVueltos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.fact_check_rounded,
                    label: "VALIDAR\nTRANSACCIÓN",
                    bgColor: const Color(0xFFD0DFFF), 
                    iconColor: const Color(0xFF1E2A50),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HashValidatorScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),

          // TECLADO NUMÉRICO MODERNO
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8, 
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNumKey("1", btnColor), _buildNumKey("2", btnColor), _buildNumKey("3", btnColor),
                        _buildNumKey("4", btnColor), _buildNumKey("5", btnColor), _buildNumKey("6", btnColor),
                        _buildNumKey("7", btnColor), _buildNumKey("8", btnColor), _buildNumKey("9", btnColor),
                        _buildNumKey(".", btnColor), _buildNumKey("0", btnColor), _buildNumKey("<", btnColor),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // BOTÓN DE ACCIÓN PRINCIPAL (C y Generar Cobro)
                  Row(
                    children: [
                      _buildSquareButton("C", btnColor, const Color(0xFFFFB74D), () {
                        HapticFeedback.lightImpact();
                        _onKeyPressed("C");
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 64, 
                          child: _BotonFisico(
                            onTap: _showQRModal,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.white.withOpacity(0.5),
                            highlightColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4361EE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.qr_code_scanner_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("GENERAR COBRO", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildActionButton({required IconData icon, required String label, required Color bgColor, required Color iconColor, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact(); // 🔥 Toque un poco más fuerte para botones de acción
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withOpacity(0.3), // 🔥 Destello del color del ícono
        highlightColor: iconColor.withOpacity(0.1), // 🔥 Efecto hundimiento
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildNumKey(String label, Color bgColor) {
    return _BotonFisico(
      onTap: () {
        HapticFeedback.lightImpact(); 
        _onKeyPressed(label);
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withOpacity(0.4), 
      highlightColor: Colors.white.withOpacity(0.1), 
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: label == "<" 
          ? const Icon(Icons.backspace_rounded, color: Color(0xFFFFA3A3), size: 22)
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSquareButton(String label, Color bgColor, Color textColor, VoidCallback onTap) {
    return _BotonFisico(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: textColor.withOpacity(0.4), 
      highlightColor: textColor.withOpacity(0.1),
      child: Container(
        width: 70,
        height: 64,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: const Text("TTC BUSINESS POS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
//             onPressed: () => isBusinessModeGlobal.value = false,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // PANTALLA DE MONTO GIGANTE
//           Expanded(
//             flex: 2,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 30),
//               alignment: Alignment.centerRight,
//               child: FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text("\$$_amount", style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w200)),
//               ),
//             ),
//           ),

//           // 🔥 LA PARTE ROJA DE TU IMAGEN: AHORA CON 3 BOTONES REDUCIDOS
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     icon: Icons.calculate_outlined,
//                     label: "SUMAR\nPRODUCTOS",
//                     color: Colors.purpleAccent,
//                     onTap: _abrirCalculadoraEstandar,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _buildActionButton(
//                     icon: Icons.price_change_rounded,
//                     label: "CALCULAR\nVUELTOS",
//                     color: Colors.greenAccent,
//                     onTap: _abrirCalculadoraVueltos,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _buildActionButton(
//                     icon: Icons.fact_check_rounded,
//                     label: "VALIDAR\nTRANSACCIÓN",
//                     color: Colors.blueAccent,
//                     onTap: () {
//                       HapticFeedback.mediumImpact();
//                       // 🔥 NAVEGAMOS A LA PANTALLA DE VALIDACIÓN
//                       Navigator.push(context, MaterialPageRoute(builder: (_) => const HashValidatorScreen()));
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // TECLADO NUMÉRICO MODERNO
//           Expanded(
//             flex: 5,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               decoration: BoxDecoration(
//                 color: theme.cardColor,
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
//               ),
//               child: Column(
//                 children: [
//                   Expanded(
//                     child: GridView.count(
//                       crossAxisCount: 3,
//                       // 🔥 AJUSTE DE TAMAÑO: 1.8 hace los botones más cortos para que no se vean gigantes
//                       childAspectRatio: 1.8, 
//                       mainAxisSpacing: 10,
//                       crossAxisSpacing: 10,
//                       physics: const NeverScrollableScrollPhysics(),
//                       children: [
//                         _buildNumKey("1"), _buildNumKey("2"), _buildNumKey("3"),
//                         _buildNumKey("4"), _buildNumKey("5"), _buildNumKey("6"),
//                         _buildNumKey("7"), _buildNumKey("8"), _buildNumKey("9"),
//                         _buildNumKey("."), _buildNumKey("0"), _buildNumKey("<"),
//                       ],
//                     ),
//                   ),
                  
//                   const SizedBox(height: 10),
                  
//                   // BOTÓN DE ACCIÓN PRINCIPAL
//                   Row(
//                     children: [
//                       _buildSquareButton("C", Colors.orange, () => _onKeyPressed("C")),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: SizedBox(
//                           height: 65, // Reducido un poco para equilibrar el espacio
//                           child: ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blueAccent,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//                             ),
//                             icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
//                             label: const Text("GENERAR COBRO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
//                             onPressed: _showQRModal,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 WIDGET DE BOTÓN DE ACCIÓN AJUSTADO (MÁS PEQUEÑO)
//   Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () {
//           HapticFeedback.mediumImpact(); // 🔥 Vibración de confirmación
//           onTap();
//         },
//         borderRadius: BorderRadius.circular(24),
//         splashColor: color.withOpacity(0.2),
//         highlightColor: color.withOpacity(0.1),
//         child: Container(
//           height: 90,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: color, size: 30),
//               const SizedBox(height: 8),
//               Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Widget para las teclas numéricas
//  Widget _buildNumKey(String label) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => _onKeyPressed(label), // _onKeyPressed ya tiene HapticFeedback.lightImpact()
//         borderRadius: BorderRadius.circular(24),
//         splashColor: Colors.white.withOpacity(0.1),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(24),
//           ),
//           alignment: Alignment.center,
//           child: label == "<" 
//             ? const Icon(Icons.backspace_rounded, color: Colors.redAccent, size: 26)
//             : Text(label, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500)),
//         ),
//       ),
//     );
//   }

//   // Botón cuadrado (para el botón C)
//   Widget _buildSquareButton(String label, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 65,
//         height: 65,
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(color: color.withOpacity(0.4)),
//         ),
//         alignment: Alignment.center,
//         child: Text(label, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
}
//  WIDGET REUTILIZABLE PARA EFECTO DE APLASTAMIENTO Y DESTELLO
class _BotonFisico extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Color splashColor;
  final Color highlightColor;

  const _BotonFisico({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.splashColor,
    required this.highlightColor,
  });

  @override
  State<_BotonFisico> createState() => _BotonFisicoState();
}

class _BotonFisicoState extends State<_BotonFisico> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.90 : 1.0, // Efecto físico de hundirse
      duration: const Duration(milliseconds: 80), // Súper rápido para que se sienta táctil
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onHighlightChanged: (isHighlighted) => setState(() => _isPressed = isHighlighted),
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          splashColor: widget.splashColor, // Destello
          highlightColor: widget.highlightColor, // Oscurecimiento al mantener presionado
          child: widget.child,
        ),
      ),
    );
  }
}