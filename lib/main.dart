import 'dart:async';

import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/authentication/login_screen.dart';
import 'package:cccc/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await dotenv.load(); // Load environment variables

  await Firebase.initializeApp();

  // Request location permission if not already granted
  if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Appinfo(),
      child: Consumer<Appinfo>(
        builder: (_, appInfo, child) {
          return MaterialApp(
            title: 'Users App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.white,
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                headlineMedium: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black),
                bodyMedium: TextStyle(fontSize: 14.0, color: Colors.blue),
                labelLarge: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white),
                bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white),
                labelLarge: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            themeMode: appInfo.themeMode,
            home: FirebaseAuth.instance.currentUser == null
                ? LoginScreen()
                : Homepage(),
          );
        },
      ),
    );
  }
}
