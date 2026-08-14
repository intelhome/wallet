import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/auth_and_security/modals/select_country_modal.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import '../../wallet_and_tx/screens/dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'seed_phrase_screen.dart';
import 'otp_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers Comunes
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aliasController = TextEditingController();

  // Controllers Persona
  final _cedulaController = TextEditingController();

  // Controllers Empresa
  final _businessNameController = TextEditingController();
  final _rucController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  bool _esCorreoInstitucional(String email) {
    final dominiosProhibidos = ['gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com', 'live.com', 'icloud.com'];
    final dominio = email.split('@').last.toLowerCase();
    return !dominiosProhibidos.contains(dominio);
  }

  Map<String, String>? _selectedCountry;

  void _intentarRegistro() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final isBusiness = _tabController.index == 1;
    final aliasOrBusiness = isBusiness ? _businessNameController.text.replaceAll(' ', '').toLowerCase() : _aliasController.text.trim();

    // 1. Validaciones básicas
    if (_selectedCountry == null) {
      UIHelper.showCustomSnackbar("Por favor, selecciona un país primero", isError: true);
      return;
    }
    
    if (email.isEmpty || pass.isEmpty || _phoneController.text.isEmpty || aliasOrBusiness.isEmpty) {
      UIHelper.showCustomSnackbar("Por favor, llena todos los campos", isError: true);
      return;
    }

    if (isBusiness && !_esCorreoInstitucional(email)) {
      UIHelper.showCustomSnackbar("Las empresas deben usar un correo institucional (no Gmail/Hotmail)", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final userService = Provider.of<UserService>(context, listen: false);

    // 🔥 2. VALIDAR ALIAS ANTES DE ENVIAR EL OTP
    bool isAliasAvailable = await userService.checkAliasAvailability(aliasOrBusiness);
    if (!isAliasAvailable) {
      setState(() => _isLoading = false);
      UIHelper.showCustomSnackbar("El alias @$aliasOrBusiness ya está en uso", isError: true);
      return; // Detenemos el flujo aquí
    }

    // 3. Si todo está perfecto, enviamos el OTP
    bool otpEnviado = await userService.sendOtp(email);

    setState(() => _isLoading = false);

    if (otpEnviado) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            password: pass,
            email: email,
            alias: aliasOrBusiness,
            phoneNumber: _selectedCountry!['code']! + _phoneController.text.trim(), // Se adjunta el prefijo
            extraData: isBusiness ? {
              "type": "BUSINESS",
              "businessName": _businessNameController.text.trim(),
              "ruc": _rucController.text.trim(),
              "website": _websiteController.text.trim(),
              "country": _selectedCountry!['name'],
            } : {
              "type": "PERSONAL",
              "cedula": _cedulaController.text.trim(),
              "country": _selectedCountry!['name'],
            },
          ),
        ),
      );
    } else {
      UIHelper.showCustomSnackbar("Error enviando OTP. Revisa tu correo.", isError: true);
    }
  }

  // void _intentarRegistro() async {
  //   final email = _emailController.text.trim();
  //   final pass = _passwordController.text;
  //   final isBusiness = _tabController.index == 1;

  //   // Validaciones básicas
  //   if (email.isEmpty || pass.isEmpty || _phoneController.text.isEmpty) {
  //     UIHelper.showCustomSnackbar("Por favor, llena todos los campos", isError: true);
  //     return;
  //   }

  //   if (isBusiness && !_esCorreoInstitucional(email)) {
  //     UIHelper.showCustomSnackbar("Las empresas deben usar un correo institucional (no Gmail/Hotmail)", isError: true);
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   // Si todo está bien, enviamos el OTP (reutilizamos tu lógica de validación de correo)
  //   final userService = Provider.of<UserService>(context, listen: false);

    
  //   bool otpEnviado = await userService.sendOtp(email);

  //   setState(() => _isLoading = false);

  //   if (otpEnviado) {
  //     if (!mounted) return;
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => OtpScreen(
  //           password: pass,
  //           email: email,
  //           // Pasamos los datos adicionales según el tipo de cuenta
  //           alias: isBusiness ? _businessNameController.text.replaceAll(' ', '').toLowerCase() : _aliasController.text.trim(),
  //           phoneNumber: _phoneController.text.trim(),
  //           extraData: isBusiness ? {
  //             "type": "BUSINESS",
  //             "businessName": _businessNameController.text.trim(),
  //             "ruc": _rucController.text.trim(),
  //             "website": _websiteController.text.trim(),
  //             "country": _selectedCountry,
  //           } : {
  //             "type": "PERSONAL",
  //             "cedula": _cedulaController.text.trim(),
  //             "country": _selectedCountry,
  //           },
  //         ),
  //       ),
  //     );
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: "Personal"),
            Tab(icon: Icon(Icons.storefront_outlined), text: "Empresa"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
          GestureDetector(
              onTap: () async {
                final result = await SelectCountryModal.show(context, initialCountry: _selectedCountry);
                if (result != null) setState(() => _selectedCountry = result);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCountry != null ? "${_selectedCountry!['flag']} ${_selectedCountry!['name']}" : "Selecciona tu país",
                        style: TextStyle(color: _selectedCountry != null ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campos comunes
            _buildField(controller: _emailController, label: "Correo Electrónico", icon: Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField(controller: _phoneController, label: "Teléfono de contacto", icon: Icons.phone_android_outlined, type: TextInputType.phone),
            const SizedBox(height: 16),
            
            // Campos dinámicos según el Tab
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // FORMULARIO PERSONAL
               Column(
                    children: [
                      _buildField(controller: _aliasController, label: "Alias de Usuario", icon: Icons.alternate_email),
                      const SizedBox(height: 16),
                      // 🔥 MODIFICADO: Título y límite dinámico según el país
                      _buildField(
                        controller: _cedulaController, 
                        label: _selectedCountry == 'Ecuador' ? "Cédula Ecuatoriana" : "Documento de Identidad (DNI)", 
                        icon: Icons.badge_outlined, 
                        type: TextInputType.number, 
                        limit: _selectedCountry == 'Ecuador' ? 10 : 20
                      ),
                    ],
                  ),
                  // FORMULARIO EMPRESA
                Column(
                    children: [
                      _buildField(controller: _businessNameController, label: "Nombre del Comercio", icon: Icons.business_outlined),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _rucController, 
                        label: _selectedCountry == 'Ecuador' ? "RUC" : "Identificación Fiscal", 
                        icon: Icons.numbers_outlined, 
                        type: TextInputType.number, 
                        limit: _selectedCountry == 'Ecuador' ? 13 : 20
                      ),
                      const SizedBox(height: 16),
                      _buildField(controller: _websiteController, label: "Página Web (opcional)", icon: Icons.language_outlined),
                    ],
                  ),
                ],
              ),
            ),
            _buildField(
              controller: _passwordController, 
              label: "Contraseña de Bóveda", 
              icon: Icons.lock_outline, 
              isPass: true, 
              obscure: _obscurePass,
              onToggle: () => setState(() => _obscurePass = !_obscurePass)
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _intentarRegistro,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Continuar verificación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPass = false, 
    bool obscure = false, 
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
    int? limit
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      maxLength: limit,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPass ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility), onPressed: onToggle) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        counterText: "",
      ),
    );
  }
}