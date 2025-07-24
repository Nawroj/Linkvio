// pages/home_page.dart

import 'package:flutter/material.dart';

import 'notifications_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'add_job_description_page.dart';
import 'job_wishlist_page.dart';
import 'job_details_page.dart';
import '../services/job_wishlist_api.dart';
import '../models/job_listing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_customize_resume_page.dart';
import 'ai_customize_resume_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<JobListing> _latestJobs = [];
  bool _isLoadingLatestJobs = true;

  final JobWishlistApi _jobApi = JobWishlistApi();

  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('')),
    NotificationsPage(),
    ProfilePage(),
  ];

  static const List<String> _pageTitles = <String>[
    'Home',
    'Notifications',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchLatestJobs() async {
    setState(() {
      _isLoadingLatestJobs = true;
    });
    try {
      final jobs = await _jobApi.getLatestJobs(10);
      setState(() {
        _latestJobs = jobs;
      });
    } catch (e) {
      debugPrint('Error fetching latest jobs: $e');
    } finally {
      setState(() {
        _isLoadingLatestJobs = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  void initState() {
    super.initState();
    if (_selectedIndex == 0) {
      _fetchLatestJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    final aiCustomizableJobs = _latestJobs.where((job) => job.fullDescription.isNotEmpty).toList();
    final displayedAiJobs = aiCustomizableJobs.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Row(
          children: [
            if (_selectedIndex == 0)
              Image.asset(
                isDarkMode ? 'assets/images/linkvio_dark.png' : 'assets/images/linkvio.png',
                height: 25,
              )
            else
              Text(
                _pageTitles[_selectedIndex],
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          if (_selectedIndex == 2)
            IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).primaryColor),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
        ],
      ),
      body: _selectedIndex == 0
          ? RefreshIndicator(
              onRefresh: _fetchLatestJobs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Job Wishlist',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_box_outlined, color: Theme.of(context).primaryColor),
                          tooltip: 'Add New Job',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddJobDescriptionPage()),
                            );
                            if (result == true) {
                              _fetchLatestJobs();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoadingLatestJobs
                        ? const Center(child: CircularProgressIndicator())
                        : _latestJobs.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.playlist_add, size: 60, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Your wishlist is empty. Add your first job!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: secondaryTextColor),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const AddJobDescriptionPage()),
                                        );
                                        if (result == true) {
                                          _fetchLatestJobs();
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
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _latestJobs.length,
                                itemBuilder: (context, index) {
                                  final job = _latestJobs[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    elevation: 1,
                                    color: cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Text(
                                        job.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${job.company} • ${DateFormat('MMM dd, yyyy').format(job.dateAdded)}',
                                        style: TextStyle(color: secondaryTextColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (job.url != null && job.url!.isNotEmpty)
                                            IconButton(
                                              icon: Icon(Icons.link, color: Theme.of(context).primaryColor),
                                              onPressed: () => _launchUrl(job.url!),
                                              tooltip: 'Open Link',
                                            ),
                                          Icon(Icons.arrow_forward_ios, size: 16, color: secondaryTextColor),
                                        ],
                                      ),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => JobDetailsPage(job: job),
                                          ),
                                        );
                                        _fetchLatestJobs();
                                      },
                                    ),
                                  );
                                },
                              ),
                    const SizedBox(height: 20),
                    if (!_isLoadingLatestJobs && _latestJobs.isNotEmpty)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const JobWishlistPage()),
                            );
                            _fetchLatestJobs();
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('See All Wishlist Jobs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Prepare Resume with AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingLatestJobs
                        ? const Center(child: CircularProgressIndicator())
                        : aiCustomizableJobs.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 60, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No jobs with descriptions for AI customization. Add one from the "Job Wishlist" above!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedAiJobs.length,
                                itemBuilder: (context, index) {
                                  final job = displayedAiJobs[index];
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
                    if (!_isLoadingLatestJobs && aiCustomizableJobs.length > displayedAiJobs.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AICustomizeResumeListPage(allJobs: aiCustomizableJobs),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Show All Jobs for AI Customization'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            )
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _fetchLatestJobs();
          }
        },
      ),
    );
  }
}
