import 'package:cccc/models/online_nearby_drivers.dart';

class ManageDriversMethod {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverID) {
    int index = nearbyOnlineDriversList
        .indexWhere((driver) => driver.uidDriver == driverID);

    if (index != -1 && nearbyOnlineDriversList.isNotEmpty) {
      print("Removing driver with ID: $driverID");
      nearbyOnlineDriversList.removeAt(index);
    } else {
      print("Driver with ID: $driverID not found in the list for removal.");
    }
  }

  static void updateOnlineNearbyDriversLocation(
      OnlineNearbyDrivers nearbyOnlineDriversInformation) {
    int index = nearbyOnlineDriversList.indexWhere((driver) =>
        driver.uidDriver == nearbyOnlineDriversInformation.uidDriver);

    if (index != -1) {
      print("Updating location for driver with ID: ${nearbyOnlineDriversInformation.uidDriver}");
      nearbyOnlineDriversList[index].latDriver =
          nearbyOnlineDriversInformation.latDriver;
      nearbyOnlineDriversList[index].lngDriver =
          nearbyOnlineDriversInformation.lngDriver;
    } else {
      // If the driver is not found, add the driver to the list
      print('Driver not found in the list for updating location. Adding driver with ID: ${nearbyOnlineDriversInformation.uidDriver} to the list.');
      nearbyOnlineDriversList.add(nearbyOnlineDriversInformation);
    }
  }
}
