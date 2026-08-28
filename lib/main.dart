import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  try {
    // Ensure Flutter engine is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Local NoSQL Database (Hive)
    await Hive.initFlutter();
    await Hive.openBox('tasks');

    // Initialize Indonesian locale formatting
    await initializeDateFormatting('id_ID', null);

    runApp(
      // ProviderScope is required for all Riverpod providers
      const ProviderScope(child: MyApp()),
    );
  } catch (e, stackTrace) {
    debugPrint('=== CRASH STARTUP ERROR ===');
    debugPrint(e.toString());
    debugPrint(stackTrace.toString());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Slate',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgMain,
      ),
      home: const SplashScreen(),
    );
  }
}
