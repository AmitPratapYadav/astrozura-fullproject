import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/spotlight_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/booking/booking_session_screen.dart';
import './core/contants/api_constants.dart';
import './core/providers/profile_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ApiConstants.debugPrintBaseUrl(); // prints active URL to console
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotlightProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider()..refresh(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/chat-session': (_) => const BookingSessionScreen(),
        },
      ),
    );
  }
}
