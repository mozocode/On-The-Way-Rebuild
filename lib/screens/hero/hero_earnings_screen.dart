import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';

class HeroEarningsScreen extends ConsumerStatefulWidget {
  const HeroEarningsScreen({super.key});

  @override
  ConsumerState<HeroEarningsScreen> createState() => _HeroEarningsScreenState();
}

class _HeroEarningsScreenState extends ConsumerState<HeroEarningsScreen> {
  bool _withdrawing = false;
  bool _loadingConnectLink = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId;

    if (heroId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Earnings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: const Center(child: Text('Hero profile not found.')),
      );
    }

    final heroState = ref.watch(heroProvider(heroId));
    final hero = heroState.hero;
    final totalEarned = hero?.totalEarned ?? 0;
    final pendingPayout = hero?.pendingPayout ?? 0;
    final hasConnect = (hero?.stripeConnectAccountId ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Earnings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EarningsCard(label: 'Total earned', amountCents: totalEarned),
              const SizedBox(height: 12),
              _EarningsCard(label: 'Available to withdraw', amountCents: pendingPayout),
              const SizedBox(height: 24),
              if (!hasConnect) ...[
                const Text(
                  'Set up payouts to send earnings to your bank via Stripe.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loadingConnectLink ? null : () => _openConnectOnboarding(heroId, user?.email ?? ''),
                    icon: _loadingConnectLink
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.account_balance_wallet, size: 22),
                    label: Text(_loadingConnectLink ? 'Loading…' : 'Set up payouts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                if (pendingPayout >= 100)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _withdrawing ? null : () => _withdraw(heroId, pendingPayout),
                      icon: _withdrawing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payments, size: 22),
                      label: Text(_withdrawing ? 'Withdrawing…' : 'Withdraw \$${(pendingPayout / 100).toStringAsFixed(2)}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Text(
                    'Minimum withdrawal is \$1.00. Complete more jobs to earn.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                'Earnings are added to your balance when you complete a trip. Withdraw to your bank via Stripe Connect.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConnectOnboarding(String heroId, String email) async {
    setState(() => _loadingConnectLink = true);
    try {
      final baseUrl = Uri.base.origin;
      final result = await FirebaseFunctions.instance.httpsCallable('createConnectAccountLink').call({
        'heroId': heroId,
        'email': email,
        'refreshUrl': '$baseUrl/hero/earnings',
        'returnUrl': '$baseUrl/hero/earnings',
      });
      final data = result.data as Map<String, dynamic>?;
      final url = data != null ? data['url'] as String? : null;
      if (url != null && mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payout setup: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingConnectLink = false);
    }
  }

  Future<void> _withdraw(String heroId, int amountCents) async {
    setState(() => _withdrawing = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('createTransferToHero').call({
        'heroId': heroId,
        'amount': amountCents,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal started. Funds will reach your bank per Stripe\'s schedule.'), backgroundColor: AppTheme.brandGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final int amountCents;

  const _EarningsCard({required this.label, required this.amountCents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            '\$${(amountCents / 100).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.brandGreen),
          ),
        ],
      ),
    );
  }
}
