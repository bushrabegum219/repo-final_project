import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EvidenceVaultScreen extends StatelessWidget {
  const EvidenceVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TOP BAR
                    Row(
                      children: [
                        _circleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 6,
                                width: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9B75F0),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Syncing",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9B75F0),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// TITLE
                    Row(
                      children: [
                        Text(
                          "Secure Vault",
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFF2D2638),
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "🔐",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      "Your private evidence is encrypted and safe.",
                      style: GoogleFonts.poppins(
                        color: Colors.black45,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// STORAGE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statItem(
                              title: "Storage Used",
                              value: "2.4 GB",
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: const Color(0xFFF0ECF7),
                          ),
                          Expanded(
                            child: _statItem(
                              title: "Total Items",
                              value: "142",
                            ),
                          ),
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1E9FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF9B75F0),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// TABS
                    Row(
                      children: [
                        _tabButton("All Files", true),
                        const SizedBox(width: 10),
                        _tabButton("Images", false),
                        const SizedBox(width: 10),
                        _tabButton("Documents", false),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /// GRID
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.78,
                      children: [
                        _evidenceCard(
                          isImage: true,
                          imageColor1: const Color(0xFF2F4A59),
                          imageColor2: const Color(0xFF0F1C24),
                          icon: Icons.image_rounded,
                          title: "Incident_01.jpg",
                          time: "Today, 10:32 AM",
                          topIcon: Icons.lock_rounded,
                        ),
                        _evidenceCard(
                          isImage: false,
                          fileIcon: Icons.description_rounded,
                          fileIconColor: const Color(0xFFB699F6),
                          title: "Police_Report.pdf",
                          time: "Yesterday, 4:15 PM",
                          topIcon: Icons.lock_rounded,
                        ),
                        _evidenceCard(
                          isImage: true,
                          imageColor1: const Color(0xFFB46748),
                          imageColor2: const Color(0xFF2F2A34),
                          icon: Icons.image_rounded,
                          title: "Location_Shot.jpg",
                          time: "Oct 12, 2024",
                          topIcon: Icons.lock_rounded,
                        ),
                        _evidenceCard(
                          isImage: false,
                          fileIcon: Icons.mic_rounded,
                          fileIconColor: const Color(0xFFB699F6),
                          title: "Audio_Record_1...",
                          time: "Oct 11, 2024",
                          topIcon: Icons.lock_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            /// UPLOAD BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Upload Evidence clicked"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFA684F1),
                        Color(0xFF8D63E6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9A70EE).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Upload Evidence",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black45,
          size: 16,
        ),
      ),
    );
  }

  Widget _statItem({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFFB1A8C3),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: const Color(0xFF2F2940),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0E7FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: selected ? const Color(0xFF9A70EE) : Colors.black38,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _evidenceCard({
    required bool isImage,
    Color? imageColor1,
    Color? imageColor2,
    IconData? icon,
    IconData? fileIcon,
    Color? fileIconColor,
    required String title,
    required String time,
    required IconData topIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PREVIEW
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isImage ? null : const Color(0xFFF3EEFB),
                    gradient: isImage
                        ? LinearGradient(
                            colors: [
                              imageColor1 ?? const Color(0xFF6E7D88),
                              imageColor2 ?? const Color(0xFF27313A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isImage
                      ? Center(
                          child: Icon(
                            icon ?? Icons.image_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 34,
                          ),
                        )
                      : Center(
                          child: Icon(
                            fileIcon ?? Icons.insert_drive_file_rounded,
                            color: fileIconColor ?? const Color(0xFFB699F6),
                            size: 34,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    height: 23,
                    width: 23,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      topIcon,
                      size: 12,
                      color: const Color(0xFF9B75F0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF342D42),
              fontSize: 11.3,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            time,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.black.withOpacity(0.35),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}