// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:cccc/global/trip_var.dart';
// import 'package:cccc/methods/push_notification_service.dart';
// import 'package:cccc/pages/homepage.dart';
// import 'package:cccc/widgets/loading_dialog.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cccc/global/global_var.dart';
// import 'package:cccc/methods/common_methods.dart';
// import 'package:cccc/models/direction_details.dart';
// import 'package:cccc/models/online_nearby_drivers.dart';
// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:url_launcher/url_launcher.dart';

// class TripStatusPage extends StatefulWidget {
//   final String? tripRequestKey;

//   const TripStatusPage({Key? key, required this.tripRequestKey})
//       : super(key: key);

//   @override
//   _TripStatusPageState createState() => _TripStatusPageState();
// }

// class _TripStatusPageState extends State<TripStatusPage> {
//   final Completer<GoogleMapController> googleMapCompleterController =
//       Completer<GoogleMapController>();
//   GoogleMapController? controllerGoogleMap;
//   Position? currentPositionOfUser;
//   DirectionDetails? tripDirectionDetailsInfo;
//   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
//   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList = [];
//   PolylinePoints pointsPolyline = PolylinePoints();
//   bool requestingDirectionDetailsInfo = false;
//   double rideDetailsContainerHeight = 0;
//   double requestContainerHeight = 0;
//   double tripContainerHeight = 0;
//   double bottomMapPadding = 0;
//   List<LatLng> polylineCoOrdinates = [];
//   Set<Polyline> polylineSet = {};
//   Set<Marker> markerSet = {};
//   Set<Circle> circleSet = {};

//   @override
//   void initState() {
//     super.initState();
//     print("entered into TripStatusPage");
//     restoreStateAfterRestart();
//     startTripStreamSubscription();
//   }

//   @override
//   void dispose() {
//     tripStreamSubscription?.cancel();
//     // controllerGoogleMap?.dispose();
//     super.dispose();
//   }

//   getCurrentLiveLocationOfUser() async {
//     // if (boolgetCurrentLiveLocationOfUser) return;
//     print("entered into getCurrentLiveLocationOfUser");
//     try {
//       Position positionOfUser = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       currentPositionOfUser = positionOfUser;

//       LatLng positionOfUserInLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//       print(positionOfUserInLatLng);

//       CameraPosition cameraPosition =
//           CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//       controllerGoogleMap!
//           .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//       await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
//           currentPositionOfUser!, context);
//     } catch (e) {
//       // Handle exceptions if needed
//       print('Error in getCurrentLiveLocationOfUser: $e');
//     }
//   }

//   Future<DirectionDetails?> obtainDirectionAndDrawRoute(
//       sourceLocationLatLng, destinationLocationLatLng) async {
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) =>
//             LoadingDialog(messageText: 'Please wait ....'));

//     var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
//         sourceLocationLatLng, destinationLocationLatLng);

//     Navigator.pop(context);

//     if (tripDetailsInfo != null) {
//       List<PointLatLng> latLngPoints =
//           pointsPolyline.decodePolyline(tripDetailsInfo.encodePoints!);

//       polylineCoOrdinates.clear();

//       if (latLngPoints.isNotEmpty) {
//         latLngPoints.forEach((PointLatLng pointLatLng) {
//           polylineCoOrdinates
//               .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
//         });
//       }

//       polylineSet.clear();
//       if (mounted) {
//         setState(() {
//           Polyline polyline = Polyline(
//               polylineId: const PolylineId("polylineID"),
//               color: Colors.pink,
//               points: polylineCoOrdinates,
//               jointType: JointType.round,
//               width: 4,
//               startCap: Cap.roundCap,
//               endCap: Cap.roundCap,
//               geodesic: true);

//           polylineSet.add(polyline);
//         });
//       }

//       LatLngBounds boundsLatLng;

//       double minLat =
//           sourceLocationLatLng.latitude < destinationLocationLatLng.latitude
//               ? sourceLocationLatLng.latitude
//               : destinationLocationLatLng.latitude;
//       double maxLat =
//           sourceLocationLatLng.latitude > destinationLocationLatLng.latitude
//               ? sourceLocationLatLng.latitude
//               : destinationLocationLatLng.latitude;

//       double minLng =
//           sourceLocationLatLng.longitude < destinationLocationLatLng.longitude
//               ? sourceLocationLatLng.longitude
//               : destinationLocationLatLng.longitude;
//       double maxLng =
//           sourceLocationLatLng.longitude > destinationLocationLatLng.longitude
//               ? sourceLocationLatLng.longitude
//               : destinationLocationLatLng.longitude;

//       boundsLatLng = LatLngBounds(
//         southwest: LatLng(minLat, minLng),
//         northeast: LatLng(maxLat, maxLng),
//       );

//       controllerGoogleMap!
//           .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

//       Marker sourceMarker = Marker(
//         markerId: const MarkerId("pickUpPointMarkerID"),
//         position: sourceLocationLatLng,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         infoWindow: const InfoWindow(
//           title: "Pickup Location",
//           snippet: "unknown",
//         ),
//       );

