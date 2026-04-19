import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/model_viewer_widget.dart';

class MaternalScreen extends StatefulWidget {
  const MaternalScreen({super.key});
  @override
  State<MaternalScreen> createState() => _MaternalScreenState();
}

class _MaternalScreenState extends State<MaternalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartbeat;
  int _selectedPlan = 1;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _heartbeat = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

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
                    _heroCard(),
                    _sectionLabel('Live Status', 'Your Safety Dashboard'),
                    _dashboardGrid(),
                    _sectionLabel('Subscription', 'Choose Your Plan'),
                    _planCard(0, 'Basic', 'Free', [
                      'Air quality alerts',
                      'Daily summary report',
                    ], AppColors.green500),
                    _planCard(1, 'Premium', '9 TND/mo', [
                      'Real-time gas alerts',
                      'Safe route planner',
                      'Doctor notifications',
                    ], AppColors.amber),
                    _subscribeBtn(),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Text(
                          'Data protected · Alerts certified by health authorities',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Text('Maternal Care',
                style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.amberLight, AppColors.amber]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('✓ ACTIVE',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _heroCard() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF5E8), Colors.white],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.amber.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('EXCLUSIVE SERVICE',
                        style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.red)),
                  ),
                  const SizedBox(height: 8),
                  Text('Protected\nMotherhood',
                      style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time pollution alerts & safe route planner — because every breath matters.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ScaleTransition(
              scale: _heartbeat,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B6B), Color(0xFFD4A017)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      );

  Widget _sectionLabel(String sub, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
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

  Widget _dashboardGrid() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _dashCard('💨', 'Air Quality', 'Moderate', 'AQI 142', AppColors.amber),
            _dashCard('📍', 'Your Zone', 'Safe', 'Zone Nord', AppColors.teal400),
            _dashCard('☁️', 'Gas Level', 'Normal', 'SO₂: 0.02 ppm', AppColors.teal400),
            _dashCard('🔔', 'Alerts Today', '1 Alert', '6:42 AM – Wind', AppColors.red),
          ],
        ),
      );

  Widget _dashCard(String emoji, String label, String value, String sub, Color valueColor) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.muted)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: valueColor)),
                const SizedBox(height: 2),
                Text(sub,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      );

  Widget _planCard(int idx, String name, String price, List<String> features, Color priceColor) {
    final selected = _selectedPlan == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.amber.withOpacity(0.4) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.amber.withOpacity(0.08),
                      blurRadius: 0,
                      spreadRadius: 3)
                ]
              : null,
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0x99FFF5E8), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.amberLight, AppColors.amber])
                    : null,
                border: selected
                    ? null
                    : Border.all(color: AppColors.borderStrong, width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name,
                          style: GoogleFonts.syne(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(price,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: priceColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check,
                              size: 12, color: AppColors.teal400),
                          const SizedBox(width: 6),
                          Text(f,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
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

  Widget _subscribeBtn() => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: GestureDetector(
          onTap: () => _showSubscribeDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.amberLight, AppColors.amber]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: AppColors.amber.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Subscribe — 9 TND/mo',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      );

  void _showSubscribeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Congratulations message
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.amberLight, AppColors.amber],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You\'re Subscribed!',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You good mother 💕',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your baby is now protected with real-time alerts & premium features',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 3D Baby Model
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green100, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ModelViewerWidget(
                    modelPath: 'sleeping-baby/source/model.glb',
                    backgroundColor: '#FFF5E8',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.green400, AppColors.green600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
