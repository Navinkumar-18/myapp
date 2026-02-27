import 'package:flutter/material.dart';

import '../services/bla_service.dart';
import 'admin_dashboard_screen.dart';
import 'voter_screen.dart';

class AccessGateScreen extends StatefulWidget {
  const AccessGateScreen({super.key});

  @override
  State<AccessGateScreen> createState() => _AccessGateScreenState();
}

class _AccessGateScreenState extends State<AccessGateScreen> {
  String _selectedRole = 'Admin';
  late final BlaService _blaService;
  late final Future<List<OfficerOption>> _officersFuture;
  OfficerOption? _selectedOfficer;

  @override
  void initState() {
    super.initState();
    _blaService = BlaService();
    _officersFuture = _blaService.fetchOfficers();
    _officersFuture.then((officers) {
      if (!mounted) return;
      if (officers.isEmpty) return;
      setState(() {
        _selectedOfficer ??= officers.first;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Election Party Access')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select role to continue',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'User', child: Text('User')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_selectedRole == 'Admin') ...[
                    FutureBuilder<List<OfficerOption>>(
                      future: _officersFuture,
                      builder: (context, snapshot) {
                        final officers = snapshot.data ?? const <OfficerOption>[];
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;
                        final selected = officers.contains(_selectedOfficer)
                            ? _selectedOfficer
                            : (officers.isNotEmpty ? officers.first : null);

                        return DropdownButtonFormField<OfficerOption>(
                          initialValue: selected,
                          decoration: InputDecoration(
                            labelText: 'Officer',
                            border: const OutlineInputBorder(),
                            helperText: isLoading ? 'Loading officers…' : null,
                          ),
                          items: officers
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o,
                                  child: Text(o.officerName),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: officers.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedOfficer = value;
                                  });
                                },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_selectedRole != 'Admin') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Only admin can view the admin dashboard.',
                              ),
                            ),
                          );
                          return;
                        }

                        final officer = _selectedOfficer;
                        if (officer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an officer.'),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AdminDashboardScreen(
                              officerId: officer.officerId,
                              officerName: officer.officerName,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Admin Dashboard'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VoterScreen(),
                          ),
                        );
                      },
                      child: const Text('Open Voter Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
