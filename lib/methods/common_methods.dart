import 'dart:convert';

import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/global/global_var.dart';
import 'package:cccc/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackbar('check internet connection', context);
    }
  }

  displaySnackbar(String messageText, BuildContext context) {
    var snackbar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

// reverse geocoding
  static Future<String> convertGeoGraphicCodingIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";

    String apiGeoCodingUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

    var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

    if (responseFromAPI != "error") {
      humanReadableAddress = responseFromAPI["results"][0]["formatted_address"];
      
      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.latitudePositon = position.latitude;
      model.longitudePosition  = position.longitude;

      Provider.of<Appinfo>(context,listen: false).updatePickUpLocation(model);

    }
    return humanReadableAddress;
  }
}
