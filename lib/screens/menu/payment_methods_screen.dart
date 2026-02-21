import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../config/theme.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('listPaymentMethods')
          .call({});
      final methods = (result.data['paymentMethods'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          _cards = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load payment methods';
        });
      }
    }
  }

  String _brandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'Amex';
      case 'discover':
        return 'Discover';
      default:
        return brand[0].toUpperCase() + brand.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'Payment Methods',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isLoading)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _loadCards,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_cards.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card_off_outlined,
                                  size: 64, color: Colors.grey[350]),
                              const SizedBox(height: 16),
                              Text(
                                'No cards saved',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a card to get started with payments',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._cards.map((card) {
                        final brand = _brandIcon(card['brand'] ?? 'card');
                        final last4 = card['last4'] ?? '····';
                        final expMonth = card['expMonth'] ?? 0;
                        final expYear = card['expYear'] ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.brandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.credit_card,
                                    color: AppTheme.brandGreen, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$brand •••• $last4',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Expires $expMonth/$expYear',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddCardScreen()),
                          );
                          if (result == true && mounted) {
                            _loadCards();
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Add New Card',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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
}
