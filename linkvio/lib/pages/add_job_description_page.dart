// lib/pages/add_job_description_page.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // To generate new IDs for new jobs

import '../models/job_listing.dart';
import '../services/job_wishlist_api.dart'; // Import the API service

class AddJobDescriptionPage extends StatefulWidget {
  final String? sharedUrl; // For initial share intent
  final JobListing? jobToEdit; // For editing existing jobs

  const AddJobDescriptionPage({super.key, this.sharedUrl, this.jobToEdit});

  @override
  State<AddJobDescriptionPage> createState() => _AddJobDescriptionPageState();
}

class _AddJobDescriptionPageState extends State<AddJobDescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

  final JobWishlistApi _jobApi = JobWishlistApi(); // Instantiate your API service

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.jobToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Pre-fill fields if editing an existing job
      _titleController.text = widget.jobToEdit!.title;
      _companyController.text = widget.jobToEdit!.company;
      _urlController.text = widget.jobToEdit!.url ?? '';
      _descriptionController.text = widget.jobToEdit!.fullDescription;
    } else if (widget.sharedUrl != null) {
      // Pre-fill URL if coming from a share intent
      _urlController.text = widget.sharedUrl!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        // Update existing job
        final updatedJob = JobListing(
          id: widget.jobToEdit!.id, // Keep the existing ID
          title: _titleController.text.trim(),
          company: _companyController.text.trim(),
          url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
          fullDescription: _descriptionController.text.trim(),
          dateAdded: widget.jobToEdit!.dateAdded, // Keep original date added
        );
        await _jobApi.updateJob(updatedJob);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job updated successfully!')),
        );
      } else {
        // Add new job
        final newJob = JobListing(
          title: _titleController.text.trim(),
          company: _companyController.text.trim(),
          url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
          fullDescription: _descriptionController.text.trim(),
          // ID and dateAdded are automatically generated by the model constructor for new entries
        );
        await _jobApi.addJob(newJob);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job added to wishlist!')),
        );
      }
      Navigator.of(context).pop(true); // Pop back, pass 'true' to indicate success/refresh needed
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save job: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final inputFillColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final borderColor = Theme.of(context).colorScheme.primary;

    InputDecoration _inputDecoration(String labelText, IconData icon) {
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelText: labelText,
        labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
        prefixIcon: Icon(icon, color: Theme.of(context).inputDecorationTheme.prefixIconColor),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Job' : 'Add New Job'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update Job Details' : 'Enter Job Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('Job Title', Icons.work),
                  style: TextStyle(color: textColor),
                  validator: (val) => val == null || val.isEmpty ? 'Job Title is required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _companyController,
                  decoration: _inputDecoration('Company Name', Icons.business),
                  style: TextStyle(color: textColor),
                  validator: (val) => val == null || val.isEmpty ? 'Company Name is required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _urlController,
                  decoration: _inputDecoration('Job Link (Optional)', Icons.link).copyWith(
                    hintText: 'e.g., https://linkedin.com/jobs/123',
                  ),
                  keyboardType: TextInputType.url,
                  style: TextStyle(color: textColor),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final uri = Uri.tryParse(val);
                      if (uri == null || !uri.hasScheme) { // check if it's a valid URL with scheme
                        return 'Enter a valid URL (e.g., https://...)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration('Full Job Description', Icons.description).copyWith(
                    alignLabelWithHint: true,
                    hintText: 'Paste the entire job description here',
                  ),
                  maxLines: null, // Allows multiline input
                  minLines: 8, // Minimum 8 lines tall
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: textColor),
                  validator: (val) => val == null || val.isEmpty ? 'Job Description is required' : null,
                ),
                const SizedBox(height: 30),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Job to Wishlist'),
                  ),
                ),
                const SizedBox(height: 20), // Extra space for keyboard
              ],
            ),
          ),
        ),
      ),
    );
  }
}