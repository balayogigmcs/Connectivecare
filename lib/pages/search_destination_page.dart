import 'package:cccc/appinfo/appinfo.dart';
import 'package:cccc/global/global_var.dart';
import 'package:cccc/methods/common_methods.dart';
import 'package:cccc/models/prediction_model.dart';
import 'package:cccc/widgets/prediction_place_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();

  List<PredictionModel> dropOffPredictionPlacesList = [];

//place API - auto complete
  searchLocation(String locationName) async {
    // print("search Location started");
    // print(locationName);
    if (locationName.length > 1) {
      String apiPlaceUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:us";
      // print("API URL: $apiPlaceUrl");
      // print("api link");
      var responsesFromPlacesApi =
          await CommonMethods.sendRequestToAPI(apiPlaceUrl);

      // print("API Response: $responsesFromPlacesApi"); // Log the response

      if (responsesFromPlacesApi == "error") {
        return;
      }
      if (responsesFromPlacesApi["status"] == "OK") {
        var predictionResultInJson = responsesFromPlacesApi["predictions"];
        print("Predictions");
        var predictionList = (predictionResultInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionPlacesList = predictionList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = "";
    final pickUpLocation = Provider.of<Appinfo>(context).pickUpLocation;
    if (pickUpLocation != null) {
      userAddress = pickUpLocation.humanReadableAddress ?? "";
    } else {
      print("pickUpLocation is null");
    }

    pickUpTextEditingController.text = userAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFD1D1D1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]),
                child: Padding(
                  padding:
                      EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 6,
                      ),
                      // icon button title
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                          Center(
                              child: Text(
                            'Set Dropoff Location',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ))
                        ],
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      // Pickup
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            height: 18,
                          ),
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(5)),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TextField(
                                controller: pickUpTextEditingController,
                                decoration: const InputDecoration(
                                    hintText: "Pickup Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        left: 11, top: 9, bottom: 9)),
                              ),
                            ),
                          ))
                        ],
                      ),
                      const SizedBox(
                        height: 11,
                      ),

                      // Destination
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(
                            height: 18,
                          ),
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(5)),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TextField(
                                controller: destinationTextEditingController,
                                onChanged: (inputText) {
                                  searchLocation(inputText);
                                },
                                decoration: const InputDecoration(
                                    hintText: "DropOff Address",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(
                                        left: 11, top: 9, bottom: 9)),
                              ),
                            ),
                          ))
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            (dropOffPredictionPlacesList.length > 0)
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0),
                      itemBuilder: (context, index) {
                        return Card(
                            elevation: 3,
                            child: PredictionPlaceUi(
                              predictedPlaceData:
                                  dropOffPredictionPlacesList[index],
                            ));
                      },
                      separatorBuilder: (BuildContext context, index) =>
                          const SizedBox(
                        height: 2,
                      ),
                      itemCount: dropOffPredictionPlacesList.length,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
