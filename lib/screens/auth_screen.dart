import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  bool _obscure = true;
  bool _pressed = false;
  bool _loading = false;

  late AnimationController _bgController;
  late AnimationController _shimmerController;

  final emailController = TextEditingController();
  final passController = TextEditingController();

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
  }

  @override
  void dispose() {
    _bgController.dispose();
    _shimmerController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  /// ✅ GOOGLE SIGN IN
  Future<void> _signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google error: $e")),
      );
    }
  }

  /// ✅ FACEBOOK SIGN IN
  Future<void> _signInWithFacebook() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook error: $e")),
      );
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
                          const Icon(Icons.shield_rounded,
                              size: 70, color: Color(0xFF8E7CFF)),

                          const SizedBox(height: 16),

                          Text("Welcome Back",
                              style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700)),

                          const SizedBox(height: 6),

                          Text("CREATE YOUR AMAAN ACCOUNT",
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54)),

                          const SizedBox(height: 28),

                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.white.withOpacity(0.25),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                _field(
                                  controller: emailController,
                                  label: "Email",
                                  icon: Icons.email_outlined,
                                ),

                                const SizedBox(height: 16),

                                _field(
                                  controller: passController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),

                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Forgot Password?",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E7CFF))),
                                ),

                                const SizedBox(height: 20),

                                _ctaButton("Sign Up"),

                                const SizedBox(height: 18),

                                Row(
                                  children: const [
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

                                /// ✅ GOOGLE BUTTON
                                GestureDetector(
                                  onTap: _signInWithGoogle,
                                  child: _social("Continue with Google",
                                      "assets/google.png"),
                                ),

                                const SizedBox(height: 10),

                                /// ✅ FACEBOOK BUTTON (WORKING)
                                GestureDetector(
                                  onTap: _signInWithFacebook,
                                  child: _social("Continue with Facebook",
                                      "assets/facebook.png"),
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
                                            fontWeight: FontWeight.w600),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscure : false,
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
                    _obscure ? Icons.visibility_off : Icons.visibility),
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
        HapticFeedback.lightImpact();

        final email = emailController.text.trim();
        final password = passController.text.trim();

        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fill all fields")),
          );
          return;
        }

        setState(() => _loading = true);

        try {
          final res = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
          );

          if (res.user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Account created! Check your email 📩")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }

        setState(() => _loading = false);
      },
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1),
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(text,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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
          Text(text,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _glow(double? top, double bottom, double size, Color color,
      {double? right}) {
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
