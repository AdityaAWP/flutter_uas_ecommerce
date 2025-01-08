import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Import the user model

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameError;
  String? emailError;
  String? passwordError;
  bool isLoading = false;

  void registerUser() async {
    String username = usernameController.text;
    String email = emailController.text;
    String password = passwordController.text;

    setState(() {
      usernameError = username.isEmpty ? 'Username tidak boleh kosong' : null;
      emailError = email.isEmpty ? 'Email tidak boleh kosong' : null;
      passwordError =
          password.isNotEmpty ? null : 'Password tidak boleh kosong';
      isLoading = true;
    });

    if (usernameError == null && emailError == null && passwordError == null) {
      try {
        var response = await http.post(
          Uri.parse(
              'https://3289-103-246-107-4.ngrok-free.app/api/register'), // Update this line
          body: jsonEncode({
            'name': username,
            'email': email,
            'password': password,
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        setState(() {
          isLoading = false;
        });

        if (response.statusCode == 201) {
          // Registration successful, navigate to login
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Handle registration error
          var errorData = json.decode(response.body);
          setState(() {
            usernameError = errorData['name']?.first;
            emailError = errorData['email']?.first;
            passwordError = errorData['password']?.first;
          });
          showAlertDialog(context, "Registration Failed",
              "Please check your input and try again.");
        }
      } catch (e, stackTrace) {
        print('Registration error: $e');
        print('Stack trace: $stackTrace');

        setState(() {
          isLoading = false;
        });
        showAlertDialog(context, "Registration Error", "Error: $e");
      }
    } else {
      setState(() {
        isLoading = false;
      });
      showAlertDialog(
          context, "Validation Error", "Please fill all fields correctly.");
    }
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Image.asset(
                    "assets/login.png",
                    width: 200,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Register',
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
              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError,
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
              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF006A67),
                  ),
                  onPressed: isLoading ? null : registerUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              // Link to Login
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Sudah Punya Akun? Login disini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
