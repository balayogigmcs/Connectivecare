


// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:cccc/forms/mobility_aids.dart';
// import 'package:cccc/global/database_services.dart';
// import 'package:cccc/main.dart';
// import 'package:cccc/pages/main_page.dart';
// import 'package:cccc/pages/personal_details_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// // import 'package:restart_app/restart_app.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:cccc/authentication/login_screen.dart';
// import 'package:cccc/global/global_var.dart';
// import 'package:cccc/global/trip_var.dart';
// import 'package:cccc/methods/common_methods.dart';
// import 'package:cccc/methods/manage_drivers_method.dart';
// import 'package:cccc/methods/push_notification_service.dart';
// import 'package:cccc/models/direction_details.dart';
// import 'package:cccc/models/online_nearby_drivers.dart';
// import 'package:cccc/pages/about_page.dart';
// import 'package:cccc/pages/search_destination_page.dart';
// import 'package:cccc/pages/trip_history_page.dart';
// import 'package:cccc/widgets/info_dialog.dart';
// import 'package:http/http.dart' as http;
// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:cccc/widgets/loading_dialog.dart';

// class Homepage extends StatefulWidget {
//   const Homepage({super.key});

//   @override
//   State<Homepage> createState() => _HomepageState();
// }

// class _HomepageState extends State<Homepage> {
//   final Completer<GoogleMapController> googleMapCompleterController =
//       Completer<GoogleMapController>();
//   GoogleMapController? controllerGoogleMap;
//   Position? currentPositionOfUser;
//   GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
//   CommonMethods cMethods = CommonMethods();
//   double searchContainerHeight = 276;
//   double bottomMapPadding = 0;
//   double rideDetailsContainerHeight = 0;
//   double requestContainerHeight = 0;
//   double tripContainerHeight = 0;
//   // double paymentContainerHeight = 0;
//   DirectionDetails? tripDirectionDetailsInfo;
//   List<LatLng> polylineCoOrdinates = [];
//   Set<Polyline> polylineSet = {};
//   Set<Marker> markerSet = {};
//   Set<Circle> circleSet = {};
//   bool isDrawerOpened = true;
//   String stateOfApp = "normal";
//   bool nearbyOnlineDriversKeysLoaded = false;
//   BitmapDescriptor? carIconNearbyDriver;
//   DatabaseReference? tripRequestRef;
//   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
//   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
//   bool requestingDirectionDetailsInfo = false;
//   // bool hasDonated = false;

//   makeDriverNearbyCarIcon() {
//     if (carIconNearbyDriver == null) {
//       ImageConfiguration configuration =
//           createLocalImageConfiguration(context, size: Size(0.5, 0.5));
//       BitmapDescriptor.fromAssetImage(
//               configuration, "assets/images/tracking.png")
//           .then((iconImage) {
//         carIconNearbyDriver = iconImage;
//       });
//     }
//   }

//   void updateMapTheme(GoogleMapController controller) {
//     getJsonFileFromThemes("themes/light_style.json")
//         .then((value) => setGoogleMapStyle(value, controller));
//   }

//   Future<String> getJsonFileFromThemes(String mapStylePath) async {
//     ByteData byteData = await rootBundle.load(mapStylePath);
//     var list = byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
//     return utf8.decode(list);
//   }

//   setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
//     controller.setMapStyle(googleMapStyle);
//   }

//   getCurrentLiveLocationOfUser() async {
//     Position positionOfUser = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.bestForNavigation);
//     currentPositionOfUser = positionOfUser;

//     LatLng positionOfUserInLatLng = LatLng(
//         currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

//     CameraPosition cameraPosition =
//         CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//     controllerGoogleMap!
//         .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//     await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
//         currentPositionOfUser!, context);

//     await getUserInfoAndCheckBlockStatus();

//     await initializeGeoFireListener();
//   }

//   getUserInfoAndCheckBlockStatus() async {
//     DatabaseReference usersRef = FirebaseDatabase.instance
//         .ref()
//         .child("users")
//         .child(FirebaseAuth.instance.currentUser!.uid);

//     await usersRef.once().then((snap) {
//       if (snap.snapshot.value != null) {
//         if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
//           setState(() {
//             userName = (snap.snapshot.value as Map)["name"];
//             userPhone = (snap.snapshot.value as Map)["phone"];
//           });
//         } else {
//           FirebaseAuth.instance.signOut();

//           Navigator.push(
//               context, MaterialPageRoute(builder: (c) => LoginScreen()));

//           cMethods.displaySnackbar(
//               "you are blocked. Contact admin: alizeb875@gmail.com", context);
//         }
//       } else {
//         FirebaseAuth.instance.signOut();
//         Navigator.push(
//             context, MaterialPageRoute(builder: (c) => LoginScreen()));
//       }
//     });
//   }

//   displayUserRideDetailsContainer() async {
//     ///Directions API
//     await retrieveDirectionDetails();

//     setState(() {
//       searchContainerHeight = 0;
//       bottomMapPadding = 240;
//       rideDetailsContainerHeight = 180;
//       isDrawerOpened = false;
//     });
//   }

//   // displayPaymentDetailsContainer() async {
//   //   setState(() {
//   //     searchContainerHeight = 0;
//   //     bottomMapPadding = 240;
//   //     rideDetailsContainerHeight = 0;
//   //     isDrawerOpened = false;
//   //   });

//   //   await initPaymentSheet();
//   //   await presentPaymentSheet();

//   //   ///Directions API
//   // }

//   retrieveDirectionDetails() async {
//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     var pickupGeoGraphicCoOrdinates = LatLng(
//         pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
//     var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
//         dropOffDestinationLocation!.latitudePositon!,
//         dropOffDestinationLocation.longitudePosition!);

//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) =>
//           LoadingDialog(messageText: "Getting direction..."),
//     );

//     ///Directions API
//     var detailsFromDirectionAPI =
//         await CommonMethods.getDirectionDetailsFromAPI(
//             pickupGeoGraphicCoOrdinates,
//             dropOffDestinationGeoGraphicCoOrdinates);
//     setState(() {
//       tripDirectionDetailsInfo = detailsFromDirectionAPI;
//     });

//     Navigator.pop(context);

//     //draw route from pickup to dropOffDestination
//     PolylinePoints pointsPolyline = PolylinePoints();
//     List<PointLatLng> latLngPointsFromPickUpToDestination =
//         pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

//     polylineCoOrdinates.clear();
//     if (latLngPointsFromPickUpToDestination.isNotEmpty) {
//       latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
//         polylineCoOrdinates
//             .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
//       });
//     }

//     polylineSet.clear();
//     setState(() {
//       Polyline polyline = Polyline(
//         polylineId: const PolylineId("polylineID"),
//         color: Colors.pink,
//         points: polylineCoOrdinates,
//         jointType: JointType.round,
//         width: 4,
//         startCap: Cap.roundCap,
//         endCap: Cap.roundCap,
//         geodesic: true,
//       );

//       polylineSet.add(polyline);
//     });

//     //fit the polyline into the map
//     LatLngBounds boundsLatLng;
//     if (pickupGeoGraphicCoOrdinates.latitude >
//             dropOffDestinationGeoGraphicCoOrdinates.latitude &&
//         pickupGeoGraphicCoOrdinates.longitude >
//             dropOffDestinationGeoGraphicCoOrdinates.longitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: dropOffDestinationGeoGraphicCoOrdinates,
//         northeast: pickupGeoGraphicCoOrdinates,
//       );
//     } else if (pickupGeoGraphicCoOrdinates.longitude >
//         dropOffDestinationGeoGraphicCoOrdinates.longitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude,
//             dropOffDestinationGeoGraphicCoOrdinates.longitude),
//         northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
//             pickupGeoGraphicCoOrdinates.longitude),
//       );
//     } else if (pickupGeoGraphicCoOrdinates.latitude >
//         dropOffDestinationGeoGraphicCoOrdinates.latitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
//             pickupGeoGraphicCoOrdinates.longitude),
//         northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude,
//             dropOffDestinationGeoGraphicCoOrdinates.longitude),
//       );
//     } else {
//       boundsLatLng = LatLngBounds(
//         southwest: pickupGeoGraphicCoOrdinates,
//         northeast: dropOffDestinationGeoGraphicCoOrdinates,
//       );
//     }

//     controllerGoogleMap!
//         .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

//     //add markers to pickup and dropOffDestination points
//     Marker pickUpPointMarker = Marker(
//       markerId: const MarkerId("pickUpPointMarkerID"),
//       position: pickupGeoGraphicCoOrdinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       infoWindow: InfoWindow(
//           title: pickUpLocation.placeName, snippet: "Pickup Location"),
//     );

//     Marker dropOffDestinationPointMarker = Marker(
//       markerId: const MarkerId("dropOffDestinationPointMarkerID"),
//       position: dropOffDestinationGeoGraphicCoOrdinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//       infoWindow: InfoWindow(
//           title: dropOffDestinationLocation.placeName,
//           snippet: "Destination Location"),
//     );

//     setState(() {
//       markerSet.add(pickUpPointMarker);
//       markerSet.add(dropOffDestinationPointMarker);
//     });

//     //add circles to pickup and dropOffDestination points
//     Circle pickUpPointCircle = Circle(
//       circleId: const CircleId('pickupCircleID'),
//       strokeColor: Colors.blue,
//       strokeWidth: 4,
//       radius: 14,
//       center: pickupGeoGraphicCoOrdinates,
//       fillColor: Colors.pink,
//     );

//     Circle dropOffDestinationPointCircle = Circle(
//       circleId: const CircleId('dropOffDestinationCircleID'),
//       strokeColor: Colors.blue,
//       strokeWidth: 4,
//       radius: 14,
//       center: dropOffDestinationGeoGraphicCoOrdinates,
//       fillColor: Colors.pink,
//     );

//     setState(() {
//       circleSet.add(pickUpPointCircle);
//       circleSet.add(dropOffDestinationPointCircle);
//     });
//   }

//   resetAppNow() {
//     setState(() {
//       polylineCoOrdinates.clear();
//       polylineSet.clear();
//       markerSet.clear();
//       circleSet.clear();
//       rideDetailsContainerHeight = 0;
//       // paymentContainerHeight = 0;
//       requestContainerHeight = 0;
//       tripContainerHeight = 0;
//       searchContainerHeight = 276;
//       bottomMapPadding = 300;
//       isDrawerOpened = true;

//       status = "";
//       nameDriver = "";
//       photoDriver = "";
//       phoneNumberDriver = "";
//       carDetialsDriver = "";
//       tripStatusDisplay = 'Driver is Arriving';
//       print("resetAppNow");
//     });
//   }

//   cancelRideRequest() {
//     //remove ride request from database
//    _tripRequestRef.deleteData("tripRequests");
//     print("cancelRideRequest");

//     setState(() {
//       stateOfApp = "normal";
//     });
//   }

//   Future<Map<String, dynamic>> createPaymentIntent({
//     required String amount,
//     required String currency,
//   }) async {
//     final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
//     final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
//     final body = {
//       'amount': amount,
//       'currency': currency,
//       'automatic_payment_methods[enabled]': 'true',
//       'description': "Test Payment",
//     };

//     final response = await http.post(
//       url,
//       headers: {
//         "Authorization": "Bearer $secretKey",
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//       body: body,
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Failed to create payment intent');
//     }
//   }

//   Future<void> initPaymentSheet() async {
//     try {
//       // Replace with your API call to create a Payment Intent
//       final data = await createPaymentIntent(
//         amount: '1000', // Example amount in the smallest currency unit
//         currency: 'USD',
//       );

//       // Initialize the payment sheet
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           // Set to true for custom flow
//           customFlow: false,
//           // Main params
//           merchantDisplayName: 'Test Merchant',
//           paymentIntentClientSecret: data['client_secret'],
//           customerEphemeralKeySecret: data['ephemeralKey'],
//           customerId: data['id'],
//           style: ThemeMode.dark,
//         ),
//       );
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//       rethrow;
//     }
//   }

//   Future<void> presentPaymentSheet() async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text('Payment Successful'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       displayRequestContainer();
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text('Payment Failed: $e'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }

//   displayRequestContainer() {
//     print("displayingRequestContainer");
//     setState(() {
//       rideDetailsContainerHeight = 0;
//       // paymentContainerHeight = 0;
//       requestContainerHeight = 220;
//       bottomMapPadding = 200;
//       isDrawerOpened = true;
//     });
//     print("before makeTripRequest function execution");
//     //send ride request
//     makeTripRequest();
//     print("after makeTripRequest function execution");
//   }

//   updateAvailableNearbyOnlineDriversOnMap() {
//     setState(() {
//       markerSet.clear();
//     });

//     Set<Marker> markersTempSet = Set<Marker>();

//     for (OnlineNearbyDrivers eachOnlineNearbyDriver
//         in ManageDriversMethod.nearbyOnlineDriversList) {
//       LatLng driverCurrentPosition = LatLng(
//           eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

//       Marker driverMarker = Marker(
//         markerId: MarkerId(
//             "driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
//         position: driverCurrentPosition,
//         icon: carIconNearbyDriver!,
//       );

//       markersTempSet.add(driverMarker);
//     }

//     setState(() {
//       markerSet = markersTempSet;
//     });
//   }

//   initializeGeoFireListener() {
//     Geofire.initialize("onlineDrivers");
//     Geofire.queryAtLocation(currentPositionOfUser!.latitude,
//             currentPositionOfUser!.longitude, 50)!
//         .listen((driverEvent) {
//       if (driverEvent != null) {
//         var onlineDriverChild = driverEvent["callBack"];

//         switch (onlineDriverChild) {
//           case Geofire.onKeyEntered:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             print(onlineNearbyDrivers.latDriver! + 2000);
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             print(onlineNearbyDrivers.lngDriver! + 2000);
//             ManageDriversMethod.nearbyOnlineDriversList
//                 .add(onlineNearbyDrivers);

