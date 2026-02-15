import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/view_mode_provider.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../config/theme.dart';
import '../menu/edit_profile_screen.dart';
import '../menu/payment_methods_screen.dart';
import '../menu/assistance_history_screen.dart';
import '../menu/messages_screen.dart';
import '../menu/settings_screen.dart';
import '../menu/invite_friends_screen.dart';
import '../request/vehicle_info_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeJob = ref.watch(activeCustomerJobProvider);
    final firstName = user?.firstName ?? user?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: activeJob.when(
          data: (job) {
            if (job != null) return _buildActiveJobView(context, ref, job);
            return _buildServiceSelection(context, ref, firstName);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildServiceSelection(context, ref, firstName),
        ),
      ),
    );
  }

  Widget _buildServiceSelection(BuildContext context, WidgetRef ref, String firstName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey $firstName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'How can we assist you?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              // Hamburger menu
              IconButton(
                onPressed: () => _showMenu(context, ref),
                icon: const Icon(Icons.menu, size: 28, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Services heading
          const Text(
            'Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 16),

          // Service grid - 2 columns
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
            children: _serviceItems.map((item) {
              return _ServiceGridCard(
                svgAsset: item['svgAsset'] as String,
                label: item['label'] as String,
                serviceId: item['serviceId'] as String,
                onTap: () {
                  ref.read(jobCreationProvider.notifier).setServiceType(item['serviceId'] as String);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleInfoScreen(
                        serviceType: item['serviceId'] as String,
                        serviceLabel: item['label'] as String,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuDrawer(user: user, ref: ref),
    );
  }

  Widget _buildActiveJobView(BuildContext context, WidgetRef ref, JobModel job) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Request',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              IconButton(
                onPressed: () => _showMenu(context, ref),
                icon: const Icon(Icons.menu, size: 28, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.serviceType.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusIndicator(job.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to tracking screen
              },
              child: const Text('Track Hero', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(JobStatus status) {
    final labels = <JobStatus, String>{
      JobStatus.pending: 'Finding a Hero...',
      JobStatus.searching: 'Finding a Hero...',
      JobStatus.assigned: 'Hero Assigned',
      JobStatus.enRoute: 'Hero On The Way',
      JobStatus.arrived: 'Hero Has Arrived',
      JobStatus.inProgress: 'Service In Progress',
    };
    final label = labels[status] ?? 'Unknown';
    final color = status == JobStatus.arrived || status == JobStatus.inProgress
        ? AppTheme.brandGreen
        : AppTheme.brandDarkGreen;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Service items matching the reference design
  static final List<Map<String, dynamic>> _serviceItems = [
    {
      'svgAsset': 'assets/icons/Towing.svg',
      'label': 'Towing',
      'serviceId': 'towing',
    },
    {
      'svgAsset': 'assets/icons/Transportation.svg',
      'label': 'Transportation',
      'serviceId': 'winch_out',
    },
    {
      'svgAsset': 'assets/icons/JumpCharge.svg',
      'label': 'Jump/Charge',
      'serviceId': 'dead_battery',
    },
    {
      'svgAsset': 'assets/icons/Gas.svg',
      'label': 'Gas Delivery',
      'serviceId': 'fuel_delivery',
    },
    {
      'svgAsset': 'assets/icons/Lockout.svg',
      'label': 'Lockout Service',
      'serviceId': 'lockout',
    },
    {
      'svgAsset': 'assets/icons/Tire.svg',
      'label': 'Tire Change',
      'serviceId': 'flat_tire',
    },
  ];
}

class _ServiceGridCard extends StatelessWidget {
  final String svgAsset;
  final String label;
  final String serviceId;
  final VoidCallback onTap;

  const _ServiceGridCard({
    required this.svgAsset,
    required this.label,
    required this.serviceId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu Drawer ────────────────────────────────────────────────────────────

class _MenuDrawer extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;

  const _MenuDrawer({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final isHero = user?.role.toString().contains('hero') ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'Menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // balance the close icon
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Profile card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isHero ? AppTheme.brandGreen : AppTheme.brandGreen,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Switch to Hero Mode (only for users who are heroes)
                    if (isHero)
                      _MenuItemTile(
                        icon: Icons.verified,
                        iconColor: AppTheme.brandGreen,
                        iconBgColor: Colors.transparent,
                        label: 'Switch to Hero Mode',
                        trailing: Icon(Icons.tune, size: 20, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(heroViewModeProvider.notifier).state = true;
                        },
                      ),
                    if (isHero) const SizedBox(height: 12),

                    const SizedBox(height: 12),

                    // Menu items
                    _MenuItemTile(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue,
                      iconBgColor: Colors.blue.withOpacity(0.1),
                      label: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                    ),

                    const SizedBox(height: 12),

                    _MenuItemTile(
                      icon: Icons.access_time,
                      iconColor: AppTheme.brandGreen,
                      iconBgColor: AppTheme.brandGreen.withOpacity(0.1),
                      label: 'Assistance History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistanceHistoryScreen()));
                      },
                    ),

                    const SizedBox(height: 12),

                    _MenuItemTile(
                      icon: Icons.payment,
                      iconColor: Colors.purple,
                      iconBgColor: Colors.purple.withOpacity(0.1),
                      label: 'Payment',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                      },
                    ),

                    const SizedBox(height: 12),

                    _MenuItemTile(
                      icon: Icons.notifications_none,
                      iconColor: Colors.orange,
                      iconBgColor: Colors.orange.withOpacity(0.1),
                      label: 'Messages',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
                      },
                    ),

                    const SizedBox(height: 12),

                    _MenuItemTile(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.grey[700]!,
                      iconBgColor: Colors.grey.withOpacity(0.1),
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),

                    const SizedBox(height: 12),

                    _MenuItemTile(
                      icon: Icons.group_outlined,
                      iconColor: Colors.red,
                      iconBgColor: Colors.red.withOpacity(0.1),
                      label: 'Invite Others',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriendsScreen()));
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(heroViewModeProvider.notifier).state = false;
                        ref.read(authProvider.notifier).signOut();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
