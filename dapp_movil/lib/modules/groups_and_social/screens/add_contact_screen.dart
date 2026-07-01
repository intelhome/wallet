import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../config/api_config.dart';

class AddContactScreen extends StatefulWidget {
 // final BlockchainService service;
  final String addressToSave;

  const AddContactScreen({
    super.key,
    required this.addressToSave,
  });

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  // 🔥 AGREGAR:
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  bool _guardando = false;
  bool _cargandoAlias = true;
  String _aliasEncontrado = "";

String _categoriaSeleccionada = "Normal";
  final List<String> _categorias = ["Normal", "Familiar", "Comercial"];

  @override
  void initState() {
    super.initState();
    _buscarAliasEnBackend();
  }

  Future<void> _buscarAliasEnBackend() async {
    try {
      String endpoint = ApiConfig.getAliasWallet.replaceAll("{address}", widget.addressToSave.toLowerCase());
      
      // 🔥 FIX 1: Inyección del JWT al buscar el alias
      final res = await http.get(
        Uri.parse(endpoint),
        headers: {
          if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
        }
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _aliasEncontrado = data['alias'] ?? "Desconocido";
          _cargandoAlias = false;
        });
      } else {
        setState(() {
          _aliasEncontrado = "Desconocido";
          _cargandoAlias = false;
        });
      }
    } catch (e) {
      setState(() {
        _aliasEncontrado = "Desconocido";
        _cargandoAlias = false;
      });
    }
  }

  Future<void> _guardarContacto() async {
    setState(() => _guardando = true);

    try {
      // 🔥 FIX 2: Inyección del JWT al guardar el contacto
      final res = await http.post(
        Uri.parse(ApiConfig.addContact),
        headers: {
          "Content-Type": "application/json",
          if (authCore.jwtToken != null) "Authorization": "Bearer ${authCore.jwtToken}"
        },
        body: jsonEncode({
          "ownerAddress": authCore.publicAddress.toLowerCase(),
          "contactAddress": widget.addressToSave.toLowerCase(),
          "alias": _aliasEncontrado, 
          "category": _categoriaSeleccionada,
        }),
      );

      if (!mounted) return;

      // Mejoramos la validación para no mentirle al usuario
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Contacto guardado exitosamente!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst); 
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de sesión: Token inválido", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Este contacto ya existe en tu libreta", style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión al guardar", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

 @override
Widget build(BuildContext context) {
  // 🔥 REGLA 1: Extraer el ColorScheme
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return PopScope(
    canPop: false, 
    child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _cargandoAlias 
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) // 🔥 Adiós blueAccent
            : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 Para iconos de éxito, mantenemos el verde pero más elegante
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("¡Envío Exitoso!", style: TextStyle(color: Colors.green, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 10),
              Text("¿Deseas agregar a este usuario a tus contactos rápidos?", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16)),
              const SizedBox(height: 32),
              
              // 🔥 TARJETA DE USUARIO: Regla 2 (Borde 24)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24), // Más espacio
                decoration: BoxDecoration(
                  color: theme.cardColor, 
                  borderRadius: BorderRadius.circular(24), // 🔥 REGLA 2: Borde 24
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.1))
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: colorScheme.primary.withOpacity(0.1), // 🔥 Fondo tonal
                      child: Text(_aliasEncontrado != "Desconocido" && _aliasEncontrado.isNotEmpty ? _aliasEncontrado[0].toUpperCase() : "?", style: TextStyle(fontSize: 28, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    _aliasEncontrado == "Desconocido" || _aliasEncontrado.isEmpty
                      ? TextField(
                          onChanged: (val) => _aliasEncontrado = val,
                          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Escribe un nombre...",
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                            filled: true,
                            fillColor: colorScheme.onSurface.withOpacity(0.05), // 🔥 REGLA 3: Input limpio
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 REGLA 2: Borde 16
                          ),
                        )
                      : Text("@$_aliasEncontrado", style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                      
                    const SizedBox(height: 8),
                    Text(widget.addressToSave, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontFamily: 'monospace', fontSize: 12)),
                    const SizedBox(height: 24),
                    
                    // 🔥 SELECTOR DE CATEGORÍA
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      dropdownColor: theme.cardColor,
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Categoría",
                        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                        filled: true,
                        fillColor: colorScheme.onSurface.withOpacity(0.05), // 🔥 REGLA 3
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), // 🔥 REGLA 2
                      ),
                      items: _categorias.map((String cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                cat == 'Familiar' ? Icons.favorite_rounded : cat == 'Comercial' ? Icons.storefront_rounded : Icons.person_outline_rounded,
                                color: cat == 'Familiar' ? colorScheme.error : cat == 'Comercial' ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(cat),
                            ],
                          )
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 🔥 BOTÓN PRINCIPAL
              SizedBox(
                width: double.infinity,
                height: 56, // Altura estándar M3
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, 
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)) // 🔥 REGLA 2
                  ),
                  onPressed: _guardando ? null : _guardarContacto,
                  child: _guardando 
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                    : const Text("Guardar Contacto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text("Omitir por ahora", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ),
      ),
    ),
  );
}
}