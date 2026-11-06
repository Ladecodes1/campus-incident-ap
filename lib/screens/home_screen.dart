import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';
import 'incident_detail_screen.dart';
import 'submit_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _onlyMine = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IncidentProvider>();
    final uid = auth.user?.uid;
    final firstName = (auth.user?.name ?? '').split(' ').first;

    var list = provider.incidents;
    if (_onlyMine && uid != null) {
      list = list.where((i) => i.reporterId == uid).toList();
    }

    final hasFilters = provider.search.isNotEmpty ||
        provider.categoryFilter != null ||
        provider.statusFilter != null ||
        _onlyMine;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.isStaff ? 'Campus Incidents (Staff)' : 'Campus Incidents',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Report'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitIncidentScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                firstName.isEmpty ? 'Hello!' : 'Hi, $firstName 👋',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Status summary tiles (tap one to filter)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                for (final status in IncidentStatus.all) ...[
                  Expanded(
                    child: _StatTile(
                      label: status,
                      count: provider.countByStatus(status),
                      color: StatusChip.colorFor(status),
                      selected: provider.statusFilter == status,
                      onTap: () => provider.setStatusFilter(
                        provider.statusFilter == status ? null : status,
                      ),
                    ),
                  ),
                  if (status != IncidentStatus.all.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          provider.setSearch('');
                        },
                      ),
              ),
              onChanged: provider.setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: provider.categoryFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...IncidentCategories.all.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: provider.setCategoryFilter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: provider.statusFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      ...IncidentStatus.all.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s),
                        ),
                      ),
                    ],
                    onChanged: provider.setStatusFilter,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('My reports'),
                  selected: _onlyMine,
                  onSelected: (v) => setState(() => _onlyMine = v),
                ),
                const Spacer(),
                if (hasFilters)
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      provider.clearFilters();
                      setState(() => _onlyMine = false);
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildList(context, provider, list, hasFilters)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    IncidentProvider provider,
    List<Incident> list,
    bool hasFilters,
  ) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(provider.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.retry,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasFilters ? Icons.search_off : Icons.inbox_outlined,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                hasFilters
                    ? 'No reports match your search or filters.'
                    : 'No reports yet. Tap "Report" to submit the first one.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final incident = list[index];
        return IncidentCard(
          incident: incident,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncidentDetailScreen(incidentId: incident.id),
              ),
            );
          },
        );
      },
    );
  }
}

// One summary tile: a count and a status name
class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}