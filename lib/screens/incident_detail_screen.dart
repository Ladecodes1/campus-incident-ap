import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
  }

  Future<void> _changeStatus(
      BuildContext context, Incident incident, String newStatus) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.updateStatus(incident.id, newStatus);
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update the status.')),
      );
    }
  }

  Future<void> _delete(BuildContext context, Incident incident) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await provider.deleteIncident(incident.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Report deleted')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = context.watch<IncidentProvider>().byId(incidentId);
    final auth = context.watch<AuthProvider>();

    // The report was deleted or cannot be found
    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report')),
        body: const Center(child: Text('This report no longer exists.')),
      );
    }

    final isOwner = auth.user?.uid == incident.reporterId;
    final canDelete = isOwner && incident.status == IncidentStatus.submitted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete report',
              onPressed: () => _delete(context, incident),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.photoUrl != null && incident.photoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    incident.photoUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 80,
                      child: Center(child: Text('Photo could not be loaded')),
                    ),
                  ),
                ),
              ),
            Text(
              incident.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            StatusChip(status: incident.status),
            const SizedBox(height: 20),
            _InfoRow(icon: Icons.category_outlined, text: incident.category),
            _InfoRow(icon: Icons.place_outlined, text: incident.location),
            _InfoRow(
              icon: Icons.person_outline,
              text: 'Reported by ${incident.reporterName}',
            ),
            _InfoRow(
              icon: Icons.schedule,
              text: 'Submitted ${_formatDate(incident.createdAt)}',
            ),
            _InfoRow(
              icon: Icons.update,
              text: 'Last updated ${_formatDate(incident.updatedAt)}',
            ),
            const SizedBox(height: 20),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(incident.description),
            // Only staff see this section
            if (auth.isStaff) ...[
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Staff: update status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: incident.status,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: IncidentStatus.all
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null && v != incident.status) {
                    _changeStatus(context, incident, v);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}