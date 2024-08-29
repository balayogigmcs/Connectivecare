import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:provider/provider.dart';
import '../appInfo/app_info.dart';
import '../global/global_var.dart';

///Updated in June 2024
///This PushNotificationService only you have to update with below code for new FCM Cloud Messaging V1 API
class PushNotificationService
{
  static Future<String> getAccessToken() async
  {
    final serviceAccountJson =
    {
      "please add your own service Account Json Here"
    };

    List<String> scopes =
    [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    //get the access token
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client
    );

    client.close();

    return credentials.accessToken.data;
  }

  static sendNotificationToSelectedDriver(String deviceToken, BuildContext context, String tripID) async
  {
    String dropOffDestinationAddress = Provider.of<AppInfo>(context, listen: false).dropOffLocation!.placeName.toString();
    String pickUpAddress = Provider.of<AppInfo>(context, listen: false).pickUpLocation!.placeName.toString();

    final String serverAccessTokenKey = await getAccessToken() ; // Your FCM server access token key
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/AddYourFirebaseProjectIDHere/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken, // Token of the device you want to send the message/notification to
        'notification': {
          "title": "NET TRIP REQUEST from $userName",
          "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress",
        },
        'data': {
          "tripID": tripID,
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessTokenKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }
}