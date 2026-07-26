import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'actions/alarm_module.dart';
import 'actions/app_launcher_module.dart';
import 'actions/automation_module.dart';
import 'actions/battery_module.dart';
import 'actions/calculator_module.dart';
import 'actions/calendar_module.dart';
import 'actions/camera_vision_module.dart';
import 'actions/clipboard_module.dart';
import 'actions/contacts_module.dart';
import 'actions/desktop_companion_module.dart';
import 'actions/device_info_module.dart';
import 'actions/device_settings_control_module.dart';
import 'actions/flashlight_module.dart';
import 'actions/memory_module.dart';
import 'actions/notes_module.dart';
import 'actions/phone_call_module.dart';
import 'actions/reminders_module.dart';
import 'actions/sms_module.dart';
import 'actions/smart_home_module.dart';
import 'actions/time_date_module.dart';
import 'actions/todo_module.dart';
import 'ai/ai_manager.dart';
import 'config/theme_config.dart';
import 'core/automation_engine.dart';
import 'core/friday_core.dart';
import 'providers/assistant_provider.dart';
import 'repositories/settings_repository.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Error Handling & Crash Recovery ──────────────────────────────
  FlutterError.onError = (details) {
    FridayLogger.error(
      LogCategory.error,
      'FlutterError caught by global handler: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // ── Orientation ─────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── System UI chrome ─────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ThemeConfig.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Load persisted settings & ApiService base URL ─────────────────────
  await SettingsRepository.instance.getBackendUrl();

  // ── FRIDAY Core initialisation ───────────────────────────────────────────
  // All local productivity & device feature modules registered for zero-latency routing.
  await FridayCore.instance.init(
    modules: [
      AppLauncherModule(),
      PhoneCallModule(),
      SmsModule(),
      ContactsModule(),
      CalculatorModule(),
      BatteryModule(),
      DeviceInfoModule(),
      TimeDateModule(),
      NotesModule(),
      RemindersModule(),
      CalendarModule(),
      AlarmModule(),
      TodoModule(),
      ClipboardModule(),
      FlashlightModule(),
      DeviceSettingsControlModule(),
      CameraVisionModule(),
      MemoryModule(),
      DesktopCompanionModule(),
      AutomationModule(),
      SmartHomeModule(),
    ],
    aiRouter: (input) => AIManager.instance.processInput(input),
  );

  // Initialise Automation Engine evaluation loop
  AutomationEngine.instance.init();

  runApp(const FridayApp());
}

class FridayApp extends StatelessWidget {
  const FridayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FridayCore>.value(value: FridayCore.instance),
        ChangeNotifierProvider<AssistantProvider>(
          create: (_) => AssistantProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FRIDAY',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
