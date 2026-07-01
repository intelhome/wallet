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

  // 🔥 1. ABRE LA CALCULADORA ESTÁNDAR Y PEGA EL RESULTADO EN LA CAJA
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

  // 🔥 2. ABRE LA CALCULADORA DE VUELTOS (EFECTIVO)
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 40, top: 40, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("PAGO DIGITAL TTC", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text("$_amount TTC", style: const TextStyle(color: Colors.blueAccent, fontSize: 45, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            QrImageView(
              data: "ttc://pay?address=${authCore.publicAddress}&amount=$_amount",
              version: QrVersions.auto,
              size: 240.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 30),
            const Text("El cliente debe escanear este código\npara transferir los fondos.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black26), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar Cobro", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
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
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("TTC BUSINESS POS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
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
                child: Text("\$$_amount", style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.w200)),
              ),
            ),
          ),

          // 🔥 LA PARTE ROJA DE TU IMAGEN: AHORA CON 3 BOTONES REDUCIDOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calculate_outlined,
                    label: "SUMAR\nPRODUCTOS",
                    color: Colors.purpleAccent,
                    onTap: _abrirCalculadoraEstandar,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.price_change_rounded,
                    label: "CALCULAR\nVUELTOS",
                    color: Colors.greenAccent,
                    onTap: _abrirCalculadoraVueltos,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.fact_check_rounded,
                    label: "VALIDAR\nTRANSACCIÓN",
                    color: Colors.blueAccent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // 🔥 NAVEGAMOS A LA PANTALLA DE VALIDACIÓN
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      // 🔥 AJUSTE DE TAMAÑO: 1.8 hace los botones más cortos para que no se vean gigantes
                      childAspectRatio: 1.8, 
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNumKey("1"), _buildNumKey("2"), _buildNumKey("3"),
                        _buildNumKey("4"), _buildNumKey("5"), _buildNumKey("6"),
                        _buildNumKey("7"), _buildNumKey("8"), _buildNumKey("9"),
                        _buildNumKey("."), _buildNumKey("0"), _buildNumKey("<"),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // BOTÓN DE ACCIÓN PRINCIPAL
                  Row(
                    children: [
                      _buildSquareButton("C", Colors.orange, () => _onKeyPressed("C")),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 65, // Reducido un poco para equilibrar el espacio
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                            label: const Text("GENERAR COBRO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            onPressed: _showQRModal,
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

  // 🔥 WIDGET DE BOTÓN DE ACCIÓN AJUSTADO (MÁS PEQUEÑO)
  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact(); // 🔥 Vibración de confirmación
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para las teclas numéricas
 Widget _buildNumKey(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPressed(label), // _onKeyPressed ya tiene HapticFeedback.lightImpact()
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: label == "<" 
            ? const Icon(Icons.backspace_rounded, color: Colors.redAccent, size: 26)
            : Text(label, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // Botón cuadrado (para el botón C)
  Widget _buildSquareButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}