import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cccc/methods/manage_drivers_method.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cccc/authentication/login_screen.dart';
import 'package:cccc/global/global_var.dart';
import 'package:cccc/global/trip_var.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/methods/push_notification_service.dart';
import 'package:cccc/models/direction_details.dart';
import 'package:cccc/models/online_nearby_drivers.dart';
import 'package:cccc/pages/about_page.dart';
import 'package:cccc/pages/search_destination_page.dart';
import 'package:cccc/pages/trip_history_page.dart';
import 'package:cccc/widgets/info_dialog.dart';
import 'package:cccc/widgets/payment_dialog.dart';
import 'package:cccc/appinfo/appinfo.dart';

import '../widgets/loading_dialog.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;

  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/tracking.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
    }
  }

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/light_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  Future<void> getCurrentLiveLocationOfUser() async {
    try {
      Position positionOfUser = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      currentPositionOfUser = positionOfUser;

      LatLng positionOfUserInLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      CameraPosition cameraPosition =
          CameraPosition(target: positionOfUserInLatLng, zoom: 15);
      await controllerGoogleMap!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      String humanReadableAddress = await CommonMethods
          .convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
              currentPositionOfUser!, context);

      await getUserInfoAndCheckBlockStatus();
      await initializeGeoFireListener();
    } catch (e) {
      print('Error getting live location: $e');
      // Handle the error accordingly
    }
  }

  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
        } else {
          FirebaseAuth.instance.signOut();

          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));

          cMethods.displaySnackbar(
              "you are blocked. Contact admin: alizeb875@gmail.com", context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }
    });
  }

  displayUserRideDetailsContainer() async {
    ///Directions API
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    var pickupGeoGraphicCoOrdinates = LatLng(
        pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
        dropOffDestinationLocation!.latitudePositon!,
        dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Getting direction..."),
    );

    ///Directions API
    var detailsFromDirectionAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickupGeoGraphicCoOrdinates,
            dropOffDestinationGeoGraphicCoOrdinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination =
        pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

    polylineCoOrdinates.clear();
    if (latLngPointsFromPickUpToDestination.isNotEmpty) {
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
        polylineCoOrdinates
            .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("polylineID"),
        color: Colors.pink,
        points: polylineCoOrdinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    //fit the polyline into the map
    LatLngBounds boundsLatLng;
    if (pickupGeoGraphicCoOrdinates.latitude >
            dropOffDestinationGeoGraphicCoOrdinates.latitude &&
        pickupGeoGraphicCoOrdinates.longitude >
            dropOffDestinationGeoGraphicCoOrdinates.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: dropOffDestinationGeoGraphicCoOrdinates,
        northeast: pickupGeoGraphicCoOrdinates,
      );
    } else if (pickupGeoGraphicCoOrdinates.longitude >
        dropOffDestinationGeoGraphicCoOrdinates.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude,
            dropOffDestinationGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
            pickupGeoGraphicCoOrdinates.longitude),
      );
    } else if (pickupGeoGraphicCoOrdinates.latitude >
        dropOffDestinationGeoGraphicCoOrdinates.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
            pickupGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude,
            dropOffDestinationGeoGraphicCoOrdinates.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: pickupGeoGraphicCoOrdinates,
        northeast: dropOffDestinationGeoGraphicCoOrdinates,
      );
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add markers to pickup and dropOffDestination points
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickupGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: pickUpLocation.placeName, snippet: "Pickup Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(
          title: dropOffDestinationLocation.placeName,
          snippet: "Destination Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    //add circles to pickup and dropOffDestination points
    Circle pickUpPointCircle = Circle(
      circleId: const CircleId('pickupCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: pickupGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    Circle dropOffDestinationPointCircle = Circle(
      circleId: const CircleId('dropOffDestinationCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: dropOffDestinationGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }

  resetAppNow() {
    setState(() {
      polylineCoOrdinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetialsDriver = "";
      tripStatusDisplay = 'Driver is Arriving';
    });
  }

  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef!.remove();

    setState(() {
      stateOfApp = "normal";
    });
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });

    //send ride request
    makeTripRequest();
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    setState(() {
      markerSet.clear();
    });

    Set<Marker> markersTempSet = Set<Marker>();

    for (OnlineNearbyDrivers eachOnlineNearbyDriver
        in ManageDriversMethod.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
          eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId(
            "driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);
    }

    setState(() {
      markerSet = markersTempSet;
    });
  }

  initializeGeoFireListener() {
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent) {
      if (driverEvent != null) {
        var onlineDriverChild = driverEvent["callBack"];

        switch (onlineDriverChild) {
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethod.nearbyOnlineDriversList
                .add(onlineNearbyDrivers);

            if (nearbyOnlineDriversKeysLoaded == true) {
              //update drivers on google map
              updateAvailableNearbyOnlineDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
            ManageDriversMethod.removeDriverFromList(driverEvent["key"]);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethod.updateOnlineNearbyDriversLocation(
                onlineNearbyDrivers);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversKeysLoaded = true;

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;
        }
      }
    });
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation!.latitudePositon.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePositon.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };

    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,
      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);

    tripStreamSubscription =
        tripRequestRef!.onValue.listen((eventSnapshot) async {
      if (eventSnapshot.snapshot.value == null) {
        return;
      }

      if ((eventSnapshot.snapshot.value as Map)["driverName"] != null) {
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverPhone"] != null) {
        phoneNumberDriver =
            (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null) {
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }

      if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
        carDetialsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }

      if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }

      if ((eventSnapshot.snapshot.value as Map)["driverLocation"] != null) {
        double driverLatitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverLongitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());
        LatLng driverCurrentLocationLatLng =
            LatLng(driverLatitude, driverLongitude);

        if (status == "accepted") {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        } else if (status == "arrived") {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() {
            tripStatusDisplay = 'Driver has Arrived';
          });
        } else if (status == "ontrip") {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(
              driverCurrentLocationLatLng);
        }
      }

      if (status == "accepted") {
        displayTripDetailsContainer();

        Geofire.stopListener();

        //remove drivers markers
        setState(() {
          markerSet.removeWhere(
              (element) => element.markerId.value.contains("driver"));
        });
      }

      if (status == "ended") {
        if ((eventSnapshot.snapshot.value as Map)["fareAmount"] != null) {
          double fareAmount = double.parse(
              (eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

          var responseFromPaymentDialog = await showDialog(
            context: context,
            builder: (BuildContext context) =>
                PaymentDialog(fareAmount: fareAmount.toString()),
          );

          if (responseFromPaymentDialog == "paid") {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();

            Restart.restartApp();
          }
        }
      }
    });
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driver is Coming - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation =
          Provider.of<Appinfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePositon!,
          dropOffLocation.longitudePosition!);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }

      setState(() {
        tripStatusDisplay =
            "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => InfoDialog(
              title: "No Driver Available",
              description:
                  "No driver found in the nearby location. Please try again shortly.",
            ));
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList!.length == 0) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList![0];

    //send notification to this currentDriver - currentDriver means selected driver
    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    //update driver's newTripStatus - assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key);

    //get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        String deviceToken = dataSnapshot.snapshot.value.toString();

        //send notification
        PushNotificationService.sendNotificationToSelectedDriver(
            deviceToken, context, tripRequestRef!.key.toString());
      } else {
        return;
      }

      const oneTickPerSec = Duration(seconds: 1);

      var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
        requestTimeoutDriver = requestTimeoutDriver - 1;

        //when trip request is not requesting means trip request cancelled - stop timer
        if (stateOfApp != "requesting") {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }

        //when trip request is accepted by online nearest available driver
        currentDriverRef.onValue.listen((dataSnapshot) {
          if (dataSnapshot.snapshot.value.toString() == "accepted") {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        //if 20 seconds passed - send notification to next nearest online available driver
        if (requestTimeoutDriver == 0) {
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;

          //send notification to next nearest online available driver
          searchDriver();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              //header
              Container(
                color: Colors.black54,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/avatarman.png",
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              const SizedBox(
                height: 10,
              ),

              //body
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => TripsHistoryPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.history,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "History",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (c) => AboutPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.info,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "About",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();

                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => LoginScreen()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: googlePlexInitialPositon,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);

              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                bottomMapPadding = 300;
              });

              getCurrentLiveLocationOfUser();
            },
          ),

          ///drawer button
          Positioned(
            top: 36,
            left: 19,
            child: GestureDetector(
              onTap: () {
                if (isDrawerOpened == true) {
                  sKey.currentState!.openDrawer();
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
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          ///search location icon button
          Positioned(
            left: 0,
            right: 0,
            bottom: -80,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      var responseFromSearchPage = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => SearchDestinationPage()));

                      if (responseFromSearchPage == "placeSelected") {
                        displayUserRideDetailsContainer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ///ride details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: BoxDecoration(
                  color: Colors.white,
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
                      child: Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (tripDirectionDetailsInfo != null)
                                      ? "Distance:${tripDirectionDetailsInfo!.distanceTextString!}"
                                      : 'Distance:0 km',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  (tripDirectionDetailsInfo != null)
                                      ? "Time:${tripDirectionDetailsInfo!.durationTextString!}"
                                      : 'Time:0 \$',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      stateOfApp = "requesting";
                                    });

                                    displayRequestContainer();

                                    //get nearest available drivers
                                    availableNearbyOnlineDriversList =
                                        ManageDriversMethod
                                            .nearbyOnlineDriversList;
                                    print("ManageDriversMethod");

                                    //search driver
                                    searchDriver();
                                    print(searchDriver);
                                  },
                                  child: Image.asset(
                                      "assets/images/uberexec.png",
                                      height: 100,
                                      width: 100),
                                ),
                                Text(
                                  (tripDirectionDetailsInfo != null)
                                      ? "${tripDirectionDetailsInfo!.durationTextString!} min away"
                                      : '0 min away',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                Text(
                                  (tripDirectionDetailsInfo != null)
                                      ? " \$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
                                      : '',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          ///request container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                        size: 50,
                      ),
                    ),
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
                          border: Border.all(width: 1.5, color: Colors.grey),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ///trip details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 5,
                    ),

                    //trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: const TextStyle(
                            fontSize: 19,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    //image - driver name and driver car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            photoDriver == ''
                                ? "https://firebasestorage.googleapis.com/v0/b/cccc-4b8a5.appspot.com/o/avatarman.png?alt=media&token=3d161402-7f8c-4de1-a9ad-96b97a41cc4c"
                                : photoDriver,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameDriver,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              carDetialsDriver,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    //call driver btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(25)),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                height: 11,
                              ),
                              const Text(
                                "Call",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:cccc/authentication/login_screen.dart';
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
// import 'package:cccc/widgets/loading_dialog.dart';
// import 'package:cccc/widgets/payment_dialog.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_geofire/flutter_geofire.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// // Ensure to import your global variables or variables used in the code
// import 'package:cccc/global/global_var.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:provider/provider.dart';
// import 'package:restart_app/restart_app.dart';
// import 'package:url_launcher/url_launcher.dart'; // Replace with actual import path

// class Homepage extends StatefulWidget {
//   const Homepage({Key? key}) : super(key: key);

//   @override
//   State<Homepage> createState() => _HomepageState();
// }

// class _HomepageState extends State<Homepage> {
//   final Completer<GoogleMapController> googleMapControllerCompleter =
//       Completer<GoogleMapController>();
//   GoogleMapController? mapController;
//   Position? currentPosition;
//   GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
//   CommonMethods cmethods = CommonMethods();
//   double searchHeightContainer = 276;
//   double bottomMapPadding = 0;
//   double rideDetailsContainerHeight = 0;
//   DirectionDetails? tripDirectionDetailsInfo;
//   List<LatLng> polylineCoordinates = [];
//   Set<Polyline> polylineSet = {};
//   Set<Marker> markerSet = {};
//   Set<Circle> circleSet = {};
//   bool isDrawerOpened = true;
//   double requestContainerHeight = 0;
//   double tripContainerHeight = 0;
//   String stateOfApp = "normal";
//   bool nearbyOnlineDriversKeysLoaded = false;
//   BitmapDescriptor? carIconNearbyDriver;
//   DatabaseReference? tripRequestRef;
//   List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
//   StreamSubscription<DatabaseEvent>? tripStreamSubscription;
//   bool requestingDirectionDetailsInfo = false;

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

//   @override
//   void initState() {
//     super.initState();
//     getCurrentUserLocation();
//   }

//   void updateMapTheme(GoogleMapController controller) {
//     getJsonFileFromThemes('themes/light_style.json')
//         .then((value) => setGoogleMapStyle(value, controller));
//   }

//   Future<String> getJsonFileFromThemes(String path) async {
//     ByteData byteData = await rootBundle.load(path);
//     var list = byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
//     return utf8.decode(list);
//   }

//   void setGoogleMapStyle(String mapStyle, GoogleMapController controller) {
//     controller.setMapStyle(mapStyle);
//   }

//   void getCurrentUserLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.bestForNavigation,
//     );
//     setState(() {
//       currentPosition = position;
//     });

//     if (mapController != null) {
//       mapController!.animateCamera(CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: LatLng(position.latitude, position.longitude),
//           zoom: 15,
//         ),
//       ));
//     }
//     await CommonMethods.convertGeoGraphicCodingIntoHumanReadableAddress(
//         currentPosition!, context);

//     await getUserInfoAndCheckBlockStatus();

//     await initializeGeoFireListener();
//   }

//   getUserInfoAndCheckBlockStatus() async {
//     DatabaseReference usersRef = FirebaseDatabase.instance
//         .ref()
//         .child('users')
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
//               context,
//               MaterialPageRoute(
//                   builder: (BuildContext context) => LoginScreen()));
//           cmethods.displaySnackbar('You are Blocked, Contact Admin', context);
//         }
//       } else {
//         FirebaseAuth.instance.signOut();
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (BuildContext context) => LoginScreen()));
//       }
//     });
//   }

