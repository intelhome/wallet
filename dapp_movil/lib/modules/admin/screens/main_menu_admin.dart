import 'package:flutter/material.dart';
import 'package:dapp_movil/modules/admin/screens/admin_panel_screen.dart';
import 'package:dapp_movil/modules/admin/screens/admin_subscription_analytics_screen.dart';
import 'package:dapp_movil/modules/admin/screens/pending_businesses_screen.dart';

class MainMenuAdmin extends StatefulWidget {
  const MainMenuAdmin({super.key});

  @override
  State<MainMenuAdmin> createState() => _MainMenuAdminState();
}

class _MainMenuAdminState extends State<MainMenuAdmin> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminPanelScreen(),
    const AdminSubscriptionAnalyticsScreen(),
    const PendingBusinessesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: theme.scaffoldBackgroundColor, // Fondo oscuro
          indicatorColor: const Color(0xFF4361EE), // Azul del botón seleccionado
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return IconThemeData(color: Colors.white.withOpacity(0.6));
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: "Inicio"),
            NavigationDestination(icon: Icon(Icons.insights_rounded), label: "Analíticas"),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: "Solicitudes"),
          ],
        ),
      ),
    );
  }
}