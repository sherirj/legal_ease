import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_client.dart';
import 'signup_lawyer.dart';
import 'signup_lawfirm.dart';
import 'client_dashboard.dart';
import 'lawyer_dashboard.dart';
import 'legal_assistant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  

  runApp(const LegalApp());
}

class LegalApp extends StatelessWidget {
  const LegalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegalEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFd4af37),
          secondary: Color(0xFF2a2a2a),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFd4af37),
            foregroundColor: Colors.black,
          ),
        ),
      ),

      home: const SplashScreen(),

      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (_) => const WelcomeScreen();
            break;
          case '/splash':
            builder = (_) => const SplashScreen();
            break;
          case '/login':
            builder = (_) => const LoginScreen();
            break;
          case '/signup_client':
            builder = (_) => const SignupClientScreen();
            break;
          case '/signup_lawyer':
            builder = (_) => const SignupLawyerScreen();
            break;
          case '/signup_lawfirm':
            builder = (_) => const SignupLawFirmScreen();
            break;
          case '/client-dashboard':
            builder = (_) => const ClientDashboard();
            break;
          case '/attorney-dashboard':
            builder = (_) => const AttorneyDashboard();
            break;
          case '/legal-assistant-dashboard':
            builder = (_) => const LegalAssistantDashboard();
            break;
          default:
            throw Exception('❌ Invalid route: ${settings.name}');
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween =
                Tween(begin: const Offset(1, 0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut));
            final fadeTween = Tween(begin: 0.0, end: 1.0);

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      },
    );
  }
}
