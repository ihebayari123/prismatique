import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _banner(context),
              _profileInfo(),
              _statsCard(),
              _sectionLabel('Achievements', 'Badges Earned'),
              _badgesRow(),
              _menuCard(context),
              _logoutCard(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.green50, Color(0x14000000)],
              ),
            ),
          ),
          // Avatar
          Positioned(
            bottom: -36,
            left: 20,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.green400, AppColors.teal600]),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: Text('AG',
                        style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.green400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
          // Settings btn
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 4)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined,
                      size: 15, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text('Settings',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _profileInfo() => Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ahmed Gharbi',
                      style: GoogleFonts.syne(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: AppColors.green400),
                      const SizedBox(width: 4),
                      Text('Gabès – Zone Nord',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.green100),
              ),
              child: Text('Edit Profile',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600)),
            ),
          ],
        ),
      );

  Widget _statsCard() => Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            _stat('47', 'Reports', AppColors.green600),
            _statDivider(),
            _stat('12', 'Projects', AppColors.amber),
            _statDivider(),
            _stat('890', 'Points', AppColors.teal400),
          ],
        ),
      );

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.syne(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.muted)),
          ],
        ),
      );

  Widget _statDivider() => Container(
      width: 1, height: 32, color: AppColors.border);

  Widget _sectionLabel(String sub, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.toUpperCase(),
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.green400)),
            Text(title,
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _badgesRow() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            _badge('🌿', 'Green Guardian', AppColors.teal400),
            const SizedBox(width: 8),
            _badge('💧', 'Water Keeper', AppColors.teal400),
            const SizedBox(width: 8),
            _badge('⭐', 'Top Reporter', AppColors.amber),
            const SizedBox(width: 8),
            _badge('❤️', 'Donor', AppColors.amber),
          ],
        ),
      );

  Widget _badge(String emoji, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 4)
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _menuCard(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            _menuItem(Icons.notifications_none_rounded, 'Notifications', null),
            _divider(),
            _menuItem(Icons.shield_outlined, 'Privacy & Data', null),
            _divider(),
            _menuItem(Icons.language_outlined, 'Language', 'العربية'),
            _divider(),
            _menuItem(Icons.info_outline_rounded, 'About Gabès App', null),
          ],
        ),
      );

  Widget _menuItem(IconData icon, String label, String? trailing) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.green100),
              ),
              child: Icon(icon, size: 16, color: AppColors.green500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            if (trailing != null)
              Text(trailing,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.muted)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.lightText),
          ],
        ),
      );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.border, indent: 16, endIndent: 16);

  Widget _logoutCard(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.red.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red.withOpacity(0.15)),
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 16, color: AppColors.red),
              ),
              const SizedBox(width: 12),
              Text('Sign Out',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red)),
            ],
          ),
        ),
      );
}