//       Marker destinationMarker = Marker(
//         markerId: const MarkerId("dropOffDestinationPointMarkerID"),
//         position: destinationLocationLatLng,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
//         infoWindow: const InfoWindow(
//           title: "Destination Location",
//           snippet: "unknown",
//         ),
//       );

//       setState(() {
//         markerSet.add(sourceMarker);
//         markerSet.add(destinationMarker);
//       });

//       Circle sourceCircle = Circle(
//           circleId: const CircleId("pickUpPointCircleID"),
//           strokeColor: Colors.orange,
//           strokeWidth: 4,
//           radius: 14,
//           center: sourceLocationLatLng,
//           fillColor: Colors.green);

//       Circle destinationCircle = Circle(
//           circleId: const CircleId("dropOffDestinationPointCircleID"),
//           strokeColor: Colors.green,
//           strokeWidth: 4,
//           radius: 14,
//           center: destinationLocationLatLng,
//           fillColor: Colors.orange);

//       setState(() {
//         circleSet.add(sourceCircle);
//         circleSet.add(destinationCircle);
//       });
//     }
//     return tripDetailsInfo;
//   }

//   Future<void> restoreStateAfterRestart() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     // nearbyOnlineDriversKeysLoaded =
//     //     prefs.getBool('nearbyOnlineDriversKeysLoaded') ?? false;
//     // print(
//     //     "Restored nearbyOnlineDriversKeysLoaded: $nearbyOnlineDriversKeysLoaded");

//     // Restore available nearby drivers list
//     availableNearbyOnlineDriversList =
//         (jsonDecode(prefs.getString('availableNearbyOnlineDriversList') ?? '[]')
//                 as List)
//             .map((data) => OnlineNearbyDrivers.fromJson(data))
//             .toList();
//     print(
//         "Restored availableNearbyOnlineDriversList: $availableNearbyOnlineDriversList drivers loaded");
//     String? jsonString = prefs.getString('tripDirectionDetailsInfo');
//     if (jsonString != null) {
//       Map<String, dynamic> jsonMap = jsonDecode(jsonString);
//       if (mounted) {
//         setState(() {
//           tripDirectionDetailsInfo = DirectionDetails.fromJson(jsonMap);
//         });
//       }
//     }
//   }

//   void updateMapTheme(GoogleMapController controller) {
//     getJsonFileFromThemes("themes/light_style.json").then((value) {
//       controller.setMapStyle(value);
//     });
//   }

//   Future<String> getJsonFileFromThemes(String mapStylePath) async {
//     ByteData byteData = await rootBundle.load(mapStylePath);
//     var list = byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
//     return utf8.decode(list);
//   }

//   displayRequestContainer() {
//     print("displayingRequestContainer in tripStatusPage");
//     setState(() {
//       rideDetailsContainerHeight = 0;
//       requestContainerHeight = 220;
//       bottomMapPadding = 200;
//     });
//   }

//   void displayTripDetailsContainer() {
//     setState(() {
//       requestContainerHeight = 0;
//       tripContainerHeight = 291;
//       bottomMapPadding = 281;
//     });
//   }

//   void startTripStreamSubscription() {
//     print("entered into startTripStreamSubscription");
//     if (widget.tripRequestKey == null) return;
//     DatabaseReference? tripRequestRef = FirebaseDatabase.instance
//         .ref()
//         .child("tripRequests")
//         .child(widget.tripRequestKey!);

//     tripStreamSubscription =
//         tripRequestRef.onValue.listen((eventSnapshot) async {
//       if (eventSnapshot.snapshot.value == null) return;

//       Map<dynamic, dynamic> data =
//           eventSnapshot.snapshot.value as Map<dynamic, dynamic>;

//       // Handle driver information
//       nameDriver = data["driverName"] ?? nameDriver;
//       phoneNumberDriver = data["driverPhone"] ?? phoneNumberDriver;
//       photoDriver = data["driverPhoto"] ?? photoDriver;
//       carDetialsDriver = data["carDetails"] ?? carDetialsDriver;

//       // Handle status
//       status = data["status"] ?? status;
//       print(status);

//       // Handle driver location
//       if (data["driverLocation"] != null) {
//         var latitudeString =
//             data["driverLocation"]["latitude"]?.toString() ?? "";
//         print(latitudeString);
//         var longitudeString =
//             data["driverLocation"]["longitude"]?.toString() ?? "";
//         print(longitudeString);

//         if (latitudeString.isNotEmpty && longitudeString.isNotEmpty) {
//           try {
//             double driverLatitude =
//                 double.tryParse(latitudeString.trim()) ?? 0.0;
//             double driverLongitude =
//                 double.tryParse(longitudeString.trim()) ?? 0.0;

//             if (driverLatitude != 0.0 && driverLongitude != 0.0) {
//               LatLng driverCurrentLocationLatLng =
//                   LatLng(driverLatitude, driverLongitude);

