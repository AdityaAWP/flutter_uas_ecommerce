import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uts/home.dart';
import 'package:uts/loginpage.dart';
import 'package:uts/orderhistory.dart';
import 'package:uts/registrasionpage.dart';
import 'package:uts/splashscreen.dart';
import 'package:uts/updateuserpage.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAz4DofAEbnxpoMlTjB5_WxJyQnIBcLQpg',
        appId: '1:968243134494:android:d93efa7a8e151132862e0f',
        messagingSenderId: '968243134494',
        projectId: 'flutter-ecommerce-pbb',
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

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
        '/login': (context) => const LoginPage(),
        '/updateUser': (context) => const UpdateUserPage(),
        '/register': (context) => const RegistrationPage(),
        '/orderHistory': (context) => const OrderHistory(), // Add this line
      },
    );
  }
}
