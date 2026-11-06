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
    final catColor = CategoryStyle.colorFor(incident.category);

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.photoUrl != null && incident.photoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
            // Title card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CategoryStyle.iconFor(incident.category),
                        color: catColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident.category,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Progress tracker
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Progress',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _StatusTracker(status: incident.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.place_outlined,
                      text: incident.location,
                    ),
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
                    const Divider(height: 24),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(incident.description),
                  ],
                ),
              ),
            ),
            // Only staff see this section
            if (auth.isStaff) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Staff: update status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: incident.status,
                        items: IncidentStatus.all
                            .map(
                              (s) =>
                                  DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null && v != incident.status) {
                            _changeStatus(context, incident, v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Four steps that fill in as the report moves along
class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = IncidentStatus.all;
    final current = steps.indexOf(status);
    final color = StatusChip.colorFor(status);

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= current ? color : Colors.grey.shade300),
                      ),
                    ),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          i <= current ? color : Colors.grey.shade300,
                      child: Icon(
                        i <= current ? Icons.check : Icons.circle,
                        size: i <= current ? 14 : 6,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i == steps.length - 1
                            ? Colors.transparent
                            : (i < current ? color : Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i == current ? FontWeight.bold : FontWeight.normal,
                    color: i <= current ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}