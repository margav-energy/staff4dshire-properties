import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/timesheet_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../projects/screens/project_selection_screen.dart';
import '../../../core/models/project_model.dart';

class TimesheetEditScreen extends StatefulWidget {
  const TimesheetEditScreen({super.key});

  @override
  State<TimesheetEditScreen> createState() => _TimesheetEditScreenState();
}

class _TimesheetEditScreenState extends State<TimesheetEditScreen> {
  DateTime _selectedStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  String? _selectedStaffFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isSupervisor = authProvider.currentUser?.role == UserRole.supervisor || 
                        authProvider.currentUser?.role == UserRole.admin;

    // Get all entries filtered by date range
    final allEntries = timesheetProvider.entries.where((entry) {
      final entryDate = entry.signInTime;
      final afterStart = entryDate.isAfter(_selectedStartDate.subtract(const Duration(days: 1)));
      final beforeEnd = entryDate.isBefore(_selectedEndDate.add(const Duration(days: 1)));
      
      if (!afterStart || !beforeEnd) return false;
      
      if (_selectedStaffFilter != null && 
          _selectedStaffFilter != 'All Staff' && 
          entry.staffId != _selectedStaffFilter) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Group by staff
    final Map<String, List<TimeEntry>> entriesByStaff = {};
    for (var entry in allEntries) {
      final key = entry.staffId;
      if (!entriesByStaff.containsKey(key)) {
        entriesByStaff[key] = [];
      }
      entriesByStaff[key]!.add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Timesheets'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedStartDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedEndDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entries List
          Expanded(
            child: allEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 64,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No timesheet entries found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allEntries.length,
                    itemBuilder: (context, index) {
                      final entry = allEntries[index];
                      final duration = entry.duration;
                      final hours = duration.inHours;
                      final minutes = duration.inMinutes.remainder(60);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _editEntry(context, entry),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('dd').format(entry.signInTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(entry.signInTime),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(entry.projectName)),
                              if (entry.approvalStatus == ApprovalStatus.approved)
                                Icon(Icons.check_circle, 
                                     color: Colors.green, 
                                     size: 20),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${entry.staffName}'),
                              Text(
                                '${DateFormat('HH:mm').format(entry.signInTime)} - ${entry.signOutTime != null ? DateFormat('HH:mm').format(entry.signOutTime!) : 'In Progress'}',
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${hours}h ${minutes}m',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _editEntry(BuildContext context, TimeEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimesheetEntryEditScreen(entry: entry),
      ),
    );
    
    // Refresh the list
    if (mounted) {
      setState(() {});
    }
  }
}

class TimesheetEntryEditScreen extends StatefulWidget {
  final TimeEntry entry;

  const TimesheetEntryEditScreen({
    super.key,
    required this.entry,
  });

  @override
  State<TimesheetEntryEditScreen> createState() => _TimesheetEntryEditScreenState();
}

class _TimesheetEntryEditScreenState extends State<TimesheetEntryEditScreen> {
  late DateTime _signInTime;
  late DateTime? _signOutTime;
  late String _selectedProjectId;
  late String _selectedProjectName;

  @override
  void initState() {
    super.initState();
    _signInTime = widget.entry.signInTime;
    _signOutTime = widget.entry.signOutTime;
    _selectedProjectId = widget.entry.projectId;
    _selectedProjectName = widget.entry.projectName;
  }

  Future<void> _selectSignInTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _signInTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_signInTime),
    );
    if (time == null) return;

    setState(() {
      _signInTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectSignOutTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _signOutTime ?? DateTime.now(),
      firstDate: _signInTime,
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_signOutTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _signOutTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      
      // Ensure sign out is after sign in
      if (_signOutTime!.isBefore(_signInTime)) {
        _signOutTime = _signInTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectProject() async {
    final result = await Navigator.push<Project>(
      context,
      MaterialPageRoute(builder: (context) => const ProjectSelectionScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedProjectId = result.id;
        _selectedProjectName = result.name;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_signOutTime != null && _signOutTime!.isBefore(_signInTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign out time must be after sign in time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
    
    final updatedEntry = TimeEntry(
      id: widget.entry.id,
      signInTime: _signInTime,
      signOutTime: _signOutTime,
      projectId: _selectedProjectId,
      projectName: _selectedProjectName,
      location: widget.entry.location,
      latitude: widget.entry.latitude,
      longitude: widget.entry.longitude,
      approvalStatus: ApprovalStatus.pending, // Reset to pending when edited
      staffId: widget.entry.staffId,
      staffName: widget.entry.staffName,
    );

    await timesheetProvider.updateEntry(widget.entry.id, updatedEntry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timesheet entry updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = _signOutTime != null 
        ? _signOutTime!.difference(_signInTime) 
        : Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Timesheet Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Staff Information (Read-only)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Name',
                      value: widget.entry.staffName,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Project Selection
            Card(
              child: InkWell(
                onTap: _selectProject,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedProjectName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sign In Time
            Card(
              child: InkWell(
                onTap: () => _selectSignInTime(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.login,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign In Time',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(_signInTime),
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sign Out Time
            Card(
              child: InkWell(
                onTap: () => _selectSignOutTime(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Out Time',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _signOutTime != null
                                  ? DateFormat('MMM dd, yyyy HH:mm').format(_signOutTime!)
                                  : 'Not set',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _signOutTime != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Duration Summary
            Card(
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Duration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _signOutTime != null
                          ? '${hours}h ${minutes}m'
                          : 'In Progress',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


