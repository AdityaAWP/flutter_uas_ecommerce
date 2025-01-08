import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameError;
  String? passwordError;
  bool isLoading = false;

  Future<void> signInWithFacebook() async {
    setState(() {
      isLoading = true;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();

        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        print('Facebook login failed: ${result.status}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook login failed: ${result.status}')),
        );
      }
    } catch (e, stackTrace) {
      print('Facebook login error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook login failed: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void loginUser() async {
    String username = usernameController.text;
    String password = passwordController.text;

    setState(() {
      usernameError = null;
      passwordError = null;
      isLoading = true;
    });

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        usernameError = username.isEmpty ? 'Username tidak boleh kosong' : null;
        passwordError = password.isEmpty ? 'Password tidak boleh kosong' : null;
        isLoading = false;
      });
      return;
    }

    try {
      print('Attempting to login with username: $username');

      final response = await http.post(
        Uri.parse(
            'https://3289-103-246-107-4.ngrok-free.app/api/login'), // Updated IP address
        body: jsonEncode({
          'name': username,
          'password': password,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        isLoading = false;
      });

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', responseData['access_token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username);
        await prefs.setString('user_id', responseData['data']['id'].toString());

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String errorMessage =
            responseData['message'] ?? 'Username dan password salah';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Center(
                  child: Image.asset(
                    "assets/login.png",
                    width: 200,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Username Field
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: usernameError,
                ),
              ),
              const SizedBox(height: 20),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError,
                ),
              ),
              const SizedBox(height: 20),
              // Regular Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006A67),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isLoading ? null : loginUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Facebook Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2), // Facebook blue
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isLoading ? null : signInWithFacebook,
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text(
                    'Login with Facebook',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // Link to Registration
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Belum punya akun? Registrasi disini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
