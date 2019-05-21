
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database.dart';

class DBAdmin extends StatelessWidget {

  static Database _database;

  DBAdmin() {
    getDatabase();
  }

  String dbName;

  getDatabase() async {
    if ( DBProvider.db != null ) {
      print(DBProvider.db.dataBaseName);
      dbName = DBProvider.db.dataBaseName;

      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, dbName);
      _database = await openDatabase(path, version: 1, onOpen: (db) {},);

      print(await _database.query("sqlite_master"));

      print(await _database.query("TOUR"));
      // which tables exist
//      if (_database != null) {
//        _database.rawQuery(sql)
//      }
      //var result = await DBProvider.db.rawQuery()
    }
  }




  void init() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DB Admin Tool"),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 24.0, top: 12.0),
        child: Column(
          children: <Widget>[
            Text(dbName),


          ],
        ),
      )
    );
  }


}