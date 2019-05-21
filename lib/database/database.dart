import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:tours_app/database/models/user.dart';
import 'package:tours_app/database/models/tour.dart';
import 'models/tourItem.dart';
import 'models/tourCoord.dart';

import 'userTable.dart';
import 'tourTable.dart';
import 'tourItemTable.dart';

/// private constructor - Singleton

class DBProvider {
  final dataBaseName = "TestDB.db";

  UserTable _userTable;
  TourTable _tourTable;
  TourItemTable _tourItemTable;

  //String _dbState = "notSet";

  /// Database tables
  /// User
  /// Tour
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;


  Future<Database> get database async {
    if (_database != null)
      return _database;

    // init db connection
    _userTable = UserTable();
    _tourTable = TourTable();
    _tourItemTable = TourItemTable();
    _database = await _initDB(dataBaseName);


    return _database;
  }

  /// create database
  /// create tables USER, TOURS ...
  _initDB(dbName) async {
    print("initDB: $dbName");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
          var _userTableState;
          _userTableState = await _userTable.createUserTable(db);
          print("initDB.createUserTable: $_userTableState");
          var _tourTableState;
          _tourTableState = _tourTable.createTourTable(db);
          print("initDB.createTourTable: $_tourTableState");
//          var _tourItemTableState = _tourItemTable.createTourItemTable(db);
//          print("initDB.createTourItemTable: $_tourItemTableState");
        }
    );
  }

  deleteTable(String tableName) async {
    final db = await database;
    var result = await db.rawQuery("DROP TABLE IF EXISTS " + tableName);
    //var result = await db.delete(tableName);
    print("deleteTable $tableName with result $result");
  }

  /// User Table
  ///
  newUser(User newUser) async {
    final db = await database;
    return _userTable.newUser(db, newUser);
  }


  userBlockOrUnblock(User user) async {
    final db = await database;
    return _userTable.UserBlockOrUnblock(db, user);
  }


  Future<List<User>> getAllUsers() async {
    print("DBProvider.getAllUsers");
    final db = await database;
    return _userTable.getAllUsers(db);
  }


  deleteUser(int id) async {
    final db = await database;
    return _userTable.deleteUser(db, id);
  }

  /// Tour Table
  ///

  newTour(Tour newTour) async {
    final db = await database;
    return _tourTable.newTour(db, newTour);
  }

  updateTour(Tour tour) async {
    final db = await database;
    return _tourTable.updateTour(db, tour);
  }

  deleteTour(int id) async {
    final db = await database;
    return _tourTable.deleteTour(db, id);
  }

  Future<List<Tour>> getAllTours() async {
    final db = await database;
    return _tourTable.getAllTours(db);
  }

  isTableExisting(String tablename) async {
    final db = await database;
    return _tourTable.isTableExisting(db, tablename);
  }

  tourExists(String tourname) async {
    final db = await database;
    return _tourTable.tourExists(db, tourname);
  }


  /// TourItem

  addTourItem(TourItem newTourItem, tourItemTable) async {
    final db = await database;
    return _tourItemTable.addTourItem(db, newTourItem, tourItemTable);
  }

  Future<List<TourItem>> getTourItems(String tourItemTable) async {
    final db = await database;
    return _tourItemTable.getTourItems(db, tourItemTable);
  }

  Future<List<TourItem>> getTourItem( String tableName,  String prop,  dynamic value) async {
    final db = await database;
    return _tourItemTable.getTourItem(db, tableName, prop, value);
  }

  /// TourCoords

  addTourCoord(TourCoord newTourCoord, tourCoordTable) async {
    final db = await database;
    return _tourTable.addTourCoords(db, newTourCoord, tourCoordTable);
  }

  insertTourCoords(TourCoord tourCoord, tourCoordTable, index) async {
    final db = await database;
    return _tourTable.insertTourCoords(db, tourCoord, tourCoordTable, index);
  }

  Future<List<TourCoord>> getTourCoords(String tourCoordTable) async {
    final db = await database;
    return _tourTable.getTourCoords(db, tourCoordTable);
  }

  deleteTourCoord(int id, String tourCoordTable) async {
    final db = await database;
    return _tourTable.deleteTourCoord(db, tourCoordTable, id);
  }

  updateTourCoord(int id, String tourCoordTable, String prop, dynamic val ) async {
    final db = await database;
    return _tourTable.updateTourCoord(db, tourCoordTable, id, prop, val);
  }

//  updateTourCoord(int id, double speed, String tourCoordTable) async {
//    final db = await database;
//    return _tourTable.updateTourCoord(db, tourCoordTable, id, speed);
//  }

  /// generic update methode

}