import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingViewerScreen extends StatefulWidget {
  const LiveTrackingViewerScreen({super.key});

  @override
  State<LiveTrackingViewerScreen> createState() =>
      _LiveTrackingViewerScreenState();
}

class _LiveTrackingViewerScreenState extends State<LiveTrackingViewerScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _latestSession;

  @override
  void initState() {
    super.initState();
    _loadLatestLiveSession();
  }

  Future<void> _loadLatestLiveSession() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final session = await _supabase
          .from('panic_live_sessions')
          .select()
          .eq('user_id', user.id)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _latestSession = session;
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

  Future<void> _openInGoogleMaps() async {
    final locationLink = _latestSession?['last_location_link']?.toString();

    if (locationLink == null || locationLink.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No live location link found'),
        ),
      );
      return;
    }

    final uri = Uri.parse(locationLink);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      body: Stack(
        children: [
          Positioned(
            top: 95,
            right: -70,
            child: _trackingGlowBlob(
              color: const Color(0xFFFFB3A7),
              size: 230,
            ),
          ),
          Positioned(
            top: 390,
            left: -90,
            child: _trackingGlowBlob(
              color: const Color(0xFFFFD8B8),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -80,
            child: _trackingGlowBlob(
              color: const Color(0xFFFF9AA2),
              size: 210,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _circleButton(
                        icon: Icons.refresh_rounded,
                        onTap: _loadLatestLiveSession,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Live Tracking",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2B2733),
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EE),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFFFFC7BD),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              color: Color(0xFFFF5B6B),
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Latest emergency location",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFF5B6B),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "View the latest shared location from your panic alert session.",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8B7B78),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFF5B6B),
                    onRefresh: _loadLatestLiveSession,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
        children: [
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFFF5B6B),
                  strokeWidth: 2.4,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading live tracking...',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B7B78),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
        children: [
          _messageCard(
            icon: Icons.error_outline_rounded,
            title: 'Could not load live tracking',
            subtitle: _errorMessage!,
            iconColor: const Color(0xFFFF5B6B),
            buttonText: 'Try Again',
            onButtonTap: _loadLatestLiveSession,
          ),
        ],
      );
    }

    if (_latestSession == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
        children: [
          _messageCard(
            icon: Icons.location_off_rounded,
            title: 'No live session found',
            subtitle: 'Start panic mode to create live tracking data.',
            iconColor: const Color(0xFFFF5B6B),
            buttonText: 'Refresh',
            onButtonTap: _loadLatestLiveSession,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      children: [
        _trackingSessionCard(),
      ],
    );
  }

  Widget _trackingSessionCard() {
    final status = _latestSession?['status']?.toString() ?? 'No session';
    final latitude = _latestSession?['last_latitude']?.toString() ?? '--';
    final longitude = _latestSession?['last_longitude']?.toString() ?? '--';
    final updatedAtBd = _latestSession?['updated_at_bd']?.toString() ?? '--';
    final isActive = status.toLowerCase() == 'active';

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? const [
                            Color(0xFFE9FFF1),
                            Color(0xFFCFFFE2),
                          ]
                        : const [
                            Color(0xFFFFF0EC),
                            Color(0xFFFFC9C0),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A7A).withOpacity(0.13),
                      blurRadius: 16,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Icon(
                  isActive
                      ? Icons.my_location_rounded
                      : Icons.location_off_rounded,
                  color: isActive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFFF5B6B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? 'Live Tracking Active'
                          : 'Latest Tracking Session',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2B2733),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Your live location session is currently active.'
                          : 'Showing the latest saved location session.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B7B78),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE9FFF1)
                      : const Color(0xFFFFF1EE),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFBFEFD1)
                        : const Color(0xFFFFC7BD),
                  ),
                ),
                child: Text(
                  isActive ? 'Active' : 'Saved',
                  style: GoogleFonts.poppins(
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFFF5B6B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow(
            icon: Icons.circle_rounded,
            label: 'Status',
            value: status,
            iconColor:
                isActive ? const Color(0xFF2E7D32) : const Color(0xFFFF5B6B),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _coordinateTile(
                  label: 'Latitude',
                  value: latitude,
                  icon: Icons.north_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _coordinateTile(
                  label: 'Longitude',
                  value: longitude,
                  icon: Icons.east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.access_time_rounded,
            label: 'Last Updated BD',
            value: updatedAtBd,
            iconColor: const Color(0xFFFF5B6B),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _openInGoogleMaps,
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF385C),
                    Color(0xFFFF7A63),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D5E).withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Open Latest Location in Maps',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w800,
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

  Widget _coordinateTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF5B6B),
            size: 19,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF9A817C),
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2B2733),
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 17,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF9A817C),
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2B2733),
                fontSize: 12.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required String buttonText,
    required VoidCallback onButtonTap,
  }) {
    return _glassCard(
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF0EC),
                  Color(0xFFFFC9C0),
                ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 1.6,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2B2733),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B7B78),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onButtonTap,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF385C),
                    Color(0xFFFF7A63),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D5E).withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.96),
                const Color(0xFFFFF1EC).withOpacity(0.78),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.96),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A7A).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.75),
                blurRadius: 12,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _trackingGlowBlob({
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 80,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.86),
                  Colors.white.withOpacity(0.46),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A7A).withOpacity(0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7B6765),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}
