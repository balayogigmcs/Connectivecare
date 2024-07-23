import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Developed by",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.grey,
            )),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset("assets/images/logo.png"),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                "This app is developed Mohan Chandra Satya Balayogi Gorripati",
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Padding(
              padding:  EdgeInsets.all(8.0),
              child: Text(
                "In case of any issue contact balayogigorripati@gmail.com",
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 22,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
