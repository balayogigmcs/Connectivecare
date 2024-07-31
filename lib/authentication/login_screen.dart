import 'package:cccc/authentication/signup_screen.dart';
import 'package:cccc/forms/personaldetails.dart';
import 'package:cccc/global/global_var.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/pages/homepage.dart';
import 'package:cccc/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cmethods = CommonMethods();

  checkIfNetworkAvailable() {
    cmethods.checkConnectivity(context);

    signInFormValidation();
  }

  void signInFormValidation() {
    String email = emailTextEditingController.text.trim();
    String password = passwordTextEditingController.text.trim();

    if (!email.contains('@')) {
      cmethods.displaySnackbar('Please enter a valid email address', context);
    } else if (password.length < 6) {
      cmethods.displaySnackbar(
          'Your Password must be at least 6 characters', context);
    } else {
      signInForm();
    }
  }

  signInForm() async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: " Allowing user to Login"));

    final User? userFirebase = (await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text.trim(),
                password: passwordTextEditingController.text.trim())
            .catchError((errorMsg) {
      Navigator.pop(context);
      cmethods.displaySnackbar(errorMsg.toString(), context);
    }))
        .user;
    if (!context.mounted) return;
    Navigator.pop(context);

    if (userFirebase != null) {
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userFirebase.uid);
      usersRef.once().then((snap) {
        if (snap.snapshot.value != null) {
          if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => Homepage()));
          } else {
            FirebaseAuth.instance.signOut();
            cmethods.displaySnackbar(
                'Your are Blocked, Contact Admin', context);
          }
        } else {
          FirebaseAuth.instance.signOut();
          cmethods.displaySnackbar('Account doesn\'t exist', context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 200,
                  height: 200,
                ),
              ),
              Text(
                'Login As a User',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: ' email',
                          labelStyle: Theme.of(context).textTheme.bodyLarge),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: ' password',
                          labelStyle: Theme.of(context).textTheme.bodyLarge),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        checkIfNetworkAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10)),
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupScreen()));
                      },
                      child:  Text(
                        'Don\'t have a account? Register here',
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
