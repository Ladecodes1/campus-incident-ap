import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service = IncidentService();
  StreamSubscription<List<Incident>>? _sub;

  List<Incident> _all = [];
  bool _loading = true;
  String? _error;

  // Search and filter state
  String _search = '';
  String? _categoryFilter; // null means "all categories"
  String? _statusFilter; // null means "all statuses"

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  String? get categoryFilter => _categoryFilter;
  String? get statusFilter => _statusFilter;

  IncidentProvider() {
    _listen();
  }

  // Starts listening to Firestore. Any change updates the screens.
  void _listen() {
    _sub?.cancel();
    _loading = true;
    _error = null;
    _sub = _service.streamIncidents().listen(
      (incidents) {
        _all = incidents;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _error = 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  void retry() => _listen();

  // The list the screens show: all reports after search and filters
  List<Incident> get incidents {
    return _all.where((i) {
      final q = _search.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q);
      final matchesCategory =
          _categoryFilter == null || i.category == _categoryFilter;
      final matchesStatus =
          _statusFilter == null || i.status == _statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  // Finds one report by its ID, ignoring search and filters.
  // Returns null if it no longer exists (for example, after it was deleted).
  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  // Reports made by one student
  List<Incident> mine(String uid) =>
      incidents.where((i) => i.reporterId == uid).toList();

  // Counts per status (used later for the staff dashboard)
  int countByStatus(String status) =>
      _all.where((i) => i.status == status).length;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _categoryFilter = null;
    _statusFilter = null;
    notifyListeners();
  }

  // CREATE, UPDATE and DELETE pass through to the service
  Future<void> addIncident(Incident incident) => _service.addIncident(incident);

  Future<void> updateDetails({
    required String id,
    required String title,
    required String description,
    required String category,
    required String location,
  }) =>
      _service.updateDetails(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
      );

  Future<void> updateStatus(String id, String status) =>
      _service.updateStatus(id, status);

  Future<void> deleteIncident(String id) => _service.deleteIncident(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}