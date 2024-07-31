import 'package:cccc/methods/common_methods.dart';
import 'package:flutter/material.dart';

class TripCompletion extends StatefulWidget {
  String? fareAmount;
  TripCompletion({super.key, required this.fareAmount});

  @override
  State<TripCompletion> createState() => _TripCompletionState();
}

class _TripCompletionState extends State<TripCompletion> {

  CommonMethods cmethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black54,
        child: Container(
          margin: EdgeInsets.all(4),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 21,
              ),
              Text(
                "PAY CASHing",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(
                height: 21,
              ),
              const Divider(
                thickness: 1,
                height: 1.5,
                color: Colors.white70,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "\$ ${widget.fareAmount}!",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                 "This is the fare amount (\$ ${widget.fareAmount}!) you have to pay to the driver", // Updated text with correct syntax
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey,fontSize: 16),
                ),
              ),
              const SizedBox(
                height: 31,
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, "PAID");
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('PAY CASH')),
              const SizedBox(
                height: 41,
              ),
            ],
          ),
        ));
  }
}
