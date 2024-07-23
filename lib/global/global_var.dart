import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userID  = FirebaseAuth.instance.currentUser!.uid;

String googleMapKey = "AIzaSyDCF3-Nl94jUPeUuDdpjT92DO3IjZF655o";

const CameraPosition googlePlexInitialPositon = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

