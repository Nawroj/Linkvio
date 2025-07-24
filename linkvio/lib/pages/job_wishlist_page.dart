// lib/pages/job_wishlist_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job_listing.dart';
import '../services/job_wishlist_api.dart'; // Import the API service
import 'add_job_description_page.dart'; // For editing
import 'job_details_page.dart'; // For viewing full details

class JobWishlistPage extends StatefulWidget {
  const JobWishlistPage({super.key});

  @override
  State<JobWishlistPage> createState() => _JobWishlistPageState();
}

class _JobWishlistPageState extends State<JobWishlistPage> {
  final JobWishlistApi _jobApi = JobWishlistApi();
  List<JobListing> _jobListings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJobListings();
  }

  Future<void> _fetchJobListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final jobs = await _jobApi.loadJobs();
      setState(() {
        _jobListings = jobs;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load job listings: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('Are you sure you want to delete this job from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true; // Show loading while deleting
      });
      try {
        await _jobApi.deleteJob(jobId);
        await _fetchJobListings(); // Refresh list after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job deleted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete job: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false; // Stop loading on error
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Wishlist'),
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
                          onPressed: _fetchJobListings,
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
              : _jobListings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          Text(
                            'Your job wishlist is empty!',
                            style: TextStyle(fontSize: 20, color: secondaryTextColor),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Add jobs by sharing links from LinkedIn/Seek or tapping the + button.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: secondaryTextColor),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddJobDescriptionPage()),
                              );
                              if (result == true) {
                                _fetchJobListings(); // Refresh if a job was added
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Job'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _jobListings.length,
                      itemBuilder: (context, index) {
                        final job = _jobListings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JobDetailsPage(job: job),
                                ),
                              );
                              if (result == true) {
                                _fetchJobListings(); // Refresh if job was edited from details page (not implemented yet, but good for future)
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.company,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Added: ${DateFormat('MMM dd, yyyy').format(job.dateAdded)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (job.url != null && job.url!.isNotEmpty)
                                        IconButton(
                                          icon: Icon(Icons.link, color: Theme.of(context).primaryColor),
                                          tooltip: 'Open Link',
                                          onPressed: () => _launchUrl(job.url!),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                                        tooltip: 'Edit Job',
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddJobDescriptionPage(jobToEdit: job),
                                            ),
                                          );
                                          if (result == true) {
                                            _fetchJobListings(); // Refresh list if job was edited
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        tooltip: 'Delete Job',
                                        onPressed: () => _deleteJob(job.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _isLoading || _errorMessage != null // Hide FAB if loading or error
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddJobDescriptionPage()),
                );
                if (result == true) {
                  _fetchJobListings(); // Refresh if a job was added
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}