// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';
// import 'package:firebase_database/firebase_database.dart';

// class MobilityAidsPage extends StatefulWidget {
//   final VoidCallback onFormSubmitted;

//   MobilityAidsPage({required this.onFormSubmitted});

//   @override
//   _MobilityAidsPageState createState() => _MobilityAidsPageState();
// }

// class _MobilityAidsPageState extends State<MobilityAidsPage> {
//   final _formKey = GlobalKey<FormBuilderState>();
//   String selectedMobilityAid = 'Wheelchair';
//   final DatabaseReference _database = FirebaseDatabase.instance.ref();
//   List<Map<dynamic, dynamic>> _dataList = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   void _fetchData() {
//   _database.child('mobilityAids').once().then((snap) {
//     List<Map<dynamic, dynamic>> dataList = [];
//     final values = snap.snapshot.value as Map<dynamic, dynamic>?;
//     if (values != null) {
//       values.forEach((key, value) {
//         dataList.add(value as Map<dynamic, dynamic>);
//       });
//     }
//     setState(() {
//       _dataList = dataList;
//     });
//   });
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mobility Aids'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               FormBuilder(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSectionTitle('Type of Mobility Aid:'),
//                     _buildHorizontalScroll(
//                       'mobilityAidType',
//                       ['Wheelchair', 'Walker', 'Cane', 'Other mobility aids'],
//                     ),
//                     SizedBox(height: 20),
//                     _buildSectionTitle('Assistance with Mobility Aids:'),
//                     _buildCheckbox(
//                       'foldingAssistance',
//                       'Need for assistance with folding mobility aids',
//                     ),
//                     _buildCheckbox(
//                       'storingAssistance',
//                       'Need for assistance with storing mobility aids',
//                     ),
//                     SizedBox(height: 20),
//                     _buildSectionTitle('Vehicle Accessibility:'),
//                     _buildCheckbox(
//                       'wheelchairAccessibility',
//                       'Requirement for wheelchair accessibility',
//                     ),
//                     _buildCheckbox(
//                       'equippedWithRamp',
//                       'Equipped with a ramp',
//                     ),
//                     _buildCheckbox(
//                       'equippedWithLift',
//                       'Equipped with a lift',
//                     ),
//                     SizedBox(height: 20),
//                     _buildSectionTitle('Assistance with Transfers:'),
//                     _buildCheckbox(
//                       'vehicleTransferHelp',
//                       'Requirement for help getting in and out of the vehicle',
//                     ),
//                     SizedBox(height: 20),
//                     _buildSectionTitle('Safety Instructions:'),
//                     _buildText(
//                       'Instructions on how to safely assist the patient without causing injury',
//                     ),
//                     SizedBox(height: 20),
//                     _buildSectionTitle('Walking Assistance:'),
//                     _buildCheckbox(
//                       'walkingAssistance',
//                       'Requirement for assistance walking to and from the vehicle',
//                     ),
//                     _buildText(
//                       'Specifics on how to guide the patient and how to support the patient',
//                     ),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         if (_formKey.currentState?.saveAndValidate() ?? false) {
//                           final formData = _formKey.currentState?.value;
//                           _saveFormData(formData);
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         padding: EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                       ),
//                       child: Text(
//                         'Submit',
//                         style: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//               _buildSectionTitle('Submitted Data:'), // Section title for the submitted data
//               _buildDataList(), // Data displaying method
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _saveFormData(Map<String, dynamic>? formData) {
//     _database.child('mobilityAids').push().set(formData).then((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Form submitted successfully!')),
//       );
//       widget.onFormSubmitted(); // Call the callback function
//       Navigator.pop(context); // Navigate back to the previous screen
//     }).catchError((error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to submit form: $error')),
//       );
//     });
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
//             SizedBox(
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

//   Widget _buildCheckbox(String fieldName, String title) {
//     return FormBuilderCheckbox(
//       name: fieldName,
//       title: Text(title),
//     );
//   }

//   Widget _buildText(String text) {
//     return Text(
//       text,
//       style: TextStyle(fontSize: 16),
//     );
//   }

//   Widget _buildDataList() {
//     if (_dataList.isEmpty) {
//       return Text('No data submitted yet.');
//     }
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: _dataList.length,
//       itemBuilder: (context, index) {
//         final data = _dataList[index];
//         return Card(
//           margin: EdgeInsets.symmetric(vertical: 10),
//           child: ListTile(
//             title: Text('Mobility Aid Type: ${data['mobilityAidType']}'),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Folding Assistance: ${data['foldingAssistance'] ?? false}'),
//                 Text('Storing Assistance: ${data['storingAssistance'] ?? false}'),
//                 Text('Wheelchair Accessibility: ${data['wheelchairAccessibility'] ?? false}'),
//                 Text('Equipped with Ramp: ${data['equippedWithRamp'] ?? false}'),
//                 Text('Equipped with Lift: ${data['equippedWithLift'] ?? false}'),
//                 Text('Vehicle Transfer Help: ${data['vehicleTransferHelp'] ?? false}'),
//                 Text('Walking Assistance: ${data['walkingAssistance'] ?? false}'),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
