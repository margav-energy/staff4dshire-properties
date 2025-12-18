import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:staff4dshire_shared/shared.dart';
class InvoiceJobsSection extends StatelessWidget {
  const InvoiceJobsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer3<InvoiceProvider, ProjectProvider, UserProvider>(
      builder: (context, invoiceProvider, projectProvider, userProvider, child) {
        final invoices = invoiceProvider.invoices;
        final unpaidInvoices = invoiceProvider.getUnpaidInvoices();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invoice Jobs',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/invoices');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (invoices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No invoices',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Summary
                      Row(
                        children: [
                          Expanded(
                            child: _InvoiceSummaryCard(
                              title: 'Total',
                              value: invoices.length.toString(),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InvoiceSummaryCard(
                              title: 'Unpaid',
                              value: unpaidInvoices.length.toString(),
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Recent invoices
                      ...invoices.take(5).map((invoice) {
                        final project = projectProvider.projects.firstWhere(
                          (p) => p.id == invoice.projectId,
                          orElse: () => Project(id: invoice.projectId, name: 'Unknown', isActive: true),
                        );
                        final staff = userProvider.getUserById(invoice.staffId);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              invoice.isPaid ? Icons.check_circle : Icons.pending,
                              color: invoice.isPaid ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                              project.name,
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              '${staff?.fullName ?? invoice.staffId} • ${invoice.invoiceNumber}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  invoice.formattedAmount,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  invoice.isPaid ? 'Paid' : 'Unpaid',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: invoice.isPaid ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InvoiceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InvoiceSummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

