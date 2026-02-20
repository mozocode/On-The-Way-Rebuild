import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../models/hero_application_model.dart';
import '../../../providers/hero_application_provider.dart';
import '../../../widgets/common/custom_button.dart';

class AgreementsStep extends ConsumerStatefulWidget {
  const AgreementsStep({super.key});

  @override
  ConsumerState<AgreementsStep> createState() => _AgreementsStepState();
}

class _AgreementsStepState extends ConsumerState<AgreementsStep>
    with AutomaticKeepAliveClientMixin {
  bool _terms = false;
  bool _privacy = false;
  bool _backgroundCheck = false;
  bool _contractor = false;
  bool _insurance = false;
  bool _safety = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final a = ref.read(heroApplicationProvider).application?.agreements;
    if (a == null) return;
    _terms = a.termsAccepted;
    _privacy = a.privacyAccepted;
    _backgroundCheck = a.backgroundCheckConsent;
    _contractor = a.independentContractorAgreement;
    _insurance = a.insuranceAcknowledgment;
    _safety = a.safetyPolicyAccepted;
  }

  bool get _allAccepted =>
      _terms && _privacy && _backgroundCheck && _contractor && _insurance && _safety;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSaving = ref.watch(isApplicationSavingProvider);
    final error = ref.watch(applicationErrorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Review & Agree',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Please review and accept the following',
            style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        const SizedBox(height: 20),

        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(error, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],

        _AgreementCard(
          title: 'Terms of Service',
          description: 'I have read and agree to the OTW Terms of Service.',
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          onView: () => _openUrl('https://otw.com/terms'),
        ),
        _AgreementCard(
          title: 'Privacy Policy',
          description: 'I have read and agree to the OTW Privacy Policy.',
          value: _privacy,
          onChanged: (v) => setState(() => _privacy = v ?? false),
          onView: () => _openUrl('https://otw.com/privacy'),
        ),
        _AgreementCard(
          title: 'Background Check Consent',
          description:
              'I consent to a background check including criminal history, driving record, and identity verification.',
          value: _backgroundCheck,
          onChanged: (v) => setState(() => _backgroundCheck = v ?? false),
        ),
        _AgreementCard(
          title: 'Independent Contractor Agreement',
          description:
              'I understand I will operate as an independent contractor, not an employee of OTW.',
          value: _contractor,
          onChanged: (v) => setState(() => _contractor = v ?? false),
          onView: () => _openUrl('https://otw.com/contractor-agreement'),
        ),
        _AgreementCard(
          title: 'Insurance Acknowledgment',
          description:
              'I confirm I maintain valid auto insurance meeting or exceeding state minimums.',
          value: _insurance,
          onChanged: (v) => setState(() => _insurance = v ?? false),
        ),
        _AgreementCard(
          title: 'Safety Policy',
          description:
              'I agree to follow all OTW safety guidelines while providing roadside assistance.',
          value: _safety,
          onChanged: (v) => setState(() => _safety = v ?? false),
          onView: () => _openUrl('https://otw.com/safety-policy'),
        ),

        const SizedBox(height: 20),

        // What happens next
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text('What happens next?',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700)),
              ]),
              const SizedBox(height: 10),
              Text(
                '1. We\'ll review your application (1-2 business days)\n'
                '2. Background check is conducted (3-5 business days)\n'
                '3. Once approved, start accepting jobs!',
                style: TextStyle(
                    color: Colors.blue.shade700, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Navigation
        Row(children: [
          Expanded(
            child: CustomButton(
              variant: ButtonVariant.outlined,
              onPressed: () =>
                  ref.read(heroApplicationProvider.notifier).previousStep(),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomButton(
              onPressed: _allAccepted && !isSaving ? _submit : null,
              isLoading: isSaving,
              child: const Text('Submit Application'),
            ),
          ),
        ]),

        if (!_allAccepted) ...[
          const SizedBox(height: 8),
          Text('Accept all agreements to submit',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    final agreements = Agreements(
      termsAccepted: _terms,
      termsAcceptedAt: DateTime.now(),
      privacyAccepted: _privacy,
      privacyAcceptedAt: DateTime.now(),
      backgroundCheckConsent: _backgroundCheck,
      backgroundCheckConsentAt: DateTime.now(),
      independentContractorAgreement: _contractor,
      independentContractorAgreementAt: DateTime.now(),
      insuranceAcknowledgment: _insurance,
      insuranceAcknowledgmentAt: DateTime.now(),
      safetyPolicyAccepted: _safety,
      safetyPolicyAcceptedAt: DateTime.now(),
    );

    final saved = await ref
        .read(heroApplicationProvider.notifier)
        .saveAgreements(agreements);
    if (!saved) return;

    final submitted =
        await ref.read(heroApplicationProvider.notifier).submitApplication();

    if (submitted && mounted) {
      _showSuccess();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle,
                  size: 56, color: AppTheme.brandGreen),
            ),
            const SizedBox(height: 20),
            const Text('Application Submitted!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'We\'ll review your application and get back to you within 1-2 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementCard extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onView;

  const _AgreementCard({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.brandGreen,
        title: Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (onView != null)
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30)),
              child: const Text('View', style: TextStyle(fontSize: 12)),
            ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
