import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:cccc/checkout/stripe_checkout_web.dart';
import 'package:cccc/forms/mobility_aids.dart';
import 'package:cccc/models/address_model.dart';
import 'package:cccc/pages/main_page.dart';
import 'package:cccc/pages/personal_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cccc/authentication/login_screen.dart';
import 'package:cccc/global/global_var.dart';
import 'package:cccc/global/trip_var.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/methods/manage_drivers_method.dart';
import 'package:cccc/methods/push_notification_service.dart';
import 'package:cccc/models/direction_details.dart';
import 'package:cccc/models/online_nearby_drivers.dart';
import 'package:cccc/pages/about_page.dart';
import 'package:cccc/pages/search_destination_page.dart';
import 'package:cccc/pages/trip_history_page.dart';
import 'package:cccc/widgets/info_dialog.dart';
import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/widgets/loading_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
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
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList = [];
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;
  bool paymentPending = false;
  // bool isAssigningDriver = false;
  bool afterPayment = false;
  bool boolsaveStateAfterDriverListPopulated = false;
  bool boolsaveStateBeforeRedirect = false;
  bool boolgetCurrentLiveLocationOfUser = false;
  bool boolgetUserInfoAndCheckBlockStatus = false;
  bool boolinitializeGeoFireListenerWeb = false;
  StreamSubscription<DatabaseEvent>? geoFireSubscriptionWeb;

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final String? sessionId = html.window.localStorage['sessionId'];
    final String? paymentStatus = html.window.localStorage['paymentStatus'];
    print("initState called");
    print(
        "Initial availableNearbyOnlineDriversList count: ${availableNearbyOnlineDriversList?.length}");
    if (sessionId != null && paymentStatus == 'pending') {
      boolsaveStateAfterDriverListPopulated = true;
      boolsaveStateBeforeRedirect = true;
      boolgetCurrentLiveLocationOfUser = true;
      boolgetUserInfoAndCheckBlockStatus = true;
      boolinitializeGeoFireListenerWeb = true;
      print("restoreStateAfterRestart is called");
      restoreStateAfterRestart();
      print("before _checkPaymentStatus");
      _checkPaymentStatus();
      print("after _checkPaymentStatus");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // saveStateBeforeRedirect();
    }
  }

  Future<void> _checkPaymentStatus() async {
    final String? sessionId = html.window.localStorage['sessionId'];
    print(sessionId);
    final String? paymentStatus = html.window.localStorage['paymentStatus'];
    print(paymentStatus);

    if (sessionId != null && paymentStatus == 'pending') {
      // setState(() {
      //   isAssigningDriver = true; // Show loading indicator and text
      // });
      paymentPending = true;
      // await Future.delayed(Duration(seconds: 2));
      final decision = await listenForPaymentCompletion(sessionId);
      if (decision == "Payment completed successfully") {
        // setState(() {
        //   isAssigningDriver = false; // Hide loading indicator and text
        // });
        handlePaymentAndRedirect();

        html.window.localStorage.remove('sessionId');
        print("remove sessionId");
        html.window.localStorage.remove('paymentStatus');
        html.window.localStorage.remove('previousScreen');
      }
    }
  }

  Future<String> listenForPaymentCompletion(String? sessionId) async {
    print("Entered into listenForPaymentCompletion in stripe_Checkout_web");

    try {
      // Capture the subscription and listen for the event
      // final event = await FirebaseDatabase.instance
      await FirebaseDatabase.instance
          .ref('payments/$sessionId')
          .onValue
          .firstWhere((DatabaseEvent event) {
        // Safely casting the data to the desired type
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        print("Listener triggered for sessionId: $sessionId");
        print("Snapshot data: $data");

        return data['status'] == 'completed';
      }).timeout(Duration(minutes: 2), onTimeout: () {
        // Handle timeout
        print("Payment confirmation timed out.");
        throw Exception("Payment confirmation timed out.");
      });

      // If the condition is met, return a success message
      print("Payment completed. Returning success message.");
      return "Payment completed successfully";
    } catch (e) {
      print("Error in collecting data: $e");
      throw e; // Rethrow the caught error
    }
  }

  // Future<void> saveStateAfterDriverListPopulated() async {
  //   if (boolsaveStateAfterDriverListPopulated) return;
  //   await Future.delayed(Duration(
  //       seconds:
  //           1)); // Adjust this duration based on when the list is typically populated

  //   print(
  //       "Before saving state in list populated: availableNearbyOnlineDriversList count = ${ManageDriversMethod.nearbyOnlineDriversList.length}");

  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   // Save the populated list
  //   prefs.setString('availableNearbyOnlineDriversList',
  //       jsonEncode(ManageDriversMethod.nearbyOnlineDriversList ?? []));

  //   print(
  //       "Saved GeoFire state in list populated: nearbyOnlineDriversKeysLoaded = true, availableNearbyOnlineDriversList count = ${ManageDriversMethod.nearbyOnlineDriversList.length}");
  //   print(
  //       "Saved availableNearbyOnlineDriversList: ${jsonEncode(ManageDriversMethod.nearbyOnlineDriversList)}");
  // }

  Future<void> saveStateBeforeRedirect() async {
    if (boolsaveStateBeforeRedirect) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //save userName and userPhone
    prefs.setString('userName', userName);
    prefs.setString('userPhone', userPhone);

    // Store user position and map state
    prefs.setDouble('userLatitude', currentPositionOfUser?.latitude ?? 0.0);
    prefs.setDouble('userLongitude', currentPositionOfUser?.longitude ?? 0.0);
    print(
        "Saved user position: Latitude = ${currentPositionOfUser?.latitude}, Longitude = ${currentPositionOfUser?.longitude}");

    // // Assuming you use Provider to manage pickup and dropoff locations
    // var pickUpLocation =
    //     Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    // var dropOffDestinationLocation =
    //     Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    // Store trip details
    prefs.setString('tripRequestKey', tripRequestRef?.key ?? '');
    prefs.setString('status', status);
    prefs.setString('stateOfApp', stateOfApp);
    print(
        "Saved trip details: tripRequestKey = ${tripRequestRef?.key}, status = $status, stateOfApp = $stateOfApp");

    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    if (pickUpLocation != null) {
      prefs.setString('pickupPlaceName', pickUpLocation.placeName ?? '');
      prefs.setDouble('pickupLatitude', pickUpLocation.latitudePositon ?? 0.0);
      prefs.setDouble(
          'pickupLongitude', pickUpLocation.longitudePosition ?? 0.0);
    }
    print(
        "pickUpPlaceName : ${pickUpLocation!.placeName}, pickuplat = ${pickUpLocation.latitudePositon},pickuplng = ${pickUpLocation.longitudePosition}");

    if (dropOffDestinationLocation != null) {
      prefs.setString(
          'dropoffPlaceName', dropOffDestinationLocation.placeName ?? '');
      prefs.setDouble(
          'dropoffLatitude', dropOffDestinationLocation.latitudePositon ?? 0.0);
      prefs.setDouble('dropoffLongitude',
          dropOffDestinationLocation.longitudePosition ?? 0.0);
    }

    print(
        "dropoff Placename = ${dropOffDestinationLocation!.placeName}, dropoffLat = ${dropOffDestinationLocation.latitudePositon}, dropoffLng = ${dropOffDestinationLocation.longitudePosition}");

    // // Store pickup and dropoff locations
    // if (pickUpLocation != null) {
    //   prefs.setString('pickupPlaceName', pickUpLocation.placeName ?? '');
    //   prefs.setDouble('pickupLatitude', pickUpLocation.latitudePositon ?? 0.0);
    //   prefs.setDouble(
    //       'pickupLongitude', pickUpLocation.longitudePosition ?? 0.0);
    //   print(
    //       "Saved pickup location: Place Name = ${pickUpLocation.placeName}, Latitude = ${pickUpLocation.latitudePositon}, Longitude = ${pickUpLocation.longitudePosition}");
    // }

    // if (dropOffDestinationLocation != null) {
    //   prefs.setString(
    //       'dropoffPlaceName', dropOffDestinationLocation.placeName ?? '');
    //   prefs.setDouble(
    //       'dropoffLatitude', dropOffDestinationLocation.latitudePositon ?? 0.0);
    //   prefs.setDouble('dropoffLongitude',
    //       dropOffDestinationLocation.longitudePosition ?? 0.0);
    //   print(
    //       "Saved dropoff location: Place Name = ${dropOffDestinationLocation.placeName}, Latitude = ${dropOffDestinationLocation.latitudePositon}, Longitude = ${dropOffDestinationLocation.longitudePosition}");
    // }

    // Store driver details
    prefs.setString('driverName', nameDriver);
    prefs.setString('driverPhoto', photoDriver);
    prefs.setString('driverPhone', phoneNumberDriver ?? "");
    prefs.setString('carDetails', carDetialsDriver);
    print(
        "Saved driver details: Name = $nameDriver, Photo = $photoDriver, Phone = $phoneNumberDriver, Car Details = $carDetialsDriver");

    if (tripDirectionDetailsInfo != null) {
      String jsonString = jsonEncode(tripDirectionDetailsInfo!.toJson());
      await prefs.setString("tripDirectionDetailsInfo", jsonString);
    }

    print(
        "tripDirectionDetailsInfo distance = ${tripDirectionDetailsInfo?.distanceTextString}");

    // print(
    //     "Saved trip direction details: Distance = ${tripDirectionDetailsInfo?.distanceTextString}, Duration = ${tripDirectionDetailsInfo?.durationTextString}, DistanceValue = ${tripDirectionDetailsInfo?.distanceValueDigits}, DurationValue = ${tripDirectionDetailsInfo?.durationValueDigits}, EncodePoints = ${tripDirectionDetailsInfo?.encodePoints}");

    // Store UI state
    prefs.setDouble('searchContainerHeight', searchContainerHeight);
    prefs.setDouble('bottomMapPadding', bottomMapPadding);
    prefs.setDouble('rideDetailsContainerHeight', rideDetailsContainerHeight);
    prefs.setDouble('requestContainerHeight', requestContainerHeight);
    prefs.setDouble('tripContainerHeight', tripContainerHeight);
    print(
        "Saved UI state: searchContainerHeight = $searchContainerHeight, bottomMapPadding = $bottomMapPadding, rideDetailsContainerHeight = $rideDetailsContainerHeight, requestContainerHeight = $requestContainerHeight, tripContainerHeight = $tripContainerHeight");
    print(
        "Before saving state in final save: availableNearbyOnlineDriversList count = ${ManageDriversMethod.nearbyOnlineDriversList.length}");
    // await Future.delayed(Duration(seconds: 3));
    // Store GeoFire state
    prefs.setBool(
        'nearbyOnlineDriversKeysLoaded', nearbyOnlineDriversKeysLoaded);
    prefs.setString('availableNearbyOnlineDriversList',
        jsonEncode(ManageDriversMethod.nearbyOnlineDriversList ?? []));
    print(
        "Saved GeoFire state: nearbyOnlineDriversKeysLoaded = $nearbyOnlineDriversKeysLoaded, availableNearbyOnlineDriversList = ${jsonEncode(ManageDriversMethod.nearbyOnlineDriversList)}");
  }

  // Location? pickUpLocation;
  // Location? dropOffDestinationLocation;

  void restoreStateAfterRestart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    userName = prefs.getString('userName') ?? "unknown";
    userPhone = prefs.getString('userPhone') ?? "unknown";

    // Restore user position and map state
    double latitude = prefs.getDouble('userLatitude') ?? 0.0;
    double longitude = prefs.getDouble('userLongitude') ?? 0.0;
    currentPositionOfUser = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime
            .now(), // Provide current timestamp or another appropriate value
        accuracy: 1.0, // Provide a default accuracy value
        altitude: 0.0, // Provide a default altitude value
        altitudeAccuracy: 1.0, // Provide a default altitudeAccuracy value
        heading: 0.0, // Provide a default heading value
        headingAccuracy: 1.0, // Provide a default headingAccuracy value
        speed: 0.0, // Provide a default speed value
        speedAccuracy: 1.0, // Provide a default speedAccuracy value
        isMocked: false);

    print(
        "Restored user position: Latitude = $latitude, Longitude = $longitude");

    // Restore tripRequestKey
    String? tripKey = prefs.getString('tripRequestKey');
    if (tripKey != null && tripKey.isNotEmpty) {
      tripRequestRef =
          FirebaseDatabase.instance.ref().child("tripRequests").child(tripKey);
    }
    print("Restored tripRequestKey: $tripKey");

    // Restore status and state of the app
    status = prefs.getString('status') ?? '';
    stateOfApp = prefs.getString('stateOfApp') ?? '';
    print("Restored status: $status");
    print("Restored stateOfApp: $stateOfApp");

    // Restore pickup and dropoff locations using AddressModel
    var appInfo = Provider.of<Appinfo>(context, listen: false);
    appInfo.updatePickUpLocation(AddressModel(
      placeName: prefs.getString('pickupPlaceName') ?? '',
      latitudePositon: prefs.getDouble('pickupLatitude') ?? 0.0,
      longitudePosition: prefs.getDouble('pickupLongitude') ?? 0.0,
    ));

    print("restoration of pickupLocation : ${appInfo.pickUpLocation}");

    appInfo.updateDropOffLocation(AddressModel(
      placeName: prefs.getString('dropoffPlaceName') ?? '',
      latitudePositon: prefs.getDouble('dropoffLatitude') ?? 0.0,
      longitudePosition: prefs.getDouble('dropoffLongitude') ?? 0.0,
    ));

    print("restoration of dropoffLocation : ${appInfo.dropOffLocation}");

    // // Restore pickup and dropoff locations
    // pickUpLocation = Location(
    //   placeName: prefs.getString('pickupPlaceName') ?? '',
    //   latitudePositon: prefs.getDouble('pickupLatitude') ?? 0.0,
    //   longitudePosition: prefs.getDouble('pickupLongitude') ?? 0.0,
    // );
    // dropOffDestinationLocation = Location(
    //   placeName: prefs.getString('dropoffPlaceName') ?? '',
    //   latitudePositon: prefs.getDouble('dropoffLatitude') ?? 0.0,
    //   longitudePosition: prefs.getDouble('dropoffLongitude') ?? 0.0,
    // );
    // print(
    //     "Restored pickup location: ${pickUpLocation?.placeName}, Latitude = ${pickUpLocation?.latitudePositon}, Longitude = ${pickUpLocation?.longitudePosition}");
    // print(
    //     "Restored dropoff location: ${dropOffDestinationLocation?.placeName}, Latitude = ${dropOffDestinationLocation?.latitudePositon}, Longitude = ${dropOffDestinationLocation?.longitudePosition}");

    // Restore driver details
    nameDriver = prefs.getString('driverName') ?? '';
    photoDriver = prefs.getString('driverPhoto') ?? '';
    phoneNumberDriver = prefs.getString('driverPhone') ?? '';
    carDetialsDriver = prefs.getString('carDetails') ?? '';
    print(
        "Restored driver details: Name = $nameDriver, Photo = $photoDriver, Phone = $phoneNumberDriver, Car Details = $carDetialsDriver");

    // Restore trip direction details info
    // tripDirectionDetailsInfo?.distanceTextString =
    //     prefs.getString('tripDistance') ?? '';
    // tripDirectionDetailsInfo?.durationTextString =
    //     prefs.getString('tripDuration') ?? '';
    // print(
    //     "Restored trip direction details: Distance = ${tripDirectionDetailsInfo?.distanceTextString}, Duration = ${tripDirectionDetailsInfo?.durationTextString}");

    String? jsonString = prefs.getString('tripDirectionDetailsInfo');
    if (jsonString != null) {
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      tripDirectionDetailsInfo = DirectionDetails.fromJson(jsonMap);
    }

    print(
        "tripDirectionDetailsInfo distance = ${tripDirectionDetailsInfo?.durationTextString}");

    // // Restore UI state
    // setState(() {
    //   searchContainerHeight = prefs.getDouble('searchContainerHeight') ?? 276;
    //   bottomMapPadding = prefs.getDouble('bottomMapPadding') ?? 0;
    //   rideDetailsContainerHeight =
    //       prefs.getDouble('rideDetailsContainerHeight') ?? 0;
    //   requestContainerHeight = prefs.getDouble('requestContainerHeight') ?? 0;
    //   tripContainerHeight = prefs.getDouble('tripContainerHeight') ?? 0;
    // });
    print(
        "Restored UI state: searchContainerHeight = $searchContainerHeight, bottomMapPadding = $bottomMapPadding, rideDetailsContainerHeight = $rideDetailsContainerHeight, requestContainerHeight = $requestContainerHeight, tripContainerHeight = $tripContainerHeight");

    // Restore GeoFire state
    nearbyOnlineDriversKeysLoaded =
        prefs.getBool('nearbyOnlineDriversKeysLoaded') ?? false;
    print(
        "Restored nearbyOnlineDriversKeysLoaded: $nearbyOnlineDriversKeysLoaded");

    // Restore available nearby drivers list
    availableNearbyOnlineDriversList =
        (jsonDecode(prefs.getString('availableNearbyOnlineDriversList') ?? '[]')
                as List)
            .map((data) => OnlineNearbyDrivers.fromJson(data))
            .toList();
    print(
        "Restored availableNearbyOnlineDriversList: $availableNearbyOnlineDriversList drivers loaded");
  }

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

  getCurrentLiveLocationOfUser() async {
    // if (boolgetCurrentLiveLocationOfUser) return;
    try {
      Position positionOfUser = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentPositionOfUser = positionOfUser;

      LatLng positionOfUserInLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      print(positionOfUserInLatLng);

      CameraPosition cameraPosition =
          CameraPosition(target: positionOfUserInLatLng, zoom: 15);
      controllerGoogleMap!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      await CommonMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
          currentPositionOfUser!, context);

      await getUserInfoAndCheckBlockStatus();
      print("initializeGeoFireListenerWeb");
      await initializeGeoFireListenerWeb();
      // if (!kIsWeb) {
      //   await initializeGeoFireListener();
      // } else {
      //   print("initializeGeoFireListenerWeb");
      //   initializeGeoFireListenerWeb();
      // }
    } catch (e) {
      // Handle exceptions if needed
      print('Error in getCurrentLiveLocationOfUser: $e');
    }
  }

  getUserInfoAndCheckBlockStatus() async {
    if (boolgetUserInfoAndCheckBlockStatus) return;
    try {
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(FirebaseAuth.instance.currentUser!.uid);

      DatabaseEvent event = await usersRef.once();
      DataSnapshot snap = event.snapshot;

      if (snap.value != null) {
        Map userData = snap.value as Map;
        String? blockStatus = userData["blockStatus"];
        String? name = userData["username"];
        String? phone = userData["phone"];

        if (blockStatus == "no") {
          if (mounted) {
            setState(() {
              userName = name ?? 'Unknown';
              userPhone = phone ?? 'Unknown';
            });
          }
        } else {
          FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (c) => LoginScreen()));

            cMethods.displaySnackbar(
                "You are blocked. Contact admin: alizeb875@gmail.com", context);
          }
        }
      } else {
        FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
        }
      }
    } catch (e) {
      // Handle exceptions if needed
      print('Error in getUserInfoAndCheckBlockStatus: $e');
    }
  }

  displayUserRideDetailsContainer() async {
    ///Directions API
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 180;
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async {
    print("entered into retrieve Direction Details");
    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    print(pickUpLocation!.placeName);

    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;
    print(dropOffDestinationLocation!.placeName);

    var pickupGeoGraphicCoOrdinates = LatLng(
        pickUpLocation.latitudePositon!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
        dropOffDestinationLocation.latitudePositon!,
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
      // paymentContainerHeight = 0;
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
      print("resetAppNow");
    });
  }

  cancelRideRequest() {
    //remove ride request from database
    print("in cancel Ride request");
    if (tripRequestRef != null) {
      tripRequestRef!.remove();
    } else {
      print("tripRequest not found");
    }
    print("cancelRideRequest");

    setState(() {
      stateOfApp = "normal";
    });
  }

  displayRequestContainer() {
    print("displayingRequestContainer");
    setState(() {
      rideDetailsContainerHeight = 0;
      // paymentContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });
    print("before makeTripRequest function called");
    //send ride request
    makeTripRequest();
    print("after makeTripRequest function called");
  }

  void updateAvailableNearbyOnlineDriversOnMap() {
    print("Entering updateAvailableNearbyOnlineDriversOnMap");
    print(
        "Current availableNearbyOnlineDriversList count: ${ManageDriversMethod.nearbyOnlineDriversList.length}");

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
      print("Marker added for driver: ${eachOnlineNearbyDriver.uidDriver}");
    }

    setState(() {
      markerSet = markersTempSet;
    });

    print("Updated map with ${markersTempSet.length} markers.");
  }

  // initializeGeoFireListener() {
  //   Geofire.initialize("onlineDrivers");
  //   Geofire.queryAtLocation(currentPositionOfUser!.latitude,
  //           currentPositionOfUser!.longitude, 50)!
  //       .listen((driverEvent) {
  //     if (driverEvent != null) {
  //       var onlineDriverChild = driverEvent["callBack"];

  //       switch (onlineDriverChild) {
  //         case Geofire.onKeyEntered:
  //           OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
  //           onlineNearbyDrivers.uidDriver = driverEvent["key"];
  //           onlineNearbyDrivers.latDriver = driverEvent["latitude"];
  //           print(onlineNearbyDrivers.latDriver! + 2000);
  //           onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
  //           print(onlineNearbyDrivers.lngDriver! + 2000);
  //           ManageDriversMethod.nearbyOnlineDriversList
  //               .add(onlineNearbyDrivers);

  //           if (nearbyOnlineDriversKeysLoaded == true) {
  //             //update drivers on google map
  //             updateAvailableNearbyOnlineDriversOnMap();
  //           }

  //           break;

  //         case Geofire.onKeyExited:
  //           print("driver exited");
  //           ManageDriversMethod.removeDriverFromList(driverEvent["key"]);

  //           //update drivers on google map
  //           updateAvailableNearbyOnlineDriversOnMap();

  //           break;

  //         case Geofire.onKeyMoved:
  //           OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
  //           onlineNearbyDrivers.uidDriver = driverEvent["key"];
  //           onlineNearbyDrivers.latDriver = driverEvent["latitude"];
  //           print(onlineNearbyDrivers.latDriver! + 4000);
  //           onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
  //           print(onlineNearbyDrivers.lngDriver! + 4000);
  //           ManageDriversMethod.updateOnlineNearbyDriversLocation(
  //               onlineNearbyDrivers);

  //           //update drivers on google map
  //           updateAvailableNearbyOnlineDriversOnMap();

  //           break;

  //         case Geofire.onGeoQueryReady:
  //           nearbyOnlineDriversKeysLoaded = true;

  //           //update drivers on google map
  //           updateAvailableNearbyOnlineDriversOnMap();

  //           break;
  //       }
  //     }
  //   });
  // }

  bool _isWithinRadius(double driverLat, double driverLng, double centerLat,
      double centerLng, double radiusInKm) {
    const double earthRadiusInKm = 6371.0;

    double dLat = _degreesToRadians(driverLat - centerLat);
    double dLng = _degreesToRadians(driverLng - centerLng);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(centerLat)) *
            cos(_degreesToRadians(driverLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadiusInKm * c;

    return distance <= radiusInKm;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  initializeGeoFireListenerWeb()async {
    if (boolinitializeGeoFireListenerWeb) return;
    print('Starting initializeGeoFireListenerWeb');

    final DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child("onlineDrivers");
    print('Fetched driversRef');

    final double latitude = currentPositionOfUser!.latitude;
    final double longitude = currentPositionOfUser!.longitude;
    final double radiusInKm = 50.0;

    final query = driversRef
        .orderByChild('position'); // Assume 'position' is lat/lng pair
    print('Created query for drivers based on position');

    geoFireSubscriptionWeb = query.onValue.listen((event) {
      print('Received event in GeoFire listener');
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> driversMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        print('Fetched driversMap with ${driversMap.length} entries');
        driversMap.forEach((key, value) {
          print('Processing driver: $key');

          double driverLat = value['latitude'];
          double driverLng = value['longitude'];

          if (_isWithinRadius(
              driverLat, driverLng, latitude, longitude, radiusInKm)) {
            bool driverExists = ManageDriversMethod.nearbyOnlineDriversList
                .any((driver) => driver.uidDriver == key);

            if (!driverExists) {
              OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
              onlineNearbyDrivers.uidDriver = key;
              onlineNearbyDrivers.latDriver = driverLat;
              onlineNearbyDrivers.lngDriver = driverLng;

              ManageDriversMethod.nearbyOnlineDriversList
                  .add(onlineNearbyDrivers);
              print(
                  'Driver added: ${onlineNearbyDrivers.uidDriver}, List count: ${ManageDriversMethod.nearbyOnlineDriversList.length}');
              print(ManageDriversMethod.nearbyOnlineDriversList);

              if (nearbyOnlineDriversKeysLoaded == true) {
                updateAvailableNearbyOnlineDriversOnMap();
              }
            } else {
              print('Driver already exists: $key');
            }
          }
        });

        nearbyOnlineDriversKeysLoaded = true;
        updateAvailableNearbyOnlineDriversOnMap();
      } else {
        print('No drivers found in GeoFire listener');
      }
    });

    print('initializeGeoFireListenerWeb completed');

    // Call this method after the drivers have been processed
    // saveStateAfterDriverListPopulated();
  }

  void stopGeoFireListenerWeb() {
    if (geoFireSubscriptionWeb != null) {
      geoFireSubscriptionWeb!.cancel();
      print("GeoFire web listener stopped");
    }
  }

  Future<void> handlePaymentAndRedirect() async {
    print("entered handlePaymentAndRedirect before try ");
    print(paymentPending);
    print(stateOfApp);
    try {
      print("entered handlePaymentAndRedirect after try ");
      print(
          "Before saving state in handlePaymentAndRedirect: availableNearbyOnlineDriversList count = ${availableNearbyOnlineDriversList?.length}");
      if (!paymentPending) {
        await saveStateBeforeRedirect();

        // Calculate the fare amount
        double amountInCents =
            cMethods.calculateFareAmount(tripDirectionDetailsInfo!);

        print("after calculating fare amount");

        // Redirect to checkout and get the session ID
        print("before  calling redirectToCheckout in handlePayment");
        await redirectToCheckout(context, amountInCents);
        print("after calling redirectToCheckout in handlePayment");
      } else {
        print(paymentPending);
        print("before presentPaymentSheet called");
        await presentPaymentSheet();
        print("after displayRequestContainer");
        print(
            "after displayRequestContainer: availableNearbyOnlineDriversList count = ${availableNearbyOnlineDriversList?.length}");
        // availableNearbyOnlineDriversList =
        //     ManageDriversMethod.nearbyOnlineDriversList;
        print(availableNearbyOnlineDriversList![0]);
        print("ManageDriversMethod1");

        // Search for a driver
        searchDriver();
        print(searchDriver);
      }
    } catch (e) {
      print("Error in handlePaymentAndRedirect: $e");
    }
  }

  Future<void> presentPaymentSheet() async {
    try {
      //     await Stripe.instance.presentPaymentSheet();
      //     scaffoldMessengerKey.currentState?.showSnackBar(
      //       SnackBar(
      //         content: Text('Payment Successful'),
      //         backgroundColor: Colors.green,
      //       ),
      //     );
      print("displaying  Request Container in PresentPayment sheet");
      displayRequestContainer();
    } catch (e) {
      //     scaffoldMessengerKey.currentState?.showSnackBar(
      //       SnackBar(
      //         content: Text('Payment Failed: $e'),
      //         backgroundColor: Colors.redAccent,
      //       ),
      //     );
      //   }
    }
  }

  makeTripRequest() {
    print("before tripRequestRef");
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();
    print("after tripRequestRef");
    print(tripRequestRef);
    print("makeTripRequest");
    print("makeTripRequest");
    var pickUpLocation =
        Provider.of<Appinfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<Appinfo>(context, listen: false).dropOffLocation;

    print(pickUpLocation!.placeName);
    print(dropOffDestinationLocation!.placeName);

    Map pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation.latitudePositon.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };
    print(pickUpCoOrdinatesMap);
    print(pickUpCoOrdinatesMap.runtimeType);
    Map dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation.latitudePositon.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };
    print(dropOffDestinationCoOrdinatesMap);
    print(dropOffDestinationCoOrdinatesMap.runtimeType);
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
      print(eventSnapshot.snapshot.value);
      print("Entered tripStreamSubscription");

      // Introduce a delay before processing the data
      //  await Future.delayed(Duration(seconds: 3)); // Waits for 2 seconds

      if (eventSnapshot.snapshot.value == null) {
        return;
      }

      Map<dynamic, dynamic> data =
          eventSnapshot.snapshot.value as Map<dynamic, dynamic>;

      // Handle driver information
      nameDriver = data["driverName"] ?? nameDriver;
      print(nameDriver);
      phoneNumberDriver = data["driverPhone"] ?? phoneNumberDriver;
      photoDriver = data["driverPhoto"] ?? photoDriver;
      carDetialsDriver = data["carDetails"] ?? carDetialsDriver;
      print(carDetialsDriver);

      // Handle status
      status = data["status"] ?? status;
      print("status = $status");

      // Handle driver location
      if (data["driverLocation"] != null) {
        print("Driver location is not null");

        // Log the exact values being parsed to help identify the issue
        var latitudeString =
            data["driverLocation"]["latitude"]?.toString() ?? "";
        var longitudeString =
            data["driverLocation"]["longitude"]?.toString() ?? "";

        print("Raw Latitude String: '$latitudeString'");
        print("Raw Longitude String: '$longitudeString'");

        if (latitudeString.isNotEmpty && longitudeString.isNotEmpty) {
          try {
            double driverLatitude =
                double.tryParse(latitudeString.trim()) ?? 0.0;
            double driverLongitude =
                double.tryParse(longitudeString.trim()) ?? 0.0;

            print(
                "Parsed Latitude: $driverLatitude, Parsed Longitude: $driverLongitude");

            if (driverLatitude != 0.0 && driverLongitude != 0.0) {
              LatLng driverCurrentLocationLatLng =
                  LatLng(driverLatitude, driverLongitude);

              if (status == "accepted") {
                updateFromDriverCurrentLocationToPickUp(
                    driverCurrentLocationLatLng);
              } else if (status == "arrived") {
                setState(() {
                  tripStatusDisplay = 'Driver has Arrived';
                });
              } else if (status == "ontrip") {
                updateFromDriverCurrentLocationToDropOffDestination(
                    driverCurrentLocationLatLng);
              }
            } else {
              print("Invalid latitude or longitude parsed to 0.0");
            }
          } catch (e) {
            print("Error parsing latitude or longitude: $e");
          }
        } else {
          print("Latitude or Longitude is empty or null");
        }
      } else {
        print("driverLocation is null");
      }

      if (status == "accepted") {
        displayTripDetailsContainer();

        if (!kIsWeb) {
          Geofire.stopListener();
        } else {
          stopGeoFireListenerWeb();
          print('Geofire.stopListener is not supported on the web.');
        }

        setState(() {
          markerSet.removeWhere(
              (element) => element.markerId.value.contains("driver"));
        });
      }

      if (status == "ended") {
        tripRequestRef!.onDisconnect();
        tripRequestRef = null;
        tripStreamSubscription!.cancel();
        tripStreamSubscription = null;
        resetAppNow();
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) => Homepage()));
      }
    });
  }

  // makeTripRequest() {
  //   print("before tripRequestRef");
  //   tripRequestRef =
  //       FirebaseDatabase.instance.ref().child("tripRequests").push();
  //   print("after tripRequestRef");

  //   print(tripRequestRef);
  //   print("makeTripRequest");
  //   print("makeTripRequest");

  //   // // var pickUpLocation
  //   // var pickUpLocation = this.pickUpLocation;
  //   // if (pickUpLocation != null) {
  //   //   print(pickUpLocation.placeName);

  //   //   // Convert Location to AddressModel
  //   //   AddressModel pickUpAddressModel = AddressModel(
  //   //     placeName: pickUpLocation.placeName,
  //   //     latitudePositon: pickUpLocation.latitudePositon,
  //   //     longitudePosition: pickUpLocation.longitudePosition,
  //   //     humanReadableAddress:
  //   //         pickUpLocation.placeName, // You can adjust this as needed
  //   //     placeId: null, // You can set this to a relevant value if available
  //   //   );

  //   //   // / Update the Provider with the restored drop-off location
  //   //   var appInfo = Provider.of<Appinfo>(context, listen: false);
  //   //   appInfo.updatePickUpLocation(pickUpAddressModel);
  //   // } else {
  //   //   print("pickUp location is null");
  //   // }

  //   // var dropOffDestinationLocation = this.dropOffDestinationLocation;
  //   // if (dropOffDestinationLocation != null) {
  //   //   print(dropOffDestinationLocation.placeName);

  //   //   // Convert Location to AddressModel
  //   //   AddressModel dropOffAddressModel = AddressModel(
  //   //     placeName: dropOffDestinationLocation.placeName,
  //   //     latitudePositon: dropOffDestinationLocation.latitudePositon,
  //   //     longitudePosition: dropOffDestinationLocation.longitudePosition,
  //   //     humanReadableAddress: dropOffDestinationLocation
  //   //         .placeName, // You can adjust this as needed
  //   //     placeId: null, // You can set this to a relevant value if available
  //   //   );

  //   //   // Update the Provider with the restored drop-off location
  //   //   var appInfo = Provider.of<Appinfo>(context, listen: false);
  //   //   appInfo.updateDropOffLocation(dropOffAddressModel);
  //   // } else {
  //   //   print("Drop-off location is null");
  //   // }

  //   var pickUpLocation =
  //       Provider.of<Appinfo>(context, listen: false).pickUpLocation;
  //   var dropOffDestinationLocation =
  //       Provider.of<Appinfo>(context, listen: false).dropOffLocation;

  //   print(pickUpLocation!.placeName);
  //   print(dropOffDestinationLocation!.placeName);

  //   Map pickUpCoOrdinatesMap = {
  //     "latitude": pickUpLocation.latitudePositon.toString(),
  //     "longitude": pickUpLocation.longitudePosition.toString(),
  //   };

  //   Map dropOffDestinationCoOrdinatesMap = {
  //     "latitude": dropOffDestinationLocation.latitudePositon.toString(),
  //     "longitude": dropOffDestinationLocation.longitudePosition.toString(),
  //   };

  //   print(dropOffDestinationCoOrdinatesMap);

  //   print(tripRequestRef!.key);

  //   // Map driverCoOrdinates = {
  //   //   "latitude": "",
  //   //   "longitude": "",
  //   // };

  //   // print(driverCoOrdinates);

  //   Map dataMap = {
  //     "tripID": tripRequestRef!.key,
  //     "publishDateTime": DateTime.now().toString(),
  //     "userName": userName,
  //     "userPhone": userPhone,
  //     "userID": userID,
  //     "pickUpLatLng": pickUpCoOrdinatesMap,
  //     "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
  //     "pickUpAddress": pickUpLocation.placeName,
  //     "dropOffAddress": dropOffDestinationLocation.placeName,
  //     "driverID": "waiting",
  //     "carDetails": "",
  //     "driverLocation": "",
  //     "driverName": "",
  //     "driverPhone": "",
  //     "driverPhoto": "",
  //     "fareAmount": "",
  //     "status": "new",
  //   };
  //   print(dataMap);

  //   tripRequestRef!.set(dataMap);
  //   print("after setting datamap");
  //   print("status");

  //   try {
  //     print("Started tripStreamSubscription");
  //     tripStreamSubscription =
  //         tripRequestRef!.onValue.listen((eventSnapshot) async {
  //       if (eventSnapshot.snapshot.value == null) {
  //         return;
  //       }
  //       if ((eventSnapshot.snapshot.value as Map)["driverName"] != null) {
  //         nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
  //         print(nameDriver);
  //       }
  //       if ((eventSnapshot.snapshot.value as Map)["driverPhone"] != null) {
  //         phoneNumberDriver =
  //             (eventSnapshot.snapshot.value as Map)["driverPhone"];
  //       }
  //       if ((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null) {
  //         photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
  //       }
  //       if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
  //         carDetialsDriver =
  //             (eventSnapshot.snapshot.value as Map)["carDetails"];
  //       }
  //       if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
  //         status = (eventSnapshot.snapshot.value as Map)["status"];
  //         print(status);
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
  //       } else {
  //         print("DriverloCation is null");
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
  //             MaterialPageRoute(builder: (BuildContext context) => Homepage()));
  //       }
  //     });
  //   } catch (e) {
  //     print("Error caused in tripStream");
  //   }
  // }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(
      LatLng driverCurrentLocationLatLng) async {
    print("entered into updateFromDriverCurrentLocationToPickUp");
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      print(userPickUpLocationLatLng);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if (directionDetailsPickup == null) {
        print("directionDetailsPickup is null");
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
      print(dropOffLocation!.placeName);
      var userDropOffLocationLatLng = LatLng(
          dropOffLocation.latitudePositon!, dropOffLocation.longitudePosition!);
      print(userDropOffLocationLatLng);

      var directionDetailsPickup =
          await CommonMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        print(" direction Details Pickup is null");
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
    print("NoDriverAvailable");
  }

  void searchDriver() {
    print("Entering searchDriver");
    print(
        "Available drivers before search: ${availableNearbyOnlineDriversList?.length}");

    if (availableNearbyOnlineDriversList!.length == 0) {
      print(availableNearbyOnlineDriversList!.length);
      print("length of available driver 0");
      cancelRideRequest();
      print("cancelled ride Request");
      resetAppNow();
      print("reset APP now");
      noDriverAvailable();
      print("no Driver Available");
      print("SearchDriverEnded");
      return;
    }

    print(
        "availableNearbyOnlineDriversList:  ${availableNearbyOnlineDriversList![0]}");

    var currentDriver = availableNearbyOnlineDriversList![0];
    print(currentDriver);
    print("driver is found ${currentDriver.uidDriver}");

    //send notification to this currentDriver - currentDriver means selected driver
    sendNotificationToDriver(currentDriver);
    print("after sendNotificationNotificationToDriver");

    availableNearbyOnlineDriversList!.removeAt(0);
    print(
        "Driver removed from list. Remaining drivers: ${availableNearbyOnlineDriversList?.length}");
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    print("entered into sendNotificationToDriver");
    print(tripDirectionDetailsInfo);
    print(currentDriver.uidDriver);
    print(tripRequestRef);
    if (tripDirectionDetailsInfo == null ||
        currentDriver.uidDriver == null ||
        tripRequestRef == null) {
      print(
          "tripDirectionDetailsInfo or currentDriver.uidDriver or tripRequestRef is null");
      // sendNotificationToDriver(currentDriver);
      return;
    }

    print(
        "tripDirectionDetailsInfo or currentDriver.uidDriver or tripRequestRef is not null");

    // Update driver's newTripStatus - assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key).then((_) {
      print("Driver's newTripStatus updated successfully");
      // Get current driver device recognition token
      DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentDriver.uidDriver.toString())
          .child("deviceToken");

      print("tokenOfCurrentDriverRef");

      tokenOfCurrentDriverRef.once().then((dataSnapshot) {
        if (dataSnapshot.snapshot.value != null) {
          String deviceToken = dataSnapshot.snapshot.value.toString();
          print("Device Token: $deviceToken");

          print("Trip ID : ${tripRequestRef!.key.toString()}");

          print("before pushNotification service called");
          // Send notification
          PushNotificationService.sendNotificationToSelectedDriver(
              deviceToken, context, tripRequestRef!.key.toString());
          print("after pushNotification Service called");

          print("before handleDriverResponseTimeout called");
          print(currentDriverRef);
          // Handle the timeout logic and other status updates
          handleDriverResponseTimeout(currentDriverRef);
        } else {
          print("No token found for driver");
          return;
        }
      }).catchError((error) {
        print("Error fetching device token: $error");
      });
    }).catchError((error) {
      print("Error updating driver's newTripStatus: $error");
    });
  }

  void handleDriverResponseTimeout(DatabaseReference currentDriverRef) {
    print("entered into handleDriverResponseTimeout");
    const oneTickPerSec = Duration(seconds: 1);

    Timer.periodic(oneTickPerSec, (timer) {
      requestTimeoutDriver = requestTimeoutDriver - 1;
      print(" stateOfApp : $stateOfApp");

      if (stateOfApp != "requesting") {
        timer.cancel();
        currentDriverRef.set("cancelled");
        currentDriverRef.onDisconnect();
        requestTimeoutDriver = 20;
        print("Trip request cancelled by user.");
        return;
      }

      currentDriverRef.onValue.listen((dataSnapshot) {
        if (dataSnapshot.snapshot.value.toString() == "accepted") {
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
          print("Trip request accepted by driver.");
        }
      });

      if (requestTimeoutDriver == 0) {
        timer.cancel();
        currentDriverRef.set("timeout");
        currentDriverRef.onDisconnect();
        requestTimeoutDriver = 20;

        // Send notification to the next nearest available driver
        searchDriver();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.white,
        child: Drawer(
          backgroundColor: Colors.white,
          child: ListView(
            children: [
              const Divider(
                height: 1,
                color: Colors.black,
                thickness: 1,
              ),

              //header
              Container(
                color: Colors.white,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.blue,
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
                color: Colors.black,
                thickness: 1,
              ),

              const SizedBox(
                height: 10,
              ),

              //body
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PersonalDetailsDisplayPage()),
                  );
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PersonalDetailsDisplayPage()),
                      );
                    },
                    icon: const Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                  ),
                  title: const Text(
                    "Personal details",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),

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
                      color: Colors.black,
                    ),
                  ),
                  title: const Text(
                    "History",
                    style: TextStyle(color: Colors.black),
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
                      color: Colors.black,
                    ),
                  ),
                  title: const Text(
                    "About",
                    style: TextStyle(color: Colors.black),
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
                      color: Colors.black,
                    ),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.black),
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
            myLocationButtonEnabled: true,
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
              print("before getcurrentlivelocationofuser");
              getCurrentLiveLocationOfUser();
              print("after getcurrentlivelocationofuser");
            },
          ),

          // if (isAssigningDriver) ...[
          //   Opacity(
          //     opacity: 0.7, // Adjust the opacity as needed
          //     child: Container(
          //       color: Colors.black, // Black color with opacity
          //       child: const Center(
          //         child: Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             CircularProgressIndicator(),
          //             SizedBox(height: 20),
          //             Text(
          //               "Finding Near by  Drivers...",
          //               style: TextStyle(
          //                 fontSize: 18,
          //                 color: Colors.white, // Text color set to white
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ],

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
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          /// payment details

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
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (c) => MainPage()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.home,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24)),
                    child: const Icon(
                      Icons.work,
                      color: Colors.black,
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
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? "Distance: "
                                            : "Distance: ",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .black, // Color for non-number part
                                        ),
                                      ),
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? "${tripDirectionDetailsInfo!.distanceTextString!}"
                                            : "0 km",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .blue, // Color for number part
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? "Time: "
                                            : "Time: ",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .black, // Color for non-number part
                                        ),
                                      ),
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? "${tripDirectionDetailsInfo!.durationTextString!}"
                                            : "0 \$",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .blue, // Color for number part
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Distribute space evenly between children
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center children vertically
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      stateOfApp = "requesting";
                                    });
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MobilityAidsPage(
                                          onFormSubmitted: () async {
                                            Navigator.pop(context);
                                    print(
                                        "before handlePaymentAndRedirect called ");
                                    handlePaymentAndRedirect();
                                    print(
                                        "after handlePaymentAndRedirect called ");
                                    // //   print(paymentPending);
                                    //   print(
                                    //       "before presentPaymentSheet called");
                                    //  presentPaymentSheet();
                                    // print(
                                    //     "after displayRequestContainer");
                                    // print(nearbyOnlineDriversList);
                                    // availableNearbyOnlineDriversList =
                                    //     ManageDriversMethod
                                    //         .nearbyOnlineDriversList;
                                    // print(
                                    //     availableNearbyOnlineDriversList);
                                    // print("ManageDriversMethod1");

                                    // // Search for a driver
                                    // searchDriver();
                                    // print(searchDriver);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    "assets/images/uberexec.png",
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? "${tripDirectionDetailsInfo!.durationTextString!}"
                                            : "0",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .blue, // Blue color for numeric part
                                        ),
                                      ),
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? " away"
                                            : " away",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .black, // Black color for the rest of the text
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: (tripDirectionDetailsInfo != null)
                                            ? " \$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!))}"
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .blue, // Blue color for numeric part
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
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
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
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
                    const Text(
                      "Connecting To Driver.....",
                      style: TextStyle(color: Colors.blue),
                    ),
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
                color: Colors.white, // Changed to white background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12, // Changed to a lighter shadow
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

                    // Trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: const TextStyle(
                            fontSize: 19,
                            color: Colors.black, // Changed text color to black
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    const Divider(
                      height: 1,
                      color: Colors
                          .black12, // Changed divider color to match new theme
                      thickness: 1,
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    // Image - driver name and driver car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            photoDriver.isEmpty
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
                                color:
                                    Colors.black, // Changed text color to black
                              ),
                            ),
                            Text(
                              carDetialsDriver,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors
                                    .blue, // Slightly lighter black for car details
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
                      color: Colors
                          .black12, // Changed divider color to match new theme
                      thickness: 1,
                    ),

                    const SizedBox(
                      height: 19,
                    ),

                    // Call driver button
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
                                  color: Colors
                                      .blue, // Changed button background color to blue
                                  border: Border.all(
                                    width: 1,
                                    color: Colors
                                        .blue, // Changed button border color to blue
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors
                                      .white, // Changed icon color to white
                                ),
                              ),
                              const SizedBox(
                                height: 11,
                              ),
                              const Text(
                                "Call",
                                style: TextStyle(
                                  color:
                                      Colors.blue, // Changed text color to blue
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
          )
        ],
      ),
    );
  }
}
