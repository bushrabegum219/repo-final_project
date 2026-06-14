import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:amaan_app/services/notification_service.dart';

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  String _selectedRepeatType = "Daily";
  String _selectedFilter = "Today";

  final List<String> _repeatTypes = ["Once", "Daily", "Weekly"];
  final List<String> _filters = ["Today", "Upcoming", "Completed"];

  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadReminders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _dateToSupabase(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  String _timeToSupabase(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute:00";
  }

  DateTime _parseReminderDate(Map<String, dynamic> reminder) {
    final rawDate = reminder['reminder_date']?.toString();

    if (rawDate == null || rawDate.isEmpty) {
      return DateTime.now();
    }

    return DateTime.parse(rawDate);
  }

  TimeOfDay _parseReminderTime(Map<String, dynamic> reminder) {
    final rawTime = reminder['reminder_time']?.toString() ?? "09:00:00";
    final parts = rawTime.split(":");

    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _notificationId(dynamic id) {
    return id.toString().hashCode & 0x7fffffff;
  }

  Future<void> _scheduleReminderNotification(
    Map<String, dynamic> reminder,
  ) async {
    final id = reminder['id'];

    if (id == null) return;
    if (reminder['is_enabled'] != true) return;
    if (reminder['is_completed'] == true) return;

    final date = _parseReminderDate(reminder);
    final time = _parseReminderTime(reminder);

    await NotificationService.scheduleReminder(
      id: _notificationId(id),
      title: reminder['title']?.toString() ?? "Daily Reminder",
      body: reminder['description']?.toString() ?? "Stay safe and protected.",
      date: date,
      hour: time.hour,
      minute: time.minute,
      repeatType: reminder['repeat_type']?.toString() ?? "Daily",
    );
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

  Future<void> _loadReminders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _reminders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await _supabase
          .from('daily_reminders')
          .select()
          .eq('user_id', user.id)
          .order('reminder_date', ascending: true)
          .order('reminder_time', ascending: true);

      setState(() {
        _reminders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("DAILY REMINDER LOAD ERROR: $e");
      setState(() {
        _isLoading = false;
      });
      _showMessage("Failed to load reminders");
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  Future<void> _addReminder() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first");
      return;
    }

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty) {
      _showMessage("Please enter reminder title");
      return;
    }

    if (_selectedTime == null) {
      _showMessage("Please select reminder time");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final insertedData = await _supabase
          .from('daily_reminders')
          .insert({
            'user_id': user.id,
            'title': title,
            'description':
                message.isEmpty ? 'Stay safe and protected.' : message,
            'reminder_date': _dateToSupabase(_selectedDate),
            'reminder_time': _timeToSupabase(_selectedTime!),
            'repeat_type': _selectedRepeatType,
            'is_enabled': true,
            'is_completed': false,
          })
          .select()
          .single();

      await _scheduleReminderNotification(
        Map<String, dynamic>.from(insertedData),
      );

      _titleController.clear();
      _messageController.clear();

      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = null;
        _selectedRepeatType = "Daily";
      });

      await _loadReminders();

      _showMessage("Reminder saved");
    } catch (e) {
      debugPrint("DAILY REMINDER SAVE ERROR: $e");
      _showMessage("Failed to save reminder");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteReminder(Map<String, dynamic> reminder) async {
    final id = reminder['id'];

    if (id == null) {
      _showMessage("Reminder id not found");
      return;
    }

    try {
      await NotificationService.cancelReminder(_notificationId(id));

      await _supabase.from('daily_reminders').delete().eq('id', id);

      await _loadReminders();

      _showMessage("Reminder deleted");
    } catch (e) {
      debugPrint("DAILY REMINDER DELETE ERROR: $e");
      _showMessage("Failed to delete reminder");
    }
  }

  Future<void> _toggleEnabled(Map<String, dynamic> reminder) async {
    final id = reminder['id'];
    final currentValue = reminder['is_enabled'] == true;

    if (id == null) {
      _showMessage("Reminder id not found");
      return;
    }

    try {
      await _supabase.from('daily_reminders').update({
        'is_enabled': !currentValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await NotificationService.cancelReminder(_notificationId(id));

      if (!currentValue) {
        final updatedReminder = Map<String, dynamic>.from(reminder);
        updatedReminder['is_enabled'] = true;
        await _scheduleReminderNotification(updatedReminder);
      }

      await _loadReminders();

      _showMessage(!currentValue ? "Reminder enabled" : "Reminder disabled");
    } catch (e) {
      debugPrint("DAILY REMINDER ENABLE ERROR: $e");
      _showMessage("Failed to update reminder");
    }
  }

  Future<void> _toggleCompleted(Map<String, dynamic> reminder) async {
    final id = reminder['id'];
    final currentValue = reminder['is_completed'] == true;

    if (id == null) {
      _showMessage("Reminder id not found");
      return;
    }

    try {
      await _supabase.from('daily_reminders').update({
        'is_completed': !currentValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await NotificationService.cancelReminder(_notificationId(id));

      if (currentValue && reminder['is_enabled'] == true) {
        final updatedReminder = Map<String, dynamic>.from(reminder);
        updatedReminder['is_completed'] = false;
        await _scheduleReminderNotification(updatedReminder);
      }

      await _loadReminders();

      _showMessage(!currentValue ? "Marked as completed" : "Marked as active");
    } catch (e) {
      debugPrint("DAILY REMINDER COMPLETE ERROR: $e");
      _showMessage("Failed to update reminder");
    }
  }

  Future<void> _updateReminder({
    required Map<String, dynamic> oldReminder,
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required String repeatType,
  }) async {
    final id = oldReminder['id'];

    if (id == null) {
      _showMessage("Reminder id not found");
      return;
    }

    try {
      await _supabase.from('daily_reminders').update({
        'title': title,
        'description': description,
        'reminder_date': _dateToSupabase(date),
        'reminder_time': _timeToSupabase(time),
        'repeat_type': repeatType,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      await NotificationService.cancelReminder(_notificationId(id));

      final updatedReminder = Map<String, dynamic>.from(oldReminder);
      updatedReminder['title'] = title;
      updatedReminder['description'] = description;
      updatedReminder['reminder_date'] = _dateToSupabase(date);
      updatedReminder['reminder_time'] = _timeToSupabase(time);
      updatedReminder['repeat_type'] = repeatType;

      await _scheduleReminderNotification(updatedReminder);

      await _loadReminders();

      _showMessage("Reminder updated");
    } catch (e) {
      debugPrint("DAILY REMINDER UPDATE ERROR: $e");
      _showMessage("Failed to update reminder");
    }
  }
int _activeReminderCount() {
  return _reminders
      .where(
        (reminder) =>
            reminder['is_enabled'] == true &&
            reminder['is_completed'] != true,
      )
      .length;
}
 List<Map<String, dynamic>> _filteredReminders() {
  final now = DateTime.now();

  if (_selectedFilter == "Completed") {
    return _reminders
        .where((reminder) => reminder['is_completed'] == true)
        .toList();
  }

  if (_selectedFilter == "Upcoming") {
    return _reminders.where((reminder) {
      if (reminder['is_completed'] == true) return false;

      final date = _parseReminderDate(reminder);
      final time = _parseReminderTime(reminder);

      final reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      return reminderDateTime.isAfter(now);
    }).toList();
  }

  return _reminders.where((reminder) {
    final date = _parseReminderDate(reminder);
    return _isSameDate(date, now) && reminder['is_completed'] != true;
  }).toList();
}

  void _openEditReminderSheet(Map<String, dynamic> reminder) {
    final editTitleController = TextEditingController(
      text: reminder['title']?.toString() ?? "",
    );
    final editDescriptionController = TextEditingController(
      text: reminder['description']?.toString() ?? "",
    );

    DateTime editDate = _parseReminderDate(reminder);
    TimeOfDay editTime = _parseReminderTime(reminder);
    String editRepeatType = reminder['repeat_type']?.toString() ?? "Daily";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFDF2F7),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit Reminder",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1632),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: editTitleController,
                      decoration: _inputDecoration("Reminder title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editDescriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration("Message"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _smallPickerButton(
                            icon: Icons.calendar_month,
                            text: _formatDate(editDate),
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: editDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 1)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );

                              if (pickedDate != null) {
                                setModalState(() {
                                  editDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _smallPickerButton(
                            icon: Icons.access_time,
                            text: _formatTime(editTime),
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: editTime,
                              );

                              if (pickedTime != null) {
                                setModalState(() {
                                  editTime = pickedTime;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editRepeatType,
                      decoration: _inputDecoration("Repeat type"),
                      items: _repeatTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          editRepeatType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = editTitleController.text.trim();
                          final description =
                              editDescriptionController.text.trim();

                          if (title.isEmpty) {
                            _showMessage("Please enter title");
                            return;
                          }

                          Navigator.pop(bottomSheetContext);

                          await _updateReminder(
                            oldReminder: reminder,
                            title: title,
                            description: description.isEmpty
                                ? "Stay safe and protected."
                                : description,
                            date: editDate,
                            time: editTime,
                            repeatType: editRepeatType,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text("Update Reminder"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      editTitleController.dispose();
      editDescriptionController.dispose();
    });
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _smallPickerButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE91E63), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A1632),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE91E63), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A1632),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard(Map<String, dynamic> reminder) {
    final date = _parseReminderDate(reminder);
    final time = _parseReminderTime(reminder);

    final isEnabled = reminder['is_enabled'] == true;
    final isCompleted = reminder['is_completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleCompleted(reminder),
            borderRadius: BorderRadius.circular(100),
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
                  isCompleted ? const Color(0xFFE91E63) : Colors.grey.shade200,
              child: Icon(
                isCompleted ? Icons.check : Icons.notifications_active,
                color: isCompleted ? Colors.white : const Color(0xFFE91E63),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openEditReminderSheet(reminder),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder['title']?.toString() ?? "Daily Reminder",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1632),
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder['description']?.toString() ??
                        "Stay safe and protected.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${_formatDate(date)} • ${_formatTime(time)}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        reminder['repeat_type']?.toString() ?? "Daily",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Switch(
                value: isEnabled,
                activeColor: const Color(0xFFE91E63),
                onChanged: (_) => _toggleEnabled(reminder),
              ),
              IconButton(
                onPressed: () => _deleteReminder(reminder),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReminders = _filteredReminders();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF2F7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4A1632)),
        title: Text(
          "Daily Reminder",
          style: GoogleFonts.poppins(
            color: const Color(0xFF4A1632),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF7AA8),
                            Color(0xFFE91E63),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stay protected every day",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Set reminders for safety checks, dua, journaling, or daily protection habits.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statCard(
                          icon: Icons.notifications_active,
                          title: "Active",
                          value: _activeReminderCount().toString(),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          icon: Icons.done_all,
                          title: "Completed",
                          value: _reminders
                              .where((item) => item['is_completed'] == true)
                              .length
                              .toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE1EC),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Reminder",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A1632),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _titleController,
                            decoration: _inputDecoration(
                              "Title e.g. Check-in with family",
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              "Message e.g. Send location update",
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _smallPickerButton(
                                  icon: Icons.calendar_month,
                                  text: _formatDate(_selectedDate),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _smallPickerButton(
                                  icon: Icons.access_time,
                                  text: _selectedTime == null
                                      ? "Select time"
                                      : _formatTime(_selectedTime!),
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRepeatType,
                            decoration: _inputDecoration("Repeat type"),
                            items: _repeatTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedRepeatType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _addReminder,
                              icon: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_alert),
                              label: Text(
                                _isSaving ? "Saving..." : "Save Reminder",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Saved Reminders",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1632),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _filters.map((filter) {
                        final selected = _selectedFilter == filter;

                        return ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          selectedColor: const Color(0xFFE91E63),
                          labelStyle: GoogleFonts.poppins(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    if (filteredReminders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.notifications_none,
                              size: 44,
                              color: Color(0xFFE91E63),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "No reminders found",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A1632),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredReminders.map(_reminderCard),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Safety Tip",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A1632),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Share your location with a trusted person before travelling alone at night.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
}