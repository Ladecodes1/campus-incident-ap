import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';

class IncidentService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('incidents');

  // READ: a live stream, newest first. The app updates automatically
  // whenever anything changes in Firestore.
  Stream<List<Incident>> streamIncidents() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Incident.fromMap(doc.id, doc.data()))
            .toList());
  }

  // CREATE
  Future<void> addIncident(Incident incident) async {
    await _col.add(incident.toMap());
  }

  // UPDATE: edit the details of a report (used by the student who made it)
  Future<void> updateDetails({
    required String id,
    required String title,
    required String description,
    required String category,
    required String location,
  }) async {
    await _col.doc(id).update({
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'updatedAt': Timestamp.now(),
    });
  }

  // UPDATE: change the status (staff only, enforced by security rules later)
  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // DELETE
  Future<void> deleteIncident(String id) async {
    await _col.doc(id).delete();
  }
}