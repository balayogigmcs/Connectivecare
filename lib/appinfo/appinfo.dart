import 'package:cccc/models/address_model.dart';
import 'package:flutter/material.dart';


class Appinfo extends ChangeNotifier{

  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickUpLocation(AddressModel pickUpModel){
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel){
    pickUpLocation = dropOffModel;
    notifyListeners();
  }


}