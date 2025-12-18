import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ToolboxTalkScreen extends StatefulWidget {
  const ToolboxTalkScreen({super.key});

  @override
  State<ToolboxTalkScreen> createState() => _ToolboxTalkScreenState();
}

class _ToolboxTalkScreenState extends State<ToolboxTalkScreen> {
  final List<Map<String, dynamic>> _toolboxTalks = [
    {
      'id': '1',
      'title': 'Site Safety Briefing',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'location': 'City Center Development',
      'attended': true,
      'signature': 'John Doe',
    },
    {
      'id': '2',
      'title': 'Working at Height',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'location': 'City Center Development',
      'attended': true,
      'signature': 'John Doe',
    },
    {
      'id': '3',
      'title': 'Electrical Safety',
      'date': DateTime.now().add(const Duration(days: 1)),
      'location': 'Riverside Complex',
      'attended': false,
      'signature': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolbox Talks'),
      ),
      body: Column(
        children: [
          // Upcoming Talks
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.event, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Toolbox Talks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Review and attend scheduled safety briefings',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Talks List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _toolboxTalks.length,
              itemBuilder: (context, index) {
                final talk = _toolboxTalks[index];
                final isPast = talk['date'].compareTo(DateTime.now()) < 0;
                final attended = talk['attended'] as bool;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: attended ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: attended
                            ? Colors.green.shade100
                            : isPast
                                ? Colors.orange.shade100
                                : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        attended
                            ? Icons.check_circle
                            : isPast
                                ? Icons.warning
                                : Icons.event,
                        color: attended
                            ? Colors.green
                            : isPast
                                ? Colors.orange
                                : theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(talk['title'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(talk['location'] as String),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(talk['date']),
                        ),
                        if (attended && talk['signature'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Attended • ${talk['signature']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: attended
                        ? const Chip(
                            label: Text('Attended'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : isPast
                            ? OutlinedButton(
                                onPressed: () {
                                  // Mark as attended
                                  setState(() {
                                    talk['attended'] = true;
                                    talk['signature'] = 'John Doe';
                                  });
                                },
                                child: const Text('Mark Attended'),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  // Attend toolbox talk
                                },
                                child: const Text('Attend'),
                              ),
                    onTap: () {
                      // View toolbox talk details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

