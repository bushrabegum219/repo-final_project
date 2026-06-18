import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/trusted_contact_service.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final TrustedContactService _trustedContactService = TrustedContactService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _trustedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadTrustedContacts();
  }

  Future<void> _loadTrustedContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final contacts = await _trustedContactService.getTrustedContacts();

      if (!mounted) return;

      setState(() {
        _trustedContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openContactForm({
    Map<String, dynamic>? contact,
  }) async {
    final isEditing = contact != null;

    final nameController = TextEditingController(
      text: isEditing ? contact['name']?.toString() ?? '' : '',
    );

    final phoneController = TextEditingController(
      text: isEditing ? contact['phone_number']?.toString() ?? '' : '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.22),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.97),
                      const Color(0xFFFFF1EC).withOpacity(0.88),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.96),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A7A).withOpacity(0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFF0EC),
                                Color(0xFFFFC9C0),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.4,
                            ),
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_rounded
                                : Icons.person_add_alt_1_rounded,
                            color: const Color(0xFFFF5B6B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEditing
                                ? 'Edit Trusted Contact'
                                : 'Add Trusted Contact',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2B2733),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        label: 'Contact name',
                        hint: 'Example: Ammu',
                        icon: Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        label: 'Phone number',
                        hint: 'Example: +8801XXXXXXXXX',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.72),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF8B7B78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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
                              final name = nameController.text.trim();
                              final phoneNumber =
                                  phoneController.text.trim();

                              if (name.isEmpty || phoneNumber.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Name and phone number are required',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(dialogContext, {
                                'name': name,
                                'phoneNumber': phoneNumber,
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF385C),
                                    Color(0xFFFF7A63),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4D5E)
                                        .withOpacity(0.20),
                                    blurRadius: 18,
                                    offset: const Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isEditing ? 'Update' : 'Add',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
  nameController.dispose();
  phoneController.dispose();
});
    if (result == null) return;

    try {
      if (isEditing) {
        await _trustedContactService.updateTrustedContact(
          contactId: contact['id'].toString(),
          name: result['name']!,
          phoneNumber: result['phoneNumber']!,
        );
      } else {
        await _trustedContactService.addTrustedContact(
          name: result['name']!,
          phoneNumber: result['phoneNumber']!,
        );
      }

      if (!mounted) return;

await _loadTrustedContacts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
        ),
      );
    }
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.22),
      builder: (dialogContext) {
        final contactName = contact['name']?.toString() ?? 'this contact';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.97),
                      const Color(0xFFFFF1EC).withOpacity(0.88),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.96),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A7A).withOpacity(0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFF0EC),
                            Color(0xFFFFC9C0),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Color(0xFFFF5B6B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete Contact?',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to delete $contactName?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B7B78),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(dialogContext, false);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.72),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF8B7B78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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
                              Navigator.pop(dialogContext, true);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF385C),
                                    Color(0xFFFF7A63),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
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

    if (shouldDelete != true) return;

    try {
      await _trustedContactService.deleteTrustedContact(
        contactId: contact['id'].toString(),
      );

      if (!mounted) return;

await _loadTrustedContacts();

      await _loadTrustedContacts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openContactForm();
        },
        backgroundColor: const Color(0xFFFF5B6B),
        elevation: 10,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: Text(
          'Add Contact',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 95,
            right: -70,
            child: _trustedGlowBlob(
              color: const Color(0xFFFFB3A7),
              size: 230,
            ),
          ),
          Positioned(
            top: 390,
            left: -90,
            child: _trustedGlowBlob(
              color: const Color(0xFFFFD8B8),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -80,
            child: _trustedGlowBlob(
              color: const Color(0xFFFF9AA2),
              size: 210,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EE),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFFFFC7BD),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              color: Color(0xFFFF5B6B),
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Emergency circle",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF5B6B),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trusted Contacts",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2B2733),
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Manage the people who can receive your panic alerts.",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8B7B78),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFF5B6B),
                    onRefresh: _loadTrustedContacts,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 120),
        children: [
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFFF5B6B),
                  strokeWidth: 2.4,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading trusted contacts...',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B7B78),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
        children: [
          _glassCard(
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF1EE),
                    border: Border.all(
                      color: const Color(0xFFFFC7BD),
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF5B6B),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load trusted contacts',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2B2733),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B7B78),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _loadTrustedContacts,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF385C),
                          Color(0xFFFF7A63),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Try Again',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_trustedContacts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
        children: [
          _glassCard(
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF0EC),
                        Color(0xFFFFC9C0),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.6,
                    ),
                  ),
                  child: const Icon(
                    Icons.contacts_rounded,
                    color: Color(0xFFFF5B6B),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'No trusted contacts yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2B2733),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add contacts who will receive your panic SMS alerts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B7B78),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    _openContactForm();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF385C),
                          Color(0xFFFF7A63),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D5E).withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Add Trusted Contact',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      itemCount: _trustedContacts.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _summaryCard();
        }

        final contact = _trustedContacts[index - 1];

        return _contactCard(contact);
      },
    );
  }

  Widget _summaryCard() {
    final count = _trustedContacts.length;

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF0EC),
                  Color(0xFFFFC9C0),
                ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFFFF5B6B),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count contacts ready',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2B2733),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your emergency circle is saved.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B7B78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EE),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFFFFC7BD),
              ),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF5B6B),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> contact) {
    final name = contact['name']?.toString() ?? 'Unknown';
    final phoneNumber = contact['phone_number']?.toString() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.96),
                const Color(0xFFFFF1EC).withOpacity(0.78),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.96),
              width: 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A7A).withOpacity(0.11),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF0EC),
                      Color(0xFFFFC9C0),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A7A).withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initialFromName(name),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF5B6B),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B7B78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _smallActionButton(
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF8B7B78),
                onTap: () {
                  _openContactForm(contact: contact);
                },
              ),
              const SizedBox(width: 8),
              _smallActionButton(
                icon: Icons.delete_rounded,
                iconColor: const Color(0xFFFF5B6B),
                onTap: () {
                  _deleteContact(contact);
                },
              ),
            ],
          ),
        ),
      ),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.64),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.96),
                const Color(0xFFFFF1EC).withOpacity(0.78),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.96),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A7A).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.75),
                blurRadius: 12,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _trustedGlowBlob({
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 80,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.86),
                  Colors.white.withOpacity(0.46),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A7A).withOpacity(0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7B6765),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFFF5B6B),
        size: 20,
      ),
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF8B7B78),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFB8A5A0),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.74),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.95),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFFF8A7A),
          width: 1.4,
        ),
      ),
    );
  }

  String _initialFromName(String name) {
    final cleanedName = name.trim();

    if (cleanedName.isEmpty) {
      return '?';
    }

    return cleanedName[0].toUpperCase();
  }
}
