import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsOn = true;
  bool liveTrackingOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Settings",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F2940),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 34,
                    width: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8DFFF),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8E6AE8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("ACCOUNT & SECURITY"),

                    const SizedBox(height: 10),

                    _settingsCard(
                      children: [
                        _settingsItem(
                          icon: Icons.lock_rounded,
                          iconColor: const Color(0xFF9B75F0),
                          iconBg: const Color(0xFFF0E9FF),
                          title: "Change Password",
                          subtitle: null,
                          onTap: () {},
                        ),
                        _divider(),
                        _settingsItem(
                          icon: Icons.shield_rounded,
                          iconColor: const Color(0xFF9B75F0),
                          iconBg: const Color(0xFFF0E9FF),
                          title: "Two-Factor Auth",
                          subtitle: null,
                          onTap: () {},
                        ),
                        _divider(),
                        _settingsItem(
                          icon: Icons.emergency_rounded,
                          iconColor: const Color(0xFFFF6D6D),
                          iconBg: const Color(0xFFFFEFEF),
                          title: "Emergency Contacts",
                          subtitle: "3 contacts configured",
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle("PREFERENCES"),

                    const SizedBox(height: 10),

                    _settingsCard(
                      children: [
                        _settingsItem(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF9B75F0),
                          iconBg: const Color(0xFFF0E9FF),
                          title: "Language",
                          subtitle: null,
                          trailingText: "English (US)",
                          onTap: () {},
                        ),
                        _divider(),
                        _switchItem(
                          icon: Icons.notifications_rounded,
                          iconColor: const Color(0xFF9B75F0),
                          iconBg: const Color(0xFFF0E9FF),
                          title: "Notifications",
                          subtitle: "Alerts & updates",
                          value: notificationsOn,
                          onChanged: (value) {
                            setState(() {
                              notificationsOn = value;
                            });
                          },
                        ),
                        _divider(),
                        _switchItem(
                          icon: Icons.location_pin,
                          iconColor: const Color(0xFF9B75F0),
                          iconBg: const Color(0xFFF0E9FF),
                          title: "Live Tracking",
                          subtitle: "Share location with trusted",
                          value: liveTrackingOn,
                          onChanged: (value) {
                            setState(() {
                              liveTrackingOn = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _settingsCard(
                      children: [
                        _settingsItem(
                          icon: Icons.help_rounded,
                          iconColor: const Color(0xFF6E6878),
                          iconBg: const Color(0xFFEFF0F4),
                          title: "Help & Support",
                          subtitle: null,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFF9D95AD),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: subtitle == null ? 62 : 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _iconBox(
              icon: icon,
              iconColor: iconColor,
              iconBg: iconBg,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4A4358),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                       color: Colors.black.withOpacity(0.35),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: GoogleFonts.poppins(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFD1CBDD),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _iconBox(
            icon: icon,
            iconColor: iconColor,
            iconBg: iconBg,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A4358),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                   color: Colors.black.withOpacity(0.35),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF9B75F0),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE4DDEE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 19,
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black45,
          size: 16,
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 65),
      child: Container(
        height: 1,
        color: const Color(0xFFF0ECF7),
      ),
    );
  }
}