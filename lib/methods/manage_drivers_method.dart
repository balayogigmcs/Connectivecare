import 'package:cccc/models/online_nearby_drivers.dart';

class ManageDriversMethod {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverID) {
    int index = nearbyOnlineDriversList
        .indexWhere((driver) => driver.uidDriver == driverID);

    if (nearbyOnlineDriversList.length > 0) {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  static void updateOnlineNearbyDriversLocation(
      OnlineNearbyDrivers nearbyOnlineDriversInformation) {
    int index = nearbyOnlineDriversList.indexWhere((driver) =>
        driver.uidDriver == nearbyOnlineDriversInformation.uidDriver);

    nearbyOnlineDriversList[index].latDriver =
        nearbyOnlineDriversInformation.latDriver;
    nearbyOnlineDriversList[index].lngDriver =
        nearbyOnlineDriversInformation.lngDriver;
  }
}
