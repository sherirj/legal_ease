import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'signup_user.dart';
import 'signup_lawyer.dart';
import 'signup_lawfirm.dart';
import 'client_dashboard.dart';
import 'lawyer_dashboard.dart';
import 'legal_assistant.dart';
import 'help_support.dart';

void main() {
  runApp(const LegalApp());
}

class LegalApp extends StatelessWidget {
  const LegalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legal App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.brown.shade700,
          secondary: Colors.brown.shade400,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/splash':
            builder = (BuildContext _) => const SplashScreen();
            break;
          case '/':
            builder = (BuildContext _) => const WelcomeScreen();
            break;
          case '/login':
            builder = (BuildContext _) => const LoginScreen();
            break;
          case '/signup_client':
            builder = (BuildContext _) => const SignupClientScreen();
            break;
          case '/signup_lawyer':
            builder = (BuildContext _) => const SignupLawyerScreen();
            break;
          case '/signup_lawfirms':
            builder = (BuildContext _) => const SignupLawFirmScreen();
            break;
          case '/client-dashboard':
            builder = (BuildContext _) => const ClientDashboard();
            break;
          case '/attorney-dashboard':
            builder = (BuildContext _) => const AttorneyDashboard();
            break;
          case '/legal-assistant-dashboard':
            builder = (BuildContext _) => const LegalAssistantDashboard();
            break;
          case '/help-support':
            builder = (BuildContext _) => const HelpSupport();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
            final fadeTween = Tween(begin: 0.0, end: 1.0);
            return SlideTransition(
              position: animation.drive(tween),
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
