import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_trusted_contact_service.dart';
import 'sms_service.dart';

class PanicService {
  final SupabaseClient supabase = Supabase.instance.client;
  final SmsService _smsService = SmsService();
  final LocalTrustedContactService _localTrustedContactService =
      LocalTrustedContactService();

  Future<String> sendAlert({
  String? liveTrackingToken,
}) async {
    print('STEP 1: sendAlert started');

    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is turned off');
    }

    print('STEP 2: location service is ON');

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    print('STEP 3: location permission granted');

    final position = await Geolocator.getCurrentPosition();

    print('STEP 4: location obtained');
    print('Latitude: ${position.latitude}');
    print('Longitude: ${position.longitude}');

    final locationLink =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

   final liveTrackingText =
    liveTrackingToken == null || liveTrackingToken.isEmpty
        ? ''
        : '\nLive token: $liveTrackingToken';

final alertMessage =
    ' I need help.\nLocation: $locationLink$liveTrackingText';
    print('STEP 4.1: alert message created');
    print(alertMessage);

    final contacts = await _getContactsForPanic();

    if (contacts.isEmpty) {
      throw Exception('No trusted contacts found on phone');
    }

    print('STEP 5: trusted contacts ready');
    print('Trusted contact count: ${contacts.length}');

    await _smsService.sendEmergencySmsToContacts(
      contacts: contacts,
      message: alertMessage,
    );

    print('STEP 5.1: emergency SMS sent to trusted contacts');

    await _trySavePanicAlertOnline(
      userId: userId,
      latitude: position.latitude,
      longitude: position.longitude,
      locationLink: locationLink,
      alertMessage: alertMessage,
      contacts: contacts,
    );

    return alertMessage;
  }

  Future<List<Map<String, dynamic>>> _getContactsForPanic() async {
    try {
      final onlineContacts = await getTrustedContacts();

      if (onlineContacts.isNotEmpty) {
        await _localTrustedContactService.saveContacts(onlineContacts);
        print('CONTACT STEP: using online Supabase contacts');
        return onlineContacts;
      }
    } catch (e) {
      print('CONTACT STEP: Supabase contacts failed, using local cache');
      print(e);
    }

    final cachedContacts =
        await _localTrustedContactService.getCachedContacts();

    print('CONTACT STEP: cached contact count: ${cachedContacts.length}');

    return cachedContacts;
  }

  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final data = await supabase
        .from('trusted_contacts')
        .select('id, name, phone_number')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _trySavePanicAlertOnline({
    required String userId,
    required double latitude,
    required double longitude,
    required String locationLink,
    required String alertMessage,
    required List<Map<String, dynamic>> contacts,
  }) async {
    try {
      final insertedAlert = await supabase
          .from('panic_alerts')
          .insert({
            'user_id': userId,
            'latitude': latitude,
            'longitude': longitude,
            'location_link': locationLink,
            'alert_message': alertMessage,
            'status': 'active',
          })
          .select()
          .single();

      final panicAlertId = insertedAlert['id'];

      print('STEP 6: panic alert inserted into Supabase');
      print('Panic alert ID: $panicAlertId');

      final recipients = contacts.map((contact) {
        return {
          'user_id': userId,
          'panic_alert_id': panicAlertId,
          'trusted_contact_id':
              contact['id']?.toString().isNotEmpty == true
                  ? contact['id']
                  : null,
          'contact_name': contact['name']?.toString() ?? '',
          'phone_number': contact['phone_number']?.toString() ?? '',
          'message': alertMessage,
          'delivery_status': 'sms_sent',
        };
      }).toList();

      await supabase.from('alert_recipients').insert(recipients);

      print('STEP 7: alert recipients inserted');
      print('Recipient count: ${recipients.length}');
    } catch (e) {
      print('ONLINE STEP: could not save panic alert online');
      print(e);
    }
  }
}
