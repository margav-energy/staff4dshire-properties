import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:staff4dshire_shared/shared.dart';
class DocumentUploadDialog extends StatefulWidget {
  final DocumentType? initialType;
  
  const DocumentUploadDialog({super.key, this.initialType});

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  late DocumentType? _selectedType;
  PlatformFile? _selectedFile;
  DateTime? _expiryDate;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  // Staff-specific document types
  final List<DocumentType> _staffDocumentTypes = [
    DocumentType.driverLicense,
    DocumentType.compliance,
    DocumentType.accreditation,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStaff = authProvider.currentUser?.role == UserRole.staff;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Document',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Document Type Selection (only show if not pre-selected)
            if (widget.initialType == null) ...[
              Text(
                'Document Type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (isStaff ? _staffDocumentTypes : DocumentType.values).map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    label: Text(_getDocumentTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Show selected document type
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document Type',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _getDocumentTypeLabel(_selectedType!),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // File Selection
            Text(
              'File',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: _selectedFile != null
                    ? Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(_selectedFile!.size),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isUploading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to select file',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Expiry Date (optional)
            Text(
              'Expiry Date (Optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploading ? null : _selectExpiryDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expiryDate != null
                          ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                          : 'No expiry date',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _expiryDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedType != null && _selectedFile != null && !_isUploading)
                    ? _uploadDocument
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Upload Document'),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        // On web, path is not available - we use bytes/name instead
        // On mobile, we can use path
        final isValidFile = kIsWeb
            ? (file.name.isNotEmpty) // On web, just check if file has a name
            : (file.path != null && file.path!.isNotEmpty); // On mobile, check path
        
        if (isValidFile) {
          setState(() {
            _selectedFile = file;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File selected: ${file.name}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid file selected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (pickedDate != null) {
      setState(() {
        _expiryDate = pickedDate;
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a document type'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    if (_selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a file to upload'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      
      // Generate a file URL (in a real app, this would upload to a server)
      final fileUrl = kIsWeb 
          ? 'web://${_selectedFile!.name}'
          : (_selectedFile!.path != null ? 'file://${_selectedFile!.path}' : 'file://${_selectedFile!.name}');
      
      debugPrint('Uploading document: ${_selectedFile!.name}, type: $_selectedType, URL: $fileUrl');
      
      // Create document
      final document = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _selectedFile!.name,
        type: _selectedType!,
        uploadDate: DateTime.now(),
        expiryDate: _expiryDate,
        fileUrl: fileUrl,
        isVerified: false,
      );

      await documentProvider.uploadDocument(document);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${_selectedFile!.name}" uploaded successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.driverLicense:
        return 'Driver License';
      case DocumentType.compliance:
        return 'Compliance';
      case DocumentType.accreditation:
        return 'Accreditation';
      case DocumentType.cscs:
        return 'CSCS';
      case DocumentType.healthSafety:
        return 'Health & Safety';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.cpp:
        return 'CPP';
      case DocumentType.rams:
        return 'RAMS';
      case DocumentType.other:
        return 'Other';
    }
  }
}
