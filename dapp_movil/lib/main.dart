import 'package:dapp_movil/config/api_config.dart';
import 'package:dapp_movil/core/helpers/ui_helper.dart';
import 'package:dapp_movil/modules/admin/services/admin_service.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_chat_handler.dart';
import 'package:dapp_movil/modules/ai_assistant/services/ai_memory_service.dart';
import 'package:dapp_movil/modules/auth_and_security/screens/app_lock_screen.dart';
import 'package:dapp_movil/modules/auth_and_security/services/panic_mode_service.dart';
import 'package:dapp_movil/modules/auth_and_security/services/planConfigService.dart';
import 'package:dapp_movil/modules/auth_and_security/services/auth_core_service.dart';
import 'package:dapp_movil/modules/burner_wallets/services/burner_service.dart';
import 'package:dapp_movil/modules/business/services/business_service.dart';
import 'package:dapp_movil/modules/business/services/business_task_service.dart';
import 'package:dapp_movil/modules/chat_and_social/screens/chat_room_screen.dart';
import 'package:dapp_movil/modules/chat_and_social/services/secure_chat_service.dart';
import 'package:dapp_movil/modules/crowdfunding/services/crowdfunding_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/debt_service.dart';
import 'package:dapp_movil/modules/debts_and_payments/services/scheduled_payment_service.dart';
import 'package:dapp_movil/modules/document_notary/services/notary_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/contact_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/family_service.dart';
import 'package:dapp_movil/modules/groups_and_social/services/group_social_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_config_service.dart';
import 'package:dapp_movil/modules/settings_and_profile/services/user_service.dart';
import 'package:dapp_movil/modules/vaults_and_savings/services/smart_vault_service.dart';
import 'package:dapp_movil/modules/wallet_and_tx/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/auth_and_security/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:io';
import 'core/notifications/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔥 Notificación en background: ${message.messageId}");
}
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<bool> discreetModeNotifier = ValueNotifier(false);
final ValueNotifier<bool> customCardNotifier = ValueNotifier(true);
//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  // Aseguramos que Flutter esté listo antes de leer la memoria
  WidgetsFlutterBinding.ensureInitialized(); 

  await Hive.initFlutter();

 
  await Hive.openBox('contacts_cache');
  await Hive.openBox('chat_cache');
 
  await Hive.openBox('crowd_cache'); 
  await Hive.openBox('business_cache');
  await Hive.openBox('admin_cache');
  await Hive.openBox('ai_cache');
  await Hive.openBox('burner_cache');
  await Hive.openBox('debts_cache');
  await Hive.openBox('notary_cache');
  await Hive.openBox('notifications_cache');
  await Hive.openBox('vaults_cache');

await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //await PushNotificationService.init();

  if (Platform.isAndroid || Platform.isIOS) {
    await ScreenProtector.preventScreenshotOn();
  }
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      // Damos un pequeño retraso para que Flutter termine de pintar la primera pantalla
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationClick(message);
      });
    }
  });


final authCore = AuthCoreService();
  await authCore.init(); 

  final planConfigService = PlanConfigService();
  planConfigService.fetchPlansConfig().catchError((e) {
    print("Error de red en background: $e");
  });

  final txService = TransactionService(authCore);
  final crowdfundingService = CrowdfundingService(authCore);
  final burnerService = BurnerService(authCore);
  final vaultService = SmartVaultService(authCore);
  final notaryService = NotaryService(authCore);
  final groupSocialService = GroupSocialService(authCore);
  final debtService = DebtService(authCore, txService); // Requiere Auth y Tx
  final scheduledPaymentService = ScheduledPaymentService(authCore);
  final userService = UserService(authCore);
  final contacService = ContactService(authCore);
  final chatService = SecureChatService(authCore);


  // Leemos la memoria caché del teléfono
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode') ?? 'Oscuro'; // Por defecto será Oscuro
  customCardNotifier.value = prefs.getBool('use_custom_card') ?? true;

  // Aplicamos el tema guardado ANTES de arrancar la app
  if (savedTheme == 'Claro') {
    themeNotifier.value = ThemeMode.light;
  } else if (savedTheme == 'Sistema') {
    themeNotifier.value = ThemeMode.system;
  } else {
    themeNotifier.value = ThemeMode.dark;
  }

  discreetModeNotifier.value = prefs.getBool('discreetMode') ?? false;

  isBusinessModeGlobal.value = prefs.getBool('is_business_mode_enabled') ?? false;

  customCardNotifier.addListener(() {
    prefs.setBool('use_custom_card', customCardNotifier.value);
  });

  isBusinessModeGlobal.addListener(() {
    prefs.setBool('is_business_mode_enabled', isBusinessModeGlobal.value);
  });

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authCore),
        Provider.value(value: planConfigService),
        Provider.value(value: txService),
        Provider.value(value: crowdfundingService),
        Provider.value(value: burnerService),
        Provider.value(value: vaultService),
        Provider.value(value: notaryService),
        Provider.value(value: groupSocialService),
        Provider.value(value: debtService),
        Provider.value(value: scheduledPaymentService),
        Provider.value(value: userService),
        Provider.value(value: contacService),
       ChangeNotifierProvider.value(value: chatService),

       ProxyProvider<AuthCoreService, BusinessService>(
          update: (_, authCore, __) => BusinessService(authCore),
        ),

        ProxyProvider<AuthCoreService, BusinessTaskService>(
          update: (_, authCore, __) => BusinessTaskService(authCore),
        ),
        ProxyProvider<AuthCoreService, AdminService>(
          update: (_, authCore, __) => AdminService(authCore),
        ),
        ProxyProvider<AuthCoreService, FamilyService>(
          update: (_, authCore, __) => FamilyService(authCore),
        ),

        ProxyProvider<AuthCoreService, UserConfigService>(
          update: (_, authCore, __) => UserConfigService(authCore),
        ),
        ChangeNotifierProvider(create: (context) => AiChatHandler()),

        

        ProxyProvider<AuthCoreService, PanicModeService>(
  update: (_, authCore, __) => PanicModeService(authCore),
),
ProxyProvider<AuthCoreService, AiMemoryService>(
  update: (_, authCore, __) => AiMemoryService(authCore),
),
       // ChangeNotifierProvider.value(value: chatService),
      ],
      child: const MiDApp(),
    ),
  );
}

