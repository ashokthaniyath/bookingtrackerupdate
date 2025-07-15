import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../utils/frontend_test_utils.dart';
import 'main_scaffold.dart';
// import '../services/google_auth_service.dart';

// Temporary stub for GoogleAuthService
class GoogleAuthService {
  static bool get isSignedIn => false;
  static String? get userEmail => 'demo@example.com';
  static String? get userDisplayName => 'Demo User';
  static String? get userPhotoUrl => null;
  static Future<bool> signIn() async => true;
  static Future<void> signOut() async {}
  static Future<void> disconnect() async {}
  static Future<Map<String, String>?> getAuthTokens() async => null;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSignedIn = false;
  bool _isSignUpMode = false;
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Profile data
  String _userName = 'Resort Manager';
  String _userEmail = 'manager@resort.com';
  final String _userRole = 'Administrator';

  @override
  void initState() {
    super.initState();

    // UI Enhancement: Initialize Fade Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Check Google Authentication status
    _checkGoogleAuthStatus();
  }

  void _checkGoogleAuthStatus() {
    setState(() {
      _isSignedIn = GoogleAuthService.isSignedIn;
      if (_isSignedIn) {
        _userName = GoogleAuthService.userDisplayName ?? 'Google User';
        _userEmail = GoogleAuthService.userEmail ?? 'google@example.com';
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    try {
      // Debug log for navigation tracking
      print("Navigating from profile page to index: $index");

      // Direct navigation to MainScaffold
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScaffold(initialIndex: index),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF87CEEB), // Sky blue
            Color(0xFFFFFFFF), // White
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            _isSignedIn ? 'Profile' : (_isSignUpMode ? 'Sign Up' : 'Sign In'),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSignedIn)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                onPressed: _editProfile,
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Profile refreshed!',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF14B8A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _isSignedIn ? _buildProfileView() : _buildAuthView(),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: -1, // Profile page doesn't map to main nav items
          onItemTapped: _onTabSelected,
        ),
      ),
    );
  }

  // UI Enhancement: Profile View for signed-in users
  Widget _buildProfileView() {
    return Column(
      children: [
        // Profile Header Card
        AnimationConfiguration.staggeredList(
          position: 0,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Name
                      Text(
                        _userName,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // User Email
                      Text(
                        _userEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // User Role
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _userRole,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Profile Options
        AnimationConfiguration.staggeredList(
          position: 1,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: _buildProfileOptions()),
          ),
        ),

        const SizedBox(height: 30),

        // Sign Out Button
        AnimationConfiguration.staggeredList(
          position: 2,
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: _buildSignOutButton()),
          ),
        ),

        // Bottom spacing for navigation bar
        const SizedBox(height: 100),
      ],
    );
  }

  // UI Enhancement: Authentication View for sign-in/sign-up
  Widget _buildAuthView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Auth Header Card
          AnimationConfiguration.staggeredList(
            position: 0,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        // Auth Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            _isSignUpMode ? Icons.person_add : Icons.login,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Auth Title
                        Text(
                          _isSignUpMode ? 'Create Account' : 'Welcome Back!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Auth Subtitle
                        Text(
                          _isSignUpMode
                              ? 'Join our resort management team'
                              : 'Sign in to manage your resort',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Auth Form
          AnimationConfiguration.staggeredList(
            position: 1,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: _buildAuthForm()),
            ),
          ),
        ],
      ),
    );
  }

  // UI Enhancement: Authentication Form
  Widget _buildAuthForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            // Name Field (Sign Up only)
            if (_isSignUpMode) ...[
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (_isSignUpMode && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            // Confirm Password Field (Sign Up only)
            if (_isSignUpMode) ...[
              const SizedBox(height: 20),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 30),

            // Auth Button
            _buildAuthButton(),

            const SizedBox(height: 20),

            // Google Sign-In Button
            _buildGoogleSignInButton(),

            const SizedBox(height: 20),

            // Toggle Auth Mode
            _buildAuthToggle(),

            const SizedBox(height: 20),

            // Firestore Test Button
            FrontendTestUtils.buildFirestoreTestButton(context),

            // Bottom spacing for navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Custom Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF14B8A6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFF43F5E)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  // UI Enhancement: Auth Button
  Widget _buildAuthButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isLoading ? null : _handleAuth,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSignUpMode ? Icons.person_add : Icons.login,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSignUpMode ? 'Create Account' : 'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // UI Enhancement: Auth Mode Toggle
  Widget _buildAuthToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUpMode
              ? 'Already have an account? '
              : 'Don\'t have an account? ',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSignUpMode = !_isSignUpMode;
              _clearForm();
            });
          },
          child: Text(
            _isSignUpMode ? 'Sign In' : 'Sign Up',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // UI Enhancement: Profile Options
  Widget _buildProfileOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileOption(
            Icons.person_outline,
            'Edit Profile',
            'Update your personal information',
            () => _editProfile(),
          ),
          _buildDivider(),
          _buildProfileOption(
            Icons.security,
            'Security',
            'Change password and security settings',
            () => _showSecurityDialog(),
          ),
          _buildDivider(),
          _buildProfileOption(
            Icons.notifications,
            'Notifications',
            'Manage your notification preferences',
            () => _showNotificationSettings(),
          ),
          _buildDivider(),
          _buildProfileOption(
            Icons.help_outline,
            'Help & Support',
            'Get help and contact support',
            () => _showHelpDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 20,
      endIndent: 20,
    );
  }

  // UI Enhancement: Sign Out Button
  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _signOut,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Modern Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
            ),
            child: Text(
              'Resort Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', '/dashboard'),
          _buildDrawerItem(Icons.bed_rounded, 'Rooms', '/rooms'),
          _buildDrawerItem(Icons.people_alt_rounded, 'Guest List', '/guests'),
          _buildDrawerItem(
            Icons.attach_money_rounded,
            'Sales / Payment',
            '/sales',
          ),
          _buildDrawerItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
          _buildDrawerItem(Icons.person_outline, 'Profile', '/profile'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  // Authentication Methods
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate authentication process
    await Future.delayed(const Duration(seconds: 2));

    if (_isSignUpMode) {
      await _signUp();
    } else {
      await _signIn();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    // Mock sign-in logic
    setState(() {
      _isSignedIn = true;
      _userEmail = _emailController.text;
    });

    _showSuccessSnackBar('Welcome back! You have successfully signed in.');
    _clearForm();
  }

  Future<void> _signUp() async {
    // Mock sign-up logic
    setState(() {
      _isSignedIn = true;
      _userName = _nameController.text;
      _userEmail = _emailController.text;
    });

    _showSuccessSnackBar(
      'Account created successfully! Welcome to Resort Manager.',
    );
    _clearForm();
  }

  void _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign out from Google if currently signed in
      if (GoogleAuthService.isSignedIn) {
        await GoogleAuthService.signOut();
      }

      setState(() {
        _isSignedIn = false;
        _isSignUpMode = false;
        _userName = 'Resort Manager';
        _userEmail = 'manager@resort.com';
      });

      _showSuccessSnackBar('You have been signed out successfully.');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-out failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _confirmPasswordController.clear();
  }

  void _editProfile() {
    _showEditProfileDialog();
  }

  // Dialog Methods
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = nameController.text;
                _userEmail = emailController.text;
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Profile updated successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() {
    _showInfoDialog(
      'Security Settings',
      'Security features will be implemented in future updates. This includes two-factor authentication, password change, and login history.',
    );
  }

  void _showNotificationSettings() {
    _showInfoDialog(
      'Notification Settings',
      'Notification preferences will be available in future updates. You will be able to customize email alerts, booking reminders, and system notifications.',
    );
  }

  void _showHelpDialog() {
    _showInfoDialog(
      'Help & Support',
      'For assistance, please contact our support team:\n\nEmail: support@resort.com\nPhone: +1 (555) 123-4567\n\nOffice Hours: Monday - Friday, 9 AM - 6 PM',
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF14B8A6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Google Sign-In Button
  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Logo placeholder (you can add a proper Google logo asset)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.g_mobiledata,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await GoogleAuthService.signIn();

      if (success) {
        setState(() {
          _isSignedIn = true;
          _userName = GoogleAuthService.userDisplayName ?? 'Google User';
          _userEmail = GoogleAuthService.userEmail ?? 'google@example.com';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully signed in with Google!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In was cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
