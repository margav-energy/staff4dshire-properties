import 'package:flutter/material.dart';

class RamsScreen extends StatefulWidget {
  const RamsScreen({super.key});

  @override
  State<RamsScreen> createState() => _RamsScreenState();
}

class _RamsScreenState extends State<RamsScreen> {
  final List<Map<String, dynamic>> _ramsDocuments = [
    {
      'id': '1',
      'title': 'Construction Site RAMS',
      'project': 'City Center Development',
      'version': '2.1',
      'date': '2024-01-15',
      'signed': false,
    },
    {
      'id': '2',
      'title': 'Working at Height RAMS',
      'project': 'City Center Development',
      'version': '1.5',
      'date': '2024-01-10',
      'signed': true,
    },
    {
      'id': '3',
      'title': 'Electrical Works RAMS',
      'project': 'Riverside Complex',
      'version': '1.0',
      'date': '2024-01-20',
      'signed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RAMS Sign-Off'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ramsDocuments.length,
        itemBuilder: (context, index) {
          final ram = _ramsDocuments[index];
          final isSigned = ram['signed'] as bool;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSigned ? Colors.green.shade50 : null,
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSigned
                      ? Colors.green.shade100
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSigned ? Icons.check_circle : Icons.description,
                  color: isSigned ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              title: Text(ram['title'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Project: ${ram['project']}'),
                  Text('Version: ${ram['version']} • ${ram['date']}'),
                ],
              ),
              trailing: isSigned
                  ? const Chip(
                      label: Text('Signed'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        _showSignOffDialog(context, ram);
                      },
                      child: const Text('Sign Off'),
                    ),
              onTap: () {
                // View RAMS document
              },
            ),
          );
        },
      ),
    );
  }

  void _showSignOffDialog(BuildContext context, Map<String, dynamic> ram) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Off RAMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ram['title'] as String,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'By signing off, you confirm that you have read, understood, and agree to comply with the Risk Assessment and Method Statement.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                ram['signed'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('RAMS signed off successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sign Off'),
          ),
        ],
      ),
    );
  }
}

