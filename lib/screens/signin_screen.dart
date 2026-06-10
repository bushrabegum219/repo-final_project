import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  bool _obscure = true;
  bool _pressed = false;
  bool _loading = false;

  late AnimationController _bgController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

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

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.9,
      upperBound: 1.1,
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _triggerPulse() async {
    HapticFeedback.lightImpact();
    await _pulseController.forward();
    await _pulseController.reverse();
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
                          GestureDetector(
                            onTap: _triggerPulse,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _floatController,
                                _pulseController
                              ]),
                              builder: (_, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, -8 * _floatController.value),
                                  child: Transform.scale(
                                    scale: _pulseController.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 95,
                                    height: 95,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8E7CFF),
                                          Color(0xFF6FE7DD),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8E7CFF)
                                              .withOpacity(0.6),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 72,
                                    color: Colors.white,
                                  ),
                                  const Icon(
                                    Icons.lock,
                                    size: 26,
                                    color: Color(0xFF8E7CFF),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text("Welcome Back",
                              style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700)),

                          const SizedBox(height: 6),

                          Text("LOGIN TO CONTINUE",
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54)),

                          const SizedBox(height: 28),

                          Container(
                            constraints:
                                const BoxConstraints(maxWidth: 420),
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
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Forgot Password?",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E7CFF))),
                                ),
                                const SizedBox(height: 20),
                                _ctaButton("Login"),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text("Back"),
                                )
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
                icon: Icon(_obscure
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
              )
            : null,
      ),
    );
  }

  /// ✅ FINAL LOGIN BUTTON (FULLY CORRECT)
  Widget _ctaButton(String text) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();

        setState(() => _loading = true);

        try {
          final res = await Supabase.instance.client.auth
              .signInWithPassword(
            email: emailController.text.trim(),
            password: passController.text.trim(),
          );

          if (res.user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login successful 🔥"),
                backgroundColor: Color(0xFF6FE7DD),
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomeScreen()),
            );
          }
        } on AuthException catch (e) {
          String message = "Something went wrong";

          if (e.message.contains("Invalid login credentials")) {
            message = "Wrong email or password";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFF8E7CFF),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        setState(() => _loading = false);
      },
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.identity()
              ..scale(_pressed ? 0.95 : 1),
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
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
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
