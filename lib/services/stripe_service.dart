import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Handles Stripe payment flow: create PaymentIntent via backend, present Payment Sheet.
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final _functions = FirebaseFunctions.instance;

  /// Creates a PaymentIntent on the backend and presents the Payment Sheet.
  /// [amountCents] total in cents. [customerId] optional for saved payment methods.
  /// Returns paymentIntentId on success, null on cancel/failure.
  Future<String?> payWithPaymentSheet({
    required int amountCents,
    String currency = 'usd',
    String? customerId,
    String merchantDisplayName = 'On The Way',
  }) async {
    final result = await _functions.httpsCallable('createPaymentIntent').call({
      'amount': amountCents,
      'currency': currency,
      if (customerId != null) 'customerId': customerId,
    });
    final data = result.data as Map<String, dynamic>?;
    if (data == null) return null;

    final clientSecret = data['clientSecret'] as String?;
    final paymentIntentId = data['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) return null;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return paymentIntentId;
  }
}
