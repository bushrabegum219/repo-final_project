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

  bool _isLoading = true;
  String _selectedCategory = "All";
  List<TrustedContact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() {
      setState(() {});
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
      setState(() {
        _isLoading = false;
      });
      _showMessage("Please login first");
      return;
    }

    try {
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

      setState(() {
        _isLoading = false;
      });

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
            .update({'is_primary': false})
            .eq('user_id', user.id);
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

  Future<void> _deleteContact(TrustedContact contact) async {
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

    try {
      await _supabase
          .from('trusted_circle')
          .update({'is_primary': false})
          .eq('user_id', user.id);

      await _supabase
          .from('trusted_circle')
          .update({'is_primary': true})
          .eq('id', contact.id);

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

    final message =
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

    final message =
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

    if (primaryContacts.isNotEmpty) {
      return primaryContacts.first;
    }

    if (_contacts.isNotEmpty) {
      return _contacts.first;
    }

    return null;
  }

  void _openAddContactSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    String selectedCategory = "Family";
    bool isPrimary = _contacts.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F1FF),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Add Trusted Contact",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F1A2E),
                      ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: "Family",
                              child: Text("Family"),
                            ),
                            DropdownMenuItem(
                              value: "Friends",
                              child: Text("Friends"),
                            ),
                            DropdownMenuItem(
                              value: "Work",
                              child: Text("Work"),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setSheetState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFAB42F5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Set as primary contact",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: isPrimary,
                            activeThumbColor: const Color(0xFFAB42F5),
                            onChanged: (value) {
                              setSheetState(() {
                                isPrimary = value;
                              });
                            },
                          ),
                        ],
                      ),
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

                        await _addContact(
                          name: name,
                          phone: phone,
                          relationship:
                              relation.isEmpty ? selectedCategory : relation,
                          category: selectedCategory,
                          isPrimary: isPrimary,
                        );
                      },
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFAB42F5),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Text(
                            "Save Contact",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            color: const Color(0xFFAB42F5),
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

  void _openContactOptions(TrustedContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contact.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${contact.relationship} • ${contact.phone}",
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              _optionTile(
                icon: Icons.call_rounded,
                title: "Call Contact",
                color: const Color(0xFF2EAD69),
                onTap: () {
                  Navigator.pop(context);
                  _callContact(contact.phone);
                },
              ),
              _optionTile(
                icon: Icons.sms_rounded,
                title: "Send Emergency SMS",
                color: const Color(0xFFAB42F5),
                onTap: () {
                  Navigator.pop(context);
                  _smsContact(contact.phone);
                },
              ),
              if (!contact.isPrimary)
                _optionTile(
                  icon: Icons.star_rounded,
                  title: "Set as Primary",
                  color: const Color(0xFFFFB800),
                  onTap: () {
                    Navigator.pop(context);
                    _setPrimaryContact(contact);
                  },
                ),
              _optionTile(
                icon: Icons.delete_rounded,
                title: "Delete Contact",
                color: const Color(0xFFFF445C),
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
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete contact?"),
          content: Text("Are you sure you want to delete ${contact.name}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteContact(contact);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Color(0xFFFF445C)),
              ),
            ),
          ],
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
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 13,
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
      backgroundColor: const Color(0xFFF8F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  _roundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Trusted Contacts",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1A2E),
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      _roundButton(
                        icon: Icons.refresh_rounded,
                        onTap: _loadContacts,
                      ),
                      if (_contacts.isNotEmpty)
                        Positioned(
                          right: 9,
                          top: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF445C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _alertAllContacts,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFFFF445C),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Emergency SOS",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1A2E),
                              ),
                            ),
                            Text(
                              "Alert all trusted contacts\ninstantly",
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                height: 1.2,
                                color: Colors.black38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 38,
                        width: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF445C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.black26,
                      size: 20,
                    ),
                    hintText: "Search contacts...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _filterChip("All"),
                  _filterChip("Family"),
                  _filterChip("Friends"),
                  _filterChip("Work"),
                ],
              ),

              const SizedBox(height: 15),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: CircularProgressIndicator(
                    color: Color(0xFFAB42F5),
                  ),
                )
              else if (_contacts.isEmpty)
                _emptyState()
              else ...[
                if (primaryContact != null) _primaryContactCard(primaryContact),

                const SizedBox(height: 13),

                if (filteredContacts.isEmpty)
                  _noSearchResult()
                else
                  ...filteredContacts.map(
                    (contact) {
                      if (primaryContact != null &&
                          contact.id == primaryContact.id) {
                        return const SizedBox.shrink();
                      }

                      return _contactTile(contact);
                    },
                  ),

                const SizedBox(height: 16),
              ],

              GestureDetector(
                onTap: _openAddContactSheet,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB42F5),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Center(
                    child: Text(
                      "+ Add New Contact",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 30, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: Color(0xFFAB42F5),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No trusted contacts yet",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add family, friends, or work contacts for emergency help.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.black38,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noSearchResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        "No matching contacts found",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.black38,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _primaryContactCard(TrustedContact contact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8D3BFF),
            Color(0xFFC849F8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _avatar(
            text: contact.initial,
            bg: const Color(0xFFE8D8FF),
            textColor: const Color(0xFF8D3BFF),
            size: 46,
          ),
          const SizedBox(width: 13),
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
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 6,
                        width: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF68F59D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${contact.category} • Primary",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact.phone,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _smallPurpleIcon(Icons.star_rounded),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _callContact(contact.phone),
            child: _whiteActionIcon(Icons.call_rounded),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _smsContact(contact.phone),
            child: _whiteActionIcon(Icons.sms_rounded),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(TrustedContact contact) {
    final colors = _categoryColors(contact.category);

    return GestureDetector(
      onTap: () => _openContactOptions(contact),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            _avatar(
              text: contact.initial,
              bg: colors.background,
              textColor: colors.text,
              size: 43,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1F1A2E),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "${contact.relationship} • ${contact.category}",
                    style: GoogleFonts.poppins(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _callContact(contact.phone),
              child: Container(
                height: 31,
                width: 31,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Color(0xFF4E9F6E),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 31,
              width: 31,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: Colors.black26,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54, size: 18),
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
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _avatar({
    required String text,
    required Color bg,
    required Color textColor,
    double size = 44,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _smallPurpleIcon(IconData icon) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white70, size: 16),
    );
  }

  Widget _whiteActionIcon(IconData icon) {
    return Container(
      height: 32,
      width: 32,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF9D3EFF), size: 17),
    );
  }

  _CategoryColor _categoryColors(String category) {
    switch (category.toLowerCase()) {
      case "friends":
        return const _CategoryColor(
          background: Color(0xFFEAF1FF),
          text: Color(0xFF5D7FEA),
        );
      case "work":
        return const _CategoryColor(
          background: Color(0xFFFFF0DB),
          text: Color(0xFFFF9F43),
        );
      case "family":
      default:
        return const _CategoryColor(
          background: Color(0xFFEAF7EF),
          text: Color(0xFF4E9F6E),
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