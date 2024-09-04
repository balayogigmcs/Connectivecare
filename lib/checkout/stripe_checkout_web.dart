import 'dart:async';
import 'package:cccc/methods/manage_drivers_method.dart';
import 'package:cccc/models/online_nearby_drivers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'url_helper_stubs.dart'
    if (dart.library.html) 'url_helper_web.dart'
    if (dart.library.io) 'url_helper_mobile.dart';

import 'package:js/js.dart';
import 'constants.dart';
import 'server_stub.dart';
import 'dart:html' as html;

List<OnlineNearbyDrivers>? nearbyOnlineDriversList =
    ManageDriversMethod.nearbyOnlineDriversList;

Future<String?> redirectToCheckout(BuildContext context, double amount) async {
  try {
    print("Entered into redirectToCheckout in stripe_Checkout_web");

    if (nearbyOnlineDriversList == null || nearbyOnlineDriversList!.isEmpty) {
      print("No drivers available. Aborting checkout.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No drivers available. Please try again later.'),
        ),
      );
      return null;
    }

    // Create a checkout session
    final server = Server();
    final successUrl = getCurrentUrl();
    print(successUrl);
    final sessionId = await server.createCheckout(amount);
    print("session id : $sessionId");

    // Store sessionId and necessary state in localStorage
    html.window.localStorage['sessionId'] = sessionId;
    html.window.localStorage['paymentStatus'] = 'pending';
    html.window.localStorage['previousScreen'] = 'home';

    // Redirect to Stripe Checkout
    final stripe = Stripe(apiKey);
    print("Entering redirectToCheckout");
    stripe.redirectToCheckout(CheckoutOptions(sessionId: sessionId));

    // If payment was successful, continue with the rest of the process
    return sessionId;
  } catch (e) {
    print("Error in redirectToCheckout: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create checkout session. Please try again.'),
      ),
    );

    return null;
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
  external factory CheckoutOptions({String sessionId});
}


// Future<void> listenForPaymentCompletion(String? sessionId) async {
//   final completer = Completer<void>();
//   print("Entered into ListenforPaymentCompletion in stripe_Checkout_web");

//   try {
//     // Capture the subscription
//     StreamSubscription<DatabaseEvent>? subscription;

//     subscription = FirebaseDatabase.instance
//         .ref('payments/$sessionId')
//         .onValue
//         .listen((DatabaseEvent event) {
//       print("Listener triggered for sessionId: $sessionId");
//       final data = event.snapshot.value as Map<String, dynamic>?;
//       print("Snapshot data: $data");

//       if (data != null && data['status'] == 'completed') {
//         print("Payment completed. Completing the future.");
//         completer.complete();  // Complete the future when payment is completed
//         subscription?.cancel(); // Cancel the subscription after completion
//       } else {
//         print("Status not completed or data is null. Waiting...");
//       }
//     });

//     // Add a timeout for the payment confirmation
//     await completer.future.timeout(Duration(minutes: 10), onTimeout: () {
//       // Handle timeout
//       print("Payment confirmation timed out.");
//       subscription?.cancel(); // Cancel the subscription on timeout
//       completer.completeError("Payment confirmation timed out.");
//     });
//   } catch (e) {
//     print("Error in collecting data: $e");
//     completer.completeError(e);  // Complete the future with an error
//   }

//   return completer.future;
// }

//3. Wait for payment completion with a timeout
  //  print("before calling listenForPaymentCompletion");
  //   await listenForPaymentCompletion(sessionId).catchError((error) {
  //     print("Error or timeout: $error");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Payment process failed or timed out. Please try again.'),
  //       ),
  //     );
  //   });

  //  // Clear the state after completion
  //   html.window.localStorage.remove('sessionId');
  //   print("removing Sessionid");
  //   html.window.localStorage.remove('paymentStatus');
  //   print("removing paymentStatus");
  //   html.window.localStorage.remove('previousScreen');
  //   print("removing PreviousScreen");

// import 'url_helper_stubs.dart'
//     if (dart.library.html) 'url_helper_web.dart'
//     if (dart.library.io) 'url_helper_mobile.dart';

// import 'package:js/js.dart';
// import 'package:flutter/material.dart';
// import 'constants.dart';
// import 'server_stub.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';