//               if (status == "accepted") {
//                 print("status is accepted");
//                 updateFromDriverCurrentLocationToPickUp(
//                     driverCurrentLocationLatLng);
//               } else if (status == "arrived") {
//                 print("status is arrived");
//                 setState(() {
//                   tripStatusDisplay = 'Driver has Arrived';
//                 });
//               } else if (status == "ontrip") {
//                 print("status is arrived");
//                 updateFromDriverCurrentLocationToDropOffDestination(
//                     driverCurrentLocationLatLng);
//               }
//             }
//           } catch (e) {
//             print("Error parsing latitude or longitude: $e");
//           }
//         }
//       }

//       if (status == "accepted") {
//         displayTripDetailsContainer();
//         // Assuming you have a method to stop listening for driver updates
//         // stopGeoFireListenerWeb();
//         setState(() {
//           // Remove any driver markers, assuming you have a markerSet for managing markers
//           markerSet.removeWhere(
//               (element) => element.markerId.value.contains("driver"));
//         });
//       }

//       if (status == "ended") {
//         tripRequestRef!.onDisconnect();
//         tripRequestRef = null;
//         tripStreamSubscription!.cancel();
//         tripStreamSubscription = null;
//         _resetToInitialPosition();
//       }
//     });
//   }

//   void _resetToInitialPosition() {
//     // Ensure the controller is available before using it
//     if (controllerGoogleMap != null) {
//       controllerGoogleMap!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: googlePlexInitialPositon
//                 .target, // Use the initial camera position
//             zoom: 15, // Set your desired zoom level
//           ),
//         ),
//       );
//     }
//     resetAppNow();
//     Navigator.popUntil(
//         context, (route) => route.isFirst); // Navigate back to the Homepage
//   }

//   updateFromDriverCurrentLocationToPickUp(
//       LatLng driverCurrentLocationLatLng) async {
//     print("entered into updateFromDriverCurrentLocationToPickUp");
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var userPickUpLocationLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

//       print(userPickUpLocationLatLng);

//       var directionDetailsPickup = await obtainDirectionAndDrawRoute(
//           driverCurrentLocationLatLng, userPickUpLocationLatLng);

//       if (directionDetailsPickup == null) {
//         print("directionDetailsPickup is null");
//         return;
//       }
//       if (mounted) {
//         setState(() {
//           tripStatusDisplay =
//               "Driver is Coming - ${directionDetailsPickup.durationTextString}";
//         });
//       }

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   updateFromDriverCurrentLocationToDropOffDestination(
//       driverCurrentLocationLatLng) async {
//     if (!requestingDirectionDetailsInfo) {
//       requestingDirectionDetailsInfo = true;

//       var dropOffLocation =
//           Provider.of<Appinfo>(context, listen: false).dropOffLocation;
//       print(dropOffLocation!.placeName);
//       var userDropOffLocationLatLng = LatLng(
//           dropOffLocation.latitudePositon!, dropOffLocation.longitudePosition!);
//       print(userDropOffLocationLatLng);

//       var directionDetailsPickup = await obtainDirectionAndDrawRoute(
//           driverCurrentLocationLatLng, userDropOffLocationLatLng);

//       if (directionDetailsPickup == null) {
//         print(" direction Details Pickup is null");
//         return;
//       }
//       if (mounted) {
//         setState(() {
//           tripStatusDisplay =
//               "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
//         });
//       }

//       requestingDirectionDetailsInfo = false;
//     }
//   }

//   void searchDriver() {
//     if (availableNearbyOnlineDriversList!.isEmpty) {
//       cancelRideRequest();
//       resetAppNow();
//       noDriverAvailable();
//       return;
//     }

//     var currentDriver = availableNearbyOnlineDriversList!.removeAt(0);
//     sendNotificationToDriver(currentDriver);
//   }

//   void sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
//     if (tripDirectionDetailsInfo == null ||
//         currentDriver.uidDriver == null ||
//         widget.tripRequestKey == null) {
//       return;
//     }

//     DatabaseReference currentDriverRef = FirebaseDatabase.instance
//         .ref()
//         .child("drivers")
//         .child(currentDriver.uidDriver.toString())
//         .child("newTripStatus");

//     currentDriverRef.set(widget.tripRequestKey!).then((_) {
//       DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
//           .ref()
//           .child("drivers")
//           .child(currentDriver.uidDriver.toString())
//           .child("deviceToken");

//       tokenOfCurrentDriverRef.once().then((dataSnapshot) {
//         if (dataSnapshot.snapshot.value != null) {
//           String deviceToken = dataSnapshot.snapshot.value.toString();
//           PushNotificationService.sendNotificationToSelectedDriver(
//               deviceToken, context, widget.tripRequestKey!);
//           handleDriverResponseTimeout(currentDriverRef);
//         }
//       });
//     });
//   }

//   void handleDriverResponseTimeout(DatabaseReference currentDriverRef) {
//     const oneTickPerSec = Duration(seconds: 1);
//     Timer.periodic(oneTickPerSec, (timer) {
//       requestTimeoutDriver -= 1;
//       if (requestTimeoutDriver <= 0) {
//         timer.cancel();
//         currentDriverRef.set("timeout");
//         currentDriverRef.onDisconnect();
//         requestTimeoutDriver = 20;
//         searchDriver();
//       }

//       currentDriverRef.onValue.listen((dataSnapshot) {
//         if (dataSnapshot.snapshot.value.toString() == "accepted") {
//           timer.cancel();
//           requestTimeoutDriver = 20;
//         }
//       });
//     });
//   }

//   void cancelRideRequest() {
//     if (widget.tripRequestKey != null) {
//       DatabaseReference tripRequestRef = FirebaseDatabase.instance
//           .ref()
//           .child("tripRequests")
//           .child(widget.tripRequestKey!);
//       tripRequestRef.remove();
//     }
//     // Navigator.pop(context);
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
//       bottomMapPadding = 300;

//       status = "";
//       nameDriver = "";
//       photoDriver = "";
//       phoneNumberDriver = "";
//       carDetialsDriver = "";
//       tripStatusDisplay = 'Driver is Arriving';
//       print("resetAppNow in tripStatusPage");
//     });
//   }

//   void noDriverAvailable() {
//     showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) => AlertDialog(
//               title: Text("No Driver Available"),
//               content: Text(
//                   "No driver found in the nearby location. Please try again shortly."),
//               actions: [
//                 TextButton(
//                   child: Text("OK"),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ],
//             ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Trip Status'),
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             padding: EdgeInsets.only(bottom: bottomMapPadding),
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
//               if (mounted) {
//                 setState(() {
//                   bottomMapPadding = 300;
//                 });
//               }
//               print("before getcurrentlivelocationofuser in tripStatus page");
//               getCurrentLiveLocationOfUser();
//               print("after getcurrentlivelocationofuser in tripStatusPAge");
//               print("before displayRequestContainer");
//               displayRequestContainer();
//               print("before SearchDriver");
//               searchDriver();
//             },
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
//                     const Text(
//                       "Connecting To Driver.....",
//                       style: TextStyle(color: Colors.blue),
//                     ),
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

//           // Trip details container...
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: tripContainerHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(16),
//                   topRight: Radius.circular(16),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 15.0,
//                     spreadRadius: 0.5,
//                     offset: Offset(0.7, 0.7),
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 5),

