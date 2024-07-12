class AddressModel {
  String? humanReadableAddress;
  double? latitudePositon;
  double? longitudePosition;
  String? placeId;
  String? placeName;

  AddressModel(
      {this.humanReadableAddress,
      this.latitudePositon,
      this.longitudePosition,
      this.placeId,
      this.placeName});
}
