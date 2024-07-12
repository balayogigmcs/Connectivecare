import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/authentication/login_screen.dart';
import 'package:cccc/global/trip_var.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/models/direction_details.dart';
import 'package:cccc/pages/search_destination_page.dart';
import 'package:cccc/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Ensure to import your global variables or variables used in the code
import 'package:cccc/global/global_var.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart'; // Replace with actual import path

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Completer<GoogleMapController> googleMapControllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? mapController;
  Position? currentPosition;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  CommonMethods cmethods = CommonMethods();
  double searchHeightContainer = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  String stateOfApp = "normal";

  @override
  void initState() {
    super.initState();
    getCurrentUserLocation();
  }

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes('themes/dark_style.json')
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String path) async {
    ByteData byteData = await rootBundle.load(path);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  void setGoogleMapStyle(String mapStyle, GoogleMapController controller) {
    controller.setMapStyle(mapStyle);
  }

  void getCurrentUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    setState(() {
      currentPosition = position;
    });

    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        ),
      ));
    }
    await CommonMethods.convertGeoGraphicCodingIntoHumanReadableAddress(
        currentPosition!, context);

    getUserInfoAndCheckBlockStatus();
  }

  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
          });
        } else {
          FirebaseAuth.instance.signOut();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => LoginScreen()));
          cmethods.displaySnackbar('You are Blocked, Contact Admin', context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => LoginScreen()));
      }
    });
  }

  /// DIRECTION API
  displayUserRideDetailContainer() async {
    await retriveDirectionDetails();

    setState(() {
      searchHeightContainer = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

  retriveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    var pickUpGeographicCoordinates = LatLng(
        pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeographicCoordinates = LatLng(
        dropOffDestinationLocation!.latitudePositon!,
        dropOffDestinationLocation.longitudePosition!);

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Getting Directions ..."));

// DIRECTION API
    var detailsFromDirectionsAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickUpGeographicCoordinates,
            dropOffDestinationGeographicCoordinates);

    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionsAPI;
    });

    Navigator.pop(context);

//DRAW DIRECTION

    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickupToDestination =
        pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

    polylineCoordinates.clear();
    latLngPointsFromPickupToDestination.forEach((PointLatLng latLngPoint) {
      polylineCoordinates
          .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
    });

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: const PolylineId("polylineID"),
          color: Colors.pink,
          points: polylineCoordinates,
          jointType: JointType.round,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (pickUpGeographicCoordinates.latitude >
            dropOffDestinationGeographicCoordinates.latitude &&
        pickUpGeographicCoordinates.longitude >
            dropOffDestinationGeographicCoordinates.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: dropOffDestinationGeographicCoordinates,
          northeast: pickUpGeographicCoordinates);
    } else if (pickUpGeographicCoordinates.longitude >
        dropOffDestinationGeographicCoordinates.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(pickUpGeographicCoordinates.latitude,
              dropOffDestinationGeographicCoordinates.longitude),
          northeast: LatLng(dropOffDestinationGeographicCoordinates.latitude,
              pickUpGeographicCoordinates.longitude));
    } else if (pickUpGeographicCoordinates.latitude >
        dropOffDestinationGeographicCoordinates.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(dropOffDestinationGeographicCoordinates.latitude,
              pickUpGeographicCoordinates.longitude),
          northeast: LatLng(pickUpGeographicCoordinates.latitude,
              dropOffDestinationGeographicCoordinates.longitude));
    } else {
      boundsLatLng = LatLngBounds(
          southwest: pickUpGeographicCoordinates,
          northeast: dropOffDestinationGeographicCoordinates);
    }

    mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickUpGeographicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow:
          InfoWindow(title: pickUpLocation.placeName, snippet: "Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeographicCoordinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
          title: dropOffDestinationLocation.placeName, snippet: "Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    Circle pickUpPointCircle = Circle(
        circleId: const CircleId("pickUpPointCircleID"),
        strokeColor: Colors.blue,
        strokeWidth: 4,
        radius: 14,
        center: pickUpGeographicCoordinates,
        fillColor: Colors.pink);

    Circle dropOffDestinationPointCircle = Circle(
        circleId: const CircleId("dropOffDestinationPointCircleID"),
        strokeColor: Colors.blue,
        strokeWidth: 4,
        radius: 14,
        center: dropOffDestinationGeographicCoordinates,
        fillColor: Colors.pink);

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }

  resetAppNow() {
    setState(() {
      polylineCoordinates.clear();
      polylineSet.cast();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchHeightContainer = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      status = "";
      carDetialsDriver = "";
      tripStatusDisplay = "Driver is Arriving";
    });
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 220;
      isDrawerOpened = true;
    });
  }

  cancelRideRequest(){
    // REMOVE RIDE REQUEST FROM DATABASE
    setState(() {
      stateOfApp  = "normal";
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      // DRAWER
      drawer: Drawer(
        child: Container(
          color: Colors.black87,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 60, color: Colors.black),
                    ),
                    SizedBox(width: 12),
                    Text(
                      userName?.toUpperCase() ?? 'GUEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.info, color: Colors.white),
                title: Text(
                  'About',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Navigate to about screen or implement action
                },
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => LoginScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Stack(
        children: [
          ///  // GOOGLE MAP
          GoogleMap(
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentPosition?.latitude ?? 37.7749,
                currentPosition?.longitude ?? -122.4194,
              ),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              updateMapTheme(mapController!);
              googleMapControllerCompleter.complete(mapController);

              setState(() {
                bottomMapPadding = 300;
              });
            },
          ),

          //drawer
          Positioned(
            top: 42,
            left: 19,
            child: GestureDetector(
              onTap: () {
                if (isDrawerOpened == true) {
                  scaffoldKey.currentState!.openDrawer();
                } else {
                  resetAppNow();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(isDrawerOpened == true ? Icons.menu : Icons.close,
                      color: Colors.black87),
                ),
              ),
            ),
          ),

          // search location icon button
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchHeightContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        var responseFromSearchPage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    SearchDestinationPage()));

                        if (responseFromSearchPage == "placeSelected") {
                          displayUserRideDetailContainer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: CircleBorder(),
                          padding: const EdgeInsets.all(24)),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 25,
                      )),
                  ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: CircleBorder(),
                          padding: const EdgeInsets.all(24)),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 25,
                      )),
                  ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: CircleBorder(),
                          padding: const EdgeInsets.all(24)),
                      child: const Icon(
                        Icons.work,
                        color: Colors.white,
                        size: 25,
                      ))
                ],
              ),
            ),
          ),

          //ride details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ]),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: SizedBox(
                        height: 190,
                        child: Card(
                          elevation: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width * .70,
                            color: Colors.black45,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        // '2 km',
                                        (tripDirectionDetailsInfo != null)
                                            ? tripDirectionDetailsInfo!
                                                .distanceTextString!
                                            : '0 km',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70),
                                      ),
                                      Text(
                                        (tripDirectionDetailsInfo != null)
                                            ? tripDirectionDetailsInfo!
                                                .durationTextString!
                                            : '0 \$',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        stateOfApp = "requesting";
                                      });

                                      displayRequestContainer();

                                      //get nearest available drivers

                                      //search driver
                                    },
                                    child: Image.asset(
                                        "assets/images/uberexec.png",
                                        height: 122,
                                        width: 122),
                                  ),
                                  Text(
                                    (tripDirectionDetailsInfo != null)
                                        ? " \$ ${(cmethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
                                        : '',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // ride request container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              // color: Colors.black54,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ]),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                        width: 200,
                        child: LoadingAnimationWidget.flickr(
                            leftDotColor: Colors.greenAccent,
                            rightDotColor: Colors.pinkAccent,
                            size: 50)),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        resetAppNow();
                        cancelRideRequest();
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1.5, color: Colors.grey)),
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
