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
    final status = _latestSession?['status']?.toString() ?? 'No session';
    final latitude = _latestSession?['last_latitude']?.toString() ?? '--';
    final longitude = _latestSession?['last_longitude']?.toString() ?? '--';
    final updatedAtBd = _latestSession?['updated_at_bd']?.toString() ?? '--';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F5F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Live Tracking',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B2733),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadLatestLiveSession,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFFFF4D5E),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatestLiveSession,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _messageCard(
                icon: Icons.error_outline_rounded,
                title: 'Could not load live tracking',
                subtitle: _errorMessage!,
                color: const Color(0xFFFF4D5E),
              )
            else if (_latestSession == null)
              _messageCard(
                icon: Icons.location_off_rounded,
                title: 'No live session found',
                subtitle: 'Start panic mode to create live tracking data.',
                color: Colors.black45,
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: status == 'active'
                                ? const Color(0xFFE9FFF1)
                                : const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            status == 'active'
                                ? Icons.my_location_rounded
                                : Icons.location_off_rounded,
                            color: status == 'active'
                                ? const Color(0xFF2E7D32)
                                : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status == 'active'
                                ? 'Live Tracking Active'
                                : 'Latest Tracking Session',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2B2733),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _infoRow('Status', status),
                    _infoRow('Latitude', latitude),
                    _infoRow('Longitude', longitude),
                    _infoRow('Last Updated BD', updatedAtBd),

                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: _openInGoogleMaps,
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D5E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Open Latest Location in Maps',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2B2733),
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2B2733),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
