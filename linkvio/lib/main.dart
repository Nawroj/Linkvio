// main.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:http/http.dart' as http; // Added for http requests
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- NEW IMPORT

import 'amplifyconfiguration.dart';
import 'pages/home_page.dart';
import 'pages/resume_builder.dart';
import 'theme/app_theme.dart';

void main() async { // <--- MODIFIED: main is now async
  WidgetsFlutterBinding.ensureInitialized(); // <--- NEW: Ensure Flutter binding is initialized
  await dotenv.load(fileName: ".env"); // <--- NEW: Load environment variables from .env
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    final authPlugin = AmplifyAuthCognito();
    try {
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);

      // Optional splash delay for smooth startup
      await Future.delayed(const Duration(seconds: 2));
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }

    setState(() {
      _amplifyConfigured = true;
    });
  }

  // New function to check for existing resume data
  Future<bool> _doesUserHaveResumeData() async {
    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        return false; // User not signed in, can't have resume data
      }

      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        safePrint('ID token is null or empty, cannot check resume data.');
        return false;
      }

      // <--- IMPORTANT: Use your actual API Gateway Invoke URL for fetching resume
      // final apiUrl = 'https://njdf4mnhdc.execute-api.ap-southeast-2.amazonaws.com/dev/resume'; // <--- REMOVED
      final apiUrl = '${dotenv.env['API_BASE_URL']!}/resume'; // <--- NEW: Use dotenv for API_BASE_URL

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!,
        },
      );

      // If status code is 200, it means data exists. If 404, it means no data.
      return response.statusCode == 200;
    } on AuthException catch (e) {
      safePrint('Authentication error checking resume: ${e.message}');
      return false;
    } catch (e) {
      safePrint('Error checking resume data: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define your base theme with SourceSansPro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseTheme = AppTheme.lightTheme; // AppTheme already sets fontFamily
    final darkTheme = AppTheme.darkTheme; // Access the new dark theme

    // Show splash screen until Amplify configured
    if (!_amplifyConfigured) {
      return MaterialApp(
        theme: baseTheme,
        darkTheme: darkTheme, // ⭐ NEW: Set darkTheme
        themeMode: ThemeMode.system, // ⭐ NEW: Use system theme mode
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Image.asset(
              isDarkMode ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
              width: 180,
              height: 180,
            ),
          ),
        ),
      );
    }

    // Once Amplify configured, show Authenticator
    return Authenticator(
      authenticatorBuilder: (context, state) {
        // Your existing authenticatorBuilder logic remains the same
        switch (state.currentStep) {
          case AuthenticatorStep.signIn:
            return _AuthCard(
              title: 'Sign In',
              body: SignInForm(),
              footerText: "Don't have an account?",
              footerButtonText: "Create Account",
              onFooterPressed: () => state.changeStep(AuthenticatorStep.signUp),
            );
          case AuthenticatorStep.signUp:
            return _AuthCard(
              title: 'Create Account',
              body: SignUpForm(),
              footerText: "Already have an account?",
              footerButtonText: "Sign In",
              onFooterPressed: () => state.changeStep(AuthenticatorStep.signIn),
            );
          case AuthenticatorStep.confirmSignUp:
            return _AuthCard(
              title: 'Confirm Sign Up',
              body:  ConfirmSignUpForm(),
            );
          case AuthenticatorStep.resetPassword:
            return _AuthCard(
              title: 'Reset Password',
              body:  ResetPasswordForm(),
            );
          case AuthenticatorStep.confirmResetPassword:
            return _AuthCard(
              title: 'Confirm Reset Password',
              body: const ConfirmResetPasswordForm(),
            );
          default:
            return null; // fallback to default Authenticator UI for other steps
        }
      },
      child: FutureBuilder<bool>(
        future: _doesUserHaveResumeData(), // Check for resume data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking for data
            return MaterialApp(
              theme: baseTheme,
              darkTheme: darkTheme, // ⭐ NEW: Set darkTheme
              themeMode: ThemeMode.system, // ⭐ NEW: Use system theme mode
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            // Handle error case
            return MaterialApp(
              theme: baseTheme,
              darkTheme: darkTheme, // ⭐ NEW: Set darkTheme
              themeMode: ThemeMode.system, // ⭐ NEW: Use system theme mode
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Text('Error: ${snapshot.error}'),
                ),
              ),
            );
          } else {
            final hasResume = snapshot.data ?? false;
            return MaterialApp(
              theme: baseTheme,
              darkTheme: darkTheme, // ⭐ NEW: Set darkTheme
              themeMode: ThemeMode.system, // ⭐ NEW: Use system theme mode
              debugShowCheckedModeBanner: false,
              builder: Authenticator.builder(), // Keep Authenticator.builder
              home: hasResume ? const HomePage() : const ResumeBuilder(), // Conditional navigation
            );
          }
        },
      ),
    );
  }
}

/// A reusable card widget for Authenticator screens
class _AuthCard extends StatelessWidget {
  final String title;
  final Widget body;
  final String? footerText;
  final String? footerButtonText;
  final VoidCallback? onFooterPressed;

  const _AuthCard({
    required this.title,
    required this.body,
    this.footerText,
    this.footerButtonText,
    this.onFooterPressed,
  });

  @override
Widget build(BuildContext context) {
  // Access the current theme's colors
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;

  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme's background color
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: cardColor, // Set card color based on theme
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    isDarkMode ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: textColor), // Apply text color
                  ),
                  const SizedBox(height: 24),
                  body,
                  if (footerText != null && footerButtonText != null && onFooterPressed != null) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(footerText!, style: TextStyle(color: textColor)), // Apply text color
                        TextButton(
                          onPressed: onFooterPressed,
                          child: Text(footerButtonText!),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
