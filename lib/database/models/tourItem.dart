/**
 *
 * Name: String
 * Tour: Int (Tour Id)
 *
 */

import 'dart:convert';

TourItem tourItemFromJson(String str) {
  final jsonData = json.decode(str);
  return TourItem.fromMap(jsonData);
}

String tourItemToJson(TourItem data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class TourItem {
  int id;
  String name;
  String info;
  DateTime timestamp;
  String latlng;
  List images;
  String createdAt;
  int markerId;

  TourItem({
    this.id,
    this.name,
    this.info,
    this.timestamp,
    this.latlng,
    this.images,
    this.createdAt,
    this.markerId,
  });

  factory TourItem.fromMap(Map<String, dynamic> json) => new TourItem(
    id: json["id"],
    name: json["name"],
    info: json["info"],
    timestamp: DateTime.parse(json['timestamp']),
    latlng: json['latlng'],
    images: json['images'],
    createdAt: json['createdAt'],
    markerId: json['markerId'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "info": info,
    "timestamp": timestamp.toIso8601String(),
    "latlng": latlng,
    "images": jsonEncode(images),
    "createdAt": createdAt,
    "markerId" : markerId,
  };

}