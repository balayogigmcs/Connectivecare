import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cccc/animation/splash_screen.dart';
import 'package:cccc/appinfo/appinfo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  // Request location permission if not already granted
  if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            home: SplashScreen(), // Set SplashScreen as the initial route
          );
        },
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

// class MobilityAidsPage extends StatefulWidget {
//   @override
//   _MobilityAidsPageState createState() => _MobilityAidsPageState();
// }

// class _MobilityAidsPageState extends State<MobilityAidsPage> {
//   final _formKey = GlobalKey<FormBuilderState>();
//   String selectedMobilityAid = 'Wheelchair';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mobility Aids'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: FormBuilder(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildSectionTitle('Type of Mobility Aid:'),
//                 _buildHorizontalScroll(
//                   'mobilityAidType',
//                   ['Wheelchair', 'Walker', 'Cane', 'Other mobility aids'],
//                 ),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Assistance with Mobility Aids:'),
//                 _buildImageWithCheckbox(
//                   'assets/images/assistance_with_folding.png', // Replace with actual image asset
//                   'foldingAssistance',
//                   'Need for assistance with folding mobility aids',
//                 ),
//                 _buildImageWithCheckbox(
//                   'assets/images/assistance_with_storing.png', // Replace with actual image asset
//                   'storingAssistance',
//                   'Need for assistance with storing mobility aids',
//                 ),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Vehicle Accessibility:'),
//                 _buildImageWithCheckbox(
//                   'assets/images/wheelchair_accessibility.png', // Replace with actual image asset
//                   'wheelchairAccessibility',
//                   'Requirement for wheelchair accessibility',
//                 ),
//                 _buildImageWithCheckbox(
//                   'assets/images/ramp.png', // Replace with actual image asset
//                   'equippedWithRamp',
//                   'Equipped with a ramp',
//                 ),
//                 _buildImageWithCheckbox(
//                   'assets/images/lift.png', // Replace with actual image asset
//                   'equippedWithLift',
//                   'Equipped with a lift',
//                 ),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Assistance with Transfers:'),
//                 _buildImageWithCheckbox(
//                   'assets/images/help_with_vehicle_transfers.png', // Replace with actual image asset
//                   'vehicleTransferHelp',
//                   'Requirement for help getting in and out of the vehicle',
//                 ),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Safety Instructions:'),
//                 _buildImageWithText(
//                   'assets/images/safety_instructions.png', // Replace with actual image asset
//                   'Instructions on how to safely assist the patient without causing injury',
//                 ),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Walking Assistance:'),
//                 _buildImageWithCheckbox(
//                   'assets/images/help_with_walking.png', // Replace with actual image asset
//                   'walkingAssistance',
//                   'Requirement for assistance walking to and from the vehicle',
//                 ),
//                 _buildImageWithText(
//                   'assets/images/guidance_and_support.png', // Replace with actual image asset
//                   'Specifics on how to guide the patient and how to support the patient',
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState?.saveAndValidate() ?? false) {
//                       final formData = _formKey.currentState?.value;
//                       // Handle form submission, e.g., save to Firebase
//                       print('Form data: $formData');
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     padding: EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                   ),
//                   child: Text(
//                     'Submit',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//     );
//   }

//   Widget _buildHorizontalScroll(String fieldName, List<String> items) {
//     return FormBuilderField(
//       name: fieldName,
//       validator: FormBuilderValidators.required(),
//       builder: (FormFieldState<dynamic> field) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 120,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         selectedMobilityAid = items[index];
//                         field.didChange(selectedMobilityAid);
//                       });
//                     },
//                     child: Container(
//                       width: 100,
//                       margin: EdgeInsets.symmetric(horizontal: 10),
//                       decoration: BoxDecoration(
//                         color: selectedMobilityAid == items[index]
//                             ? Colors.blueAccent
//                             : Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.grey),
//                       ),
//                       child: Center(
//                         child: Text(
//                           items[index],
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: selectedMobilityAid == items[index]
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             if (field.hasError)
//               Padding(
//                 padding: const EdgeInsets.only(top: 5.0),
//                 child: Text(
//                   field.errorText!,
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildImageWithCheckbox(
//       String imagePath, String fieldName, String title) {
//     return Column(
//       children: [
//         Image.asset(imagePath),
//         FormBuilderCheckbox(
//           name: fieldName,
//           title: Text(title),
//         ),
//       ],
//     );
//   }

//   Widget _buildImageWithText(String imagePath, String text) {
//     return Column(
//       children: [
//         Image.asset(imagePath),
//         SizedBox(height: 10),
//         Text(
//           text,
//           style: TextStyle(fontSize: 16),
//         ),
//       ],
//     );
//   }
// }
