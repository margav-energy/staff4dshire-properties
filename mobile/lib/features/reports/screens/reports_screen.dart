import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/timesheet_provider.dart';
import '../../../core/services/timesheet_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedProject;
  String? _selectedStaff;
  String? _selectedReportType = 'Attendance';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedReport;

  final List<String> _projects = [
    'All Projects',
    'City Center Development',
    'Riverside Complex',
    'Park View Apartments',
  ];

  final List<String> _staffMembers = [
    'All Staff',
    'John Doe',
    'Jane Smith',
    'Mike Johnson',
  ];

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final allEntries = timesheetProvider.entries;

      // Filter entries based on date range
      final filteredEntries = allEntries.where((entry) {
        final entryDate = entry.signInTime;
        final afterStart = entryDate.isAfter(_startDate.subtract(const Duration(days: 1)));
        final beforeEnd = entryDate.isBefore(_endDate.add(const Duration(days: 1)));
        
        if (!afterStart || !beforeEnd) return false;

        // Filter by project
        if (_selectedProject != null && 
            _selectedProject != 'All Projects' && 
            entry.projectName != _selectedProject) {
          return false;
        }

        return true;
      }).toList();

      // Calculate statistics
      Duration totalHours = Duration.zero;
      int totalEntries = filteredEntries.length;
      int completedEntries = filteredEntries.where((e) => e.signOutTime != null).length;
      Map<String, int> projectCounts = {};
      
      for (var entry in filteredEntries) {
        if (entry.signOutTime != null) {
          totalHours += entry.duration;
        }
        projectCounts[entry.projectName] = (projectCounts[entry.projectName] ?? 0) + 1;
      }

      // Generate report data
      _generatedReport = {
        'type': _selectedReportType,
        'startDate': _startDate,
        'endDate': _endDate,
        'project': _selectedProject ?? 'All Projects',
        'totalEntries': totalEntries,
        'completedEntries': completedEntries,
        'totalHours': totalHours.inHours,
        'totalMinutes': totalHours.inMinutes.remainder(60),
        'projectCounts': projectCounts,
        'entries': filteredEntries,
      };

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated successfully! ${filteredEntries.length} entries found.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportReport(String format) async {
    if (_generatedReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a report first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final entries = _generatedReport!['entries'] as List;
      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await TimesheetExportService.exportTimesheet(
        entries.cast(),
        format,
        context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully as $format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export',
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Type Cards
            Text(
              'Report Types',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.access_time,
                    title: 'Attendance',
                    description: 'Daily attendance records',
                    color: theme.colorScheme.primary,
                    isSelected: _selectedReportType == 'Attendance',
                    onTap: () {
                      setState(() {
                        _selectedReportType = 'Attendance';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.people,
                    title: 'Headcount',
                    description: 'Live headcount reports',
                    color: Colors.green,
                    isSelected: _selectedReportType == 'Headcount',
                    onTap: () {
                      setState(() {
                        _selectedReportType = 'Headcount';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.description,
                    title: 'Timesheets',
                    description: 'Hours worked reports',
                    color: theme.colorScheme.secondary,
                    isSelected: _selectedReportType == 'Timesheets',
                    onTap: () {
                      setState(() {
                        _selectedReportType = 'Timesheets';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.verified_user,
                    title: 'Compliance',
                    description: 'Safety compliance status',
                    color: Colors.orange,
                    isSelected: _selectedReportType == 'Compliance',
                    onTap: () {
                      setState(() {
                        _selectedReportType = 'Compliance';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Filters
            Text(
              'Filters',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Date Range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Project Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedProject ?? _projects.first,
                      items: _projects.map((project) {
                        return DropdownMenuItem(
                          value: project,
                          child: Text(project),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProject = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Staff Filter (if supervisor/admin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Member',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedStaff ?? _staffMembers.first,
                      items: _staffMembers.map((staff) {
                        return DropdownMenuItem(
                          value: staff,
                          child: Text(staff),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStaff = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Generate Report Button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            // Generated Report Summary
            if (_generatedReport != null) ...[
              const SizedBox(height: 32),
              Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Report Summary',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _generatedReport = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Report Type',
                        value: _generatedReport!['type'] as String,
                      ),
                      _SummaryRow(
                        label: 'Date Range',
                        value: '${DateFormat('MMM dd, yyyy').format(_generatedReport!['startDate'])} - ${DateFormat('MMM dd, yyyy').format(_generatedReport!['endDate'])}',
                      ),
                      _SummaryRow(
                        label: 'Total Entries',
                        value: '${_generatedReport!['totalEntries']}',
                      ),
                      _SummaryRow(
                        label: 'Completed Entries',
                        value: '${_generatedReport!['completedEntries']}',
                      ),
                      _SummaryRow(
                        label: 'Total Hours',
                        value: '${_generatedReport!['totalHours']}h ${_generatedReport!['totalMinutes']}m',
                      ),
                      if (_generatedReport!['projectCounts'] != null &&
                          (_generatedReport!['projectCounts'] as Map).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Projects',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_generatedReport!['projectCounts'] as Map<String, int>)
                            .entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        '${entry.value} entries',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('PDF');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('Excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('CSV');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

