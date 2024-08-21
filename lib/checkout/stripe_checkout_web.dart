import 'url_helper_stubs.dart'
    if (dart.library.html) 'url_helper_web.dart'
    if (dart.library.io) 'url_helper_mobile.dart';

import 'package:js/js.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'server_stub.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

void listenForPaymentCompletion(BuildContext context, String sessionId, Function displayRequestContainer) {
  print("entered into ListenforPaymentCompletion in stripe_Checkout_web");
  print("Setting up listener for sessionId: $sessionId");
  try{
  FirebaseFirestore.instance
      .collection('payments')
      .doc(sessionId)
      .snapshots()
      .listen((DocumentSnapshot snapshot) {
    print("Listener triggered sessionId: $sessionId");
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>?;
      print("Snapshot data: $data");
      if (data != null && data['status'] == 'completed') {
        print("Displaying Request Container");
        displayRequestContainer();
      } else {
        print("Status not completed or data is null");
      }
    } else {
      print("Snapshot does not exist");
    }
  });
  }
  catch(e){
print("error in collecting data");
  }
}

Future<void> redirectToCheckout(BuildContext context, double amount, Function displayRequestContainer) async {
  try {
    print("entered into redirectToCheckout in stripe_Checkout_web");
    final server = Server();
    final successUrl = getCurrentUrl();
    final sessionId = await server.createCheckout(amount, successUrl);
    print("session id : ");
    print( sessionId);

    await Future.delayed(Duration(seconds: 10));

    // Listen for payment completion
    listenForPaymentCompletion(context, sessionId, displayRequestContainer);

    final stripe = Stripe(apiKey);
    stripe.redirectToCheckout(CheckoutOptions(
      sessionId: sessionId,
    ));
  } catch (e) {
    print("Error in redirectToCheckout: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create checkout session. Please try again.'),
      ),
    );
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
