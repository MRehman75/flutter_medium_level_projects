import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onRegisterClicked;
  const LoginPage({super.key, required this.onRegisterClicked});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String error = '';
  bool loading = false;
  bool showVerifyMessage = false;
  User? _unverifiedUser;

  Future<void> login() async {
    setState(() {
      error = '';
      loading = true;
      showVerifyMessage = false;
    });
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        setState(() {
          showVerifyMessage = true;
          _unverifiedUser = userCredential.user;
          loading = false;
        });
        return;
      }
      setState(() {
        loading = false;
      });
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? 'Login failed';
        loading = false;
      });
      return;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _unverifiedUser?.sendEmailVerification();
      setState(() {
        error = 'Verification email resent. Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        error = 'Failed to resend verification email.';
      });
    }
  }

  Future<void> checkVerification() async {
    if (_unverifiedUser != null) {
      await _unverifiedUser!.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        setState(() {
          showVerifyMessage = false;
          error = '';
        });
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          error = 'Email not verified yet. Please check your inbox.';
        });
      }
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
                'Your email is not verified.\nPlease check your inbox and verify your email before logging in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: checkVerification,
                child: const Text('Check Verification'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: resendVerificationEmail,
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => showVerifyMessage = false),
                child: const Text('Back to Login'),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                : ElevatedButton(onPressed: login, child: const Text('Login')),
            TextButton(
              onPressed: widget.onRegisterClicked,
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
