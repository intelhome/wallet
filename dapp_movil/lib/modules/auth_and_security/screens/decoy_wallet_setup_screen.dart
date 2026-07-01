import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/panic_mode_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:provider/provider.dart';
import '../../../core/services/transaction_skeleton.dart';
import '../../../core/helpers/ui_helper.dart';

class DecoyWalletSetupScreen extends StatefulWidget {

  const DecoyWalletSetupScreen({super.key});

  @override
  State<DecoyWalletSetupScreen> createState() => _DecoyWalletSetupScreenState();
}

class _DecoyWalletSetupScreenState extends State<DecoyWalletSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: "5.0");
  bool _isProcessing = false;
  bool _isLoadingState = true;
  bool _obscurePin = true;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  PanicModeService get panicService => Provider.of<PanicModeService>(context, listen: false);

  // Estado local
  String? _existingDecoyAddress;

  final FlutterSecureStorage _vault = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkExistingDecoy();
  }

Future<void> _checkExistingDecoy() async {
    setState(() => _isLoadingState = true);
    
    // 1. Buscamos en local primero
    String? localAddress = await _vault.read(key: 'decoy_address');
    
    // 2. Buscamos en el servidor para estar 100% seguros
    final remoteData = await panicService.syncDecoyState();
    
    if (mounted) {
      setState(() {
        // Priorizamos la verdad del servidor o lo que haya quedado en local
        _existingDecoyAddress = remoteData['exists'] == true 
            ? remoteData['decoyAddress'] 
            : localAddress;
        _isLoadingState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Modo Pánico", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.redAccent,
      ),
      body: _isLoadingState 
        ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _existingDecoyAddress != null 
              ? _buildManageDecoyView(colorScheme) 
              : _buildSetupDecoyView(colorScheme),
          ),
    );
  }

  // =========================================================================
  // VISTA 1: GESTIÓN Y ELIMINACIÓN (CUANDO YA EXISTE)
  // =========================================================================
  Widget _buildManageDecoyView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.redAccent.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.redAccent)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                const Text("Bóveda Señuelo Activa", style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Si inicias sesión usando tu PIN de pánico, serás redirigido a esta dirección falsa:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text(_existingDecoyAddress!, style: TextStyle(fontFamily: 'monospace', color: colorScheme.onSurface, fontSize: 12), textAlign: TextAlign.center),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        
        const Text("Zona de Peligro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 10),
        const Text("Eliminar la bóveda desvinculará el PIN de pánico de este dispositivo y devolverá los fondos restantes a tu cuenta principal.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.delete_forever_rounded),
            label: _isProcessing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                : const Text("Desvincular y Recuperar Fondos", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _isProcessing ? null : _eliminarBoveda,
          ),
        )
      ],
    );
  }

  // =========================================================================
  // VISTA 2: FORMULARIO DE CREACIÓN (COMO ESTABA ANTES)
  // =========================================================================
  Widget _buildSetupDecoyView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.redAccent.shade700, Colors.red.shade900])),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.security_rounded, color: Colors.white, size: 32)),
                    const SizedBox(width: 16),
                    const Expanded(child: Text("Bóveda Señuelo", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Si alguien te obliga a abrir la aplicación, ingresa tu 'PIN de Pánico' en lugar del normal.", style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: _obscurePin,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: "Crea tu PIN de Pánico",
            prefixIcon: const Icon(Icons.password_rounded, color: Colors.redAccent),
            suffixIcon: IconButton(icon: Icon(_obscurePin ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: () => setState(() => _obscurePin = !_obscurePin)),
            filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Fondeo Inicial Señuelo (TTC)",
            prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.redAccent),
            filled: true, fillColor: colorScheme.onSurface.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _isProcessing ? null : _activarBoveda,
            icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.shield_rounded),
            label: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("Activar Bóveda Señuelo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  // =========================================================================
  // MÉTODOS DE ACCIÓN
  // =========================================================================

  Future<void> _eliminarBoveda() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la eliminación del señuelo."));
    bool isAuth = await authCore.authenticateUser();
    if (mounted) Navigator.pop(context);
    if (!isAuth) return;

    setState(() => _isProcessing = true);
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Eliminando", message: "Recuperando fondos a tu cuenta principal..."));
      String res = await panicService.deleteDecoyWallet();
      if (mounted) Navigator.pop(context);

      if (res == "Exito" || res.contains("exitosamente")) {
        UIHelper.showCustomSnackbar("Bóveda eliminada correctamente");
        _checkExistingDecoy(); // Refrescamos la UI
      } else {
        UIHelper.showCustomSnackbar(res, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _activarBoveda() async {
    if (_pinController.text.isEmpty || _pinController.text.length < 4) return;
    FocusScope.of(context).unfocus();

    showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Autenticación", message: "Autoriza la creación del señuelo."));
    bool isAuth = await authCore.authenticateUser();
    if (mounted) Navigator.pop(context);
    if (!isAuth) return;

    setState(() => _isProcessing = true);
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const TransactionSkeleton(title: "Modo Pánico", message: "Generando bóveda fantasma en la red..."));
      String res = await panicService.setupDecoyWallet(_pinController.text, double.parse(_amountController.text));
      if (mounted) Navigator.pop(context);

      if (res == "Exito" || res.contains("exitosamente")) {
        UIHelper.showCustomSnackbar("Modo Pánico Activado");
        _checkExistingDecoy(); // Cambiamos a la vista de gestión
      } else {
        UIHelper.showCustomSnackbar(res, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}