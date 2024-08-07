// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

// class MedicalConsiderationsPage extends StatefulWidget {
//   @override
//   _MedicalConsiderationsPageState createState() => _MedicalConsiderationsPageState();
// }

// class _MedicalConsiderationsPageState extends State<MedicalConsiderationsPage> {
//   final _formKey = GlobalKey<FormBuilderState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Medical Considerations'),
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
//                 _buildSectionTitle('Medical Equipment'),
//                 _buildImageWithCheckbox('assets/images/oxygen_tank.png', 'oxygenTanks', 'Oxygen tanks'),
//                 _buildImageWithCheckbox('assets/images/portable_iv.png', 'portableIVs', 'Portable IVs'),
//                 _buildImageWithCheckbox('assets/images/other_medical_equipment.png', 'otherMedicalEquipment', 'Other medical equipment'),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Handling and Securing Equipment'),
//                 _buildTextField('handlingInstructions', 'Instructions on handling the equipment'),
//                 _buildTextField('securingInstructions', 'Instructions on securing the equipment in the vehicle'),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Health Conditions'),
//                 _buildImageWithCheckbox('assets/images/motion_sickness.png', 'motionSickness', 'Motion sickness'),
//                 _buildImageWithCheckbox('assets/images/epilepsy.png', 'epilepsy', 'Epilepsy (seizures)'),
//                 _buildImageWithCheckbox('assets/images/diabetes.png', 'diabetes', 'Diabetes (hypoglycemia)'),
//                 _buildImageWithCheckbox('assets/images/other_health_conditions.png', 'otherHealthConditions', 'Other health conditions'),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Allergies'),
//                 _buildTextField('allergies', 'Information about allergies'),
//                 _buildTextField('potentialTriggers', 'Potential triggers in the vehicle (e.g., air fresheners)'),
//                 SizedBox(height: 20),
//                 _buildSectionTitle('Medication'),
//                 _buildTextField('medicationInstructions', 'Instructions for taking medication during the trip'),
//                 _buildTextField('medicationStorage', 'Location of stored medication'),
//                 _buildTextField('administeringMedication', 'Instructions on administering medication if necessary'),
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
//                     primary: Colors.blueAccent,
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

//   Widget _buildImageWithCheckbox(String imagePath, String fieldName, String title) {
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

//   Widget _buildTextField(String fieldName, String labelText) {
//     return FormBuilderTextField(
//       name: fieldName,
//       decoration: InputDecoration(
//         labelText: labelText,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//       ),
//       validator: FormBuilderValidators.required(),
//     );
//   }
// }