//   /// DIRECTION API
//   displayUserRideDetailContainer() async {
//     await retriveDirectionDetails();

//     setState(() {
//       searchHeightContainer = 0;
//       bottomMapPadding = 240;
//       rideDetailsContainerHeight = 180;
//       isDrawerOpened = false;
//     });
//   }

//   retriveDirectionDetails() async {
//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     var pickUpGeographicCoordinates = LatLng(
//         pickUpLocation!.latitudePositon!, pickUpLocation.longitudePosition!);
//     var dropOffDestinationGeographicCoordinates = LatLng(
//         dropOffDestinationLocation!.latitudePositon!,
//         dropOffDestinationLocation.longitudePosition!);

//     showDialog(
//         barrierDismissible: false,
//         context: context,
//         builder: (BuildContext context) =>
//             LoadingDialog(messageText: "Getting Directions ..."));

// // DIRECTION API
//     var detailsFromDirectionsAPI =
//         await CommonMethods.getDirectionDetailsFromAPI(
//             pickUpGeographicCoordinates,
//             dropOffDestinationGeographicCoordinates);

//     setState(() {
//       tripDirectionDetailsInfo = detailsFromDirectionsAPI;
//     });

//     Navigator.pop(context);

// //DRAW DIRECTION

//     PolylinePoints pointsPolyline = PolylinePoints();
//     List<PointLatLng> latLngPointsFromPickupToDestination =
//         pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodePoints!);

