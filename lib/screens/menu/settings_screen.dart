import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'light'; // system, light, dark
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ACCOUNT section
                    _sectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    _settingsItem(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue,
                      label: 'Personal Information',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _settingsItem(
                      icon: Icons.payment,
                      iconColor: AppTheme.brandGreen,
                      label: 'Payment Method',
                      onTap: () {},
                    ),

                    const SizedBox(height: 24),

                    // DISPLAY section
                    _sectionLabel('DISPLAY'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _themeChip('System', 'system', Icons.brightness_auto),
                        const SizedBox(width: 8),
                        _themeChip('Light', 'light', Icons.radio_button_checked),
                        const SizedBox(width: 8),
                        _themeChip('Dark', 'dark', Icons.dark_mode_outlined),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // NOTIFICATIONS section
                    _sectionLabel('NOTIFICATIONS'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_none, color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Push Notifications',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _pushNotifications,
                            onChanged: (v) => setState(() => _pushNotifications = v),
                            activeColor: AppTheme.brandGreen,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ABOUT section
                    _sectionLabel('ABOUT'),
                    const SizedBox(height: 8),
                    _settingsItem(
                      icon: Icons.verified_user_outlined,
                      iconColor: Colors.pink[300]!,
                      label: 'Privacy',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _settingsItem(
                      icon: Icons.description_outlined,
                      iconColor: Colors.purple[200]!,
                      label: 'Terms of Service',
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),

                    // Version
                    Center(
                      child: Text(
                        'OTW Version 1.0.0',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
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
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(String label, String value, IconData icon) {
    final selected = _themeMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _themeMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            border: Border.all(
              color: selected ? AppTheme.brandGreen : Colors.grey[300]!,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppTheme.brandGreen : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppTheme.brandGreen : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
