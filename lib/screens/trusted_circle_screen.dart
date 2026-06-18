import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({super.key});

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  static const Color _bgTop = Color(0xFFEAF7F6);
  static const Color _bgBottom = Color(0xFFDDEBFF);
  static const Color _ink = Color(0xFF113238);
  static const Color _muted = Color(0xFF6B838A);
  static const Color _primary = Color(0xFF007A78);
  static const Color _primaryLight = Color(0xFF00B4A6);
  static const Color _blue = Color(0xFF3A86FF);
  static const Color _danger = Color(0xFFEF476F);
  static const Color _gold = Color(0xFFFFB703);

  bool _isLoading = true;
  String _selectedCategory = "All";
  List<TrustedContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage("Please login first");
      return;
    }

    try {
      setState(() => _isLoading = true);

      final data = await _supabase
          .from('trusted_circle')
          .select()
          .eq('user_id', user.id)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      final loadedContacts = (data as List)
          .map(
            (item) => TrustedContact.fromMap(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _contacts = loadedContacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("TRUSTED CONTACT LOAD ERROR: $e");

      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage("Failed to load trusted contacts");
    }
  }

  Future<void> _addContact({
    required String name,
    required String phone,
    required String relationship,
    required String category,
    required bool isPrimary,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first");
      return;
    }

    try {
      if (isPrimary) {
        await _supabase
            .from('trusted_circle')
            .update({'is_primary': false}).eq('user_id', user.id);
      }

      await _supabase.from('trusted_circle').insert({
        'user_id': user.id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'category': category,
        'is_primary': isPrimary,
      });

      _showMessage("Trusted contact added");
      await _loadContacts();
    } catch (e) {
      debugPrint("TRUSTED CONTACT ADD ERROR: $e");
      _showMessage("Failed to add contact");
    }
  }

  Future<void> _updateContact({
    required TrustedContact contact,
    required String name,
    required String phone,
    required String relationship,
    required String category,
    required bool isPrimary,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first");
      return;
    }

    if (contact.id.trim().isEmpty) {
      _showMessage("Contact id not found");
      return;
    }

    try {
      if (isPrimary) {
        await _supabase
            .from('trusted_circle')
            .update({'is_primary': false}).eq('user_id', user.id);
      }

      await _supabase.from('trusted_circle').update({
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'category': category,
        'is_primary': isPrimary,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', contact.id);

      _showMessage("Contact updated");
      await _loadContacts();
    } catch (e) {
      debugPrint("TRUSTED CONTACT UPDATE ERROR: $e");
      _showMessage("Failed to update contact");
    }
  }

  Future<void> _deleteContact(TrustedContact contact) async {
    if (contact.id.trim().isEmpty) {
      _showMessage("Contact id not found");
      return;
    }

    try {
      await _supabase.from('trusted_circle').delete().eq('id', contact.id);

      _showMessage("Contact deleted");
      await _loadContacts();
    } catch (e) {
      debugPrint("TRUSTED CONTACT DELETE ERROR: $e");
      _showMessage("Failed to delete contact");
    }
  }

  Future<void> _setPrimaryContact(TrustedContact contact) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first");
      return;
    }

    if (contact.id.trim().isEmpty) {
      _showMessage("Contact id not found");
      return;
    }

    try {
      await _supabase
          .from('trusted_circle')
          .update({'is_primary': false}).eq('user_id', user.id);

      await _supabase
          .from('trusted_circle')
          .update({'is_primary': true}).eq('id', contact.id);

      _showMessage("${contact.name} set as primary");
      await _loadContacts();
    } catch (e) {
      debugPrint("SET PRIMARY ERROR: $e");
      _showMessage("Failed to set primary contact");
    }
  }

  Future<void> _callContact(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      _showMessage("Phone number is empty");
      return;
    }

    final uri = Uri.parse('tel:$cleanPhone');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage("Could not open phone dialer");
      }
    } catch (e) {
      debugPrint("CALL OPEN ERROR: $e");
      _showMessage("Could not open phone dialer");
    }
  }

  Future<void> _smsContact(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      _showMessage("Phone number is empty");
      return;
    }

    const message =
        'Emergency! I need help. Please contact me as soon as possible.';

    final uri = Uri.parse(
      'sms:$cleanPhone?body=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage("Could not open SMS app");
      }
    } catch (e) {
      debugPrint("SMS OPEN ERROR: $e");
      _showMessage("Could not open SMS app");
    }
  }

  Future<void> _alertAllContacts() async {
    if (_contacts.isEmpty) {
      _showMessage("No trusted contacts added yet");
      return;
    }

    const message =
        'Emergency! I need help. Please contact me as soon as possible.';

    final phoneNumbers = _contacts
        .map((contact) => contact.phone.trim())
        .where((phone) => phone.isNotEmpty)
        .join(';');

    if (phoneNumbers.isEmpty) {
      _showMessage("No phone numbers available");
      return;
    }

    final uri = Uri.parse(
      'sms:$phoneNumbers?body=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage("Could not open SMS app");
      }
    } catch (e) {
      debugPrint("ALERT ALL SMS ERROR: $e");
      _showMessage("Could not open SMS app");
    }
  }

  List<TrustedContact> get _filteredContacts {
    final searchText = _searchController.text.trim().toLowerCase();

    return _contacts.where((contact) {
      final matchesCategory = _selectedCategory == "All" ||
          contact.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSearch = searchText.isEmpty ||
          contact.name.toLowerCase().contains(searchText) ||
          contact.phone.toLowerCase().contains(searchText) ||
          contact.relationship.toLowerCase().contains(searchText) ||
          contact.category.toLowerCase().contains(searchText);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  TrustedContact? get _primaryContact {
    final primaryContacts =
        _contacts.where((contact) => contact.isPrimary).toList();

    if (primaryContacts.isNotEmpty) return primaryContacts.first;
    if (_contacts.isNotEmpty) return _contacts.first;

    return null;
  }

  Future<void> _openContactForm({TrustedContact? contact}) async {
    final isEditing = contact != null;

    final nameController = TextEditingController(
      text: isEditing ? contact.name : '',
    );
    final phoneController = TextEditingController(
      text: isEditing ? contact.phone : '',
    );
    final relationController = TextEditingController(
      text: isEditing ? contact.relationship : '',
    );

    String selectedCategory = isEditing ? contact.category : "Family";
    bool isPrimary = isEditing ? contact.isPrimary : _contacts.isEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _bottomSheetShell(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _softIconBadge(
                        icon: isEditing
                            ? Icons.edit_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: _primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing
                              ? "Edit Trusted Contact"
                              : "Add Trusted Contact",
                          style: GoogleFonts.poppins(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _inputField(
                    controller: nameController,
                    hint: "Contact name",
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: phoneController,
                    hint: "Phone number",
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: relationController,
                    hint: "Relationship, e.g. Mom, Friend",
                    icon: Icons.favorite_rounded,
                  ),
                  const SizedBox(height: 12),
                  _categoryMenu(
                    selectedCategory: selectedCategory,
                    onChanged: (value) {
                      setSheetState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _primaryToggle(
                    value: isPrimary,
                    onChanged: (value) {
                      setSheetState(() {
                        isPrimary = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final relation = relationController.text.trim();

                      if (name.isEmpty || phone.isEmpty) {
                        _showMessage("Name and phone are required");
                        return;
                      }

                      Navigator.pop(sheetContext);

                      if (isEditing) {
                        await _updateContact(
                          contact: contact,
                          name: name,
                          phone: phone,
                          relationship:
                              relation.isEmpty ? selectedCategory : relation,
                          category: selectedCategory,
                          isPrimary: isPrimary,
                        );
                      } else {
                        await _addContact(
                          name: name,
                          phone: phone,
                          relationship:
                              relation.isEmpty ? selectedCategory : relation,
                          category: selectedCategory,
                          isPrimary: isPrimary,
                        );
                      }
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF007A78),
                            Color(0xFF00B4A6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isEditing ? "Update Contact" : "Save Contact",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();
  }

  void _openContactOptions(TrustedContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        return _bottomSheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              _avatar(
                text: contact.initial,
                size: 62,
                bg: _categoryColors(contact.category).background,
                textColor: _categoryColors(contact.category).text,
              ),
              const SizedBox(height: 12),
              Text(
                contact.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${contact.relationship} • ${contact.phone}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _optionTile(
                icon: Icons.call_rounded,
                title: "Call Contact",
                color: const Color(0xFF06A77D),
                onTap: () {
                  Navigator.pop(context);
                  _callContact(contact.phone);
                },
              ),
              _optionTile(
                icon: Icons.sms_rounded,
                title: "Send Emergency SMS",
                color: _blue,
                onTap: () {
                  Navigator.pop(context);
                  _smsContact(contact.phone);
                },
              ),
              _optionTile(
                icon: Icons.edit_rounded,
                title: "Edit Contact",
                color: _primary,
                onTap: () {
                  Navigator.pop(context);
                  _openContactForm(contact: contact);
                },
              ),
              if (!contact.isPrimary)
                _optionTile(
                  icon: Icons.star_rounded,
                  title: "Set as Primary",
                  color: _gold,
                  onTap: () {
                    Navigator.pop(context);
                    _setPrimaryContact(contact);
                  },
                ),
              _optionTile(
                icon: Icons.delete_rounded,
                title: "Delete Contact",
                color: _danger,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(contact);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(TrustedContact contact) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFEAF7F6).withValues(alpha: 0.78),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 34,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _softIconBadge(
                      icon: Icons.delete_rounded,
                      color: _danger,
                      size: 62,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Delete Contact?",
                      style: GoogleFonts.poppins(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Are you sure you want to delete ${contact.name} from your trusted circle?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _muted,
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
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.68),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.poppins(
                                    color: _muted,
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
                              Navigator.pop(context);
                              _deleteContact(contact);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _danger,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _danger.withValues(alpha: 0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Delete",
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

  Widget _optionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _muted.withValues(alpha: 0.45),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _filteredContacts;
    final primaryContact = _primaryContact;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _bgTop,
                  Color(0xFFEAF1FF),
                  _bgBottom,
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _glowBlob(
              color: _primaryLight,
              size: 260,
              opacity: 0.18,
            ),
          ),
          Positioned(
            top: 270,
            left: -110,
            child: _glowBlob(
              color: _blue,
              size: 260,
              opacity: 0.12,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -70,
            child: _glowBlob(
              color: const Color(0xFF06D6A0),
              size: 240,
              opacity: 0.16,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _loadContacts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _circleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _glassPill(
                          icon: Icons.verified_user_rounded,
                          text: "Trusted Circle",
                        ),
                        const SizedBox(width: 10),
                        _circleButton(
                          icon: Icons.refresh_rounded,
                          onTap: _loadContacts,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      "Trusted",
                      style: GoogleFonts.poppins(
                        color: _ink,
                        fontSize: 40,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    Text(
                      "circle",
                      style: GoogleFonts.playfairDisplay(
                        color: _primary,
                        fontSize: 52,
                        height: 0.92,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Keep emergency contacts ready for calls, SMS alerts, and panic support.",
                      style: GoogleFonts.poppins(
                        color: _muted,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _heroCard(),
                    const SizedBox(height: 16),
                    _summaryStrip(),
                    const SizedBox(height: 16),
                    _searchBox(),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip("All"),
                          _filterChip("Family"),
                          _filterChip("Friends"),
                          _filterChip("Work"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel("YOUR SAFETY CIRCLE"),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      _loadingState()
                    else if (_contacts.isEmpty)
                      _emptyState()
                    else ...[
                      if (primaryContact != null)
                        _primaryContactCard(primaryContact),
                      const SizedBox(height: 14),
                      if (filteredContacts.isEmpty)
                        _noSearchResult()
                      else
                        ...filteredContacts.map((contact) {
                          if (primaryContact != null &&
                              contact.id == primaryContact.id) {
                            return const SizedBox.shrink();
                          }

                          return _contactTile(contact);
                        }),
                    ],
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => _openContactForm(),
                      child: Container(
                        height: 58,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(21),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primary,
                              _primaryLight,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              "Add New Contact",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
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
  }

  Widget _heroCard() {
    return _glassCard(
      padding: const EdgeInsets.all(17),
      radius: 28,
      child: Row(
        children: [
          _softIconBadge(
            icon: Icons.shield_moon_rounded,
            color: _primary,
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency SMS ready",
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Alert everyone in your trusted circle from one place.",
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _alertAllContacts,
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: _danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _danger.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip() {
    final primaryContact = _primaryContact;
    final primaryName = primaryContact == null ? "Not set" : primaryContact.name;

    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            icon: Icons.groups_rounded,
            value: _contacts.length.toString(),
            label: "Contacts",
            color: _primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStatCard(
            icon: Icons.star_rounded,
            value: primaryName,
            label: "Primary",
            color: _gold,
            smallValue: true,
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool smallValue = false,
  }) {
    return _glassCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
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
                    color: _ink,
                    fontSize: smallValue ? 13 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.78),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _muted.withValues(alpha: 0.72),
                size: 22,
              ),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : GestureDetector(
                      onTap: _searchController.clear,
                      child: Icon(
                        Icons.close_rounded,
                        color: _muted.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
              hintText: "Search name, phone, relation...",
              hintStyle: GoogleFonts.poppins(
                color: _muted.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return _glassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2.6,
          ),
          const SizedBox(height: 16),
          Text(
            "Loading trusted contacts...",
            style: GoogleFonts.poppins(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return _glassCard(
      child: Column(
        children: [
          _softIconBadge(
            icon: Icons.group_add_rounded,
            color: _primary,
            size: 72,
          ),
          const SizedBox(height: 18),
          Text(
            "No trusted contacts yet",
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add family, friends, or work contacts who can receive your emergency alerts.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _muted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noSearchResult() {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: Center(
        child: Text(
          "No matching contacts found",
          style: GoogleFonts.poppins(
            color: _muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _primaryContactCard(TrustedContact contact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF005F73),
                Color(0xFF0A9396),
                Color(0xFF94D2BD),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              _avatar(
                text: contact.initial,
                bg: Colors.white.withValues(alpha: 0.92),
                textColor: _primary,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openContactOptions(contact),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.34),
                              ),
                            ),
                            child: Text(
                              "PRIMARY",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${contact.relationship} • ${contact.category}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        contact.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _whiteActionIcon(
                icon: Icons.call_rounded,
                onTap: () => _callContact(contact.phone),
              ),
              const SizedBox(width: 8),
              _whiteActionIcon(
                icon: Icons.sms_rounded,
                onTap: () => _smsContact(contact.phone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactTile(TrustedContact contact) {
    final colors = _categoryColors(contact.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        radius: 24,
        child: Row(
          children: [
            _avatar(
              text: contact.initial,
              bg: colors.background,
              textColor: colors.text,
              size: 50,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: GestureDetector(
                onTap: () => _openContactOptions(contact),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${contact.relationship} • ${contact.category}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _muted.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _smallActionButton(
              icon: Icons.call_rounded,
              iconColor: const Color(0xFF06A77D),
              onTap: () => _callContact(contact.phone),
            ),
            const SizedBox(width: 8),
            _smallActionButton(
              icon: Icons.edit_rounded,
              iconColor: _primary,
              onTap: () => _openContactForm(contact: contact),
            ),
            const SizedBox(width: 8),
            _smallActionButton(
              icon: Icons.more_horiz_rounded,
              iconColor: _muted,
              onTap: () => _openContactOptions(contact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text) {
    final selected = _selectedCategory == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _ink.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? _ink.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.76),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : _muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
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
        color: _ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: _primary,
          size: 20,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: _muted.withValues(alpha: 0.55),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.66),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _primaryLight,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _categoryMenu({
    required String selectedCategory,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.84),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
          items: [
            _dropdownItem("Family"),
            _dropdownItem("Friends"),
            _dropdownItem("Work"),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }

  DropdownMenuItem<String> _dropdownItem(String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(
        value,
        style: GoogleFonts.poppins(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _primaryToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.84),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: _gold, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Set as primary contact",
              style: GoogleFonts.poppins(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: _primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _muted.withValues(alpha: 0.22),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _bottomSheetShell({required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                const Color(0xFFEAF7F6).withValues(alpha: 0.84),
                const Color(0xFFDDEBFF).withValues(alpha: 0.72),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.4,
              ),
            ),
          ),
          child: SingleChildScrollView(child: child),
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
          color: _muted.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(99),
        ),
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
              colors: [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.36),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.78),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
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

  Widget _glassPill({
    required IconData icon,
    required String text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: _primary, size: 16),
              const SizedBox(width: 7),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: _ink,
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
              color: Colors.white.withValues(alpha: 0.48),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.78),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Icon(icon, color: _ink, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _softIconBadge({
    required IconData icon,
    required Color color,
    double size = 52,
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
            color.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.70),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.82),
          width: 1.2,
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }

  Widget _smallActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.56),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _whiteActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: _primary, size: 18),
      ),
    );
  }

  Widget _avatar({
    required String text,
    required Color bg,
    required Color textColor,
    double size = 48,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: _muted.withValues(alpha: 0.92),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
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

  _CategoryColor _categoryColors(String category) {
    switch (category.toLowerCase()) {
      case "friends":
        return const _CategoryColor(
          background: Color(0xFFEAF1FF),
          text: Color(0xFF3A86FF),
        );
      case "work":
        return const _CategoryColor(
          background: Color(0xFFFFF3D8),
          text: Color(0xFFFF9F1C),
        );
      case "family":
      default:
        return const _CategoryColor(
          background: Color(0xFFE4F8F3),
          text: Color(0xFF007A78),
        );
    }
  }
}

class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final String category;
  final bool isPrimary;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.category,
    required this.isPrimary,
  });

  factory TrustedContact.fromMap(Map<String, dynamic> map) {
    return TrustedContact(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      phone: map['phone']?.toString() ?? '',
      relationship: map['relationship']?.toString() ?? 'Trusted Contact',
      category: map['category']?.toString() ?? 'Family',
      isPrimary: map['is_primary'] == true,
    );
  }

  String get initial {
    if (name.trim().isEmpty) return "?";
    return name.trim()[0].toUpperCase();
  }
}

class _CategoryColor {
  final Color background;
  final Color text;

  const _CategoryColor({
    required this.background,
    required this.text,
  });
}
