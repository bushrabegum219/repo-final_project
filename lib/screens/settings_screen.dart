import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amaan_app/constants/app_theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

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

    final updatedDefaultSosMessage =
        newDefaultSosMessage ?? defaultSosMessage;
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

  void _openEditProfileSheet() {
    final nameController = TextEditingController(text: fullName);
    final phoneController = TextEditingController(text: phoneNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _bottomSheetContainer(
          sheetContext: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle("Edit Profile"),
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
  }

  void _openSosMessageSheet() {
    final messageController = TextEditingController(text: defaultSosMessage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _bottomSheetContainer(
          sheetContext: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              _sheetTitle("Default SOS Message"),
              const SizedBox(height: 18),
              Container(
                constraints: const BoxConstraints(minHeight: 130),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Write your default SOS message",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Logout?"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Color(0xFFFF6D6D)),
              ),
            ),
          ],
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
      backgroundColor:
    darkModeOn ? const Color(0xFF121212) : const Color(0xFFF8F6FB),
      body: SafeArea(
        child: Column(
          children: [
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
                          color: darkModeOn ? Colors.white : const Color(0xFF2F2940),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
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
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xCCFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF9B75F0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9B75F0),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _settingsCard(
                            children: [
                              ListTile(
                                onTap: _openEditProfileSheet,
                                leading: Container(
                                  height: 46,
                                  width: 46,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8DFFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF8E6AE8),
                                  ),
                                ),
                                title: Text(
                                  displayName,
                                  style: GoogleFonts.poppins(
                                    color: darkModeOn ? Colors.white : const Color(0xFF2F2940),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  displayPhone,
                                  style: GoogleFonts.poppins(
                                    color: darkModeOn ? Colors.white70 : Colors.black45,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF9B75F0),
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle("ACCOUNT & SECURITY"),
                          const SizedBox(height: 10),
                          _settingsCard(
                            children: [
                             
                              
                              _settingsItem(
                                icon: Icons.logout_rounded,
                                iconColor: const Color(0xFFFF6D6D),
                                iconBg: const Color(0xFFFFEFEF),
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
                                iconColor: const Color(0xFF9B75F0),
                                iconBg: const Color(0xFFF0E9FF),
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
                                iconColor: const Color(0xFF9B75F0),
                                iconBg: const Color(0xFFF0E9FF),
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
                                iconColor: const Color(0xFFFF6D6D),
                                iconBg: const Color(0xFFFFEFEF),
                                title: "Default SOS Message",
                                subtitle: defaultSosMessage,
                                onTap: _openSosMessageSheet,
                              ),
                              _divider(),
                              _switchItem(
                                icon: Icons.my_location_rounded,
                                iconColor: const Color(0xFFFF6D6D),
                                iconBg: const Color(0xFFFFEFEF),
                                title: "Auto Share Location in SOS",
                                subtitle: "Attach location during SOS alerts",
                                value: autoShareLocationOn,
                                onChanged: (value) {
                                  _saveSettings(
                                    newAutoShareLocationOn: value,
                                  );
                                },
                              ),
                              _divider(),
                             
                              
                            ],
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle("SUPPORT"),
                          const SizedBox(height: 10),
                          _settingsCard(
                            children: [
                              _settingsItem(
                                icon: Icons.help_rounded,
                                iconColor: const Color(0xFF6E6878),
                                iconBg: const Color(0xFFEFF0F4),
                                title: "Help & Support",
                                subtitle: null,
                                onTap: _showHelpMessage,
                              ),
                              _divider(),
                              _settingsItem(
                                icon: Icons.info_rounded,
                                iconColor: const Color(0xFF6E6878),
                                iconBg: const Color(0xFFEFF0F4),
                                title: "About App",
                                subtitle: "Amaan Women Safety App",
                                onTap: _showAboutMessage,
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

  Widget _bottomSheetContainer({
    required BuildContext sheetContext,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
      ),
      decoration:  BoxDecoration(
        color: darkModeOn ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(child: child),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF9B75F0),
            size: 20,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.black26,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 15),
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
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF9B75F0),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      height: 5,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _sheetTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: darkModeOn ? Colors.white : const Color(0xFF2F2940),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
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
        color: darkModeOn ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
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
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      color: darkModeOn ? Colors.white : const Color(0xFF4A4358),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: darkModeOn ? Colors.white70 : Colors.black45,
                        fontSize: 10.5,
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
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
                    color: darkModeOn ? Colors.white : const Color(0xFF4A4358),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: darkModeOn ? Colors.white70 : Colors.black45,
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
              activeThumbColor: Colors.white,
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
          color: darkModeOn ? Colors.white70 : Colors.black45,
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
        color: darkModeOn ? const Color(0xFF333333) : const Color(0xFFF0ECF7),
      ),
    );
  }
}