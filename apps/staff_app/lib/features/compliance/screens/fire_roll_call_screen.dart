import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StaffMember {
  final String id;
  final String name;
  final String? project;
  final bool isAccounted;
  final DateTime? accountedAt;

  StaffMember({
    required this.id,
    required this.name,
    this.project,
    this.isAccounted = false,
    this.accountedAt,
  });
}

class FireRollCallScreen extends StatefulWidget {
  const FireRollCallScreen({super.key});

  @override
  State<FireRollCallScreen> createState() => _FireRollCallScreenState();
}

class _FireRollCallScreenState extends State<FireRollCallScreen> {
  final List<StaffMember> _staffMembers = [
    StaffMember(id: '1', name: 'John Doe', project: 'City Center Development'),
    StaffMember(id: '2', name: 'Jane Smith', project: 'City Center Development'),
    StaffMember(id: '3', name: 'Mike Johnson', project: 'Riverside Complex'),
    StaffMember(id: '4', name: 'Sarah Williams', project: 'City Center Development'),
    StaffMember(id: '5', name: 'David Brown', project: 'Park View Apartments'),
    StaffMember(id: '6', name: 'Emma Davis', project: 'City Center Development'),
    StaffMember(id: '7', name: 'Chris Wilson', project: 'Riverside Complex'),
    StaffMember(id: '8', name: 'Lisa Anderson', project: 'City Center Development'),
  ];

  bool _isEmergencyActive = false;
  DateTime? _emergencyStartTime;

  int get accountedCount => _staffMembers.where((s) => s.isAccounted).length;
  int get totalCount => _staffMembers.length;
  int get missingCount => totalCount - accountedCount;

  void _toggleEmergency() {
    setState(() {
      if (_isEmergencyActive) {
        _isEmergencyActive = false;
        _emergencyStartTime = null;
        // Reset all accounted status
        for (var i = 0; i < _staffMembers.length; i++) {
          _staffMembers[i] = StaffMember(
            id: _staffMembers[i].id,
            name: _staffMembers[i].name,
            project: _staffMembers[i].project,
            isAccounted: false,
          );
        }
      } else {
        _isEmergencyActive = true;
        _emergencyStartTime = DateTime.now();
      }
    });
  }

  void _markAsAccounted(StaffMember member) {
    setState(() {
      final index = _staffMembers.indexWhere((s) => s.id == member.id);
      if (index != -1) {
        _staffMembers[index] = StaffMember(
          id: member.id,
          name: member.name,
          project: member.project,
          isAccounted: true,
          accountedAt: DateTime.now(),
        );
      }
    });
  }

  void _markAllAsAccounted() {
    setState(() {
      for (var i = 0; i < _staffMembers.length; i++) {
        _staffMembers[i] = StaffMember(
          id: _staffMembers[i].id,
          name: _staffMembers[i].name,
          project: _staffMembers[i].project,
          isAccounted: true,
          accountedAt: DateTime.now(),
        );
      }
    });
  }

  void _exportRollCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fire Roll Call Report exported\n'
            'Total: $totalCount | Accounted: $accountedCount | Missing: $missingCount'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Roll Call'),
        actions: [
          if (_isEmergencyActive && accountedCount == totalCount)
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export Report',
              onPressed: _exportRollCall,
            ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: _isEmergencyActive
                ? (missingCount > 0 ? Colors.red : Colors.green)
                : Colors.orange,
            child: Column(
              children: [
                Icon(
                  _isEmergencyActive
                      ? (missingCount > 0 ? Icons.warning : Icons.check_circle)
                      : Icons.pending,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  _isEmergencyActive
                      ? (missingCount > 0 ? 'EMERGENCY - ROLL CALL IN PROGRESS' : 'ALL ACCOUNTED FOR')
                      : 'ROLL CALL READY',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isEmergencyActive && _emergencyStartTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Started: ${DateFormat('HH:mm:ss').format(_emergencyStartTime!)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(
                      label: 'Total',
                      value: totalCount.toString(),
                      color: Colors.white,
                    ),
                    _StatBox(
                      label: 'Accounted',
                      value: accountedCount.toString(),
                      color: Colors.white,
                    ),
                    _StatBox(
                      label: 'Missing',
                      value: missingCount.toString(),
                      color: missingCount > 0 ? Colors.yellow : Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _toggleEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _isEmergencyActive ? Colors.red : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    _isEmergencyActive ? 'END ROLL CALL' : 'START ROLL CALL',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: _isEmergencyActive
                ? Column(
                    children: [
                      if (missingCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.red.shade50,
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$missingCount staff member(s) still missing',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _staffMembers.length,
                          itemBuilder: (context, index) {
                            final member = _staffMembers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: member.isAccounted
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: member.isAccounted
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    member.isAccounted
                                        ? Icons.check_circle
                                        : Icons.person_outline,
                                    color: member.isAccounted ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  member.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (member.project != null) Text(member.project!),
                                    if (member.isAccounted && member.accountedAt != null)
                                      Text(
                                        'Accounted: ${DateFormat('HH:mm:ss').format(member.accountedAt!)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: member.isAccounted
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : ElevatedButton(
                                        onPressed: () => _markAsAccounted(member),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('MARK SAFE'),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (missingCount > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: _markAllAsAccounted,
                            icon: const Icon(Icons.done_all),
                            label: const Text('Mark All as Safe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fire_extinguisher,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ready to start fire roll call',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Press "START ROLL CALL" to begin',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

