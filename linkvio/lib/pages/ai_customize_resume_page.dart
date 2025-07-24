// lib/pages/ai_customize_resume_page.dart

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/job_listing.dart';
import 'profile_page.dart'; // To get access to EducationEntry, ExperienceEntry, etc.
import 'resume_template_selection_page.dart'; // To navigate for PDF generation

// IMPORTANT: Define your API Base URL here (duplicate from profile_page.dart for convenience)
const String API_BASE_URL = 'https://njdf4mnhdc.execute-api.ap-southeast-2.amazonaws.com/dev'; // Your existing base for resume, joblist
const String AI_CUSTOMIZE_API_URL = 'https://gbuyvo0j1k.execute-api.ap-southeast-2.amazonaws.com/dev/customize-resume'; // Make sure this is your correct AI API Gateway Invoke URL

class AICustomizeResumePage extends StatefulWidget {
  final JobListing jobListing;

  const AICustomizeResumePage({super.key, required this.jobListing});

  @override
  State<AICustomizeResumePage> createState() => _AICustomizeResumePageState();
}

class _AICustomizeResumePageState extends State<AICustomizeResumePage> {
  // State variables for loading and errors
  bool _isLoading = true;
  String? _errorMessage;
  bool _isGeneratingPdf = false;

  // Original user resume data (fetched from backend)
  Map<String, dynamic>? _originalResumeData;

  // Customized resume data (initially AI-suggested, then user-approved/modified)
  Map<String, dynamic> _currentCustomizedResumeData = {};

  // Controllers for each section's text fields (for display and editing)
  final _summaryController = TextEditingController();
  final _technicalSkillsController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _languagesController = TextEditingController();

  // List controllers for dynamic entries (Education, Experience, Projects, Certificates)
  // These will hold *copies* of the AI/user-modified data for UI manipulation
  List<EducationEntry> _customizedEducationList = [];
  List<CertificateEntry> _customizedCertificateList = [];
  List<ExperienceEntry> _customizedExperienceList = [];
  List<ProjectEntry> _customizedProjectList = [];

  // Approval states for each section
  bool _isSummaryApproved = false;
  bool _isEducationApproved = false;
  bool _isCertificatesApproved = false;
  bool _isExperienceApproved = false;
  bool _isSkillsApproved = false;
  bool _isProjectsApproved = false;

