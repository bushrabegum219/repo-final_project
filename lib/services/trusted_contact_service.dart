import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_trusted_contact_service.dart';

class TrustedContactService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalTrustedContactService _localTrustedContactService =
      LocalTrustedContactService();

  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final response = await _supabase
        .from('trusted_contacts')
        .select('id, name, phone_number')
        .eq('user_id', user.id);

    final contacts = List<Map<String, dynamic>>.from(response);

    await _localTrustedContactService.saveContacts(contacts);

    return contacts;
  }

  Future<List<Map<String, dynamic>>> getCachedTrustedContacts() async {
    return _localTrustedContactService.getCachedContacts();
  }

  Future<void> addTrustedContact({
    required String name,
    required String phoneNumber,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await _supabase.from('trusted_contacts').insert({
      'user_id': user.id,
      'name': name.trim(),
      'phone_number': phoneNumber.trim(),
    });

    await getTrustedContacts();
  }

  Future<void> updateTrustedContact({
    required String contactId,
    required String name,
    required String phoneNumber,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await _supabase
        .from('trusted_contacts')
        .update({
          'name': name.trim(),
          'phone_number': phoneNumber.trim(),
        })
        .eq('id', contactId)
        .eq('user_id', user.id);

    await getTrustedContacts();
  }

  Future<void> deleteTrustedContact({
    required String contactId,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await _supabase
        .from('trusted_contacts')
        .delete()
        .eq('id', contactId)
        .eq('user_id', user.id);

    await getTrustedContacts();
  }
}
