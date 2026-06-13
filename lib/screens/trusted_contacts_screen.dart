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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing ? 'Edit Trusted Contact' : 'Add Trusted Contact',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact name',
                  hintText: 'Example: Ammu',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: 'Example: +8801XXXXXXXXX',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phoneNumber = phoneController.text.trim();

                if (name.isEmpty || phoneNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  'name': name,
                  'phoneNumber': phoneNumber,
                });
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Trusted contact updated' : 'Trusted contact added',
          ),
        ),
      );

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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to delete ${contact['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D5E),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _trustedContactService.deleteTrustedContact(
        contactId: contact['id'].toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trusted contact deleted'),
        ),
      );

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
      backgroundColor: const Color(0xFFF9F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Trusted Contacts',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B2733),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openContactForm();
        },
        backgroundColor: const Color(0xFFFF4D5E),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrustedContacts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Could not load trusted contacts',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTrustedContacts,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_trustedContacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.contacts_rounded,
            color: Colors.black26,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            'No trusted contacts yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2B2733),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts who will receive your panic SMS alerts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _trustedContacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contact = _trustedContacts[index];
        final name = contact['name']?.toString() ?? 'Unknown';
        final phoneNumber = contact['phone_number']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFE5EA),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF4D5E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phoneNumber,
                      style: GoogleFonts.poppins(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _openContactForm(contact: contact);
                },
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.black45,
                ),
              ),
              IconButton(
                onPressed: () {
                  _deleteContact(contact);
                },
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFFF4D5E),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
