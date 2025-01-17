import 'package:cccc/authentication/login_screen.dart';
import 'package:cccc/forms/personaldetails.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  CommonMethods cmethods = CommonMethods();

  checkIfNetworkAvailable() {
    cmethods.checkConnectivity(context);

    signUpFormValidation();
  }

  signUpFormValidation() {
    String email = emailTextEditingController.text.trim();
    if (phoneTextEditingController.text.trim().length < 10) {
      cmethods.displaySnackbar(
          'Your Phone number must be atleast 10 characters', context);
    } else if (!email.contains('@')) {
      cmethods.displaySnackbar('Please enter email address', context);
    } else if (passwordTextEditingController.text.trim().length < 6) {
      cmethods.displaySnackbar(
          'Your Password must be atleast 6 characters', context);
    } else {
      registerNewUser();
    }
  }

  registerNewUser() async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: " Registering Account"));

    final User? userFirebase = (await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailTextEditingController.text.trim(),
                password: passwordTextEditingController.text.trim())
            .catchError((errorMsg) {
      Navigator.pop(context);
      cmethods.displaySnackbar(errorMsg.toString(), context);
    }))
        .user;
    if (!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference usersRef =
        FirebaseDatabase.instance.ref().child('users').child(userFirebase!.uid);

    Map userDataMap = {
      'email': emailTextEditingController.text.trim(),
      'phone': phoneTextEditingController.text.trim(),
      'uid': userFirebase.uid,
      'blockStatus': "no"
    };
    usersRef.set(userDataMap);
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => PersonalDetails()));
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
              const Text(
                'Create User\'s Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    // TextField(
                    //   controller: usernameTextEditingController,
                    //   keyboardType: TextInputType.emailAddress,
                    //   decoration: InputDecoration(
                    //       labelText: ' username',
                    //       labelStyle: Theme.of(context).textTheme.bodyLarge),
                    // ),
                    // const SizedBox(
                    //   height: 22,
                    // ),
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
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: 'Phone number',
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
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: 'Re-enter password',
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
                        'Sign Up',
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
                                builder: (context) => LoginScreen()));
                      },
                      child: Text(
                        'Already have a account? Login here',
                        style: Theme.of(context).textTheme.bodyLarge,
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
