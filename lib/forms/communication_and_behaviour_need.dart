import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CommunicationAndBehavioralNeedsPage extends StatefulWidget {
  @override
  _CommunicationAndBehavioralNeedsPageState createState() =>
      _CommunicationAndBehavioralNeedsPageState();
}

class _CommunicationAndBehavioralNeedsPageState
    extends State<CommunicationAndBehavioralNeedsPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Communication and Behavioral Needs'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Communication Preferences'),
                _buildImageWithCheckbox(
                  'assets/images/hearing_impairment.png', // Replace with actual image asset
                  'hearingImpairments',
                  'Hearing impairments',
                ),
                _buildImageWithCheckbox(
                  'assets/images/vision_impairment.png', // Replace with actual image asset
                  'visionImpairments',
                  'Vision impairments',
                ),
                SizedBox(height: 20),
                _buildSectionTitle('Preferred Communication Methods'),
                _buildImageWithCheckbox(
                  'assets/images/written_notes.png', // Replace with actual image asset
                  'writtenNotes',
                  'Written notes',
                ),
                _buildImageWithCheckbox(
                  'assets/images/sign_language.png', // Replace with actual image asset
                  'signLanguage',
                  'Sign language',
                ),
                _buildImageWithCheckbox(
                  'assets/images/other_communication_methods.png', // Replace with actual image asset
                  'otherCommunicationMethods',
                  'Other methods of communication',
                ),
                SizedBox(height: 20),
                _buildSectionTitle('Behavioral Considerations'),
                _buildImageWithCheckbox(
                  'assets/images/dementia.png', // Replace with actual image asset
                  'dementia',
                  'Dementia',
                ),
                _buildImageWithCheckbox(
                  'assets/images/autism.png', // Replace with actual image asset
                  'autism',
                  'Autism',
                ),
                _buildImageWithCheckbox(
                  'assets/images/anxiety.png', // Replace with actual image asset
                  'anxiety',
                  'Anxiety',
                ),
                _buildImageWithCheckbox(
                  'assets/images/other_behavioral_conditions.png', // Replace with actual image asset
                  'otherBehavioralConditions',
                  'Other behavioral conditions',
                ),
                SizedBox(height: 20),
                _buildSectionTitle('Interaction Guidelines'),
                _buildTextField(
                  'interactionGuidelines',
                  'How to interact to ensure the patient feels safe and comfortable',
                ),
                _buildTextField(
                  'calmingTips',
                  'Tips for calming or reassuring the patient during the ride',
                ),
                SizedBox(height: 20),
                _buildSectionTitle('Language Preferences'),
                _buildTextField(
                  'preferredLanguage',
                  'Specify if the patient prefers communication in a language other than English',
                ),
                _buildTextField(
                  'specificLanguage',
                  'Indicate the specific language preference',
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      final formData = _formKey.currentState?.value;
                      // Handle form submission, e.g., save to Firebase
                      print('Form data: $formData');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildImageWithCheckbox(String imagePath, String fieldName, String title) {
    return Column(
      children: [
        Image.asset(imagePath),
        FormBuilderCheckbox(
          name: fieldName,
          title: Text(title),
        ),
      ],
    );
  }

  Widget _buildTextField(String fieldName, String labelText) {
    return FormBuilderTextField(
      name: fieldName,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      validator: FormBuilderValidators.required(),
    );
  }
}