// void listenForPaymentCompletion(BuildContext context, String sessionId,Function onComplete) {
//   print("entered into ListenforPaymentCompletion in stripe_Checkout_web");
//   print("Setting up listener for sessionId: $sessionId");
//   try{
//   FirebaseFirestore.instance
//       .collection('payments')
//       .doc(sessionId)
//       .snapshots()
//       .listen((DocumentSnapshot snapshot) {
//     print("Listener triggered sessionId: $sessionId");
//     if (snapshot.exists) {
//       var data = snapshot.data() as Map<String, dynamic>?;
//       print("Snapshot data: $data");
//       if (data != null && data['status'] == 'completed') {
//         onComplete();
//         print("Displaying Request Container");
//       } else {
//         print("Status not completed or data is null");
//       }
//     } else {
//       print("Snapshot does not exist");
//     }
//   });
//   }
//   catch(e){
// print("error in collecting data");
//   }
// }

// Future<void> redirectToCheckout(BuildContext context, double amount,  Function onComplete) async {
//   try {
//     print("entered into redirectToCheckout in stripe_Checkout_web");
//     final server = Server();
//     final successUrl = getCurrentUrl();
//     final sessionId = await server.createCheckout(amount, successUrl);
//     print("session id : ");
//     print( sessionId);

//     // await Future.delayed(Duration(seconds: ));

//     // Listen for payment completion
//     listenForPaymentCompletion(context, sessionId, onComplete);

//     final stripe = Stripe(apiKey);
//     stripe.redirectToCheckout(CheckoutOptions(
//       sessionId: sessionId,
//     ));
//   } catch (e) {
//     print("Error in redirectToCheckout: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to create checkout session. Please try again.'),
//       ),
//     );
//   }
// }

// @JS()
// class Stripe {
//   external Stripe(String key);

//   external void redirectToCheckout(CheckoutOptions options);
// }

// @JS()
// @anonymous
// class CheckoutOptions {
//   external String get sessionId;

//   external factory CheckoutOptions({
//     String sessionId,
//   });
// }

// @JS()
// library stripe;

// import 'url_helper_stubs.dart'
//     if (dart.library.html) 'url_helper_web.dart'
//     if (dart.library.io) 'url_helper_mobile.dart';

// import 'package:js/js.dart';
// import 'package:flutter/material.dart';
// import 'constants.dart';
// import 'server_stub.dart'; // Ensure this import points to the correct file

// void redirectToCheckout(BuildContext context, double amount) async {
//   try {
//     final server = Server();
//     final successtUrl = getCurrentUrl();
//     final sessionId = await server.createCheckout(amount, successtUrl);

//     if (!context.mounted) {
//       print("context is not mounted");
//       return;
//     }

//     final stripe = Stripe(apiKey);
//     stripe.redirectToCheckout(CheckoutOptions(
//       sessionId: sessionId, // Use sessionId here as a direct parameter
//     ));
//     Navigator.pushNamed(context, '/success');
//   } catch (e) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text('Failed to create checkout session. Please try again.')),
//       );
//     }
//     print("Error creating checkout session: $e");
//   }
// }

// @JS()
// class Stripe {
//   external Stripe(String key);

//   external void redirectToCheckout(CheckoutOptions options);
// }

// @JS()
// @anonymous
// class CheckoutOptions {
//   external String get sessionId;

//   external factory CheckoutOptions({
//     String sessionId,
//   });
// }

// import 'package:http/http.dart' as http;

// Stream<String> callFirebaseFunction() async* {
//   print("In callFirebaseFunction");
//   final url = Uri.parse(
//       'https://us-central1-cccc-4b8a5.cloudfunctions.net/newStripeWebhook/webhook');

//   print(url);
//   try {
//     final response = await http.post(
//       url,
//       body: json.encode({
//         'amount': 5000, // Amount in cents
//         'currency': 'usd',
//         'userId': 'unique_user_id', // Replace with actual user ID
//       }),
//       headers: {
//         'Content-Type': 'application/json',
//         'Stripe-Signature': 'your-stripe-signature',
//       },
//     );

//     if (response.statusCode == 200) {
//       print("response");
//       final body = jsonDecode(response.body);
//       if (body['received'] == true) {
//         yield 'responseReceived';
//       } else {
//         yield 'responseNotAcknowledged';
//       }
//     } else {
//       print('Failed with status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//       yield 'failedToCallFunction';
//     }
//   } catch (e) {
//     print('Error occurred: $e');
//     yield 'errorOccurred';
//   }
// }
