import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      
      final userId = authProvider.currentUser?.id;
      companyProvider.loadCompanies(userId: userId);
      // Superadmins see all users, regular admins see only their company
      if (authProvider.currentUser?.isSuperadmin == true || authProvider.currentUser?.role == UserRole.superadmin) {
        userProvider.loadUsers();
      } else {
        userProvider.loadUsers(userId: userId);
      }
      projectProvider.loadProjects();
    });
  }

  void _refreshData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    final userId = authProvider.currentUser?.id;
    companyProvider.loadCompanies(userId: userId);
    // Superadmins see all users, regular admins see only their company
    if (authProvider.currentUser?.isSuperadmin == true || authProvider.currentUser?.role == UserRole.superadmin) {
      userProvider.loadUsers();
    } else {
      userProvider.loadUsers(userId: userId);
    }
    projectProvider.loadProjects();
    
    // Calculate stats
    if (companyProvider.companies.isNotEmpty) {
      companyProvider.calculateStatsFromProviders(userProvider, projectProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Companies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Consumer4<CompanyProvider, UserProvider, ProjectProvider, AuthProvider>(
        builder: (context, companyProvider, userProvider, projectProvider, authProvider, child) {
          // Calculate stats from providers
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (companyProvider.companies.isNotEmpty) {
              companyProvider.calculateStatsFromProviders(userProvider, projectProvider);
            }
          });

          if (companyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (companyProvider.companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No companies found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: companyProvider.companies.length,
              itemBuilder: (context, index) {
                final company = companyProvider.companies[index];
                final stats = companyProvider.getCompanyStats(company.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      _showCompanyDetails(context, company, stats);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      company.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (company.email != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        company.email!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: company.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  company.isActive ? 'Active' : 'Inactive',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: company.isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.people,
                                  value: '${stats['usersCount'] ?? 0}',
                                  label: 'Users',
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.location_on,
                                  value: '${stats['projectsCount'] ?? 0}',
                                  label: 'Projects',
                                  color: Colors.orange,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.person_outline,
                                  value: '${stats['activeUsersCount'] ?? 0}',
                                  label: 'Active',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCompanyDetails(BuildContext context, Company company, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(company.name),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: company.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                company.isActive ? 'Active' : 'Inactive',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: company.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (company.email != null) ...[
                _DetailRow(label: 'Email', value: company.email!),
                const SizedBox(height: 12),
              ],
              if (company.phoneNumber != null) ...[
                _DetailRow(label: 'Phone', value: company.phoneNumber!),
                const SizedBox(height: 12),
              ],
              if (company.address != null) ...[
                _DetailRow(label: 'Address', value: company.address!),
                const SizedBox(height: 12),
              ],
              if (company.domain != null) ...[
                _DetailRow(label: 'Domain', value: company.domain!),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    icon: Icons.people,
                    value: '${stats['usersCount'] ?? 0}',
                    label: 'Users',
                    color: theme.colorScheme.primary,
                  ),
                  _StatColumn(
                    icon: Icons.location_on,
                    value: '${stats['projectsCount'] ?? 0}',
                    label: 'Projects',
                    color: Colors.orange,
                  ),
                  _StatColumn(
                    icon: Icons.person_outline,
                    value: '${stats['activeUsersCount'] ?? 0}',
                    label: 'Active Users',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close details dialog first
              _showEditCompanyDialog(context, company);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close details dialog first
              _confirmDeleteCompany(context, company);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(BuildContext context, Company company) {
    final nameController = TextEditingController(text: company.name);
    final emailController = TextEditingController(text: company.email ?? '');
    final addressController = TextEditingController(text: company.address ?? '');
    final phoneController = TextEditingController(text: company.phoneNumber ?? '');
    final domainController = TextEditingController(text: company.domain ?? '');
    bool isActive = company.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Company: ${company.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(
                    labelText: 'Domain',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Company is active and operational'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Company name is required')),
                  );
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
                  
                  await companyProvider.updateCompany(
                    company.id,
                    {
                      'name': nameController.text,
                      'email': emailController.text.isNotEmpty ? emailController.text : null,
                      'phone_number': phoneController.text.isNotEmpty ? phoneController.text : null,
                      'address': addressController.text.isNotEmpty ? addressController.text : null,
                      'domain': domainController.text.isNotEmpty ? domainController.text : null,
                      'is_active': isActive,
                    },
                    userId: authProvider.currentUser?.id,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Company updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Refresh the list
                    _refreshData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCompany(BuildContext context, Company company) {
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${company.name}"?'),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. All users, projects, and data associated with this company will be deleted.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog
              
              try {
                await companyProvider.deleteCompany(
                  company.id,
                  userId: authProvider.currentUser?.id,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh the list
                  _refreshData();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting company: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

