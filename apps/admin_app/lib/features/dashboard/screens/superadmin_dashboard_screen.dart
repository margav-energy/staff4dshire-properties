import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:staff4dshire_shared/shared.dart';
import '../widgets/welcome_banner.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
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
      // Superadmins see all users, so no userId filter needed
      // Pass null explicitly instead of undefined
      userProvider.loadUsers(userId: null);
      projectProvider.loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperAdmin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await authProvider.logout(userProvider: userProvider);
                  
                  if (mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  debugPrint('Error during logout: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error during logout: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Consumer4<CompanyProvider, UserProvider, ProjectProvider, AuthProvider>(
        builder: (context, companyProvider, userProvider, projectProvider, authProvider, child) {
          // Calculate stats from providers (after build completes)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (companyProvider.companies.isNotEmpty) {
              companyProvider.calculateStatsFromProviders(userProvider, projectProvider);
            }
          });

          final totalCompanies = companyProvider.totalCompanies;
          final activeCompanies = companyProvider.activeCompanies;
          final totalUsers = userProvider.users.length;
          final totalProjects = projectProvider.projects.length;
          final activeUsers = userProvider.users.where((u) => u.isActive).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                const WelcomeBanner(),

                const SizedBox(height: 24),

                // Overview Statistics
                Text(
                  'Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Companies',
                        value: totalCompanies.toString(),
                        icon: Icons.business,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Companies',
                        value: activeCompanies.toString(),
                        icon: Icons.business_center,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Users',
                        value: totalUsers.toString(),
                        icon: Icons.people,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Active Users',
                        value: activeUsers.toString(),
                        icon: Icons.person_outline,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Projects',
                        value: totalProjects.toString(),
                        icon: Icons.location_on,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Inactive Companies',
                        value: (totalCompanies - activeCompanies).toString(),
                        icon: Icons.business_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Companies Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Companies',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Show company management options
                        _showCompanyManagementOptions(context);
                      },
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Companies List
                if (companyProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (companyProvider.companies.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
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
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddCompanyDialog(context);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Company'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...companyProvider.companies.map((company) {
                    final stats = companyProvider.getCompanyStats(company.id);
                    return _CompanyCard(
                      company: company,
                      stats: stats,
                      onTap: () {
                        // Show company details in a dialog
                        _showCompanyDetails(context, company, stats);
                      },
                    );
                  }).toList(),

                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _ActionCard(
                      icon: Icons.add_business,
                      label: 'Add Company',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        _showAddCompanyDialog(context);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.manage_accounts,
                      label: 'Manage Companies',
                      color: Colors.blue,
                      onTap: () {
                        _showCompanyManagementOptions(context);
                      },
                    ),
                    _ActionCard(
                      icon: Icons.people,
                      label: 'All Users',
                      color: Colors.green,
                      onTap: () {
                        context.push('/users');
                      },
                    ),
                    _ActionCard(
                      icon: Icons.location_on,
                      label: 'All Projects',
                      color: Colors.orange,
                      onTap: () {
                        context.push('/projects/management');
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCompanyDialog(BuildContext context) async {
    // Use the new invitation-based company creation
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final adminEmailController = TextEditingController();
    bool createInvitation = true;

    final result = await showDialog<CompanyInvitation?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Company'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                    labelText: 'Company Email',
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
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Create Admin Invitation'),
                  subtitle: const Text('Send an invitation to create admin account'),
                  value: createInvitation,
                  onChanged: (value) {
                    setState(() {
                      createInvitation = value;
                    });
                  },
                ),
                if (createInvitation) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Admin Invitation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the admin email address. An invitation will be sent to complete registration.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email *',
                      hintText: 'admin@company.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
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

                if (createInvitation && adminEmailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin email is required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
                  
                  // Create company first
                  final newCompany = await companyProvider.createCompany(
                    {
                      'name': nameController.text,
                      'email': emailController.text.isNotEmpty ? emailController.text : null,
                      'phone_number': phoneController.text.isNotEmpty ? phoneController.text : null,
                      'address': addressController.text.isNotEmpty ? addressController.text : null,
                    },
                    userId: authProvider.currentUser?.id,
                  );

                  // Create invitation if requested
                  CompanyInvitation? invitation;
                  if (createInvitation) {
                    try {
                      // Use app base URL (not API URL) for invitation links
                      // This is the URL where users access the app
                      final invitationBaseUrl = ApiConfig.appBaseUrl;
                      
                      invitation = await CompanyInvitationApiService.createInvitation(
                        companyId: newCompany.id,
                        email: adminEmailController.text.trim(),
                        role: 'admin',
                        invitedById: authProvider.currentUser?.id,
                        expiresInDays: 30, // 30 days expiration
                        baseUrl: invitationBaseUrl,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Company created but invitation failed: ${e.toString()}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop(invitation);
                    
                    // Show invitation details if created
                    if (invitation != null) {
                      _showInvitationDetails(context, newCompany, invitation);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Company created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvitationDetails(BuildContext context, Company company, CompanyInvitation invitation) {
    // Get the appropriate URL for invitation links
    // For web: use current origin, for mobile: use deep link or code-only
    final appBaseUrl = ApiConfig.webAppUrl.isNotEmpty 
        ? ApiConfig.webAppUrl 
        : ApiConfig.appBaseUrl;
    
    // For mobile apps, we'll show code-only since deep links need app configuration
    // For web, show the full URL
    final isWeb = Uri.base.hasScheme; // Check if we're on web
    final invitationLink = isWeb 
        ? '$appBaseUrl/register?token=${invitation.invitationToken}'
        : 'Use invitation code: ${invitation.invitationToken}';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Company Created!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${company.name} has been created successfully!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Invitation email sent to: ${invitation.email}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Admin Invitation Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can also share these details manually:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              // QR Code (only show for web or if we have a valid URL)
              if (invitationLink.contains('http') || invitationLink.contains('://'))
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: QrImageView(
                              data: invitationLink,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scan to register',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (invitationLink.contains('http') || invitationLink.contains('://'))
                const SizedBox(height: 16),
              const SizedBox(height: 16),
              // Invitation Code
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invitation Code:',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: invitation.invitationToken));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation code copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        invitation.invitationToken,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Invitation Link (only show if it's a valid URL)
              if (invitationLink.contains('http') || invitationLink.contains('://'))
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invitation Link:',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Copy link',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: invitationLink));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation link copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          invitationLink,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              if (invitationLink.contains('http') || invitationLink.contains('://'))
                const SizedBox(height: 16),
              const SizedBox(height: 16),
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. An invitation email has been sent to ${invitation.email}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2. They will receive an email with:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• A registration link (click to register)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '• An invitation code (enter manually in app)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '3. To use the invitation code manually:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• Open the app and go to Registration',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '• Enter the invitation code: ${invitation.invitationToken}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4. The invitation expires on ${_formatInvitationDate(invitation.expiresAt)}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatInvitationDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Old method removed - using invitation-based system now
  void _OLD_SHOW_ADD_COMPANY_DIALOG_REMOVED(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    
    // Admin user fields
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final adminFirstNameController = TextEditingController();
    final adminLastNameController = TextEditingController();
    bool createAdmin = true;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Company'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                    labelText: 'Company Email',
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
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Create Admin User'),
                  subtitle: const Text('Create an admin account for this company'),
                  value: createAdmin,
                  onChanged: (value) {
                    setState(() {
                      createAdmin = value;
                    });
                  },
                ),
                if (createAdmin) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Admin User Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminFirstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminLastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Admin Password *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),
                ],
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

                if (createAdmin) {
                  if (adminEmailController.text.isEmpty ||
                      adminPasswordController.text.isEmpty ||
                      adminFirstNameController.text.isEmpty ||
                      adminLastNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All admin user fields are required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (adminPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                }

                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  
                  // Create company first
                  final newCompany = await companyProvider.createCompany(
                    {
                      'name': nameController.text,
                      'email': emailController.text.isNotEmpty ? emailController.text : null,
                      'phone_number': phoneController.text.isNotEmpty ? phoneController.text : null,
                      'address': addressController.text.isNotEmpty ? addressController.text : null,
                    },
                    userId: authProvider.currentUser?.id,
                  );

                  // Create admin user if requested
                  if (createAdmin && context.mounted) {
                    try {
                      // Create UserModel for the admin
                      final adminUserModel = UserModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID, backend will generate UUID
                        email: adminEmailController.text.trim(),
                        firstName: adminFirstNameController.text.trim(),
                        lastName: adminLastNameController.text.trim(),
                        role: UserRole.admin,
                        companyId: newCompany.id,
                        isActive: true,
                      );
                      
                      await userProvider.addUser(
                        adminUserModel,
                        password: adminPasswordController.text,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Company "${newCompany.name}" and admin user created successfully!\n'
                              'Admin can login with:\n'
                              'Email: ${adminEmailController.text.trim()}\n'
                              'Password: ${'*' * adminPasswordController.text.length}',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      // Company was created but admin user failed
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Company created but admin user creation failed: ${e.toString()}\n'
                              'You can create an admin user later from User Management.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  } else {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Company created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyManagementOptions(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text('Add New Company'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddCompanyDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Companies'),
              onTap: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                companyProvider.loadCompanies(userId: authProvider.currentUser?.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing companies...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View All Companies'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/companies');
              },
            ),
          ],
        ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final Map<String, dynamic> stats;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.company,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

