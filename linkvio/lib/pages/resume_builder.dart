// pages/resume_builder.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'home_page.dart'; // Assuming HomePage is where you navigate after sign out


class ResumeBuilder extends StatefulWidget {
  const ResumeBuilder({super.key});

  @override
  State<ResumeBuilder> createState() => _ResumeBuilderState();
}

class EducationEntry {
  String degree;
  String university;
  String graduationDate;
  String major;
  String coursework;

  EducationEntry({
    this.degree = '',
    this.university = '',
    this.graduationDate = '',
    this.major = '',
    this.coursework = '',
  });
}

class CertificateEntry {
  String name;
  String date;
  String coursework;

  CertificateEntry({
    this.name = '',
    this.date = '',
    this.coursework = '',
  });
}

class ExperienceEntry {
  String jobTitle;
  String company;
  String location;
  String startDate;
  String endDate;
  String responsibilities;

  ExperienceEntry({
    this.jobTitle = '',
    this.company = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.responsibilities = '',
  });
}

class ProjectEntry {
  String name;
  String link;
  String description;

  ProjectEntry({
    this.name = '',
    this.link = '',
    this.description = '',
  });
}

class _ResumeBuilderState extends State<ResumeBuilder> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Personal Info
  final _formKeyStep1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();


  // Step 2: Professional Summary
  final _formKeyStep2 = GlobalKey<FormState>();
  final _summaryController = TextEditingController();

  // Step 3: Education & Certificates (combined into one page)
  final _formKeyStep3 = GlobalKey<FormState>();
  List<EducationEntry> educationList = [EducationEntry()];
  List<CertificateEntry> certificateList = [CertificateEntry()];

  // Step 4: Experience (multiple entries)
  final _formKeyStep4 = GlobalKey<FormState>();
  List<ExperienceEntry> experienceList = [ExperienceEntry()];

  // Step 5: Skills
  final _formKeyStep5 = GlobalKey<FormState>();
  final _technicalSkillsController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _languagesController = TextEditingController();

  // Step 6: Projects (new final step)
  final _formKeyStep6 = GlobalKey<FormState>();
  List<ProjectEntry> projectList = [ProjectEntry()];

  // Define total number of steps
  static const int _totalSteps = 6; // Personal Info (0) to Projects (5)

  @override
  void dispose() {
    _pageController.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _addressController.dispose();
    _websiteController.dispose();


    _summaryController.dispose();

    _technicalSkillsController.dispose();
    _softSkillsController.dispose();
    _languagesController.dispose();

    super.dispose();
  }

  // ⭐ NEW: Sign out function for the AppBar button
  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
      // Navigate to HomePage after signing out, clearing the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()), // Assuming HomePage is accessible after sign-out
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.message}')),
      );
    }
  }

  void _nextPage() {
    // Logic for validation and page transition
    // The last step is _totalSteps - 1 (which is 5 for Projects)
    if (_currentPage < _totalSteps - 1) {
      switch (_currentPage) {
        case 0: // Personal Info
          if (_formKeyStep1.currentState!.validate()) _goToNextPage();
          break;
        case 1: // Professional Summary
          if (_formKeyStep2.currentState!.validate()) _goToNextPage();
          break;
        case 2: // Education & Certificates (Combined Step)
          if (_formKeyStep3.currentState!.validate()) _goToNextPage();
          break;
        case 3: // Experience
          if (_formKeyStep4.currentState!.validate()) _goToNextPage();
          break;
        case 4: // Skills
          if (_formKeyStep5.currentState!.validate()) _goToNextPage();
          break;
        case 5: // Projects (This is the new last data entry step)
          if (_formKeyStep6.currentState!.validate()) _submitResume(); // Submit from Projects page
          break;
      }
    } else {
      // If we are already on the last step (_totalSteps - 1, which is 5 for Projects),
      // then calling _nextPage means we want to submit.
      if (_formKeyStep6.currentState!.validate()) _submitResume();
    }
  }


  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  // _printCollectedData is for debugging and no longer tied to a final review page
  void _printCollectedData() {
    final personalInfo = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'linkedin': _linkedinController.text.trim(),
    };
    final summary = _summaryController.text.trim();

    final educationData = educationList.map((e) => {
          'degree': e.degree,
          'university': e.university,
          'graduationDate': e.graduationDate,
          'major': e.major,
          'coursework': e.coursework,
        }).toList();

    final certificateData = certificateList.map((e) => {
          'name': e.name,
          'date': e.date,
          'coursework': e.coursework,
        }).toList();

    final experienceData = experienceList.map((e) => {
          'jobTitle': e.jobTitle,
          'company': e.company,
          'location': e.location,
          'startDate': e.startDate,
          'endDate': e.endDate,
          'responsibilities': e.responsibilities,
        }).toList();

    final skillsData = {
      'technicalSkills': _technicalSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'softSkills': _softSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'languages': _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    };

    final projectData = projectList.map((p) => {
      'name': p.name,
      'link': p.link,
      'description': p.description,
    }).toList();

    safePrint('Personal Info: $personalInfo');
    safePrint('Professional Summary: $summary');
    safePrint('Education: $educationData');
    safePrint('Certificates: $certificateData');
    safePrint('Experience: $experienceData');
    safePrint('Skills: $skillsData');
    safePrint('Projects: $projectData');
  }


  Future<void> _submitResume() async {
  try {
    final userSession = await Amplify.Auth.fetchAuthSession();

    if (!userSession.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not signed in')),
      );
      return;
    }

    final cognitoSession = userSession as CognitoAuthSession;
    final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

    if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get user token')),
      );
      return;
    }

    // Prepare resume data
    final resumeData = {
      'personalInfo': {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'address': _addressController.text.trim(),
        'website': _websiteController.text.trim(),
      },
      'summary': _summaryController.text.trim(),
      'education': educationList.map((e) => {
        'degree': e.degree.trim(),
        'university': e.university.trim(),
        'graduationDate': e.graduationDate.trim(),
        'major': e.major.trim(),
        'coursework': e.coursework.trim(),
      }).toList(),
      'certificates': certificateList.map((e) => {
        'name': e.name.trim(),
        'date': e.date.trim(),
        'coursework': e.coursework.trim(),
      }).toList(),
      'experience': experienceList.map((e) => {
        'jobTitle': e.jobTitle.trim(),
        'company': e.company.trim(),
        'location': e.location.trim(),
        'startDate': e.startDate.trim(),
        'endDate': e.endDate.trim(),
        'responsibilities': e.responsibilities.trim(),
      }).toList(),
      'skills': {
        'technicalSkills': _technicalSkillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'softSkills': _softSkillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'languages': _languagesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      },
      'projects': projectList.map((p) => {
        'name': p.name.trim(),
        'link': p.link.trim(),
        'description': p.description.trim(),
      }).toList(),
    };

    final apiUrl = 'https://njdf4mnhdc.execute-api.ap-southeast-2.amazonaws.com/dev/resume';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': idToken.raw!,
      },
      body: jsonEncode(resumeData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume submitted successfully! 🎉')),
      );
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false, // This clears all previous routes
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: ${response.statusCode} - ${response.body}')),
      );
    }
  } on AuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Authentication error: ${e.message}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


  @override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).primaryColor;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
  final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.grey.shade100;

  return GestureDetector( // Wrap with GestureDetector
    onTap: () {
      FocusScope.of(context).unfocus(); // Dismiss the keyboard
    },
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Use theme color
        iconTheme: Theme.of(context).appBarTheme.iconTheme, // Use theme icon color
        centerTitle: true,
        title: Image.asset(
          'assets/images/linkvio.png',
          height: 30,
          color: isDarkMode ? Colors.white : null, // Invert logo color for dark mode if it's black by default
          colorBlendMode: isDarkMode ? BlendMode.srcIn : null, // Apply blend mode
        ),
        // ⭐ NEW: Add actions property for the sign out button
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).appBarTheme.iconTheme?.color), // Use themed icon color
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Build Your Resume - Step ${_currentPage + 1} of $_totalSteps', // Updated step count
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalInfoStep(),
                _buildProfessionalSummaryStep(),
                _buildEducationAndCertificatesStep(),
                _buildExperienceStep(),
                _buildSkillsStep(),
                _buildProjectsStep(), // Last content page
                // Removed _buildReviewStep()
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.transparent, // Always transparent, background is scaffold's
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _prevPage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: const CircleBorder(),
                  backgroundColor: primaryColor, // Use theme's primary color
                  foregroundColor: Colors.white, // White icon/text on button
                  elevation: 2,
                ),
                child: const Icon(Icons.arrow_back),
              )
            else
              const SizedBox(width: 56),

            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(14),
                shape: const CircleBorder(),
                backgroundColor: primaryColor, // Use theme's primary color
                foregroundColor: Colors.white, // White icon/text on button
                elevation: 2,
              ),
              // Change icon to 'check' on the final step (Projects page)
              child: Icon(_currentPage == _totalSteps -1 ? Icons.check : Icons.arrow_forward),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildPersonalInfoStep() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inputFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final iconColor = isDarkMode ? Colors.white70 : null;


  final inputDecoration = InputDecoration(
    filled: true,
    fillColor: inputFillColor, // Themed fill color
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
    prefixIconColor: iconColor, // Themed prefix icon color
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Form(
      key: _formKeyStep1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Please enter your name' : null,
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: inputDecoration.copyWith(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your email';
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(val)) return 'Enter a valid email';
                return null;
              },
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              decoration: inputDecoration.copyWith(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Please enter your phone number' : null,
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _linkedinController,
              decoration: inputDecoration.copyWith(
                labelText: 'LinkedIn URL (optional)',
                prefixIcon: const Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  final urlRegex = RegExp(r'^https?://');
                  if (!urlRegex.hasMatch(val)) return 'Enter a valid URL';
                }
                return null;
              },
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _githubController,
              decoration: inputDecoration.copyWith(
                labelText: 'GitHub URL (optional)',
                prefixIcon: const Icon(Icons.code),
              ),
              keyboardType: TextInputType.url,
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  final urlRegex = RegExp(r'^https?://');
                  if (!urlRegex.hasMatch(val)) return 'Enter a valid URL';
                }
                return null;
              },
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _addressController,
              decoration: inputDecoration.copyWith(
                labelText: 'Address (optional)',
                prefixIcon: const Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.streetAddress,
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _websiteController,
              decoration: inputDecoration.copyWith(
                labelText: 'Website URL (optional)',
                prefixIcon: const Icon(Icons.web),
              ),
              keyboardType: TextInputType.url,
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  final urlRegex = RegExp(r'^https?://');
                  if (!urlRegex.hasMatch(val)) return 'Enter a valid URL';
                }
                return null;
              },
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}



  Widget _buildProfessionalSummaryStep() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inputFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final iconColor = isDarkMode ? Colors.white70 : null;

  final inputDecoration = InputDecoration(
    labelText: 'Professional Summary / Objective',
    alignLabelWithHint: true,
    filled: true,
    fillColor: inputFillColor, // Themed fill color
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
    prefixIconColor: iconColor, // Themed prefix icon color
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Form(
      key: _formKeyStep2,
      child: Column( // This is the Column that is overflowing
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor, // Themed text color
            ),
          ),
          const SizedBox(height: 24),
          // ⭐ FIX: Wrap the TextFormField in an Expanded widget
          Expanded( // Allows the TextFormField to take available height in the Column
            child: TextFormField(
              controller: _summaryController,
              decoration: inputDecoration,
              maxLines: null, // Set maxLines to null to allow infinite lines (scrollable internally)
              keyboardType: TextInputType.multiline, // Ensure multiline input
              validator: (val) =>
                  val == null || val.isEmpty ? 'Please enter a summary' : null,
              style: TextStyle(color: textColor), // Themed text input
            ),
          ),
        ],
      ),
    ),
  );
}

