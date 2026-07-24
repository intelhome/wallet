import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../wallet_and_tx/screens/main_screen.dart';

class ImportWalletScreen extends StatefulWidget {

  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final TextEditingController _phraseController = TextEditingController();
  //final TextEditingController _passController = TextEditingController();

  final List<TextEditingController> _wordControllers = List.generate(12, (_) => TextEditingController());
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  Future<void> _importWallet() async {
    //final authCore = Provider.of<AuthCoreService>(context, listen: false);
    // String mnemonic = _phraseController.text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    // final pass = _passController.text;
    String mnemonic = _wordControllers.map((c) => c.text.trim()).join(' ').toLowerCase();
    final pass = _passController.text;

    if (!bip39.validateMnemonic(mnemonic)) {
      UIHelper.showCustomSnackbar("Frase inválida. Revisa que sean 12 palabras.", isError: true);
      return;
    }

    if (pass.isEmpty) {
      UIHelper.showCustomSnackbar("Debes ingresar la contraseña de tu cuenta.", isError: true);
      return;
    }

    await const FlutterSecureStorage().delete(key: 'trusted_device_token');

    setState(() => _isLoading = true);

    try {
      // 1. Recreamos la billetera y la encriptamos localmente
     await authCore.createWalletFromMnemonic(mnemonic);
    await authCore.savePin(pass);

    String loginResult = await authCore.requestJwtToken(pass);

      if (loginResult == "2FA_REQUIRED") {
        setState(() => _isLoading = false);
        _mostrarDialogo2FA(pass);
        return;
      } 
      
      if (loginResult == "SUCCESS") {
        _ingresarAlDashboard();
      } else {
        await authCore.deleteWallet();
        UIHelper.showCustomSnackbar("Contraseña incorrecta o billetera no registrada en la red.", isError: true);
      }
    } catch (e) {
      await authCore.deleteWallet();
      UIHelper.showCustomSnackbar("Error importando: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogo2FA(String password) {
    final TextEditingController codeController = TextEditingController();
    bool verificando = false;

    showDialog(
      
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
         backgroundColor: theme.cardColor,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // 🔥 M3 Dialog
          title: Column(
            children: [
              Icon(Icons.security_rounded, color: colorScheme.primary, size: 40), // 🔥 Primary
              SizedBox(height: 10),
              Text("Autenticador 2FA", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Esta cuenta está protegida. Ingresa el código de 6 dígitos de tu Google Authenticator.", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                authCore.deleteWallet();
                Navigator.pop(ctx);
              },
             child: Text("Cancelar", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
             style: ElevatedButton.styleFrom(
  backgroundColor: colorScheme.primary, 
  foregroundColor: colorScheme.onPrimary,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
),
              onPressed: verificando ? null : () async {
                if (codeController.text.length != 6) return;
                setStateDialog(() => verificando = true);

                String result = await authCore.requestJwtToken(password, twoFactorCode: codeController.text);

                if (result == "SUCCESS") {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _ingresarAlDashboard();
                } else {
                  setStateDialog(() => verificando = false);
                  UIHelper.showCustomSnackbar("Código incorrecto", isError: true);
                }
              },
              child: verificando 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Verificar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      }
    );
  }

  void _ingresarAlDashboard() {
    UIHelper.showCustomSnackbar("¡Billetera sincronizada con éxito!");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
      (Route<dynamic> route) => false,
    );
  }

//   @override
//   Widget build(BuildContext context) {
//     final onSurface = Theme.of(context).colorScheme.onSurface;
//     final cardColor = Theme.of(context).cardColor;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: Text("Importar Bóveda", style: TextStyle(color: onSurface)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: IconThemeData(color: onSurface),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//            Icon(Icons.download_for_offline_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
           
//             const SizedBox(height: 20),
//             Text("Recupera tus fondos", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
//             const SizedBox(height: 10),
//             Text("Ingresa tus 12 palabras y la contraseña original de tu cuenta para sincronizar con el servidor.", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14), textAlign: TextAlign.center),
//             const SizedBox(height: 30),

//             TextField(
//               controller: _phraseController,
//               maxLines: 4,
//               style: TextStyle(color: onSurface, fontSize: 16),
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: cardColor,
//                 hintText: "Ejemplo: perro gato arbol casa...",
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
//               ),
//             ),
//             const SizedBox(height: 20),

//             TextField(
//               controller: _passController,
//               obscureText: _obscurePass,
//               style: TextStyle(color: onSurface, fontSize: 16),
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: cardColor,
//                 hintText: "Contraseña de tu cuenta",
//                 prefixIcon: Icon(Icons.lock, color: onSurface.withOpacity(0.5)),
//                 suffixIcon: IconButton(
//                   icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: onSurface.withOpacity(0.5)),
//                   onPressed: () => setState(() => _obscurePass = !_obscurePass),
//                 ),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
//               ),
//             ),
//             const SizedBox(height: 40),

//             ElevatedButton(
//        style: ElevatedButton.styleFrom(
//   backgroundColor: Theme.of(context).colorScheme.primary,
//   foregroundColor: Theme.of(context).colorScheme.onPrimary,
//   padding: const EdgeInsets.symmetric(vertical: 16),
//   elevation: 0,
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 M3 Botón
// ),
//               onPressed: _isLoading ? null : _importWallet,
//               child: _isLoading
//                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                   : const Text("Sincronizar Billetera", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("TTC Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4361EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4361EE).withOpacity(0.2), blurRadius: 40, spreadRadius: 10)
                  ]
                ),
                child: const Icon(Icons.download_rounded, size: 48, color: Color(0xFF4361EE)),
              ),
              const SizedBox(height: 24),
              Text("Recupera tus fondos", style: TextStyle(color: onSurface, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("Ingresa tus 12 palabras y la contraseña original de tu cuenta para sincronizar con el servidor.", style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.4), textAlign: TextAlign.center),
              const SizedBox(height: 32),

              // 🔥 FIX 3: Cuadrícula de 12 Inputs
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: onSurface.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: onSurface.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                          ),
                          child: Text("${index + 1}", style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _wordControllers[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Palabra ${index + 1}",
                              hintStyle: TextStyle(color: onSurface.withOpacity(0.2), fontSize: 14, fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),

              // Contraseña
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: onSurface.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _passController,
                  obscureText: _obscurePass,
                  style: TextStyle(color: onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: onSurface.withOpacity(0.5)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: onSurface.withOpacity(0.5)),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Botón
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4361EE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _isLoading ? null : _importWallet,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Sincronizar Billetera", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}