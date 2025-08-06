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
  runApp(LegalApp());
}

class LegalApp extends StatelessWidget {
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
            builder = (BuildContext _) => SplashScreen();
            break;
          case '/':
            builder = (BuildContext _) => WelcomeScreen();
            break;
          case '/login':
            builder = (BuildContext _) => LoginScreen();
            break;
          case '/signup_client':
            builder = (BuildContext _) => SignupClientScreen();
            break;
          case '/signup_lawyer':
            builder = (BuildContext _) => SignupLawyerScreen();
            break;
          case '/signup_lawfirms':
            builder = (BuildContext _) => SignupLawFirmScreen();
            break;
          case '/client-dashboard':
            builder = (BuildContext _) => ClientDashboard();
            break;
          case '/attorney-dashboard':
            builder = (BuildContext _) => AttorneyDashboard();
            break;
          case '/legal-assistant-dashboard':
            builder = (BuildContext _) => LegalAssistantDashboard();
            break;
          case '/help-support':
            builder = (BuildContext _) => HelpSupport();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: Offset(1, 0), end: Offset.zero)
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
          transitionDuration: Duration(milliseconds: 400),
        );
      },
    );
  }
}
