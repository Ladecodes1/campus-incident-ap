markdown
# Campus Incident Reporter

A Flutter mobile app that lets ALU students report campus issues (broken facilities, water or electricity problems, damaged furniture, sanitation, safety concerns) and lets authorised staff review reports and update their status.

## Features
- Register and log in with Firebase Authentication, restricted to ALU email domains and email verification required
- Submit incident reports with a title, category, location and description
- Browse reports live, search by text, and filter by category, status, or "My reports"
- Report details with a progress tracker (Submitted, Under Review, In Progress, Resolved)
- Staff-only status updates
- Students can delete their own report while it is still "Submitted"
- Role-based access control enforced by Firestore security rules

## Tech stack
- Flutter and Dart
- State management: Provider (`ChangeNotifier`)
- Firebase Authentication and Cloud Firestore
- Firebase Storage for photos

## Project structure

lib/
models/ Data classes (AppUser, Incident)
services/ Firebase calls (AuthService, IncidentService)
providers/ State management (AuthProvider, IncidentProvider)
screens/ Full pages (login, register, home, report form, details)
widgets/ Reusable components (IncidentCard, StatusChip)
app_theme.dart
main.dart


## User roles
- **Student:** the default role for every new account. Can submit, view, search and filter reports, and delete their own report while it is "Submitted".
- **Staff:** can change the status of any report. Staff roles are assigned manually by an administrator in the Firestore `users` collection, so nobody can make themselves staff.

## How to run
1. Install Flutter and set up an Android emulator or connect an Android phone.
2. Clone this repository.
3. Run `flutter pub get`.
4. Connect your own Firebase project with `flutterfire configure`, then enable Email/Password sign-in, Cloud Firestore and Storage.
5. Publish the Firestore security rules described in the report.
6. Run `flutter run`.

## Tests
Run `flutter test` to run the unit tests for the models, statuses and categories.

## Links
- Demo video: ADD LINK HERE