class DirectionDetails {
  String? distanceTextString;
  String? durationTextString;
  int? distanceValueDigits;
  int? durationValueDigits;
  String? encodePoints;

  DirectionDetails({
    this.distanceTextString,
    this.distanceValueDigits,
    this.durationTextString,
    this.durationValueDigits,
    this.encodePoints,
  });

  // Convert a DirectionDetails instance to a Map (for JSON encoding)
  Map<String, dynamic> toJson() {
    return {
      'distanceTextString': distanceTextString,
      'durationTextString': durationTextString,
      'distanceValueDigits': distanceValueDigits,
      'durationValueDigits': durationValueDigits,
      'encodePoints': encodePoints,
    };
  }

  // Create a DirectionDetails instance from a Map (for JSON decoding)
  static DirectionDetails fromJson(Map<String, dynamic> json) {
    return DirectionDetails(
      distanceTextString: json['distanceTextString'],
      durationTextString: json['durationTextString'],
      distanceValueDigits: json['distanceValueDigits'],
      durationValueDigits: json['durationValueDigits'],
      encodePoints: json['encodePoints'],
    );
  }
}
