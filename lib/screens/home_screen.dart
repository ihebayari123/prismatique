import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroSection(),
                    _sectionLabel('Live Feed', 'Recent Reports'),
                    _activeIssuesCard(),
                    _sectionLabel('Explore', 'Pollution Map'),
                    _mapPreview(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
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
              child: const Icon(Icons.eco, color: AppColors.green400, size: 18),
            ),
            const SizedBox(width: 8),
            Text('Tacape',
                style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green600)),
            const Spacer(),
            _iconBtn(Icons.search_rounded),
            const SizedBox(width: 4),
            _iconBtn(Icons.notifications_none_rounded),
          ],
        ),
      );

  Widget _iconBtn(IconData icon) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.muted),
      );

  Widget _heroSection() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.green50, AppColors.green50.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.green100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.green100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.green400, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('AI-Powered Environmental Platform',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: GoogleFonts.syne(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2),
                children: const [
                  TextSpan(text: 'Transform\nproblems into\n'),
                  TextSpan(
                      text: 'smart solutions',
                      style: TextStyle(color: AppColors.green500)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tacape connects citizens, communities, and investors to detect and solve environmental challenges.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _heroBtn('Report', true),
                const SizedBox(width: 10),
                _heroBtn('Map', false),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _stat('2,400+', 'Issues Reported'),
                  _statDivider(),
                  _stat('840+', 'Solutions'),
                  _statDivider(),
                  _stat('120+', 'Investors'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _heroBtn(String label, bool primary) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [AppColors.green400, AppColors.green600])
                : null,
            color: primary ? null : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: primary ? null : Border.all(color: AppColors.borderStrong),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      );

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green600)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.muted),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _statDivider() => Container(
      width: 1, height: 32, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _sectionLabel(String sub, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
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

  Widget _activeIssuesCard() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Issues',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                _chip('4 critical', AppColors.red),
              ],
            ),
            const SizedBox(height: 12),
            _issueItem('🏭', 'Industrial Emissions', 'Zone Industrielle Sud',
                'Critical', AppColors.red, '2h ago'),
            _issueItem('💧', 'Water Pollution', 'Gulf of Gabès', 'Moderate',
                AppColors.amber, '5h ago'),
            _issueItem('🗑️', 'Waste Dumping', 'Plage Nord', 'Resolved',
                AppColors.green400, '1d ago'),
          ],
        ),
      );

  Widget _issueItem(String emoji, String name, String loc, String status,
      Color statusColor, String time) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('📍 $loc',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chip(status, statusColor),
                const SizedBox(height: 3),
                Text(time,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.lightText)),
              ],
            ),
          ],
        ),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      );

  Widget _mapPreview(BuildContext context) => GestureDetector(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDE5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              // Grid pattern
              CustomPaint(
                  painter: _GridPainter(), size: const Size(double.infinity, 180)),
              // Pins
              _mapPin(0.35, 0.30, AppColors.red),
              _mapPin(0.55, 0.55, AppColors.amberLight),
              _mapPin(0.25, 0.65, AppColors.teal400),
              _mapPin(0.60, 0.20, AppColors.red),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 4)
                    ],
                  ),
                  child: Text('📍 Gabès, Tunisia',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.green400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('View Full Map →',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _mapPin(double top, double left, Color color) => Positioned.fill(
        child: FractionallySizedBox(
          alignment: Alignment(left * 2 - 1, top * 2 - 1),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 2)
              ],
            ),
          ),
        ),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
