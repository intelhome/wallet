import 'dart:convert';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/login_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:dapp_movil/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'register_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../wallet_and_tx/screens/dashboard_screen.dart';
import '../../wallet_and_tx/screens/main_screen.dart';

class SeedPhraseScreen extends StatefulWidget {
 // final BlockchainService service;
  final String password;
  final String email;  // 🔥 NUEVO
  final String alias;
  final String phoneNumber;
  final Map<String, dynamic>? extraData;

  const SeedPhraseScreen({
    super.key,
   // required this.service,
    required this.password,
    required this.email,
    required this.alias,
    required this.phoneNumber,
    this.extraData,
  });

  @override
  State<SeedPhraseScreen> createState() => _SeedPhraseScreenState();
}

class _SeedPhraseScreenState extends State<SeedPhraseScreen> {
  List<String> _seedWords = [];
  bool _isCopied = false;
  bool _isLoading = false;

  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _generateSeedPhrase();
  }

  void _generateSeedPhrase() {
    String mnemonic = bip39.generateMnemonic();
    setState(() {
      _seedWords = mnemonic.split(' ');
    });
  }

  void _copyToClipboard() {
    final phrase = _seedWords.join(' ');
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: phrase));
    setState(() => _isCopied = true);

    UIHelper.showCustomSnackbar( "Frase copiada al portapapeles");
  }

  // Future<void> _crearBilleteraFinal() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     String phrase = _seedWords.join(' ');
  //     await authCore.createWalletFromMnemonic(phrase);
  //     await authCore.savePin(widget.password);

  //     String nuevaWalletGenerada = authCore.publicAddress;

  //     String? fcmToken;
  //     try {
  //       fcmToken = await FirebaseMessaging.instance.getToken();
  //     } catch (e) {
  //       print("Error obteniendo FCM Token preventivo: $e");
  //     }

  //     final url = Uri.parse(ApiConfig.registerUser);
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({
  //         "alias": widget.alias,
  //         "walletAddress": nuevaWalletGenerada.toLowerCase(),
  //         "email": widget.email,
  //         "password": widget.password,
  //         "phoneNumber": widget.phoneNumber,
  //         if (fcmToken != null) "fcmToken": fcmToken
  //       }),
  //     );

  //     print("📡 Respuesta del Servidor al Registrar: ${response.statusCode} - ${response.body}");

  //     if (response.statusCode == 200 || response.statusCode == 201) {
        
  //       // 1. PRIMERO OBTENEMOS EL TOKEN (Porque la ruta de alias está protegida)
  //       await authCore.requestJwtToken(widget.password);

  //       // 🔥 FIX: AHORA SÍ REGISTRAMOS EL ALIAS EN LA BASE DE DATOS GLOBAL 🔥
  //       try {
  //         final urlAlias = Uri.parse(ApiConfig.registerAlias);
  //         await http.post(
  //           urlAlias,
  //           headers: {
  //             "Content-Type": "application/json",
  //             if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
  //           },
  //           body: jsonEncode({
  //             "alias": widget.alias,
  //             "walletAddress": nuevaWalletGenerada.toLowerCase()
  //           }),
  //         );
  //         print("✅ Alias registrado globalmente.");
  //       } catch (e) {
  //         print("Aviso: No se pudo registrar el alias global: $e");
  //       }

  //       if (!mounted) return;
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //          builder: (context) => MainScreen(),
  //         ),
  //         (Route<dynamic> route) => false,
  //       );
  //     } else {
  //       UIHelper.showCustomSnackbar("Error del Servidor: ${response.body}", isError: true);
  //     }
  //   } catch (e) {
  //     print("❌ Excepción crítica al crear billetera: $e");
  //     UIHelper.showCustomSnackbar("Error de red: no se pudo conectar al servidor.", isError: true);
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

Future<void> _crearBilleteraFinal() async {
    setState(() => _isLoading = true);

    try {
      print("🛠️ [REGISTRO] Iniciando creación de billetera final...");
      String phrase = _seedWords.join(' ');
      await authCore.createWalletFromMnemonic(phrase);
      await authCore.savePin(widget.password);

      String nuevaWalletGenerada = authCore.publicAddress;
      print("🛠️ [REGISTRO] Wallet generada: $nuevaWalletGenerada");

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print("⚠️ [REGISTRO] Error obteniendo FCM Token: $e");
      }

      //  LÓGICA DUAL: PERSONA VS EMPRESA
      final bool esEmpresa = widget.extraData?["type"] == "BUSINESS";
      final String urlFinal = esEmpresa ? ApiConfig.registerBusiness : ApiConfig.registerUser;

      print("🛠️ [REGISTRO] ¿Es Empresa?: $esEmpresa | Endpoint: $urlFinal");

      // Armamos el JSON dinámicamente según el tipo
      Map<String, dynamic> requestBody = {
        "walletAddress": nuevaWalletGenerada.toLowerCase(),
        "email": widget.email,
        "password": widget.password,
        "phoneNumber": widget.phoneNumber,
        if (fcmToken != null) "fcmToken": fcmToken,
        "country": widget.extraData?["country"] ?? "Ecuador",
      };

      if (esEmpresa) {
        requestBody["businessName"] = widget.extraData?["businessName"];
        requestBody["ruc"] = widget.extraData?["ruc"];
        requestBody["website"] = widget.extraData?["website"];
      } else {
        requestBody["alias"] = widget.alias;
        requestBody["cedula"] = widget.extraData?["cedula"];
      }

      print("📡 [REGISTRO] Enviando JSON al backend: $requestBody");

      final url = Uri.parse(urlFinal);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("📡 [REGISTRO] Respuesta HTTP ${response.statusCode}: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        if (esEmpresa) {
          // Si es empresa, borramos la sesión local porque requiere aprobación del Admin
          await authCore.deleteWallet(); 
          UIHelper.showCustomSnackbar("Registro exitoso. Tu cuenta empresarial está en revisión.", isError: false);
          
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
        } else {
          // Flujo normal de usuario personal
          await authCore.requestJwtToken(widget.password);
          try {
            await http.post(
              Uri.parse(ApiConfig.registerAlias),
              headers: { "Content-Type": "application/json", if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" },
              body: jsonEncode({ "alias": widget.alias, "walletAddress": nuevaWalletGenerada.toLowerCase() }),
            );
          } catch (e) {}

          if (!mounted) return;
          
          // 🔥 FIX: Navegamos a MainScreen y le decimos que muestre el modal de bienvenida
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => MainScreen(showWelcomeTrial: true, newAlias: widget.alias)), 
            (r) => false
          );
        }
        
        // if (esEmpresa) {
        //   // Si es empresa, borramos la sesión local porque requiere aprobación del Admin
        //   await authCore.deleteWallet(); 
        //   UIHelper.showCustomSnackbar("Registro exitoso. Tu cuenta empresarial está en revisión.", isError: false);
          
        //   if (!mounted) return;
        //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
        // } else {
        //   // Flujo normal de usuario personal
        //   await authCore.requestJwtToken(widget.password);
        //   try {
        //     await http.post(
        //       Uri.parse(ApiConfig.registerAlias),
        //       headers: { "Content-Type": "application/json", if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}" },
        //       body: jsonEncode({ "alias": widget.alias, "walletAddress": nuevaWalletGenerada.toLowerCase() }),
        //     );
        //   } catch (e) {}

        //   if (!mounted) return;
        //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>  MainScreen()), (r) => false);
        // }

      } else {
        await authCore.deleteWallet();
        String errorMsg = "Error desconocido del servidor.";
        
        // 🔥 LOGS EXTRA PARA DEBUGGING
        print("🚨 [REGISTRO] ERROR HTTP: ${response.statusCode}");
        print("🚨 [REGISTRO] BODY DEL ERROR: '${response.body}'");

        if (response.statusCode == 403 || response.statusCode == 401) {
            errorMsg = "El servidor bloqueó la petición (Error de Seguridad/Ruta). Avisa al desarrollador backend.";
        } else {
            try { 
              errorMsg = jsonDecode(response.body)['message'] ?? jsonDecode(response.body)['error'] ?? response.body; 
            } catch(_) { 
              if (response.body.isNotEmpty) errorMsg = response.body; 
            }
        }
        
        UIHelper.showCustomSnackbar(errorMsg, isError: true);
      }
    } catch (e) {
      print("❌ [REGISTRO] Excepción crítica al crear billetera: $e");
      await authCore.deleteWallet();
      UIHelper.showCustomSnackbar("Error de red: no se pudo conectar al servidor.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final onSurface = colorScheme.onSurface;
//     return Scaffold(
//      backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: Text(
//           "Tu Bóveda Segura",
//           style: TextStyle(color: onSurface),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//              Icon(Icons.security_rounded, size: 60, color: colorScheme.secondary),
//               const SizedBox(height: 20),
//               const Text(
//                 "Guarda tus 12 palabras",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 "Anota estas palabras en un papel y guárdalo en un lugar seguro. Si pierdes estas palabras, PERDERÁS TODOS TUS FONDOS. Nosotros no podemos recuperarlas.",
//                 style: TextStyle(color: Colors.white70, fontSize: 14),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),

//               Expanded(
//                 child: _seedWords.isEmpty
//                     ? const Center(
//                         child: CircularProgressIndicator(
//                           color: Colors.orangeAccent,
//                         ),
//                       )
//                     : GridView.builder(
//   shrinkWrap: true,
//   physics: const NeverScrollableScrollPhysics(),
//   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//     crossAxisCount: 3,
//     crossAxisSpacing: 12,
//     mainAxisSpacing: 12,
//     childAspectRatio: 2.2,
//   ),
//   itemCount: _seedWords.length,
//   itemBuilder: (context, index) {
//     return AnimatedContainer(
//       duration: Duration(milliseconds: 300 + (index * 50)),
//       curve: Curves.easeOut,
//       decoration: BoxDecoration(
//         color: colorScheme.secondaryContainer.withOpacity(0.7), // Color tonal M3
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
//         ]
//       ),
//       child: Stack(
//         children: [
//           Positioned( // ✅ CORREGIDO
//             top: 6,
//             left: 6,
//             child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: colorScheme.primary.withOpacity(0.5))),
//             // child: Align(
//             //   alignment: Alignment.topLeft,
//             //   child: Padding(
//             //     padding: const EdgeInsets.all(6.0),
//             //     child: Text("${index + 1}", style: TextStyle(fontSize: 10, color: colorScheme.primary.withOpacity(0.5))),
//             //   ),
//             // ),
//           ),
//           Center(
//             child: Text(
//               _seedWords[index],
//               style: TextStyle(
//                 color: colorScheme.onSecondaryContainer,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//                 letterSpacing: 0.5
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   },
// ),
//               ),
//               SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   TextButton.icon(
//                     onPressed: _copyToClipboard,
//                     icon: Icon(
//                       _isCopied ? Icons.check : Icons.copy,
//                       color: Colors.orangeAccent,
//                     ),
//                     label: Text(
//                       _isCopied
//                           ? "Copiado al portapapeles"
//                           : "Copiar al portapapeles",
//                       style: const TextStyle(color: Colors.orangeAccent),
//                     ),
//                   ),
//                   TextButton.icon(
//                     onPressed: () async {
//                       final phrase = _seedWords.join('');

//                       final directory =
//                           await getApplicationDocumentsDirectory();
//                       final file = File(
//                         '${directory.path}/TTC_Wallet_Backup.txt',
//                       );
//                       await file.writeAsString(
//                         "ESTE ES TU RESPALDO SECRETO.\nNUNCA LO COMPARTAS CON NADIE.\n\nFrase:\n$phrase",
//                       );

//                       await Share.shareXFiles(
//                         [XFile(file.path)],
//                         subject: "Respaldo Billetera TTC",
//                         text: "Guarda este archivo en un lugar seguro.",
//                       );

//                       setState(() => _isCopied = true);
//                     },
//                     icon: const Icon(Icons.download, color: Colors.blueAccent),
//                     label: const Text(
//                       "Exportar Frase",
//                       style: TextStyle(
//                         color: Colors.blueAccent,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               ),

//               const SizedBox(height: 20),

//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: _isLoading ? null : _crearBilleteraFinal,
//                 child: _isLoading
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text(
//                         "Ya guardé mi frase segura",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Márgenes reducidos
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.shield_outlined, size: 40, color: colorScheme.primary), // Icono más pequeño
              ),
              const SizedBox(height: 12),
              Text("Guarda tus 12 palabras", style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              
              // Advertencia más pequeña
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Text.rich(
                  TextSpan(
                    text: "Anota estas palabras en un papel y guárdalo en un lugar seguro. Si pierdes estas palabras, ",
                    style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, height: 1.3), // Fuente más pequeña
                    children: const [
                      TextSpan(text: "PERDERÁS TODOS TUS FONDOS", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      TextSpan(text: ". Nosotros no podemos recuperarlas."),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Contenedor de palabras más compacto
              Expanded(
                child: _seedWords.isEmpty
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8, // Menos espacio horizontal
                          mainAxisSpacing: 8,  // Menos espacio vertical
                          childAspectRatio: 3.5, // Tarjetas más delgadas para que quepan
                        ),
                        itemCount: _seedWords.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: onSurface.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, // Indicador de número más pequeño
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: onSurface.withOpacity(0.05),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                                  ),
                                  child: Text("${index + 1}", style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      _seedWords[index],
                                      style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14), // Texto más pequeño
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              
              // Botones secundarios más pequeños
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _copyToClipboard,
                    icon: Icon(_isCopied ? Icons.check : Icons.copy_rounded, color: const Color(0xFFFFB86B), size: 16),
                    label: Text("Copiar al portapapeles", style: TextStyle(color: const Color(0xFFFFB86B).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final phrase = _seedWords.join('');
                      final directory = await getApplicationDocumentsDirectory();
                      final file = File('${directory.path}/TTC_Wallet_Backup.txt');
                      await file.writeAsString("ESTE ES TU RESPALDO SECRETO.\nNUNCA LO COMPARTAS CON NADIE.\n\nFrase:\n$phrase");
                      await Share.shareXFiles([XFile(file.path)], subject: "Respaldo Billetera TTC", text: "Guarda este archivo en un lugar seguro.");
                      setState(() => _isCopied = true);
                    },
                    icon: Icon(Icons.download_rounded, color: onSurface.withOpacity(0.6), size: 16),
                    label: Text("Exportar Frase", style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Botón principal
              SizedBox(
                width: double.infinity,
                height: 52, // Un poco más bajo
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4361EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _crearBilleteraFinal,
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Ya guardé mi frase segura", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
