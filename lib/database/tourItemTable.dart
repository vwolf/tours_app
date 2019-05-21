import 'package:sqflite/sqflite.dart';
import 'models/tourItem.dart';

class TourItemTable {
  TourItemTable();

  createTourItemTable(Database db, String tourName) async {
    print("createTourItemTable");
    String tourItemTableName = "TourItem_" + tourName;
    try {
      var res = db.transaction((txn) async {
        await txn.execute("CREATE TABLE " +
            tourItemTableName +
            "(id INTEGER PRIMARY KEY,"
            "name TEXT,"
            "info TEXT,"
            "timestamp TEXT,"
            "latlng TEXT,"
            "images TEXT,"
            "createdAt TEXT,"
            "markerId INTEGER"
            ")"
        );
      });
      return tourItemTableName;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
  }

  addTourItem(Database db, TourItem newTourItem, String tourItemTable) async {
    print("db newTourItem");
    var table =
        await db.rawQuery("SELECT MAX(id)+1 as id FROM " + tourItemTable);
    newTourItem.id = table.first["id"];
    newTourItem.timestamp = DateTime.now();
    newTourItem.createdAt = DateTime.now().toIso8601String();
    // insert
    var res = await db.insert(tourItemTable, newTourItem.toMap());
    return res;
  }


  updateTourItem(Database db, TourItem tourItem) async {}

  updateTourItemProperty(Database db, String tourItemTable, String prop, dynamic val) {}


  Future<List<TourItem>> getTourItems(
      Database db, String tourCoordTable) async {
    print("getTourCoords");
    try {
      var res = await db.query(tourCoordTable);
      List<TourItem> list =
          res.isNotEmpty ? res.map((c) => TourItem.fromMap(c)).toList() : [];

      return list;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }

    return [];
  }


  Future<List<TourItem>> getTourItem(Database db, String tableName, String prop, dynamic value ) async {
    print("getTourItem with $prop = $value");
    String query = "SELECT $prop FROM $tableName WHERE $prop = value";
    try {
      var result = await db.query(query);
      List<TourItem> tourItem = result.isNotEmpty ? result.map((c) => TourItem.fromMap(c)).toList() : [];
      return tourItem;
    } on DatabaseException catch (e) {
      print("DatabaseException $e");
    }
    return [];
  }
}
