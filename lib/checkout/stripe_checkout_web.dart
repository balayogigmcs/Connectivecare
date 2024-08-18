@JS()
library stripe;

import 'url_helper_stubs.dart'
    if (dart.library.html) 'url_helper_web.dart'
    if (dart.library.io) 'url_helper_mobile.dart';

import 'package:js/js.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'server_stub.dart'; // Ensure this import points to the correct file

void redirectToCheckout(BuildContext context, double amount) async {
  try {
    final server = Server();
    final successtUrl = getCurrentUrl();
    final sessionId = await server.createCheckout(amount, successtUrl);

    if (!context.mounted) return;

    final stripe = Stripe(apiKey);
    stripe.redirectToCheckout(CheckoutOptions(
      sessionId: sessionId, // Use sessionId here as a direct parameter
    ));
    Navigator.pushNamed(context, '/success');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to create checkout session. Please try again.')),
      );
    }
    print("Error creating checkout session: $e");
  }
}

@JS()
class Stripe {
  external Stripe(String key);

  external void redirectToCheckout(CheckoutOptions options);
}

@JS()
@anonymous
class CheckoutOptions {
  external String get sessionId;

  external factory CheckoutOptions({
    String sessionId,
  });
}