// Combined Education and Certificates Step
  Widget _buildEducationAndCertificatesStep() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
  final iconColor = isDarkMode ? Colors.white70 : null;


  final inputDecoration = InputDecoration(
    filled: true,
    fillColor: inputFillColor, // Themed fill color
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
    prefixIconColor: iconColor, // Themed prefix icon color
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Form(
      key: _formKeyStep3,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Education Section
            Text(
              'Education',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
            const SizedBox(height: 24),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: educationList.length,
              itemBuilder: (context, index) {
                final edu = educationList[index];
                final TextEditingController graduationDateController =
                    TextEditingController(text: edu.graduationDate);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: cardColor, // Themed card color
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: edu.degree,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Degree',
                            prefixIcon: const Icon(Icons.school),
                          ),
                          onChanged: (val) => edu.degree = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter degree' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: edu.university,
                          decoration: inputDecoration.copyWith(
                            labelText: 'University',
                            prefixIcon: const Icon(Icons.location_city),
                          ),
                          onChanged: (val) => edu.university = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter university' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: edu.major,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Major (Optional)',
                            prefixIcon: const Icon(Icons.book),
                          ),
                          onChanged: (val) => edu.major = val,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: graduationDateController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Graduation Date',
                            hintText: 'e.g. June 2023',
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            await _selectDate(context, (selectedDate) {
                              setState(() {
                                edu.graduationDate = selectedDate;
                                graduationDateController.text = selectedDate;
                              });
                            }, edu.graduationDate);
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Please enter graduation date' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: edu.coursework,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Relevant Coursework (optional, comma-separated)',
                            prefixIcon: const Icon(Icons.list_alt),
                          ),
                          onChanged: (val) => edu.coursework = val,
                          maxLines: 3,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                educationList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  educationList.add(EducationEntry());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00b09b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 40),

            // Certificates Section
            Text(
              'Certificates',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
            const SizedBox(height: 24),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: certificateList.length,
              itemBuilder: (context, index) {
                final cert = certificateList[index];
                final TextEditingController certificateDateController =
                    TextEditingController(text: cert.date);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: cardColor, // Themed card color
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: cert.name,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Certificate Name',
                            prefixIcon: const Icon(Icons.workspace_premium),
                          ),
                          onChanged: (val) => cert.name = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter certificate name' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: certificateDateController,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Date Issued / Completed',
                            hintText: 'e.g. March 2024',
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            await _selectDate(context, (selectedDate) {
                              setState(() {
                                cert.date = selectedDate;
                                certificateDateController.text = selectedDate;
                              });
                            }, cert.date);
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Please enter date' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: cert.coursework,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Coursework / Key Learnings (optional, comma-separated)',
                            prefixIcon: const Icon(Icons.list_alt),
                          ),
                          onChanged: (val) => cert.coursework = val,
                          maxLines: 3,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                certificateList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  certificateList.add(CertificateEntry());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00b09b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}



  Widget _buildExperienceStep() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
  final iconColor = isDarkMode ? Colors.white70 : null;


  final inputDecoration = InputDecoration(
    filled: true,
    fillColor: inputFillColor, // Themed fill color
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
    prefixIconColor: iconColor, // Themed prefix icon color
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Form(
      key: _formKeyStep4,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: experienceList.length,
              itemBuilder: (context, index) {
                final exp = experienceList[index];
                final TextEditingController startDateController =
                    TextEditingController(text: exp.startDate);
                final TextEditingController endDateController =
                    TextEditingController(text: exp.endDate);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: cardColor, // Themed card color
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: exp.jobTitle,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Job Title',
                            prefixIcon: const Icon(Icons.work),
                          ),
                          onChanged: (val) => exp.jobTitle = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter job title' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: exp.company,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Company',
                            prefixIcon: const Icon(Icons.business),
                          ),
                          onChanged: (val) => exp.company = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter company' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: exp.location,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Location',
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          onChanged: (val) => exp.location = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter location' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: startDateController,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Start Date',
                                  hintText: 'e.g. Jan 2020',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  await _selectDate(context, (selectedDate) {
                                    setState(() {
                                      exp.startDate = selectedDate;
                                      startDateController.text = selectedDate;
                                    });
                                  }, exp.startDate);
                                },
                                validator: (val) => val == null || val.isEmpty ? 'Enter start date' : null,
                                style: TextStyle(color: textColor), // Themed text input
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: endDateController,
                                decoration: inputDecoration.copyWith(
                                  labelText: 'End Date',
                                  hintText: 'e.g. Dec 2022 or Present',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  await _selectDate(context, (selectedDate) {
                                    setState(() {
                                      exp.endDate = selectedDate;
                                      endDateController.text = selectedDate;
                                    });
                                  }, exp.endDate);
                                },
                                validator: (val) => val == null || val.isEmpty ? 'Enter end date' : null,
                                style: TextStyle(color: textColor), // Themed text input
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: exp.responsibilities,
                          decoration: inputDecoration.copyWith(
                            labelText: 'Responsibilities / Bullet Points',
                            prefixIcon: const Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          onChanged: (val) => exp.responsibilities = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter responsibilities' : null,
                          style: TextStyle(color: textColor), // Themed text input
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                experienceList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  experienceList.add(ExperienceEntry());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Experience'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00b09b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSkillsStep() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final inputFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final iconColor = isDarkMode ? Colors.white70 : null;

  final inputDecoration = InputDecoration(
    filled: true,
    fillColor: inputFillColor, // Themed fill color
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
    prefixIconColor: iconColor, // Themed prefix icon color
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Form(
      key: _formKeyStep5,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills (comma separated)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // Themed text color
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _technicalSkillsController,
              decoration: inputDecoration.copyWith(
                labelText: 'Technical Skills (optional)',
                hintText: 'e.g. Python, Flutter, AWS',
                prefixIcon: const Icon(Icons.code),
              ),
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _softSkillsController,
              decoration: inputDecoration.copyWith(
                labelText: 'Soft Skills (optional)',
                hintText: 'e.g. Communication, Teamwork',
                prefixIcon: const Icon(Icons.people),
              ),
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _languagesController,
              decoration: inputDecoration.copyWith(
                labelText: 'Languages (optional)',
                hintText: 'e.g. English, Spanish',
                prefixIcon: const Icon(Icons.language),
              ),
              style: TextStyle(color: textColor), // Themed text input
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProjectsStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final iconColor = isDarkMode ? Colors.white70 : null;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: inputFillColor, // Themed fill color
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: Theme.of(context).inputDecorationTheme.labelStyle, // Use themed label style
      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle, // Use themed hint style
      prefixIconColor: iconColor, // Themed prefix icon color
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Form(
        key: _formKeyStep6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Themed text color
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectList.length,
                itemBuilder: (context, index) {
                  final project = projectList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: cardColor, // Themed card color
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: project.name,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Project Name',
                              prefixIcon: const Icon(Icons.folder_open),
                            ),
                            onChanged: (val) => project.name = val,
                            validator: (val) => val == null || val.isEmpty ? 'Please enter project name' : null,
                            style: TextStyle(color: textColor), // Themed text input
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: project.link,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Project Link (optional)',
                              hintText: 'e.g. https://github.com/your-project',
                              prefixIcon: const Icon(Icons.link),
                            ),
                            keyboardType: TextInputType.url,
                            onChanged: (val) => project.link = val,
                            validator: (val) {
                              if (val != null && val.isNotEmpty) {
                                final urlRegex = RegExp(r'^https?://');
                                if (!urlRegex.hasMatch(val)) return 'Enter a valid URL';
                              }
                              return null;
                            },
                            style: TextStyle(color: textColor), // Themed text input
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: project.description,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                            onChanged: (val) => project.description = val,
                            validator: (val) => val == null || val.isEmpty ? 'Please enter project description' : null,
                            style: TextStyle(color: textColor), // Themed text input
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  projectList.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    projectList.add(ProjectEntry());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00b09b),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


// Helper function for date picking
Future<void> _selectDate(BuildContext context, ValueChanged<String> onDateSelected, String? initialDateString) async {
  DateTime? initialDate;
  if (initialDateString != null && initialDateString.isNotEmpty) {
    try {
      initialDate = DateTime.tryParse(initialDateString);
    } catch (e) {
      initialDate = null;
    }
  }

  initialDate ??= DateTime.now();
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;


  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1900),
    lastDate: DateTime(2101),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith( // Use copyWith to adapt current theme
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF00b09b),
            onPrimary: Colors.white,
            surface: isDarkMode ? Colors.grey[800]! : Colors.white, // Date picker background
            onSurface: isDarkMode ? Colors.white : Colors.black, // Date picker text
          ),
          dialogBackgroundColor: isDarkMode ? Colors.grey[800]! : Colors.white, // Dialog background
        ),
        child: child!,
      );
    },
  );
  if (picked != null) {
    final String formattedDate = '${_getMonthName(picked.month)} ${picked.year}';
    onDateSelected(formattedDate);
  }
}

String _getMonthName(int month) {
  switch (month) {
    case 1: return 'January';
    case 2: return 'February';
    case 3: return 'March';
    case 4: return 'April';
    case 5: return 'May';
    case 6: return 'June';
    case 7: return 'July';
    case 8: return 'August';
    case 9: return 'September';
    case 10: return 'October';
    case 11: return 'November';
    case 12: return 'December';
    default: return '';
  }
}
}