import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.green50, Colors.white],
                    stops: [0, 0.6],
                  ),
                  border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GABÈS',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SMART CITY · TUNISIA',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: AppColors.green400,
                      ),
                    ),
                  ],
                ),
              ),
              // Tab switcher
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _tab('Sign In', _isSignIn, () => setState(() => _isSignIn = true)),
                      _tab('Create Account', !_isSignIn, () => setState(() => _isSignIn = false)),
                    ],
                  ),
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.all(20),
                child: _isSignIn ? _signInForm() : _registerForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.green400 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: AppColors.green400.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _signInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Email Address'),
        _input('ahmed@gabes.tn', false),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        _input('••••••••', true),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Forgot password?',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.green500,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        _primaryBtn('Enter Gabès', _enter),
        _orDivider(),
        _socialBtns(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Full Name'),
        _input('Ahmed Gharbi', false),
        const SizedBox(height: 16),
        _fieldLabel('Email Address'),
        _input('ahmed@gabes.tn', false),
        const SizedBox(height: 16),
        _fieldLabel('Password'),
        _input('••••••••', true),
        const SizedBox(height: 20),
        _primaryBtn('Join the Community', _enter),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06 * 10,
            color: AppColors.muted,
          ),
        ),
      );

  Widget _input(String hint, bool obscure) => Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: AppColors.lightText),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.green400, width: 1.5),
            ),
          ),
        ),
      );

  Widget _primaryBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.green400, AppColors.green600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppColors.green400.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );

  Widget _orDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderStrong)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.lightText, letterSpacing: 0.5)),
            ),
            const Expanded(child: Divider(color: AppColors.borderStrong)),
          ],
        ),
      );

  Widget _socialBtns() => Row(
        children: [
          _socialBtn('Google', Icons.g_mobiledata),
          const SizedBox(width: 10),
          _socialBtn('Apple', Icons.apple),
        ],
      );

  Widget _socialBtn(String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
}
