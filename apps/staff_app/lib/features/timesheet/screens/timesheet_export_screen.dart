import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:staff4dshire_shared/shared.dart';
class TimesheetExportScreen extends StatefulWidget {
  const TimesheetExportScreen({super.key});

  @override
  State<TimesheetExportScreen> createState() => _TimesheetExportScreenState();
}

class _TimesheetExportScreenState extends State<TimesheetExportScreen> {
  String _selectedFormat = 'PDF';
  bool _isExporting = false;

  Future<void> _exportTimesheet() async {
    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
    
    if (timesheetProvider.entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No timesheet entries to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await timesheetProvider.exportTimesheet(_selectedFormat, context: context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timesheet exported successfully as $_selectedFormat'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Timesheet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Export Format',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Format Options
            _FormatOption(
              format: 'PDF',
              icon: Icons.picture_as_pdf,
              description: 'Portable Document Format',
              isSelected: _selectedFormat == 'PDF',
              onTap: () {
                setState(() {
                  _selectedFormat = 'PDF';
                });
              },
            ),
            const SizedBox(height: 12),
            _FormatOption(
              format: 'Excel',
              icon: Icons.table_chart,
              description: 'Microsoft Excel (.xlsx)',
              isSelected: _selectedFormat == 'Excel',
              onTap: () {
                setState(() {
                  _selectedFormat = 'Excel';
                });
              },
            ),
            const SizedBox(height: 12),
            _FormatOption(
              format: 'CSV',
              icon: Icons.description,
              description: 'Comma Separated Values',
              isSelected: _selectedFormat == 'CSV',
              onTap: () {
                setState(() {
                  _selectedFormat = 'CSV';
                });
              },
            ),

            const Spacer(),

            // Export Button
            ElevatedButton(
              onPressed: _isExporting ? null : _exportTimesheet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Export'),
            ),
            
            if (Provider.of<TimesheetProvider>(context).entries.isEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No timesheet entries available to export',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
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
}

class _FormatOption extends StatelessWidget {
  final String format;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.format,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

