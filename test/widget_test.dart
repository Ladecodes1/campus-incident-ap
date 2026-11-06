import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/widgets/incident_card.dart';

void main() {
  group('AppUser', () {
    test('staff role is recognised as staff', () {
      final user = AppUser(
        uid: '1',
        email: 'a@alustudent.com',
        name: 'Test',
        role: 'staff',
      );
      expect(user.isStaff, true);
    });

    test('student role is not staff', () {
      final user = AppUser(
        uid: '1',
        email: 'a@alustudent.com',
        name: 'Test',
        role: 'student',
      );
      expect(user.isStaff, false);
    });

    test('missing role defaults to student', () {
      final user = AppUser.fromMap('1', {'email': 'a@alustudent.com'});
      expect(user.role, 'student');
      expect(user.isStaff, false);
    });

    test('toMap and fromMap keep the same data', () {
      final user = AppUser(
        uid: '9',
        email: 'b@alueducation.com',
        name: 'Beth',
        role: 'student',
      );
      final copy = AppUser.fromMap('9', user.toMap());
      expect(copy.email, user.email);
      expect(copy.name, user.name);
      expect(copy.role, user.role);
    });
  });

  group('Incident', () {
    test('survives a round trip through a Firestore map', () {
      final now = DateTime(2026, 11, 5, 10, 30);
      final incident = Incident(
        id: 'abc',
        title: 'Broken tap',
        description: 'The tap in Block B is leaking',
        category: 'Broken facilities',
        location: 'Block B',
        status: IncidentStatus.submitted,
        reporterId: 'u1',
        reporterName: 'Naomi',
        createdAt: now,
        updatedAt: now,
      );

      final copy = Incident.fromMap('abc', incident.toMap());

      expect(copy.title, 'Broken tap');
      expect(copy.category, 'Broken facilities');
      expect(copy.location, 'Block B');
      expect(copy.status, IncidentStatus.submitted);
      expect(copy.reporterId, 'u1');
      expect(copy.createdAt, now);
    });

    test('empty map falls back to safe defaults', () {
      final incident = Incident.fromMap('x', {});
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.category, 'Other');
      expect(incident.title, '');
      expect(incident.photoUrl, isNull);
    });

    test('photo is optional', () {
      final incident = Incident.fromMap('x', {'photoUrl': null});
      expect(incident.photoUrl, isNull);
    });
  });

  group('Statuses and categories', () {
    test('statuses are in progress order', () {
      expect(IncidentStatus.all, [
        'Submitted',
        'Under Review',
        'In Progress',
        'Resolved',
      ]);
    });

    test('every category has an icon', () {
      for (final c in IncidentCategories.all) {
        expect(CategoryStyle.iconFor(c), isA<IconData>());
      }
    });

    test('each status has a different colour', () {
      final colors = IncidentStatus.all.map(StatusChip.colorFor).toSet();
      expect(colors.length, IncidentStatus.all.length);
    });
  });
}
