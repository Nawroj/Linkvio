// pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // <--- NEW IMPORT for launching URLs

import 'settings_page.dart';
import 'resume_template_selection_page.dart'; // Import the resume template selection page

// IMPORTANT: Define your API Base URL here (duplicate from resume_template_selection_page.dart for direct usage)
const String API_BASE_URL = 'https://njdf4mnhdc.execute-api.ap-southeast-2.amazonaws.com/dev'; // <--- NEW CONSTANT

// Data models (kept here for completeness, ideally in a separate file)
// ... (EducationEntry, CertificateEntry, ExperienceEntry, ProjectEntry classes remain the same)
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

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      degree: json['degree'] ?? '',
      university: json['university'] ?? '',
      graduationDate: json['graduationDate'] ?? '',
      major: json['major'] ?? '',
      coursework: json['coursework'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'university': university,
      'graduationDate': graduationDate,
      'major': major,
      'coursework': coursework,
    };
  }
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

  factory CertificateEntry.fromJson(Map<String, dynamic> json) {
    return CertificateEntry(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      coursework: json['coursework'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'coursework': coursework,
    };
  }
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

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      responsibilities: json['responsibilities'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobTitle': jobTitle,
      'company': company,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'responsibilities': responsibilities,
    };
  }
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

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    return ProjectEntry(
      name: json['name'] ?? '',
      link: json['link'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'link': link,
      'description': description,
    };
  }
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _resumeData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isGeneratingPdf = false; // <--- NEW STATE VARIABLE

  bool _isEditingPersonalInfo = false;
  bool _isEditingSummary = false;
  bool _isEditingEducation = false;
  bool _isEditingCertificates = false;
  bool _isEditingExperience = false;
  bool _isEditingSkills = false;
  bool _isEditingProjects = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _summaryController = TextEditingController();

  List<EducationEntry> _educationList = [];
  List<CertificateEntry> _certificateList = [];
  List<ExperienceEntry> _experienceList = [];
  List<ProjectEntry> _projectList = [];
  final _technicalSkillsController = TextEditingController();
  final _softSkillsController = TextEditingController();
  final _languagesController = TextEditingController();

  // New: ScrollController and GlobalKeys for sections
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _personalInfoKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _educationKey = GlobalKey();
  final GlobalKey _certificatesKey = GlobalKey();
  final GlobalKey _experienceKey = GlobalKey();
  final GlobalKey _skillsKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();

  String _currentSection = 'Personal Info'; // To track the currently visible section

  // Define the height of the fixed header (Name + Selector)
  // This needs to be adjusted because we're adding another element
  static const double _fixedHeaderHeight = 180.0; // Increased height to accommodate the new button

  @override
  void initState() {
    super.initState();
    _fetchResumeData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // This threshold helps determine when a section is "active" as you scroll
    // Adjusted to account for the fixed header height
    const double scrollThreshold = _fixedHeaderHeight + 20.0; // A bit more than header height

    final RenderBox? personalInfoBox = _personalInfoKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? summaryBox = _summaryKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? educationBox = _educationKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? certificatesBox = _certificatesKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? experienceBox = _experienceKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? skillsBox = _skillsKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? projectsBox = _projectsKey.currentContext?.findRenderObject() as RenderBox?;

    final double scrollOffset = _scrollController.offset;

    // Helper to get the top position relative to the scroll view's viewport
    double getRelativeTop(RenderBox? box) {
      if (box == null) return double.infinity;
      // Get global position and subtract scroll offset to get position relative to viewport top
      return box.localToGlobal(Offset.zero).dy - MediaQuery.of(context).padding.top;
    }

    setState(() {
      if (projectsBox != null && getRelativeTop(projectsBox) <= scrollThreshold) {
        _currentSection = 'Projects';
      } else if (skillsBox != null && getRelativeTop(skillsBox) <= scrollThreshold) {
        _currentSection = 'Skills';
      } else if (experienceBox != null && getRelativeTop(experienceBox) <= scrollThreshold) {
        _currentSection = 'Experience';
      } else if (certificatesBox != null && getRelativeTop(certificatesBox) <= scrollThreshold) {
        _currentSection = 'Certificates';
      } else if (educationBox != null && getRelativeTop(educationBox) <= scrollThreshold) {
        _currentSection = 'Education';
      } else if (summaryBox != null && getRelativeTop(summaryBox) <= scrollThreshold) {
        _currentSection = 'Summary';
      } else if (personalInfoBox != null && getRelativeTop(personalInfoBox) <= scrollThreshold) {
        _currentSection = 'Personal Info';
      }
    });
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0, // Scroll to the top of the section
        // Add a negative offset to account for the fixed header
        // This makes the section stop *below* the fixed header
        // You might need to adjust this value
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      ).then((_) {
        // After scrolling, manually adjust if needed to precisely position below the header
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final double dy = renderBox.localToGlobal(Offset.zero).dy;
        final double currentScrollOffset = _scrollController.offset;
        final double targetScrollOffset = currentScrollOffset + dy - (MediaQuery.of(context).padding.top + _fixedHeaderHeight);

        // Only animate if the target is significantly different
        if ((_scrollController.offset - targetScrollOffset).abs() > 5.0) {
           _scrollController.animateTo(
            targetScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }


  Future<void> _fetchResumeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resumeData = null; // Clear existing data while fetching
    });

    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        setState(() {
          _errorMessage = 'User is not signed in.';
          _isLoading = false;
        });
        return;
      }

      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to get user token.';
          _isLoading = false;
        });
        return;
      }

      final apiUrl = '$API_BASE_URL/resume'; // Use the constant

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _resumeData = data;
          _populateControllers(data);
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = null; // 404 means no resume, not an error for the user, so clear error message.
          _resumeData = null; // Ensure resumeData is null on 404
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch resume: ${response.statusCode} - ${response.body}';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching resume: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    final personalInfo = data['personalInfo'] as Map<String, dynamic>?;
    if (personalInfo != null) {
      _nameController.text = personalInfo['name'] ?? '';
      _emailController.text = personalInfo['email'] ?? '';
      _phoneController.text = personalInfo['phone'] ?? '';
      _linkedinController.text = personalInfo['linkedin'] ?? '';
      _githubController.text = personalInfo['github'] ?? '';
      _addressController.text = personalInfo['address'] ?? '';
      _websiteController.text = personalInfo['website'] ?? '';
    }

    _summaryController.text = data['summary'] ?? '';

    _educationList = (data['education'] as List?)
            ?.map((e) => EducationEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _certificateList = (data['certificates'] as List?)
            ?.map((c) => CertificateEntry.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    _experienceList = (data['experience'] as List?)
            ?.map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _projectList = (data['projects'] as List?)
            ?.map((p) => ProjectEntry.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    final skills = data['skills'] as Map<String, dynamic>?;
    if (skills != null) {
      _technicalSkillsController.text = (skills['technicalSkills'] as List?)?.join(', ') ?? '';
      _softSkillsController.text = (skills['softSkills'] as List?)?.join(', ') ?? '';
      _languagesController.text = (skills['languages'] as List?)?.join(', ') ?? '';
    }
  }

  Future<void> _saveResumeData() async {
    setState(() {
      _isLoading = true; // Show loading while saving
    });

    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;

      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get user token for saving.')),
        );
        return;
      }

      final resumeDataToSave = {
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
        'education': _educationList.map((e) => e.toJson()).toList(),
        'certificates': _certificateList.map((c) => c.toJson()).toList(),
        'experience': _experienceList.map((e) => e.toJson()).toList(),
        'projects': _projectList.map((p) => p.toJson()).toList(),
        'skills': {
          'technicalSkills': _technicalSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'softSkills': _softSkillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          'languages': _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        },
      };

      final apiUrl = '$API_BASE_URL/resume'; // Use the constant

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!,
        },
        body: jsonEncode(resumeDataToSave),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume updated successfully!')),
        );
        setState(() {
          _isEditingPersonalInfo = false;
          _isEditingSummary = false;
          _isEditingEducation = false;
          _isEditingCertificates = false;
          _isEditingExperience = false;
          _isEditingSkills = false;
          _isEditingProjects = false;
          // After successful save, refresh data to ensure the _resumeData is not null
          _fetchResumeData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save resume: ${response.statusCode} - ${response.body}')),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error saving resume: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving resume: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // <--- NEW METHOD FOR DIRECT PDF DOWNLOAD --->
  Future<void> _generateAndDownloadResume() async {
    if (_resumeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resume data found to generate PDF.')),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      final idToken = cognitoSession.userPoolTokensResult.value?.idToken;
      if (idToken == null || idToken.raw == null || idToken.raw!.isEmpty) {
        throw Exception('Failed to get user token for PDF generation.');
      }

      final String generateApiUrl = '$API_BASE_URL/generate-pdf';
      const String defaultTemplateId = 'classic'; // Hardcoded default template

      final response = await http.post(
        Uri.parse(generateApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': idToken.raw!,
        },
        body: jsonEncode({
          'templateId': defaultTemplateId,
          'resumeData': _resumeData,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String downloadUrl = responseBody['downloadUrl'];

        // Use url_launcher to open the PDF in an external application (browser/PDF viewer)
        if (!await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open PDF: $downloadUrl')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume PDF generated and opened!')),
          );
        }
      } else {
        throw Exception('Failed to generate resume PDF: ${response.statusCode} - ${response.body}');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error generating PDF: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }
  // <--- END NEW METHOD --->


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF00b09b);
    final sectionHeaderColor = isDarkMode ? Colors.white : const Color.fromARGB(255, 0, 0, 0);
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final editFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final readOnlyFillColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final readOnlyTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;


    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchResumeData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00b09b),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            top: _fixedHeaderHeight, // Start content below the fixed header
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- NEW: Resume Status and Action Buttons ---
                  // This section is now empty or removed as the button is in the header
                  // _buildResumeStatusSection(), // REMOVE or make it return SizedBox.shrink()
                  const SizedBox(height: 20), // Adjust spacing if needed after removing status section
                  // --- END NEW ---

                  // Personal Info Section
                  _buildSectionHeader(
                    'Personal Information',
                    _isEditingPersonalInfo,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingPersonalInfo = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _personalInfoKey,
                  ),
                  _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email, readOnly: !_isEditingPersonalInfo),
                  _buildTextField(controller: _phoneController, label: 'Phone', icon: Icons.phone, readOnly: !_isEditingPersonalInfo),
                  _buildTextField(controller: _linkedinController, label: 'LinkedIn', icon: Icons.link, readOnly: !_isEditingPersonalInfo),
                  _buildTextField(controller: _githubController, label: 'GitHub', icon: Icons.code, readOnly: !_isEditingPersonalInfo),
                  _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on, readOnly: !_isEditingPersonalInfo),
                  _buildTextField(controller: _websiteController, label: 'Website', icon: Icons.web, readOnly: !_isEditingPersonalInfo),
                  const SizedBox(height: 20),

                  // Professional Summary Section
                  _buildSectionHeader(
                    'Professional Summary',
                    _isEditingSummary,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingSummary = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _summaryKey,
                  ),
                  if (_isEditingSummary || _summaryController.text.isNotEmpty)
                    TextFormField(
                      controller: _summaryController,
                      decoration: _getSectionInputDecoration(_isEditingSummary).copyWith(
                        labelText: 'Summary',
                        alignLabelWithHint: true,
                        fillColor: _isEditingSummary ? editFillColor : readOnlyFillColor, // Use themed colors
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: _isEditingSummary ? BorderSide.none : const BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: _isEditingSummary ? BorderSide.none : const BorderSide(color: Colors.transparent),
                        ),
                        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : null), // Themed label
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : null), // Themed hint
                        prefixIconColor: isDarkMode ? Colors.white70 : null, // Themed prefix icon
                      ),
                      maxLines: _isEditingSummary ? 10 : null,
                      readOnly: !_isEditingSummary,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), // Themed text input
                    ),
                  const SizedBox(height: 20),

                  // Education Section
                  _buildSectionHeader(
                    'Education',
                    _isEditingEducation,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingEducation = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _educationKey,
                  ),
                  if (_isEditingEducation || _educationList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _educationList.length + (_isEditingEducation ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _educationList.length) {
                          return _isEditingEducation ? _buildAddButton('Education', () {
                            setState(() {
                              _educationList.add(EducationEntry());
                            });
                          }) : const SizedBox.shrink();
                        }
                        final edu = _educationList[index];
                        final degreeController = TextEditingController(text: edu.degree);
                        final universityController = TextEditingController(text: edu.university);
                        final majorController = TextEditingController(text: edu.major);
                        final graduationDateController = TextEditingController(text: edu.graduationDate);
                        final courseworkController = TextEditingController(text: edu.coursework);

                        return _buildDynamicEntry(
                          context,
                          index,
                          isEditing: _isEditingEducation,
                          onDelete: _isEditingEducation ? () {
                            setState(() {
                              _educationList.removeAt(index);
                            });
                          } : null,
                          children: [
                            _buildTextField(controller: degreeController, label: 'Degree', icon: Icons.school, onChanged: (val) => edu.degree = val, readOnly: !_isEditingEducation),
                            _buildTextField(controller: universityController, label: 'University', icon: Icons.location_city, onChanged: (val) => edu.university = val, readOnly: !_isEditingEducation),
                            _buildTextField(controller: majorController, label: 'Major (Optional)', icon: Icons.book, onChanged: (val) => edu.major = val, readOnly: !_isEditingEducation),
                            _buildDateInputField(context, controller: graduationDateController, label: 'Graduation Date', onChanged: (val) {
                              edu.graduationDate = val;
                            }, readOnly: !_isEditingEducation),
                            _buildTextField(controller: courseworkController, label: 'Relevant Coursework (optional)', icon: Icons.list_alt, onChanged: (val) => edu.coursework = val, readOnly: !_isEditingEducation, maxLines: 3),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // Certificates Section
                  _buildSectionHeader(
                    'Certificates',
                    _isEditingCertificates,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingCertificates = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _certificatesKey,
                  ),
                  if (_isEditingCertificates || _certificateList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _certificateList.length + (_isEditingCertificates ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _certificateList.length) {
                          return _isEditingCertificates ? _buildAddButton('Certificate', () {
                            setState(() {
                              _certificateList.add(CertificateEntry());
                            });
                          }) : const SizedBox.shrink();
                        }
                        final cert = _certificateList[index];
                        final nameController = TextEditingController(text: cert.name);
                        final dateController = TextEditingController(text: cert.date);
                        final courseworkController = TextEditingController(text: cert.coursework);

                        return _buildDynamicEntry(
                          context,
                          index,
                          isEditing: _isEditingCertificates,
                          onDelete: _isEditingCertificates ? () {
                            setState(() {
                              _certificateList.removeAt(index);
                            });
                          } : null,
                          children: [
                            _buildTextField(controller: nameController, label: 'Certificate Name', icon: Icons.workspace_premium, onChanged: (val) => cert.name = val, readOnly: !_isEditingCertificates),
                            _buildDateInputField(context, controller: dateController, label: 'Date Issued / Completed', onChanged: (val) {
                              cert.date = val;
                            }, readOnly: !_isEditingCertificates),
                            _buildTextField(controller: courseworkController, label: 'Coursework / Key Learnings (optional)', icon: Icons.list_alt, onChanged: (val) => cert.coursework = val, readOnly: !_isEditingCertificates, maxLines: 3),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // Experience Section
                  _buildSectionHeader(
                    'Experience',
                    _isEditingExperience,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingExperience = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _experienceKey,
                  ),
                  if (_isEditingExperience || _experienceList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _experienceList.length + (_isEditingExperience ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _experienceList.length) {
                          return _isEditingExperience ? _buildAddButton('Experience', () {
                            setState(() {
                              _experienceList.add(ExperienceEntry());
                            });
                          }) : const SizedBox.shrink();
                        }
                        final exp = _experienceList[index];
                        final jobTitleController = TextEditingController(text: exp.jobTitle);
                        final companyController = TextEditingController(text: exp.company);
                        final locationController = TextEditingController(text: exp.location);
                        final startDateController = TextEditingController(text: exp.startDate);
                        final endDateController = TextEditingController(text: exp.endDate);
                        final responsibilitiesController = TextEditingController(text: exp.responsibilities);

                        return _buildDynamicEntry(
                          context,
                          index,
                          isEditing: _isEditingExperience,
                          onDelete: _isEditingExperience ? () {
                            setState(() {
                              _experienceList.removeAt(index);
                            });
                          } : null,
                          children: [
                            _buildTextField(controller: jobTitleController, label: 'Job Title', icon: Icons.work, onChanged: (val) => exp.jobTitle = val, readOnly: !_isEditingExperience),
                            _buildTextField(controller: companyController, label: 'Company', icon: Icons.business, onChanged: (val) => exp.company = val, readOnly: !_isEditingExperience),
                            _buildTextField(controller: locationController, label: 'Location', icon: Icons.location_on, onChanged: (val) => exp.location = val, readOnly: !_isEditingExperience),
                            Row(
                              children: [
                                Expanded(child: _buildDateInputField(context, controller: startDateController, label: 'Start Date', onChanged: (val) {exp.startDate = val;}, readOnly: !_isEditingExperience)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDateInputField(context, controller: endDateController, label: 'End Date', onChanged: (val) {exp.endDate = val;}, readOnly: !_isEditingExperience)),
                              ],
                            ),
                            _buildTextField(controller: responsibilitiesController, label: 'Responsibilities', icon: Icons.description, onChanged: (val) => exp.responsibilities = val, readOnly: !_isEditingExperience, maxLines: 4),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // Skills Section
                  _buildSectionHeader(
                    'Skills',
                    _isEditingSkills,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingSkills = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _skillsKey,
                  ),
                  if (_isEditingSkills || _technicalSkillsController.text.isNotEmpty || _softSkillsController.text.isNotEmpty || _languagesController.text.isNotEmpty) ...[
                    _buildTextField(controller: _technicalSkillsController, label: 'Technical Skills (comma separated)', icon: Icons.code, readOnly: !_isEditingSkills),
                    _buildTextField(controller: _softSkillsController, label: 'Soft Skills (comma separated)', icon: Icons.people, readOnly: !_isEditingSkills),
                    _buildTextField(controller: _languagesController, label: 'Languages (comma separated)', icon: Icons.language, readOnly: !_isEditingSkills),
                  ],
                  const SizedBox(height: 20),

                  // Projects Section
                  _buildSectionHeader(
                    'Projects',
                    _isEditingProjects,
                    onEditToggle: (isEditing) {
                      setState(() {
                        _isEditingProjects = isEditing;
                        if (!isEditing) _saveResumeData();
                      });
                    },
                    sectionKey: _projectsKey,
                  ),
                  if (_isEditingProjects || _projectList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _projectList.length + (_isEditingProjects ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _projectList.length) {
                          return _isEditingProjects ? _buildAddButton('Project', () {
                            setState(() {
                              _projectList.add(ProjectEntry());
                            });
                          }) : const SizedBox.shrink();
                        }
                        final project = _projectList[index];
                        final projectNameController = TextEditingController(text: project.name);
                        final projectLinkController = TextEditingController(text: project.link);
                        final projectDescriptionController = TextEditingController(text: project.description);

                        return _buildDynamicEntry(
                          context,
                          index,
                          isEditing: _isEditingProjects,
                          onDelete: _isEditingProjects ? () {
                            setState(() {
                              _projectList.removeAt(index);
                            });
                          } : null,
                          children: [
                            _buildTextField(controller: projectNameController, label: 'Project Name', icon: Icons.folder_open, onChanged: (val) => project.name = val, readOnly: !_isEditingProjects),
                            _buildTextField(controller: projectLinkController, label: 'Project Link (optional)', icon: Icons.link, onChanged: (val) => project.link = val, readOnly: !_isEditingProjects, keyboardType: TextInputType.url),
                            _buildTextField(controller: projectDescriptionController, label: 'Description', icon: Icons.description, onChanged: (val) => project.description = val, readOnly: !_isEditingProjects, maxLines: 5),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  // Add extra padding at the bottom to ensure the last section scrolls above the fixed header
                  SizedBox(height: _fixedHeaderHeight + 50),
                ],
              ),
            ),
          ),

          // Fixed Header (Name and Section Selector)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor, // Background color for the fixed header
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
              child: Column(
                children: [
                  _buildNameSection(),
                  const SizedBox(height: 10), // Spacing after the name
                  // This is where your new button will go
                  Align(
                    alignment: Alignment.centerLeft, // Align button to the left within the fixed header
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0), // Adjust padding as needed
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResumeTemplateSelectionPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_box),
                        label: const Text('Create / Edit Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white, // Themed background
                          foregroundColor: iconColor, // Themed foreground
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Smaller padding for a more compact button
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(
                              color: iconColor, // Border color
                              width: 2, // Border thickness
                            ),
                            elevation: 0,
                          textStyle: const TextStyle(fontSize: 14), // Smaller text
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Spacing before the section selector
                  _buildSectionSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Building the UI ---

  // Removed _buildResumeStatusSection() or made it return SizedBox.shrink()
  // as its content is now integrated into the fixed header.
  Widget _buildResumeStatusSection() {
    return const SizedBox.shrink(); // This widget is no longer needed in its original form
  }

  // Helper to get consistent InputDecoration for sections
  InputDecoration _getSectionInputDecoration(bool isEditing) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final editFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final readOnlyFillColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.white54 : null;
    final labelColor = isDarkMode ? Colors.white70 : null;
    final prefixIconColor = isDarkMode ? Colors.white70 : null;


    BorderSide borderSide = isEditing ? BorderSide.none : const BorderSide(color: Colors.transparent);
    return InputDecoration(
      filled: true,
      fillColor: isEditing ? editFillColor : readOnlyFillColor, // Themed fill color
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00b09b), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      labelStyle: TextStyle(color: labelColor), // Themed label
      hintStyle: TextStyle(color: hintColor), // Themed hint
      prefixIconColor: prefixIconColor, // Themed prefix icon
    );
  }

  // New helper for Name section
  Widget _buildNameSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF00b09b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _isEditingPersonalInfo
              ? TextFormField(
                  controller: _nameController,
                  decoration: _getSectionInputDecoration(true).copyWith(
                    labelText: 'Full Name',
                    border: InputBorder.none, // No border for the name field
                    enabledBorder: InputBorder.none,
                    focusedBorder: const UnderlineInputBorder( // Optional: underline when focused
                      borderSide: BorderSide(color: Color(0xFF00b09b), width: 1),
                    ),
                    fillColor: Colors.transparent, // Transparent background for name
                    filled: false, // Don't fill
                    contentPadding: EdgeInsets.zero, // No extra padding
                  ),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), // Themed text
                )
              : Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : 'Your Name',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), // Themed text
                ),
        ),
        // Edit/Save button specifically for Personal Info (which includes Name)
        IconButton(
          icon: Icon(_isEditingPersonalInfo ? Icons.check : Icons.edit, color: iconColor), // Themed icon
          tooltip: _isEditingPersonalInfo ? 'Save Personal Info' : 'Edit Personal Info',
          onPressed: () {
            setState(() {
              _isEditingPersonalInfo = !_isEditingPersonalInfo;
              if (!_isEditingPersonalInfo) _saveResumeData();
            });
          },
        ),
      ],
    );
  }

  // New: Section Selector Widget
  Widget _buildSectionSelector() {
    final Map<String, GlobalKey> sections = {
      'Personal Info': _personalInfoKey,
      'Summary': _summaryKey,
      'Education': _educationKey,
      'Certificates': _certificatesKey,
      'Experience': _experienceKey,
      'Skills': _skillsKey,
      'Projects': _projectsKey,
    };
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final chipBackgroundColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200;


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sections.keys.map((sectionName) {
          final isSelected = _currentSection == sectionName;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(sectionName),
              selected: isSelected,
              selectedColor: const Color(0xFF00b09b),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textColor, // Themed text
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentSection = sectionName;
                  });
                  _scrollToSection(sections[sectionName]!);
                }
              },
              side: BorderSide.none,
              backgroundColor: chipBackgroundColor, // Themed background
              // Removed the showCheckmark property or explicitly set to false
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildSectionHeader(
    String title,
    bool isEditingSection, {
    required ValueChanged<bool> onEditToggle,
    required GlobalKey sectionKey, // Add sectionKey parameter
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = isDarkMode ? Colors.white : const Color.fromARGB(255, 0, 0, 0);
    final iconColor = isDarkMode ? Colors.white : const Color(0xFF00b09b);

    return RepaintBoundary( // Wrap with RepaintBoundary
      key: sectionKey, // Assign the key here
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: sectionHeaderColor, // Themed color
              ),
            ),
            IconButton(
              icon: Icon(isEditingSection ? Icons.check : Icons.edit, color: iconColor), // Themed icon
              tooltip: isEditingSection ? 'Save Section' : 'Edit Section',
              onPressed: () => onEditToggle(!isEditingSection),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller, // Always require controller
    // String? initialValue, // Removed initialValue parameter
    required String label,
    required IconData icon,
    required bool readOnly,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
  }) {
    // Determine if the field should be shown at all (if not editing AND has no data)
    bool shouldShow = readOnly ? controller.text.isNotEmpty : true;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final readOnlyTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white70 : null;


    if (!shouldShow) {
      return const SizedBox.shrink(); // Hide if no data and not editing
    }

    final inputDecoration = _getSectionInputDecoration(!readOnly).copyWith(
      labelText: label,
      prefixIcon: Icon(icon, color: readOnly ? Colors.grey : iconColor), // Themed icon color
      floatingLabelBehavior: readOnly && controller.text.isEmpty
          ? FloatingLabelBehavior.never
          : FloatingLabelBehavior.auto,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: readOnly ? readOnlyTextColor : textColor), // Themed text color
        decoration: inputDecoration,
      ),
    );
  }

  Widget _buildDateInputField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  required ValueChanged<String> onChanged,
  required bool readOnly,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDarkMode ? Colors.white : Colors.black;
  final iconColor = isDarkMode ? Colors.white70 : null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: GestureDetector(
      onTap: readOnly
          ? null
          : () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFF00b09b), // Primary color for date picker
                        onPrimary: Colors.white,
                        surface: isDarkMode ? Colors.grey[800]! : Colors.white, // Date picker background
                        onSurface: isDarkMode ? Colors.white : Colors.black, // Date picker text
                      ),
                      dialogBackgroundColor: isDarkMode ? Colors.grey[800]! : Colors.white,
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                final formattedDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                controller.text = formattedDate;
                onChanged(formattedDate);
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: _getSectionInputDecoration(!readOnly).copyWith(
            labelText: label,
            prefixIcon: Icon(Icons.calendar_today, color: iconColor), // Themed icon color
          ),
          readOnly: true, // Prevent manual input
          style: TextStyle(color: textColor), // Themed text color
        ),
      ),
    )
  );
}



  Widget _buildDynamicEntry(
    BuildContext context,
    int index, {
    required List<Widget> children,
    required bool isEditing,
    VoidCallback? onDelete,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final editCardColor = isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50; // Darker blue for dark mode

    // Check if any of the text fields within this dynamic entry have content
    // This now correctly checks the controller.text.isNotEmpty
    bool hasContent = children.any((widget) {
      if (widget is Padding && widget.child is TextFormField) {
        final TextFormField textFormField = widget.child as TextFormField;
        if (textFormField.controller != null) {
          return textFormField.controller!.text.isNotEmpty;
        }
      }
      return false;
    });

    // Only show the card if it has content OR it's being edited
    if (!hasContent && !isEditing) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isEditing ? editCardColor : cardColor, // Themed card color
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...children.expand((widget) => [
                  widget,
                  const SizedBox(height: 20),
                ]).toList()
                  ..removeLast(),
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String type, VoidCallback onPressed) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final foregroundColor = isDarkMode ? Colors.white : Colors.white; // Keep white for text

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text('Add $type'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Use theme's primary color
          foregroundColor: foregroundColor, // Themed text color
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }


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