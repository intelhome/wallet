import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/PremiumBlockerModal.dart';
import 'package:dapp_movil/core/helpers/route_helper.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/core/services/local_cache_service.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/app_lock_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/chat_and_social/screens/chat_list_screen.dart';
import 'package:dapp_movil/modules/crowdfunding/screens/campaigns_screen.dart';
import 'package:dapp_movil/modules/debts_and_payments/screens/debts_screen.dart';
import 'package:dapp_movil/modules/document_notary/screens/document_notary_screen.dart';
import 'package:dapp_movil/modules/wallet_and_tx/screens/ttc_business_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import '../../groups_and_social/screens/contacts_screen.dart';
import '../../settings_and_profile/screens/analytics_screen.dart';
import '../../debts_and_payments/screens/scheduled_payments_screen.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../../core/notifications/push_notification_service.dart';

final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  //const MainScreen({super.key});
  MainScreen({Key? key}) : super(key: mainScreenKey ?? key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  AuthCoreService get authCore => Provider.of<AuthCoreService>(context, listen: false);
  DateTime? _pausedTime;
  bool _isLockScreenVisible = false;
  
  int _currentIndex = 0;

  Key _dashboardKey = UniqueKey();

  void forceDashboardRefresh() async {
    if (mounted) {
      final cacheService = LocalCacheService();
      await cacheService.clearDashboardCache(); // Aseguramos limpieza de caché
      
      setState(() {
        // Al cambiar la key, forzamos a Flutter a destruir y recrear el DashboardApp
        _dashboardKey = UniqueKey();
        _currentIndex = 0; // Aseguramos volver a la pestaña de inicio
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotifications();
    });
    _iniciarSimuladorIaSulencioso();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final secondsInBg = DateTime.now().difference(_pausedTime!).inSeconds;
        if (secondsInBg >= 30 && !_isLockScreenVisible) {
          _isLockScreenVisible = true;
          final authCore = Provider.of<AuthCoreService>(context, listen: false);
          
          Navigator.push(
            context,
            RouteHelper.fadeRoute(AppLockScreen(authCore: authCore)),
          ).then((_) {
            _isLockScreenVisible = false;
          });
        }
      }
      _pausedTime = null; 
    }
  }

  // 🔥 LÓGICA DEL SIMULADOR AUTÓNOMO BLINDADA
  void _iniciarSimuladorIaSulencioso() {
    Future.delayed(const Duration(seconds: 10), () async {
      if (!mounted) return;

      try {
        final authCore = Provider.of<AuthCoreService>(context, listen: false);
        
        // 🔥 FIX: Forzamos la ruta absoluta
        final url = "${ApiConfig.baseUrl}/notifications/test-ai-push";
        debugPrint("🤖 Despertando Cerebro IA en: $url");

        final res = await http.get(
          Uri.parse(url),
          headers: authCore.authHeaders,
        );
        
        // 🔥 ESTE LOG NOS DIRÁ LA VERDAD
        debugPrint("🤖 Respuesta del servidor IA: ${res.statusCode} -> ${res.body}");
        
        if (res.statusCode == 200) {
          UIHelper.showCustomSnackbar("La IA está analizando tu perfil...", isError: false);
        }
        
      } catch (e) {
        debugPrint("❌ Error despertando a la IA: $e");
      }
    });
  }

  void _checkPendingNotifications() {
    if (PushNotificationService.pendingRoute != null) {
      final data = PushNotificationService.pendingRoute!;
      PushNotificationService.pendingRoute = null; 

      String tipoNotificacion = data['type'] ?? '';

      if (tipoNotificacion == 'TRANSACTION') {
        setState(() => _currentIndex = 1);
      }
    }
  }

  Widget _getCurrentScreen() {
    // 🔥 SOLO LAS PANTALLAS ESENCIALES 🔥
    switch (_currentIndex) {
      case 0:
       return DashboardApp(key: _dashboardKey);
      case 1:
        return HistoryScreen(key: UniqueKey());
      case 2:
        return AnalyticsScreen(key: UniqueKey());
      case 3:
        return ChatListScreen(key: UniqueKey());
      case 4:
        return CampaignsScreen(key: UniqueKey()); // Solo visible si está activo el Crowdfunding
      default:
       return DashboardApp(key: _dashboardKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: showCrowdfundingGlobal,
      builder: (context, showCrowdfunding, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: isBusinessModeGlobal,
          builder: (context, isBusinessMode, _) {
            
            // 🔥 DISEÑO MATERIAL 3 DE LA BARRA INFERIOR 🔥
            List<NavigationDestination> destinations = [
              NavigationDestination(
                icon: Icon(Icons.wallet_outlined, color: colorScheme.onSurface.withOpacity(0.6)), 
                selectedIcon: Icon(Icons.wallet, color: colorScheme.primary), 
                label: "Inicio"
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: colorScheme.onSurface.withOpacity(0.6)), 
                selectedIcon: Icon(Icons.receipt_long, color: colorScheme.primary), 
                label: "Historial"
              ),
              NavigationDestination(
                icon: Icon(Icons.donut_small_outlined, color: colorScheme.onSurface.withOpacity(0.6)), 
                selectedIcon: Icon(Icons.donut_small, color: colorScheme.primary), 
                label: "Análisis"
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.onSurface.withOpacity(0.6)), 
                selectedIcon: Icon(Icons.chat_bubble_rounded, color: colorScheme.primary), 
                label: "Chat"
              ),
            ];

            // 5to Elemento Opcional
            if (showCrowdfunding) {
              destinations.add(
                NavigationDestination(
                  icon: Icon(Icons.volunteer_activism_outlined, color: colorScheme.onSurface.withOpacity(0.6)), 
                  selectedIcon: Icon(Icons.volunteer_activism, color: colorScheme.primary), 
                  label: "Donar"
                )
              );
            }

            // Seguridad de índices
            if (_currentIndex >= destinations.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _currentIndex = 0));
            }

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              
              // 🔥 ANIMACIÓN FLUIDA DE TRANSICIÓN ENTRE PANTALLAS 🔥
              body: isBusinessMode 
                  ? const TTCBusinessScreen() 
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.05), // Ligero deslizamiento desde abajo
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _getCurrentScreen(),
                    ),
                    
              bottomNavigationBar: isBusinessMode ? null : Container(
                decoration: BoxDecoration(
                  color: theme.cardColor, 
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                  ]
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 65, // Altura refinada
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected, 
                  selectedIndex: _currentIndex >= destinations.length ? 0 : _currentIndex,
                onDestinationSelected: (index) async { 
                    if (_currentIndex != index) {
                      HapticFeedback.lightImpact(); 
                      
                      if (index == 0) {
                        final cacheService = LocalCacheService();
                        await cacheService.clearDashboardCache();
                        _dashboardKey = UniqueKey(); // Aseguramos recreación
                      }
                      
                      setState(() => _currentIndex = index);
                    }
                  },
                  indicatorColor: colorScheme.primary.withOpacity(0.15),
                  destinations: destinations,
                ),
              ),
            );
          }
        );
      }
    );
  }
}
