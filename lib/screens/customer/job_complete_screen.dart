import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../utils/formatters.dart';

class JobCompleteScreen extends StatefulWidget {
  final JobModel job;
  final VoidCallback onDone;

  const JobCompleteScreen({
    super.key,
    required this.job,
    required this.onDone,
  });

  @override
  State<JobCompleteScreen> createState() => _JobCompleteScreenState();
}

class _JobCompleteScreenState extends State<JobCompleteScreen> {
  int _rating = 5;
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // TODO: submit rating to Firestore
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final heroName = widget.job.hero?.name ?? 'Your Hero';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppTheme.brandGreen, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Service Complete!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$heroName has completed your service.',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Price summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                        label: 'Base Price',
                        amount: widget.job.pricing.basePrice),
                    if (widget.job.pricing.heroTravelFee > 0)
                      _PriceRow(
                          label: 'Travel (${widget.job.pricing.heroTravelMiles.toStringAsFixed(1)} mi)',
                          amount: widget.job.pricing.heroTravelFee),
                    if (widget.job.pricing.heroTravelFee == 0)
                      _PriceRow(
                          label: 'Mileage',
                          amount: widget.job.pricing.mileagePrice),
                    if (widget.job.pricing.towingDistanceFee > 0)
                      _PriceRow(
                          label: 'Towing (${widget.job.pricing.towingDistanceMiles.toStringAsFixed(1)} mi)',
                          amount: widget.job.pricing.towingDistanceFee),
                    if (widget.job.pricing.priorityFee > 0)
                      _PriceRow(
                          label: 'Priority Fee',
                          amount: widget.job.pricing.priorityFee),
                    if (widget.job.pricing.winchFee > 0)
                      _PriceRow(
                          label: 'Winch Fee',
                          amount: widget.job.pricing.winchFee),
                    if (widget.job.pricing.addOns.afterHoursFee > 0)
                      _PriceRow(
                          label: 'After Hours Fee',
                          amount: widget.job.pricing.addOns.afterHoursFee),
                    if (widget.job.pricing.surgePricing.surgeAmount > 0)
                      _PriceRow(
                          label: 'Surge (${widget.job.pricing.surgePricing.formattedMultiplier})',
                          amount: widget.job.pricing.surgePricing.surgeAmount),
                    if (widget.job.pricing.discounts.totalDiscount > 0)
                      _PriceRow(
                          label: 'Discount',
                          amount: -widget.job.pricing.discounts.totalDiscount),
                    _PriceRow(
                        label: 'Service Fee',
                        amount: widget.job.pricing.serviceFee),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.currency(widget.job.pricing.total),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('Rate your Hero',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Leave feedback (optional)',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final int amount;

  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(Formatters.currency(amount)),
        ],
      ),
    );
  }
}
