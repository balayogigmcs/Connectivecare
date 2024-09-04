import 'package:cccc/pages/homepage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cccc/animation/splash_screen.dart';
import 'package:cccc/appinfo/appinfo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as flutter_stripe;
import 'dart:html' as html;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: "AIzaSyAtedTYdh2b484usx8sIa1JELhOY7vOIJM",
              authDomain: "cccc-4b8a5.firebaseapp.com",
              databaseURL: "https://cccc-4b8a5-default-rtdb.firebaseio.com",
              projectId: "cccc-4b8a5",
              storageBucket: "cccc-4b8a5.appspot.com",
              messagingSenderId: "185150577423",
              appId: "1:185150577423:web:ed5a745501913c6c357c7a",
              measurementId: "G-LG8DKVDRXN"));
      print('Firebase initialized for web.');

      // Stripe initialization for web
      flutter_stripe.Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
      print(flutter_stripe.Stripe.publishableKey);
      flutter_stripe.Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
      flutter_stripe.Stripe.urlScheme = 'flutterstripe';
      await flutter_stripe.Stripe.instance.applySettings();

      // Request notification and location permissions for web
      await requestNotificationPermissionWeb();
      await requestLocationPermissionWeb();
    } else {
      await Firebase.initializeApp();
      print('Firebase initialized for mobile.');

      // Stripe initialization for mobile
      flutter_stripe.Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
      print(flutter_stripe.Stripe.publishableKey);
      flutter_stripe.Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
      flutter_stripe.Stripe.urlScheme = 'flutterstripe';
      await flutter_stripe.Stripe.instance.applySettings();

      // Request location permission for mobile
      if (await Permission.locationWhenInUse.isDenied) {
        await Permission.locationWhenInUse.request();
      }
    }
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? initialScreen;

  @override
  void initState() {
    super.initState();

    // Check for pending payment in initState
    final String? sessionId = html.window.localStorage['sessionId'];
    print("sessionId : $sessionId");
    final String? paymentStatus = html.window.localStorage['paymentStatus'];
    print("paymentStatus : $paymentStatus");
    final String? previousScreen = html.window.localStorage['previousScreen'];
    print("previousScreen : $previousScreen");

    if (sessionId != null && paymentStatus == 'pending' && previousScreen == 'home') {
      // If there is a pending payment, skip the splash screen and go directly to HomePage
      print("entered ");
      initialScreen = Homepage(
        // onPaymentComplete: () async {
        //   await listenForPaymentCompletion(sessionId);
        //   print("onPaymentComplete");

        //   html.window.localStorage.remove('sessionId');
        //   html.window.localStorage.remove('paymentStatus');
        //   html.window.localStorage.remove('previousScreen');

        // },
      );
    } else {
      // Otherwise, show the SplashScreen
      initialScreen = SplashScreen();
    }

    // Update the state to reflect the chosen initial screen
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Appinfo(),
      child: Consumer<Appinfo>(
        builder: (_, appInfo, child) {
          return MaterialApp(
            title: 'Users App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.white,
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                headlineMedium: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black),
                bodyMedium: TextStyle(fontSize: 14.0, color: Colors.blue),
                labelLarge: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
                bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
                labelLarge: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            themeMode: appInfo.themeMode,
            home: initialScreen ?? CircularProgressIndicator(), // Show a loading indicator if the initialScreen is not yet determined
          );
        },
      ),
    );
  }
}


Future<void> requestNotificationPermissionWeb() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

// Function to request location permission on the web using the Geolocator package
Future<void> requestLocationPermissionWeb() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission denied');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permissions are permanently denied');
    return;
  }

  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    print('Location permission granted');
  }
}



// mobile {
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flutter/material.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:provider/provider.dart';
// // import 'package:cccc/mobile/appInfo/app_info.dart';
// // import 'package:cccc/mobile/authentication/login_screen.dart';
// // import 'package:cccc/mobile/authentication/signup_screen.dart';
// // import 'package:cccc/mobile/pages/home_page.dart';

// // Future<void> main() async
// // {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp();

// //   await Permission.locationWhenInUse.isDenied.then((valueOfPermission)
// //   {
// //     if(valueOfPermission)
// //     {
// //       Permission.locationWhenInUse.request();
// //     }
// //   });

// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget
// // {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context)
// //   {
// //     return ChangeNotifierProvider(
// //       create: (context) => AppInfo(),
// //       child: MaterialApp(
// //         title: 'Flutter User App',
// //         debugShowCheckedModeBanner: false,
// //         theme: ThemeData.dark().copyWith(
// //           scaffoldBackgroundColor: Colors.black,
// //         ),
// //         home: FirebaseAuth.instance.currentUser == null ? LoginScreen() : HomePage(),
// //       ),
// //     );
// //   }
// // }
// }



// class SuccessPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text(
//           'Success',
//           style: Theme.of(context).textTheme.headlineLarge,
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_form_builder/flutter_form_builder.dart';
// // import 'package:form_builder_validators/form_builder_validators.dart';

// // class MobilityAidsPage extends StatefulWidget {
// //   @override
// //   _MobilityAidsPageState createState() => _MobilityAidsPageState();
// // }

