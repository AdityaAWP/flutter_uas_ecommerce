import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  void loginUser() async {
    String username = usernameController.text;
    String password = passwordController.text;

    // Reset previous errors
    setState(() {
      usernameError = null;
      passwordError = null;
      isLoading = true;
    });

    // Validate input
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        usernameError = username.isEmpty ? 'Username tidak boleh kosong' : null;
        passwordError = password.isEmpty ? 'Password tidak boleh kosong' : null;
        isLoading = false;
      });
      return;
    }

    try {
      // Make API call to login
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:8000/api/login'), // Replace with your actual API endpoint
        body: jsonEncode({
          'name': username,
          'password': password,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        isLoading = false;
      });

      // Parse the response
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        // Login successful
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', responseData['access_token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', username);

        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Login failed
        String errorMessage =
            responseData['message'] ?? 'username dan password salah';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan. Silakan coba lagi.')),
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
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006A67),
                  ),
                  onPressed: isLoading ? null : loginUser,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
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
