import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentCategories {
  static const all = [
    'Broken facilities',
    'Water shortage',
    'Electricity outage',
    'Damaged furniture',
    'Sanitation',
    'Safety concern',
    'Other',
  ];
}

class IncidentStatus {
  static const submitted = 'Submitted';
  static const underReview = 'Under Review';
  static const inProgress = 'In Progress';
  static const resolved = 'Resolved';

  static const all = [submitted, underReview, inProgress, resolved];
}

class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final String? photoUrl; // optional
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    this.photoUrl,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Turns this report into a map so we can save it in Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'status': status,
      'photoUrl': photoUrl,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Builds a report from a Firestore document
  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    return Incident(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      location: map['location'] ?? '',
      status: map['status'] ?? IncidentStatus.submitted,
      photoUrl: map['photoUrl'],
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}