//     polylineCoordinates.clear();
//     latLngPointsFromPickupToDestination.forEach((PointLatLng latLngPoint) {
//       polylineCoordinates
//           .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
//     });

//     polylineSet.clear();
//     setState(() {
//       Polyline polyline = Polyline(
//           polylineId: const PolylineId("polylineID"),
//           color: Colors.pink,
//           points: polylineCoordinates,
//           jointType: JointType.round,
//           width: 4,
//           startCap: Cap.roundCap,
//           endCap: Cap.roundCap,
//           geodesic: true);

//       polylineSet.add(polyline);
//     });

//     LatLngBounds boundsLatLng;

//     double minLat = pickUpGeographicCoordinates.latitude <
//             dropOffDestinationGeographicCoordinates.latitude
//         ? pickUpGeographicCoordinates.latitude
//         : dropOffDestinationGeographicCoordinates.latitude;
//     double maxLat = pickUpGeographicCoordinates.latitude >
//             dropOffDestinationGeographicCoordinates.latitude
//         ? pickUpGeographicCoordinates.latitude
//         : dropOffDestinationGeographicCoordinates.latitude;

//     double minLng = pickUpGeographicCoordinates.longitude <
//             dropOffDestinationGeographicCoordinates.longitude
//         ? pickUpGeographicCoordinates.longitude
//         : dropOffDestinationGeographicCoordinates.longitude;
//     double maxLng = pickUpGeographicCoordinates.longitude >
//             dropOffDestinationGeographicCoordinates.longitude
//         ? pickUpGeographicCoordinates.longitude
//         : dropOffDestinationGeographicCoordinates.longitude;

