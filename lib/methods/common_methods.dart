// import 'dart:convert';

// import 'package:cccc/appinfo/appinfo.dart';
// import 'package:cccc/global/global_var.dart';
// import 'package:cccc/models/address_model.dart';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:cccc/models/direction_details.dart';

// class CommonMethods {
//   checkConnectivity(BuildContext context) async {
//     var connectionResult = await Connectivity().checkConnectivity();

//     if (connectionResult != ConnectivityResult.mobile &&
//         connectionResult != ConnectivityResult.wifi) {
//       if (!context.mounted) return;
//       displaySnackbar('check internet connection', context);
//     }
//   }

//   displaySnackbar(String messageText, BuildContext context) {
//     var snackbar = SnackBar(content: Text(messageText));
//     ScaffoldMessenger.of(context).showSnackBar(snackbar);
//   }

//   static sendRequestToAPI(String apiUrl) async {
//     http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

//     try {
//       if (responseFromAPI.statusCode == 200) {
//         String dataFromApi = responseFromAPI.body;
//         var dataDecoded = jsonDecode(dataFromApi);
//         return dataDecoded;
//       } else {
//         return "error";
//       }
//     } catch (errorMsg) {
//       return "error";
//     }
//   }

// // reverse geocoding
//   static Future<String> convertGeoGraphicCodingIntoHumanReadableAddress(
//       Position position, BuildContext context) async {
//     String humanReadableAddress = "";

//     String apiGeoCodingUrl =
//         "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

//     var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

//     if (responseFromAPI != "error") {
//       humanReadableAddress = responseFromAPI["results"][0]["formatted_address"];

//       AddressModel model = AddressModel();
//       model.humanReadableAddress = humanReadableAddress;
//       model.placeName = humanReadableAddress;
//       model.latitudePositon = position.latitude;
//       model.longitudePosition = position.longitude;

//       Provider.of<Appinfo>(context, listen: false).updatePickUpLocation(model);
//     }
//     return humanReadableAddress;
//   }

//   // DIRECTION API
//   static Future<DirectionDetails?> getDirectionDetailsFromAPI(
//     LatLng source, LatLng destination) async {
//   String urlDirectionsAPI =
//       "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

//   var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

//   if (responseFromDirectionsAPI == "error") {
//     return null;
//   }

//   // Validate the response
//   if (responseFromDirectionsAPI["routes"] == null || responseFromDirectionsAPI["routes"].isEmpty ||
//       responseFromDirectionsAPI["routes"][0]["legs"] == null || responseFromDirectionsAPI["routes"][0]["legs"].isEmpty) {
//     return null;
//   }

//   DirectionDetails detailsModel = DirectionDetails();
//   detailsModel.distanceTextString =
//       responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"] ?? "";
//   detailsModel.distanceValueDigits =
//       responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"] ?? 0;
//   detailsModel.durationTextString =
//       responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"] ?? "";
//   detailsModel.durationValueDigits =
//       responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"] ?? 0;

//   detailsModel.encodePoints =
//       responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"] ?? "";

//   return detailsModel;
// }

//   calculateFareAmount(DirectionDetails directionDetails) {
//     double distancePerKmAmount = 0.4;
//     double durationPerMinuteAmount = 0.3;
//     double baseFareAmount = 2;

//     double totalDistanceTravelFareAmount =
//         (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;

//     double totalDurationSpendFareAmount = (directionDetails.durationValueDigits!/60) * durationPerMinuteAmount;

//     double totalOverAllFareAmount = baseFareAmount + totalDistanceTravelFareAmount +totalDurationSpendFareAmount;

//     return totalOverAllFareAmount.toStringAsFixed(1);
//   }
// }

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/global/global_var.dart';
import 'package:http/http.dart' as http;
import 'package:cccc/models/address_model.dart';

import '../models/direction_details.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackbar(
          "your Internet is not Available. Check your connection. Try Again.",
          context);
    }
  }

  displaySnackbar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Future<dynamic> sendRequestToAPI(String apiUrl) async {
    try {
      print("entered into SendRequestToApi");
      final responseFromAPI = await http.get(Uri.parse(apiUrl));
      print("responseFromAPI = $responseFromAPI ");

      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded; // Returning the decoded data
      } else {
        return null; // Returning null in case of an error
      }
    } catch (errorMsg) {
      print("Error occurred: $errorMsg");
      return null; // Returning null if an exception occurs
    }
  }


  ///Reverse GeoCoding
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";
    String apiGeoCodingUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

    var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

    if (responseFromAPI != "error") {
      
      humanReadableAddress = responseFromAPI["results"][0]["formatted_address"];

      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.placeName = humanReadableAddress;
      model.longitudePosition = position.longitude;
      model.latitudePositon = position.latitude;

      // Check if Appinfo is available
      final appInfoProvider = Provider.of<Appinfo>(context, listen: false);
      if (appInfoProvider != null) {
        appInfoProvider.updatePickUpLocation(model);
      } else {
        print("Appinfo provider not found");
      }
    }

    return humanReadableAddress;
  }

  ///Directions API
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
        print("entered into getDirectionDetailsFromApi");
    String urlDirectionsAPI =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&mode=driving&key=$googleMapKey";

    print(urlDirectionsAPI);
    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if (responseFromDirectionsAPI == "error") {
      print(" responseFromDirectionsAPI  is error ");
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();

    detailsModel.distanceTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["text"];
        print(detailsModel.distanceTextString);
    detailsModel.distanceValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["distance"]["value"];
        print(detailsModel.distanceValueDigits);

    detailsModel.durationTextString =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["text"];
        print(detailsModel.durationTextString);
    detailsModel.durationValueDigits =
        responseFromDirectionsAPI["routes"][0]["legs"][0]["duration"]["value"];
        print(detailsModel.durationValueDigits);

    detailsModel.encodePoints =
        responseFromDirectionsAPI["routes"][0]["overview_polyline"]["points"];
        print(detailsModel.encodePoints);

    return detailsModel;
  }

  double calculateFareAmount(DirectionDetails directionDetails) {
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;
    double baseFareAmount = 2;

    double totalDistanceTravelFareAmount =
        (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount =
        (directionDetails.durationValueDigits! / 60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount +
        totalDistanceTravelFareAmount +
        totalDurationSpendFareAmount;

    return double.parse(overAllTotalFareAmount.toStringAsFixed(1));
  }

  // void addMarker(LatLng position, String markerId, BuildContext context) {
  //   if (kIsWeb) {
  //     // Web-specific code using AdvancedMarkerElement
  //     final mapDiv = html.querySelector('#map');
  //     if (mapDiv != null) {
  //       final advancedMarker = html.document.createElement('div')
  //         ..setAttribute('style',
  //             'position: absolute; width: 40px; height: 40px; background-color: red; border-radius: 50%;')
  //         ..setInnerHtml(
  //             '<div style="background-color: blue; width: 100%; height: 100%; border-radius: 50%;"></div>');
  //       mapDiv.append(advancedMarker);
  //       // Position and additional settings for the marker could be set here
  //     }
  //   } else {
  //     // Mobile-specific code using GoogleMap's Marker
  //     Marker marker = Marker(
  //       markerId: MarkerId(markerId),
  //       position: position,
  //       infoWindow: InfoWindow(title: "Location"),
  //       icon: BitmapDescriptor.defaultMarker,
  //     );
  //     // Assuming `controllerGoogleMap` is your GoogleMapController

  //     if (controllerGoogleMap != null) {
  //     controllerGoogleMap.addMarker(marker);
  //   } else {
  //     print("GoogleMapController is not initialized");
  //   }
  //   }
  // }
}
