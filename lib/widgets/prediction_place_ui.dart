import 'package:cccc/models/prediction_model.dart';
import 'package:flutter/material.dart';

class PredictionPlaceUi extends StatefulWidget {
  PredictionModel? predictedPlaceData;

  PredictionPlaceUi({super.key, this.predictedPlaceData});

  @override
  State<PredictionPlaceUi> createState() => _PredictionPlaceUiState();
}

class _PredictionPlaceUiState extends State<PredictionPlaceUi> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
        child: Container(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Icon(
                    Icons.share_location,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    width: 13,
                  ),
                  Expanded(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.predictedPlaceData!.main_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        widget.predictedPlaceData!.secondary_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      )
                    ],
                  ))
                ],
              ),
              const SizedBox(
                height: 10,
              )
            ],
          ),
        ));
  }
}