//     boundsLatLng = LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );

//     mapController!
//         .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

//     Marker pickUpPointMarker = Marker(
//       markerId: const MarkerId("pickUpPointMarkerID"),
//       position: pickUpGeographicCoordinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       infoWindow:
//           InfoWindow(title: pickUpLocation.placeName, snippet: "Location"),
//     );

//     Marker dropOffDestinationPointMarker = Marker(
//       markerId: const MarkerId("dropOffDestinationPointMarkerID"),
//       position: dropOffDestinationGeographicCoordinates,
//       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
//       infoWindow: InfoWindow(
//           title: dropOffDestinationLocation.placeName, snippet: "Location"),
//     );

//     setState(() {
//       markerSet.add(pickUpPointMarker);
//       markerSet.add(dropOffDestinationPointMarker);
//     });

//     Circle pickUpPointCircle = Circle(
//         circleId: const CircleId("pickUpPointCircleID"),
//         strokeColor: Colors.blue,
//         strokeWidth: 4,
//         radius: 14,
//         center: pickUpGeographicCoordinates,
//         fillColor: Colors.pink);

//     Circle dropOffDestinationPointCircle = Circle(
//         circleId: const CircleId("dropOffDestinationPointCircleID"),
//         strokeColor: Colors.blue,
//         strokeWidth: 4,
//         radius: 14,
//         center: dropOffDestinationGeographicCoordinates,
//         fillColor: Colors.pink);

//     setState(() {
//       circleSet.add(pickUpPointCircle);
//       circleSet.add(dropOffDestinationPointCircle);
//     });
//   }

//   resetAppNow() {
//     setState(() {
//       polylineCoordinates.clear();
//       polylineSet.cast();
//       markerSet.clear();
//       circleSet.clear();
//       rideDetailsContainerHeight = 0;
//       requestContainerHeight = 0;
//       tripContainerHeight = 0;
//       searchHeightContainer = 276;
//       bottomMapPadding = 300;
//       isDrawerOpened = true;

//       nameDriver = "";
//       photoDriver = "";
//       phoneNumberDriver = "";
//       status = "";
//       carDetialsDriver = "";
//       tripStatusDisplay = "Driver is Arriving";
//     });
//   }

