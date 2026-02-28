import 'package:flutter/material.dart';

import '../models/voter.dart';
import 'voter_age_group_bar_chart.dart';
import 'voter_gender_pie_chart.dart';
import 'voter_list_widget.dart';

class VoterManagementDashboard extends StatefulWidget {
  const VoterManagementDashboard({
    super.key,
    required this.voters,
  });

  final List<Voter> voters;

  @override
  State<VoterManagementDashboard> createState() =>
      _VoterManagementDashboardState();
}

class _VoterManagementDashboardState extends State<VoterManagementDashboard> {
  late List<Voter> _allVoters;
  late List<Voter> _filteredVoters;

  String _searchQuery = '';
  String _selectedGender = 'All';
  String _selectedAgeGroup = 'All';

  @override
  void initState() {
    super.initState();
    _allVoters = List<Voter>.from(widget.voters);
    _filteredVoters = _allVoters;
  }

  @override
  void didUpdateWidget(covariant VoterManagementDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voters != widget.voters) {
      _allVoters = List<Voter>.from(widget.voters);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = _filteredVoters.length;
    final maleCount =
        _filteredVoters.where((v) => _isMale(v.gender)).length.toDouble();
    final femaleCount =
        _filteredVoters.where((v) => _isFemale(v.gender)).length.toDouble();
    final avgAge =
        total == 0 ? 0 : _filteredVoters.fold<int>(0, (s, v) => s + v.age) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.people_alt_rounded,
                label: 'Total Voters',
                value: total.toString(),
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.male_rounded,
                label: 'Male',
                value: maleCount.toInt().toString(),
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.female_rounded,
                label: 'Female',
                value: femaleCount.toInt().toString(),
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.calendar_month_rounded,
                label: 'Average Age',
                value: avgAge.toStringAsFixed(1),
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'Search by name or EPIC ID',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),

        // Filters
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedGender = value;
                    _applyFilters();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedAgeGroup,
                decoration: InputDecoration(
                  labelText: 'Age Group',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: '18-25',
                    child: Text('18–25'),
                  ),
                  DropdownMenuItem(
                    value: '26-40',
                    child: Text('26–40'),
                  ),
                  DropdownMenuItem(
                    value: '41-60',
                    child: Text('41–60'),
                  ),
                  DropdownMenuItem(
                    value: '60+',
                    child: Text('60+'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedAgeGroup = value;
                    _applyFilters();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Analytics section
        Text(
          'Analytics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: VoterGenderPieChart(voters: _filteredVoters),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: VoterAgeGroupBarChart(voters: _filteredVoters),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Voter List',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        VoterListWidget(voters: _filteredVoters),
      ],
    );
  }

  void _applyFilters() {
    var list = List<Voter>.from(_allVoters);

    // Text search: name or EPIC ID (case-insensitive).
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where(
            (v) =>
                v.name.toLowerCase().contains(query) ||
                v.epicId.toLowerCase().contains(query),
          )
          .toList();
    }

    // Gender filter.
    if (_selectedGender == 'Male') {
      list = list.where((v) => _isMale(v.gender)).toList();
    } else if (_selectedGender == 'Female') {
      list = list.where((v) => _isFemale(v.gender)).toList();
    }

    // Age-group filter.
    list = list.where((v) {
      final age = v.age;
      switch (_selectedAgeGroup) {
        case '18-25':
          return age >= 18 && age <= 25;
        case '26-40':
          return age >= 26 && age <= 40;
        case '41-60':
          return age >= 41 && age <= 60;
        case '60+':
          return age >= 60;
        default:
          return true;
      }
    }).toList();

    _filteredVoters = list;
  }

  bool _isMale(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'm' ||
        v.contains('male') ||
        raw.contains('ஆண்') ||
        raw.contains('पुरुष');
  }

  bool _isFemale(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'f' ||
        v.contains('female') ||
        raw.contains('பெண்') ||
        raw.contains('महिला');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

