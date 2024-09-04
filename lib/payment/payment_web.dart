import 'dart:convert';
import 'package:cccc/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;  // Import the dart:js library

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

Future<void> initPaymentSheetWeb(String amount) async {
  try {
    final data = await createPaymentIntent(
      amount: amount,
      currency: 'USD',
    );

    // Initialize Stripe
    final stripe = js.context.callMethod('Stripe', [dotenv.env["STRIPE_PUBLIC_KEY"]]);

    // Initialize Stripe Elements
    final elements = stripe.callMethod('elements');
    final card = elements.callMethod('create', ['card']);
    card.callMethod('mount', ['#card-element']);

    // Confirm card payment
    final paymentResult = await js.context.callMethod('confirmCardPayment', [
      data['client_secret'],
      js.JsObject.jsify({
        'payment_method': {
          'card': card,
          'billing_details': {
            'name': 'Customer Name',
          },
        },
      })
    ]);

    if (paymentResult['error'] != null) {
      throw Exception(paymentResult['error']['message']);
    }
  } catch (e) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    rethrow;
  }
}
