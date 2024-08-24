import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cccc/checkout/constants.dart';

import 'url_helper_stubs.dart'
    if (dart.library.html) 'url_helper_web.dart'
    if (dart.library.io) 'url_helper_mobile.dart';

/// Only for demo purposes!
/// Don't you dare do it in real apps!

class Server {
  Future<String> createCheckout(double amount) async {
    print("entered into createCheckout in server stub");
    final auth = 'Basic ' + base64Encode(utf8.encode('$secretKey:'));

    // Convert the amount to cents as Stripe expects amounts in the smallest currency unit.
    final amountInCents = (amount * 100).toInt();
    print("amount in server stub");
    print(amount);

    final currentUrl = getCurrentUrl();
    print(currentUrl);

    final successUrl = '$currentUrl';

    final body = {
      'payment_method_types[]':
          'card', // Correctly formatted for form-urlencoded
      'line_items[0][price_data][currency]': 'usd',
      'line_items[0][price_data][product_data][name]': 'Ride Payment',
      'line_items[0][price_data][unit_amount]': amountInCents.toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      'success_url': successUrl,
      'cancel_url': currentUrl,
    };

    try {
      print("entered into Dio");
      final result = await Dio().post(
        "https://api.stripe.com/v1/checkout/sessions",
        data: body,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: auth},
          contentType: "application/x-www-form-urlencoded",
        ),
      );
      print("after dio");
      print(result.data['id']);
      return result.data['id'];
    } on DioError catch (e) {
      print(e.response);
      throw e;
    }
  }
}
