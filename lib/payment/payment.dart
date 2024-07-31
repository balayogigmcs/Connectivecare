// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http; 
// import 'package:cccc/main.dart';// Import main.dart to access the scaffoldMessengerKey

// Future<Map<String, dynamic>> createPaymentIntent({
//   required String amount,
//   required String currency,
// }) async {
//   final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
//   final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
//   final body = {
//     'amount': amount,
//     'currency': currency,
//     'automatic_payment_methods[enabled]': 'true',
//     'description': "Test Payment",
//   };

//   final response = await http.post(
//     url,
//     headers: {
//       "Authorization": "Bearer $secretKey",
//       'Content-Type': 'application/x-www-form-urlencoded',
//     },
//     body: body,
//   );

//   if (response.statusCode == 200) {
//     return jsonDecode(response.body);
//   } else {
//     throw Exception('Failed to create payment intent');
//   }
// }

// Future<void> initPaymentSheet() async {
//   try {
//     // Replace with your API call to create a Payment Intent
//     final data = await createPaymentIntent(
//       amount: '1000', // Example amount in the smallest currency unit
//       currency: 'USD',
//     );

//     // Initialize the payment sheet
//     await Stripe.instance.initPaymentSheet(
//       paymentSheetParameters: SetupPaymentSheetParameters(
//         // Set to true for custom flow
//         customFlow: false,
//         // Main params
//         merchantDisplayName: 'Test Merchant',
//         paymentIntentClientSecret: data['client_secret'],
//         customerEphemeralKeySecret: data['ephemeralKey'],
//         customerId: data['id'],
//         style: ThemeMode.dark,
//       ),
//     );
//   } catch (e) {
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//     rethrow;
//   }
// }

// Future<void> presentPaymentSheet() async {
//   try {
//     await Stripe.instance.presentPaymentSheet();
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(
//         content: Text('Payment Successful'),
//         backgroundColor: Colors.green,
//       ),
//     );
//     displayRequestContainer();
//   } catch (e) {
//     scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(
//         content: Text('Payment Failed: $e'),
//         backgroundColor: Colors.redAccent,
//       ),
//     );
//   }
// }


// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;

// Future<Map<String, dynamic>> createPaymentIntent({
//   required String amount,
//   required String currency,
// }) async {
//   final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
//   final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
//   final body = {
//     'amount': amount,
//     'currency': currency,
//     'automatic_payment_methods[enabled]': 'true',
//     'description': "Test Payment",
//   };

//   final response = await http.post(
//     url,
//     headers: {
//       "Authorization": "Bearer $secretKey",
//       'Content-Type': 'application/x-www-form-urlencoded',
//     },
//     body: body,
//   );

//   if (response.statusCode == 200) {
//     return jsonDecode(response.body);
//   } else {
//     throw Exception('Failed to create payment intent');
//   }
// }

// import 'dart:convert';

// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import  'package:http/http.dart' as http;

// Future createPaymentIntent({required String name,
//   required String address,
//   required String pin,
//   required String city,
//   required String state,
//   required String country,
//   required String currency,
//   required String amount}) async{

//   final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
//   final secretKey=dotenv.env["STRIPE_SECRET_KEY"]!;
//   final body={
//     'amount': amount,
//     'currency': currency.toLowerCase(),
//     'automatic_payment_methods[enabled]': 'true',
//     'description': "Test Donation",
//     'shipping[name]': name,
//     'shipping[address][line1]': address,
//     'shipping[address][postal_code]': pin,
//     'shipping[address][city]': city,
//     'shipping[address][state]': state,
//     'shipping[address][country]': country
//   };

//   final response= await http.post(url,
//   headers: {
//     "Authorization": "Bearer $secretKey",
//     'Content-Type': 'application/x-www-form-urlencoded'
//   },
//     body: body
//   );

//   print(body);

//   if(response.statusCode==200){
//     var json=jsonDecode(response.body);
//     print(json);
//     return json;
//   }
//   else{
//     print("error in calling payment intent");
//   }
// }