// // class _MobilityAidsPageState extends State<MobilityAidsPage> {
// //   final _formKey = GlobalKey<FormBuilderState>();
// //   String selectedMobilityAid = 'Wheelchair';

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Mobility Aids'),
// //         backgroundColor: Colors.blueAccent,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: FormBuilder(
// //           key: _formKey,
// //           child: SingleChildScrollView(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 _buildSectionTitle('Type of Mobility Aid:'),
// //                 _buildHorizontalScroll(
// //                   'mobilityAidType',
// //                   ['Wheelchair', 'Walker', 'Cane', 'Other mobility aids'],
// //                 ),
// //                 SizedBox(height: 20),
// //                 _buildSectionTitle('Assistance with Mobility Aids:'),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/assistance_with_folding.png', // Replace with actual image asset
// //                   'foldingAssistance',
// //                   'Need for assistance with folding mobility aids',
// //                 ),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/assistance_with_storing.png', // Replace with actual image asset
// //                   'storingAssistance',
// //                   'Need for assistance with storing mobility aids',
// //                 ),
// //                 SizedBox(height: 20),
// //                 _buildSectionTitle('Vehicle Accessibility:'),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/wheelchair_accessibility.png', // Replace with actual image asset
// //                   'wheelchairAccessibility',
// //                   'Requirement for wheelchair accessibility',
// //                 ),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/ramp.png', // Replace with actual image asset
// //                   'equippedWithRamp',
// //                   'Equipped with a ramp',
// //                 ),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/lift.png', // Replace with actual image asset
// //                   'equippedWithLift',
// //                   'Equipped with a lift',
// //                 ),
// //                 SizedBox(height: 20),
// //                 _buildSectionTitle('Assistance with Transfers:'),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/help_with_vehicle_transfers.png', // Replace with actual image asset
// //                   'vehicleTransferHelp',
// //                   'Requirement for help getting in and out of the vehicle',
// //                 ),
// //                 SizedBox(height: 20),
// //                 _buildSectionTitle('Safety Instructions:'),
// //                 _buildImageWithText(
// //                   'assets/images/safety_instructions.png', // Replace with actual image asset
// //                   'Instructions on how to safely assist the patient without causing injury',
// //                 ),
// //                 SizedBox(height: 20),
// //                 _buildSectionTitle('Walking Assistance:'),
// //                 _buildImageWithCheckbox(
// //                   'assets/images/help_with_walking.png', // Replace with actual image asset
// //                   'walkingAssistance',
// //                   'Requirement for assistance walking to and from the vehicle',
// //                 ),
// //                 _buildImageWithText(
// //                   'assets/images/guidance_and_support.png', // Replace with actual image asset
// //                   'Specifics on how to guide the patient and how to support the patient',
// //                 ),
// //                 SizedBox(height: 20),
// //                 ElevatedButton(
// //                   onPressed: () {
// //                     if (_formKey.currentState?.saveAndValidate() ?? false) {
// //                       final formData = _formKey.currentState?.value;
// //                       // Handle form submission, e.g., save to Firebase
// //                       print('Form data: $formData');
// //                     }
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.blueAccent,
// //                     padding: EdgeInsets.symmetric(vertical: 15),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(10.0),
// //                     ),
// //                   ),
// //                   child: Text(
// //                     'Submit',
// //                     style: TextStyle(fontSize: 18),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSectionTitle(String title) {
// //     return Text(
// //       title,
// //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //     );
// //   }

// //   Widget _buildHorizontalScroll(String fieldName, List<String> items) {
// //     return FormBuilderField(
// //       name: fieldName,
// //       validator: FormBuilderValidators.required(),
// //       builder: (FormFieldState<dynamic> field) {
// //         return Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Container(
// //               height: 120,
// //               child: ListView.builder(
// //                 scrollDirection: Axis.horizontal,
// //                 itemCount: items.length,
// //                 itemBuilder: (context, index) {
// //                   return GestureDetector(
// //                     onTap: () {
// //                       setState(() {
// //                         selectedMobilityAid = items[index];
// //                         field.didChange(selectedMobilityAid);
// //                       });
// //                     },
// //                     child: Container(
// //                       width: 100,
// //                       margin: EdgeInsets.symmetric(horizontal: 10),
// //                       decoration: BoxDecoration(
// //                         color: selectedMobilityAid == items[index]
// //                             ? Colors.blueAccent
// //                             : Colors.white,
// //                         borderRadius: BorderRadius.circular(10),
// //                         border: Border.all(color: Colors.grey),
// //                       ),
// //                       child: Center(
// //                         child: Text(
// //                           items[index],
// //                           textAlign: TextAlign.center,
// //                           style: TextStyle(
// //                             color: selectedMobilityAid == items[index]
// //                                 ? Colors.white
// //                                 : Colors.black,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //             if (field.hasError)
// //               Padding(
// //                 padding: const EdgeInsets.only(top: 5.0),
// //                 child: Text(
// //                   field.errorText!,
// //                   style: TextStyle(color: Colors.red),
// //                 ),
// //               ),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildImageWithCheckbox(
// //       String imagePath, String fieldName, String title) {
// //     return Column(
// //       children: [
// //         Image.asset(imagePath),
// //         FormBuilderCheckbox(
// //           name: fieldName,
// //           title: Text(title),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildImageWithText(String imagePath, String text) {
// //     return Column(
// //       children: [
// //         Image.asset(imagePath),
// //         SizedBox(height: 10),
// //         Text(
// //           text,
// //           style: TextStyle(fontSize: 16),
// //         ),
// //       ],
// //     );
// //   }
// // }
