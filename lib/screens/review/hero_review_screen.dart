import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../services/firestore_service.dart';

class HeroReviewScreen extends StatefulWidget {
  final JobModel job;
  final String heroId;

  const HeroReviewScreen({
    super.key,
    required this.job,
    required this.heroId,
  });

  @override
  State<HeroReviewScreen> createState() => _HeroReviewScreenState();
}

class _HeroReviewScreenState extends State<HeroReviewScreen> {
  int _rating = 5;
  final _selectedTags = <String>{};
  final _commentController = TextEditingController();
  bool _submitting = false;

  static const _ratingLabels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Great',
    5: 'Excellent!',
  };

  static const _tags = [
    {'icon': Icons.sentiment_satisfied_alt, 'label': 'Friendly Customer'},
    {'icon': Icons.navigation_outlined, 'label': 'Good Directions'},
    {'icon': Icons.favorite_border, 'label': 'Respectful'},
    {'icon': Icons.bolt, 'label': 'Quick Response'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Clear Communication'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await FirestoreService().submitReview(
        jobId: widget.job.id,
        reviewerId: widget.heroId,
        revieweeId: widget.job.customer.id,
        reviewerRole: 'hero',
        rating: _rating,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _skip() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.job.customer.name.isNotEmpty
        ? widget.job.customer.name.split(' ').first
        : 'Customer';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Rate Customer',
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
            const SizedBox(height: 32),

            // Green checkmark
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.brandGreen,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Job Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'How was your experience with $customerName?',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Rating card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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

            // Tags
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What went well? (Optional)',
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
                      color:
                          selected ? AppTheme.brandGreen.withOpacity(0.1) : Colors.white,
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
                  borderSide:
                      const BorderSide(color: AppTheme.brandGreen, width: 1.5),
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
                disabledBackgroundColor: AppTheme.brandGreen.withOpacity(0.6),
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
                  : const Text('Submit Feedback'),
            ),
          ),
        ),
      ),
    );
  }
}
