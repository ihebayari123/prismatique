import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _spinCtrl;
  late AnimationController _loadCtrl;
  late Animation<double> _pulse;
  late Animation<double> _spin;
  late Animation<double> _load;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _loadCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _spin = Tween<double>(begin: 0, end: 1).animate(_spinCtrl);
    _load = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 50),
    ]).animate(_loadCtrl);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Radial gradients
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.green400.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Spinning rings
          AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => Transform.rotate(
              angle: _spin.value * 2 * 3.14159,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.green400.withOpacity(0.12), width: 1),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => Transform.rotate(
              angle: -_spin.value * 2 * 3.14159 * 1.5,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.teal400.withOpacity(0.10), width: 1),
                ),
              ),
            ),
          ),
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.green400, AppColors.green600],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.green400.withOpacity(0.08),
                          blurRadius: 0,
                          spreadRadius: 12),
                      BoxShadow(
                          color: AppColors.green400.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'GABÈS',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SMART CITY',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 5,
                  color: AppColors.green400,
                ),
              ),
              const SizedBox(height: 14),
              // Animated line
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 80 + (_pulse.value - 1) * 400,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      AppColors.green400,
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Text(
                'Rebuilding the Pearl of the Gulf',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              // Progress bar
              Container(
                width: 120,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedBuilder(
                  animation: _load,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _load.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
