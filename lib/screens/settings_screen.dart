import 'dart:ui';

import 'package:amaan_app/constants/app_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Color _blueDeep = Color(0xFF102A43);
  static const Color _blueMain = Color(0xFF2563EB);
  static const Color _blueSoft = Color(0xFF38BDF8);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFF6366F1);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);

  bool _isLoading = true;
  bool _isSaving = false;

  String fullName = "";
  String phoneNumber = "";
  String language = "English (US)";

  bool notificationsOn = true;
  bool twoFactorOn = false;
  bool appLockOn = false;
  bool darkModeOn = false;
  bool soundVibrationOn = true;

  String defaultSosMessage =
      "Emergency! I need help. Please contact me as soon as possible.";
  bool autoShareLocationOn = true;
  int sosCountdownSeconds = 5;
  int fakeCallDelaySeconds = 10;

  Color get _textMain => darkModeOn ? Colors.white : _blueDeep;
  Color get _textMuted =>
      darkModeOn ? Colors.white.withValues(alpha: 0.68) : const Color(0xFF61748A);
  Color get _glassLight =>
      darkModeOn ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.54);
  Color get _glassStrong =>
      darkModeOn ? Colors.white.withValues(alpha: 0.11) : Colors.white.withValues(alpha: 0.74);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showMessage("Please login first");
      return;
    }

    try {
      final data = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        await _createDefaultSettings();
        return;
      }

      setState(() {
        fullName = data['full_name']?.toString() ?? "";
        phoneNumber = data['phone_number']?.toString() ?? "";
        language = data['language']?.toString() ?? "English (US)";

        notificationsOn = data['notifications_on'] == true;
        twoFactorOn = data['two_factor_on'] == true;
        appLockOn = data['app_lock_on'] == true;
        darkModeOn = data['dark_mode_on'] == true;
        AppThemeController.isDarkMode.value = darkModeOn;
        soundVibrationOn = data['sound_vibration_on'] == true;

        defaultSosMessage = data['default_sos_message']?.toString() ??
            "Emergency! I need help. Please contact me as soon as possible.";
        autoShareLocationOn = data['auto_share_location_on'] == true;
        sosCountdownSeconds = data['sos_countdown_seconds'] is int
            ? data['sos_countdown_seconds'] as int
            : 5;
        fakeCallDelaySeconds = data['fake_call_delay_seconds'] is int
            ? data['fake_call_delay_seconds'] as int
            : 10;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("SETTINGS LOAD ERROR: $e");

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showMessage("Failed to load settings");
    }
  }

  Future<void> _createDefaultSettings() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _supabase.from('user_settings').insert({
        'user_id': user.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'language': language,
        'notifications_on': notificationsOn,
        'two_factor_on': twoFactorOn,
        'app_lock_on': appLockOn,
        'dark_mode_on': darkModeOn,
        'sound_vibration_on': soundVibrationOn,
        'default_sos_message': defaultSosMessage,
        'auto_share_location_on': autoShareLocationOn,
        'sos_countdown_seconds': sosCountdownSeconds,
        'fake_call_delay_seconds': fakeCallDelaySeconds,
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("DEFAULT SETTINGS CREATE ERROR: $e");

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showMessage("Failed to create settings");
    }
  }

  Future<void> _saveSettings({
    String? newFullName,
    String? newPhoneNumber,
    String? newLanguage,
    bool? newNotificationsOn,
    bool? newTwoFactorOn,
    bool? newAppLockOn,
    bool? newDarkModeOn,
    bool? newSoundVibrationOn,
    String? newDefaultSosMessage,
    bool? newAutoShareLocationOn,
    int? newSosCountdownSeconds,
    int? newFakeCallDelaySeconds,
    bool showMessage = true,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedFullName = newFullName ?? fullName;
    final updatedPhoneNumber = newPhoneNumber ?? phoneNumber;
    final updatedLanguage = newLanguage ?? language;

    final updatedNotificationsOn = newNotificationsOn ?? notificationsOn;
    final updatedTwoFactorOn = newTwoFactorOn ?? twoFactorOn;
    final updatedAppLockOn = newAppLockOn ?? appLockOn;
    final updatedDarkModeOn = newDarkModeOn ?? darkModeOn;
    final updatedSoundVibrationOn = newSoundVibrationOn ?? soundVibrationOn;

    final updatedDefaultSosMessage = newDefaultSosMessage ?? defaultSosMessage;
    final updatedAutoShareLocationOn =
        newAutoShareLocationOn ?? autoShareLocationOn;
    final updatedSosCountdownSeconds =
        newSosCountdownSeconds ?? sosCountdownSeconds;
    final updatedFakeCallDelaySeconds =
        newFakeCallDelaySeconds ?? fakeCallDelaySeconds;

    try {
      await _supabase.from('user_settings').upsert({
        'user_id': user.id,
        'full_name': updatedFullName,
        'phone_number': updatedPhoneNumber,
        'language': updatedLanguage,
        'notifications_on': updatedNotificationsOn,
        'two_factor_on': updatedTwoFactorOn,
        'app_lock_on': updatedAppLockOn,
        'dark_mode_on': updatedDarkModeOn,
        'sound_vibration_on': updatedSoundVibrationOn,
        'default_sos_message': updatedDefaultSosMessage,
        'auto_share_location_on': updatedAutoShareLocationOn,
        'sos_countdown_seconds': updatedSosCountdownSeconds,
        'fake_call_delay_seconds': updatedFakeCallDelaySeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (!mounted) return;

      setState(() {
        fullName = updatedFullName;
        phoneNumber = updatedPhoneNumber;
        language = updatedLanguage;

        notificationsOn = updatedNotificationsOn;
        twoFactorOn = updatedTwoFactorOn;
        appLockOn = updatedAppLockOn;
        darkModeOn = updatedDarkModeOn;
        soundVibrationOn = updatedSoundVibrationOn;

        defaultSosMessage = updatedDefaultSosMessage;
        autoShareLocationOn = updatedAutoShareLocationOn;
        sosCountdownSeconds = updatedSosCountdownSeconds;
        fakeCallDelaySeconds = updatedFakeCallDelaySeconds;

        _isSaving = false;
      });

      if (showMessage) {
        _showMessage("Settings saved");
      }
    } catch (e) {
      debugPrint("SETTINGS SAVE ERROR: $e");

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      _showMessage("Failed to save settings");
    }
  }

  Future<void> _openEditProfileSheet() async {
    final nameController = TextEditingController(text: fullName);
    final phoneController = TextEditingController(text: phoneNumber);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        return _bottomSheetContainer(
          sheetContext: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  _premiumIcon(
                    icon: Icons.person_rounded,
                    color: _blueMain,
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetTitle("Edit Profile"),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: nameController,
                hint: "Full name",
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: phoneController,
                hint: "Phone number",
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              _saveButton(
                text: "Save Profile",
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _saveSettings(
                    newFullName: nameController.text.trim(),
                    newPhoneNumber: phoneController.text.trim(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _openSosMessageSheet() async {
    final messageController = TextEditingController(text: defaultSosMessage);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        return _bottomSheetContainer(
          sheetContext: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  _premiumIcon(
                    icon: Icons.sms_rounded,
                    color: _danger,
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetTitle("Default SOS Message"),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: messageController,
                maxLines: 5,
                style: GoogleFonts.poppins(
                  color: _textMain,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  hint: "Write your default SOS message",
                  icon: Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 18),
              _saveButton(
                text: "Save Message",
                onTap: () async {
                  final message = messageController.text.trim();

                  if (message.isEmpty) {
                    _showMessage("Message cannot be empty");
                    return;
                  }

                  Navigator.pop(sheetContext);
                  await _saveSettings(newDefaultSosMessage: message);
                },
              ),
            ],
          ),
        );
      },
    );

    messageController.dispose();
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      _showMessage("Logged out successfully");
      Navigator.pop(context);
    } catch (e) {
      debugPrint("LOGOUT ERROR: $e");
      _showMessage("Failed to logout");
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: darkModeOn
                        ? [
                            const Color(0xFF0F172A).withValues(alpha: 0.92),
                            const Color(0xFF1E293B).withValues(alpha: 0.80),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.92),
                            const Color(0xFFEAF5FF).withValues(alpha: 0.80),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: darkModeOn ? 0.12 : 0.82),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _premiumIcon(
                      icon: Icons.logout_rounded,
                      color: _danger,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Logout?",
                      style: GoogleFonts.poppins(
                        color: _textMain,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Are you sure you want to sign out from this account?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _textMuted,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _glassStrong,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: darkModeOn ? 0.10 : 0.75,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.poppins(
                                    color: _textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _logout();
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _danger,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _danger.withValues(alpha: 0.24),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Logout",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHelpMessage() {
    _showMessage("Help & Support will be added later");
  }

  void _showAboutMessage() {
    _showMessage("Amaan Women Safety App - Version 1.0");
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = fullName.trim().isEmpty ? "Amaan User" : fullName;
    final displayPhone =
        phoneNumber.trim().isEmpty ? "No phone added" : phoneNumber;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: darkModeOn ? const Color(0xFF020617) : const Color(0xFFEAF5FF),
      body: Stack(
        children: [
          _background(),
          Positioned(
            top: -90,
            right: -80,
            child: _glowBlob(
              color: _blueSoft,
              size: 280,
              opacity: darkModeOn ? 0.20 : 0.24,
            ),
          ),
          Positioned(
            top: 260,
            left: -120,
            child: _glowBlob(
              color: _violet,
              size: 280,
              opacity: darkModeOn ? 0.15 : 0.13,
            ),
          ),
          Positioned(
            bottom: -90,
            right: -80,
            child: _glowBlob(
              color: _cyan,
              size: 260,
              opacity: darkModeOn ? 0.16 : 0.16,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _topPill(),
                      const SizedBox(width: 10),
                      _savingAvatar(),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: darkModeOn ? _blueSoft : _blueMain,
                            strokeWidth: 2.6,
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Settings",
                                style: GoogleFonts.poppins(
                                  color: _textMain,
                                  fontSize: 40,
                                  height: 0.95,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Control your safety preferences, profile, and emergency setup.",
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _profileHero(
                                displayName: displayName,
                                displayPhone: displayPhone,
                              ),
                              const SizedBox(height: 16),
                              _quickStatusStrip(),
                              const SizedBox(height: 24),
                              _sectionTitle("ACCOUNT & SECURITY"),
                              const SizedBox(height: 10),
                              _settingsCard(
                                children: [
                                  _settingsItem(
                                    icon: Icons.logout_rounded,
                                    iconColor: _danger,
                                    title: "Logout",
                                    subtitle: "Sign out from this account",
                                    onTap: _confirmLogout,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              _sectionTitle("APP PREFERENCES"),
                              const SizedBox(height: 10),
                              _settingsCard(
                                children: [
                                  _switchItem(
                                    icon: Icons.dark_mode_rounded,
                                    iconColor: _violet,
                                    title: "Theme / Dark Mode",
                                    subtitle: "Save dark mode preference",
                                    value: darkModeOn,
                                    onChanged: (value) {
                                      AppThemeController.isDarkMode.value = value;
                                      _saveSettings(newDarkModeOn: value);
                                    },
                                  ),
                                  _divider(),
                                  _switchItem(
                                    icon: Icons.vibration_rounded,
                                    iconColor: _blueMain,
                                    title: "Sound & Vibration",
                                    subtitle: "SOS sound and vibration preference",
                                    value: soundVibrationOn,
                                    onChanged: (value) {
                                      _saveSettings(newSoundVibrationOn: value);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              _sectionTitle("SAFETY PREFERENCES"),
                              const SizedBox(height: 10),
                              _settingsCard(
                                children: [
                                  _settingsItem(
                                    icon: Icons.sms_rounded,
                                    iconColor: _danger,
                                    title: "Default SOS Message",
                                    subtitle: defaultSosMessage,
                                    onTap: _openSosMessageSheet,
                                  ),
                                  _divider(),
                                  _switchItem(
                                    icon: Icons.my_location_rounded,
                                    iconColor: _success,
                                    title: "Auto Share Location in SOS",
                                    subtitle: "Attach location during SOS alerts",
                                    value: autoShareLocationOn,
                                    onChanged: (value) {
                                      _saveSettings(
                                        newAutoShareLocationOn: value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              _sectionTitle("SUPPORT"),
                              const SizedBox(height: 10),
                              _settingsCard(
                                children: [
                                  _settingsItem(
                                    icon: Icons.help_rounded,
                                    iconColor: _blueMain,
                                    title: "Help & Support",
                                    subtitle: "Get assistance and guidance",
                                    onTap: _showHelpMessage,
                                  ),
                                  _divider(),
                                  _settingsItem(
                                    icon: Icons.info_rounded,
                                    iconColor: _cyan,
                                    title: "About App",
                                    subtitle: "Amaan Women Safety App",
                                    onTap: _showAboutMessage,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _versionCard(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: darkModeOn
              ? const [
                  Color(0xFF020617),
                  Color(0xFF0F172A),
                  Color(0xFF111827),
                ]
              : const [
                  Color(0xFFEAF5FF),
                  Color(0xFFE0F2FE),
                  Color(0xFFF4F7FF),
                ],
        ),
      ),
    );
  }

  Widget _profileHero({
    required String displayName,
    required String displayPhone,
  }) {
    return _glassCard(
      radius: 30,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _blueMain,
                  _blueSoft,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _blueMain.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initialFromName(displayName),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: _openEditProfileSheet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPhone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _blueMain.withValues(alpha: darkModeOn ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _blueMain.withValues(alpha: darkModeOn ? 0.28 : 0.16),
                      ),
                    ),
                    child: Text(
                      "Tap to edit profile",
                      style: GoogleFonts.poppins(
                        color: darkModeOn ? _blueSoft : _blueMain,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _smallCircleAction(
            icon: Icons.edit_rounded,
            color: _blueMain,
            onTap: _openEditProfileSheet,
          ),
        ],
      ),
    );
  }

  Widget _quickStatusStrip() {
  return Row(
    children: [
      Expanded(
        child: _miniStatusCard(
          icon: Icons.notifications_active_rounded,
          label: "Alerts",
          value: notificationsOn ? "On" : "Off",
          color: _blueMain,
          onTap: () {
            _saveSettings(
              newNotificationsOn: !notificationsOn,
            );
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _miniStatusCard(
          icon: Icons.location_on_rounded,
          label: "Location",
          value: autoShareLocationOn ? "Auto" : "Manual",
          color: _success,
          onTap: () {
            _saveSettings(
              newAutoShareLocationOn: !autoShareLocationOn,
            );
          },
        ),
      ),
    ],
  );
}

  Widget _miniStatusCard({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: _glassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: darkModeOn ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.touch_app_rounded,
            color: color.withValues(alpha: 0.70),
            size: 17,
          ),
        ],
      ),
    ),
  );
}
  Widget _versionCard() {
    return _glassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _premiumIcon(
            icon: Icons.shield_moon_rounded,
            color: _cyan,
            size: 46,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Amaan Safety",
                  style: GoogleFonts.poppins(
                    color: _textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Version 1.0 • Premium safety controls",
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: _glassLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: Colors.white.withValues(alpha: darkModeOn ? 0.12 : 0.72),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: darkModeOn ? _blueSoft : _blueMain,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                "Settings",
                style: GoogleFonts.poppins(
                  color: _textMain,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savingAvatar() {
    return Stack(
      children: [
        _circleButton(
          icon: Icons.person_rounded,
          onTap: _openEditProfileSheet,
        ),
        if (_isSaving)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _blueMain,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bottomSheetContainer({
    required BuildContext sheetContext,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: darkModeOn
                  ? [
                      const Color(0xFF0F172A).withValues(alpha: 0.94),
                      const Color(0xFF1E293B).withValues(alpha: 0.86),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFEAF5FF).withValues(alpha: 0.86),
                      const Color(0xFFDDF6FF).withValues(alpha: 0.72),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: darkModeOn ? 0.12 : 0.86),
                width: 1.4,
              ),
            ),
          ),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        color: _textMain,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: darkModeOn ? _blueSoft : _blueMain,
        size: 20,
      ),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: _textMuted.withValues(alpha: 0.65),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _glassStrong,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: darkModeOn ? 0.10 : 0.78),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: darkModeOn ? _blueSoft : _blueMain,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _saveButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _blueMain,
              _blueSoft,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _blueMain.withValues(alpha: 0.26),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        height: 5,
        width: 46,
        decoration: BoxDecoration(
          color: _textMuted.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _sheetTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: _textMain,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: _textMuted.withValues(alpha: 0.92),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return _glassCard(
      radius: 26,
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _premiumIcon(
                icon: icon,
                color: iconColor,
                size: 44,
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
                        color: _textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _textMuted,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Flexible(
                  child: Text(
                    trailingText,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _textMuted.withValues(alpha: 0.45),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
  constraints: const BoxConstraints(minHeight: 74),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _premiumIcon(
            icon: icon,
            color: iconColor,
            size: 44,
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
                    color: _textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.86,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: darkModeOn ? _blueSoft : _blueMain,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _textMuted.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: darkModeOn
                  ? [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.045),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.36),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: darkModeOn ? 0.11 : 0.76),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: darkModeOn ? 0.18 : 0.055),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
              if (!darkModeOn)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.52),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _premiumIcon({
    required IconData icon,
    required Color color,
    double size = 42,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: darkModeOn ? 0.22 : 0.15),
            Colors.white.withValues(alpha: darkModeOn ? 0.06 : 0.72),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: darkModeOn ? 0.10 : 0.80),
          width: 1.1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.46,
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _glassLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: darkModeOn ? 0.10 : 0.76),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: darkModeOn ? 0.16 : 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: _textMain,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallCircleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: darkModeOn ? 0.20 : 0.12),
          border: Border.all(
            color: color.withValues(alpha: darkModeOn ? 0.24 : 0.16),
          ),
        ),
        child: Icon(
          icon,
          color: darkModeOn ? _blueSoft : color,
          size: 20,
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 73),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: darkModeOn ? 0.08 : 0.42),
      ),
    );
  }

  Widget _glowBlob({
    required Color color,
    required double size,
    required double opacity,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 95,
            spreadRadius: 26,
          ),
        ],
      ),
    );
  }

  String _initialFromName(String name) {
    final cleanedName = name.trim();

    if (cleanedName.isEmpty || cleanedName == "Amaan User") {
      return "A";
    }

    return cleanedName[0].toUpperCase();
  }
}
