import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/user_card.dart';
import '../widgets/settings_card.dart';
import '../utils/profile_settings.dart';
import '../utils/supabase_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:provider/provider.dart';
import '../utils/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Host Name';
  String _email = 'host@email.com';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileSettings.getProfile();
      if (mounted) {
        setState(() {
          _name = profile['name'] ?? 'Host Name';
          _email = profile['email'] ?? 'host@email.com';
        });
      }
    } catch (e) {
      // Use default values if profile loading fails
      print('Error loading profile: $e');
    }
  }

  void _editUserInfo() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, [
                nameController.text,
                emailController.text,
              ]);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result is List && result.length == 2) {
      setState(() {
        _name = result[0];
        _email = result[1];
      });
      await ProfileSettings.saveProfile(_name, _email);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Log out: reset navigation to AuthGate or dashboard
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _pickAvatar() async {
    // Placeholder: In a real app, use image_picker or file_picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Avatar'),
        content: const Text('Avatar picker coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBookings({required bool asCsv}) async {
    try {
      final bookings = await SupabaseService.getBookings();
      if (bookings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No bookings to export.')),
          );
        }
        return;
      }
      String data;
      String fileType;
      if (asCsv) {
        fileType = 'csv';
        final header =
            'Guest,Room,CheckIn,CheckOut,Notes,DepositPaid,PaymentStatus';
        final rows = bookings
            .map(
              (b) =>
                  '"${b.guest.name}","${b.room.number}","${b.checkIn}","${b.checkOut}","${b.notes}",${b.depositPaid},${b.paymentStatus}',
            )
            .join('\n');
        data = '$header\n$rows';
      } else {
        fileType = 'json';
        data = jsonEncode(
          bookings
              .map(
                (b) => {
                  'guest': b.guest.name,
                  'room': b.room.number,
                  'checkIn': b.checkIn.toIso8601String(),
                  'checkOut': b.checkOut.toIso8601String(),
                  'notes': b.notes,
                  'depositPaid': b.depositPaid,
                  'paymentStatus': b.paymentStatus,
                },
              )
              .toList(),
        );
      }
      await Clipboard.setData(ClipboardData(text: data));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported as $fileType (copied to clipboard)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting bookings: $e')));
      }
    }
  }

  Future<void> _exportGuestPolicy() async {
    // Placeholder: In a real app, generate PDF or text from policy
    const policy =
        'Guest Policy: 1. Check-in after 2pm. 2. No smoking. 3. ID required.';
    await Clipboard.setData(const ClipboardData(text: policy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest policy copied to clipboard.')),
      );
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@lakshadweep.com',
      query: 'subject=Support Request',
    );
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileComplete = _name.isNotEmpty && _email.isNotEmpty;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: true);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF222B45),
                  ),
                ),
                const Spacer(),
                if (!profileComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Incomplete',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    child: _avatarPath == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: const Color(0xFF007AFF),
                          )
                        : null, // Placeholder for avatar image
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF007AFF),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            UserCard(name: _name, email: _email, onEdit: _editUserInfo),
            const SizedBox(height: 24),
            SettingsSectionCard(
              title: 'Backup & Export',
              icon: Icons.cloud_download_outlined,
              iconColor: const Color(0xFF7C3AED),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFF007AFF),
                  ),
                  title: Text(
                    'Export Bookings (CSV)',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: () => _exportBookings(asCsv: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFF007AFF),
                  ),
                  title: Text(
                    'Export Bookings (JSON)',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: () => _exportBookings(asCsv: false),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.policy_outlined,
                    color: Color(0xFF7C3AED),
                  ),
                  title: Text(
                    'Export Guest Policy (Text)',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: _exportGuestPolicy,
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Sync & Settings',
              icon: Icons.sync_outlined,
              iconColor: const Color(0xFF34D399),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: themeNotifier.themeMode == ThemeMode.light,
                  onChanged: (v) {
                    themeNotifier.setTheme(!v);
                    setState(() {});
                  },
                  title: Text('Light Mode', style: GoogleFonts.inter()),
                  activeColor: const Color(0xFF007AFF),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: null,
                  title: Text(
                    'Cloud Sync (Coming Soon)',
                    style: GoogleFonts.inter(),
                  ),
                  activeColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
            SettingsSectionCard(
              title: 'Support',
              icon: Icons.support_agent_outlined,
              iconColor: const Color(0xFFF59E42),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF007AFF),
                  ),
                  title: Text('Contact Support', style: GoogleFonts.inter()),
                  onTap: _contactSupport,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFFF43F5E)),
                  title: Text(
                    'Log Out',
                    style: GoogleFonts.inter(color: const Color(0xFFF43F5E)),
                  ),
                  onTap: _showLogoutDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(thickness: 1, color: Colors.grey[200]),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Text(
                    'Lakshadweep Guest App',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2025 Your Company',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
