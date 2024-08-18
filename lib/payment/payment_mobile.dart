import 'package:cccc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> createPaymentIntent({
  required String amount,
  required String currency,
}) async {
  final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
  final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
  final body = {
    'amount': amount,
    'currency': currency,
    'automatic_payment_methods[enabled]': 'true',
    'description': "Test Payment",
  };

  final response = await http.post(
    url,
    headers: {
      "Authorization": "Bearer $secretKey",
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final errorResponse = jsonDecode(response.body);
    print('Failed to create payment intent: $errorResponse');
    throw Exception(
        'Failed to create payment intent: ${errorResponse['error']['message']}');
  }
}

Future<void> initPaymentSheet(String amount) async {
  try {
    final data = await createPaymentIntent(
      amount: amount,
      currency: 'USD',
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        customFlow: false,
        merchantDisplayName: 'Test Merchant',
        paymentIntentClientSecret: data['client_secret'],
        customerEphemeralKeySecret: data['ephemeralKey'],
        customerId: data['id'],
        style: ThemeMode.dark,
      ),
    );
  } catch (e) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    rethrow;
  }
}

