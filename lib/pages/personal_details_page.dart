
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PersonalDetailsDisplayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getPersonalDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data available'));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                _buildDetailTile('First Name', data['firstName']),
                _buildDetailTile('Last Name', data['lastName']),
                _buildDetailTile('Date of Birth', data['dob']),
                _buildDetailTile('Gender', data['gender']),
                _buildDetailTile(
                    'Consent', data['consent'] != null && data['consent'] ? 'Yes' : 'No'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getPersonalDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.uid)
          .get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    }
    return null;
  }

  Widget _buildDetailTile(String title, dynamic value) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value != null ? value.toString() : 'Not available'),
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      leading: Icon(Icons.info),
    );
  }
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';

// class PersonalDetailsDisplayPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Personal Details'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: FutureBuilder(
//         future: _getPersonalDetails(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data == null) {
//             return Center(child: Text('No data available'));
//           }

//           final data = snapshot.data as Map<String, dynamic>;
//           return Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: ListView(
//               children: [
//                 _buildDetailTile('First Name', data['firstName']),
//                 _buildDetailTile('Last Name', data['lastName']),
//                 _buildDetailTile('Date of Birth', data['dob']),
//                 _buildDetailTile('Gender', data['gender']),
//                 _buildDetailTile('Consent', data['consent'] ? 'Yes' : 'No'),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future<Map<String, dynamic>?> _getPersonalDetails() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseDatabase.instance
//           .ref()
//           .child('users')
//           .child(user.uid)
//           .get();
//       if (snapshot.exists) {
//         return Map<String, dynamic>.from(snapshot.value as Map);
//       }
//     }
//     return null;
//   }

//   Widget _buildDetailTile(String title, String value) {
//     return ListTile(
//       contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       title: Text(
//         title,
//         style: TextStyle(fontWeight: FontWeight.bold),
//       ),
//       subtitle: Text(value),
//       tileColor: Colors.grey[200],
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       leading: Icon(Icons.info),
//     );
//   }
// }
