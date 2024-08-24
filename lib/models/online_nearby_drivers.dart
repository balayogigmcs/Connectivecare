class OnlineNearbyDrivers{

  String? uidDriver;
  double? latDriver;
  double? lngDriver;

  OnlineNearbyDrivers({
    this.uidDriver,
    this.latDriver,
    this.lngDriver
  });

  // Factory method to create an instance from JSON
  factory OnlineNearbyDrivers.fromJson(Map<String, dynamic> json) {
    return OnlineNearbyDrivers(
      uidDriver: json['uidDriver'],
      latDriver: (json['latDriver'] as num?)?.toDouble(),
      lngDriver: (json['lngDriver'] as num?)?.toDouble(),
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'uidDriver': uidDriver,
      'latDriver': latDriver,
      'lngDriver': lngDriver,
    };
  }
}
