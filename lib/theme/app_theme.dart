import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const green50 = Color(0xFFF0F7E8);
  static const green100 = Color(0xFFD4EBBA);
  static const green200 = Color(0xFFAADA78);
  static const green400 = Color(0xFF5B9B1A);
  static const green500 = Color(0xFF4A820F);
  static const green600 = Color(0xFF3B6D11);
  static const green700 = Color(0xFF2C5409);
  static const teal400 = Color(0xFF1D9E75);
  static const teal600 = Color(0xFF0F6E56);
  static const bg = Color(0xFFFAFAF8);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A18);
  static const muted = Color(0xFF5F5E5A);
  static const lightText = Color(0xFF9E9D97);
  static const border = Color(0x14000000);
  static const borderStrong = Color(0x24000000);
  static const red = Color(0xFFE24B4A);
  static const amber = Color(0xFFBA7517);
  static const amberLight = Color(0xFFEF9F27);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green400),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      );
}
