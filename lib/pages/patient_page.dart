// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

// class PatientInfoForm extends StatefulWidget {
//   @override
//   _PatientInfoFormState createState() => _PatientInfoFormState();
// }

// class _PatientInfoFormState extends State<PatientInfoForm> {
//   final _formKey = GlobalKey<FormBuilderState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Patient Information'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: FormBuilder(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               FormBuilderTextField(
//                 name: 'fullName',
//                 decoration: InputDecoration(labelText: 'Full Name'),
//                 validator: FormBuilderValidators.required(context),
//               ),
//               FormBuilderDateTimePicker(
//                 name: 'dob',
//                 inputType: InputType.date,
//                 decoration: InputDecoration(labelText: 'Date of Birth'),
//                 validator: FormBuilderValidators.required(context),
//               ),
//               FormBuilderDropdown(
//                 name: 'gender',
//                 decoration: InputDecoration(labelText: 'Gender'),
//                 items: ['Male', 'Female', 'Other']
//                     .map((gender) => DropdownMenuItem(
//                           value: gender,
//                           child: Text(gender),
//                         ))
//                     .toList(),
//                 validator: FormBuilderValidators.required(context),
//               ),
//               FormBuilderTextField(
//                 name: 'phoneNumber',
//                 decoration: InputDecoration(labelText: 'Phone Number'),
//                 keyboardType: TextInputType.phone,
//                 validator: FormBuilderValidators.compose([
//                   FormBuilderValidators.required(context),
//                   FormBuilderValidators.numeric(context),
//                 ]),
//               ),
//               FormBuilderTextField(
//                 name: 'email',
//                 decoration: InputDecoration(labelText: 'Email Address'),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: FormBuilderValidators.email(context),
//               ),
//               FormBuilderTextField(
//                 name: 'medicalConditions',
//                 decoration: InputDecoration(labelText: 'Medical Conditions'),
//                 maxLines: 3,
//               ),
//               FormBuilderTextField(
//                 name: 'medications',
//                 decoration: InputDecoration(labelText: 'Medications'),
//                 maxLines: 3,
//               ),
//               FormBuilderTextField(
//                 name: 'pickupAddress',
//                 decoration: InputDecoration(labelText: 'Pickup Address'),
//                 validator: FormBuilderValidators.required(context),
//               ),
//               FormBuilderTextField(
//                 name: 'destinationAddress',
//                 decoration: InputDecoration(labelText: 'Destination Address'),
//                 validator: FormBuilderValidators.required(context),
//               ),
//               FormBuilderTextField(
//                 name: 'insuranceProvider',
//                 decoration: InputDecoration(labelText: 'Insurance Provider'),
//               ),
//               FormBuilderTextField(
//                 name: 'policyNumber',
//                 decoration: InputDecoration(labelText: 'Policy Number'),
//               ),
//               FormBuilderSwitch(
//                 name: 'specialRequirements',
//                 title: Text('Special Requirements'),
//                 // Additional options can be configured here
//               ),
//               FormBuilderCheckbox(
//                 name: 'consent',
//                 title: Text('I consent to transport and data sharing'),
//                 validator: FormBuilderValidators.equal(context, true, errorText: 'Consent is required'),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState?.saveAndValidate() ?? false) {
//                     final user = FirebaseAuth.instance.currentUser;
//                     if (user != null) {
//                       final data = _formKey.currentState?.value;
//                       await FirebaseFirestore.instance
//                           .collection('patients')
//                           .doc(user.uid)
//                           .set(data!);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Patient information saved successfully')),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('User not logged in')),
//                       );
//                     }
//                   }
//                 },
//                 child: Text('Submit'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