//                     // Trip status display text
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           tripStatusDisplay,
//                           style: const TextStyle(
//                               fontSize: 19, color: Colors.black),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 19),

//                     const Divider(
//                         height: 1, color: Colors.black12, thickness: 1),

//                     const SizedBox(height: 19),

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
//                         const SizedBox(width: 8),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               nameDriver,
//                               style: const TextStyle(
//                                   fontSize: 20, color: Colors.black),
//                             ),
//                             Text(
//                               carDetialsDriver,
//                               style: const TextStyle(
//                                   fontSize: 14, color: Colors.blue),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 19),

//                     const Divider(
//                         height: 1, color: Colors.black12, thickness: 1),

//                     const SizedBox(height: 19),

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
//                                   color: Colors.blue,
//                                   border:
//                                       Border.all(width: 1, color: Colors.blue),
//                                 ),
//                                 child: const Icon(Icons.phone,
//                                     color: Colors.white),
//                               ),
//                               const SizedBox(height: 11),
//                               const Text("Call",
//                                   style: TextStyle(color: Colors.blue)),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:html' as html;

// import 'package:cccc/checkout/stripe_checkout_web.dart';
// import 'package:cccc/forms/mobility_aids.dart';
// import 'package:cccc/models/address_model.dart';
// import 'package:cccc/pages/main_page.dart';
// import 'package:cccc/pages/personal_details_page.dart';
// import 'package:cccc/pages/trip_status_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:cccc/authentication/login_screen.dart';
// import 'package:cccc/global/global_var.dart';
// import 'package:cccc/global/trip_var.dart';
// import 'package:cccc/methods/common_methods.dart';
// import 'package:cccc/methods/manage_drivers_method.dart';
// import 'package:cccc/models/direction_details.dart';
// import 'package:cccc/models/online_nearby_drivers.dart';
// import 'package:cccc/pages/about_page.dart';
// import 'package:cccc/pages/search_destination_page.dart';
// import 'package:cccc/pages/trip_history_page.dart';
// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:cccc/widgets/loading_dialog.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Homepage extends StatefulWidget {
//   const Homepage({super.key});

//   @override
//   State<Homepage> createState() => _HomepageState();
// }

// class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
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
//   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList = [];
//   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
//   bool requestingDirectionDetailsInfo = false;
//   bool paymentPending = false;
//   // bool isAssigningDriver = false;
//   bool afterPayment = false;
//   bool boolsaveStateAfterDriverListPopulated = false;
//   bool boolsaveStateBeforeRedirect = false;
//   bool boolgetCurrentLiveLocationOfUser = false;
//   bool boolgetUserInfoAndCheckBlockStatus = false;
//   bool boolinitializeGeoFireListenerWeb = false;
//   StreamSubscription<DatabaseEvent>? geoFireSubscriptionWeb;

