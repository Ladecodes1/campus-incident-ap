import 'package:flutter/material.dart';
import '../models/incident.dart';

// A small coloured label showing a report's status
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  static Color colorFor(String status) {
    switch (status) {
      case IncidentStatus.underReview:
        return Colors.orange;
      case IncidentStatus.inProgress:
        return Colors.blue;
      case IncidentStatus.resolved:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// An icon and colour for each category
class CategoryStyle {
  static IconData iconFor(String category) {
    switch (category) {
      case 'Broken facilities':
        return Icons.build_rounded;
      case 'Water shortage':
        return Icons.water_drop_rounded;
      case 'Electricity outage':
        return Icons.bolt_rounded;
      case 'Damaged furniture':
        return Icons.chair_alt_rounded;
      case 'Sanitation':
        return Icons.cleaning_services_rounded;
      case 'Safety concern':
        return Icons.shield_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }

  static Color colorFor(String category) {
    switch (category) {
      case 'Broken facilities':
        return Colors.deepOrange;
      case 'Water shortage':
        return Colors.lightBlue;
      case 'Electricity outage':
        return Colors.amber.shade700;
      case 'Damaged furniture':
        return Colors.brown;
      case 'Sanitation':
        return Colors.teal;
      case 'Safety concern':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}

// One report in the list
class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusChip.colorFor(incident.status);
    final catColor = CategoryStyle.colorFor(incident.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Coloured stripe showing the status
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryStyle.iconFor(incident.category),
                          color: catColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              incident.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 15),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    incident.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                StatusChip(status: incident.status),
                                const Spacer(),
                                Text(
                                  _formatDate(incident.createdAt),
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}