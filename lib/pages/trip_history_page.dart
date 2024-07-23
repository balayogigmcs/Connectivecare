import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TripsHistoryPage extends StatefulWidget {
  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentUser =
      FirebaseDatabase.instance.ref().child("tripRequests");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Trips History",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
      ),
      body: StreamBuilder(
          stream: completedTripRequestsOfCurrentUser.onValue,
          builder: (BuildContext context, snapshotData) {
            if (snapshotData.hasError) {
              return Center(
                  child: Text(
                "Error Occured",
                style: TextStyle(color: Colors.white),
              ));
            }

            if (!(snapshotData.hasData)) {
              return Center(
                  child: Text(
                "No Record Found",
                style: TextStyle(color: Colors.white),
              ));
            }

            Map dataTrips = snapshotData.data!.snapshot.value as Map;
            List tripsList = [];
            dataTrips.forEach(
                (key, value) => tripsList.add({"key": key, ...value}));

            return ListView.builder(
                shrinkWrap: true,
                itemCount: tripsList.length,
                itemBuilder: ((context, index) {
                  if (tripsList[index]["status"] != null &&
                      tripsList[index]["status"] == "ended" &&
                      tripsList[index]["userID"] ==
                          FirebaseAuth.instance.currentUser!.uid) {
                    return Card(
                      elevation: 10,
                      color: Colors.white10,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // pickup Address and  fare Amount
                            Row(
                              children: [
                                Image.asset("assets/images/initial.png",
                                    height: 16, width: 16),
                                const SizedBox(
                                  width: 18,
                                ),
                                Expanded(
                                    child: Text(
                                  tripsList[index]["pickUpAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white38,fontSize: 18
                                  ),
                                ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "\$" + tripsList[index]["fareAmount"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,fontSize: 16
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                                  width: 8,
                                ),

                                // dropOff Address 
                            Row(
                              children: [
                                Image.asset("assets/images/initial.png",
                                    height: 16, width: 16),
                                const SizedBox(
                                  width: 18,
                                ),
                                Expanded(
                                    child: Text(
                                  tripsList[index]["dropOffAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white38,fontSize: 18
                                  ),
                                ),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                }));
          }),
    );
  }
}
