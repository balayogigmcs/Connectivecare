import 'dart:convert';

import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/global/global_var.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:provider/provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson ={dotenv.env["SERVICE_ACCOUNT_JSON"];}

  //  {
    //   "type": "service_account",
    //   "project_id": "cccc-4b8a5",
    //   "private_key_id": "b4f1a6f963a7de0e2b9c27d58821ce6ca1f60b7b",
    //   "private_key":
    //       "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCRkTliQLlghIwF\n23MlatJ+SCMZmZzMhZ/u2hjU+/CRoG4jMKQhEJfqfUd7WLxQRG3dx+e4A/4+z5aU\nY64odar8EYjYw2eTTh9DTkkkxyHoD2+MZ/yGP8jSWEvLcIfwwVz4MVjlGFSFs9LO\nkVbqy30s04szU11Ax9tIpR0ueC6/rF0yIMec2kszfRft/ZY053f3MLS3iCOYfD3W\ncPu1z9V9kOoyEzkN2Zf27RPizHQTNS/WU19dSfPFSyj0crpAuqCpl5Fq8ZzOFHnW\nK+ND7cYHIZczIvtFDzSgyM93EYuQwJjdlV02mN8NJxECnISVoeyIw1qRXz2GNgCe\nC0g6mi6DAgMBAAECggEAHT8379lARber6Htcib6KN0woHTsjaWZJqXRRe+14utGo\nf1KFD42lcDwmkg5Um638AwzorizDNvx/bSYP9loZ9hZRz/eGxm5yUpQWlxiZY+ZC\nC8xSzOhg4X5TEDd2YLWBB+7mRPVb+hcUumMyOu+SoWCJfdD4kgz1roVaNR15ixH5\nY+3A3ogH8DJXv4Q1V9D5iTkh1slS80Ez5gq4Xk9vP0u0O0iA4Ze1Pj1qf7BNYtt6\nEPKmqzh9z2beiH6Cp7+8rEsWn/Wp0CZ9U3xnQU4/iQBSOXmItOjg8OhzY/BIbWFe\npfv5P4tB6q/Rreypmv0EHfjwrThqyDtOF4KkGoVYqQKBgQDLa2JIdsCwu5Tp4FHh\n7aGv0D3io1nAKE319kJQA8qoERu8WAyzIr5trGNWUdpIzYp8pL3vKezIqQI/OrZV\njcTTMiW6aSQGihzL5Ns/FnxhWD6OYLOTljXuaFy0FpA4AMkijF2mq7uXEiIIA1Kw\ngnRmNiEo2nHJ1q635/dIpu/fuQKBgQC3MalbjhifRptWVHCTHrN5s1qehU9WcxWY\nrkrVeamJkEo4zq+z2QiBFxKOvRKxl6zNGfKwSwWBM21CvhSPHbUfCLptbWhqjeEe\nIc7hy1Rtl6WfhPlXUuWkZpHMfnYt3I1HulFSt9fHp+42i22SVFqoJFxnqZaxWihk\nWfLWj6lGGwKBgH+g9X5fu9BnMSx4SQfGz95+eoWbVfGBmECNbNfFOT6v1UYbvIQc\ndXxcX8tF+f4ZsB06Q80t8dmIaNeBH+uX0nlsCk3mL+tGdoDbK1Bu7EUrV7x/Icyk\nv1vA8QEw8vWgUJIznYK4Vy+W+fErHJOQljWXGsEGJcSsxNywVu+nhfNJAoGAa+uF\nqbn8J1ihCiqUZxcfBAL0z44ZPwRtJJUI4NnbVn76Op0IRRsGN4YwGIaqDJUd53Xx\n0olfpM13AGqaEfWeTboGmZBqgtsyU133Um1GP4mmuGLNwPPE9SS3n5CgbkQPtsG8\nRs6m/6eeXeOlmR64iXViOm9dpv1F7lhPBrd7MSECgYEAhYUh//EeOMSklyokVuaj\nvAgBIkKl2f8BxnFHZNpmXbS3+JrKdwg5ZzPelUywjYOFlVqqDIu2RM7HGF/k9CxE\nR0K0/eZBaGtSMRXON1gPzYUSqW5ivr6x6+g23JnRg3dY9pRwsDVML19+VjrGGavN\nlUgJq1uNlL70DwYG3TRk5Xk=\n-----END PRIVATE KEY-----\n",
    //   "client_email": "connectivecare@cccc-4b8a5.iam.gserviceaccount.com",
    //   "client_id": "111936843876643959391",
    //   "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    //   "token_uri": "https://oauth2.googleapis.com/token",
    //   "auth_provider_x509_cert_url":
    //       "https://www.googleapis.com/oauth2/v1/certs",
    //   "client_x509_cert_url":
    //       "https://www.googleapis.com/robot/v1/metadata/x509/connectivecare%40cccc-4b8a5.iam.gserviceaccount.com",
    //   "universe_domain": "googleapis.com"
    // };
        // dotenv.env['SERVICE_ACCOUNT_JSON'] ?? 'ServiceAccountJson Not found';
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    // get the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
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

    final Map<String, dynamic> messsage = {
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
            body: jsonEncode(messsage));

    if (response.statusCode == 200) {
      print('Notification sent Successfully');
    } else {
      print('Failed Notification, Not Sent : ${response.statusCode}');
    }
  }
}
