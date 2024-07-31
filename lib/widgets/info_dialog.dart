import 'package:cccc/pages/homepage.dart';
import 'package:flutter/material.dart';

class InfoDialog extends StatefulWidget {
  String? title;
  String? description;

  InfoDialog({super.key, this.title, this.description});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white60,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 12,
                ),
                Text(
                  widget.title.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.white60),
                ),
                const SizedBox(
                  height: 27,
                ),
                Text(
                  widget.description.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.white60,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 32,
                ),
                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Restart.restartApp();
                        Navigator.push(context, MaterialPageRoute(builder:(BuildContext context) => Homepage()));
                      },
                      child: Text("OK")),
                ),
                const SizedBox(
                  height: 12,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
