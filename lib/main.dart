import 'package:flutter/material.dart';

import 'tour_list.dart';
import 'tour_new.dart';
import 'tour_newtrack.dart';
import 'map/location.dart';
import 'user_list.dart';
import 'database/models/tour.dart';
import 'database/dbadmin.dart';

//import 'package:mongo_dart/mongo_dart.dart';
import 'tour/tour_write.dart';
import 'tour_swipelist/tour_swipe_widget.dart';
import 'xml/gpx_writer.dart';

void main() => runApp(MyApp());

/// This widget is the root of your application.
class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tours',
      //theme: new ThemeData(brightness: Brightness.dark),
      theme: ThemeData(brightness: Brightness.dark),
      home: ToursHomePage(title: 'Tours Home Page'),
    );
  }
}


/// Homepage of tour app.
class ToursHomePage extends StatefulWidget {
  ToursHomePage({Key key, this.title}) : super(key: key);

  /// AppBar title string
  final String title;

  @override
  ToursHomePageState createState() => ToursHomePageState();
}


/// State for TourHomePage
class ToursHomePageState extends State<ToursHomePage> {


  List<Tour> initialTours = []
    ..add(Tour(id: 1, name: 'Bergslagsleden', open: false, location: 'Schweden'))
    ..add(Tour(id: 2, name: 'Bohusleden', open: false, location: 'Schweden'));

  /// Navigate to page User.
  goUser() {
    print('showUserListPage');

    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) {
          return new UserListPage();
    }));
  }

  /// Navigate to page NewTour.
  goNewTour() {
    print("goNewTour");

    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return new TourNewPage(Tour());
      })
    );
  }

  /// Load track .gpx format
  loadTrack() {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return new TourNewTrack();
      })
    );
  }

  /// load map with current position
  showPosition() {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return new Location();
      })
    );
  }

  /// database tool
  dbAdmin() {
     Navigator.of(context).push(
       new MaterialPageRoute(builder: (context) {
         return new DBAdmin();
       })
     );
  }

  connectMongoDB() {
   // DBProvider.db.database;
  }

  writeTest() async {
    /// write to local
//    try {
//      await WriteTour().writeTour(2);
//      var readResult = await WriteTour().readTour();
//      print ("readResult: $readResult");
//
//    } catch (e) {
//      print("writeTest error $e");
//    }

    /// write to external storage

    /// create directory
    bool result = await WriteTourExternal().makeFolder("/tour");
    print(result);

    /// write file
    WriteTourExternal().writeToFile("tour/data.gpx", "data and data");

    /// read file
    String content = await ReadFileExternal().readFile("/tour/data.gpx");
    print (content);
  }

  writeTestXml() {
    GpxWriter gpxWriter = GpxWriter();

    //gpxWriter.buildGpx();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.account_circle), onPressed: (){goUser();}),
        ],
      ),
      body: Container(
        //child: TourList( initialTours ),
        child: TourList(),
      ),

//      body: new Center(
//        child: new ListView.builder(
//          itemBuilder: (BuildContext context, int index) {
//            return new OnSlide(
//              items: <ActionItems>[
//                new ActionItems(
//                  icon: new IconButton(
//                      icon: new Icon(Icons.archive),
//                      onPressed: () {},
//                      color: Colors.green,
//                  ),
//                  onPress: () {}, backgroundColor: Colors.white
//                ),
//                new ActionItems(
//                    icon: new IconButton(
//                      icon: new Icon(Icons.delete),
//                      onPressed: () {},
//                      color: Colors.red,
//                    ),
//                    onPress: () {}, backgroundColor: Colors.white
//                ),
//              ],
//              child: new Container(
//                padding: const EdgeInsets.only(top: 10.0),
//                width: 200.0,
//                height: 150.0,
//                child: new Card(
//                  child: new Row(
//                    children: <Widget>[
//                      new Text("Demo Card")
//                    ],
//                  )
//                ),
//              ),
//
//            );
//          },
//        )
//      ),

      /// temporäre row of buttons
      persistentFooterButtons: <Widget>[
          FloatingActionButton(
            heroTag: "newTour",
            child: Icon(Icons.add),
            onPressed: () {
              goNewTour();
            },
          ),
          FloatingActionButton(
             heroTag: "newTrack",
             child: Icon(Icons.add_location),
             onPressed: () {
                loadTrack();
             },
            ),

          FloatingActionButton(
            heroTag: "showPos",
            child: Icon(Icons.gps_fixed),
            onPressed: () {
              showPosition();
            },
          ),
          FloatingActionButton(
            heroTag: "showDBTool",
            child: Icon(Icons.dashboard),
            onPressed: () {
              dbAdmin();
            },
          ),
            FloatingActionButton(
              heroTag: "mongodb",
              child: Icon(Icons.build),
              onPressed: () {
                connectMongoDB();
              },
          ),
            FloatingActionButton(
              heroTag: "write-read",
              child: Icon(Icons.create),
              onPressed: () {
                writeTestXml();
              },
            )
//        ),

      ],

      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