  @override
  void initState() {
    super.initState();
    _initializeResumeCustomization();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _technicalSkillsController.dispose();
    _softSkillsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _initializeResumeCustomization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch original user resume data
      _originalResumeData = await _fetchUserResumeData();

      if (_originalResumeData == null) {
        throw Exception('Failed to load your resume data. Please build your resume in the Profile section first.');
      }

      // 2. Get AI customized suggestions
      final Map<String, dynamic> aiSuggestions = await _getAICustomizedResume(
        _originalResumeData!,
        widget.jobListing.fullDescription,
      );

      // Initialize customized data with AI suggestions (or original if AI not available for a section)
      _currentCustomizedResumeData = Map.from(_originalResumeData!); // Start with original data
      _applyAISuggestions(aiSuggestions); // Apply AI suggestions on top

      // Populate controllers and lists for display
      _populateControllersFromCustomizedData();

    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to customize resume: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to fetch user's full resume data from your API
  // This is used to get the original resume data.
  Future<Map<String, dynamic>?> _fetchUserResumeData() async {
    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        throw Exception('Failed to get user token for fetching resume data.');
      }

      final apiUrl = '$API_BASE_URL/resume';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!, // ⭐ MODIFIED: Removed 'Bearer ' prefix
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null; // No resume data found
      } else {
        throw Exception('Failed to fetch resume: ${response.statusCode} - ${response.body}');
      }
    } on AuthException catch (e) {
      throw Exception('Authentication error fetching resume: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // This method sends data to your GPT-4 backend
  Future<Map<String, dynamic>> _getAICustomizedResume(Map<String, dynamic> userResume, String jobDescription) async {
    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        throw Exception('Failed to get user token for AI customization.');
      }

      // ⭐ Corrected API endpoint to use AI_CUSTOMIZE_API_URL
      final response = await http.post(
        Uri.parse(AI_CUSTOMIZE_API_URL), // Use the specific AI API endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!, // ⭐ MODIFIED: Removed 'Bearer ' prefix
        },
        body: jsonEncode({
          'userResumeData': userResume,
          'jobDescription': jobDescription,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody.containsKey('customizedResume')) {
          return responseBody['customizedResume'] as Map<String, dynamic>;
        } else {
          throw Exception('AI response missing "customizedResume" key.');
        }
      } else {
        // Print the backend error for debugging
        print('Backend AI API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get AI customization: ${response.statusCode} - ${response.body}');
      }
    } on AuthException catch (e) {
      throw Exception('Authentication error during AI customization: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // Apply AI suggestions to the current customized data
  void _applyAISuggestions(Map<String, dynamic> aiSuggestions) {
    setState(() {
      _currentCustomizedResumeData['summary'] = aiSuggestions['summary'] ?? _originalResumeData?['summary'] ?? '';
      _currentCustomizedResumeData['experience'] = aiSuggestions['experience'] ?? _originalResumeData?['experience'] ?? [];
      _currentCustomizedResumeData['skills'] = aiSuggestions['skills'] ?? _originalResumeData?['skills'] ?? {};
      _currentCustomizedResumeData['projects'] = aiSuggestions['projects'] ?? _originalResumeData?['projects'] ?? [];

      // Ensure non-AI-customized sections are also present from original data
      _currentCustomizedResumeData['personalInfo'] = _originalResumeData?['personalInfo'] ?? {};
      _currentCustomizedResumeData['education'] = _originalResumeData?['education'] ?? [];
      _currentCustomizedResumeData['certificates'] = _originalResumeData?['certificates'] ?? [];
    });
  }

  // Populate UI controllers from _currentCustomizedResumeData
  void _populateControllersFromCustomizedData() {
    _summaryController.text = _currentCustomizedResumeData['summary'] ?? '';
    _technicalSkillsController.text = (_currentCustomizedResumeData['skills']['technicalSkills'] as List?)?.join(', ') ?? '';
    _softSkillsController.text = (_currentCustomizedResumeData['skills']['softSkills'] as List?)?.join(', ') ?? '';
    _languagesController.text = (_currentCustomizedResumeData['skills']['languages'] as List?)?.join(', ') ?? '';

    _customizedEducationList = (_currentCustomizedResumeData['education'] as List?)
            ?.map((e) => EducationEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _customizedCertificateList = (_currentCustomizedResumeData['certificates'] as List?)
            ?.map((c) => CertificateEntry.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    _customizedExperienceList = (_currentCustomizedResumeData['experience'] as List?)
            ?.map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _customizedProjectList = (_currentCustomizedResumeData['projects'] as List?)
            ?.map((p) => ProjectEntry.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
  }

  // --- Helper Widgets for building sections ---

  Widget _buildSectionHeader(
    String title,
    bool isApproved,
    VoidCallback onApprove,
    VoidCallback onDecline,
    // Add retry functionality later
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isApproved ? null : onApprove,
                  icon: Icon(isApproved ? Icons.check_circle : Icons.check),
                  label: Text(isApproved ? 'Approved' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproved ? Colors.green : primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isApproved ? onDecline : null, // Can only decline if currently approved
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isApproved ? Colors.red : Colors.grey, // Red when declineable, grey otherwise
                    side: BorderSide(color: isApproved ? Colors.red : Colors.grey),
                  ),
                ),
              ),
              // Add a retry button here later
              // IconButton(
              //   onPressed: () => _retryAISuggestionForSection(title),
              //   icon: Icon(Icons.refresh),
              //   tooltip: 'Retry AI Suggestion',
              // ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _getTextFieldDecoration(String label, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final borderColor = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      filled: true,
      fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      labelText: label,
      labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
      prefixIcon: Icon(icon, color: Theme.of(context).inputDecorationTheme.prefixIconColor),
    );
  }


  Widget _buildSummarySection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Professional Summary',
          _isSummaryApproved,
          () => setState(() {
            _isSummaryApproved = true;
            _currentCustomizedResumeData['summary'] = _summaryController.text;
          }),
          () => setState(() {
            _isSummaryApproved = false;
            _summaryController.text = _originalResumeData?['summary'] ?? '';
            _currentCustomizedResumeData['summary'] = _summaryController.text;
          }),
        ),
        TextFormField(
          controller: _summaryController,
          decoration: _getTextFieldDecoration('Summary', Icons.description).copyWith(
            alignLabelWithHint: true,
          ),
          maxLines: null,
          minLines: 5,
          keyboardType: TextInputType.multiline,
          readOnly: _isSummaryApproved, // Read-only if approved
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Experience',
          _isExperienceApproved,
          () => setState(() {
            _isExperienceApproved = true;
            // Update _currentCustomizedResumeData from the controllers in the list
            _currentCustomizedResumeData['experience'] = _customizedExperienceList.map((e) => e.toJson()).toList();
          }),
          () => setState(() {
            _isExperienceApproved = false;
            // Revert to original data for experience section
            _customizedExperienceList = (_originalResumeData?['experience'] as List?)
                    ?.map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];
            _currentCustomizedResumeData['experience'] = _customizedExperienceList.map((e) => e.toJson()).toList();
          }),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customizedExperienceList.length,
          itemBuilder: (context, index) {
            final exp = _customizedExperienceList[index];
            final responsibilitiesController = TextEditingController(text: exp.responsibilities);

            // Important: Add listeners to update the model when text changes
            responsibilitiesController.addListener(() {
              exp.responsibilities = responsibilitiesController.text;
            });

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exp.jobTitle} at ${exp.company}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '${exp.startDate} - ${exp.endDate}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: responsibilitiesController,
                      decoration: _getTextFieldDecoration('Responsibilities (AI Suggestion)', Icons.description).copyWith(
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      readOnly: _isExperienceApproved,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Skills',
          _isSkillsApproved,
          () => setState(() {
            _isSkillsApproved = true;
            _currentCustomizedResumeData['skills']['technicalSkills'] = _technicalSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            _currentCustomizedResumeData['skills']['softSkills'] = _softSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            _currentCustomizedResumeData['skills']['languages'] = _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          }),
          () => setState(() {
            _isSkillsApproved = false;
            // Revert to original data for skills section
            final originalSkills = _originalResumeData?['skills'] ?? {};
            _technicalSkillsController.text = (originalSkills['technicalSkills'] as List?)?.join(', ') ?? '';
            _softSkillsController.text = (originalSkills['softSkills'] as List?)?.join(', ') ?? '';
            _languagesController.text = (originalSkills['languages'] as List?)?.join(', ') ?? '';

            _currentCustomizedResumeData['skills'] = {
              'technicalSkills': _technicalSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              'softSkills': _softSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              'languages': _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
            };
          }),
        ),
        TextFormField(
          controller: _technicalSkillsController,
          decoration: _getTextFieldDecoration('Technical Skills (AI Suggestion)', Icons.code),
          readOnly: _isSkillsApproved,
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _softSkillsController,
          decoration: _getTextFieldDecoration('Soft Skills', Icons.people),
          readOnly: _isSkillsApproved,
          style: TextStyle(color: textColor),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _languagesController,
          decoration: _getTextFieldDecoration('Languages', Icons.language),
          readOnly: _isSkillsApproved,
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }

  Widget _buildProjectsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Projects',
          _isProjectsApproved,
          () => setState(() {
            _isProjectsApproved = true;
            _currentCustomizedResumeData['projects'] = _customizedProjectList.map((p) => p.toJson()).toList();
          }),
          () => setState(() {
            _isProjectsApproved = false;
            // Revert to original data for projects section
            _customizedProjectList = (_originalResumeData?['projects'] as List?)
                    ?.map((p) => ProjectEntry.fromJson(p as Map<String, dynamic>))
                    .toList() ??
                [];
            _currentCustomizedResumeData['projects'] = _customizedProjectList.map((p) => p.toJson()).toList();
          }),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customizedProjectList.length,
          itemBuilder: (context, index) {
            final project = _customizedProjectList[index];
            final descriptionController = TextEditingController(text: project.description);

            // Important: Add listeners to update the model when text changes
            descriptionController.addListener(() {
              project.description = descriptionController.text;
            });

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    if (project.link.isNotEmpty)
                      Text(
                        project.link,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      decoration: _getTextFieldDecoration('Description (AI Suggestion)', Icons.description).copyWith(
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      readOnly: _isProjectsApproved,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Education and Certificates sections will mostly display original data
  // but still need the approve/decline UI for consistency.
  Widget _buildEducationSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Education',
          _isEducationApproved,
          () => setState(() {
            _isEducationApproved = true;
            _currentCustomizedResumeData['education'] = _customizedEducationList.map((e) => e.toJson()).toList();
          }),
          () => setState(() {
            _isEducationApproved = false;
            _customizedEducationList = (_originalResumeData?['education'] as List?)
                    ?.map((e) => EducationEntry.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];
            _currentCustomizedResumeData['education'] = _customizedEducationList.map((e) => e.toJson()).toList();
          }),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customizedEducationList.length,
          itemBuilder: (context, index) {
            final edu = _customizedEducationList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu.degree,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      '${edu.university} • ${edu.graduationDate}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (edu.major.isNotEmpty)
                      Text(
                        'Major: ${edu.major}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    if (edu.coursework.isNotEmpty)
                      Text(
                        'Coursework: ${edu.coursework}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCertificatesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Certificates',
          _isCertificatesApproved,
          () => setState(() {
            _isCertificatesApproved = true;
            _currentCustomizedResumeData['certificates'] = _customizedCertificateList.map((e) => e.toJson()).toList();
          }),
          () => setState(() {
            _isCertificatesApproved = false;
            _customizedCertificateList = (_originalResumeData?['certificates'] as List?)
                    ?.map((c) => CertificateEntry.fromJson(c as Map<String, dynamic>))
                    .toList() ??
                [];
            _currentCustomizedResumeData['certificates'] = _customizedCertificateList.map((e) => e.toJson()).toList();
          }),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customizedCertificateList.length,
          itemBuilder: (context, index) {
            final cert = _customizedCertificateList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      'Issued: ${cert.date}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (cert.coursework.isNotEmpty)
                      Text(
                        'Coursework: ${cert.coursework}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Customize for: ${widget.jobListing.title}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _initializeResumeCustomization,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Resume Customization',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Review and approve AI suggestions based on the "${widget.jobListing.title}" job description from ${widget.jobListing.company}.',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Build Resume Sections
                      _buildSummarySection(),
                      _buildExperienceSection(),
                      _buildSkillsSection(),
                      _buildProjectsSection(),
                      _buildEducationSection(), // No AI customization for now, but include for completeness
                      _buildCertificatesSection(), // No AI customization for now, but include for completeness


                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingPdf ? null : () async {
                            setState(() {
                              _isGeneratingPdf = true;
                            });
                            // Navigate to the template selection page, passing the customized data
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResumeTemplateSelectionPage(
                                  prefilledResumeData: _currentCustomizedResumeData,
                                ),
                              ),
                            );
                            setState(() {
                              _isGeneratingPdf = false;
                            });
                          },
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf),
                          label: Text(
                            _isGeneratingPdf ? 'Generating PDF...' : 'Generate Customized PDF',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}