//   displayRequestContainer() {
//     setState(() {
//       rideDetailsContainerHeight = 0;
//       requestContainerHeight = 220;
//       bottomMapPadding = 220;
//       isDrawerOpened = true;
//       print("DisplayRequestContainer");
//     });

//     // Send Ride Request
//     makeTripRequest();
//   }

//   cancelRideRequest() {
//     // REMOVE RIDE REQUEST FROM DATABASE
//     tripRequestRef!.remove();

//     setState(() {
//       stateOfApp = "normal";
//     });
//   }

//   updateOnlineNearbyAvailableDriversOnMap() {
//     setState(() {
//       markerSet.clear();
//     });

//     Set<Marker> markersTempSet = Set<Marker>();

//     for (OnlineNearbyDrivers eachOnlineNearbyDrivers
//         in ManageDriversMethod.nearbyOnlineDriversList) {
//       LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDrivers.latDriver!,
//           eachOnlineNearbyDrivers.lngDriver!);

//       Marker driverMarker = Marker(
//           markerId: MarkerId(
//               "driver ID = " + eachOnlineNearbyDrivers.uidDriver.toString()),
//           position: driverCurrentPosition,
//           icon: carIconNearbyDriver!);

//       markersTempSet.add(driverMarker);
//     }
//     setState(() {
//       markerSet = markersTempSet;
//     });
//   }

//   initializeGeoFireListener() {
//     Geofire.initialize("onlineDrivers");
//     Geofire.queryAtLocation(
//             currentPosition!.latitude, currentPosition!.longitude, 22)!
//         .listen((driverEvent) {
//       if (driverEvent != null) {
//         var onlineDriverChild = driverEvent["callBack"];

//         switch (onlineDriverChild) {
//           case Geofire.onKeyEntered:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             ManageDriversMethod.nearbyOnlineDriversList
//                 .add(onlineNearbyDrivers);

//             if (nearbyOnlineDriversKeysLoaded == true) {
//               // update drivers on google map
//               updateOnlineNearbyAvailableDriversOnMap();
//             }
//             break;

//           case Geofire.onKeyExited:
//             ManageDriversMethod.removeDriverFromList(driverEvent["key"]);
//             // update drivers on google map

//             updateOnlineNearbyAvailableDriversOnMap();
//             break;

//           case Geofire.onKeyMoved:
//             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
//             onlineNearbyDrivers.uidDriver = driverEvent["key"];
//             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
//             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
//             ManageDriversMethod.updateOnlineNearbyDriversLocation(
//                 onlineNearbyDrivers);

//             //update driveers on google map
//             updateOnlineNearbyAvailableDriversOnMap();
//             break;

//           case Geofire.onGeoQueryReady:
//             // display nearest online drivers
//             nearbyOnlineDriversKeysLoaded = true;
//             //update driveers on google map
//             updateOnlineNearbyAvailableDriversOnMap();
//             break;
//         }
//       }
//     });
//   }

//   // The _parseDouble method should be defined before it's used.
//   double _parseDouble(String value) {
//     try {
//       return double.parse(value);
//     } catch (e) {
//       print("Invalid double: $value");
//       return 0.0; // or handle error as needed
//     }
//   }

//   void makeTripRequest() {
//     tripRequestRef =
//         FirebaseDatabase.instance.ref().child('tripRequests').push();

//     var pickUpLocation =
//         Provider.of<Appinfo>(context, listen: false).pickUpLocation;
//     var dropOffDestinationLocation =
//         Provider.of<Appinfo>(context, listen: false).dropOffLocation;

//     Map pickUpCoOrdinatesMap = {
//       "latitude": pickUpLocation?.latitudePositon.toString() ?? "",
//       "longitude": pickUpLocation?.longitudePosition.toString() ?? "",
//     };

//     Map dropOffDestinationCoOrdinatesMap = {
//       "latitude": dropOffDestinationLocation?.latitudePositon.toString() ?? "",
//       "longitude":
//           dropOffDestinationLocation?.longitudePosition.toString() ?? ""
//     };

//     Map driverCoOrdinates = {
//       "latitude": "",
//       "longitude": "",
//     };

//     Map dataMap = {
//       "tripID": tripRequestRef?.key,
//       "publishDataTime": DateTime.now().toString(),
//       "userName": userName,
//       "userPhone": userPhone,
//       "userID": userID,
//       "pickUpLatLng": pickUpCoOrdinatesMap,
//       "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
//       "pickUpAddress": pickUpLocation?.placeName ?? "",
//       "dropOffAddress": dropOffDestinationLocation?.placeName ?? "",
//       "driverID": "waiting",
//       "carDetails": "",
//       "driverLocation": driverCoOrdinates,
//       "driverName": "",
//       "driverPhone": "",
//       "driverPhoto": "",
//       "fareAmount": "",
//       "status": "new",
//     };

//     tripRequestRef?.set(dataMap);

