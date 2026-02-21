import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const _referralCode = 'OTWFE68CA';

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
                      'Invite Friends',
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Gift icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        size: 40,
                        color: AppTheme.brandGreen,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Give \$10, Get \$10',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Invite friends to OTW. When they complete their first service, you both get \$10 credit!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Referral code card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR REFERRAL CODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  _referralCode,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(const ClipboardData(text: _referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Referral code copied!'),
                                      backgroundColor: AppTheme.brandGreen,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.copy,
                                  size: 22,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // How it works
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'How it works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _howItWorksStep(
                      number: '1',
                      title: 'Share your code',
                      subtitle: 'Send your code to friends via text, email, or social media',
                    ),
                    const SizedBox(height: 16),
                    _howItWorksStep(
                      number: '2',
                      title: 'Friend signs up',
                      subtitle: 'They download the app and enter your referral code',
                    ),
                    const SizedBox(height: 16),
                    _howItWorksStep(
                      number: '3',
                      title: 'You both earn',
                      subtitle: 'After their first service, you both get \$10 credit',
                    ),

                    const SizedBox(height: 32),

                    // Share button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'Join me on On The Way! Use my referral code $_referralCode to get \$10 off your first service. Download the app: https://ontheway.app',
                            subject: 'Join On The Way - Get \$10 Off!',
                          );
                        },
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text(
                          'Share with Friends',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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

  Widget _howItWorksStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.brandGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
