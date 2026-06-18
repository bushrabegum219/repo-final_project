import 'dart:async';
import 'dart:ui';

import 'package:amaan_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'signin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _obscure = true;
  bool _pressed = false;
  bool _loading = false;

  StreamSubscription<AuthState>? _authSubscription;

  late AnimationController _bgController;
  late AnimationController _shimmerController;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;

        if (session != null && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();

    _bgController.dispose();
    _shimmerController.dispose();

    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();

    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'amaan://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google error: $e")),
      );
    }
  }

  Future<void> _signUp() async {
    HapticFeedback.lightImpact();

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final ageText = ageController.text.trim();
    final email = emailController.text.trim();
    final password = passController.text.trim();
    final confirmPassword = confirmPassController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        ageText.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age < 13 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid age")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'amaan://login-callback',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'age': age,
          'full_name': '$firstName $lastName',
        },
      );

      if (!mounted) return;

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account created! Please check your email for verification 📩",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFFEDE7FF),
                    const Color(0xFFD6C6FF),
                    _bgController.value,
                  )!,
                  Color.lerp(
                    const Color(0xFFD6C6FF),
                    const Color(0xFFA8F0E8),
                    _bgController.value,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                _glow(-80, -60, 260, const Color(0xFF9F8CFF)),
                _glow(null, -100, 300, const Color(0xFF6FE7DD), right: -50),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 70,
                            color: Color(0xFF8E7CFF),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "CREATE YOUR AMAAN ACCOUNT",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.white.withOpacity(0.25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Create your Amaan account",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2D2350),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Set up your safety profile to continue",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7B728F),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _field(
                                  controller: firstNameController,
                                  label: "First Name",
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 14),
                                _field(
                                  controller: lastNameController,
                                  label: "Last Name",
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 14),
                                _field(
                                  controller: ageController,
                                  label: "Age",
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 14),
                                _field(
                                  controller: emailController,
                                  label: "Email",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _field(
                                  controller: passController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 14),
                                _field(
                                  controller: confirmPassController,
                                  label: "Confirm Password",
                                  icon: Icons.lock_reset_outlined,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 20),
                                _ctaButton("Register"),
                                const SizedBox(height: 18),
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text("OR"),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: _signInWithGoogle,
                                  child: _social(
                                    "Continue with Google",
                                    "assets/google.png",
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account? "),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SignInScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          color: Color(0xFF8E7CFF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscure : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withOpacity(0.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
              )
            : null,
      ),
    );
  }

  Widget _ctaButton(String text) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        await _signUp();
      },
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.95 : 1,
              _pressed ? 0.95 : 1,
              1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment(-1 + _shimmerController.value * 2, -1),
                end: Alignment(1 + _shimmerController.value * 2, 1),
                colors: const [
                  Color(0xFF8E7CFF),
                  Color(0xFF6FE7DD),
                  Color(0xFF8E7CFF),
                ],
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        text,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _social(String text, String imagePath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 22),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _glow(
    double? top,
    double bottom,
    double size,
    Color color, {
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: top == null ? bottom : null,
      left: right == null ? -60 : null,
      right: right,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
          child: Container(
            width: size,
            height: size,
            color: color.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
