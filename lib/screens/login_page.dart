import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Test Firebase initialization with new project
    print('=== LOGIN SCREEN INITIALIZED ===');
    print('Firebase project: TestPro (testpro-73a93)');
    AuthService.debugAuthStatus();
    print('================================');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== LOGIN ATTEMPT START ===');
      UserCredential? result = await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('Login result: $result');
      print('User email: ${result?.user?.email}');
      print('User UID: ${result?.user?.uid}');

      if (result != null) {
        print('=== NAVIGATING TO WELCOME SCREEN ===');
        // Test with a simple screen first
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Welcome!")),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Login Successful!", style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  Text("Welcome to TestPro App", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          )),
        );
        print('=== NAVIGATION COMPLETED ===');
      } else {
        print('=== LOGIN FAILED - RESULT IS NULL ===');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'Account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Try again later.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? result = await AuthService.signInWithGoogle();

      if (result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in failed.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),

            const SizedBox(height: 20),

            const Text("OR"),

            const SizedBox(height: 20),

            // Google Login
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text("Login with Google"),
                onPressed: _isLoading ? null : _signInWithGoogle,
              ),
            ),

            const SizedBox(height: 15),

            // Test Login Function
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                child: const Text("Test Login Function"),
                onPressed: () {
                  print('Test login button pressed');
                  print('Email: ${_emailController.text}');
                  print('Password: ${_passwordController.text}');
                  _signInWithEmail();
                },
              ),
            ),

            const SizedBox(height: 10),

            // Debug button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                child: const Text("Debug Auth Status"),
                onPressed: () {
                  AuthService.debugAuthStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Check console for debug info')),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // Facebook Login
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.facebook),
                label: const Text("Login with Facebook"),
                onPressed: () {
                  // TODO: Facebook login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Facebook login coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}