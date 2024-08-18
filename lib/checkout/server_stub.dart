import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cccc/checkout/constants.dart';

/// Only for demo purposes!
/// Don't you dare do it in real apps!


class Server {
  Future<String> createCheckout(double amount,String successUrl) async {
    final auth = 'Basic ' + base64Encode(utf8.encode('$secretKey:'));

    // Convert the amount to cents as Stripe expects amounts in the smallest currency unit.
    final amountInCents = (amount * 100).toInt();

    final body = {
      'payment_method_types[]': 'card',  // Correctly formatted for form-urlencoded
      'line_items[0][price_data][currency]': 'usd',
      'line_items[0][price_data][product_data][name]': 'Ride Payment',
      'line_items[0][price_data][unit_amount]': amountInCents.toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      'success_url': successUrl,
      'cancel_url': 'http://localhost:56756/#/cancel',
    };

    try {
      final result = await Dio().post(
        "https://api.stripe.com/v1/checkout/sessions",
        data: body,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: auth},
          contentType: "application/x-www-form-urlencoded",
        ),
      );
      return result.data['id'];
    } on DioError catch (e) {
      print(e.response);
      throw e;
    }
  }
}