//     tripStreamSubscription =
//         tripRequestRef?.onValue.listen((eventSnapshot) async {
//       if (eventSnapshot.snapshot.value == null) {
//         return;
//       }
//       var valueMap = eventSnapshot.snapshot.value as Map;
//       if (valueMap["driverName"] != null) {
//         nameDriver = valueMap["driverName"];
//       }
//       if (valueMap["driverPhone"] != null) {
//         phoneNumberDriver = valueMap["driverPhone"];
//       }
//       if (valueMap["driverPhoto"] != null) {
//         photoDriver = valueMap["driverPhoto"];
//       }
//       if (valueMap["carDetails"] != null) {
//         carDetialsDriver = valueMap["carDetails"];
//       }
//       if (valueMap["status"] != null) {
//         status = valueMap["status"];
//       }
//       if (valueMap["driverLocation"] != null) {
//         try {
//           var driverLocation = valueMap["driverLocation"];

//           if (driverLocation["latitude"] != null &&
//               driverLocation["longitude"] != null) {
//             double driverLatitude =
//                 _parseDouble(driverLocation["latitude"].toString());
//             double driverLongitude =
//                 _parseDouble(driverLocation["longitude"].toString());

//             LatLng driverCurrentLocationLatLng =
//                 LatLng(driverLatitude, driverLongitude);

//             if (status == "accepted") {
//               updateFromDriverCurrentLocationToPickUp(
//                   driverCurrentLocationLatLng);
//             } else if (status == "arrived") {
//               setState(() {
//                 tripStatusDisplay = "Driver has Arrived";
//               });
//             } else if (status == "ontrip") {
//               updateFromDriverCurrentLocationToDropOffDestination(
//                   driverCurrentLocationLatLng);
//             }
//           } else {
//             print("Driver location is missing latitude or longitude.");
//           }
//         } catch (e) {
//           print("Error parsing driver location coordinates: $e");
//           // Handle the error appropriately, for example, by setting default values or showing an error message
//         }
//       } else {
//         print("Driver location is null.");
//       }

//       if (status == "accepted") {
//         displayTripDetailsContainer();

//         Geofire.stopListener();

//         // remove other available driver markers
//         setState(() {
//           markerSet.removeWhere(
//               (element) => element.markerId.value.contains("driver"));
//         });
//       }

//       if (status == "ended") {
//         if (valueMap["fareAmount"] != null) {
//           try {
//             double fareAmount = double.parse(valueMap["fareAmount"].toString());

//             var responseFromPaymentDialog = await showDialog(
//                 context: context,
//                 builder: (BuildContext context) =>
//                     PaymentDialog(fareAmount: fareAmount.toString()));

//             if (responseFromPaymentDialog == "PAID") {
//               tripRequestRef?.onDisconnect();
//               tripRequestRef = null;

//               tripStreamSubscription?.cancel();
//               tripStreamSubscription = null;

//               resetAppNow();

//               // Restart.restartApp();
//             }
//           } catch (e) {
//             print("Error parsing fare amount: $e");
//           }
//         }
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

//       var userPickupLocationLatLng =
//           LatLng(currentPosition!.latitude, currentPosition!.longitude);

//       var directionDetailsPickup =
//           await CommonMethods.getDirectionDetailsFromAPI(
//               driverCurrentLocationLatLng, userPickupLocationLatLng);

//       if (directionDetailsPickup == null) {
//         print("failed failed failed");
//         return;
//       }

//       setState(() {
//         tripStatusDisplay =
//             "Driver is Coming in - ${directionDetailsPickup.durationTextString}";
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
//             "Driving to DropOff Location in  - ${directionDetailsPickup.durationTextString}";
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
//                   "No driver found in the NearbyLocation , Please try again in Shortly",
//             ));
//   }

//   Future<void> searchDriver() async {
//     if (availableNearbyOnlineDriversList == null ||
//         availableNearbyOnlineDriversList!.isEmpty) {
//       print("No available drivers.");
//       cancelRideRequest();
//       noDriverAvailable();
//       resetAppNow();
//       return;
//     }

//     var currentDriver = availableNearbyOnlineDriversList![0];

//     // Log the current driver information for debugging
//     print("Current driver: $currentDriver");

//     try {
//       // Send notification to this current driver
//       await sendNotificationToDriver(currentDriver);
//       print("Notification sent to driver: $currentDriver");

//       // Remove the notified driver from the list
//       availableNearbyOnlineDriversList!.removeAt(0);
//     } catch (e) {
//       print("Error sending notification to driver: $e");
//     }
//   }

//   sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
//     //update driver's new tripstatus - assign tripID to current Driver
//     DatabaseReference currentDriverRef = FirebaseDatabase.instance
//         .ref()
//         .child("drivers")
//         .child(currentDriver.uidDriver.toString())
//         .child("newTripStatus");

