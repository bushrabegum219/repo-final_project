import 'package:flutter/material.dart';
import 'panic_screen.dart' as panic;
import 'trusted_circle_screen.dart' as trusted;
import 'sos_alarm_screen.dart' as sos;
import 'daily_reminder_screen.dart' as daily;
import 'scam_detector_screen.dart' as scam;
import 'map_screen.dart' as map;
import 'journal_screen.dart' as journal;
import 'evidence_vault_screen.dart' as evidence;
import 'settings_screen.dart' as settings;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7F7FD5),
              Color(0xFF6EA8FF),
              Color(0xFF91EAE4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TOP TITLE
                const Text(
                  "Amaan Safety",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stay safe, connected, and prepared.",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 10, 10, 10).withOpacity(0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                /// HERO PANIC
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = 1 + (_controller.value * 0.05);
                    double glow = 18 + (_controller.value * 24);

                    return Transform.scale(
                      scale: scale,
                      child: _TapScale(
                        onTap: () => _openScreen(panic.PanicScreen()),
                        child: _GlassCard(
                          height: 140,
                          child: Row(
                            children: [
                              Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF3B3B),
                                      Color(0xFFFF6B6B),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.55),
                                      blurRadius: glow,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Panic Alert",
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 43, 42, 42),
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Share location, record audio, and notify contacts.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                /// QUICK ACTIONS
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.people_rounded,
                        title: "Trusted\nCircle",
                        onTap: () =>
                            _openScreen(trusted.TrustedCircleScreen()),
                      ),
                    ),
                    
                  ],
                ),

                const SizedBox(height: 24),

                /// MAIN TOOLS
                const Text(
                  "Safety Tools",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 0,
                  child: _LayeredCard(
                    title: "Scam Detector",
                    subtitle: "Check suspicious messages and links",
                    icon: Icons.security_rounded,
                    colors: const [Color.fromARGB(255, 49, 18, 19), Color.fromARGB(255, 70, 33, 23)],
                    onTap: () => _openScreen(scam.ScamDetectorScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 100,
                  child: _LayeredCard(
                    title: "Map Screen",
                    subtitle: "View location and share safely",
                    icon: Icons.map_rounded,
                    colors: const [Color.fromARGB(255, 64, 80, 69), Color(0xFF38f9d7)],
                    onTap: () => _openScreen(map.MapScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 200,
                  child: _LayeredCard(
                    title: "Evidence Vault",
                    subtitle: "Save photos, files, and proof safely",
                    icon: Icons.folder_special_rounded,
                    colors: const [Color.fromARGB(255, 59, 19, 63), Color(0xFFf5576c)],
                    onTap: () => _openScreen(evidence.EvidenceVaultScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 300,
                  child: _LayeredCard(
                    title: "SOS Alarm",
                    subtitle: "Activate loud emergency alarm",
                    icon: Icons.notifications_active_rounded,
                    colors: const [Color.fromARGB(255, 88, 52, 78), Color(0xFFa6c1ee)],
                    onTap: () => _openScreen(sos.SosAlarmScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 400,
                  child: _LayeredCard(
                    title: "Journal",
                    subtitle: "Write private safety notes",
                    icon: Icons.menu_book_rounded,
                    colors: const [Color.fromARGB(255, 19, 24, 43), Color(0xFF764ba2)],
                    onTap: () => _openScreen(journal.JournalScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 500,
                  child: _LayeredCard(
                    title: "Daily Reminder",
                    subtitle: "Read safety tips and daily protection reminders",
                    icon: Icons.alarm_rounded,
                    colors: const [Color.fromARGB(255, 36, 28, 3), Color(0xFFfda085)],
                    onTap: () => _openScreen(daily.DailyReminderScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                _FadeSlide(
                  delay: 600,
                  child: _LayeredCard(
                    title: "Settings",
                    subtitle: "Manage security and app preferences",
                    icon: Icons.settings_rounded,
                    colors: const [Color.fromARGB(255, 36, 60, 61), Color(0xFF66a6ff)],
                    onTap: () => _openScreen(settings.SettingsScreen()),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// GLASS CARD
class _GlassCard extends StatelessWidget {
  final Widget child;
  final double height;

  const _GlassCard({
    required this.child,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withOpacity(0.18),
        border: Border.all(
          color: Colors.white.withOpacity(0.24),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.18),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

////////////////////////////////////////////////////////////
/// QUICK ACTION CARD
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 21,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// LAYERED CARD
class _LayeredCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  const _LayeredCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            right: 0,
            child: Container(
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.84),
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// TAP SCALE
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double scale = 1;

  void _down(_) => setState(() => scale = 0.96);

  void _up(_) => setState(() => scale = 1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: () => _up(null),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// FADE + SLIDE
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlide({
    required this.child,
    required this.delay,
  });

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacity;
  late Animation<Offset> offset;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    opacity = Tween(begin: 0.0, end: 1.0).animate(controller);
    offset = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}