//             if (nearbyOnlineDriversKeysLoaded == true) {
//               //update drivers on google map
//               updateAvailableNearbyOnlineDriversOnMap();
//             }

//             break;

//           case Geofire.onKeyExited:
//             print("driver exited");
//             ManageDriversMethod.removeDriverFromList(driverEvent["key"]);

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;

//           case Geofire.onKeyMoved:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             print(onlineNearbyDrivers.latDriver! + 4000);
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             print(onlineNearbyDrivers.lngDriver! + 4000);
//             ManageDriversMethod.updateOnlineNearbyDriversLocation(
//                 onlineNearbyDrivers);

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;

//           case Geofire.onGeoQueryReady:
//             nearbyOnlineDriversKeysLoaded = true;

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;
//         }
//       }
//     });
//   }
//   final DatabaseService _tripRequestRef = DatabaseService();


//   void makeTripRequest() {
//   final user = FirebaseAuth.instance.currentUser;

//   var pickUpLocation =
//       Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//   var dropOffDestinationLocation =
//       Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//   if (pickUpLocation == null || dropOffDestinationLocation == null || user == null) {
//     // Handle the error case where location or user data is null
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Please ensure all necessary information is provided.')),
//     );
//     return;
//   }

//   Map pickUpCoOrdinatesMap = {
//     "latitude": pickUpLocation.latitudePositon.toString(),
//     "longitude": pickUpLocation.longitudePosition.toString(),
//   };

//   Map dropOffDestinationCoOrdinatesMap = {
//     "latitude": dropOffDestinationLocation.latitudePositon.toString(),
//     "longitude": dropOffDestinationLocation.longitudePosition.toString(),
//   };

//   Map driverCoOrdinates = {
//     "latitude": "",
//     "longitude": "",
//   };

//   Map dataMap = {
//     "tripID": _tripRequestRef.dbRef.push().key,
//     "publishDateTime": DateTime.now().toString(),
//     "userName": user.displayName ?? "Anonymous",
//     "userPhone": user.phoneNumber ?? "Unknown",
//     "userID": user.uid,
//     "pickUpLatLng": pickUpCoOrdinatesMap,
//     "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
//     "pickUpAddress": pickUpLocation.placeName,
//     "dropOffAddress": dropOffDestinationLocation.placeName,
//     "driverID": "waiting",
//     "carDetails": "",
//     "driverLocation": driverCoOrdinates,
//     "driverName": "",
//     "driverPhone": "",
//     "driverPhoto": "",
//     "fareAmount": "",
//     "status": "new",
//   };


//   _tripRequestRef.writeData("tripRequests/${dataMap['tripID']}", dataMap.cast<String,dynamic >());

//   tripStreamSubscription = _tripRequestRef.dbRef
//       .child("tripRequests/${dataMap['tripID']}")
//       .onValue
//       .listen((eventSnapshot) async {
//     if (eventSnapshot.snapshot.value == null) {
//       return;
//     }

//     Map<String, dynamic> eventData = Map<String, dynamic>.from(eventSnapshot.snapshot.value as Map);

//     if (eventData["driverName"] != null) {
//       nameDriver = eventData["driverName"];
//     }

//     if (eventData["driverPhone"] != null) {
//       phoneNumberDriver = eventData["driverPhone"];
//     }

//     if (eventData["driverPhoto"] != null) {
//       photoDriver = eventData["driverPhoto"];
//     }

//     if (eventData["carDetails"] != null) {
//       carDetialsDriver = eventData["carDetails"];
//     }

//     if (eventData["status"] != null) {
//       status = eventData["status"];
//     }

//     if (eventData["driverLocation"] != null) {
//       try {
//         double driverLatitude = double.parse(eventData["driverLocation"]["latitude"].toString());
//         double driverLongitude = double.parse(eventData["driverLocation"]["longitude"].toString());
//         LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

//         if (status == "accepted") {
//           // Update info for pickup to user on UI
//           // Info from driver current location to user pickup location
//           updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
//         } else if (status == "arrived") {
//           // Update info for arrived - when driver reaches the pickup point of user
//           setState(() {
//             tripStatusDisplay = 'Driver has Arrived';
//           });
//         } else if (status == "ontrip") {
//           // Update info for dropoff to user on UI
//           // Info from driver current location to user dropoff location
//           updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
//         }
//       } catch (e) {
//         print("Error: $e");
//       }
//     }

//     if (status == "accepted") {
//       displayTripDetailsContainer();

//       Geofire.stopListener();

//       // Remove drivers markers
//       setState(() {
//         markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
//       });
//     }

//     if (status == "ended") {
//       _tripRequestRef.dbRef.child("tripRequests/${dataMap['tripID']}").onDisconnect();
//       tripStreamSubscription!.cancel();
//       tripStreamSubscription = null;

//       resetAppNow();

//       Navigator.push(
//           context,
//           MaterialPageRoute(builder: (BuildContext context) => Homepage()));
//     }
//   });
// }


//   displayTripDetailsContainer() {
//     setState(() {
//       requestContainerHeight = 0;
//       tripContainerHeight = 291;
//       bottomMapPadding = 281;
//     });
//   }

//   updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var userPickUpLocationLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

//       var directionDetailsPickup =
//           await CommonMethods.getDirectionDetailsFromAPI(
//               driverCurrentLocationLatLng, userPickUpLocationLatLng);

//       if (directionDetailsPickup == null) {
//         return;
//       }

//       setState(() {
//         tripStatusDisplay =
//             "Driver is Coming - ${directionDetailsPickup.durationTextString}";
//       });

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   updateFromDriverCurrentLocationToDropOffDestination(
//       driverCurrentLocationLatLng) async {
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var dropOffLocation =
//           Provider.of<Appinfo>(context, listen: false).dropOffLocation;
//       var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePositon!,
//           dropOffLocation.longitudePosition!);

//       var directionDetailsPickup =
//           await CommonMethods.getDirectionDetailsFromAPI(
//               driverCurrentLocationLatLng, userDropOffLocationLatLng);

//       if (directionDetailsPickup == null) {
//         return;
//       }

//       setState(() {
//         tripStatusDisplay =
//             "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
//       });

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   noDriverAvailable() {
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) => InfoDialog(
//               title: "No Driver Available",
//               description:
//                   "No driver found in the nearby location. Please try again shortly.",
//             ));
//     print("NoDriverAvailable");
//   }

//   searchDriver() {
//     if (availableNearbyOnlineDriversList!.length == 0) {
//       print(availableNearbyOnlineDriversList!.length);
//       print("length of available driver 0");
//       cancelRideRequest();
//       resetAppNow();
//       noDriverAvailable();
//       print("SearchDriverEnded");
//       return;
//     }

//     var currentDriver = availableNearbyOnlineDriversList![0];
//     print("driver is found");

//     //send notification to this currentDriver - currentDriver means selected driver
//     sendNotificationToDriver(currentDriver);
//     print("sendNotification1");

//     availableNearbyOnlineDriversList!.removeAt(0);
//   }

//   sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
//     if (tripDirectionDetailsInfo != null) {
//       //update driver's newTripStatus - assign tripID to current driver
//       DatabaseReference currentDriverRef = FirebaseDatabase.instance
//           .ref()
//           .child("drivers")
//           .child(currentDriver.uidDriver.toString())
//           .child("newTripStatus");

//       // print(_tripRequestRef);
//       print("newTripStatus assigned");

//       currentDriverRef.set(_tripRequestRef.dbRef.push().key);
//       print("tripRequestRef formed");

//       //get current driver device recognition token
//       DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
//           .ref()
//           .child("drivers")
//           .child(currentDriver.uidDriver.toString())
//           .child("deviceToken");
//       print(tokenOfCurrentDriverRef);

//       tokenOfCurrentDriverRef.once().then((dataSnapshot) {
//         if (dataSnapshot.snapshot.value != null) {
//           String deviceToken = dataSnapshot.snapshot.value.toString();
//           print("Device Token: $deviceToken");

//           //send notification
//           PushNotificationService.sendNotificationToSelectedDriver(
//               deviceToken, context, _tripRequestRef.dbRef.push().key.toString());
//           print("sendNotification2");
//         } else {
//           print("no token found");
//           return;
//         }

//         const oneTickPerSec = Duration(seconds: 1);

//         Timer.periodic(oneTickPerSec, (timer) {
//           requestTimeoutDriver = requestTimeoutDriver - 1;

//           //when trip request is not requesting means trip request cancelled - stop timer
//           if (stateOfApp != "requesting") {
//             timer.cancel();
//             currentDriverRef.set("cancelled");
//             currentDriverRef.onDisconnect();
//             requestTimeoutDriver = 20;
//             print("sendNotification3");
//           }

//           //when trip request is accepted by online nearest available driver
//           currentDriverRef.onValue.listen((dataSnapshot) {
//             if (dataSnapshot.snapshot.value.toString() == "accepted") {
//               timer.cancel();
//               currentDriverRef.onDisconnect();
//               requestTimeoutDriver = 20;
//               print("sendNotification4");
//             }
//           });

//           //if 20 seconds passed - send notification to next nearest online available driver
//           if (requestTimeoutDriver == 0) {
//             currentDriverRef.set("timeout");
//             timer.cancel();
//             currentDriverRef.onDisconnect();
//             requestTimeoutDriver = 20;
//             print("sendNotification5");

//             //send notification to next nearest online available driver
//             searchDriver();
//             print("searchDriver2");
//           }
//         });
//       });
//     } else {
//       print("tripDirectionDetailsInfo is null");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     makeDriverNearbyCarIcon();

//     return Scaffold(
//       key: sKey,
//       drawer: Container(
//         width: 255,
//         color: Colors.white,
//         child: Drawer(
//           backgroundColor: Colors.white,
//           child: ListView(
//             children: [
//               const Divider(
//                 height: 1,
//                 color: Colors.black,
//                 thickness: 1,
//               ),

//               //header
//               Container(
//                 color: Colors.white,
//                 height: 160,
//                 child: DrawerHeader(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                   ),
//                   child: Row(
//                     children: [
//                       Image.asset(
//                         "assets/images/avatarman.png",
//                         width: 60,
//                         height: 60,
//                       ),
//                       const SizedBox(
//                         width: 16,
//                       ),
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             userName,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 4,
//                           ),
//                           const Text(
//                             "Profile",
//                             style: TextStyle(
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const Divider(
//                 height: 1,
//                 color: Colors.black,
//                 thickness: 1,
//               ),

//               const SizedBox(
//                 height: 10,
//               ),

//               //body
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => PersonalDetailsDisplayPage()),
//                   );
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => PersonalDetailsDisplayPage()),
//                       );
//                     },
//                     icon: const Icon(
//                       Icons.person,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "Personal details",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (c) => TripsHistoryPage()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.history,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "History",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context, MaterialPageRoute(builder: (c) => AboutPage()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.info,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "About",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   FirebaseAuth.instance.signOut();

//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (c) => LoginScreen()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.logout,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "Logout",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           ///google map
//           GoogleMap(
//             padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
//             mapType: MapType.normal,
//             myLocationEnabled: true,
//             polylines: polylineSet,
//             markers: markerSet,
//             circles: circleSet,
//             initialCameraPosition: googlePlexInitialPositon,
//             onMapCreated: (GoogleMapController mapController) {
//               controllerGoogleMap = mapController;
//               updateMapTheme(controllerGoogleMap!);

//               googleMapCompleterController.complete(controllerGoogleMap);

//               setState(() {
//                 bottomMapPadding = 300;
//               });

//               getCurrentLiveLocationOfUser();
//             },
//           ),

//           ///drawer button
//           Positioned(
//             top: 36,
//             left: 19,
//             child: GestureDetector(
//               onTap: () {
//                 if (isDrawerOpened == true) {
//                   sKey.currentState!.openDrawer();
//                 } else {
//                   resetAppNow();
//                 }
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ],
//                 ),
//                 child: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   radius: 20,
//                   child: Icon(
//                     isDrawerOpened == true ? Icons.menu : Icons.close,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           /// payment details

//           ///search location icon button
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: -80,
//             child: Container(
//               height: searchContainerHeight,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () async {
//                       var responseFromSearchPage = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (c) => SearchDestinationPage()));

