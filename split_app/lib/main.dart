import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/auth_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/home_page.dart';
import 'auth/profile_page.dart';
import 'auth/create_group_page.dart';
import 'auth/group_page.dart';
import 'auth/invite_user_page.dart';
import 'auth/group_dashboard_page.dart';
import 'auth/add_expense_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6D0EB5);
    final accentColor = const Color(0xFF4059F1);
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          headlineMedium: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineMedium: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/login':
            (context) => LoginPage(
              onRegisterClicked:
                  () => Navigator.of(context).pushReplacementNamed('/register'),
            ),
        '/register':
            (context) => RegisterPage(
              onLoginClicked:
                  () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/create_group': (context) => const CreateGroupPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/group') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => GroupPage(groupId: groupId),
          );
        }
        if (settings.name == '/invite_user') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => InviteUserPage(groupId: groupId),
          );
        }
        if (settings.name == '/group_dashboard') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => GroupDashboardPage(groupId: groupId),
          );
        }
        if (settings.name == '/add_expense') {
          final groupId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => AddExpensePage(groupId: groupId),
          );
        }
        return null;
      },
    );
  }
}
