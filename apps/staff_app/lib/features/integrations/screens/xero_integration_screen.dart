import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:staff4dshire_shared/shared.dart';
class XeroIntegrationScreen extends StatefulWidget {
  const XeroIntegrationScreen({super.key});

  @override
  State<XeroIntegrationScreen> createState() => _XeroIntegrationScreenState();
}

class _XeroIntegrationScreenState extends State<XeroIntegrationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xeroProvider = Provider.of<XeroProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xero Integration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xero Accounting Integration',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sync your timesheets and create invoices automatically in Xero',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Connection Status Card
            Consumer<XeroProvider>(
              builder: (context, provider, child) {
                if (provider.isConnected && provider.connection != null) {
                  return Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Connected to Xero',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (provider.connection!.tenantName != null)
                            _InfoRow(
                              label: 'Organization',
                              value: provider.connection!.tenantName!,
                              theme: theme,
                            ),
                          if (provider.connection!.tenantId != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Tenant ID',
                              value: provider.connection!.tenantId!,
                              theme: theme,
                            ),
                          ],
                          if (provider.connection!.expiresAt != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Token Expires',
                              value: DateFormat('MMM dd, yyyy HH:mm')
                                  .format(provider.connection!.expiresAt!),
                              theme: theme,
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Disconnect Xero'),
                                          content: const Text(
                                            'Are you sure you want to disconnect from Xero? This will stop automatic syncing.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Disconnect'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true && mounted) {
                                        await provider.disconnectXero();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Disconnected from Xero'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.link_off),
                              label: const Text('Disconnect'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Card(
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.link_off,
                                color: theme.colorScheme.secondary,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Not Connected',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connect your Xero account to sync timesheets and create invoices automatically.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      await provider.connectXero();
                                      if (mounted && provider.errorMessage != null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(provider.errorMessage!),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.link),
                              label: Text(provider.isLoading
                                  ? 'Connecting...'
                                  : 'Connect to Xero'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),

            if (xeroProvider.isConnected) ...[
              const SizedBox(height: 24),

              // Sync Options Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Options',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SyncOptionTile(
                        icon: Icons.receipt,
                        title: 'Create Invoice from Timesheet',
                        description:
                            'Generate Xero invoices from approved timesheet entries',
                        onTap: () {
                          _showCreateInvoiceDialog(context);
                        },
                      ),
                      const Divider(),
                      _SyncOptionTile(
                        icon: Icons.people,
                        title: 'Sync Contacts',
                        description: 'View and manage Xero contacts',
                        onTap: () {
                          _showContactsDialog(context);
                        },
                      ),
                      const Divider(),
                      _SyncOptionTile(
                        icon: Icons.description,
                        title: 'View Invoices',
                        description: 'View invoices created in Xero',
                        onTap: () {
                          _showInvoicesDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: theme.colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Xero Integration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Automatically sync approved timesheets to Xero\n'
                      '• Create invoices with line items for each project\n'
                      '• Track payments and reconcile accounts\n'
                      '• Manage contacts and customer information\n'
                      '• Export timesheet data for accounting purposes',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateInvoiceDialog(BuildContext context) async {
    final xeroProvider = Provider.of<XeroProvider>(context, listen: false);
    final timesheetProvider =
        Provider.of<TimesheetProvider>(context, listen: false);

    // Get approved entries for invoicing
    final approvedEntries = timesheetProvider.getApprovedEntries();

    if (approvedEntries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No approved timesheet entries to invoice'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show dialog with options
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateInvoiceDialog(
        entries: approvedEntries,
        xeroProvider: xeroProvider,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice creation started'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showContactsDialog(BuildContext context) async {
    final xeroProvider = Provider.of<XeroProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loading Contacts...'),
        content: const CircularProgressIndicator(),
      ),
    );

    try {
      final contacts = await xeroProvider.getContacts();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => _ContactsDialog(contacts: contacts),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInvoicesDialog(BuildContext context) async {
    final xeroProvider = Provider.of<XeroProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loading Invoices...'),
        content: const CircularProgressIndicator(),
      ),
    );

    try {
      final invoices = await xeroProvider.getInvoices();
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => _InvoicesDialog(invoices: invoices),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoices: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SyncOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CreateInvoiceDialog extends StatefulWidget {
  final List<dynamic> entries;
  final XeroProvider xeroProvider;

  const _CreateInvoiceDialog({
    required this.entries,
    required this.xeroProvider,
  });

  @override
  State<_CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<_CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedContactId;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await widget.xeroProvider.getContacts();
      setState(() {
        _contacts = contacts.map((c) => {
          'id': c['ContactID'] ?? c['ContactId'],
          'name': c['Name'] ?? 'Unknown',
        }).toList();
        _loadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _loadingContacts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate() || _selectedContactId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Group entries by project
      final groupedEntries = <String, List<dynamic>>{};
      for (var entry in widget.entries) {
        final projectId = entry.projectId ?? 'unknown';
        groupedEntries.putIfAbsent(projectId, () => []).add(entry);
      }

      // Create line items
      final lineItems = <Map<String, dynamic>>[];
      for (var projectGroup in groupedEntries.entries) {
        double totalHours = 0;
        for (var entry in projectGroup.value) {
          final duration = entry.duration;
          totalHours += duration.inHours + (duration.inMinutes / 60);
        }

        lineItems.add({
          'Description': 'Labour for ${projectGroup.value.first.projectName}',
          'Quantity': totalHours,
          'UnitAmount': 0.0, // TODO: Get rate from settings/project
          'AccountCode': '200', // TODO: Configure account code
        });
      }

      final invoiceNumber =
          'INV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      await widget.xeroProvider.createInvoice(
        contactId: _selectedContactId!,
        invoiceNumber: invoiceNumber,
        date: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        lineItems: lineItems,
        description: 'Timesheet invoice for ${widget.entries.length} entries',
      );

      if (mounted) {
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Create Invoice from Timesheets'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.entries.length} approved timesheet entries selected',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_loadingContacts)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Contact',
                    prefixIcon: Icon(Icons.person),
                  ),
                  value: _selectedContactId,
                  items: _contacts.map((contact) {
                    return DropdownMenuItem<String>(
                      value: contact['id'] as String,
                      child: Text(contact['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContactId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a contact';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createInvoice,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Invoice'),
        ),
      ],
    );
  }
}

class _ContactsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;

  const _ContactsDialog({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Xero Contacts'),
      content: SizedBox(
        width: double.maxFinite,
        child: contacts.isEmpty
            ? const Text('No contacts found')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length > 10 ? 10 : contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ListTile(
                    title: Text(contact['Name'] ?? 'Unknown'),
                    subtitle: Text(
                      contact['EmailAddress'] ?? contact['FirstName'] ?? '',
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InvoicesDialog extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;

  const _InvoicesDialog({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Xero Invoices'),
      content: SizedBox(
        width: double.maxFinite,
        child: invoices.isEmpty
            ? const Text('No invoices found')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: invoices.length > 10 ? 10 : invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final date = invoice['Date'] != null
                      ? DateTime.tryParse(invoice['Date'])
                      : null;
                  final total = invoice['Total'] ?? 0.0;

                  return ListTile(
                    title: Text(invoice['InvoiceNumber'] ?? 'No Number'),
                    subtitle: date != null
                        ? Text(DateFormat('MMM dd, yyyy').format(date))
                        : null,
                    trailing: Text(
                      '£${total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}


