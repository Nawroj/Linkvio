// lib/pages/job_details_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../models/job_listing.dart';

class JobDetailsPage extends StatelessWidget {
  final JobListing job;

  const JobDetailsPage({super.key, required this.job});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      // You can show a SnackBar or AlertDialog here if the URL can't be launched
      debugPrint('Could not launch $url');
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
        title: Text(job.title),
        actions: [
          if (job.url != null && job.url!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: 'Open Job Link',
              onPressed: () => _launchUrl(job.url!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.company,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Added: ${DateFormat('MMM dd, yyyy').format(job.dateAdded)}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: secondaryTextColor,
              ),
            ),
            if (job.url != null && job.url!.isNotEmpty) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchUrl(job.url!),
                child: Text(
                  job.url!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Job Description:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                job.fullDescription,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}