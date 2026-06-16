import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveLocationTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _trackingTimer;
  String? _activeSessionId;
  String? _activeTrackingToken;

  bool get isTracking => _trackingTimer?.isActive ?? false;
  String? get activeTrackingToken => _activeTrackingToken;

  Future<String?> startLiveTracking() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is turned off');
    }

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

    final position = await Geolocator.getCurrentPosition();

    final locationLink = _createLocationLink(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final insertedSession = await _supabase
        .from('panic_live_sessions')
        .insert({
          'user_id': user.id,
          'status': 'active',
          'last_latitude': position.latitude,
          'last_longitude': position.longitude,
          'last_accuracy': position.accuracy,
          'last_location_link': locationLink,
        })
        .select()
        .single();

    _activeSessionId = insertedSession['id'].toString();
    _activeTrackingToken = insertedSession['tracking_token'].toString();

    await _insertLocationUpdate(
      userId: user.id,
      sessionId: _activeSessionId!,
      position: position,
    );

    _trackingTimer?.cancel();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        _sendLiveLocationUpdate();
      },
    );

    print('LIVE LOCATION STEP: tracking started');
    print('Live session ID: $_activeSessionId');

    return _activeSessionId;
  }

  Future<void> _sendLiveLocationUpdate() async {
    final user = _supabase.auth.currentUser;

    if (user == null || _activeSessionId == null) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();

      final locationLink = _createLocationLink(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _insertLocationUpdate(
        userId: user.id,
        sessionId: _activeSessionId!,
        position: position,
      );

      final nowUtc = DateTime.now().toUtc();
      final nowBd = nowUtc.add(const Duration(hours: 6));

      await _supabase
          .from('panic_live_sessions')
          .update({
            'last_latitude': position.latitude,
            'last_longitude': position.longitude,
            'last_accuracy': position.accuracy,
            'last_location_link': locationLink,
            'updated_at': nowUtc.toIso8601String(),
            'updated_at_bd': nowBd.toIso8601String(),
          })
          .eq('id', _activeSessionId!)
          .eq('user_id', user.id);

      print('LIVE LOCATION STEP: update sent');
      print(locationLink);
    } catch (e) {
      print('LIVE LOCATION STEP: update failed');
      print(e);
    }
  }

  Future<void> _insertLocationUpdate({
    required String userId,
    required String sessionId,
    required Position position,
  }) async {
    final locationLink = _createLocationLink(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await _supabase.from('panic_live_location_updates').insert({
      'session_id': sessionId,
      'user_id': userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'heading': position.heading,
      'location_link': locationLink,
    });
  }

  Future<void> stopLiveTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      print('LIVE LOCATION STEP: stop failed because user is null');
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final nowBd = nowUtc.add(const Duration(hours: 6));

    try {
      await _supabase
          .from('panic_live_sessions')
          .update({
            'status': 'ended',
            'ended_at': nowUtc.toIso8601String(),
            'ended_at_bd': nowBd.toIso8601String(),
            'updated_at': nowUtc.toIso8601String(),
            'updated_at_bd': nowBd.toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('status', 'active');

      print('LIVE LOCATION STEP: all active sessions stopped for user');
    } catch (e) {
      print('LIVE LOCATION STEP: stop failed');
      print(e);
    }

    _activeSessionId = null;
    _activeTrackingToken = null;
  }

  String _createLocationLink({
    required double latitude,
    required double longitude,
  }) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  void dispose() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _activeTrackingToken = null;
  }
}
