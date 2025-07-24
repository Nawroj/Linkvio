// lib/pages/ai_customize_resume_list_page.dart

import 'package:flutter/material.dart';
import '../models/job_listing.dart';
import 'package:intl/intl.dart';
import 'ai_customize_resume_page.dart';

class AICustomizeResumeListPage extends StatelessWidget {
  final List<JobListing> allJobs;

  const AICustomizeResumeListPage({super.key, required this.allJobs});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobs for AI Customization',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      body: allJobs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No jobs with descriptions available for AI customization.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: secondaryTextColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: allJobs.length,
              itemBuilder: (context, index) {
                final job = allJobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 1,
                  color: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      job.title,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${job.company} • ${DateFormat('MMM dd, yyyy').format(job.dateAdded)}',
                      style: TextStyle(color: secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AICustomizeResumePage(jobListing: job),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}