import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> setupPushNotifications() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      print('PUSH STEP 1: user not logged in, token not saved');
      return;
    }

    print('PUSH STEP 1: requesting notification permission');

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('PUSH STEP 2: getting FCM token');

    final token = await _messaging.getToken();

    if (token == null) {
      print('PUSH STEP 3: FCM token is null');
      return;
    }

    print('PUSH STEP 3: FCM token obtained');
    print(token);

    await _supabase.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'platform': 'android',
        'device_name': 'Android phone',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,fcm_token',
    );

    print('PUSH STEP 4: FCM token saved to Supabase');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        return;
      }

      await _supabase.from('user_push_tokens').upsert(
        {
          'user_id': currentUserId,
          'fcm_token': newToken,
          'platform': 'android',
          'device_name': 'Android phone',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );

      print('PUSH STEP 5: refreshed FCM token saved');
    });
  }
}