//                       if (responseFromSearchPage == "placeSelected") {
//                         displayUserRideDetailsContainer();
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.search,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(context,
//                           MaterialPageRoute(builder: (c) => MainPage()));
//                     },
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.home,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.work,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           ///ride details container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: rideDetailsContainerHeight,
//               decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(15),
//                       topRight: Radius.circular(15)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black45,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ]),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 18),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.only(left: 16, right: 16),
//                       child: Padding(
//                         padding: EdgeInsets.only(top: 8, bottom: 8),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "Distance: "
//                                             : "Distance: ",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Color for non-number part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.distanceTextString!}"
//                                             : "0 km",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Color for number part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "Time: "
//                                             : "Time: ",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Color for non-number part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
//                                             : "0 \$",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Color for number part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment
//                                   .spaceBetween, // Distribute space evenly between children
//                               crossAxisAlignment: CrossAxisAlignment
//                                   .center, // Center children vertically
//                               children: [
//                                 GestureDetector(
//                                   onTap: () async {
//                                     setState(() {
//                                       stateOfApp = "requesting";
//                                     });

//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => MobilityAidsPage(
//                                           onFormSubmitted: () async {
//                                             // Continue the remaining code after form submission
//                                             // displayRequestContainer();
//                                             await initPaymentSheet();
//                                             await presentPaymentSheet();
//                                             availableNearbyOnlineDriversList =
//                                                 ManageDriversMethod
//                                                     .nearbyOnlineDriversList;
//                                             print(
//                                                 availableNearbyOnlineDriversList);
//                                             print("ManageDriversMethod1");

//                                             // Search for a driver
//                                             searchDriver();
//                                             print(searchDriver);
//                                           }
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   child: Image.asset(
//                                     "assets/images/uberexec.png",
//                                     height: 100,
//                                     width: 100,
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
//                                             : "0",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Blue color for numeric part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? " away"
//                                             : " away",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Black color for the rest of the text
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? " \$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
//                                             : '',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Blue color for numeric part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           ///request container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: requestContainerHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.white30,
//                     blurRadius: 15.0,
//                     spreadRadius: 0.5,
//                     offset: Offset(
//                       0.7,
//                       0.7,
//                     ),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     SizedBox(
//                       width: 200,
//                       child: LoadingAnimationWidget.flickr(
//                         leftDotColor: Colors.greenAccent,
//                         rightDotColor: Colors.pinkAccent,
//                         size: 50,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         resetAppNow();
//                         cancelRideRequest();
//                       },
//                       child: Container(
//                         height: 50,
//                         width: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.white70,
//                           borderRadius: BorderRadius.circular(25),
//                           border: Border.all(width: 1.5, color: Colors.grey),
//                         ),
//                         child: const Icon(
//                           Icons.close,
//                           color: Colors.black,
//                           size: 25,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           ///trip details container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: tripContainerHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white, // Changed to white background
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12, // Changed to a lighter shadow
//                     blurRadius: 15.0,
//                     spreadRadius: 0.5,
//                     offset: Offset(
//                       0.7,
//                       0.7,
//                     ),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(
//                       height: 5,
//                     ),

//                     // Trip status display text
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           tripStatusDisplay,
//                           style: const TextStyle(
//                             fontSize: 19,
//                             color: Colors.black, // Changed text color to black
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     const Divider(
//                       height: 1,
//                       color: Colors
//                           .black12, // Changed divider color to match new theme
//                       thickness: 1,
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     // Image - driver name and driver car details
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         ClipOval(
//                           child: Image.network(
//                             photoDriver.isEmpty
//                                 ? "https://firebasestorage.googleapis.com/v0/b/cccc-4b8a5.appspot.com/o/avatarman.png?alt=media&token=3d161402-7f8c-4de1-a9ad-96b97a41cc4c"
//                                 : photoDriver,
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 8,
//                         ),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               nameDriver,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 color:
//                                     Colors.black, // Changed text color to black
//                               ),
//                             ),
//                             Text(
//                               carDetialsDriver,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 color: Colors
//                                     .blue, // Slightly lighter black for car details
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     const Divider(
//                       height: 1,
//                       color: Colors
//                           .black12, // Changed divider color to match new theme
//                       thickness: 1,
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     // Call driver button
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             launchUrl(Uri.parse("tel://$phoneNumberDriver"));
//                           },
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 height: 50,
//                                 width: 50,
//                                 decoration: BoxDecoration(
//                                   borderRadius: const BorderRadius.all(
//                                       Radius.circular(25)),
//                                   color: Colors
//                                       .blue, // Changed button background color to blue
//                                   border: Border.all(
//                                     width: 1,
//                                     color: Colors
//                                         .blue, // Changed button border color to blue
//                                   ),
//                                 ),
//                                 child: const Icon(
//                                   Icons.phone,
//                                   color: Colors
//                                       .white, // Changed icon color to white
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 11,
//                               ),
//                               const Text(
//                                 "Call",
//                                 style: TextStyle(
//                                   color:
//                                       Colors.blue, // Changed text color to blue
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }







// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';

// import 'package:cccc/forms/mobility_aids.dart';
// import 'package:cccc/pages/main_page.dart';
// import 'package:cccc/pages/personal_details_page.dart';
// import 'package:cccc/payment/payment_mobile.dart';
// import 'package:cccc/payment/payment_web.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:cccc/authentication/login_screen.dart';
// import 'package:cccc/global/global_var.dart';
// import 'package:cccc/global/trip_var.dart';
// import 'package:cccc/methods/common_methods.dart';
// import 'package:cccc/methods/manage_drivers_method.dart';
// import 'package:cccc/methods/push_notification_service.dart';
// import 'package:cccc/models/direction_details.dart';
// import 'package:cccc/models/online_nearby_drivers.dart';
// import 'package:cccc/pages/about_page.dart';
// import 'package:cccc/pages/search_destination_page.dart';
// import 'package:cccc/pages/trip_history_page.dart';
// import 'package:cccc/widgets/info_dialog.dart';
// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:cccc/widgets/loading_dialog.dart';

// class HomepageWeb extends StatefulWidget {
//   const HomepageWeb({super.key});

//   @override
//   State<HomepageWeb> createState() => _HomepageWebState();
// }

// class _HomepageWebState extends State<HomepageWeb> {
//   final Completer<GoogleMapController> googleMapCompleterController =
//       Completer<GoogleMapController>();
//   GoogleMapController? controllerGoogleMap;
//   Position? currentPositionOfUser;
//   GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
//   CommonMethods cMethods = CommonMethods();
//   double searchContainerHeight = 276;
//   double bottomMapPadding = 0;
//   double rideDetailsContainerHeight = 0;
//   double requestContainerHeight = 0;
//   double tripContainerHeight = 0;
//   DirectionDetails? tripDirectionDetailsInfo;
//   List<LatLng> polylineCoOrdinates = [];
//   Set<Polyline> polylineSet = {};
//   Set<Marker> markerSet = {};
//   Set<Circle> circleSet = {};
//   bool isDrawerOpened = true;
//   String stateOfApp = "normal";
//   bool nearbyOnlineDriversKeysLoaded = false;
//   BitmapDescriptor? carIconNearbyDriver;
//   DatabaseReference? tripRequestRef;
//   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
//   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
//   bool requestingDirectionDetailsInfo = false;

//   final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//       GlobalKey<ScaffoldMessengerState>();

//   makeDriverNearbyCarIcon() {
//     if (carIconNearbyDriver == null) {
//       ImageConfiguration configuration =
//           createLocalImageConfiguration(context, size: Size(0.5, 0.5));
//       BitmapDescriptor.fromAssetImage(
//               configuration, "assets/images/tracking.png")
//           .then((iconImage) {
//         carIconNearbyDriver = iconImage;
//       });
//     }
//   }

//   void updateMapTheme(GoogleMapController controller) {
//     getJsonFileFromThemes("themes/light_style.json")
//         .then((value) => setGoogleMapStyle(value, controller));
//   }

//   Future<String> getJsonFileFromThemes(String mapStylePath) async {
//     ByteData byteData = await rootBundle.load(mapStylePath);
//     var list = byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
//     return utf8.decode(list);
//   }

//   setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
//     controller.setMapStyle(googleMapStyle);
//   }

//   getCurrentLiveLocationOfUser() async {
//     try {
//       Position positionOfUser = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       currentPositionOfUser = positionOfUser;

//       LatLng positionOfUserInLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//           print(positionOfUserInLatLng);

//       CameraPosition cameraPosition =
//           CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//       controllerGoogleMap!
//           .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//       await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
//           currentPositionOfUser!, context);

//       await getUserInfoAndCheckBlockStatus();
//       if (!kIsWeb) {
//         await initializeGeoFireListener();
//       } else {
//         print("initializeGeoFireListenerWeb");
//         initializeGeoFireListenerWeb();
//       }
//     } catch (e) {
//       // Handle exceptions if needed
//       print('Error in getCurrentLiveLocationOfUser: $e');
//     }
//   }

//   getUserInfoAndCheckBlockStatus() async {
//     try {
//       DatabaseReference usersRef = FirebaseDatabase.instance
//           .ref()
//           .child("users")
//           .child(FirebaseAuth.instance.currentUser!.uid);

//       DatabaseEvent event = await usersRef.once();
//       DataSnapshot snap = event.snapshot;

//       if (snap.value != null) {
//         Map userData = snap.value as Map;
//         String? blockStatus = userData["blockStatus"];
//         String? name = userData["firstName"];
//         String? phone = userData["phone"];

//         if (blockStatus == "no") {
//           if (mounted) {
//             setState(() {
//               userName = name ?? 'Unknown';
//               userPhone = phone ?? 'Unknown';
//             });
//           }
//         } else {
//           FirebaseAuth.instance.signOut();
//           if (mounted) {
//             Navigator.pushReplacement(
//                 context, MaterialPageRoute(builder: (c) => LoginScreen()));

//             cMethods.displaySnackbar(
//                 "You are blocked. Contact admin: alizeb875@gmail.com", context);
//           }
//         }
//       } else {
//         FirebaseAuth.instance.signOut();
//         if (mounted) {
//           Navigator.pushReplacement(
//               context, MaterialPageRoute(builder: (c) => LoginScreen()));
//         }
//       }
//     } catch (e) {
//       // Handle exceptions if needed
//       print('Error in getUserInfoAndCheckBlockStatus: $e');
//     }
//   }

//   displayUserRideDetailsContainer() async {
//     ///Directions API
//     await retrieveDirectionDetails();

//     setState(() {
//       searchContainerHeight = 0;
//       bottomMapPadding = 240;
//       rideDetailsContainerHeight = 180;
//       isDrawerOpened = false;
//     });
//   }

//   retrieveDirectionDetails() async {
//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     var pickupGeoGraphicCoOrdinates = LatLng(
//         pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
//     var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
//         dropOffDestinationLocation!.latitudePositon!,
//         dropOffDestinationLocation.longitudePosition!);

//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (BuildContext context) =>
//           LoadingDialog(messageText: "Getting direction..."),
//     );

//     ///Directions API
//     var detailsFromDirectionAPI =
//         await CommonMethods.getDirectionDetailsFromAPI(
//             pickupGeoGraphicCoOrdinates,
//             dropOffDestinationGeoGraphicCoOrdinates);
//     setState(() {
//       tripDirectionDetailsInfo = detailsFromDirectionAPI;
//     });

//     Navigator.pop(context);

//     //draw route from pickup to dropOffDestination
//     PolylinePoints pointsPolyline = PolylinePoints();
//     List<PointLatLng> latLngPointsFromPickUpToDestination =
//         pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

//     polylineCoOrdinates.clear();
//     if (latLngPointsFromPickUpToDestination.isNotEmpty) {
//       latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
//         polylineCoOrdinates
//             .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
//       });
//     }

//     polylineSet.clear();
//     setState(() {
//       Polyline polyline = Polyline(
//         polylineId: const PolylineId("polylineID"),
//         color: Colors.pink,
//         points: polylineCoOrdinates,
//         jointType: JointType.round,
//         width: 4,
//         startCap: Cap.roundCap,
//         endCap: Cap.roundCap,
//         geodesic: true,
//       );

//       polylineSet.add(polyline);
//     });

//     //fit the polyline into the map
//     LatLngBounds boundsLatLng;
//     if (pickupGeoGraphicCoOrdinates.latitude >
//             dropOffDestinationGeoGraphicCoOrdinates.latitude &&
//         pickupGeoGraphicCoOrdinates.longitude >
//             dropOffDestinationGeoGraphicCoOrdinates.longitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: dropOffDestinationGeoGraphicCoOrdinates,
//         northeast: pickupGeoGraphicCoOrdinates,
//       );
//     } else if (pickupGeoGraphicCoOrdinates.longitude >
//         dropOffDestinationGeoGraphicCoOrdinates.longitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude,
//             dropOffDestinationGeoGraphicCoOrdinates.longitude),
//         northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
//             pickupGeoGraphicCoOrdinates.longitude),
//       );
//     } else if (pickupGeoGraphicCoOrdinates.latitude >
//         dropOffDestinationGeoGraphicCoOrdinates.latitude) {
//       boundsLatLng = LatLngBounds(
//         southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
//             pickupGeoGraphicCoOrdinates.longitude),
//         northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude,
//             dropOffDestinationGeoGraphicCoOrdinates.longitude),
//       );
//     } else {
//       boundsLatLng = LatLngBounds(
//         southwest: pickupGeoGraphicCoOrdinates,
//         northeast: dropOffDestinationGeoGraphicCoOrdinates,
//       );
//     }

//     controllerGoogleMap!
//         .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

//     //add markers to pickup and dropOffDestination points
//     Marker pickUpPointMarker = Marker(
//       markerId: const MarkerId("pickUpPointMarkerID"),
//       position: pickupGeoGraphicCoOrdinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       infoWindow: InfoWindow(
//           title: pickUpLocation.placeName, snippet: "Pickup Location"),
//     );

//     Marker dropOffDestinationPointMarker = Marker(
//       markerId: const MarkerId("dropOffDestinationPointMarkerID"),
//       position: dropOffDestinationGeoGraphicCoOrdinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//       infoWindow: InfoWindow(
//           title: dropOffDestinationLocation.placeName,
//           snippet: "Destination Location"),
//     );

//     setState(() {
//       markerSet.add(pickUpPointMarker);
//       markerSet.add(dropOffDestinationPointMarker);
//     });

//     //add circles to pickup and dropOffDestination points
//     Circle pickUpPointCircle = Circle(
//       circleId: const CircleId('pickupCircleID'),
//       strokeColor: Colors.blue,
//       strokeWidth: 4,
//       radius: 14,
//       center: pickupGeoGraphicCoOrdinates,
//       fillColor: Colors.pink,
//     );

//     Circle dropOffDestinationPointCircle = Circle(
//       circleId: const CircleId('dropOffDestinationCircleID'),
//       strokeColor: Colors.blue,
//       strokeWidth: 4,
//       radius: 14,
//       center: dropOffDestinationGeoGraphicCoOrdinates,
//       fillColor: Colors.pink,
//     );

//     setState(() {
//       circleSet.add(pickUpPointCircle);
//       circleSet.add(dropOffDestinationPointCircle);
//     });
//   }

//   resetAppNow() {
//     setState(() {
//       polylineCoOrdinates.clear();
//       polylineSet.clear();
//       markerSet.clear();
//       circleSet.clear();
//       rideDetailsContainerHeight = 0;
//       // paymentContainerHeight = 0;
//       requestContainerHeight = 0;
//       tripContainerHeight = 0;
//       searchContainerHeight = 276;
//       bottomMapPadding = 300;
//       isDrawerOpened = true;

//       status = "";
//       nameDriver = "";
//       photoDriver = "";
//       phoneNumberDriver = "";
//       carDetialsDriver = "";
//       tripStatusDisplay = 'Driver is Arriving';
//       print("resetAppNow");
//     });
//   }

//   cancelRideRequest() {
//     //remove ride request from database
//     tripRequestRef!.remove();
//     print("cancelRideRequest");

//     setState(() {
//       stateOfApp = "normal";
//     });
//   }

//   // Future<Map<String, dynamic>> createPaymentIntent({
//   //   required String amount,
//   //   required String currency,
//   // }) async {
//   //   final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
//   //   final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
//   //   final body = {
//   //     'amount': amount,
//   //     'currency': currency,
//   //     'automatic_payment_methods[enabled]': 'true',
//   //     'description': "Test Payment",
//   //   };

//   //   final response = await http.post(
//   //     url,
//   //     headers: {
//   //       "Authorization": "Bearer $secretKey",
//   //       'Content-Type': 'application/x-www-form-urlencoded',
//   //     },
//   //     body: body,
//   //   );

//   //   if (response.statusCode == 200) {
//   //     return jsonDecode(response.body);
//   //   } else {
//   //     final errorResponse = jsonDecode(response.body);
//   //     print('Failed to create payment intent: $errorResponse');
//   //     throw Exception(
//   //         'Failed to create payment intent: ${errorResponse['error']['message']}');
//   //   }
//   // }

//   // Future<void> initPaymentSheet(String amount) async {
//   //   try {
//   //     final data = await createPaymentIntent(
//   //       amount: amount,
//   //       currency: 'USD',
//   //     );

//   //     await Stripe.instance.initPaymentSheet(
//   //       paymentSheetParameters: SetupPaymentSheetParameters(
//   //         customFlow: false,
//   //         merchantDisplayName: 'Test Merchant',
//   //         paymentIntentClientSecret: data['client_secret'],
//   //         customerEphemeralKeySecret: data['ephemeralKey'],
//   //         customerId: data['id'],
//   //         style: ThemeMode.dark,
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     scaffoldMessengerKey.currentState?.showSnackBar(
//   //       SnackBar(content: Text('Error: $e')),
//   //     );
//   //     rethrow;
//   //   }
//   // }

//   Future<void> presentPaymentSheet() async {
//     try {
//       await Stripe.instance.presentPaymentSheet();
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text('Payment Successful'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       displayRequestContainer();
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(
//           content: Text('Payment Failed: $e'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }

//   displayRequestContainer() {
//     print("displayingRequestContainer");
//     setState(() {
//       rideDetailsContainerHeight = 0;
//       // paymentContainerHeight = 0;
//       requestContainerHeight = 220;
//       bottomMapPadding = 200;
//       isDrawerOpened = true;
//     });
//     print("before makeTripRequest function execution");
//     //send ride request
//     makeTripRequest();
//     print("after makeTripRequest function execution");
//   }

//   updateAvailableNearbyOnlineDriversOnMap() {
//     setState(() {
//       markerSet.clear();
//     });

//     Set<Marker> markersTempSet = Set<Marker>();

//     for (OnlineNearbyDrivers eachOnlineNearbyDriver
//         in ManageDriversMethod.nearbyOnlineDriversList) {
//       LatLng driverCurrentPosition = LatLng(
//           eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

//       Marker driverMarker = Marker(
//         markerId: MarkerId(
//             "driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
//         position: driverCurrentPosition,
//         icon: carIconNearbyDriver!,
//       );

//       markersTempSet.add(driverMarker);
//     }

//     setState(() {
//       markerSet = markersTempSet;
//     });
//   }

//   initializeGeoFireListener() {
//     Geofire.initialize("onlineDrivers");
//     Geofire.queryAtLocation(currentPositionOfUser!.latitude,
//             currentPositionOfUser!.longitude, 50)!
//         .listen((driverEvent) {
//       if (driverEvent != null) {
//         var onlineDriverChild = driverEvent["callBack"];

//         switch (onlineDriverChild) {
//           case Geofire.onKeyEntered:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             print(onlineNearbyDrivers.latDriver! + 2000);
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             print(onlineNearbyDrivers.lngDriver! + 2000);
//             ManageDriversMethod.nearbyOnlineDriversList
//                 .add(onlineNearbyDrivers);

//             if (nearbyOnlineDriversKeysLoaded == true) {
//               //update drivers on google map
//               updateAvailableNearbyOnlineDriversOnMap();
//             }

//             break;

//           case Geofire.onKeyExited:
//             print("driver exited");
//             ManageDriversMethod.removeDriverFromList(driverEvent["key"]);

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;

//           case Geofire.onKeyMoved:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             print(onlineNearbyDrivers.latDriver! + 4000);
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             print(onlineNearbyDrivers.lngDriver! + 4000);
//             ManageDriversMethod.updateOnlineNearbyDriversLocation(
//                 onlineNearbyDrivers);

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;

//           case Geofire.onGeoQueryReady:
//             nearbyOnlineDriversKeysLoaded = true;

//             //update drivers on google map
//             updateAvailableNearbyOnlineDriversOnMap();

//             break;
//         }
//       }
//     });
//   }

//   bool _isWithinRadius(double driverLat, double driverLng, double centerLat,
//       double centerLng, double radiusInKm) {
//     const double earthRadiusInKm = 6371.0;

//     double dLat = _degreesToRadians(driverLat - centerLat);
//     double dLng = _degreesToRadians(driverLng - centerLng);

//     double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(centerLat)) *
//             cos(_degreesToRadians(driverLat)) *
//             sin(dLng / 2) *
//             sin(dLng / 2);

//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     double distance = earthRadiusInKm * c;

//     return distance <= radiusInKm;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * pi / 180.0;
//   }

//   initializeGeoFireListenerWeb() {
//     print('Starting initializeGeoFireListenerWeb');

//     final DatabaseReference driversRef =
//         FirebaseDatabase.instance.ref().child("onlineDrivers");
//     print('Fetched driversRef');

//     final double latitude = currentPositionOfUser!.latitude;
//     final double longitude = currentPositionOfUser!.longitude;
//     final double radiusInKm = 50.0;

//     final query = driversRef
//         .orderByChild('position'); // Assume 'position' is lat/lng pair
//     print('Created query for drivers based on position');

//     query.onValue.listen((event) {
//       print('Received event in GeoFire listener');
//       if (event.snapshot.value != null) {
//         final Map<dynamic, dynamic> driversMap =
//             event.snapshot.value as Map<dynamic, dynamic>;
//         print('Fetched driversMap with ${driversMap.length} entries');
//         driversMap.forEach((key, value) {
//           print('Processing driver: $key');

//           // Assuming value contains the position data as latitude and longitude
//           double driverLat = value['latitude'];
//           double driverLng = value['longitude'];

//           // Check if the driver is within the radius
//           if (_isWithinRadius(
//               driverLat, driverLng, latitude, longitude, radiusInKm)) {
//             // Handle the driver as within the radius
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = key;
//             onlineNearbyDrivers.latDriver = driverLat;
//             onlineNearbyDrivers.lngDriver = driverLng;

//             ManageDriversMethod.nearbyOnlineDriversList
//                 .add(onlineNearbyDrivers);

//             if (nearbyOnlineDriversKeysLoaded == true) {
//               //update drivers on google map
//               updateAvailableNearbyOnlineDriversOnMap();
//             }
//           } else {
//             // Handle the driver as outside the radius if necessary
//             print('Driver $key is outside the radius');
//           }
//         });

//         nearbyOnlineDriversKeysLoaded = true;

//         //update drivers on google map
//         updateAvailableNearbyOnlineDriversOnMap();
//       } else {
//         print('No drivers found in GeoFire listener');
//       }
//     }).onError((error) {
//       print('Error in GeoFire listener: $error');
//     });

//     print('initializeGeoFireListenerWeb completed');
//   }

//   makeTripRequest() {
//     print("before tripRequestRef");
//     tripRequestRef =
//         FirebaseDatabase.instance.ref().child("tripRequests").push();
//     print("after tripRequestRef");

//     print(tripRequestRef);
//     print("makeTripRequest");
//     print("makeTripRequest");

//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     Map pickUpCoOrdinatesMap = {
//       "latitude": pickUpLocation!.latitudePositon.toString(),
//       "longitude": pickUpLocation.longitudePosition.toString(),
//     };

//     Map dropOffDestinationCoOrdinatesMap = {
//       "latitude": dropOffDestinationLocation!.latitudePositon.toString(),
//       "longitude": dropOffDestinationLocation.longitudePosition.toString(),
//     };

//     Map driverCoOrdinates = {
//       "latitude": "",
//       "longitude": "",
//     };

//     Map dataMap = {
//       "tripID": tripRequestRef!.key,
//       "publishDateTime": DateTime.now().toString(),
//       "userName": userName,
//       "userPhone": userPhone,
//       "userID": userID,
//       "pickUpLatLng": pickUpCoOrdinatesMap,
//       "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
//       "pickUpAddress": pickUpLocation.placeName,
//       "dropOffAddress": dropOffDestinationLocation.placeName,
//       "driverID": "waiting",
//       "carDetails": "",
//       "driverLocation": driverCoOrdinates,
//       "driverName": "",
//       "driverPhone": "",
//       "driverPhoto": "",
//       "fareAmount": "",
//       "status": "new",
//     };

//     tripRequestRef!.set(dataMap);

//     tripStreamSubscription =
//         tripRequestRef!.onValue.listen((eventSnapshot) async {
//       if (eventSnapshot.snapshot.value == null) {
//         return;
//       }

//       if ((eventSnapshot.snapshot.value as Map)["driverName"] != null) {
//         nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
//       }

//       if ((eventSnapshot.snapshot.value as Map)["driverPhone"] != null) {
//         phoneNumberDriver =
//             (eventSnapshot.snapshot.value as Map)["driverPhone"];
//       }

//       if ((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null) {
//         photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
//       }

//       if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
//         carDetialsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
//       }

//       if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
//         status = (eventSnapshot.snapshot.value as Map)["status"];
//       }

//       if ((eventSnapshot.snapshot.value as Map)["driverLocation"] != null) {
//         try {
//           double driverLatitude = double.parse((eventSnapshot.snapshot.value
//                   as Map)["driverLocation"]["latitude"]
//               .toString());
//           print(driverLatitude);
//           double driverLongitude = double.parse((eventSnapshot.snapshot.value
//                   as Map)["driverLocation"]["longitude"]
//               .toString());
//           print(driverLongitude);
//           LatLng driverCurrentLocationLatLng =
//               LatLng(driverLatitude, driverLongitude);

//           if (status == "accepted") {
//             //update info for pickup to user on UI
//             //info from driver current location to user pickup location
//             updateFromDriverCurrentLocationToPickUp(
//                 driverCurrentLocationLatLng);
//           } else if (status == "arrived") {
//             //update info for arrived - when driver reach at the pickup point of user
//             setState(() {
//               tripStatusDisplay = 'Driver has Arrived';
//             });
//           } else if (status == "ontrip") {
//             //update info for dropoff to user on UI
//             //info from driver current location to user dropoff location
//             updateFromDriverCurrentLocationToDropOffDestination(
//                 driverCurrentLocationLatLng);
//           }
//         } on Exception catch (e) {
//           print("error : $e");
//         }
//       }

//       if (status == "accepted") {
//         displayTripDetailsContainer();

//         Geofire.stopListener();

//         //remove drivers markers
//         setState(() {
//           markerSet.removeWhere(
//               (element) => element.markerId.value.contains("driver"));
//         });
//       }

//       if (status == "ended") {
//         tripRequestRef!.onDisconnect();
//         tripRequestRef = null;

//         tripStreamSubscription!.cancel();
//         tripStreamSubscription = null;

//         resetAppNow();

//         Navigator.push(context,
//             MaterialPageRoute(builder: (BuildContext context) => HomepageWeb()));
//       }
//     });
//   }

//   displayTripDetailsContainer() {
//     setState(() {
//       requestContainerHeight = 0;
//       tripContainerHeight = 291;
//       bottomMapPadding = 281;
//     });
//   }

//   updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var userPickUpLocationLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

//       var directionDetailsPickup =
//           await CommonMethods.getDirectionDetailsFromAPI(
//               driverCurrentLocationLatLng, userPickUpLocationLatLng);

//       if (directionDetailsPickup == null) {
//         return;
//       }

//       setState(() {
//         tripStatusDisplay =
//             "Driver is Coming - ${directionDetailsPickup.durationTextString}";
//       });

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   updateFromDriverCurrentLocationToDropOffDestination(
//       driverCurrentLocationLatLng) async {
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var dropOffLocation =
//           Provider.of<Appinfo>(context, listen: false).dropOffLocation;
//       var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePositon!,
//           dropOffLocation.longitudePosition!);

//       var directionDetailsPickup =
//           await CommonMethods.getDirectionDetailsFromAPI(
//               driverCurrentLocationLatLng, userDropOffLocationLatLng);

//       if (directionDetailsPickup == null) {
//         return;
//       }

//       setState(() {
//         tripStatusDisplay =
//             "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
//       });

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   noDriverAvailable() {
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) => InfoDialog(
//               title: "No Driver Available",
//               description:
//                   "No driver found in the nearby location. Please try again shortly.",
//             ));
//     print("NoDriverAvailable");
//   }

//   searchDriver() {
//     if (availableNearbyOnlineDriversList!.length == 0) {
//       print(availableNearbyOnlineDriversList!.length);
//       print("length of available driver 0");
//       cancelRideRequest();
//       resetAppNow();
//       noDriverAvailable();
//       print("SearchDriverEnded");
//       return;
//     }

//     var currentDriver = availableNearbyOnlineDriversList![0];
//     print("driver is found");

//     //send notification to this currentDriver - currentDriver means selected driver
//     sendNotificationToDriver(currentDriver);
//     print("sendNotification1");

//     availableNearbyOnlineDriversList!.removeAt(0);
//   }

//   sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
//     if (tripDirectionDetailsInfo != null) {
//       //update driver's newTripStatus - assign tripID to current driver
//       DatabaseReference currentDriverRef = FirebaseDatabase.instance
//           .ref()
//           .child("drivers")
//           .child(currentDriver.uidDriver.toString())
//           .child("newTripStatus");

//       print(tripRequestRef);
//       print("newTripStatus assigned");

//       currentDriverRef.set(tripRequestRef!.key);
//       print("tripRequestRef formed");

//       //get current driver device recognition token
//       DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
//           .ref()
//           .child("drivers")
//           .child(currentDriver.uidDriver.toString())
//           .child("deviceToken");
//       print(tokenOfCurrentDriverRef);

//       tokenOfCurrentDriverRef.once().then((dataSnapshot) {
//         if (dataSnapshot.snapshot.value != null) {
//           String deviceToken = dataSnapshot.snapshot.value.toString();
//           print("Device Token: $deviceToken");

//           //send notification
//           PushNotificationService.sendNotificationToSelectedDriver(
//               deviceToken, context, tripRequestRef!.key.toString());
//           print("sendNotification2");
//         } else {
//           print("no token found");
//           return;
//         }

//         const oneTickPerSec = Duration(seconds: 1);

//         Timer.periodic(oneTickPerSec, (timer) {
//           requestTimeoutDriver = requestTimeoutDriver - 1;

//           //when trip request is not requesting means trip request cancelled - stop timer
//           if (stateOfApp != "requesting") {
//             timer.cancel();
//             currentDriverRef.set("cancelled");
//             currentDriverRef.onDisconnect();
//             requestTimeoutDriver = 20;
//             print("sendNotification3");
//           }

//           //when trip request is accepted by online nearest available driver
//           currentDriverRef.onValue.listen((dataSnapshot) {
//             if (dataSnapshot.snapshot.value.toString() == "accepted") {
//               timer.cancel();
//               currentDriverRef.onDisconnect();
//               requestTimeoutDriver = 20;
//               print("sendNotification4");
//             }
//           });

//           //if 20 seconds passed - send notification to next nearest online available driver
//           if (requestTimeoutDriver == 0) {
//             currentDriverRef.set("timeout");
//             timer.cancel();
//             currentDriverRef.onDisconnect();
//             requestTimeoutDriver = 20;
//             print("sendNotification5");

//             //send notification to next nearest online available driver
//             searchDriver();
//             print("searchDriver2");
//           }
//         });
//       });
//     } else {
//       print("tripDirectionDetailsInfo is null");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     makeDriverNearbyCarIcon();

//     return Scaffold(
//       key: sKey,
//       drawer: Container(
//         width: 255,
//         color: Colors.white,
//         child: Drawer(
//           backgroundColor: Colors.white,
//           child: ListView(
//             children: [
//               const Divider(
//                 height: 1,
//                 color: Colors.black,
//                 thickness: 1,
//               ),

//               //header
//               Container(
//                 color: Colors.white,
//                 height: 160,
//                 child: DrawerHeader(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                   ),
//                   child: Row(
//                     children: [
//                       Image.asset(
//                         "assets/images/avatarman.png",
//                         width: 60,
//                         height: 60,
//                       ),
//                       const SizedBox(
//                         width: 16,
//                       ),
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             userName,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 4,
//                           ),
//                           const Text(
//                             "Profile",
//                             style: TextStyle(
//                               color: Colors.blue,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const Divider(
//                 height: 1,
//                 color: Colors.black,
//                 thickness: 1,
//               ),

//               const SizedBox(
//                 height: 10,
//               ),

//               //body
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => PersonalDetailsDisplayPage()),
//                   );
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => PersonalDetailsDisplayPage()),
//                       );
//                     },
//                     icon: const Icon(
//                       Icons.person,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "Personal details",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (c) => TripsHistoryPage()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.history,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "History",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context, MaterialPageRoute(builder: (c) => AboutPage()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.info,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "About",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),

//               GestureDetector(
//                 onTap: () {
//                   FirebaseAuth.instance.signOut();

//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (c) => LoginScreen()));
//                 },
//                 child: ListTile(
//                   leading: IconButton(
//                     onPressed: () {},
//                     icon: const Icon(
//                       Icons.logout,
//                       color: Colors.black,
//                     ),
//                   ),
//                   title: const Text(
//                     "Logout",
//                     style: TextStyle(color: Colors.black),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           ///google map
//           GoogleMap(
//             padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
//             mapType: MapType.normal,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             polylines: polylineSet,
//             markers: markerSet,
//             circles: circleSet,
//             initialCameraPosition: googlePlexInitialPositon,
//             onMapCreated: (GoogleMapController mapController) {
//               controllerGoogleMap = mapController;
//               updateMapTheme(controllerGoogleMap!);

//               googleMapCompleterController.complete(controllerGoogleMap);

//               setState(() {
//                 bottomMapPadding = 300;
//               });
//               print("before getcurrentlivelocationofuser");
//               getCurrentLiveLocationOfUser();
//               print("after getcurrentlivelocationofuser");

              
//             },
//           ),

//           ///drawer button
//           Positioned(
//             top: 36,
//             left: 19,
//             child: GestureDetector(
//               onTap: () {
//                 if (isDrawerOpened == true) {
//                   sKey.currentState!.openDrawer();
//                 } else {
//                   resetAppNow();
//                 }
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ],
//                 ),
//                 child: CircleAvatar(
//                   backgroundColor: Colors.white,
//                   radius: 20,
//                   child: Icon(
//                     isDrawerOpened == true ? Icons.menu : Icons.close,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           /// payment details

//           ///search location icon button
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: -80,
//             child: Container(
//               height: searchContainerHeight,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () async {
//                       var responseFromSearchPage = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (c) => SearchDestinationPage()));

//                       if (responseFromSearchPage == "placeSelected") {
//                         displayUserRideDetailsContainer();
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.search,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(context,
//                           MaterialPageRoute(builder: (c) => MainPage()));
//                     },
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.home,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         padding: const EdgeInsets.all(24)),
//                     child: const Icon(
//                       Icons.work,
//                       color: Colors.black,
//                       size: 25,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           ///ride details container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: rideDetailsContainerHeight,
//               decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(15),
//                       topRight: Radius.circular(15)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black45,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ]),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 18),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Padding(
//                       padding: EdgeInsets.only(left: 16, right: 16),
//                       child: Padding(
//                         padding: EdgeInsets.only(top: 8, bottom: 8),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "Distance: "
//                                             : "Distance: ",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Color for non-number part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.distanceTextString!}"
//                                             : "0 km",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Color for number part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "Time: "
//                                             : "Time: ",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Color for non-number part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
//                                             : "0 \$",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Color for number part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment
//                                   .spaceBetween, // Distribute space evenly between children
//                               crossAxisAlignment: CrossAxisAlignment
//                                   .center, // Center children vertically
//                               children: [
//                                 GestureDetector(
//                                   onTap: () async {
//                                     setState(() {
//                                       stateOfApp = "requesting";
//                                     });

//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => MobilityAidsPage(
//                                           onFormSubmitted: () async {
//                                             // Continue the remaining code after form submission
//                                             // displayRequestContainer();
//                                             double c =
//                                                 cMethods.calculateFareAmount(
//                                                     tripDirectionDetailsInfo!);
//                                             // Ensure amount is a valid integer in cents
//                                             int amountInCents =
//                                                 (c * 100).round();
//                                             String amount =
//                                                 amountInCents.toString();
//                                             if(!kIsWeb){
//                                             await initPaymentSheet(amount);
//                                             await presentPaymentSheet();
//                                             }
//                                             else{
//                                               await initPaymentSheetWeb(amount);
//                                               await presentPaymentSheet();
//                                             }
//                                             // audioPlayer.open(Audio("assets/audio/alert_sound.mp3"));
//                                             availableNearbyOnlineDriversList =
//                                                 ManageDriversMethod
//                                                     .nearbyOnlineDriversList;
//                                             print(
//                                                 availableNearbyOnlineDriversList);
//                                             print("ManageDriversMethod1");

//                                             // Search for a driver
//                                             searchDriver();
//                                             print(searchDriver);
//                                           },
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   child: Image.asset(
//                                     "assets/images/uberexec.png",
//                                     height: 100,
//                                     width: 100,
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
//                                             : "0",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Blue color for numeric part
//                                         ),
//                                       ),
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? " away"
//                                             : " away",
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // Black color for the rest of the text
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     children: [
//                                       TextSpan(
//                                         text: (tripDirectionDetailsInfo != null)
//                                             ? " \$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
//                                             : '',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .blue, // Blue color for numeric part
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           ///request container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: requestContainerHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.white30,
//                     blurRadius: 15.0,
//                     spreadRadius: 0.5,
//                     offset: Offset(
//                       0.7,
//                       0.7,
//                     ),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     SizedBox(
//                       width: 200,
//                       child: LoadingAnimationWidget.flickr(
//                         leftDotColor: Colors.greenAccent,
//                         rightDotColor: Colors.pinkAccent,
//                         size: 50,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         resetAppNow();
//                         cancelRideRequest();
//                       },
//                       child: Container(
//                         height: 50,
//                         width: 50,
//                         decoration: BoxDecoration(
//                           color: Colors.white70,
//                           borderRadius: BorderRadius.circular(25),
//                           border: Border.all(width: 1.5, color: Colors.grey),
//                         ),
//                         child: const Icon(
//                           Icons.close,
//                           color: Colors.black,
//                           size: 25,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           ///trip details container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: tripContainerHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white, // Changed to white background
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12, // Changed to a lighter shadow
//                     blurRadius: 15.0,
//                     spreadRadius: 0.5,
//                     offset: Offset(
//                       0.7,
//                       0.7,
//                     ),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(
//                       height: 5,
//                     ),

//                     // Trip status display text
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           tripStatusDisplay,
//                           style: const TextStyle(
//                             fontSize: 19,
//                             color: Colors.black, // Changed text color to black
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     const Divider(
//                       height: 1,
//                       color: Colors
//                           .black12, // Changed divider color to match new theme
//                       thickness: 1,
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     // Image - driver name and driver car details
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         ClipOval(
//                           child: Image.network(
//                             photoDriver.isEmpty
//                                 ? "https://firebasestorage.googleapis.com/v0/b/cccc-4b8a5.appspot.com/o/avatarman.png?alt=media&token=3d161402-7f8c-4de1-a9ad-96b97a41cc4c"
//                                 : photoDriver,
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 8,
//                         ),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               nameDriver,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 color:
//                                     Colors.black, // Changed text color to black
//                               ),
//                             ),
//                             Text(
//                               carDetialsDriver,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 color: Colors
//                                     .blue, // Slightly lighter black for car details
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     const Divider(
//                       height: 1,
//                       color: Colors
//                           .black12, // Changed divider color to match new theme
//                       thickness: 1,
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),

//                     // Call driver button
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             launchUrl(Uri.parse("tel://$phoneNumberDriver"));
//                           },
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 height: 50,
//                                 width: 50,
//                                 decoration: BoxDecoration(
//                                   borderRadius: const BorderRadius.all(
//                                       Radius.circular(25)),
//                                   color: Colors
//                                       .blue, // Changed button background color to blue
//                                   border: Border.all(
//                                     width: 1,
//                                     color: Colors
//                                         .blue, // Changed button border color to blue
//                                   ),
//                                 ),
//                                 child: const Icon(
//                                   Icons.phone,
//                                   color: Colors
//                                       .white, // Changed icon color to white
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 11,
//                               ),
//                               const Text(
//                                 "Call",
//                                 style: TextStyle(
//                                   color:
//                                       Colors.blue, // Changed text color to blue
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:typed_data';

// // import 'package:cccc/forms/mobility_aids.dart';
// // import 'package:cccc/global/database_services.dart';
// // import 'package:cccc/main.dart';
// // import 'package:cccc/pages/main_page.dart';
// // import 'package:cccc/pages/personal_details_page.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_database/firebase_database.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// // import 'package:flutter_geofire/flutter_geofire.dart';
// // import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// // import 'package:flutter_stripe/flutter_stripe.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:loading_animation_widget/loading_animation_widget.dart';
// // import 'package:provider/provider.dart';
// // // import 'package:restart_app/restart_app.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:cccc/authentication/login_screen.dart';
// // import 'package:cccc/global/global_var.dart';
// // import 'package:cccc/global/trip_var.dart';
// // import 'package:cccc/methods/common_methods.dart';
// // import 'package:cccc/methods/manage_drivers_method.dart';
// // import 'package:cccc/methods/push_notification_service.dart';
// // import 'package:cccc/models/direction_details.dart';
// // import 'package:cccc/models/online_nearby_drivers.dart';
// // import 'package:cccc/pages/about_page.dart';
// // import 'package:cccc/pages/search_destination_page.dart';
// // import 'package:cccc/pages/trip_history_page.dart';
// // import 'package:cccc/widgets/info_dialog.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:cccc/appinfo/appinfo.dart';
// // import 'package:cccc/widgets/loading_dialog.dart';

// // class Homepage extends StatefulWidget {
// //   const Homepage({super.key});

// //   @override
// //   State<Homepage> createState() => _HomepageState();
// // }

// // class _HomepageState extends State<Homepage> {
// //   final Completer<GoogleMapController> googleMapCompleterController =
// //       Completer<GoogleMapController>();
// //   GoogleMapController? controllerGoogleMap;
// //   Position? currentPositionOfUser;
// //   GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
// //   CommonMethods cMethods = CommonMethods();
// //   double searchContainerHeight = 276;
// //   double bottomMapPadding = 0;
// //   double rideDetailsContainerHeight = 0;
// //   double requestContainerHeight = 0;
// //   double tripContainerHeight = 0;
// //   // double paymentContainerHeight = 0;
// //   DirectionDetails? tripDirectionDetailsInfo;
// //   List<LatLng> polylineCoOrdinates = [];
// //   Set<Polyline> polylineSet = {};
// //   Set<Marker> markerSet = {};
// //   Set<Circle> circleSet = {};
// //   bool isDrawerOpened = true;
// //   String stateOfApp = "normal";
// //   bool nearbyOnlineDriversKeysLoaded = false;
// //   BitmapDescriptor? carIconNearbyDriver;
// //   DatabaseReference? tripRequestRef;
// //   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
// //   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
// //   bool requestingDirectionDetailsInfo = false;
// //   // bool hasDonated = false;

// //   makeDriverNearbyCarIcon() {
// //     if (carIconNearbyDriver == null) {
// //       ImageConfiguration configuration =
// //           createLocalImageConfiguration(context, size: Size(0.5, 0.5));
// //       BitmapDescriptor.fromAssetImage(
// //               configuration, "assets/images/tracking.png")
// //           .then((iconImage) {
// //         carIconNearbyDriver = iconImage;
// //       });
// //     }
// //   }

// //   void updateMapTheme(GoogleMapController controller) {
// //     getJsonFileFromThemes("themes/light_style.json")
// //         .then((value) => setGoogleMapStyle(value, controller));
// //   }

// //   Future<String> getJsonFileFromThemes(String mapStylePath) async {
// //     ByteData byteData = await rootBundle.load(mapStylePath);
// //     var list = byteData.buffer
// //         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
// //     return utf8.decode(list);
// //   }

// //   setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
// //     controller.setMapStyle(googleMapStyle);
// //   }

// //   getCurrentLiveLocationOfUser() async {
// //     Position positionOfUser = await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.bestForNavigation);
// //     currentPositionOfUser = positionOfUser;

// //     LatLng positionOfUserInLatLng = LatLng(
// //         currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

// //     CameraPosition cameraPosition =
// //         CameraPosition(target: positionOfUserInLatLng, zoom: 15);
// //     controllerGoogleMap!
// //         .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

// //     await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
// //         currentPositionOfUser!, context);

// //     await getUserInfoAndCheckBlockStatus();

// //     await initializeGeoFireListener();
// //   }

// //   getUserInfoAndCheckBlockStatus() async {
// //     DatabaseReference usersRef = FirebaseDatabase.instance
// //         .ref()
// //         .child("users")
// //         .child(FirebaseAuth.instance.currentUser!.uid);

// //     await usersRef.once().then((snap) {
// //       if (snap.snapshot.value != null) {
// //         if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
// //           setState(() {
// //             userName = (snap.snapshot.value as Map)["name"];
// //             userPhone = (snap.snapshot.value as Map)["phone"];
// //           });
// //         } else {
// //           FirebaseAuth.instance.signOut();

// //           Navigator.push(
// //               context, MaterialPageRoute(builder: (c) => LoginScreen()));

// //           cMethods.displaySnackbar(
// //               "you are blocked. Contact admin: alizeb875@gmail.com", context);
// //         }
// //       } else {
// //         FirebaseAuth.instance.signOut();
// //         Navigator.push(
// //             context, MaterialPageRoute(builder: (c) => LoginScreen()));
// //       }
// //     });
// //   }

// //   displayUserRideDetailsContainer() async {
// //     ///Directions API
// //     await retrieveDirectionDetails();

// //     setState(() {
// //       searchContainerHeight = 0;
// //       bottomMapPadding = 240;
// //       rideDetailsContainerHeight = 180;
// //       isDrawerOpened = false;
// //     });
// //   }

// //   // displayPaymentDetailsContainer() async {
// //   //   setState(() {
// //   //     searchContainerHeight = 0;
// //   //     bottomMapPadding = 240;
// //   //     rideDetailsContainerHeight = 0;
// //   //     isDrawerOpened = false;
// //   //   });

// //   //   await initPaymentSheet();
// //   //   await presentPaymentSheet();

// //   //   ///Directions API
// //   // }

// //   retrieveDirectionDetails() async {
// //     var pickUpLocation =
// //         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
// //     var dropOffDestinationLocation =
// //         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

// //     var pickupGeoGraphicCoOrdinates = LatLng(
// //         pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
// //     var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
// //         dropOffDestinationLocation!.latitudePositon!,
// //         dropOffDestinationLocation.longitudePosition!);

// //     showDialog(
// //       barrierDismissible: false,
// //       context: context,
// //       builder: (BuildContext context) =>
// //           LoadingDialog(messageText: "Getting direction..."),
// //     );

// //     ///Directions API
// //     var detailsFromDirectionAPI =
// //         await CommonMethods.getDirectionDetailsFromAPI(
// //             pickupGeoGraphicCoOrdinates,
// //             dropOffDestinationGeoGraphicCoOrdinates);
// //     setState(() {
// //       tripDirectionDetailsInfo = detailsFromDirectionAPI;
// //     });

// //     Navigator.pop(context);

// //     //draw route from pickup to dropOffDestination
// //     PolylinePoints pointsPolyline = PolylinePoints();
// //     List<PointLatLng> latLngPointsFromPickUpToDestination =
// //         pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

// //     polylineCoOrdinates.clear();
// //     if (latLngPointsFromPickUpToDestination.isNotEmpty) {
// //       latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
// //         polylineCoOrdinates
// //             .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
// //       });
// //     }

// //     polylineSet.clear();
// //     setState(() {
// //       Polyline polyline = Polyline(
// //         polylineId: const PolylineId("polylineID"),
// //         color: Colors.pink,
// //         points: polylineCoOrdinates,
// //         jointType: JointType.round,
// //         width: 4,
// //         startCap: Cap.roundCap,
// //         endCap: Cap.roundCap,
// //         geodesic: true,
// //       );

// //       polylineSet.add(polyline);
// //     });

// //     //fit the polyline into the map
// //     LatLngBounds boundsLatLng;
// //     if (pickupGeoGraphicCoOrdinates.latitude >
// //             dropOffDestinationGeoGraphicCoOrdinates.latitude &&
// //         pickupGeoGraphicCoOrdinates.longitude >
// //             dropOffDestinationGeoGraphicCoOrdinates.longitude) {
// //       boundsLatLng = LatLngBounds(
// //         southwest: dropOffDestinationGeoGraphicCoOrdinates,
// //         northeast: pickupGeoGraphicCoOrdinates,
// //       );
// //     } else if (pickupGeoGraphicCoOrdinates.longitude >
// //         dropOffDestinationGeoGraphicCoOrdinates.longitude) {
// //       boundsLatLng = LatLngBounds(
// //         southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude,
// //             dropOffDestinationGeoGraphicCoOrdinates.longitude),
// //         northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
// //             pickupGeoGraphicCoOrdinates.longitude),
// //       );
// //     } else if (pickupGeoGraphicCoOrdinates.latitude >
// //         dropOffDestinationGeoGraphicCoOrdinates.latitude) {
// //       boundsLatLng = LatLngBounds(
// //         southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
// //             pickupGeoGraphicCoOrdinates.longitude),
// //         northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude,
// //             dropOffDestinationGeoGraphicCoOrdinates.longitude),
// //       );
// //     } else {
// //       boundsLatLng = LatLngBounds(
// //         southwest: pickupGeoGraphicCoOrdinates,
// //         northeast: dropOffDestinationGeoGraphicCoOrdinates,
// //       );
// //     }

// //     controllerGoogleMap!
// //         .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

// //     //add markers to pickup and dropOffDestination points
// //     Marker pickUpPointMarker = Marker(
// //       markerId: const MarkerId("pickUpPointMarkerID"),
// //       position: pickupGeoGraphicCoOrdinates,
// //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
// //       infoWindow: InfoWindow(
// //           title: pickUpLocation.placeName, snippet: "Pickup Location"),
// //     );

// //     Marker dropOffDestinationPointMarker = Marker(
// //       markerId: const MarkerId("dropOffDestinationPointMarkerID"),
// //       position: dropOffDestinationGeoGraphicCoOrdinates,
// //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
// //       infoWindow: InfoWindow(
// //           title: dropOffDestinationLocation.placeName,
// //           snippet: "Destination Location"),
// //     );

// //     setState(() {
// //       markerSet.add(pickUpPointMarker);
// //       markerSet.add(dropOffDestinationPointMarker);
// //     });

// //     //add circles to pickup and dropOffDestination points
// //     Circle pickUpPointCircle = Circle(
// //       circleId: const CircleId('pickupCircleID'),
// //       strokeColor: Colors.blue,
// //       strokeWidth: 4,
// //       radius: 14,
// //       center: pickupGeoGraphicCoOrdinates,
// //       fillColor: Colors.pink,
// //     );

// //     Circle dropOffDestinationPointCircle = Circle(
// //       circleId: const CircleId('dropOffDestinationCircleID'),
// //       strokeColor: Colors.blue,
// //       strokeWidth: 4,
// //       radius: 14,
// //       center: dropOffDestinationGeoGraphicCoOrdinates,
// //       fillColor: Colors.pink,
// //     );

// //     setState(() {
// //       circleSet.add(pickUpPointCircle);
// //       circleSet.add(dropOffDestinationPointCircle);
// //     });
// //   }

// //   resetAppNow() {
// //     setState(() {
// //       polylineCoOrdinates.clear();
// //       polylineSet.clear();
// //       markerSet.clear();
// //       circleSet.clear();
// //       rideDetailsContainerHeight = 0;
// //       // paymentContainerHeight = 0;
// //       requestContainerHeight = 0;
// //       tripContainerHeight = 0;
// //       searchContainerHeight = 276;
// //       bottomMapPadding = 300;
// //       isDrawerOpened = true;

// //       status = "";
// //       nameDriver = "";
// //       photoDriver = "";
// //       phoneNumberDriver = "";
// //       carDetialsDriver = "";
// //       tripStatusDisplay = 'Driver is Arriving';
// //       print("resetAppNow");
// //     });
// //   }

// //   cancelRideRequest() {
// //     //remove ride request from database
// //    _tripRequestRef.deleteData("tripRequests");
// //     print("cancelRideRequest");

// //     setState(() {
// //       stateOfApp = "normal";
// //     });
// //   }

// //   Future<Map<String, dynamic>> createPaymentIntent({
// //     required String amount,
// //     required String currency,
// //   }) async {
// //     final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
// //     final secretKey = dotenv.env["STRIPE_SECRET_KEY"]!;
// //     final body = {
// //       'amount': amount,
// //       'currency': currency,
// //       'automatic_payment_methods[enabled]': 'true',
// //       'description': "Test Payment",
// //     };

// //     final response = await http.post(
// //       url,
// //       headers: {
// //         "Authorization": "Bearer $secretKey",
// //         'Content-Type': 'application/x-www-form-urlencoded',
// //       },
// //       body: body,
// //     );

// //     if (response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('Failed to create payment intent');
// //     }
// //   }

// //   Future<void> initPaymentSheet() async {
// //     try {
// //       // Replace with your API call to create a Payment Intent
// //       final data = await createPaymentIntent(
// //         amount: '1000', // Example amount in the smallest currency unit
// //         currency: 'USD',
// //       );

// //       // Initialize the payment sheet
// //       await Stripe.instance.initPaymentSheet(
// //         paymentSheetParameters: SetupPaymentSheetParameters(
// //           // Set to true for custom flow
// //           customFlow: false,
// //           // Main params
// //           merchantDisplayName: 'Test Merchant',
// //           paymentIntentClientSecret: data['client_secret'],
// //           customerEphemeralKeySecret: data['ephemeralKey'],
// //           customerId: data['id'],
// //           style: ThemeMode.dark,
// //         ),
// //       );
// //     } catch (e) {
// //       scaffoldMessengerKey.currentState?.showSnackBar(
// //         SnackBar(content: Text('Error: $e')),
// //       );
// //       rethrow;
// //     }
// //   }

// //   Future<void> presentPaymentSheet() async {
// //     try {
// //       await Stripe.instance.presentPaymentSheet();
// //       scaffoldMessengerKey.currentState?.showSnackBar(
// //         SnackBar(
// //           content: Text('Payment Successful'),
// //           backgroundColor: Colors.green,
// //         ),
// //       );
// //       displayRequestContainer();
// //     } catch (e) {
// //       scaffoldMessengerKey.currentState?.showSnackBar(
// //         SnackBar(
// //           content: Text('Payment Failed: $e'),
// //           backgroundColor: Colors.redAccent,
// //         ),
// //       );
// //     }
// //   }

// //   displayRequestContainer() {
// //     print("displayingRequestContainer");
// //     setState(() {
// //       rideDetailsContainerHeight = 0;
// //       // paymentContainerHeight = 0;
// //       requestContainerHeight = 220;
// //       bottomMapPadding = 200;
// //       isDrawerOpened = true;
// //     });
// //     print("before makeTripRequest function execution");
// //     //send ride request
// //     makeTripRequest();
// //     print("after makeTripRequest function execution");
// //   }

// //   updateAvailableNearbyOnlineDriversOnMap() {
// //     setState(() {
// //       markerSet.clear();
// //     });

// //     Set<Marker> markersTempSet = Set<Marker>();

// //     for (OnlineNearbyDrivers eachOnlineNearbyDriver
// //         in ManageDriversMethod.nearbyOnlineDriversList) {
// //       LatLng driverCurrentPosition = LatLng(
// //           eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

// //       Marker driverMarker = Marker(
// //         markerId: MarkerId(
// //             "driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
// //         position: driverCurrentPosition,
// //         icon: carIconNearbyDriver!,
// //       );

// //       markersTempSet.add(driverMarker);
// //     }

// //     setState(() {
// //       markerSet = markersTempSet;
// //     });
// //   }

// //   initializeGeoFireListener() {
// //     Geofire.initialize("onlineDrivers");
// //     Geofire.queryAtLocation(currentPositionOfUser!.latitude,
// //             currentPositionOfUser!.longitude, 50)!
// //         .listen((driverEvent) {
// //       if (driverEvent != null) {
// //         var onlineDriverChild = driverEvent["callBack"];

// //         switch (onlineDriverChild) {
// //           case Geofire.onKeyEntered:
// //             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
// //             onlineNearbyDrivers.uidDriver = driverEvent["key"];
// //             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
// //             print(onlineNearbyDrivers.latDriver! + 2000);
// //             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
// //             print(onlineNearbyDrivers.lngDriver! + 2000);
// //             ManageDriversMethod.nearbyOnlineDriversList
// //                 .add(onlineNearbyDrivers);

// //             if (nearbyOnlineDriversKeysLoaded == true) {
// //               //update drivers on google map
// //               updateAvailableNearbyOnlineDriversOnMap();
// //             }

// //             break;

// //           case Geofire.onKeyExited:
// //             print("driver exited");
// //             ManageDriversMethod.removeDriverFromList(driverEvent["key"]);

// //             //update drivers on google map
// //             updateAvailableNearbyOnlineDriversOnMap();

// //             break;

// //           case Geofire.onKeyMoved:
// //             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
// //             onlineNearbyDrivers.uidDriver = driverEvent["key"];
// //             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
// //             print(onlineNearbyDrivers.latDriver! + 4000);
// //             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
// //             print(onlineNearbyDrivers.lngDriver! + 4000);
// //             ManageDriversMethod.updateOnlineNearbyDriversLocation(
// //                 onlineNearbyDrivers);

// //             //update drivers on google map
// //             updateAvailableNearbyOnlineDriversOnMap();

// //             break;

// //           case Geofire.onGeoQueryReady:
// //             nearbyOnlineDriversKeysLoaded = true;

// //             //update drivers on google map
// //             updateAvailableNearbyOnlineDriversOnMap();

// //             break;
// //         }
// //       }
// //     });
// //   }
// //   final DatabaseService _tripRequestRef = DatabaseService();


// //   void makeTripRequest() {
// //   final user = FirebaseAuth.instance.currentUser;

// //   var pickUpLocation =
// //       Provider.of<Appinfo>(context, listen: false).pickUpLocation;
// //   var dropOffDestinationLocation =
// //       Provider.of<Appinfo>(context, listen: false).dropOffLocation;

// //   if (pickUpLocation == null || dropOffDestinationLocation == null || user == null) {
// //     // Handle the error case where location or user data is null
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Please ensure all necessary information is provided.')),
// //     );
// //     return;
// //   }

// //   Map pickUpCoOrdinatesMap = {
// //     "latitude": pickUpLocation.latitudePositon.toString(),
// //     "longitude": pickUpLocation.longitudePosition.toString(),
// //   };

// //   Map dropOffDestinationCoOrdinatesMap = {
// //     "latitude": dropOffDestinationLocation.latitudePositon.toString(),
// //     "longitude": dropOffDestinationLocation.longitudePosition.toString(),
// //   };

// //   Map driverCoOrdinates = {
// //     "latitude": "",
// //     "longitude": "",
// //   };

// //   Map dataMap = {
// //     "tripID": _tripRequestRef.dbRef.push().key,
// //     "publishDateTime": DateTime.now().toString(),
// //     "userName": user.displayName ?? "Anonymous",
// //     "userPhone": user.phoneNumber ?? "Unknown",
// //     "userID": user.uid,
// //     "pickUpLatLng": pickUpCoOrdinatesMap,
// //     "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
// //     "pickUpAddress": pickUpLocation.placeName,
// //     "dropOffAddress": dropOffDestinationLocation.placeName,
// //     "driverID": "waiting",
// //     "carDetails": "",
// //     "driverLocation": driverCoOrdinates,
// //     "driverName": "",
// //     "driverPhone": "",
// //     "driverPhoto": "",
// //     "fareAmount": "",
// //     "status": "new",
// //   };


// //   _tripRequestRef.writeData("tripRequests/${dataMap['tripID']}", dataMap.cast<String,dynamic >());

// //   tripStreamSubscription = _tripRequestRef.dbRef
// //       .child("tripRequests/${dataMap['tripID']}")
// //       .onValue
// //       .listen((eventSnapshot) async {
// //     if (eventSnapshot.snapshot.value == null) {
// //       return;
// //     }

// //     Map<String, dynamic> eventData = Map<String, dynamic>.from(eventSnapshot.snapshot.value as Map);

// //     if (eventData["driverName"] != null) {
// //       nameDriver = eventData["driverName"];
// //     }

// //     if (eventData["driverPhone"] != null) {
// //       phoneNumberDriver = eventData["driverPhone"];
// //     }

// //     if (eventData["driverPhoto"] != null) {
// //       photoDriver = eventData["driverPhoto"];
// //     }

// //     if (eventData["carDetails"] != null) {
// //       carDetialsDriver = eventData["carDetails"];
// //     }

// //     if (eventData["status"] != null) {
// //       status = eventData["status"];
// //     }

// //     if (eventData["driverLocation"] != null) {
// //       try {
// //         double driverLatitude = double.parse(eventData["driverLocation"]["latitude"].toString());
// //         double driverLongitude = double.parse(eventData["driverLocation"]["longitude"].toString());
// //         LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

// //         if (status == "accepted") {
// //           // Update info for pickup to user on UI
// //           // Info from driver current location to user pickup location
// //           updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
// //         } else if (status == "arrived") {
// //           // Update info for arrived - when driver reaches the pickup point of user
// //           setState(() {
// //             tripStatusDisplay = 'Driver has Arrived';
// //           });
// //         } else if (status == "ontrip") {
// //           // Update info for dropoff to user on UI
// //           // Info from driver current location to user dropoff location
// //           updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
// //         }
// //       } catch (e) {
// //         print("Error: $e");
// //       }
// //     }

// //     if (status == "accepted") {
// //       displayTripDetailsContainer();

// //       Geofire.stopListener();

// //       // Remove drivers markers
// //       setState(() {
// //         markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
// //       });
// //     }

// //     if (status == "ended") {
// //       _tripRequestRef.dbRef.child("tripRequests/${dataMap['tripID']}").onDisconnect();
// //       tripStreamSubscription!.cancel();
// //       tripStreamSubscription = null;

// //       resetAppNow();

// //       Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (BuildContext context) => Homepage()));
// //     }
// //   });
// // }


// //   displayTripDetailsContainer() {
// //     setState(() {
// //       requestContainerHeight = 0;
// //       tripContainerHeight = 291;
// //       bottomMapPadding = 281;
// //     });
// //   }

// //   updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
// //     if (!requestingDirectionDetailsInfo) {
// //       requestingDirectionDetailsInfo = true;

// //       var userPickUpLocationLatLng = LatLng(
// //           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

// //       var directionDetailsPickup =
// //           await CommonMethods.getDirectionDetailsFromAPI(
// //               driverCurrentLocationLatLng, userPickUpLocationLatLng);

// //       if (directionDetailsPickup == null) {
// //         return;
// //       }

// //       setState(() {
// //         tripStatusDisplay =
// //             "Driver is Coming - ${directionDetailsPickup.durationTextString}";
// //       });

// //       requestingDirectionDetailsInfo = false;
// //     }
// //   }

// //   updateFromDriverCurrentLocationToDropOffDestination(
// //       driverCurrentLocationLatLng) async {
// //     if (!requestingDirectionDetailsInfo) {
// //       requestingDirectionDetailsInfo = true;

// //       var dropOffLocation =
// //           Provider.of<Appinfo>(context, listen: false).dropOffLocation;
// //       var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePositon!,
// //           dropOffLocation.longitudePosition!);

// //       var directionDetailsPickup =
// //           await CommonMethods.getDirectionDetailsFromAPI(
// //               driverCurrentLocationLatLng, userDropOffLocationLatLng);

// //       if (directionDetailsPickup == null) {
// //         return;
// //       }

// //       setState(() {
// //         tripStatusDisplay =
// //             "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
// //       });

// //       requestingDirectionDetailsInfo = false;
// //     }
// //   }

// //   noDriverAvailable() {
// //     showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (BuildContext context) => InfoDialog(
// //               title: "No Driver Available",
// //               description:
// //                   "No driver found in the nearby location. Please try again shortly.",
// //             ));
// //     print("NoDriverAvailable");
// //   }

// //   searchDriver() {
// //     if (availableNearbyOnlineDriversList!.length == 0) {
// //       print(availableNearbyOnlineDriversList!.length);
// //       print("length of available driver 0");
// //       cancelRideRequest();
// //       resetAppNow();
// //       noDriverAvailable();
// //       print("SearchDriverEnded");
// //       return;
// //     }

// //     var currentDriver = availableNearbyOnlineDriversList![0];
// //     print("driver is found");

// //     //send notification to this currentDriver - currentDriver means selected driver
// //     sendNotificationToDriver(currentDriver);
// //     print("sendNotification1");

// //     availableNearbyOnlineDriversList!.removeAt(0);
// //   }

// //   sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
// //     if (tripDirectionDetailsInfo != null) {
// //       //update driver's newTripStatus - assign tripID to current driver
// //       DatabaseReference currentDriverRef = FirebaseDatabase.instance
// //           .ref()
// //           .child("drivers")
// //           .child(currentDriver.uidDriver.toString())
// //           .child("newTripStatus");

// //       // print(_tripRequestRef);
// //       print("newTripStatus assigned");

// //       currentDriverRef.set(_tripRequestRef.dbRef.push().key);
// //       print("tripRequestRef formed");

// //       //get current driver device recognition token
// //       DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
// //           .ref()
// //           .child("drivers")
// //           .child(currentDriver.uidDriver.toString())
// //           .child("deviceToken");
// //       print(tokenOfCurrentDriverRef);

// //       tokenOfCurrentDriverRef.once().then((dataSnapshot) {
// //         if (dataSnapshot.snapshot.value != null) {
// //           String deviceToken = dataSnapshot.snapshot.value.toString();
// //           print("Device Token: $deviceToken");

// //           //send notification
// //           PushNotificationService.sendNotificationToSelectedDriver(
// //               deviceToken, context, _tripRequestRef.dbRef.push().key.toString());
// //           print("sendNotification2");
// //         } else {
// //           print("no token found");
// //           return;
// //         }

// //         const oneTickPerSec = Duration(seconds: 1);

// //         Timer.periodic(oneTickPerSec, (timer) {
// //           requestTimeoutDriver = requestTimeoutDriver - 1;

// //           //when trip request is not requesting means trip request cancelled - stop timer
// //           if (stateOfApp != "requesting") {
// //             timer.cancel();
// //             currentDriverRef.set("cancelled");
// //             currentDriverRef.onDisconnect();
// //             requestTimeoutDriver = 20;
// //             print("sendNotification3");
// //           }

// //           //when trip request is accepted by online nearest available driver
// //           currentDriverRef.onValue.listen((dataSnapshot) {
// //             if (dataSnapshot.snapshot.value.toString() == "accepted") {
// //               timer.cancel();
// //               currentDriverRef.onDisconnect();
// //               requestTimeoutDriver = 20;
// //               print("sendNotification4");
// //             }
// //           });

// //           //if 20 seconds passed - send notification to next nearest online available driver
// //           if (requestTimeoutDriver == 0) {
// //             currentDriverRef.set("timeout");
// //             timer.cancel();
// //             currentDriverRef.onDisconnect();
// //             requestTimeoutDriver = 20;
// //             print("sendNotification5");

// //             //send notification to next nearest online available driver
// //             searchDriver();
// //             print("searchDriver2");
// //           }
// //         });
// //       });
// //     } else {
// //       print("tripDirectionDetailsInfo is null");
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     makeDriverNearbyCarIcon();

// //     return Scaffold(
// //       key: sKey,
// //       drawer: Container(
// //         width: 255,
// //         color: Colors.white,
// //         child: Drawer(
// //           backgroundColor: Colors.white,
// //           child: ListView(
// //             children: [
// //               const Divider(
// //                 height: 1,
// //                 color: Colors.black,
// //                 thickness: 1,
// //               ),

// //               //header
// //               Container(
// //                 color: Colors.white,
// //                 height: 160,
// //                 child: DrawerHeader(
// //                   decoration: const BoxDecoration(
// //                     color: Colors.white,
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Image.asset(
// //                         "assets/images/avatarman.png",
// //                         width: 60,
// //                         height: 60,
// //                       ),
// //                       const SizedBox(
// //                         width: 16,
// //                       ),
// //                       Column(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children: [
// //                           Text(
// //                             userName,
// //                             style: const TextStyle(
// //                               fontSize: 16,
// //                               color: Colors.black,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                           const SizedBox(
// //                             height: 4,
// //                           ),
// //                           const Text(
// //                             "Profile",
// //                             style: TextStyle(
// //                               color: Colors.blue,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),

// //               const Divider(
// //                 height: 1,
// //                 color: Colors.black,
// //                 thickness: 1,
// //               ),

// //               const SizedBox(
// //                 height: 10,
// //               ),

// //               //body
// //               GestureDetector(
// //                 onTap: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                         builder: (context) => PersonalDetailsDisplayPage()),
// //                   );
// //                 },
// //                 child: ListTile(
// //                   leading: IconButton(
// //                     onPressed: () {
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                             builder: (context) => PersonalDetailsDisplayPage()),
// //                       );
// //                     },
// //                     icon: const Icon(
// //                       Icons.person,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   title: const Text(
// //                     "Personal details",
// //                     style: TextStyle(color: Colors.black),
// //                   ),
// //                 ),
// //               ),

// //               GestureDetector(
// //                 onTap: () {
// //                   Navigator.push(context,
// //                       MaterialPageRoute(builder: (c) => TripsHistoryPage()));
// //                 },
// //                 child: ListTile(
// //                   leading: IconButton(
// //                     onPressed: () {},
// //                     icon: const Icon(
// //                       Icons.history,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   title: const Text(
// //                     "History",
// //                     style: TextStyle(color: Colors.black),
// //                   ),
// //                 ),
// //               ),

// //               GestureDetector(
// //                 onTap: () {
// //                   Navigator.push(
// //                       context, MaterialPageRoute(builder: (c) => AboutPage()));
// //                 },
// //                 child: ListTile(
// //                   leading: IconButton(
// //                     onPressed: () {},
// //                     icon: const Icon(
// //                       Icons.info,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   title: const Text(
// //                     "About",
// //                     style: TextStyle(color: Colors.black),
// //                   ),
// //                 ),
// //               ),

// //               GestureDetector(
// //                 onTap: () {
// //                   FirebaseAuth.instance.signOut();

// //                   Navigator.push(context,
// //                       MaterialPageRoute(builder: (c) => LoginScreen()));
// //                 },
// //                 child: ListTile(
// //                   leading: IconButton(
// //                     onPressed: () {},
// //                     icon: const Icon(
// //                       Icons.logout,
// //                       color: Colors.black,
// //                     ),
// //                   ),
// //                   title: const Text(
// //                     "Logout",
// //                     style: TextStyle(color: Colors.black),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //       body: Stack(
// //         children: [
// //           ///google map
// //           GoogleMap(
// //             padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
// //             mapType: MapType.normal,
// //             myLocationEnabled: true,
// //             polylines: polylineSet,
// //             markers: markerSet,
// //             circles: circleSet,
// //             initialCameraPosition: googlePlexInitialPositon,
// //             onMapCreated: (GoogleMapController mapController) {
// //               controllerGoogleMap = mapController;
// //               updateMapTheme(controllerGoogleMap!);

// //               googleMapCompleterController.complete(controllerGoogleMap);

// //               setState(() {
// //                 bottomMapPadding = 300;
// //               });

// //               getCurrentLiveLocationOfUser();
// //             },
// //           ),

// //           ///drawer button
// //           Positioned(
// //             top: 36,
// //             left: 19,
// //             child: GestureDetector(
// //               onTap: () {
// //                 if (isDrawerOpened == true) {
// //                   sKey.currentState!.openDrawer();
// //                 } else {
// //                   resetAppNow();
// //                 }
// //               },
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(20),
// //                   boxShadow: const [
// //                     BoxShadow(
// //                       color: Colors.black26,
// //                       blurRadius: 5,
// //                       spreadRadius: 0.5,
// //                       offset: Offset(0.7, 0.7),
// //                     ),
// //                   ],
// //                 ),
// //                 child: CircleAvatar(
// //                   backgroundColor: Colors.white,
// //                   radius: 20,
// //                   child: Icon(
// //                     isDrawerOpened == true ? Icons.menu : Icons.close,
// //                     color: Colors.black87,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),

// //           /// payment details

// //           ///search location icon button
// //           Positioned(
// //             left: 0,
// //             right: 0,
// //             bottom: -80,
// //             child: Container(
// //               height: searchContainerHeight,
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                 children: [
// //                   ElevatedButton(
// //                     onPressed: () async {
// //                       var responseFromSearchPage = await Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                               builder: (c) => SearchDestinationPage()));

// //                       if (responseFromSearchPage == "placeSelected") {
// //                         displayUserRideDetailsContainer();
// //                       }
// //                     },
// //                     style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.white,
// //                         shape: const CircleBorder(),
// //                         padding: const EdgeInsets.all(24)),
// //                     child: const Icon(
// //                       Icons.search,
// //                       color: Colors.black,
// //                       size: 25,
// //                     ),
// //                   ),
// //                   ElevatedButton(
// //                     onPressed: () {
// //                       Navigator.push(context,
// //                           MaterialPageRoute(builder: (c) => MainPage()));
// //                     },
// //                     style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.white,
// //                         shape: const CircleBorder(),
// //                         padding: const EdgeInsets.all(24)),
// //                     child: const Icon(
// //                       Icons.home,
// //                       color: Colors.black,
// //                       size: 25,
// //                     ),
// //                   ),
// //                   ElevatedButton(
// //                     onPressed: () {},
// //                     style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.white,
// //                         shape: const CircleBorder(),
// //                         padding: const EdgeInsets.all(24)),
// //                     child: const Icon(
// //                       Icons.work,
// //                       color: Colors.black,
// //                       size: 25,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           ///ride details container
// //           Positioned(
// //             left: 0,
// //             right: 0,
// //             bottom: 0,
// //             child: Container(
// //               height: rideDetailsContainerHeight,
// //               decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.only(
// //                       topLeft: Radius.circular(15),
// //                       topRight: Radius.circular(15)),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black45,
// //                       blurRadius: 5,
// //                       spreadRadius: 0.5,
// //                       offset: Offset(0.7, 0.7),
// //                     ),
// //                   ]),
// //               child: Padding(
// //                 padding: EdgeInsets.symmetric(vertical: 18),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Padding(
// //                       padding: EdgeInsets.only(left: 16, right: 16),
// //                       child: Padding(
// //                         padding: EdgeInsets.only(top: 8, bottom: 8),
// //                         child: Column(
// //                           children: [
// //                             Row(
// //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                               children: [
// //                                 RichText(
// //                                   text: TextSpan(
// //                                     children: [
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? "Distance: "
// //                                             : "Distance: ",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .black, // Color for non-number part
// //                                         ),
// //                                       ),
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? "${tripDirectionDetailsInfo!.distanceTextString!}"
// //                                             : "0 km",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .blue, // Color for number part
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                                 RichText(
// //                                   text: TextSpan(
// //                                     children: [
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? "Time: "
// //                                             : "Time: ",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .black, // Color for non-number part
// //                                         ),
// //                                       ),
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
// //                                             : "0 \$",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .blue, // Color for number part
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                             Row(
// //                               mainAxisAlignment: MainAxisAlignment
// //                                   .spaceBetween, // Distribute space evenly between children
// //                               crossAxisAlignment: CrossAxisAlignment
// //                                   .center, // Center children vertically
// //                               children: [
// //                                 GestureDetector(
// //                                   onTap: () async {
// //                                     setState(() {
// //                                       stateOfApp = "requesting";
// //                                     });

// //                                     await Navigator.push(
// //                                       context,
// //                                       MaterialPageRoute(
// //                                         builder: (context) => MobilityAidsPage(
// //                                           onFormSubmitted: () async {
// //                                             // Continue the remaining code after form submission
// //                                             // displayRequestContainer();
// //                                             await initPaymentSheet();
// //                                             await presentPaymentSheet();
// //                                             availableNearbyOnlineDriversList =
// //                                                 ManageDriversMethod
// //                                                     .nearbyOnlineDriversList;
// //                                             print(
// //                                                 availableNearbyOnlineDriversList);
// //                                             print("ManageDriversMethod1");

// //                                             // Search for a driver
// //                                             searchDriver();
// //                                             print(searchDriver);
// //                                           }
// //                                         ),
// //                                       ),
// //                                     );
// //                                   },
// //                                   child: Image.asset(
// //                                     "assets/images/uberexec.png",
// //                                     height: 100,
// //                                     width: 100,
// //                                   ),
// //                                 ),
// //                                 RichText(
// //                                   text: TextSpan(
// //                                     children: [
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? "${tripDirectionDetailsInfo!.durationTextString!}"
// //                                             : "0",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .blue, // Blue color for numeric part
// //                                         ),
// //                                       ),
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? " away"
// //                                             : " away",
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .black, // Black color for the rest of the text
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                                 RichText(
// //                                   text: TextSpan(
// //                                     children: [
// //                                       TextSpan(
// //                                         text: (tripDirectionDetailsInfo != null)
// //                                             ? " \$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
// //                                             : '',
// //                                         style: const TextStyle(
// //                                           fontSize: 14,
// //                                           fontWeight: FontWeight.bold,
// //                                           color: Colors
// //                                               .blue, // Blue color for numeric part
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   ),
// //                                 ),
// //                               ],
// //                             )
// //                           ],
// //                         ),
// //                       ),
// //                     )
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),

// //           ///request container
// //           Positioned(
// //             left: 0,
// //             right: 0,
// //             bottom: 0,
// //             child: Container(
// //               height: requestContainerHeight,
// //               decoration: const BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.only(
// //                     topLeft: Radius.circular(16),
// //                     topRight: Radius.circular(16)),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.white30,
// //                     blurRadius: 15.0,
// //                     spreadRadius: 0.5,
// //                     offset: Offset(
// //                       0.7,
// //                       0.7,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               child: Padding(
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.center,
// //                   children: [
// //                     const SizedBox(
// //                       height: 12,
// //                     ),
// //                     SizedBox(
// //                       width: 200,
// //                       child: LoadingAnimationWidget.flickr(
// //                         leftDotColor: Colors.greenAccent,
// //                         rightDotColor: Colors.pinkAccent,
// //                         size: 50,
// //                       ),
// //                     ),
// //                     const SizedBox(
// //                       height: 20,
// //                     ),
// //                     GestureDetector(
// //                       onTap: () {
// //                         resetAppNow();
// //                         cancelRideRequest();
// //                       },
// //                       child: Container(
// //                         height: 50,
// //                         width: 50,
// //                         decoration: BoxDecoration(
// //                           color: Colors.white70,
// //                           borderRadius: BorderRadius.circular(25),
// //                           border: Border.all(width: 1.5, color: Colors.grey),
// //                         ),
// //                         child: const Icon(
// //                           Icons.close,
// //                           color: Colors.black,
// //                           size: 25,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),

// //           ///trip details container
// //           Positioned(
// //             left: 0,
// //             right: 0,
// //             bottom: 0,
// //             child: Container(
// //               height: tripContainerHeight,
// //               decoration: const BoxDecoration(
// //                 color: Colors.white, // Changed to white background
// //                 borderRadius: BorderRadius.only(
// //                   topLeft: Radius.circular(16),
// //                   topRight: Radius.circular(16),
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.black12, // Changed to a lighter shadow
// //                     blurRadius: 15.0,
// //                     spreadRadius: 0.5,
// //                     offset: Offset(
// //                       0.7,
// //                       0.7,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               child: Padding(
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const SizedBox(
// //                       height: 5,
// //                     ),

// //                     // Trip status display text
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Text(
// //                           tripStatusDisplay,
// //                           style: const TextStyle(
// //                             fontSize: 19,
// //                             color: Colors.black, // Changed text color to black
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     const SizedBox(
// //                       height: 19,
// //                     ),

// //                     const Divider(
// //                       height: 1,
// //                       color: Colors
// //                           .black12, // Changed divider color to match new theme
// //                       thickness: 1,
// //                     ),

// //                     const SizedBox(
// //                       height: 19,
// //                     ),

// //                     // Image - driver name and driver car details
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       crossAxisAlignment: CrossAxisAlignment.center,
// //                       children: [
// //                         ClipOval(
// //                           child: Image.network(
// //                             photoDriver.isEmpty
// //                                 ? "https://firebasestorage.googleapis.com/v0/b/cccc-4b8a5.appspot.com/o/avatarman.png?alt=media&token=3d161402-7f8c-4de1-a9ad-96b97a41cc4c"
// //                                 : photoDriver,
// //                             width: 60,
// //                             height: 60,
// //                             fit: BoxFit.cover,
// //                           ),
// //                         ),
// //                         const SizedBox(
// //                           width: 8,
// //                         ),
// //                         Column(
// //                           mainAxisAlignment: MainAxisAlignment.start,
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Text(
// //                               nameDriver,
// //                               style: const TextStyle(
// //                                 fontSize: 20,
// //                                 color:
// //                                     Colors.black, // Changed text color to black
// //                               ),
// //                             ),
// //                             Text(
// //                               carDetialsDriver,
// //                               style: const TextStyle(
// //                                 fontSize: 14,
// //                                 color: Colors
// //                                     .blue, // Slightly lighter black for car details
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),

// //                     const SizedBox(
// //                       height: 19,
// //                     ),

// //                     const Divider(
// //                       height: 1,
// //                       color: Colors
// //                           .black12, // Changed divider color to match new theme
// //                       thickness: 1,
// //                     ),

// //                     const SizedBox(
// //                       height: 19,
// //                     ),

// //                     // Call driver button
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         GestureDetector(
// //                           onTap: () {
// //                             launchUrl(Uri.parse("tel://$phoneNumberDriver"));
// //                           },
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.center,
// //                             children: [
// //                               Container(
// //                                 height: 50,
// //                                 width: 50,
// //                                 decoration: BoxDecoration(
// //                                   borderRadius: const BorderRadius.all(
// //                                       Radius.circular(25)),
// //                                   color: Colors
// //                                       .blue, // Changed button background color to blue
// //                                   border: Border.all(
// //                                     width: 1,
// //                                     color: Colors
// //                                         .blue, // Changed button border color to blue
// //                                   ),
// //                                 ),
// //                                 child: const Icon(
// //                                   Icons.phone,
// //                                   color: Colors
// //                                       .white, // Changed icon color to white
// //                                 ),
// //                               ),
// //                               const SizedBox(
// //                                 height: 11,
// //                               ),
// //                               const Text(
// //                                 "Call",
// //                                 style: TextStyle(
// //                                   color:
// //                                       Colors.blue, // Changed text color to blue
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           )
// //         ],
// //       ),
// //     );
// //   }
// // }