void _handleNotificationClick(RemoteMessage message) {
  if (message.data['type'] == 'CHAT') {
    final senderWallet = message.data['senderWallet'];
    final senderAlias = message.data['senderAlias'];

    if (senderWallet != null && senderAlias != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            alias: senderAlias,
            address: senderWallet,
          ),
        ),
      );
    }
  }
}

class MiDApp extends StatefulWidget {
  const MiDApp({super.key});

  @override
  State<MiDApp> createState() => _MiDAppState();
}

class _MiDAppState extends State<MiDApp> with WidgetsBindingObserver {
  DateTime? _backgroundTime;
  bool _isLockScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    PushNotificationService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        if (diff.inSeconds > 30 && !_isLockScreenOpen) {
          _isLockScreenOpen = true;
          
          final authCore = Provider.of<AuthCoreService>(navigatorKey.currentContext!, listen: false);

          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => AppLockScreen(authCore: authCore))
          ).then((_) => _isLockScreenOpen = false);
        }
      }
    }
  }

@override
  Widget build(BuildContext context) {
    const lightBg = Color(0xFFF8FAFC);
    const lightSurface = Color(0xFFFFFFFF);
    const lightPrimary = Color(0xFF0F62FE);
    const lightSecondary = Color(0xFFF59E0B);
    const lightText = Color(0xFF1E293B);

    const darkBg = Color(0xFF0B1120);
    const darkSurface = Color(0xFF1E293B);
    const darkPrimary = Color(0xFF3B82F6);
    const darkSecondary = Color(0xFFFBBF24);
    const darkText = Color(0xFFF8FAFC);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          
          scaffoldMessengerKey: UIHelper.messengerKey,
         navigatorKey: navigatorKey,
         
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), 
            Locale('en', 'US'), 
          ],
          debugShowCheckedModeBanner: false,
          title: 'TTC Wallet',
          themeMode: currentMode,
          
         
          theme: ThemeData.light(useMaterial3: true).copyWith(
            primaryColor: lightPrimary,
            scaffoldBackgroundColor: lightBg,
            cardColor: lightSurface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: lightText),
              titleTextStyle: TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            colorScheme: const ColorScheme.light(
              primary: lightPrimary,
              secondary: lightSecondary,
              surface: lightSurface,
              onSurface: lightText,
              error: Color(0xFFEF4444), 
            ),
            iconTheme: const IconThemeData(color: lightText),
            dividerColor: lightText.withOpacity(0.1),
            cardTheme: const CardThemeData( 
              color: lightSurface,
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0)),
              ),
            ),
          ),

          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            primaryColor: darkPrimary,
            scaffoldBackgroundColor: darkBg,
            cardColor: darkSurface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: darkText),
              titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            colorScheme: const ColorScheme.dark(
              primary: darkPrimary,
              secondary: darkSecondary,
              surface: darkSurface,
              onSurface: darkText,
              error: Color(0xFFEF4444),
            ),
            iconTheme: const IconThemeData(color: darkText),
            dividerColor: darkText.withOpacity(0.1),
            cardTheme: const CardThemeData( 
              color: darkSurface,
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0)),
              ),
            ),
          ),
          home: const InitialRouter(), // Pantalla Splash/Auth inicial
        );
      },
    );
  }
}