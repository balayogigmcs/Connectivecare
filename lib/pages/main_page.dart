import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pickup Location Text Field
            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter pickup location',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                ),
              ),
            ),

            // Gesture Card Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Handle Ride button tap
                    print('Ride button tapped');
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.all(16), // Remove top and bottom padding
                      width: 150,
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.lightBlueAccent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons
                                .ambulance, // Use the ambulance icon
                            size: 50.0,
                            color: Colors.red,
                          ),
                          // Image.asset(
                          //   "assets/images/uberexec.png",
                          //   width: 50,
                          //   height: 50,
                          //   fit: BoxFit.contain,
                          // ),
                          const SizedBox(
                              height:
                                  4), // Minimal space between image and text
                          Text(
                            'Ride',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Handle Reserve button tap
                    print('Reserve button tapped');
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      width: 150,
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.green,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons
                                .schedule_outlined, // Replace with your desired icon
                            size: 50, // Adjust size as needed
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reserve',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
