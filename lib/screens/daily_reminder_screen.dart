import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('daily_reminders');

    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        _reminders = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_reminders', jsonEncode(_reminders));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addReminder() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter title and select time"),
        ),
      );
      return;
    }

    final reminder = {
      'title': title,
      'message': message.isEmpty ? 'Stay safe and protected.' : message,
      'hour': _selectedTime!.hour,
      'minute': _selectedTime!.minute,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _reminders.add(reminder);
      _titleController.clear();
      _messageController.clear();
      _selectedTime = null;
    });

    await _saveReminders();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reminder saved successfully"),
      ),
    );
  }

  Future<void> _deleteReminder(int index) async {
    setState(() {
      _reminders.removeAt(index);
    });

    await _saveReminders();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reminder deleted"),
      ),
    );
  }

  String _formatReminderTime(Map<String, dynamic> reminder) {
    final time = TimeOfDay(
      hour: reminder['hour'],
      minute: reminder['minute'],
    );

    return time.format(context);
  }

  String _selectedTimeText() {
    if (_selectedTime == null) return "Choose time";
    return _selectedTime!.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _smallIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "You have ${_reminders.length} saved reminders",
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 34,
                    width: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=300&auto=format&fit=crop",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// TITLE
              Text(
                "Daily",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF2D2438),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Protection",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF9C8BC9),
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Your spiritual and physical safety shield.",
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              /// SET TIMER CARD
              _setTimerCard(),

              const SizedBox(height: 16),

              /// SAVED REMINDERS
              _savedRemindersCard(),

              const SizedBox(height: 16),

              /// DAILY DUA CARD
              _infoCard(
                iconBg: const Color(0xFFEDE7FF),
                iconColor: const Color(0xFFA58BEA),
                icon: Icons.auto_awesome_rounded,
                title: "DAILY DUA",
                trailing: const SizedBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "\"Hasbunallahu wa ni'mal wakeel\"",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF3A2F45),
                        fontSize: 17,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sufficient for us is Allah, and [He is] the best Disposer of affairs.",
                      style: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 10.8,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// SAFETY TIP CARD
              _infoCard(
                iconBg: const Color(0xFFFFF1D9),
                iconColor: const Color(0xFFFFB648),
                icon: Icons.lightbulb_rounded,
                title: "SAFETY TIP",
                trailing: const Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: Colors.black26,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stay Visible",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF30273B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Keep your phone charged and visible when walking alone at night.",
                            style: GoogleFonts.poppins(
                              color: Colors.black38,
                              fontSize: 10.8,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: Color(0xFFA48ADF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /// STREAK HEADER
              Text(
                "Streak Level",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF3A2F45),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              /// STREAK CARD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _streakItem(
                      icon: Icons.home_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.grid_view_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _centerStreakItem(),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.favorite_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.person_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// COMPLETE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCCFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF7E63D2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reminders.isEmpty
                            ? "Set a daily reminder to complete your protection routine."
                            : "You have ${_reminders.length} active protection reminder(s).",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF433453),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setTimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  size: 16,
                  color: Color(0xFF8E7CFF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "SET DAILY TIMER",
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "Reminder title",
              prefixIcon: const Icon(Icons.edit_note_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F5FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: "Reminder message",
              prefixIcon: const Icon(Icons.message_outlined),
              filled: true,
              fillColor: const Color(0xFFF8F5FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF8E7CFF),
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTimeText(),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF433453),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E7CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savedRemindersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Saved Reminders",
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF3A2F45),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_reminders.isEmpty)
            Text(
              "No reminders yet. Add your first daily safety timer.",
              style: GoogleFonts.poppins(
                color: Colors.black45,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Column(
              children: List.generate(_reminders.length, (index) {
                final reminder = _reminders[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCCFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF7E63D2),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder['title'],
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF30273B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${_formatReminderTime(reminder)} • ${reminder['message']}",
                              style: GoogleFonts.poppins(
                                color: Colors.black45,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteReminder(index),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
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
        height: 36,
        width: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _infoCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required Widget trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _streakItem({
    required IconData icon,
    required Color bg,
    required bool selected,
  }) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected ? const Color(0xFF8D73D8) : Colors.black38,
      ),
    );
  }

  Widget _centerStreakItem() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_moon_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}