import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔥 Necesario para las vibraciones

class StandardCalculatorModal extends StatefulWidget {
  const StandardCalculatorModal({super.key});

  static Future<double?> show(BuildContext context) async {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const StandardCalculatorModal(),
    );
  }

  @override
  State<StandardCalculatorModal> createState() => _StandardCalculatorModalState();
}

class _StandardCalculatorModalState extends State<StandardCalculatorModal> {
  String _display = "0";
  double _firstOperand = 0;
  String _operator = "";
  bool _shouldResetDisplay = false;

  void _onButtonPressed(String value) {
    // 🔥 FEEDBACK HÁPTICO: Vibración sutil al tocar
    HapticFeedback.lightImpact();

    setState(() {
      if (value == "C") {
        _display = "0";
        _firstOperand = 0;
        _operator = "";
        _shouldResetDisplay = false;
      } else if (value == "+" || value == "-" || value == "x" || value == "÷") {
        _firstOperand = double.tryParse(_display) ?? 0;
        _operator = value;
        _shouldResetDisplay = true;
      } else if (value == "=") {
        if (_operator.isNotEmpty) {
          double secondOperand = double.tryParse(_display) ?? 0;
          double result = 0;
          switch (_operator) {
            case "+": result = _firstOperand + secondOperand; break;
            case "-": result = _firstOperand - secondOperand; break;
            case "x": result = _firstOperand * secondOperand; break;
            case "÷": result = secondOperand != 0 ? _firstOperand / secondOperand : 0; break;
          }
          _display = result == result.toInt() ? result.toInt().toString() : result.toStringAsFixed(2);
          _operator = "";
          _shouldResetDisplay = true;
        }
      } else if (value == ".") {
        if (!_display.contains(".")) {
          _display += ".";
          _shouldResetDisplay = false;
        }
      } else {
        if (_display == "0" || _shouldResetDisplay) {
          _display = value;
          _shouldResetDisplay = false;
        } else {
          if (_display.length < 12) _display += value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        top: 20, left: 24, right: 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("CALCULADORA DE PRODUCTOS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.centerRight,
            child: Text(_display, style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildCalcBtn("7"), _buildCalcBtn("8"), _buildCalcBtn("9"), _buildCalcBtn("÷", isOp: true),
              _buildCalcBtn("4"), _buildCalcBtn("5"), _buildCalcBtn("6"), _buildCalcBtn("x", isOp: true),
              _buildCalcBtn("1"), _buildCalcBtn("2"), _buildCalcBtn("3"), _buildCalcBtn("-", isOp: true),
              _buildCalcBtn("C", isClear: true), _buildCalcBtn("0"), _buildCalcBtn("."), _buildCalcBtn("+", isOp: true),
            ],
          ),
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Aplicar a la Caja", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      HapticFeedback.mediumImpact(); // 🔥 Vibración más fuerte al confirmar
                      if (_operator.isNotEmpty) _onButtonPressed("=");
                      Navigator.pop(context, double.tryParse(_display) ?? 0.0);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 60,
                width: 70,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _onButtonPressed("="),
                  child: const Text("=", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalcBtn(String label, {bool isOp = false, bool isClear = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onButtonPressed(label),
        borderRadius: BorderRadius.circular(20),
        splashColor: isOp ? Colors.purpleAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: isOp ? Colors.purpleAccent.withOpacity(0.1) : (isClear ? Colors.orange.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isOp ? Colors.purpleAccent : (isClear ? Colors.orange : Colors.white), fontSize: 26, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}