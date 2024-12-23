import 'package:flutter/material.dart';
import 'package:uts/home.dart';
import 'package:uts/homes.dart';
import 'package:uts/loginpage.dart';
import 'package:uts/registrasionpage.dart';
import 'package:uts/splashscreen.dart';
import 'package:uts/updateuserpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Splashscreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const Home(),
        '/homes': (context) => const Homes(),
        '/login': (context) => const LoginPage(),
        '/updateUser': (context) => const UpdateUserPage(),
        '/register': (context) => const RegistrationPage(),
      },
    );
  }
}
