import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';

class PriceBreakdownCard extends StatefulWidget {
  final JobPricing pricing;
  final bool initiallyExpanded;

  const PriceBreakdownCard({
    super.key,
    required this.pricing,
    this.initiallyExpanded = false,
  });

  @override
  State<PriceBreakdownCard> createState() => _PriceBreakdownCardState();
}

class _PriceBreakdownCardState extends State<PriceBreakdownCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pricing;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total + range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Price',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p.formattedTotal,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandGreen,
                      ),
                    ),
                    if (p.estimatedMax > 0 && p.estimatedMax != p.total)
                      Text(
                        p.formattedRange,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),

            // Surge badge
            if (p.hasSurge) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 16, color: Colors.orange[800]),
                    const SizedBox(width: 4),
                    Text(
                      'Surge pricing: ${p.surgePricing.formattedMultiplier}',
                      style: TextStyle(
                          color: Colors.orange[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            // Discount badge
            if (p.hasDiscounts) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer, size: 16, color: Colors.green[800]),
                    const SizedBox(width: 4),
                    Text(
                      'Discount: ${p.discounts.formattedDiscount}',
                      style: TextStyle(
                          color: Colors.green[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            // Toggle details
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? 'Hide details' : 'Show details',
                    style: TextStyle(
                        color: AppTheme.brandGreen, fontWeight: FontWeight.w500),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.brandGreen,
                  ),
                ],
              ),
            ),

            // Expanded breakdown
            if (_expanded) ...[
              const Divider(height: 24),
              _row('Base price', p.basePrice),
              if (p.subTypeAdditionalFee > 0)
                _row('Sub-type fee', p.subTypeAdditionalFee),
              if (p.heroTravelFee > 0)
                _row(
                  'Travel (${p.heroTravelMiles.toStringAsFixed(1)} mi)',
                  p.heroTravelFee,
                ),
              if (p.towingDistanceFee > 0)
                _row(
                  'Towing (${p.towingDistanceMiles.toStringAsFixed(1)} mi)',
                  p.towingDistanceFee,
                ),
              if (p.surgePricing.surgeAmount > 0)
                _row('Surge pricing', p.surgePricing.surgeAmount,
                    color: Colors.orange[800]),
              if (p.addOns.priorityFee > 0) _row('Priority', p.addOns.priorityFee),
              if (p.addOns.winchFee > 0) _row('Winch', p.addOns.winchFee),
              if (p.addOns.fuelFee > 0) _row('Fuel', p.addOns.fuelFee),
              if (p.addOns.afterHoursFee > 0)
                _row('After hours', p.addOns.afterHoursFee),
              const Divider(height: 16),
              if (p.subtotalBeforeDiscounts > 0)
                _row('Subtotal', p.subtotalBeforeDiscounts),
              if (p.discounts.totalDiscount > 0)
                _row('Discount', -p.discounts.totalDiscount, color: Colors.green),
              _row(
                'Service fee (${p.serviceFeePercent.toStringAsFixed(0)}%)',
                p.serviceFee,
              ),
              if (p.taxAmount > 0) _row('Tax', p.taxAmount),
              const Divider(height: 16),
              _row('Total', p.total, bold: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int cents, {bool bold = false, Color? color}) {
    final negative = cents < 0;
    final display = negative
        ? '-\$${(-cents / 100).toStringAsFixed(2)}'
        : '\$${(cents / 100).toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
          Text(display,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: negative ? Colors.green : color)),
        ],
      ),
    );
  }
}
