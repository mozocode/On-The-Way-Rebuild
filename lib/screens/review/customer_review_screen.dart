import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../services/firestore_service.dart';

class CustomerReviewScreen extends StatefulWidget {
  final JobModel job;
  final String customerId;

  const CustomerReviewScreen({
    super.key,
    required this.job,
    required this.customerId,
  });

  @override
  State<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  int _rating = 5;
  final _selectedTags = <String>{};
  final _commentController = TextEditingController();
  final _customTipController = TextEditingController();
  bool _submitting = false;
  int? _selectedTipCents;
  bool _showCustomTip = false;

  static const _ratingLabels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Great',
    5: 'Excellent!',
  };

  static const _tags = [
    {'icon': Icons.business_center, 'label': 'Professional'},
    {'icon': Icons.bolt, 'label': 'Fast Service'},
    {'icon': Icons.sentiment_satisfied_alt, 'label': 'Friendly'},
    {'icon': Icons.lightbulb_outline, 'label': 'Knowledgeable'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Great Communication'},
    {'icon': Icons.star_outline, 'label': 'Went Above & Beyond'},
  ];

  static const _tipPresets = [0, 300, 500, 1000];
  static const _tipLabels = ['No Tip', '\$3', '\$5', '\$10'];

  @override
  void dispose() {
    _commentController.dispose();
    _customTipController.dispose();
    super.dispose();
  }

  String get _submitButtonText {
    if (_showCustomTip && _customTipController.text.isNotEmpty) {
      final dollars = double.tryParse(_customTipController.text);
      if (dollars != null && dollars > 0) {
        return 'Submit & Tip \$${dollars.toStringAsFixed(0)}';
      }
    }
    if (_selectedTipCents != null && _selectedTipCents! > 0) {
      return 'Submit & Tip \$${(_selectedTipCents! / 100).toStringAsFixed(0)}';
    }
    return 'Submit Feedback';
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    int? tipCents = _selectedTipCents;
    if (_showCustomTip && _customTipController.text.isNotEmpty) {
      final dollars = double.tryParse(_customTipController.text);
      if (dollars != null && dollars > 0) {
        tipCents = (dollars * 100).round();
      }
    }
    if (tipCents == 0) tipCents = null;

    bool success = false;
    try {
      await FirestoreService().submitReview(
        jobId: widget.job.id,
        reviewerId: widget.customerId,
        revieweeId: widget.job.hero?.id ?? '',
        reviewerRole: 'customer',
        rating: _rating,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        tipAmountCents: tipCents,
      );
      success = true;
    } catch (e) {
      debugPrint('[Review] Submit failed: $e');
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Please try again.')),
      );
      setState(() => _submitting = false);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2C2C2C),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thank You!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your feedback helps our Heroes.',
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (mounted) setState(() => _submitting = false);
  }

  void _skip() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final heroName = widget.job.hero?.name.isNotEmpty == true
        ? widget.job.hero!.name.split(' ').first
        : 'Hero';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Rate Your Hero',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(height: 1.5, color: AppTheme.brandGreen),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 28),

            // Green shield checkmark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: AppTheme.brandGreen,
                size: 48,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              heroName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Your Hero',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),

            const SizedBox(height: 24),

            // Rating card
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _rating = starIndex),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starIndex <= _rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFC107),
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabels[_rating] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tip section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add a tip for Hero',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '100% of tips go directly to your Hero',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 14),

            // Tip presets: No Tip, $3, $5, $10
            Row(
              children: List.generate(_tipPresets.length, (i) {
                final cents = _tipPresets[i];
                final selected =
                    _selectedTipCents == cents && !_showCustomTip;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showCustomTip = false;
                          _selectedTipCents =
                              _selectedTipCents == cents ? null : cents;
                        });
                      },
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.brandGreen.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.brandGreen
                                : Colors.grey[300]!,
                            width: selected ? 2 : 1.5,
                          ),
                        ),
                        child: Text(
                          _tipLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.brandGreen
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            // $ Other
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showCustomTip = !_showCustomTip;
                    if (!_showCustomTip) {
                      _selectedTipCents = null;
                      _customTipController.clear();
                    }
                  });
                },
                child: Text(
                  '\$ Other',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showCustomTip
                        ? AppTheme.brandGreen
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),

            if (_showCustomTip) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customTipController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.brandGreen, width: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What stood out? (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _tags.map((tag) {
                final label = tag['label'] as String;
                final icon = tag['icon'] as IconData;
                final selected = _selectedTags.contains(label);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTags.remove(label);
                      } else {
                        _selectedTags.add(label);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.brandGreen.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? AppTheme.brandGreen
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? AppTheme.brandGreen
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.brandGreen
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Comments
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Additional Comments (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share any additional feedback...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.brandGreen, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.brandGreen.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(_submitButtonText),
            ),
          ),
        ),
      ),
    );
  }
}
