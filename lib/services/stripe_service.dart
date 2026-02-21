import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final _functions = FirebaseFunctions.instance;

  Future<String> createPaymentIntent(String jobId) async {
    final result = await _functions.httpsCallable('createPaymentIntent').call({'jobId': jobId});
    final clientSecret = result.data['clientSecret'] as String;
    return clientSecret;
  }

  Future<void> presentPaymentSheet(String clientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'On The Way',
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  Future<Map<String, dynamic>> getOrCreateCustomer({
    required String userId,
    required String email,
    String? name,
    String? phone,
  }) async {
    final result = await _functions.httpsCallable('getOrCreateCustomer').call({
      'userId': userId,
      'email': email,
      'name': name,
      'phone': phone,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
