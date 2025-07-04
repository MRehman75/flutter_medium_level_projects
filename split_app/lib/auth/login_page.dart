import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onRegisterClicked;
  const LoginPage({super.key, required this.onRegisterClicked});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String error = '';
  bool loading = false;
  bool showVerifyMessage = false;
  User? _unverifiedUser;
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        appBar: AppBar(
          title: Text(
            'Verify Email',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SlideTransition(
              position: _offset,
              child: FadeTransition(
                opacity: _opacity,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your email is not verified.\nPlease check your inbox and verify your email before logging in.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4059F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                          ),
                          child: Text(
                            'Check Verification',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: resendVerificationEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D0EB5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                          ),
                          child: Text(
                            'Resend Verification Email',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => setState(() => showVerifyMessage = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 32,
                            ),
                          ),
                          child: Text(
                            'Back to Login',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              error,
                              style: GoogleFonts.openSans(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _opacity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.openSans(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: GoogleFonts.openSans(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: true,
                      ),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            error,
                            style: GoogleFonts.openSans(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 16),
                      loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4059F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 32,
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      TextButton(
                        onPressed: widget.onRegisterClicked,
                        child: Text(
                          'Don\'t have an account? Register',
                          style: GoogleFonts.openSans(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