//   final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//       GlobalKey<ScaffoldMessengerState>();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     final String? sessionId = html.window.localStorage['sessionId'];
//     final String? paymentStatus = html.window.localStorage['paymentStatus'];
//     print("initState called");
//     print(
//         "Initial availableNearbyOnlineDriversList count: ${availableNearbyOnlineDriversList?.length}");
//     if (sessionId != null && paymentStatus == 'pending') {
//       boolsaveStateAfterDriverListPopulated = true;
//       boolsaveStateBeforeRedirect = true;
//       boolgetCurrentLiveLocationOfUser = true;
//       boolgetUserInfoAndCheckBlockStatus = true;
//       boolinitializeGeoFireListenerWeb = true;
//       print("restoreStateAfterRestart is called");
//       restoreStateAfterRestart();
//       print("before _checkPaymentStatus");
//       _checkPaymentStatus();
//       print("after _checkPaymentStatus");
//     } else {
//       resetAppNow();
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> _checkPaymentStatus() async {
//     final String? sessionId = html.window.localStorage['sessionId'];
//     print(sessionId);
//     final String? paymentStatus = html.window.localStorage['paymentStatus'];
//     print(paymentStatus);

//     if (sessionId != null && paymentStatus == 'pending') {
//       paymentPending = true;
//       final decision = await listenForPaymentCompletion(sessionId);
//       if (decision == "Payment completed successfully") {
//         handlePaymentAndRedirect();

//         html.window.localStorage.remove('sessionId');
//         print("remove sessionId");
//         html.window.localStorage.remove('paymentStatus');
//         html.window.localStorage.remove('previousScreen');
//       }
//     } else {
//       resetAppNow();
//     }
//   }

//   Future<String> listenForPaymentCompletion(String? sessionId) async {
//     print("Entered into listenForPaymentCompletion in stripe_Checkout_web");

//     try {
//       await FirebaseDatabase.instance
//           .ref('payments/$sessionId')
//           .onValue
//           .firstWhere((DatabaseEvent event) {
//         // Safely casting the data to the desired type
//         final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         print("Listener triggered for sessionId: $sessionId");
//         print("Snapshot data: $data");

//         return data['status'] == 'completed';
//       }).timeout(Duration(minutes: 2), onTimeout: () {
//         // Handle timeout
//         print("Payment confirmation timed out.");
//         throw Exception("Payment confirmation timed out.");
//       });

//       // If the condition is met, return a success message
//       print("Payment completed. Returning success message.");
//       return "Payment completed successfully";
//     } catch (e) {
//       print("Error in collecting data: $e");
//       throw e; // Rethrow the caught error
//     }
//   }

//   Future<void> saveStateBeforeRedirect() async {
//     if (boolsaveStateBeforeRedirect) return;
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     //save userName and userPhone
//     prefs.setString('userName', userName);
//     prefs.setString('userPhone', userPhone);

//     // Store user position and map state
//     prefs.setDouble('userLatitude', currentPositionOfUser?.latitude ?? 0.0);
//     prefs.setDouble('userLongitude', currentPositionOfUser?.longitude ?? 0.0);
//     print(
//         "Saved user position: Latitude = ${currentPositionOfUser?.latitude}, Longitude = ${currentPositionOfUser?.longitude}");

//     // Store trip details
//     prefs.setString('tripRequestKey', tripRequestRef?.key ?? '');
//     prefs.setString('status', status);
//     prefs.setString('stateOfApp', stateOfApp);
//     print(
//         "Saved trip details: tripRequestKey = ${tripRequestRef?.key}, status = $status, stateOfApp = $stateOfApp");

//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     if (pickUpLocation != null) {
//       prefs.setString('pickupPlaceName', pickUpLocation.placeName ?? '');
//       prefs.setDouble('pickupLatitude', pickUpLocation.latitudePositon ?? 0.0);
//       prefs.setDouble(
//           'pickupLongitude', pickUpLocation.longitudePosition ?? 0.0);
//     }
//     print(
//         "pickUpPlaceName : ${pickUpLocation!.placeName}, pickuplat = ${pickUpLocation.latitudePositon},pickuplng = ${pickUpLocation.longitudePosition}");

//     if (dropOffDestinationLocation != null) {
//       prefs.setString(
//           'dropoffPlaceName', dropOffDestinationLocation.placeName ?? '');
//       prefs.setDouble(
//           'dropoffLatitude', dropOffDestinationLocation.latitudePositon ?? 0.0);
//       prefs.setDouble('dropoffLongitude',
//           dropOffDestinationLocation.longitudePosition ?? 0.0);
//     }

//     print(
//         "dropoff Placename = ${dropOffDestinationLocation!.placeName}, dropoffLat = ${dropOffDestinationLocation.latitudePositon}, dropoffLng = ${dropOffDestinationLocation.longitudePosition}");

//     // Store driver details
//     prefs.setString('driverName', nameDriver);
//     prefs.setString('driverPhoto', photoDriver);
//     prefs.setString('driverPhone', phoneNumberDriver ?? "");
//     prefs.setString('carDetails', carDetialsDriver);
//     print(
//         "Saved driver details: Name = $nameDriver, Photo = $photoDriver, Phone = $phoneNumberDriver, Car Details = $carDetialsDriver");

//     if (tripDirectionDetailsInfo != null) {
//       String jsonString = jsonEncode(tripDirectionDetailsInfo!.toJson());
//       await prefs.setString("tripDirectionDetailsInfo", jsonString);
//     }

//     print(
//         "tripDirectionDetailsInfo distance = ${tripDirectionDetailsInfo?.distanceTextString}");

//     // print(
//     //     "Saved trip direction details: Distance = ${tripDirectionDetailsInfo?.distanceTextString}, Duration = ${tripDirectionDetailsInfo?.durationTextString}, DistanceValue = ${tripDirectionDetailsInfo?.distanceValueDigits}, DurationValue = ${tripDirectionDetailsInfo?.durationValueDigits}, EncodePoints = ${tripDirectionDetailsInfo?.encodePoints}");

//     // Store UI state
//     prefs.setDouble('searchContainerHeight', searchContainerHeight);
//     prefs.setDouble('bottomMapPadding', bottomMapPadding);
//     prefs.setDouble('rideDetailsContainerHeight', rideDetailsContainerHeight);
//     prefs.setDouble('requestContainerHeight', requestContainerHeight);
//     prefs.setDouble('tripContainerHeight', tripContainerHeight);
//     print(
//         "Saved UI state: searchContainerHeight = $searchContainerHeight, bottomMapPadding = $bottomMapPadding, rideDetailsContainerHeight = $rideDetailsContainerHeight, requestContainerHeight = $requestContainerHeight, tripContainerHeight = $tripContainerHeight");
//     print(
//         "Before saving state in final save: availableNearbyOnlineDriversList count = ${ManageDriversMethod.nearbyOnlineDriversList.length}");
//     // await Future.delayed(Duration(seconds: 3));
//     // Store GeoFire state
//     prefs.setBool(
//         'nearbyOnlineDriversKeysLoaded', nearbyOnlineDriversKeysLoaded);
//     prefs.setString('availableNearbyOnlineDriversList',
//         jsonEncode(ManageDriversMethod.nearbyOnlineDriversList ?? []));
//     print(
//         "Saved GeoFire state: nearbyOnlineDriversKeysLoaded = $nearbyOnlineDriversKeysLoaded, availableNearbyOnlineDriversList = ${jsonEncode(ManageDriversMethod.nearbyOnlineDriversList)}");
//   }

//   void restoreStateAfterRestart() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     userName = prefs.getString('userName') ?? "unknown";
//     userPhone = prefs.getString('userPhone') ?? "unknown";

//     // Restore user position and map state
//     double latitude = prefs.getDouble('userLatitude') ?? 0.0;
//     double longitude = prefs.getDouble('userLongitude') ?? 0.0;
//     currentPositionOfUser = Position(
//         latitude: latitude,
//         longitude: longitude,
//         timestamp: DateTime
//             .now(), // Provide current timestamp or another appropriate value
//         accuracy: 1.0, // Provide a default accuracy value
//         altitude: 0.0, // Provide a default altitude value
//         altitudeAccuracy: 1.0, // Provide a default altitudeAccuracy value
//         heading: 0.0, // Provide a default heading value
//         headingAccuracy: 1.0, // Provide a default headingAccuracy value
//         speed: 0.0, // Provide a default speed value
//         speedAccuracy: 1.0, // Provide a default speedAccuracy value
//         isMocked: false);

//     print(
//         "Restored user position: Latitude = $latitude, Longitude = $longitude");

//     // Restore tripRequestKey
//     String? tripKey = prefs.getString('tripRequestKey');
//     if (tripKey != null && tripKey.isNotEmpty) {
//       tripRequestRef =
//           FirebaseDatabase.instance.ref().child("tripRequests").child(tripKey);
//     }
//     print("Restored tripRequestKey: $tripKey");

//     // Restore status and state of the app
//     status = prefs.getString('status') ?? '';
//     stateOfApp = prefs.getString('stateOfApp') ?? '';
//     print("Restored status: $status");
//     print("Restored stateOfApp: $stateOfApp");

//     // Restore pickup and dropoff locations using AddressModel
//     var appInfo = Provider.of<Appinfo>(context, listen: false);
//     appInfo.updatePickUpLocation(AddressModel(
//       placeName: prefs.getString('pickupPlaceName') ?? '',
//       latitudePositon: prefs.getDouble('pickupLatitude') ?? 0.0,
//       longitudePosition: prefs.getDouble('pickupLongitude') ?? 0.0,
//     ));

//     print("restoration of pickupLocation : ${appInfo.pickUpLocation}");

//     appInfo.updateDropOffLocation(AddressModel(
//       placeName: prefs.getString('dropoffPlaceName') ?? '',
//       latitudePositon: prefs.getDouble('dropoffLatitude') ?? 0.0,
//       longitudePosition: prefs.getDouble('dropoffLongitude') ?? 0.0,
//     ));

//     print("restoration of dropoffLocation : ${appInfo.dropOffLocation}");

//     // Restore driver details
//     nameDriver = prefs.getString('driverName') ?? '';
//     photoDriver = prefs.getString('driverPhoto') ?? '';
//     phoneNumberDriver = prefs.getString('driverPhone') ?? '';
//     carDetialsDriver = prefs.getString('carDetails') ?? '';
//     print(
//         "Restored driver details: Name = $nameDriver, Photo = $photoDriver, Phone = $phoneNumberDriver, Car Details = $carDetialsDriver");

//     String? jsonString = prefs.getString('tripDirectionDetailsInfo');
//     if (jsonString != null) {
//       Map<String, dynamic> jsonMap = jsonDecode(jsonString);
//       tripDirectionDetailsInfo = DirectionDetails.fromJson(jsonMap);
//     }

//     print(
//         "tripDirectionDetailsInfo distance = ${tripDirectionDetailsInfo?.durationTextString}");

//     print(
//         "Restored UI state: searchContainerHeight = $searchContainerHeight, bottomMapPadding = $bottomMapPadding, rideDetailsContainerHeight = $rideDetailsContainerHeight, requestContainerHeight = $requestContainerHeight, tripContainerHeight = $tripContainerHeight");

//     // Restore GeoFire state
//     nearbyOnlineDriversKeysLoaded =
//         prefs.getBool('nearbyOnlineDriversKeysLoaded') ?? false;
//     print(
//         "Restored nearbyOnlineDriversKeysLoaded: $nearbyOnlineDriversKeysLoaded");

//     // Restore available nearby drivers list
//     availableNearbyOnlineDriversList =
//         (jsonDecode(prefs.getString('availableNearbyOnlineDriversList') ?? '[]')
//                 as List)
//             .map((data) => OnlineNearbyDrivers.fromJson(data))
//             .toList();
//     print(
//         "Restored availableNearbyOnlineDriversList: $availableNearbyOnlineDriversList drivers loaded");
//   }

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
//     // if (boolgetCurrentLiveLocationOfUser) return;
//     try {
//       Position positionOfUser = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       currentPositionOfUser = positionOfUser;

//       LatLng positionOfUserInLatLng = LatLng(
//           currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//       print(positionOfUserInLatLng);

//       CameraPosition cameraPosition =
//           CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//       controllerGoogleMap!
//           .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

//       await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
//           currentPositionOfUser!, context);

//       await getUserInfoAndCheckBlockStatus();
//       print("initializeGeoFireListenerWeb");
//       await initializeGeoFireListenerWeb();
//       // if (!kIsWeb) {
//       //   await initializeGeoFireListener();
//       // } else {
//       //   print("initializeGeoFireListenerWeb");
//       //   initializeGeoFireListenerWeb();
//       // }
//     } catch (e) {
//       // Handle exceptions if needed
//       print('Error in getCurrentLiveLocationOfUser: $e');
//     }
//   }

//   getUserInfoAndCheckBlockStatus() async {
//     if (boolgetUserInfoAndCheckBlockStatus) return;
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
//         String? name = userData["username"];
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
//     print("entered into retrieve Direction Details");
//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     print(pickUpLocation!.placeName);

//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;
//     print(dropOffDestinationLocation!.placeName);

//     var pickupGeoGraphicCoOrdinates = LatLng(
//         pickUpLocation.latitudePositon!, pickUpLocation.longitudePosition!);
//     var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
//         dropOffDestinationLocation.latitudePositon!,
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
//       print("resetAppNow in homepage");
//       stopGeoFireListenerWeb();
//       if (controllerGoogleMap != null) {
//         controllerGoogleMap!.animateCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(
//               target: googlePlexInitialPositon
//                   .target, // Use the initial camera position
//               zoom: 15, // Set your desired zoom level
//             ),
//           ),
//         );
//       }
//     });
//   }

//   cancelRideRequest() {
//     //remove ride request from database
//     print("in cancel Ride request");
//     if (tripRequestRef != null) {
//       tripRequestRef!.remove();
//     } else {
//       print("tripRequest not found");
//     }
//     print("cancelRideRequest");

//     setState(() {
//       stateOfApp = "normal";
//     });
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
//     print("before makeTripRequest function called");
//     //send ride request
//     makeTripRequest();
//     print("after makeTripRequest function called");
//   }

//   void updateAvailableNearbyOnlineDriversOnMap() {
//     print("Entering updateAvailableNearbyOnlineDriversOnMap");
//     print(
//         "Current availableNearbyOnlineDriversList count: ${ManageDriversMethod.nearbyOnlineDriversList.length}");

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
//       print("Marker added for driver: ${eachOnlineNearbyDriver.uidDriver}");
//     }

//     setState(() {
//       markerSet = markersTempSet;
//     });

//     print("Updated map with ${markersTempSet.length} markers.");
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

//   initializeGeoFireListenerWeb() async {
//     if (boolinitializeGeoFireListenerWeb) return;
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

//     geoFireSubscriptionWeb = query.onValue.listen((event) {
//       print('Received event in GeoFire listener');
//       if (event.snapshot.value != null) {
//         final Map<dynamic, dynamic> driversMap =
//             event.snapshot.value as Map<dynamic, dynamic>;
//         print('Fetched driversMap with ${driversMap.length} entries');
//         driversMap.forEach((key, value) {
//           print('Processing driver: $key');

//           double driverLat = value['latitude'];
//           double driverLng = value['longitude'];

//           if (_isWithinRadius(
//               driverLat, driverLng, latitude, longitude, radiusInKm)) {
//             bool driverExists = ManageDriversMethod.nearbyOnlineDriversList
//                 .any((driver) => driver.uidDriver == key);

//             if (!driverExists) {
//               OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//               onlineNearbyDrivers.uidDriver = key;
//               onlineNearbyDrivers.latDriver = driverLat;
//               onlineNearbyDrivers.lngDriver = driverLng;

//               ManageDriversMethod.nearbyOnlineDriversList
//                   .add(onlineNearbyDrivers);
//               print(
//                   'Driver added: ${onlineNearbyDrivers.uidDriver}, List count: ${ManageDriversMethod.nearbyOnlineDriversList.length}');
//               print(ManageDriversMethod.nearbyOnlineDriversList);

//               if (nearbyOnlineDriversKeysLoaded == true) {
//                 updateAvailableNearbyOnlineDriversOnMap();
//               }
//             } else {
//               print('Driver already exists: $key');
//             }
//           }
//         });

//         nearbyOnlineDriversKeysLoaded = true;
//         updateAvailableNearbyOnlineDriversOnMap();
//       } else {
//         print('No drivers found in GeoFire listener');
//       }
//     });

//     print('initializeGeoFireListenerWeb completed');

//     // Call this method after the drivers have been processed
//     // saveStateAfterDriverListPopulated();
//   }

//   void stopGeoFireListenerWeb() {
//     if (geoFireSubscriptionWeb != null) {
//       geoFireSubscriptionWeb!.cancel();
//       print("GeoFire web listener stopped");
//     }
//   }

//   Future<void> handlePaymentAndRedirect() async {
//     print("entered handlePaymentAndRedirect before try ");
//     print(paymentPending);
//     print(stateOfApp);
//     try {
//       print("entered handlePaymentAndRedirect after try ");
//       print(
//           "Before saving state in handlePaymentAndRedirect: availableNearbyOnlineDriversList count = ${availableNearbyOnlineDriversList?.length}");
//       if (!paymentPending) {
//         await saveStateBeforeRedirect();

//         // Calculate the fare amount
//         double amountInCents =
//             cMethods.calculateFareAmount(tripDirectionDetailsInfo!);

//         print("after calculating fare amount");

//         // Redirect to checkout and get the session ID
//         print("before  calling redirectToCheckout in handlePayment");
//         await redirectToCheckout(context, amountInCents);
//         print("after calling redirectToCheckout in handlePayment");
//       } else {
//         print(paymentPending);
//         print("before presentPaymentSheet called");
//         // await presentPaymentSheet();
//         print("makeTripRequest");
//         makeTripRequest();
//       }
//     } catch (e) {
//       print("Error in handlePaymentAndRedirect: $e");
//     }
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

//     print(pickUpLocation!.placeName);
//     print(dropOffDestinationLocation!.placeName);

//     Map pickUpCoOrdinatesMap = {
//       "latitude": pickUpLocation.latitudePositon.toString(),
//       "longitude": pickUpLocation.longitudePosition.toString(),
//     };
//     print(pickUpCoOrdinatesMap);
//     print(pickUpCoOrdinatesMap.runtimeType);
//     Map dropOffDestinationCoOrdinatesMap = {
//       "latitude": dropOffDestinationLocation.latitudePositon.toString(),
//       "longitude": dropOffDestinationLocation.longitudePosition.toString(),
//     };
//     print(dropOffDestinationCoOrdinatesMap);
//     print(dropOffDestinationCoOrdinatesMap.runtimeType);
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

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => TripStatusPage(
//           tripRequestKey: tripRequestRef!.key,
//         ),
//       ),
//     );
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
//               print("before setState in hompage");
//               if (!paymentPending) {
//                 setState(() {
//                   bottomMapPadding = 300;
//                 });
//               }
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
//                                     // setState(() {
//                                     //   stateOfApp = "requesting";
//                                     // });
//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => MobilityAidsPage(
//                                           onFormSubmitted: () async {
//                                             Navigator.pop(context);
//                                             print(
//                                                 "before handlePaymentAndRedirect called ");
//                                             handlePaymentAndRedirect();
//                                             print(
//                                                 "after handlePaymentAndRedirect called ");
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
//                     const Text(
//                       "Connecting To Driver.....",
//                       style: TextStyle(color: Colors.blue),
//                     ),
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
//         ],
//       ),
//     );
//   }
// }

