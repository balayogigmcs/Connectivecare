import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/models/address_model.dart';
import 'package:cccc/models/prediction_model.dart';
import 'package:cccc/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cccc/global/global_var.dart';

class PredictionPlaceUi extends StatefulWidget {
  PredictionModel? predictedPlaceData;

  PredictionPlaceUi({super.key, this.predictedPlaceData});

  @override
  State<PredictionPlaceUi> createState() => _PredictionPlaceUiState();
}

class _PredictionPlaceUiState extends State<PredictionPlaceUi> {
// place details api
  fetchClickedPlaceDetails(String placeId) async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Getting Details ..."));

    String urlPlaceDetailsApi =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapKey";

    var responceFromPlaceDetailsApi =
        await CommonMethods.sendRequestToAPI(urlPlaceDetailsApi);

    Navigator.pop(context);
    if (responceFromPlaceDetailsApi == "error") {
      return;
    }
    if (responceFromPlaceDetailsApi["status"] == "OK") {
      AddressModel dropOffLocation = AddressModel();

      dropOffLocation.placeName = responceFromPlaceDetailsApi["result"]["name"];
      dropOffLocation.latitudePositon =
          responceFromPlaceDetailsApi["result"]["geometry"]["location"]["lat"];
      dropOffLocation.longitudePosition =
          responceFromPlaceDetailsApi["result"]["geometry"]["location"]["lng"];
      dropOffLocation.placeId = placeId;

      Provider.of<Appinfo>(context, listen: false)
          .updateDropOffLocation(dropOffLocation);

      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          fetchClickedPlaceDetails(
              widget.predictedPlaceData!.place_id.toString());
        },
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
