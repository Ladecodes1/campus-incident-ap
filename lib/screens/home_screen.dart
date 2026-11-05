import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';
import '../models/incident.dart';
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
        title: Text(auth.isStaff ? 'Campus Incidents (Staff)' : 'Campus Incidents'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
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
          child: Text(
            hasFilters
                ? 'No reports match your search or filters.'
                : 'No reports yet. Tap "Report" to submit the first one.',
            textAlign: TextAlign.center,
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