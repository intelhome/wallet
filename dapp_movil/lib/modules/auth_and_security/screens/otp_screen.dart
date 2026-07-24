import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'seed_phrase_screen.dart';

class OtpScreen extends StatefulWidget {
 // final BlockchainService service;
  final String password;
  final String email;
  final String alias;
  final String phoneNumber;
  final Map<String, dynamic>? extraData;

  const OtpScreen({
    super.key,
    //required this.service,
    required this.password,
    required this.email,
    required this.alias,
    required this.phoneNumber,
    this.extraData,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String _errorMsg = "";
  UserService get userService => Provider.of<UserService>(context, listen: false);

  Future<void> _verificar() async {
    if (_otpController.text.length != 6) {
      setState(() => _errorMsg = "El código debe tener 6 dígitos");
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMsg = "";
    });

    bool isValid = await userService.verifyOtp(widget.email, _otpController.text);

    if (isValid) {
      if (!mounted) return;
      print("✅ [OTP] Verificado. Pasando extraData a la Semilla: ${widget.extraData}"); // LOG
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SeedPhraseScreen(
            password: widget.password,
            email: widget.email,
            alias: widget.alias,
            phoneNumber: widget.phoneNumber,
            extraData: widget.extraData, //  3. PÁSALO A LA SEMILLA
          ),
        ),
      );
    }else {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMsg = "Código incorrecto o expirado. Revisa tu correo (consola).";
        });
      }
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   return Scaffold(
  //    backgroundColor: theme.scaffoldBackgroundColor,
  //     appBar: AppBar(
  //       title: Text("Verificación", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //      iconTheme: IconThemeData(color: colorScheme.onSurface),
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(24.0),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //         Icon(Icons.mark_email_read_rounded, size: 80, color: colorScheme.primary), // 🔥 Primary
  //           const SizedBox(height: 20),
  //           Text("Revisa tu correo", style: TextStyle(color: colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w900)),
  //           const SizedBox(height: 10),
  //          Text("Hemos enviado un código de 6 dígitos a:\n${widget.email}", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16)),
  //           const SizedBox(height: 40),

  //           TextField(
  //             controller: _otpController,
  //             keyboardType: TextInputType.number,
  //             maxLength: 6,
  //             textAlign: TextAlign.center,
  //            style: TextStyle(color: colorScheme.onSurface, fontSize: 32, letterSpacing: 10, fontWeight: FontWeight.bold),
  //             decoration: InputDecoration(
  //               counterText: "",
  //               filled: true,
  //              fillColor: colorScheme.onSurface.withOpacity(0.05),
  //               hintText: "000000",
  //              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.2), letterSpacing: 10),
  //               border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 Bordes 16
  //             ),
  //           ),
            
  //           if (_errorMsg.isNotEmpty)
  //             Padding(
  //               padding: const EdgeInsets.only(top: 10),
  //               child: Text(_errorMsg, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)), // 🔥 Error
  //             ),

  //           const SizedBox(height: 40),
  //             SingleChildScrollView(
  //                 physics: const BouncingScrollPhysics(),
  //             child: 
  //           SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                backgroundColor: colorScheme.primary, // 🔥 Primary
  //                 foregroundColor: colorScheme.onPrimary,
  //                 padding: const EdgeInsets.symmetric(vertical: 16),
  //                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🔥 Borde 16
  //               ),
  //               onPressed: _isVerifying ? null : _verificar,
  //               child: _isVerifying 
  //                 ? const CircularProgressIndicator(color: Colors.white) 
  //                 : const Text("Verificar Código", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  //             ),
  //           )
  //             )
  //         ],
  //       ),
  //     ),
  //   );
  // }
 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("TTC Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded, size: 50, color: Color(0xFF4361EE)),
            ),
            const SizedBox(height: 24),
            Text("Revisa tu correo", style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: "Hemos enviado un código de 6 dígitos a:\n",
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16, height: 1.4),
                children: [
                  TextSpan(text: widget.email, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 🔥 NUEVO DISEÑO: 6 Casillas individuales con TextField invisible superpuesto
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    // Extraemos el carácter actual si existe
                    String char = "";
                    if (_otpController.text.length > index) {
                      char = _otpController.text[index];
                    }
                    // Resaltamos la casilla activa (donde se escribirá el siguiente número)
                    bool isFocused = _otpController.text.length == index;
                    
                    return Container(
                      width: 48,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused ? const Color(0xFF4361EE) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        char,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
                
                // TextField invisible que captura todos los eventos del teclado
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0, // Totalmente invisible
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      onChanged: (val) => setState(() {}), // Refresca las casillas al escribir
                      decoration: const InputDecoration(
                        counterText: "", // Oculta el contador nativo
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorMsg, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 16),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {}, 
                icon: Icon(Icons.refresh_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                label: Text("Reenviar código", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4361EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                onPressed: _isVerifying ? null : _verificar,
                child: _isVerifying 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Verificar Código", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text("Si no lo encuentras, revisa tu carpeta de spam.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}