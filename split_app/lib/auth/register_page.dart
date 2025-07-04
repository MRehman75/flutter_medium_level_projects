import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';
  final VoidCallback onLoginClicked;
  const RegisterPage({super.key, required this.onLoginClicked});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String error = '';
  bool loading = false;
  bool showVerifyMessage = false;

  Future<void> register() async {
    setState(() {
      error = '';
      loading = true;
    });
    try {
      final username = _usernameController.text.trim();
      final usernameQuery =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();
      if (usernameQuery.docs.isNotEmpty) {
        setState(() {
          error = 'Username already taken';
          loading = false;
        });
        return;
      }
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': _emailController.text.trim(),
        'groups': [],
        'cash': 0.0,
      });
      await userCredential.user!.sendEmailVerification();
      await _auth.signOut();
      setState(() {
        showVerifyMessage = true;
        loading = false;
      });
      // Use Navigator to go to login page after showing the verification message
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Registration failed';
        loading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showVerifyMessage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify Email')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A verification email has been sent.\nPlease check your inbox and verify your email before logging in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: register,
                  child: const Text('Register'),
                ),
            TextButton(
              onPressed:
                  () => Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
