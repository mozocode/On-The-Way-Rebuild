import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/pricing_provider.dart';

class PromoCodeInput extends ConsumerStatefulWidget {
  final VoidCallback? onApplied;

  const PromoCodeInput({super.key, this.onApplied});

  @override
  ConsumerState<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends ConsumerState<PromoCodeInput> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(pricingProvider);

    if (pState.promoCodeValid && pState.appliedPromoCode != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Promo applied',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500)),
                  Text(pState.appliedPromoCode!,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.green),
              onPressed: () =>
                  ref.read(pricingProvider.notifier).removePromoCode(),
            ),
          ],
        ),
      );
    }

    if (!_isExpanded) {
      return TextButton.icon(
        onPressed: () => setState(() => _isExpanded = true),
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('Add promo code'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: pState.isLoading
                    ? null
                    : () async {
                        final code = _controller.text.trim();
                        if (code.isEmpty) return;
                        final success = await ref
                            .read(pricingProvider.notifier)
                            .applyPromoCode(code);
                        if (success) widget.onApplied?.call();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                ),
                child: pState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Apply',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (pState.error != null) ...[
            const SizedBox(height: 8),
            Text(pState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isExpanded = false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
