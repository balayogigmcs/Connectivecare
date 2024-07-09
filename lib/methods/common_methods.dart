import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
          if(!context.mounted) return;
      displaySnackbar('check internet connection', context);
    }
  }

  displaySnackbar(String messageText, BuildContext context) {
    var snackbar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
