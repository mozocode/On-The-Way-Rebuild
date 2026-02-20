import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/view_mode_provider.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../menu/edit_profile_screen.dart';
import '../menu/payment_methods_screen.dart';
import '../menu/assistance_history_screen.dart';
import '../menu/messages_screen.dart';
import '../menu/settings_screen.dart';
import '../menu/invite_friends_screen.dart';
import '../request/location_screen.dart';
import '../request/service_subtype_screen.dart';
import '../request/vehicle_info_screen.dart';
import '../review/customer_review_screen.dart';
import '../hero_onboarding/hero_onboarding_screen.dart';
import 'tracking_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String? _lastActiveJobId;
  bool _reviewShown = false;
  StreamSubscription? _completionSub;

  @override
  void dispose() {
    _completionSub?.cancel();
    super.dispose();
  }

  void _checkForCompletion(JobModel? activeJob) {
    if (activeJob != null) {
      _lastActiveJobId = activeJob.id;
      _reviewShown = false;
    } else if (_lastActiveJobId != null && !_reviewShown) {
      _reviewShown = true;
      final jobId = _lastActiveJobId!;
      _lastActiveJobId = null;
      _navigateToReviewIfCompleted(jobId);
    }
  }

  Future<void> _navigateToReviewIfCompleted(String jobId) async {
    try {
      final job = await FirestoreService().getJob(jobId);
      if (job == null || job.status != JobStatus.completed) return;
      final alreadyReviewed = await FirestoreService().hasReview(jobId, 'customer');
      if (alreadyReviewed) return;
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerReviewScreen(job: job, customerId: user.id),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeJob = ref.watch(activeCustomerJobProvider);
    final firstName = user?.firstName ?? user?.displayName ?? 'there';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: activeJob.when(
          data: (job) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkForCompletion(job);
            });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'How can we assist you?',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              // Hamburger menu
              IconButton(
                onPressed: () => _showMenu(context, ref),
                icon: Icon(Icons.menu, size: 28, color: textColor),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Services heading
          Text(
            'Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
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
                  final serviceId = item['serviceId'] as String;
                  final serviceLabel = item['label'] as String;
                  ref.read(jobCreationProvider.notifier).setServiceType(serviceId);

                  if (serviceId == 'towing') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceSubTypeScreen(
                          serviceType: serviceId,
                          serviceLabel: serviceLabel,
                          allowMultiple: true,
                          options: const [
                            SubTypeOption(
                              id: 'tow',
                              title: 'Tow',
                              subtitle: 'Transport vehicle to another location',
                              icon: Icons.local_shipping,
                            ),
                            SubTypeOption(
                              id: 'winch',
                              title: 'Winch',
                              subtitle: 'Pull vehicle from stuck position',
                              icon: Icons.link,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (serviceId == 'winch_out') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationScreen(
                          serviceType: serviceId,
                          serviceLabel: serviceLabel,
                          totalSteps: 3,
                          currentStep: 1,
                        ),
                      ),
                    );
                  } else if (serviceId == 'dead_battery') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceSubTypeScreen(
                          serviceType: serviceId,
                          serviceLabel: serviceLabel,
                          options: const [
                            SubTypeOption(
                              id: 'standard_jump',
                              title: 'Standard Battery Jump',
                              subtitle: 'Traditional 12V battery jump start',
                              icon: Icons.flash_on,
                            ),
                            SubTypeOption(
                              id: 'ev_charge',
                              title: 'Electric Vehicle Charge',
                              subtitle: 'Mobile EV charging assistance',
                              icon: Icons.ev_station,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleInfoScreen(
                          serviceType: serviceId,
                          serviceLabel: serviceLabel,
                        ),
                      ),
                    );
                  }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerTrackingScreen(jobId: job.id),
                  ),
                );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In dark mode use the white icon variant from assets/icons/dark/
    final iconPath = isDark
        ? svgAsset.replaceFirst('assets/icons/', 'assets/icons/dark/')
        : svgAsset;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
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
                iconPath,
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24, color: isDark ? Colors.white : Colors.black),
                  ),
                  Expanded(
                    child: Text(
                      'Menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
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
                child: isHero
                    ? _buildHeroMenuItems(context, ref, displayName, email, initial, isDark, cardColor)
                    : _buildCustomerMenuItems(context, ref, displayName, email, initial, isDark, bgColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero user menu (when viewing customer side) ───────────────────────────
  Widget _buildHeroMenuItems(BuildContext context, WidgetRef ref, String displayName, String email, String initial, bool isDark, Color cardColor) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Profile card (compact)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.brandGreen, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.brandGreen)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Switch to Hero Mode
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

        const SizedBox(height: 12),

        // Hero menu order: Profile, Assistance History, Payment, Messages, Settings, Invite Others
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
          iconColor: isDark ? Colors.grey[400]! : Colors.grey[700]!,
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

        // Logout
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
                Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  // ─── Regular customer menu ─────────────────────────────────────────────────
  Widget _buildCustomerMenuItems(BuildContext context, WidgetRef ref, String displayName, String email, String initial, bool isDark, Color bgColor) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Profile header with avatar + Edit Profile button
        Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Edit Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Customer menu order: Messages, Invite Others, Assistance History, Settings, Help Center, Be A Hero!, Logout
        _MenuItemTile(
          icon: Icons.chat_bubble_outline,
          iconColor: isDark ? Colors.white : Colors.grey[800]!,
          iconBgColor: isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          label: 'Messages',
          subtitle: 'Messages and notifications',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
          },
        ),

        const SizedBox(height: 12),

        _MenuItemTile(
          icon: Icons.group_outlined,
          iconColor: Colors.blue,
          iconBgColor: Colors.blue.withOpacity(0.1),
          label: 'Invite Others',
          subtitle: 'Share the app with friends',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteFriendsScreen()));
          },
        ),

        const SizedBox(height: 12),

        _MenuItemTile(
          icon: Icons.history,
          iconColor: AppTheme.brandGreen,
          iconBgColor: AppTheme.brandGreen.withOpacity(0.1),
          label: 'Assistance History',
          subtitle: 'View your assistance history',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistanceHistoryScreen()));
          },
        ),

        const SizedBox(height: 12),

        _MenuItemTile(
          icon: Icons.settings_outlined,
          iconColor: isDark ? Colors.grey[400]! : Colors.grey[700]!,
          iconBgColor: Colors.grey.withOpacity(0.1),
          label: 'Settings',
          subtitle: 'Customize app appearance',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),

        const SizedBox(height: 12),

        _MenuItemTile(
          icon: Icons.help_outline,
          iconColor: Colors.purple,
          iconBgColor: Colors.purple.withOpacity(0.1),
          label: 'Help Center',
          subtitle: 'Get support and assistance',
          onTap: () {
            // TODO: Navigate to help center
          },
        ),

        const SizedBox(height: 12),

        // Be A Hero!
        _MenuItemTile(
          icon: Icons.local_taxi,
          iconColor: AppTheme.brandGreen,
          iconBgColor: AppTheme.brandGreen.withOpacity(0.1),
          label: 'Be A Hero!',
          subtitle: 'Start earning as a hero',
          highlightColor: AppTheme.brandGreen,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HeroOnboardingScreen()),
            );
          },
        ),

        const SizedBox(height: 20),

        // Logout
        _MenuItemTile(
          icon: Icons.logout,
          iconColor: Colors.red,
          iconBgColor: Colors.red.withOpacity(0.08),
          label: 'Logout',
          subtitle: 'Sign out from your account',
          highlightColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            ref.read(heroViewModeProvider.notifier).state = false;
            ref.read(authProvider.notifier).signOut();
          },
        ),

        const SizedBox(height: 48),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? highlightColor;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = highlightColor != null
        ? highlightColor!.withOpacity(isDark ? 0.15 : 0.06)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final labelColor = highlightColor ?? (isDark ? Colors.white : const Color(0xFF1A1A1A));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: highlightColor?.withOpacity(0.8) ?? (isDark ? Colors.grey[500] : Colors.grey[500]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, size: 20, color: highlightColor ?? Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
