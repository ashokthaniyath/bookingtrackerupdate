import 'package:flutter/material.dart';
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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    if (GoogleAuthService.isSignedIn) {
      setState(() {
        _statusMessage = 'Already signed in as ${GoogleAuthService.userEmail}';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in...';
    });

    try {
      final bool success = await GoogleAuthService.signIn();

      if (success) {
        setState(() {
          _statusMessage =
              'Successfully signed in as ${GoogleAuthService.userEmail}';
        });

        // Navigate to main app or show success
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _statusMessage = 'Sign-in was cancelled or failed';
        });
      }
    } catch (error) {
      setState(() {
        _statusMessage = 'Sign-in failed: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });

    try {
      await GoogleAuthService.signOut();
      setState(() {
        _statusMessage = 'Signed out successfully';
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Sign-out failed: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo or Icon
            const Icon(Icons.account_circle, size: 100, color: Colors.blue),
            const SizedBox(height: 32),

            // App Title
            Text(
              'Booking Tracker',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Sign in to sync your bookings across devices',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.blue.shade700),
                  textAlign: TextAlign.center,
                ),
              ),

            // Sign In/Out Buttons
            if (!GoogleAuthService.isSignedIn) ...[
              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset(
                        'assets/google_logo.png', // You can add this asset or use an icon
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login, size: 20),
                      ),
                label: Text(
                  _isLoading ? 'Signing in...' : 'Sign in with Google',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Continue as Guest Button
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                child: const Text('Continue as Guest'),
              ),
            ] else ...[
              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (GoogleAuthService.userPhotoUrl != null)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            GoogleAuthService.userPhotoUrl!,
                          ),
                        )
                      else
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        GoogleAuthService.userDisplayName ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GoogleAuthService.userEmail ?? 'No email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Continue to App Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                child: const Text('Continue to App'),
              ),
              const SizedBox(height: 8),

              // Sign Out Button
              TextButton(
                onPressed: _isLoading ? null : _signOut,
                child: Text(_isLoading ? 'Signing out...' : 'Sign Out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
