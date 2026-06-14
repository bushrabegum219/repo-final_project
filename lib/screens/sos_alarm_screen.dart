import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosAlarmScreen extends StatefulWidget {
  const SosAlarmScreen({super.key});

  @override
  State<SosAlarmScreen> createState() => _SosAlarmScreenState();
}

class _SosAlarmScreenState extends State<SosAlarmScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isAlarmActive = false;
  bool _isLoading = false;
  bool _isOnline = false;
  bool _soundVibrationOn = true;
  String _defaultSosMessage =
    "Emergency! I need help. Please contact me as soon as possible.";
  bool _autoShareLocationOn = true;

  Timer? _vibrationTimer;

  double? _latitude;
  double? _longitude;
  double? _accuracy;

  String _address = "Location not captured yet";
  String _statusText = "Ready to activate SOS alarm";
  String _subText = "Tap only during emergency";

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
     _loadUserSettings();
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkOnlineStatus() async {
  final result = await Connectivity().checkConnectivity();

  if (!mounted) return;

  setState(() {
    _isOnline = !result.contains(ConnectivityResult.none);
  });
}

Future<void> _loadUserSettings() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) return;

  try {
    final data = await Supabase.instance.client
        .from('user_settings')
        .select('sound_vibration_on, default_sos_message, auto_share_location_on')
        .eq('user_id', user.id)
        .maybeSingle();

    if (data == null) return;

    if (!mounted) return;

    setState(() {
      _soundVibrationOn = data['sound_vibration_on'] == true;
      _defaultSosMessage = data['default_sos_message']?.toString() ??
          "Emergency! I need help. Please contact me as soon as possible.";
      _autoShareLocationOn = data['auto_share_location_on'] == true;
    });
  } catch (e) {
    debugPrint("SOS SETTINGS LOAD ERROR: $e");
  }
}



  Future<void> _startAlarmSoundLoop() async {
  if (!_soundVibrationOn) {
    debugPrint("SOS sound and vibration disabled from settings");
    return;
  }

  try {
    await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sos_alarm.mp3'));

      HapticFeedback.heavyImpact();

      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) {
          HapticFeedback.heavyImpact();
        },
      );
    } catch (e) {
      debugPrint("SOS AUDIO ERROR: $e");
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      _showMessage("Alarm sound file error. Check assets/sos_alarm.mp3");
    }
  }

  Future<void> _stopAlarmSoundLoop() async {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint("SOS STOP AUDIO ERROR: $e");
    }
  }

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage("Please turn on location service");

      if (!mounted) return false;

      setState(() {
        _statusText = "SOS alarm active";
        _subText = "Location service is off. Turn on GPS to save location.";
      });

      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _showMessage("Location permission denied");

        if (!mounted) return false;

        setState(() {
          _statusText = "SOS alarm active";
          _subText = "Location permission denied. Alarm still running.";
        });

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage("Enable location permission from app settings");

      if (!mounted) return false;

      setState(() {
        _statusText = "SOS alarm active";
        _subText = "Enable location permission from settings.";
      });

      return false;
    }

    return true;
  }

  Future<String> _getSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sos_address') ??
        prefs.getString('last_address') ??
        "Saved emergency location";
  }

  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    await _checkOnlineStatus();

    if (!_isOnline) {
      return await _getSavedAddress();
    }

    try {
      final uri = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?format=jsonv2"
        "&lat=$latitude"
        "&lon=$longitude"
        "&zoom=18"
        "&addressdetails=1",
      );

      final response = await http.get(
        uri,
        headers: {
          "User-Agent": "AmaanSafetyApp/1.0",
          "Accept": "application/json",
          "Accept-Language": "en",
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("OpenStreetMap SOS address lookup timed out");
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data["address"] as Map<String, dynamic>?;

        if (address != null) {
          final exactParts = <String?>[
            address["neighbourhood"]?.toString(),
            address["suburb"]?.toString(),
            address["quarter"]?.toString(),
            address["residential"]?.toString(),
            address["hamlet"]?.toString(),
            address["road"]?.toString(),
            address["village"]?.toString(),
            address["town"]?.toString(),
            address["city"]?.toString(),
            address["municipality"]?.toString(),
            address["county"]?.toString(),
            address["state_district"]?.toString(),
            address["state"]?.toString(),
            address["country"]?.toString(),
          ];

          final cleanedParts = exactParts
              .where((e) => e != null && e.trim().isNotEmpty)
              .map((e) => e!.trim())
              .toSet()
              .toList();

          if (cleanedParts.isNotEmpty) {
            return cleanedParts.join(", ");
          }
        }

        final displayName = data["display_name"]?.toString();

        if (displayName != null && displayName.trim().isNotEmpty) {
          return displayName;
        }
      }

      return await _getFallbackAddress(latitude, longitude);
    } catch (e) {
      debugPrint("SOS OPENSTREETMAP ADDRESS ERROR: $e");
      return await _getFallbackAddress(latitude, longitude);
    }
  }

  Future<String> _getFallbackAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final places = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("SOS fallback address lookup timed out");
        },
      );

      if (places.isEmpty) {
        return await _getSavedAddress();
      }

      final place = places.first;

      final parts = <String>[
        if ((place.street ?? "").trim().isNotEmpty) place.street!,
        if ((place.subLocality ?? "").trim().isNotEmpty) place.subLocality!,
        if ((place.locality ?? "").trim().isNotEmpty) place.locality!,
        if ((place.subAdministrativeArea ?? "").trim().isNotEmpty)
          place.subAdministrativeArea!,
        if ((place.administrativeArea ?? "").trim().isNotEmpty)
          place.administrativeArea!,
        if ((place.country ?? "").trim().isNotEmpty) place.country!,
      ];

      final cleanedParts = parts
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (cleanedParts.isEmpty) {
        return await _getSavedAddress();
      }

      return cleanedParts.join(", ");
    } catch (e) {
      debugPrint("SOS FALLBACK ADDRESS ERROR: $e");
      return await _getSavedAddress();
    }
  }

  Future<void> _saveSosLocally({
    required Position position,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('last_sos_latitude', position.latitude);
    await prefs.setDouble('last_sos_longitude', position.longitude);
    await prefs.setDouble('last_sos_accuracy', position.accuracy);
    await prefs.setString('last_sos_address', address);
    await prefs.setString('last_sos_time', DateTime.now().toIso8601String());
  }

  Future<void> _saveSosToSupabase({
    required Position position,
    required String address,
  }) async {
    await _checkOnlineStatus();

    if (!_isOnline) {
      _showMessage("Offline: SOS saved locally only");
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage("Please login first to save SOS online");
      debugPrint("SOS SAVE ERROR: User not logged in");
      return;
    }

    try {
      await Supabase.instance.client.from('sos_alerts').insert({
        'user_id': user.id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'address': address,
        'is_online': true,
      }).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Supabase SOS save timed out");
        },
      );

      debugPrint("SOS SAVE SUCCESS");
      _showMessage("SOS alert saved to Supabase");
    } catch (e) {
      debugPrint("SOS SAVE ERROR: $e");
      _showMessage("SOS saved locally, Supabase save failed");
    }
  }

  Future<void> _activateSosAlarm() async {
    if (_isLoading) return;

    if (_isAlarmActive) {
      await _stopSosAlarm();
      return;
    }

    setState(() {
      _isAlarmActive = true;
      _isLoading = true;
      _statusText = "SOS alarm active";
      _subText = "Alarm started. Capturing emergency location...";
    });

    await _startAlarmSoundLoop();
    await _checkOnlineStatus();

    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await _saveSosLocally(
        position: position,
        address: address,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _address = address;
        _statusText = "SOS alarm active";
        _subText = _isOnline
            ? "Emergency alert saved online and locally"
            : "Offline mode: SOS saved locally";
      });

      await _saveSosToSupabase(
        position: position,
        address: address,
      );
    } catch (e) {
      debugPrint("SOS LOCATION ERROR: $e");

      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        final address = await _getAddressFromCoordinates(
          lastPosition.latitude,
          lastPosition.longitude,
        );

        await _saveSosLocally(
          position: lastPosition,
          address: address,
        );

        if (!mounted) return;

        setState(() {
          _latitude = lastPosition.latitude;
          _longitude = lastPosition.longitude;
          _accuracy = lastPosition.accuracy;
          _address = address;
          _statusText = "SOS alarm active with backup location";
          _subText = "Live GPS failed, using last known location";
        });

        await _saveSosToSupabase(
          position: lastPosition,
          address: address,
        );
      } else {
        if (!mounted) return;

        setState(() {
          _statusText = "SOS alarm active";
          _subText = "Location failed, but alarm is still running";
        });

        _showMessage("Location failed. Alarm is still running.");
      }
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopSosAlarm() async {
    await _stopAlarmSoundLoop();

    if (!mounted) return;

    setState(() {
      _isAlarmActive = false;
      _isLoading = false;
      _statusText = "SOS alarm stopped";
      _subText = "Tap activate if emergency continues";
    });

    _showMessage("SOS alarm stopped");
  }

  Future<void> _copySosInfo() async {
  final locationText = (_latitude == null || _longitude == null)
      ? "Location not available"
      : "$_address\nCoordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}";

  final accuracyText = _accuracy == null
      ? "Accuracy not available"
      : "Accuracy: ${_accuracy!.toStringAsFixed(1)} meters";

  final sosText = _autoShareLocationOn
      ? "🚨 SOS Emergency Alert\n"
          "$_defaultSosMessage\n\n"
          "Location: $locationText\n"
          "$accuracyText"
      : "🚨 SOS Emergency Alert\n"
          "$_defaultSosMessage";

  await Clipboard.setData(
    ClipboardData(text: sosText),
  );

  _showMessage("SOS info copied");
}
  String _coordinateText() {
    if (_latitude == null || _longitude == null) {
      return "Coordinates not captured yet";
    }

    return "${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}";
  }

  String _accuracyText() {
    if (_accuracy == null) {
      return "Accuracy not available";
    }

    return "Accuracy: ${_accuracy!.toStringAsFixed(1)} meters";
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

  Color get _mainColor =>
      _isAlarmActive ? const Color(0xFFD90429) : const Color(0xFFFF3B45);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const Spacer(),
                  const Text(
                    "SOS Alarm",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const Spacer(),

              GestureDetector(
                onTap: _activateSosAlarm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _isAlarmActive ? 245 : 230,
                  width: _isAlarmActive ? 245 : 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mainColor.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Container(
                      height: _isAlarmActive ? 185 : 170,
                      width: _isAlarmActive ? 185 : 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mainColor.withOpacity(0.20),
                      ),
                      child: Center(
                        child: Container(
                          height: _isAlarmActive ? 132 : 120,
                          width: _isAlarmActive ? 132 : 120,
                          decoration: BoxDecoration(
                            color: _mainColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _mainColor.withOpacity(0.45),
                                blurRadius: 35,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isAlarmActive
                                ? Icons.warning_amber_rounded
                                : Icons.notifications_active,
                            color: Colors.white,
                            size: _isAlarmActive ? 64 : 58,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                _isAlarmActive ? "SOS Alarm Active" : "Loud SOS Alarm",
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF171722),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _isAlarmActive
                    ? "Alarm is active. Your emergency location is being saved."
                    : "Activate a loud emergency alarm and save your emergency location.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFD6DC),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: _isOnline
                              ? const Color(0xFF2EAD69)
                              : const Color(0xFFFF9F43),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isOnline
                                ? "Online: Supabase save available"
                                : "Offline: local save only",
                            style: TextStyle(
                              color: _isOnline
                                  ? const Color(0xFF2EAD69)
                                  : const Color(0xFFFF9F43),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF171722),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _coordinateText(),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _accuracyText(),
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$_statusText • $_subText",
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _isLoading ? null : _activateSosAlarm,
                child: Container(
                  height: 58,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isAlarmActive ? Colors.black87 : _mainColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _mainColor.withOpacity(0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isLoading
                          ? "Saving Location..."
                          : _isAlarmActive
                              ? "Stop Alarm"
                              : "Activate Alarm",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _copySosInfo,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "Copy SOS Info",
                      style: TextStyle(
                        color: Color(0xFFFF3B45),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Tap only during emergency",
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}