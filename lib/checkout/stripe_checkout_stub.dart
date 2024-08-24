import 'package:flutter/material.dart';

void redirectToCheckout(BuildContext context, double amount) {
    print('UnsupportedError: This platform is neither mobile nor web. Amount: $amount');
    throw UnsupportedError('It\'s neither mobile nor web');
}
