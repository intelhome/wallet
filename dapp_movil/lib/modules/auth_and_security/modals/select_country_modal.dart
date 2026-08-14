import 'package:flutter/material.dart';

class SelectCountryModal extends StatefulWidget {
  final Map<String, String>? initialCountry;
  const SelectCountryModal({super.key, this.initialCountry});

  static Future<Map<String, String>?> show(BuildContext context, {Map<String, String>? initialCountry}) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectCountryModal(initialCountry: initialCountry),
    );
  }

  @override
  State<SelectCountryModal> createState() => _SelectCountryModalState();
}

class _SelectCountryModalState extends State<SelectCountryModal> {
  final List<Map<String, String>> _allCountries = [
    {'name': 'Ecuador', 'code': '+593', 'flag': '🇪🇨'},
    {'name': 'Colombia', 'code': '+57', 'flag': '🇨🇴'},
    {'name': 'Perú', 'code': '+51', 'flag': '🇵🇪'},
    {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷'},
    {'name': 'México', 'code': '+52', 'flag': '🇲🇽'},
    {'name': 'España', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Estados Unidos', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'Chile', 'code': '+56', 'flag': '🇨🇱'},
    {'name': 'Brasil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Venezuela', 'code': '+58', 'flag': '🇻🇪'},
    {'name': 'Otro', 'code': '', 'flag': '🌍'},
  ];

  List<Map<String, String>> _filteredCountries = [];
  Map<String, String>? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _filteredCountries = _allCountries;
    if (widget.initialCountry != null) {
      _selectedCountry = _allCountries.firstWhere(
        (c) => c['name'] == widget.initialCountry!['name'],
        orElse: () => _allCountries.first,
      );
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _allCountries;
      } else {
        _filteredCountries = _allCountries.where((c) => c['name']!.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // HEADER Y BUSCADOR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.7)), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text("Seleccionar País", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface))),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: _filter,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: "Buscar país...",
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // LISTA DE PAÍSES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = _selectedCountry?['name'] == country['name'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedCountry = country),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4361EE).withOpacity(0.1) : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF4361EE) : onSurface.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(child: Text(country['name']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface))),
                        Text(country['code']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // BOTÓN GUARDAR
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 16, top: 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: onSurface.withOpacity(0.05))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBAC3FF),
                  foregroundColor: const Color(0xFF00218d),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _selectedCountry == null ? null : () => Navigator.pop(context, _selectedCountry),
                child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}