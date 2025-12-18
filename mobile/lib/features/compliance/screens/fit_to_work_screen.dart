import 'package:flutter/material.dart';

class FitToWorkScreen extends StatefulWidget {
  const FitToWorkScreen({super.key});

  @override
  State<FitToWorkScreen> createState() => _FitToWorkScreenState();
}

class _FitToWorkScreenState extends State<FitToWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isFit = true;
  String? _notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit to Work Declaration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please complete this declaration before starting work',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Declaration Title
              Text(
                'Are you fit to work today?',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Fit/Not Fit Toggle
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: _isFit
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : null,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isFit = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: _isFit
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Fit to Work',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _isFit
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: !_isFit
                          ? Colors.red.withOpacity(0.1)
                          : null,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isFit = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cancel,
                                size: 48,
                                color: !_isFit ? Colors.red : theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Not Fit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: !_isFit ? Colors.red : theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Notes Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional information...',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Submit declaration
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isFit
                              ? 'Fit to work declaration submitted'
                              : 'Not fit to work declaration submitted',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: _isFit
                      ? theme.colorScheme.primary
                      : Colors.red,
                ),
                child: Text(
                  _isFit ? 'Submit Declaration' : 'Report Not Fit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

