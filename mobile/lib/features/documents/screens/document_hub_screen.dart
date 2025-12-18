import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/document_provider.dart';
import '../../../core/models/document_model.dart';
import '../widgets/document_upload_dialog.dart';

class DocumentHubScreen extends StatefulWidget {
  const DocumentHubScreen({super.key});

  @override
  State<DocumentHubScreen> createState() => _DocumentHubScreenState();
}

class _DocumentHubScreenState extends State<DocumentHubScreen> {
  DocumentType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentProvider>(context, listen: false).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final expiringDocs = documentProvider.getExpiringDocuments();
    final expiredDocs = documentProvider.getExpiredDocuments();

    List<Document> documents;
    if (_selectedFilter != null) {
      documents = documentProvider.getDocumentsByType(_selectedFilter!);
    } else {
      documents = documentProvider.documents;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DocumentUploadDialog(),
              );
            },
          ),
        ],
      ),
      body: documentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Alerts Section
                if (expiredDocs.isNotEmpty || expiringDocs.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: expiredDocs.isNotEmpty
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              expiredDocs.isNotEmpty
                                  ? Icons.error_outline
                                  : Icons.warning_amber_rounded,
                              color: expiredDocs.isNotEmpty
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                expiredDocs.isNotEmpty
                                    ? '${expiredDocs.length} Document(s) Expired'
                                    : '${expiringDocs.length} Document(s) Expiring Soon',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: expiredDocs.isNotEmpty
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Filter Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _selectedFilter == null,
                          onTap: () {
                            setState(() {
                              _selectedFilter = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ...DocumentType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: _getDocumentTypeLabel(type),
                              isSelected: _selectedFilter == type,
                              onTap: () {
                                setState(() {
                                  _selectedFilter = type;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Documents List
                Expanded(
                  child: documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 64,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No documents found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            return _DocumentCard(document: doc);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const DocumentUploadDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
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
        return 'H&S';
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

  static void _viewDocument(BuildContext context, Document document) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${_getDocumentTypeLabelStatic(document.type)}'),
              const SizedBox(height: 8),
              Text('Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}'),
              if (document.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text('Expires: ${DateFormat('MMM dd, yyyy').format(document.expiryDate!)}'),
              ],
              if (document.isVerified) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('File: ${document.fileUrl}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _downloadDocument(BuildContext context, Document document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${document.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
    // In a real app, this would trigger a download
  }

  static Future<void> _deleteDocument(BuildContext context, Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      await documentProvider.deleteDocument(document.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${document.name} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  static String _getDocumentTypeLabelStatic(DocumentType type) {
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
        return 'H&S';
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = document.isExpired;
    final isExpiringSoon = document.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isExpired
          ? Colors.red.shade50
          : isExpiringSoon
              ? Colors.orange.shade50
              : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isExpired
                ? Colors.red.shade100
                : isExpiringSoon
                    ? Colors.orange.shade100
                    : theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.description,
            color: isExpired
                ? Colors.red
                : isExpiringSoon
                    ? Colors.orange
                    : theme.colorScheme.primary,
          ),
        ),
        title: Text(document.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getDocumentTypeLabel(document.type),
              style: theme.textTheme.bodySmall,
            ),
            if (document.expiryDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isExpired
                        ? Colors.red
                        : isExpiringSoon
                            ? Colors.orange
                            : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(document.expiryDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpired
                          ? Colors.red
                          : isExpiringSoon
                              ? Colors.orange
                              : theme.colorScheme.secondary,
                      fontWeight: isExpired || isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if (document.isVerified) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _viewDocument(context);
            } else if (value == 'download') {
              _downloadDocument(context);
            } else if (value == 'delete') {
              _deleteDocument(context);
            }
          },
        ),
      ),
    );
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
        return 'CSCS Card';
      case DocumentType.healthSafety:
        return 'Health & Safety Certificate';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.cpp:
        return 'CPP';
      case DocumentType.rams:
        return 'RAMS';
      case DocumentType.other:
        return 'Other Document';
    }
  }

  void _viewDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${_getDocumentTypeLabel(document.type)}'),
              const SizedBox(height: 8),
              Text('Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}'),
              if (document.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text('Expires: ${DateFormat('MMM dd, yyyy').format(document.expiryDate!)}'),
              ],
              if (document.isVerified) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('File: ${document.fileUrl}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${document.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
    // In a real app, this would trigger a download
  }

  Future<void> _deleteDocument(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      await documentProvider.deleteDocument(document.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${document.name} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

