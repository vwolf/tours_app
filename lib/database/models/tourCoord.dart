import 'dart:convert';

///
TourCoord tourCoordFromJson(String str) {
  final jsonData = json.decode(str);
  return TourCoord.fromMap(jsonData);
}

String tourCoordToJson(TourCoord data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}


class TourCoord {
  int id;
  double latitude;
  double longitude;
  double altitude;
  DateTime timestamp;
  double accuracy;
  double heading;
  double speed;
  double speedAccuracy;
  int item;

  TourCoord({
    this.id,
    this.latitude,
    this.longitude,
    this.altitude,
    this.timestamp,
    this.accuracy,
    this.heading,
    this.speed,
    this.speedAccuracy,
    this.item,
  });

  factory TourCoord.fromMap(Map<String, dynamic> json) => TourCoord(
    id: json["id"],
    latitude: json['latitude'],
    longitude: json['longitude'],
    altitude: json['altitude'],
    timestamp: DateTime.parse(json['timestamp']),
    accuracy: json['accuracy'],
    heading: json['heading'],
    speed: json['speed'],
    speedAccuracy: json['speedAccuracy'],
    item: json['item'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "latitude": latitude,
    "longitude": longitude,
    "altitude": altitude,
    "timestamp": timestamp.toIso8601String(),
    "accuracy": accuracy,
    "heading": heading,
    "speed": speed,
    "speedAccuracy": speedAccuracy,
    "item": item,
  };

}
