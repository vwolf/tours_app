import 'package:flutter/material.dart';
import 'database/models/user.dart';
import 'database/database.dart';

import 'dart:math' as math;

class UserListPage extends StatefulWidget {

  @override

  _UserListPageState createState() => _UserListPageState();
}


class _UserListPageState extends State<UserListPage> {

  List<User> testUsers = [
    User(firstName: "Raouf", lastName: "Rahiche", blocked: false),
    User(firstName: "Zaki", lastName: "oun", blocked: true),
    User(firstName: "oussama", lastName: "ali", blocked: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
      ),
      body: FutureBuilder<List<User>>(
          future: DBProvider.db.getAllUsers(),
          builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  User item = snapshot.data[index];
                  return Dismissible(
                    key: UniqueKey(),
                    background: Container(color: Colors.red),
                    onDismissed: (direction) {
                      DBProvider.db.deleteUser(item.id);
                    },
                    child: ListTile(
                      title: Text(item.lastName),
                      leading: Text(item.id.toString()),
                      trailing: Checkbox(
                        onChanged: (bool value) {
                          DBProvider.db.userBlockOrUnblock(item);
                          setState(() {});
                        },
                        value: item.blocked,
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            User rnd = testUsers[math.Random().nextInt(testUsers.length)];
            await DBProvider.db.newUser(rnd);
            setState(() {});

          }
      ),
    );
  }
}