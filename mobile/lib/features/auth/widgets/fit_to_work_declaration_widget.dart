import 'package:flutter/material.dart';

class FitToWorkDeclaration {
  final bool isFit;
  final String? notes;
  final DateTime declaredAt;

  FitToWorkDeclaration({
    required this.isFit,
    this.notes,
    DateTime? declaredAt,
  }) : declaredAt = declaredAt ?? DateTime.now();
}

class FitToWorkDeclarationWidget extends StatefulWidget {
  final Function(FitToWorkDeclaration) onDeclarationComplete;
  final FitToWorkDeclaration? initialDeclaration;

  const FitToWorkDeclarationWidget({
    super.key,
    required this.onDeclarationComplete,
    this.initialDeclaration,
  });

  @override
  State<FitToWorkDeclarationWidget> createState() => _FitToWorkDeclarationWidgetState();
}

class _FitToWorkDeclarationWidgetState extends State<FitToWorkDeclarationWidget> {
  bool? _isFit;
  String? _notes;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDeclaration != null) {
      _isFit = widget.initialDeclaration!.isFit;
      _notes = widget.initialDeclaration!.notes;
      _notesController.text = _notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: _isFit == null
          ? Colors.orange.shade50
          : (_isFit! ? Colors.green.shade50 : Colors.red.shade50),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: _isFit == null
                      ? Colors.orange.shade700
                      : (_isFit! ? Colors.green.shade700 : Colors.red.shade700),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fit to Work Declaration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isFit == null
                          ? Colors.orange.shade900
                          : (_isFit! ? Colors.green.shade900 : Colors.red.shade900),
                    ),
                  ),
                ),
                if (_isFit != null)
                  Icon(
                    _isFit! ? Icons.check_circle : Icons.cancel,
                    color: _isFit! ? Colors.green.shade700 : Colors.red.shade700,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Please confirm you are fit to work today before signing in.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Fit/Not Fit Selection
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFit = true;
                      });
                      widget.onDeclarationComplete(
                        FitToWorkDeclaration(isFit: true, notes: _notes),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isFit == true
                            ? Colors.green.shade700
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFit == true
                              ? Colors.green.shade900
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _isFit == true ? Colors.white : Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fit to Work',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _isFit == true ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFit = false;
                      });
                      widget.onDeclarationComplete(
                        FitToWorkDeclaration(isFit: false, notes: _notes),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isFit == false
                            ? Colors.red.shade700
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFit == false
                              ? Colors.red.shade900
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: _isFit == false ? Colors.white : Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Not Fit',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: _isFit == false ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Notes field (shown after selection)
            if (_isFit != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional information...',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _notes = value.isEmpty ? null : value;
                  });
                  widget.onDeclarationComplete(
                    FitToWorkDeclaration(isFit: _isFit!, notes: _notes),
                  );
                },
              ),
            ],
            
            // Warning if not fit
            if (_isFit == false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will not be able to sign in if you are not fit to work. Please contact your supervisor.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

