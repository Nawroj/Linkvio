// lib/services/job_wishlist_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import '../models/job_listing.dart';

// IMPORTANT: Use your actual API Base URL here
const String API_BASE_URL = 'https://fjzyub8in2.execute-api.ap-southeast-2.amazonaws.com/dav';

class JobWishlistApi {
  // Helper to get the authenticated user's ID token
  Future<String?> _getIdToken() async {
    try {
      final userSession = await Amplify.Auth.fetchAuthSession();
      if (!userSession.isSignedIn) {
        throw Exception('User is not signed in.');
      }
      final cognitoSession = userSession as CognitoAuthSession;
      return cognitoSession.userPoolTokensResult.value?.idToken?.raw;
    } on AuthException catch (e) {
      safePrint('Auth error getting ID token: ${e.message}');
      rethrow; // Re-throw to be caught by the calling function
    } catch (e) {
      safePrint('Error getting ID token: $e');
      rethrow;
    }
  }

  // Add a new JobListing to the backend
  Future<JobListing> addJob(JobListing job) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Authentication token not available.');
    }

    final url = Uri.parse('$API_BASE_URL/jobs'); // Assuming /jobs is your endpoint for adding
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(job.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Backend might return the saved object with any server-generated fields (e.g., createdAt)
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return JobListing.fromJson(responseData);
    } else {
      safePrint('Failed to add job: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to add job: ${response.body}');
    }
  }

  // Load all JobListing objects from the backend for the current user
  Future<List<JobListing>> loadJobs() async {
    final token = await _getIdToken();
    if (token == null) {
      return []; // Or throw an exception if not signed in
    }

    final url = Uri.parse('$API_BASE_URL/jobs'); // Assuming /jobs is your endpoint for loading all
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      // Sort jobs by dateAdded in descending order (latest first)
      List<JobListing> jobs = jsonList.map((json) => JobListing.fromJson(json)).toList();
      jobs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return jobs;
    } else if (response.statusCode == 404) {
      // No jobs found is not an error, just an empty list
      return [];
    } else {
      safePrint('Failed to load jobs: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load jobs: ${response.body}');
    }
  }

  // Update an existing JobListing on the backend
  Future<JobListing> updateJob(JobListing updatedJob) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Authentication token not available.');
    }

    final url = Uri.parse('$API_BASE_URL/jobs/${updatedJob.id}'); // Assuming /jobs/{id} for update
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(updatedJob.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return JobListing.fromJson(responseData);
    } else {
      safePrint('Failed to update job: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update job: ${response.body}');
    }
  }

  // Delete a JobListing by ID from the backend
  Future<void> deleteJob(String jobId) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Authentication token not available.');
    }

    final url = Uri.parse('$API_BASE_URL/jobs/$jobId'); // Assuming /jobs/{id} for delete
    final response = await http.delete(
      url,
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      safePrint('Failed to delete job: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to delete job: ${response.body}');
    }
  }

  // Get the latest N jobs (for homepage display) - fetches all then filters
  // (Alternatively, your backend could provide a dedicated endpoint for this)
  Future<List<JobListing>> getLatestJobs(int count) async {
    List<JobListing> allJobs = await loadJobs(); // Load all jobs
    return allJobs.take(count).toList(); // Take the first 'count' which are already sorted by loadJobs
  }
}