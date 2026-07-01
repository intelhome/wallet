import 'package:flutter/material.dart';
import 'debts_screen.dart';
import 'scheduled_payments_screen.dart';

class DebtsAndPaymentsHubScreen extends StatefulWidget {
  const DebtsAndPaymentsHubScreen({super.key});

  @override
  State<DebtsAndPaymentsHubScreen> createState() => _DebtsAndPaymentsHubScreenState();
}

class _DebtsAndPaymentsHubScreenState extends State<DebtsAndPaymentsHubScreen> {
  int _currentIndex = 0;

  // 🔥 IndexedStack mantiene vivas ambas pantallas para no recargar datos al cambiar de pestaña
  final List<Widget> _screens = const [
    DebtsScreen(),
    ScheduledPaymentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: theme.cardColor,
        elevation: 15,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_repeat_rounded),
            activeIcon: Icon(Icons.event_repeat_rounded, size: 28),
            label: "Suscripciones",
          ),
        ],
      ),
    );
  }
}