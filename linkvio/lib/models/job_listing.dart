// lib/models/job_listing.dart
import 'package:uuid/uuid.dart'; // For generating unique IDs

class JobListing {
  final String id;
  String title;
  String company;
  String? url; // Optional, as it might be manually added without a link
  String fullDescription; // Mandatory
  final DateTime dateAdded;

  JobListing({
    String? id,
    required this.title,
    required this.company,
    this.url,
    required this.fullDescription,
    DateTime? dateAdded,
  }) : id = id ?? const Uuid().v4(), // Generate ID if not provided (for new entries)
       dateAdded = dateAdded ?? DateTime.now(); // Set timestamp if not provided

  // Convert JobListing object to a JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'url': url,
      'fullDescription': fullDescription,
      'dateAdded': dateAdded.toIso8601String(), // Store date as ISO string
    };
  }

  // Create a JobListing object from a JSON map
  factory JobListing.fromJson(Map<String, dynamic> json) {
    return JobListing(
      id: json['id'],
      title: json['title'],
      company: json['company'],
      url: json['url'],
      fullDescription: json['fullDescription'],
      dateAdded: DateTime.parse(json['dateAdded']),
    );
  }
}