//     currentDriverRef.set(tripRequestRef!.key);

//     // get current driver device recognization token
//     DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
//         .ref()
//         .child("drivers")
//         .child(currentDriver.uidDriver.toString())
//         .child("deviceToken");

//     tokenOfCurrentDriverRef.once().then((dataSnapshot) {
//       if (dataSnapshot.snapshot.value != null) {
//         String deviceToken = dataSnapshot.snapshot.value.toString();

//         //Send Notification
//         PushNotificationService.sendNotificationToSelectedDriver(
//             deviceToken, context, tripRequestRef!.key.toString());
//       } else {
//         return;
//       }

//       const oneTickPerSec = Duration(seconds: 1);

//       // ignore: unused_local_variable
//       var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
//         requestTimeoutDriver--;

//         // when trip request is not requesting
//         if (stateOfApp != "requesting") {
//           timer.cancel();
//           currentDriverRef.set("cancelled");
//           currentDriverRef.onDisconnect();
//           requestTimeoutDriver = 20;
//         }

//         // when trip request is accepted by nearest driver
//         currentDriverRef.onValue.listen((dataSnapshot) {
//           if (dataSnapshot.snapshot.value.toString() == "accepted") {
//             timer.cancel();
//             currentDriverRef.onDisconnect();
//             requestTimeoutDriver = 20;
//           }
//         });

//         // if 20 seconds passed - send notification to next nearest driver
//         if (requestTimeoutDriver == 0) {
//           currentDriverRef.set("timeout");
//           timer.cancel();
//           currentDriverRef.onDisconnect();
//           requestTimeoutDriver = 20;

//           //send notification to next nearest driver
//           searchDriver();
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     makeDriverNearbyCarIcon();

//     return Scaffold(
//       key: scaffoldKey,
//       // DRAWER
//       drawer: Drawer(
//         child: Container(
//           color: Colors.black87,
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: <Widget>[
//               DrawerHeader(
//                 decoration: BoxDecoration(color: Colors.black),
//                 padding: EdgeInsets.all(16.0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 40,
//                       backgroundColor: Colors.grey,
//                       child: Icon(Icons.person, size: 60, color: Colors.black),
//                     ),
//                     SizedBox(width: 12),
//                     Text(
//                       userName.toUpperCase(),
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to about screen or implement action
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (BuildContext context) =>
//                               TripsHistoryPage()));
//                 },
//                 child: ListTile(
//                   leading: Icon(Icons.history, color: Colors.white),
//                   title: Text(
//                     'Trip History',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to about screen or implement action
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (BuildContext context) => AboutPage()));
//                 },
//                 child: ListTile(
//                   leading: Icon(Icons.info, color: Colors.white),
//                   title: Text(
//                     'About',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   // Navigate to about screen or implement action
//                   Provider.of<Appinfo>(context, listen: false).toggleTheme();
//                 },
//                 child: ListTile(
//                   leading: Icon(Icons.history, color: Colors.white),
//                   title: Text(
//                     'Theme',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () {
//                   FirebaseAuth.instance.signOut();
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (BuildContext context) => LoginScreen()));
//                 },
//                 child: ListTile(
//                   leading: Icon(Icons.logout, color: Colors.white),
//                   title: Text(
//                     'Logout',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),

//       body: Stack(
//         children: [
//           ///  // GOOGLE MAP
//           GoogleMap(
//             padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
//             mapType: MapType.normal,
//             myLocationButtonEnabled: true,
//             myLocationEnabled: true,
//             polylines: polylineSet,
//             markers: markerSet,
//             circles: circleSet,
//             initialCameraPosition: CameraPosition(
//               target: LatLng(
//                 currentPosition?.latitude ?? 37.7749,
//                 currentPosition?.longitude ?? -122.4194,
//               ),
//               zoom: 15,
//             ),
//             onMapCreated: (GoogleMapController controller) {
//               mapController = controller;
//               updateMapTheme(mapController!);
//               googleMapControllerCompleter.complete(mapController);

//               setState(() {
//                 bottomMapPadding = 300;
//               });
//             },
//           ),

//           //drawer
//           Positioned(
//             top: 42,
//             left: 19,
//             child: GestureDetector(
//               onTap: () {
//                 if (isDrawerOpened == true) {
//                   scaffoldKey.currentState!.openDrawer();
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
//                       color: Colors.black45,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ],
//                 ),
//                 child: CircleAvatar(
//                   backgroundColor: Colors.grey,
//                   radius: 20,
//                   child: Icon(isDrawerOpened == true ? Icons.menu : Icons.close,
//                       color: Colors.black87),
//                 ),
//               ),
//             ),
//           ),

//           // search location icon button
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: -80,
//             child: Container(
//               height: searchHeightContainer,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   ElevatedButton(
//                       onPressed: () async {
//                         var responseFromSearchPage = await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (BuildContext context) =>
//                                     SearchDestinationPage()));

