import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _prepareMapScreen();
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
        _address = savedAddress ?? "Saved offline location";
        _hasLocation = true;
        _statusText =
            _isOnline ? "Last saved location" : "Offline saved location";
        _subText = _isOnline
            ? "Online map is available"
            : "Internet is off, showing saved safety location";
      });

      if (_isOnline) {
        _moveMapToLocation(lat, lng);
      }
    } else {
      setState(() {
        _statusText = _isOnline ? "Online map ready" : "Offline mode active";
        _subText = _isOnline
            ? "Tap update my location to show your position"
            : "No saved offline location found yet";
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
    return prefs.getString('last_address') ?? "Saved offline location";
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
        _statusText =
            _isOnline ? "Current online location" : "Current offline GPS location";
        _subText = _isOnline
            ? "Real map and Supabase save available"
            : "Internet off, location saved locally";
      });

      if (_isOnline) {
        _moveMapToLocation(position.latitude, position.longitude);
        await _saveLocationToSupabase(position);
      } else {
        _showMessage("Offline mode: location saved locally only");
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
          _statusText = "Last known GPS location";
          _subText = _isOnline
              ? "Live GPS timed out, showing backup location"
              : "Offline mode, showing saved safety location";
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
      _showMessage("Offline mode: location saved locally only");
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      debugPrint("SUPABASE LOCATION SAVE ERROR: User is not logged in");
      _showMessage("Please login first to save location online");
      return;
    }

    try {
      await Supabase.instance.client.from('user_locations').insert({
        'user_id': user.id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'is_online': true,
      }).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Supabase save timed out");
        },
      );

      debugPrint("SUPABASE LOCATION SAVE SUCCESS");
      _showMessage("Location saved online and offline");
    } catch (e) {
      debugPrint("SUPABASE LOCATION SAVE ERROR: $e");
      _showMessage("Saved locally, but Supabase save failed");
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
    _statusText = "Loading live tracking location...";
    _subText = "Checking token from panic SMS";
  });

  try {
    await _checkOnlineStatus();

    if (!_isOnline) {
      _showMessage("Internet is required to load live tracking token");
      return;
    }

    final session = await Supabase.instance.client
        .rpc(
          'get_live_tracking_by_token',
          params: {
            'input_token': token,
          },
        )
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

    final address = await _getAddressFromCoordinates(
      latitude,
      longitude,
    );

    if (!mounted) return;

    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _accuracy = accuracy;
      _address = address;
      _hasLocation = true;
      _statusText = status == 'active'
          ? "Trusted live tracking active"
          : "Trusted live session ended";
      _subText = "Location loaded using panic SMS token";
    });

    _moveMapToLocation(latitude, longitude);

    _showMessage("Live tracking location loaded");
  } catch (e) {
    debugPrint("LIVE TOKEN LOCATION ERROR: $e");

    if (!mounted) return;

    setState(() {
      _statusText = "Could not load live token";
      _subText = "Check the token and try again";
    });

    _showMessage("Could not load live location from token");
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
      _showMessage("No offline saved location found yet");
      return;
    }

    await _checkOnlineStatus();

    if (!mounted) return;

    setState(() {
      _latitude = lat;
      _longitude = lng;
      _accuracy = acc;
      _address = savedAddress ?? "Saved offline location";
      _hasLocation = true;
      _statusText = "Offline saved location";
      _subText = "This works without internet";
    });

    if (_isOnline) {
      _moveMapToLocation(lat, lng);
    }

    _showMessage("Offline saved location loaded");
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

    await Clipboard.setData(
      ClipboardData(text: locationText),
    );

    _showMessage("Location copied with accuracy");
  }

  void _centerOnlineMap() async {
    await _checkOnlineStatus();

    if (!_isOnline) {
      _showMessage("Online map needs internet. Use offline saved location.");
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
      _mapController.move(
        LatLng(latitude, longitude),
        17,
      );
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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
                width: 70,
                height: 70,
                child: const Icon(
                  Icons.location_pin,
                  color: Color(0xFF8F6AE8),
                  size: 48,
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
        Positioned.fill(
          child: CustomPaint(
            painter: _SimpleMapPainter(),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFFF7EF).withOpacity(0.35),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 170),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Color(0xFFFF9F43),
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Offline Safety Mode",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF342D42),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Real map needs internet, but your saved location and coordinates still work.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 11,
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
                        color: const Color(0xFF3A3348),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isOnline
                    ? const Color(0xFFF0E9FF)
                    : const Color(0xFFFFEFE2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 6,
                    width: 6,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF9B7BE8)
                          : const Color(0xFFFF9F43),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _isOnline ? "Online Real Map" : "Offline Saved Mode",
                    style: GoogleFonts.poppins(
                      color: _isOnline
                          ? const Color(0xFF9B7BE8)
                          : const Color(0xFFFF9F43),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF0ECF7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color:
                  _isOnline ? const Color(0xFFF0E9FF) : const Color(0xFFFFEFE2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isOnline ? Icons.location_pin : Icons.offline_pin_rounded,
              color:
                  _isOnline ? const Color(0xFF9B7BE8) : const Color(0xFFFF9F43),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? "CURRENT ADDRESS" : "OFFLINE SAFETY LOCATION",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB2A9C3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF342D42),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _coordinateText(),
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _accuracyText(),
                  style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "$_statusText • $_subText",
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 10,
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
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F6FB),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFE8E0F2),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "LIVE TRACKING TOKEN",
          style: GoogleFonts.poppins(
            color: const Color(0xFF9B7BE8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tokenController,
          decoration: InputDecoration(
            hintText: "Paste token from panic SMS",
            hintStyle: GoogleFonts.poppins(
              color: Colors.black38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isLoadingTokenLocation ? null : _loadLiveLocationFromToken,
          child: Container(
            height: 44,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF9B7BE8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isLoadingTokenLocation
                      ? Icons.hourglass_bottom_rounded
                      : Icons.location_searching_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoadingTokenLocation
                      ? "Loading Live Location..."
                      : "Load Live Location",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFA685F0),
              Color(0xFF8F6AE8),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B7BE8).withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLoading ? Icons.hourglass_bottom_rounded : Icons.near_me_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isLoading ? "Getting Location..." : "Update My Location",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(16),
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 450),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E0EE),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              _locationCard(),
const SizedBox(height: 14),
_liveTokenCard(),
const SizedBox(height: 14),
_primaryButton(),
const SizedBox(height: 10),
_actionButton(
  text: "Show Offline Saved Location",
                icon: Icons.offline_pin_rounded,
                backgroundColor: const Color(0xFFFFEFE2),
                textColor: const Color(0xFFFF9F43),
                onTap: _showOfflineSavedLocation,
              ),
              const SizedBox(height: 10),
              _actionButton(
                text: "Copy Location Info",
                icon: Icons.copy_rounded,
                backgroundColor: const Color(0xFFEAF7EF),
                textColor: const Color(0xFF37A66B),
                onTap: _copyLocationInfo,
              ),
              const SizedBox(height: 10),
              _actionButton(
                text: _isOnline ? "Center Online Map" : "Online Map Disabled",
                icon: Icons.map_rounded,
                backgroundColor:
                    _isOnline ? const Color(0xFFF0E9FF) : const Color(0xFFECECEC),
                textColor: _isOnline ? const Color(0xFF9B7BE8) : Colors.black38,
                onTap: _centerOnlineMap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F6FB),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6C627C),
          size: 16,
        ),
      ),
    );
  }
  @override
void dispose() {
  _tokenController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
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
      ..color = const Color(0xFFF4E8DA)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
