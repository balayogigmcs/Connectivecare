import 'package:cccc/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class PersonalDetails extends StatefulWidget {
  PersonalDetails({super.key});

  
  @override
  _PersonalDetailsState createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Information'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'firstName',
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'lastName',
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: 20),
                FormBuilderDateTimePicker(
                  name: 'dob',
                  inputType: InputType.date,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: 20),
                FormBuilderDropdown(
                  name: 'gender',
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender,style: const TextStyle(color: Colors.black),),
                          ))
                      .toList(),
                  validator: FormBuilderValidators.required(),
                ),
                SizedBox(height: 20),
                FormBuilderCheckbox(
                  name: 'consent',
                  title: Text('I consent to transport and data sharing'),
                  validator: FormBuilderValidators.equal(
                    true,
                    errorText: 'Consent is required',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final formData = Map<String, dynamic>.from(
                            _formKey.currentState!.value);

                        // Convert DateTime to string
                        if (formData.containsKey('dob')) {
                          formData['dob'] =
                              (formData['dob'] as DateTime).toIso8601String();
                        }

                        await FirebaseDatabase.instance
                            .ref()
                            .child('personalinformation')
                            .child(user.uid)
                            .set(formData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Patient information saved successfully')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Homepage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not logged in')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