//                         if (responseFromSearchPage == "placeSelected") {
//                           displayUserRideDetailContainer();
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey,
//                           shape: CircleBorder(),
//                           padding: const EdgeInsets.all(24)),
//                       child: const Icon(
//                         Icons.search,
//                         color: Colors.white,
//                         size: 25,
//                       )),
//                   ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey,
//                           shape: CircleBorder(),
//                           padding: const EdgeInsets.all(24)),
//                       child: const Icon(
//                         Icons.home,
//                         color: Colors.white,
//                         size: 25,
//                       )),
//                   ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey,
//                           shape: CircleBorder(),
//                           padding: const EdgeInsets.all(24)),
//                       child: const Icon(
//                         Icons.work,
//                         color: Colors.white,
//                         size: 25,
//                       ))
//                 ],
//               ),
//             ),
//           ),

//           //ride details container
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
//                                 Text(
//                                   (tripDirectionDetailsInfo != null)
//                                       ? "Distance:${tripDirectionDetailsInfo!.distanceTextString!}"
//                                       : 'Distance:0 km',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black),
//                                 ),
//                                 Text(
//                                   (tripDirectionDetailsInfo != null)
//                                       ? "Time:${tripDirectionDetailsInfo!.durationTextString!}"
//                                       : 'Time:0 \$',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 GestureDetector(
//                                   onTap: () {
//                                     setState(() {
//                                       stateOfApp = "requesting";
//                                     });

//                                     displayRequestContainer();

//                                     //get nearest available drivers
//                                     availableNearbyOnlineDriversList =
//                                         ManageDriversMethod
//                                             .nearbyOnlineDriversList;
//                                     print("ManageDriversMethod");

//                                     //search driver
//                                     searchDriver();
//                                     print(searchDriver);
//                                   },
//                                   child: Image.asset(
//                                       "assets/images/uberexec.png",
//                                       height: 100,
//                                       width: 100),
//                                 ),
//                                 Text(
//                                   (tripDirectionDetailsInfo != null)
//                                       ? "${tripDirectionDetailsInfo!.durationTextString!} min away"
//                                       : '0 min away',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black),
//                                 ),
//                                 Text(
//                                   (tripDirectionDetailsInfo != null)
//                                       ? " \$ ${(cmethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
//                                       : '',
//                                   style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // ride request container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: requestContainerHeight,
//               // color: Colors.black54,
//               decoration: BoxDecoration(
//                   color: Colors.black54,
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
//                 padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     SizedBox(
//                         width: 200,
//                         child: LoadingAnimationWidget.flickr(
//                             leftDotColor: Colors.greenAccent,
//                             rightDotColor: Colors.pinkAccent,
//                             size: 50)),
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
//                             color: Colors.white70,
//                             borderRadius: BorderRadius.circular(25),
//                             border: Border.all(width: 1.5, color: Colors.grey)),
//                         child: Icon(
//                           Icons.close,
//                           color: Colors.black,
//                           size: 25,
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // trip request container
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               height: tripContainerHeight,
//               decoration: BoxDecoration(
//                   color: Colors.black87,
//                   borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(15),
//                       topRight: Radius.circular(15)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.white24,
//                       blurRadius: 5,
//                       spreadRadius: 0.5,
//                       offset: Offset(0.7, 0.7),
//                     ),
//                   ]),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(
//                       height: 5,
//                     ),

//                     //trip status display
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           tripStatusDisplay,
//                           style: TextStyle(color: Colors.grey, fontSize: 16),
//                         ),
//                         const SizedBox(
//                           height: 19,
//                         ),
//                         Divider(
//                           height: 1,
//                           thickness: 1,
//                           color: Colors.white70,
//                         ),
//                         const SizedBox(
//                           height: 19,
//                         ),
//                       ],
//                     ),

//                     // image - drivername and driver car details
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         ClipOval(
//                           child: Image.network(
//                             photoDriver == ""
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
//                               style:
//                                   TextStyle(color: Colors.grey, fontSize: 20),
//                             ),
//                             Text(
//                               carDetialsDriver,
//                               style:
//                                   TextStyle(color: Colors.grey, fontSize: 14),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),

//                     const SizedBox(
//                       height: 19,
//                     ),
//                     Divider(
//                       height: 1,
//                       thickness: 1,
//                       color: Colors.white70,
//                     ),
//                     const SizedBox(
//                       height: 19,
//                     ),

//                     //call driver button
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
//                                     borderRadius:
//                                         BorderRadius.all(Radius.circular(25)),
//                                     border: Border.all(
//                                         width: 1, color: Colors.white)),
//                                 child: Icon(
//                                   Icons.phone,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 11,
//                               ),
//                               Text(
//                                 "Call",
//                                 style: TextStyle(color: Colors.grey),
//                               )
//                             ],
//                           ),
//                         )
//                       ],
//                     )
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
