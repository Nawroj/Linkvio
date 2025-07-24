// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// Import the new change password page
import 'change_password_page.dart'; // <--- NEW IMPORT

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
      // You might want to navigate to a sign-in page after signing out
      // Example: Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => SignInPage()), (Route<dynamic> route) => false);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the border color based on your theme's primary color
    final Color borderColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ⭐ NEW: Change Password as a ListTile
                ListTile(
                  leading: Icon(Icons.lock_reset, color: Theme.of(context).iconTheme.color),
                  title: Text(
                    'Change Password',
                    style: TextStyle(
                      fontFamily: 'SourceSansPro',
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                    );
                  },
                ),
                Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]), // Add a divider for separation
                // You can add more settings options here later
              ],
            ),
          ),
          // ⭐ MOVE: Sign Out Button to the bottom
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _signOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: borderColor,
                  side: BorderSide(color: borderColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontFamily: 'SourceSansPro',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}