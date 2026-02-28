import 'package:flutter/material.dart';

import '../models/voter.dart';
import '../services/voter_service.dart';

class VoterListPage extends StatefulWidget {
  const VoterListPage({super.key});

  @override
  State<VoterListPage> createState() => _VoterListPageState();
}

class _VoterListPageState extends State<VoterListPage> {
  late final VoterService _voterService;
  List<Voter> _voters = [];
  List<Voter> _filteredVoters = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _voterService = const VoterService();
    _loadVoters();
  }

  /// Load voters from JSON
  Future<void> _loadVoters() async {
    try {
      setState(() => _isLoading = true);
      
      final voters = await _voterService.loadVoters();
      
      if (mounted) {
        setState(() {
          _voters = voters;
          _filteredVoters = voters;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading voters: $error'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  /// Search voters
  void _searchVoters(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVoters = _voters;
      } else {
        _filteredVoters = _voters
            .where((voter) =>
                voter.name.toLowerCase().contains(query.toLowerCase()) ||
                voter.epicId.toLowerCase().contains(query.toLowerCase()) ||
                voter.fatherName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Filter by gender
  void _filterByGender(String gender) {
    setState(() {
      if (gender.isEmpty) {
        _filteredVoters = _voters;
      } else {
        _filteredVoters =
            _voters.where((voter) => voter.gender == gender).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voter Database'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: _searchVoters,
                        decoration: InputDecoration(
                          hintText: 'Search by name or EPIC ID...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('All (${_voters.length})'),
                              onSelected: (_) => _filterByGender(''),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Male'),
                              onSelected: (_) => _filterByGender('Male'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Female'),
                              onSelected: (_) => _filterByGender('Female'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text('Found (${_filteredVoters.length})'),
                              backgroundColor: Colors.green[100],
                              onSelected: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Voter List
                Expanded(
                  child: _filteredVoters.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No voters found'
                                : 'No matching voters found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredVoters.length,
                          itemBuilder: (context, index) {
                            final voter = _filteredVoters[index];
                            return VoterCard(voter: voter);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Voter info card widget
class VoterCard extends StatelessWidget {
  final Voter voter;

  const VoterCard({
    super.key,
    required this.voter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Gender
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voter.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Father: ${voter.fatherName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: voter.gender == 'Male'
                        ? Colors.blue[100]
                        : Colors.pink[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    voter.gender,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: voter.gender == 'Male'
                          ? Colors.blue[900]
                          : Colors.pink[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('Age', voter.age.toString()),
                _buildDetailItem('EPIC ID', voter.epicId),
                _buildDetailItem('Booth', voter.houseNumber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
