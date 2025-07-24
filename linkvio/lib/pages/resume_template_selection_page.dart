// pages/resume_template_selection_page.dart (Modified for modern look and grid layout)

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'pdf_viewer_page.dart';

// IMPORTANT: Define your API Base URL here
const String API_BASE_URL = 'https://njdf4mnhdc.execute-api.ap-southeast-2.amazonaws.com/dev';

// --- ResumeTemplate Model ---
class ResumeTemplate {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isRecommended; // New property

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isRecommended = false, // Default to false
  });
}

class ResumeTemplateSelectionPage extends StatefulWidget {
  // <--- MODIFIED CONSTRUCTOR: Now accepts optional prefilledResumeData
  final Map<String, dynamic>? prefilledResumeData;

  const ResumeTemplateSelectionPage({super.key, this.prefilledResumeData});

  @override
  State<ResumeTemplateSelectionPage> createState() => _ResumeTemplateSelectionPageState();
}

class _ResumeTemplateSelectionPageState extends State<ResumeTemplateSelectionPage> {
  final List<ResumeTemplate> _templates = [
    ResumeTemplate(
      id: 'classic',
      name: 'Classic Professional',
      description: 'A clean, traditional layout suitable for most industries. Focuses on readability and professional appeal.',
      imageUrl: 'assets/resume/classic_resume.jpg',
      isRecommended: true, // Set Classic as recommended
    ),
    ResumeTemplate(
      id: 'modern',
      name: 'Modern Minimalist',
      description: 'A sleek, contemporary design with a focus on simplicity, strong visual hierarchy, and modern aesthetics.',
      imageUrl: 'assets/resume/modern_resume.png',
      isRecommended: false, // Modern is not recommended in this case
    ),
  ];

  ResumeTemplate? _selectedTemplate;
  Map<String, dynamic>? _resumeData; // This will hold the data used for PDF generation
  bool _isLoadingData = true;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    // <--- MODIFIED INITSTATE LOGIC
    if (widget.prefilledResumeData != null) {
      // If prefilled data is provided, use it directly
      _resumeData = widget.prefilledResumeData;
      _isLoadingData = false; // No need to fetch, data is already here
    } else {
      // Otherwise, fetch data from the API as before (for standard resume generation)
      _fetchResumeData();
    }
  }

  Future<void> _fetchResumeData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
      _resumeData = null;
    });

    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;
      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        throw Exception('Failed to get user token.');
      }

      final String fullApiUrl = '$API_BASE_URL/resume';

      final response = await http.get(
        Uri.parse(fullApiUrl),
        headers: {'Authorization': idToken.raw!},
      );

      if (response.statusCode == 200) {
        setState(() {
          _resumeData = jsonDecode(response.body) as Map<String, dynamic>;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'No resume data found. Please build your resume first from the Home page.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch resume data: ${response.statusCode} - ${response.body}';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = 'Authentication error fetching resume: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching resume: $e';
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _generateResume() async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resume template.')),
      );
      return;
    }
    if (_resumeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot generate resume: no data found. Please build your resume first.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _downloadUrl = null;
      _errorMessage = null;
    });

    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;
      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        throw Exception('Failed to get user token.');
      }

      final String generateApiUrl = '$API_BASE_URL/generate-pdf';

      final response = await http.post(
        Uri.parse(generateApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!,
        },
        body: jsonEncode({
          'templateId': _selectedTemplate!.id,
          'resumeData': _resumeData, // This will now use the prefilled data if available
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String url = responseBody['downloadUrl'];
        setState(() {
          _downloadUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume PDF generated successfully!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerPage(pdfUrl: _downloadUrl!),
          ),
        );

      } else {
        throw Exception('Failed to generate resume: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating resume: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF00b09b);
    final Color accentColor = primaryColor.withOpacity(0.8);
    final Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[800]!;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Resume',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _fetchResumeData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Fetch Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _resumeData == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 60,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Resume data not found. Please go back to the Home page and build your resume first to generate a PDF.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                          child: Text(
                            'Please select a template:',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _templates.length,
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              final isSelected = _selectedTemplate?.id == template.id;

                              // Determine card background color based on theme
                              final cardBackgroundColor = Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).cardColor // Use cardColor from darkTheme
                                  : Colors.white; // Keep white for light mode

                              // Determine description text color based on theme
                              final descriptionColor = Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400] // Lighter grey for dark mode descriptions
                                  : Colors.grey[600]; // Darker grey for light mode descriptions

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: cardBackgroundColor, // Apply dynamic card background color
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? primaryColor.withOpacity(0.4)
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.black.withOpacity(0.4) // Darker shadow for dark mode
                                              : Colors.grey.withOpacity(0.2), // Lighter shadow for light mode
                                      spreadRadius: isSelected ? 3 : 1,
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: Offset(0, isSelected ? 4 : 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected ? primaryColor : Colors.transparent,
                                    width: isSelected ? 2.5 : 0,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () {
                                    setState(() {
                                      _selectedTemplate = template;
                                      _downloadUrl = null;
                                    });
                                  },
                                  child: Stack(
                                    // Use Stack to overlay the banner
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                              child: Image.asset(
                                                template.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  template.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor, // This already uses the dynamic textColor
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  template.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: descriptionColor, // Apply dynamic description color
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: Radio<ResumeTemplate>(
                                                    value: template,
                                                    groupValue: _selectedTemplate,
                                                    onChanged: (ResumeTemplate? value) {
                                                      setState(() {
                                                        _selectedTemplate = value;
                                                        _downloadUrl = null;
                                                      });
                                                    },
                                                    activeColor: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // --- Recommended Banner ---
                                      if (template.isRecommended)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[600],
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(15),
                                                bottomLeft: Radius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Recommended',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isGenerating || _selectedTemplate == null || _resumeData == null ? null : _generateResume,
                                icon: _isGenerating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator.adaptive(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(
                                  _isGenerating ? 'Generating PDF...' : 'Generate Resume PDF',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                              if (_downloadUrl != null) ...[
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () => _launchUrl(_downloadUrl!),
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download PDF', style: const TextStyle(fontSize: 15),),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your PDF will open in your device\'s default viewer.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}