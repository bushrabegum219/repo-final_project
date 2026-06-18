import 'dart:convert';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _isOnline = false;
  bool _hasLocation = false;
  bool _isLoadingTokenLocation = false;

  double? _latitude;
  double? _longitude;
  double? _accuracy;

  String _address = "Address not loaded yet";
  String _statusText = "Location not loaded yet";
  String _subText = "Tap update my location to start";

  static const LatLng _defaultSylhet = LatLng(24.904780, 91.860007);

  static const Color _aqua = Color(0xFF35F2D0);
  static const Color _teal = Color(0xFF0AA6A6);
  static const Color _deepTeal = Color(0xFF104B4C);
  static const Color _mint = Color(0xFFB8FFF0);
  
  static const Color _ink = Color(0xFF14333D);
  static const Color _muted = Color(0xFF647982);
  static const Color _warning = Color(0xFFFF9F43);
  static const Color _success = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _prepareMapScreen();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _prepareMapScreen() async {
    await _checkOnlineStatus();
    await _loadLastSavedLocation();
  }

  Future<void> _checkOnlineStatus() async {
    final result = await Connectivity().checkConnectivity();

    if (!mounted) return;

    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  Future<void> _loadLastSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    final acc = prefs.getDouble('last_accuracy');
    final savedAddress = prefs.getString('last_address');

    if (!mounted) return;

    if (lat != null && lng != null) {
      setState(() {
        _latitude = lat;
        _longitude = lng;
        _accuracy = acc;
        _address = savedAddress ?? "Saved safety location";
        _hasLocation = true;
        _statusText = "Saved location ready";
        _subText = _isOnline
            ? "Map is ready to show your position"
            : "Showing your saved safety location";
      });

      if (_isOnline) {
        _moveMapToLocation(lat, lng);
      }
    } else {
      setState(() {
        _statusText = _isOnline ? "Map ready" : "Offline mode active";
        _subText = _isOnline
            ? "Tap update my location to show your position"
            : "No saved location found yet";
      });
    }
  }

  Future<void> _saveLocationLocally(
    Position position, {
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
    await prefs.setDouble('last_accuracy', position.accuracy);

    if (address.trim().isNotEmpty && address != "Address unavailable") {
      await prefs.setString('last_address', address);
    }
  }

  Future<String> _getSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_address') ?? "Saved safety location";
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
              throw Exception("OpenStreetMap address lookup timed out");
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
      debugPrint("OPENSTREETMAP ADDRESS ERROR: $e");
      return await _getFallbackAddress(latitude, longitude);
    }
  }

  Future<String> _getFallbackAddress(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(latitude, longitude)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception("Fallback address lookup timed out");
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
      debugPrint("FALLBACK ADDRESS ERROR: $e");
      return await _getSavedAddress();
    }
  }

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      setState(() {
        _statusText = "Location service is off";
        _subText = "Please turn on GPS/location service";
      });

      _showMessage("Please turn on location service");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (!mounted) return false;

        setState(() {
          _statusText = "Location permission denied";
          _subText = "Please allow location permission";
        });

        _showMessage("Location permission denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      setState(() {
        _statusText = "Permission permanently denied";
        _subText = "Enable permission from app settings";
      });

      _showMessage("Enable location permission from app settings");
      return false;
    }

    return true;
  }

  Future<void> _updateMyLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusText = "Getting location...";
      _subText = "Please wait, maximum 15 seconds";
    });

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

      await _saveLocationLocally(position, address: address);

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _address = address;
        _hasLocation = true;
        _statusText = "Current location ready";
        _subText = _isOnline
            ? "Your location has been updated"
            : "Internet is off, location saved on this device";
      });

      if (_isOnline) {
        _moveMapToLocation(position.latitude, position.longitude);
        await _saveLocationToSupabase(position);
      } else {
        _showMessage("Location saved on this device");
      }
    } catch (e) {
      debugPrint("LOCATION ERROR: $e");

      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        final address = await _getAddressFromCoordinates(
          lastPosition.latitude,
          lastPosition.longitude,
        );

        await _saveLocationLocally(lastPosition, address: address);

        if (!mounted) return;

        setState(() {
          _latitude = lastPosition.latitude;
          _longitude = lastPosition.longitude;
          _accuracy = lastPosition.accuracy;
          _address = address;
          _hasLocation = true;
          _statusText = "Backup location ready";
          _subText = "Live GPS timed out, showing last known location";
        });

        if (_isOnline) {
          _moveMapToLocation(lastPosition.latitude, lastPosition.longitude);
          await _saveLocationToSupabase(lastPosition);
        }

        _showMessage("Showing last known location");
      } else {
        if (!mounted) return;

        setState(() {
          _statusText = "Location timeout or GPS issue";
          _subText = "Turn on GPS and try again";
        });

        _showMessage("Location failed. Turn on GPS and try again.");
      }
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocationToSupabase(Position position) async {
    if (!_isOnline) {
      _showMessage("Location saved on this device");
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      debugPrint("LOCATION SAVE ERROR: User is not logged in");
      _showMessage("Location saved on this device");
      return;
    }

    try {
      await Supabase.instance.client
          .from('user_locations')
          .insert({
            'user_id': user.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'is_online': true,
          })
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception("Supabase save timed out");
            },
          );

      debugPrint("LOCATION SAVE SUCCESS");
      _showMessage("Location updated safely");
    } catch (e) {
      debugPrint("LOCATION SAVE ERROR: $e");
      _showMessage("Location saved on this device");
    }
  }

  Future<void> _loadLiveLocationFromToken() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      _showMessage("Please paste a live tracking token first");
      return;
    }

    if (_isLoadingTokenLocation) return;

    setState(() {
      _isLoadingTokenLocation = true;
      _statusText = "Loading shared location...";
      _subText = "Checking token from panic SMS";
    });

    try {
      await _checkOnlineStatus();

      if (!_isOnline) {
        _showMessage("Internet is required to load live tracking token");
        return;
      }

      final session = await Supabase.instance.client
          .rpc('get_live_tracking_by_token', params: {'input_token': token})
          .maybeSingle();

      if (session == null) {
        throw Exception("No live tracking session found for this token");
      }

      final latitudeValue = session['last_latitude'];
      final longitudeValue = session['last_longitude'];
      final accuracyValue = session['last_accuracy'];
      final status = session['status']?.toString() ?? 'unknown';

      if (latitudeValue == null || longitudeValue == null) {
        throw Exception("Live location is not available yet");
      }

      final latitude = latitudeValue is num
          ? latitudeValue.toDouble()
          : double.parse(latitudeValue.toString());

      final longitude = longitudeValue is num
          ? longitudeValue.toDouble()
          : double.parse(longitudeValue.toString());

      final accuracy = accuracyValue == null
          ? null
          : accuracyValue is num
          ? accuracyValue.toDouble()
          : double.tryParse(accuracyValue.toString());

      final address = await _getAddressFromCoordinates(latitude, longitude);

      if (!mounted) return;

      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _accuracy = accuracy;
        _address = address;
        _hasLocation = true;
        _statusText = status == 'active'
            ? "Shared location active"
            : "Shared session ended";
        _subText = "Location loaded using panic SMS token";
      });

      _moveMapToLocation(latitude, longitude);

      _showMessage("Shared location loaded");
    } catch (e) {
      debugPrint("LIVE TOKEN LOCATION ERROR: $e");

      if (!mounted) return;

      setState(() {
        _statusText = "Could not load token";
        _subText = "Check the token and try again";
      });

      _showMessage("Could not load shared location");
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingTokenLocation = false;
      });
    }
  }

  Future<void> _showOfflineSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final lat = prefs.getDouble('last_latitude');
    final lng = prefs.getDouble('last_longitude');
    final acc = prefs.getDouble('last_accuracy');
    final savedAddress = prefs.getString('last_address');

    if (lat == null || lng == null) {
      _showMessage("No saved location found yet");
      return;
    }

    await _checkOnlineStatus();

    if (!mounted) return;

    setState(() {
      _latitude = lat;
      _longitude = lng;
      _accuracy = acc;
      _address = savedAddress ?? "Saved safety location";
      _hasLocation = true;
      _statusText = "Saved location loaded";
      _subText = "This can help when internet is unavailable";
    });

    if (_isOnline) {
      _moveMapToLocation(lat, lng);
    }

    _showMessage("Saved location loaded");
  }

  Future<void> _copyLocationInfo() async {
    if (_latitude == null || _longitude == null) {
      _showMessage("No location available to copy");
      return;
    }

    final accuracyText = _accuracy == null
        ? "Accuracy not available"
        : "${_accuracy!.toStringAsFixed(1)} meters";

    final locationText =
        "My location: $_address\n"
        "Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}\n"
        "Accuracy: $accuracyText";

    await Clipboard.setData(ClipboardData(text: locationText));

    _showMessage("Location copied");
  }

  void _centerOnlineMap() async {
    await _checkOnlineStatus();

    if (!_isOnline) {
      _showMessage("Map needs internet. Use saved location instead.");
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage("No location available yet");
      return;
    }

    _moveMapToLocation(_latitude!, _longitude!);
    _showMessage("Map centered on your location");
  }

  void _moveMapToLocation(double latitude, double longitude) {
    try {
      _mapController.move(LatLng(latitude, longitude), 17);
    } catch (e) {
      debugPrint("MAP MOVE ERROR: $e");
    }
  }

  LatLng _currentMapCenter() {
    if (_latitude != null && _longitude != null) {
      return LatLng(_latitude!, _longitude!);
    }

    return _defaultSylhet;
  }

  String _coordinateText() {
    if (_latitude == null || _longitude == null) {
      return "No coordinates found";
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

  Widget _onlineMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentMapCenter(),
        initialZoom: _hasLocation ? 17 : 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.amaan_app',
        ),
        if (_latitude != null && _longitude != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_latitude!, _longitude!),
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _aqua.withValues(alpha: 0.22),
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _teal,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _offlineMapView() {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _SimpleMapPainter())),
        Positioned.fill(
          child: Container(
            color: const Color(0xFFE2FFF8).withValues(alpha: 0.34),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 170),
            child: _glassCard(
              radius: 26,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _softIcon(
                    icon: Icons.wifi_off_rounded,
                    color: _warning,
                    size: 58,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Saved Location Mode",
                    style: GoogleFonts.poppins(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Real map needs internet, but your saved location and coordinates can still be used.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _muted,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.74),
                  _mint.withValues(alpha: 0.26),
                  Colors.white.withValues(alpha: 0.56),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _topCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Safety Map",
                          style: GoogleFonts.poppins(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    _topCircleButton(
                      icon: Icons.my_location_rounded,
                      onTap: _updateMyLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _statusPill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill() {
    final hasCapturedLocation = _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              color: hasCapturedLocation
                  ? _success
                  : _isOnline
                  ? _teal
                  : _warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasCapturedLocation
                ? "Location Ready"
                : _isOnline
                ? "Map Ready"
                : "Saved Mode",
            style: GoogleFonts.poppins(
              color: hasCapturedLocation
                  ? _success
                  : _isOnline
                  ? _teal
                  : _warning,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _glassCard(
      radius: 25,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _softIcon(
            icon: _latitude == null
                ? Icons.location_searching_rounded
                : Icons.location_on_rounded,
            color: _latitude == null ? _deepTeal : _success,
            size: 50,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURRENT ADDRESS",
                  style: GoogleFonts.poppins(
                    color: _muted.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _coordinateText(),
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _accuracyText(),
                  style: GoogleFonts.poppins(
                    color: _muted.withValues(alpha: 0.82),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "$_statusText • $_subText",
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 10.2,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveTokenCard() {
    return _glassCard(
      radius: 22,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LIVE TRACKING TOKEN",
            style: GoogleFonts.poppins(
              color: _teal,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tokenController,
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: "Paste token from panic SMS",
              hintStyle: GoogleFonts.poppins(
                color: _muted.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.66),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isLoadingTokenLocation ? null : _loadLiveLocationFromToken,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_deepTeal, _teal, _aqua],
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isLoadingTokenLocation
                        ? Icons.hourglass_bottom_rounded
                        : Icons.location_searching_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoadingTokenLocation
                        ? "Loading Shared Location..."
                        : "Load Shared Location",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
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

  Widget _primaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _updateMyLocation,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_deepTeal, _teal, _aqua]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _teal.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLoading
                  ? Icons.hourglass_bottom_rounded
                  : Icons.near_me_rounded,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(width: 9),
            Text(
              _isLoading ? "Getting Location..." : "Update My Location",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 19),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 12.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.16,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.16, 0.48, 0.86],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(34),
            topRight: Radius.circular(34),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    _mint.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.72),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.82),
                    width: 1.3,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 54,
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Swipe up for options • Swipe down for map",
                      style: GoogleFonts.poppins(
                        color: _muted.withValues(alpha: 0.78),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _locationCard(),
                    const SizedBox(height: 14),
                    _liveTokenCard(),
                    const SizedBox(height: 14),
                    _primaryButton(),
                    const SizedBox(height: 10),
                    _actionButton(
                      text: "Show Saved Location",
                      icon: Icons.offline_pin_rounded,
                      backgroundColor: _warning.withValues(alpha: 0.12),
                      textColor: _warning,
                      onTap: _showOfflineSavedLocation,
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      text: "Copy Location Info",
                      icon: Icons.copy_rounded,
                      backgroundColor: _success.withValues(alpha: 0.12),
                      textColor: _success,
                      onTap: _copyLocationInfo,
                    ),
                    const SizedBox(height: 10),
                    _actionButton(
                      text: _isOnline ? "Center Map" : "Map Needs Internet",
                      icon: Icons.map_rounded,
                      backgroundColor: _isOnline
                          ? _teal.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06),
                      textColor: _isOnline
                          ? _teal
                          : Colors.black.withValues(alpha: 0.38),
                      onTap: _centerOnlineMap,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(icon, color: _ink, size: 19),
          ),
        ),
      ),
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
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.74),
                Colors.white.withValues(alpha: 0.36),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 20,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _softIcon({
    required IconData icon,
    required Color color,
    double size = 44,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isOnline ? _onlineMapView() : _offlineMapView(),
            ),
            _topHeader(),
            _bottomSheet(),
          ],
        ),
      ),
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFE5FFF7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPaint = Paint()
      ..color = const Color(0xFF74D9F2).withValues(alpha: 0.28)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final river = ui.Path()
      ..moveTo(size.width * 0.08, 0)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.22,
        size.width * 0.12,
        size.height * 0.42,
        size.width * 0.34,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.78,
        size.width * 0.44,
        size.height * 0.90,
        size.width * 0.62,
        size.height,
      );

    canvas.drawPath(river, riverPaint);

    final path1 = ui.Path()
      ..moveTo(size.width * 0.60, 0)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.46,
        size.height * 0.30,
        size.width * 0.50,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.65,
        size.width * 0.43,
        size.height * 0.78,
        size.width * 0.47,
        size.height,
      );

    final path2 = ui.Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.40,
        size.height * 0.57,
        size.width * 0.62,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.45,
        size.width * 0.88,
        size.height * 0.42,
        size.width,
        size.height * 0.36,
      );

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadPaint);

    for (double i = 0.10; i < 0.95; i += 0.14) {
      final p = ui.Path()
        ..moveTo(size.width * i, 0)
        ..cubicTo(
          size.width * (i + 0.05),
          size.height * 0.22,
          size.width * (i - 0.04),
          size.height * 0.42,
          size.width * (i + 0.02),
          size.height * 0.70,
        )
        ..cubicTo(
          size.width * (i + 0.04),
          size.height * 0.82,
          size.width * (i - 0.03),
          size.height * 0.90,
          size.width * i,
          size.height,
        );

      canvas.drawPath(p, thinRoadPaint);
    }

    for (double j = 0.18; j < 0.95; j += 0.16) {
      final p = ui.Path()
        ..moveTo(0, size.height * j)
        ..cubicTo(
          size.width * 0.22,
          size.height * (j - 0.03),
          size.width * 0.45,
          size.height * (j + 0.04),
          size.width * 0.66,
          size.height * j,
        )
        ..cubicTo(
          size.width * 0.78,
          size.height * (j - 0.02),
          size.width * 0.90,
          size.height * (j + 0.04),
          size.width,
          size.height * j,
        );

      canvas.drawPath(p, thinRoadPaint);
    }

    final parkPaint = Paint()
      ..color = const Color(0xFFB8F7D4).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      42,
      parkPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.78),
      52,
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
