import 'models/user.dart';
import 'package:sqflite/sqflite.dart';

class UserTable {

  UserTable();

  //await db.execute("CREATE TABLE USER ("
//          "id INTEGER PRIMARY KEY,"
//          "first_name TEXT,"
//          "last_name TEXT,"
//          "blocked BIT"
//      ")");

//  createUserTable(Database db) async {
//    print("createUserTable");
//    //final db = await database;
//    try {
//        await db.execute( 'CREATE TABLE USER ( id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, blocked BIT)');
//        print("collection User create ok");
//        return "collection User create ok";
//    } on DatabaseException catch (e) {
//      print("sqlite error: $e");
//      return false;
//    }
//    return true;
//  }


  createUserTable(Database db) async {
    print("createUserTable");
    //final db = await database;
    try {
      var res = db.transaction((txn) async {
        await txn.execute("CREATE TABLE USER (id INTEGER PRIMARY KEY, first_name TEXT, last_name TEXT, blocked BIT )" );
        print("collection User create ok");
        return "collection User create ok";
      });
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
    return true;
  }


  newUser(Database db, User newUser) async {
    print("db newUser");

    // get biggest id in the table
    var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM USER");
    int id = table.first["id"];
    // insert into the table using new id
    var raw = await db.rawInsert(
        "INSERT Into USER (id, first_name, last_name, blocked)"
            " VALUES (?,?,?,?)",
        [id, newUser.firstName, newUser.lastName, newUser.blocked]
    );
    return raw;
  }


  Future<List<User>> getAllUsers(Database db) async {
    print("UserTable.getAllUsers");
    var res = await db.query("User");

    print( res );
    List<User> list = res.isNotEmpty ? res.map((c) => User.fromMap(c)).toList() : [];

    print(list);
    return list;
  }

  deleteUser(Database db, int id) async {
    return db.delete("User", where: "id = ?", whereArgs: [id]);
  }


  UserBlockOrUnblock(Database db, User user) async {

    User blocked = User(
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        blocked: !user.blocked
    );
    var res = await db.update("User", blocked.toMap(),
        where: "id = ?", whereArgs: [user.id]);
    return res;
  }
}