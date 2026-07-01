import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:flutter/material.dart';
import 'seed_phrase_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  //final BlockchainService service;
  // final String mnemonic;

  const PasswordSetupScreen({super.key});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
   final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aliasPassController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  
  

  void continuarASemilla() {
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;
    final email = _emailController.text;  // 🔥 NUEVO
    final alias = _aliasPassController.text;
    final phoneNumber = _phoneController.text;  // 🔥 NUEVO

    bool isStrong = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$',).hasMatch(pass);

    if (!isStrong) {
    UIHelper.showCustomSnackbar( "Debe tener 8 caracteres, mayúscula, minúscula, número y símbolo especial.", 
        isError: true
      );
      return;
    }

    if (pass != confirmPass) {
      UIHelper.showCustomSnackbar("Las contraseñas no coinciden", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeedPhraseScreen(
         // service: widget.service,
          password: pass,
          email: email,
          alias: alias,
          phoneNumber: phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
     backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Asegura tu Bóveda", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "Crea una contraseña segura",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Esta contraseña protegerá tus llaves privadas en este dispositivo. No lo olvides.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _passController,
              keyboardType: TextInputType.text,
              obscureText: _obscurePass,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                hintText: "Contraseña",
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                prefixIcon: Icon(Icons.key_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass), // (Ajusta la variable en el segundo)
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 Borde 16
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _confirmPassController,
              keyboardType: TextInputType.text,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                hintText: "Confirmar Contraseña",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
                prefixIcon: const Icon(
                  Icons.verified_user,
                  color: Colors.white54,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
               backgroundColor: colorScheme.primary, // 🔥 Primary
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : continuarASemilla,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Encriptar y Continuar",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
