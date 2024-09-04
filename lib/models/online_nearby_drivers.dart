class OnlineNearbyDrivers {
  String? uidDriver;
  double? latDriver;
  double? lngDriver;

  OnlineNearbyDrivers({this.uidDriver, this.latDriver, this.lngDriver});

  factory OnlineNearbyDrivers.fromJson(Map<String, dynamic> json) {
    print("Deserializing OnlineNearbyDrivers from JSON: $json");
    return OnlineNearbyDrivers(
      uidDriver: json['uidDriver'],
      latDriver: (json['latDriver'] as num?)?.toDouble(),
      lngDriver: (json['lngDriver'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'uidDriver': uidDriver,
      'latDriver': latDriver,
      'lngDriver': lngDriver,
    };
    print("Serializing OnlineNearbyDrivers to JSON: $json");
    return json;
  }
}
