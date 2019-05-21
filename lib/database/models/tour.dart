

import 'dart:convert';

Tour tourFromJson(String str) {
  final jsonData = json.decode(str);
  return Tour.fromMap(jsonData);
}

String tourToJson(Tour data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}


class Tour {

  int id;
  String name;
  String description;
  DateTime timestamp;
  bool open;
  String location;
  String tourImage;
  String options;
  String coords;
  String track;
  String items;
  String createdAt;

  Tour({
    this.id,
    this.name,
    this.description,
    this.timestamp,
    this.open,
    this.location,
    this.tourImage,
    this.options,
    this.coords,
    this.track,
    this.items,
    this.createdAt,
  });

  factory Tour.fromMap(Map<String, dynamic> json) => new Tour(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    timestamp: DateTime.parse(json['timestamp']),
    location: json["location"],
    tourImage: json["tourImage"],
    open: json["open"] == 1,
    options: json['options'],
    coords: json['coords'],
    track: json['track'],
    items: json['items'],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "description": description,
    "timestamp": timestamp != null ?? timestamp.toIso8601String(),
    "open": open,
    "location": location,
    "tourImage": tourImage,
    "options": options,
    "coords": coords,
    "track": track,
    "items": items,
    "createdAt": createdAt,
  };

  //
  getOption( String optionsIdentifier ) {
    if (options == null) {
      return null;
    }

    var tourOptions = json.decode(options);

    return (tourOptions[optionsIdentifier]);
  }
}

