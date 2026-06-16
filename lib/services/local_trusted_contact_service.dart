import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalTrustedContactService {
  static const String _storageKey = 'cached_trusted_contacts';

  Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanContacts = contacts.map((contact) {
      return {
        'id': contact['id']?.toString() ?? '',
        'name': contact['name']?.toString() ?? '',
        'phone_number': contact['phone_number']?.toString() ?? '',
      };
    }).toList();

    final encodedContacts = cleanContacts.map((contact) {
      return jsonEncode(contact);
    }).toList();

    await prefs.setStringList(_storageKey, encodedContacts);
  }

  Future<List<Map<String, dynamic>>> getCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getStringList(_storageKey) ?? [];

    final contacts = <Map<String, dynamic>>[];

    for (final encodedContact in encodedContacts) {
      try {
        final decoded = jsonDecode(encodedContact);

        if (decoded is Map<String, dynamic>) {
          final phoneNumber = decoded['phone_number']?.toString() ?? '';

          if (phoneNumber.trim().isNotEmpty) {
            contacts.add({
              'id': decoded['id']?.toString() ?? '',
              'name': decoded['name']?.toString() ?? '',
              'phone_number': phoneNumber,
            });
          }
        }
      } catch (_) {
        continue;
      }
    }

    return contacts;
  }

  Future<void> clearCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
