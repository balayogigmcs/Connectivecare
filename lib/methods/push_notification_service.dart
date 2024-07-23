import 'dart:convert';

import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/global/global_var.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson = dotenv.env['SERVICE_ACCOUNT_JSON'] ?? '{}';
    Map<String, dynamic> jsonCredentials = jsonDecode(serviceAccountJson);
    
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(jsonCredentials), scopes);

    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(jsonCredentials),
        scopes,
        client);

    client.close();
    return credentials.accessToken.data;
  }

  static sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    String pickUpAddress = Provider.of<Appinfo>(context, listen: false)
        .pickUpLocation!
        .placeName
        .toString();
    String dropOffDestinationAddress =
        Provider.of<Appinfo>(context, listen: false)
            .dropOffLocation!
            .placeName
            .toString();

    final String serverAccessTokenKey = await getAccessToken();

    String endpointFirebaseCloudMessaging =
        "https://fcm.googleapis.com/v1/projects/cccc-4b8a5/messages:send";

    final Map<String, dynamic> message = {
      'message': {
        "token": deviceToken,
        "notification": {
          "title": "NET TRIP REQUEST from $userName",
          "body":
              "Pickup Location: $pickUpAddress \nDropoff Location: $dropOffDestinationAddress",
        },
        'data': {'tripID': tripID}
      }
    };

    final http.Response response =
        await http.post(Uri.parse(endpointFirebaseCloudMessaging),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $serverAccessTokenKey'
            },
            body: jsonEncode(message));

    if (response.statusCode == 200) {
      print('Notification sent Successfully');
    } else {
      print('Failed Notification, Not Sent : ${response.statusCode}');
    }
  }
}
