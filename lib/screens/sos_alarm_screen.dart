import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const Color _bgTop = Color(0xFF62B8F6);
  static const Color _bgMid = Color(0xFF78D5F2);
  static const Color _bgBottom = Color(0xFFE8F6FF);
  static const Color _deepInk = Color(0xFF14213D);
  static const Color _mutedInk = Color(0xFF5E6B7E);
  static const Color _cardDark = Color(0xFF3A2147);
  static const Color _cardBlue = Color(0xFFB8D8FF);
  static const Color _danger = Color(0xFFFF385C);
  static const Color _dangerDark = Color(0xFFD90429);
  static const Color _safeGreen = Color(0xFF14B8A6);

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
          .select(
            'sound_vibration_on, default_sos_message, auto_share_location_on',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return;
      if (!mounted) return;

      setState(() {
        _soundVibrationOn = data['sound_vibration_on'] == true;
        _defaultSosMessage =
            data['default_sos_message']?.toString() ??
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
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        HapticFeedback.heavyImpact();
      });
    } catch (e) {
      debugPrint("SOS AUDIO ERROR: $e");
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      _showMessage("Alarm sound could not start");
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
          _subText = "Location permission denied. Alarm is still running.";
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

      final response = await http
          .get(
            uri,
            headers: {
              "User-Agent": "AmaanSafetyApp/1.0",
              "Accept": "application/json",
              "Accept-Language": "en",
            },
          )
          .timeout(
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

  Future<String> _getFallbackAddress(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(latitude, longitude)
          .timeout(
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
      _showMessage("Emergency location saved on this device");
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      debugPrint("SOS SAVE ERROR: User not logged in");
      _showMessage("Emergency location saved on this device");
      return;
    }

    try {
      await Supabase.instance.client
          .from('sos_alerts')
          .insert({
            'user_id': user.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'address': address,
            'is_online': true,
          })
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception("Supabase SOS save timed out");
            },
          );

      debugPrint("SOS SAVE SUCCESS");
      _showMessage("Emergency location saved");
    } catch (e) {
      debugPrint("SOS SAVE ERROR: $e");
      _showMessage("Emergency location saved on this device");
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

      await _saveSosLocally(position: position, address: address);

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _address = address;
        _statusText = "SOS alarm active";
        _subText = "Emergency location captured";
      });

      await _saveSosToSupabase(position: position, address: address);
    } catch (e) {
      debugPrint("SOS LOCATION ERROR: $e");

      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        final address = await _getAddressFromCoordinates(
          lastPosition.latitude,
          lastPosition.longitude,
        );

        await _saveSosLocally(position: lastPosition, address: address);

        if (!mounted) return;

        setState(() {
          _latitude = lastPosition.latitude;
          _longitude = lastPosition.longitude;
          _accuracy = lastPosition.accuracy;
          _address = address;
          _statusText = "SOS alarm active";
          _subText = "Using your last known emergency location";
        });

        await _saveSosToSupabase(position: lastPosition, address: address);
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

    await Clipboard.setData(ClipboardData(text: sosText));

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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Color get _mainColor => _isAlarmActive ? _dangerDark : _danger;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          _background(),
          Positioned(
            top: -90,
            right: -90,
            child: _glowBlob(color: _bgTop, size: 300, opacity: 0.32),
          ),
          Positioned(
            top: 235,
            left: -125,
            child: _glowBlob(
              color: const Color(0xFF5B2A60),
              size: 280,
              opacity: 0.18,
            ),
          ),
          Positioned(
            bottom: -90,
            right: -70,
            child: _glowBlob(color: _bgMid, size: 260, opacity: 0.24),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 28),
                  Text(
                    "SOS",
                    style: GoogleFonts.poppins(
                      color: _deepInk,
                      fontSize: 44,
                      height: 0.92,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  Text(
                    "alarm",
                    style: GoogleFonts.poppins(
                      color: _cardDark,
                      fontSize: 44,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Activate a loud emergency alarm and keep your emergency location ready.",
                    style: GoogleFonts.poppins(
                      color: _mutedInk,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _heroCard(),
                  const SizedBox(height: 22),
                  Center(child: _alarmPulseButton()),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      _isAlarmActive ? "SOS Alarm Active" : "Loud SOS Alarm",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _deepInk,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _isAlarmActive
                          ? "Alarm is active. Your emergency location is being captured."
                          : "Tap activate only when you need emergency attention.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _mutedInk,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _locationCard(),
                  const SizedBox(height: 20),
                  _primaryButton(),
                  const SizedBox(height: 12),
                  _secondaryButton(),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      "Tap only during emergency",
                      style: GoogleFonts.poppins(
                        color: _mutedInk.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgBottom, Color(0xFFDDF5FF), _bgMid],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        _glassPill(icon: Icons.notifications_active_rounded, text: "SOS Alarm"),
      ],
    );
  }

  Widget _heroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _cardDark.withValues(alpha: 0.78),
                const Color(0xFF788EB5).withValues(alpha: 0.58),
                _cardBlue.withValues(alpha: 0.50),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _cardDark.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 66,
                width: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Emergency alarm",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Loud sound, vibration, and emergency location capture.",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                _isAlarmActive
                    ? Icons.warning_amber_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alarmPulseButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _activateSosAlarm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: _isAlarmActive ? 230 : 212,
        width: _isAlarmActive ? 230 : 212,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _mainColor.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isAlarmActive ? 170 : 156,
            width: _isAlarmActive ? 170 : 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _mainColor.withValues(alpha: 0.17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: _isAlarmActive ? 118 : 108,
                width: _isAlarmActive ? 118 : 108,
                decoration: BoxDecoration(
                  color: _mainColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _mainColor.withValues(alpha: 0.38),
                      blurRadius: 34,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(34),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        _isAlarmActive
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: _isAlarmActive ? 58 : 52,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationCard() {
    return _glassCard(
      radius: 26,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softIcon(
                icon: _latitude == null
                    ? Icons.location_searching_rounded
                    : Icons.location_on_rounded,
                color: _latitude == null ? _cardDark : _safeGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Emergency location",
                  style: GoogleFonts.poppins(
                    color: _deepInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (_latitude == null ? _cardDark : _safeGreen)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _latitude == null ? "Pending" : "Captured",
                  style: GoogleFonts.poppins(
                    color: _latitude == null ? _cardDark : _safeGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _deepInk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow(icon: Icons.my_location_rounded, text: _coordinateText()),
          const SizedBox(height: 6),
          _infoRow(icon: Icons.speed_rounded, text: _accuracyText()),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            child: Text(
              "$_statusText • $_subText",
              style: GoogleFonts.poppins(
                color: _mutedInk,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _activateSosAlarm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isAlarmActive ? _deepInk : _danger,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (_isAlarmActive ? _deepInk : _danger).withValues(
                alpha: 0.26,
              ),
              blurRadius: 22,
              offset: const Offset(0, 12),
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
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton() {
    return GestureDetector(
      onTap: _copySosInfo,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        ),
        child: Center(
          child: Text(
            "Copy SOS Info",
            style: GoogleFonts.poppins(
              color: _cardDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: _mutedInk.withValues(alpha: 0.70), size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: _mutedInk,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
              color: Colors.white.withValues(alpha: 0.74),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.50),
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

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.76),
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
            child: Icon(icon, color: _deepInk, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _glassPill({required IconData icon, required String text}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _cardDark, size: 17),
              const SizedBox(width: 7),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: _deepInk,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _softIcon({required IconData icon, required Color color}) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
      ),
      child: Icon(icon, color: color, size: 22),
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
}
