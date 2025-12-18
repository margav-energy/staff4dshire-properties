import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import '../widgets/project_type_selection_widget.dart';

class StaffProjectSelectionScreen extends StatefulWidget {
  const StaffProjectSelectionScreen({super.key});

  @override
  State<StaffProjectSelectionScreen> createState() => _StaffProjectSelectionScreenState();
}

class _StaffProjectSelectionScreenState extends State<StaffProjectSelectionScreen> {
  Project? _selectedProject;

  @override
  void initState() {
    super.initState();
    // Load projects when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.loadProjects();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload projects when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProjectTypeSelectionWidget(
          selectedProject: _selectedProject,
          onProjectSelected: (project) {
            setState(() {
              _selectedProject = project;
            });
            Navigator.pop(context, project);
          },
        ),
      ),
    );
  }
}
