import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final Color _notionPrimary = const Color(0xFF2F3437);
final Color _notionAccent = const Color(0xFF006EFF);
final Color _notionBackground = const Color(0xFFF7F7F8);
final Color _notionCard = const Color(0xFFFFFFFF);
final Color _notionTextPrimary = const Color(0xFF2F3437);
final Color _notionTextSecondary = const Color(0xFF6B7280);
final Color _notionDivider = const Color(0xFFE5E7EB);
final Color _notionNavBar = const Color(0xFFEAEFF3);

final ThemeData notionTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: _notionPrimary,
    secondary: _notionAccent,
    surface: _notionCard,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: _notionTextPrimary,
    outline: _notionDivider,
  ),
  scaffoldBackgroundColor: _notionBackground,
  cardTheme: CardThemeData(
    color: _notionCard,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    shadowColor: Colors.black.withOpacity(0.06),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: _notionCard,
    elevation: 0.5,
    iconTheme: IconThemeData(color: _notionPrimary),
    titleTextStyle: GoogleFonts.inter(
      color: _notionPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    centerTitle: true,
    shadowColor: Colors.black.withOpacity(0.04),
  ),
  dividerColor: _notionDivider,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    bodyLarge: GoogleFonts.inter(
      color: _notionTextPrimary,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.inter(
      color: _notionTextSecondary,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: GoogleFonts.inter(
      color: _notionTextPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      color: _notionTextPrimary,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.inter(
      color: _notionAccent,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _notionAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  iconTheme: IconThemeData(color: _notionTextSecondary, size: 22),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: _notionNavBar,
    selectedItemColor: _notionAccent,
    unselectedItemColor: _notionTextSecondary,
    selectedLabelStyle: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    unselectedLabelStyle: GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  useMaterial3: true,
);
