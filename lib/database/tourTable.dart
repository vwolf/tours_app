import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'models/tour.dart';
import 'models/tourCoord.dart';
import 'models/tourItem.dart';
import 'tourItemTable.dart';

class TourTable {
  TourTable();

  createTourTable(Database db) async {
    print("createTourTable");

    try {
      var res = db.transaction((txn) async {
        await txn.execute("CREATE TABLE TOUR ("
            "id INTEGER PRIMARY KEY,"
            "name TEXT,"
            "description TEXT,"
            "timestamp TEXT,"
            "open BIT,"
            "location TEXT,"
            "tourImage TEXT,"
            "options TEXT,"
            "coords TEXT,"
            "track TEXT,"
            "items TEXT,"
            "createdAt TEXT )");
      });
      print("collection Tour create ok: $res");
      return res;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
  }

  /// Tour names have to be unique

  newTour(Database db, Tour newTour) async {
    print("db newTour");
    // get biggest id in the table
    var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM TOUR");
    int id = table.first["id"];
    // join all parts of tourname with '_'
    var modTourname = newTour.name.replaceAll(new RegExp(r' '), '_');
    // create trackTable for tour
    var createTableResult = await createTourTrackTable(db, modTourname);
    print("CreateTourTrackTable: " + createTableResult);
    newTour.track = createTableResult;

    var createTableItems = await createTourItemTable(db, modTourname);
    print("CreateTourItemTable: " + createTableItems);
    newTour.items = createTableItems;

    // insert into the table using new id
    print("Start insert new Tour");
    newTour.id = id;
    newTour.createdAt = DateTime.now().toIso8601String();
    var res = await db.insert("TOUR", newTour.toMap());
    return res;
  }

  /// createdAt: date string ISO8601

  createTourTrackTable(Database db, String tourName) async {
    String tourTrackTableName = "TourTrack_" + tourName;
    try {
      var res = db.transaction((txn) async {
        await txn.execute("CREATE TABLE " +
            tourTrackTableName +
            " (id INTEGER PRIMARY KEY,"
            "latitude REAL,"
            "longitude REAL,"
            "altitude REAL,"
            "timestamp TEXT,"
            "accuracy REAL,"
            "heading REAL,"
            "speed REAL,"
            "speedAccuracy REAL,"
            "item INTEGER"
            ")");
      });
      return tourTrackTableName;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
  }

  createTourItemTable(Database db, String tourName) async {
    String tourItemTableName = "TourItem_" + tourName;
    return await TourItemTable().createTourItemTable(db, tourName);
  }

  updateTour(Database db, Tour tour) async {
    print("updateTour");
    try {
      var res = await db
          .update("TOUR", tour.toMap(), where: "id = ?", whereArgs: [tour.id]);
      return 1;
    } on DatabaseException catch (e) {
      print("sqlite error $e");
    }
    return 0;
    //return await db.update("TOUR", tour.toMap(), where: "id = ?", whereArgs: [tour.id]);
  }

  addCoord(Database db, String coord) async {
    try {
      return 1;
    } on DatabaseException catch (e) {
      print("sqlite error $e");
    }
    return 0;
  }

  deleteTour(Database db, int id) async {
    print("deleteTour with id $id");
    return db.delete("Tour", where: "id = ?", whereArgs: [id]);
  }

  Future<List<Tour>> getAllTours(Database db) async {
    print("getAllTours");
    try {
      var res = await db.query("TOUR");
      List<Tour> list =
          res.isNotEmpty ? res.map((c) => Tour.fromMap(c)).toList() : [];

      print(list);
      return list;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }

    return [];
  }

  Future<int> isTableExisting(Database db, String tablename) async {
    var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name= ?",
        [tablename]);
    if (result.length > 0) {
      print("table $tablename exists");
      return result.length;
    } else {
      print("table $tablename does not exists");
      var tableCreated = await createTourTable(db);
      if (tableCreated == true) {
        return 1;
      }
    }
    return null;
  }

  Future<int> tourExists(Database db, String query) async {
    try {
      List<Map> maps =
          await db.rawQuery("SELECT id FROM TOUR WHERE name = ? ", [query]);
      if (maps.length > 0) {
        return maps.length;
      }
    } on DatabaseException catch (e) {
      print("Sqlite error: $e");
    }
    return null;
  }

  /// TourCoords functions - extra file?
  ///

  addTourCoords(Database db, TourCoord tourCoord, String tourCoordTable) async {
    print("db addTourCoords");
    String query = "SELECT MAX(id)+1 as id FROM " + tourCoordTable;
    var table = await db.rawQuery(query);
    int id = table.first["id"];

    // insert
    tourCoord.id = id;
    var res = await db.insert(tourCoordTable, tourCoord.toMap());
    return res;
  }

  /// Insert new TourCoord at index index
  /// First increase all TourCoords with higher index
  /// Now insert TourCoord mit id = index
  insertTourCoords(Database db, TourCoord tourCoord, String tourCoordTable,
      int index) async {
    print(" insertTourCoords");

    /// get highest id
    String query = "SELECT MAX(id) as id FROM " + tourCoordTable;
    var table = await db.rawQuery(query);
    int maxId = table.first["id"];

    for (int i = maxId; i >= index; i--) {
      await db
          .rawUpdate("UPDATE $tourCoordTable SET id = $i + 1 WHERE id = $i");
    }

    /// now insert new tourCoord
    try {
      tourCoord.id = index;
      var res = await db.insert(tourCoordTable, tourCoord.toMap());
      print("insertTourCoord insert result: $res");
    } on DatabaseException catch (e) {
      print("sqlite error $e");
    }
  }

  Future<List<TourCoord>> getTourCoords(
      Database db, String tourCoordTable) async {
    print("getTourCoords");
    try {
      var res = await db.query(tourCoordTable);
      List<TourCoord> list =
          res.isNotEmpty ? res.map((c) => TourCoord.fromMap(c)).toList() : [];

      print(list);
      return list;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }

    return [];
  }

  /// Delete tourCoord at index id.
  /// Update following id's of following tourCoord's (decrease by 1)
  /// TourCoord has item then update item with coords
  deleteTourCoord(Database db, String tourCoordTable, int id) async {
    try {
      var res =
          await db.delete(tourCoordTable, where: "id = ?", whereArgs: [id]);
      print("deleteTourCoord res: $res");
      String query = "UPDATE $tourCoordTable SET id = id - 1 WHERE id > $id";
      await db.rawUpdate(query);
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }
  }

  /// Update one value in tourCoords table
  /// #Set or remove id of item
  updateTourCoord(Database db, String tableName, int id, String prop, dynamic val) async {
    String query = "UPDATE $tableName SET $prop = $val WHERE id = $id";
    try {
      var res = await db.rawUpdate(query);
      print ("updateTourCoord $res");
    } on DatabaseException catch (e) {
      print ("DatabaseException $e");
    }
  }
//  updateTourCoord(
//      Database db, String tourCoordTable, int id, double speed) async {
//    String query = "UPDATE $tourCoordTable SET speed = $speed WHERE id < $id";
//    try {
//      var res = await db.rawUpdate(query);
//      print("updateTourCoord result: $res");
//    } on DatabaseException catch (e) {
//      print("sqlite error $e");
//    }
//  }

}


