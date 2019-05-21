
import 'package:flutter/material.dart';
import 'package:tours_app/database/database.dart';
import 'package:tours_app/database/models/tour.dart';
import 'package:tours_app/database/models/tourCoord.dart';
import 'package:tours_app/database/models/tourItem.dart';

import '../tour/tour_write.dart';
import '../xml/gpx_writer.dart';

/// Save a tour to external storage
/// Tours are saved to directory TourData
class TourToExternal extends StatefulWidget {
  TourToExternal(this.tour);

  final Tour tour;

  _TourToExternalState createState() => _TourToExternalState();
}


class _TourToExternalState extends State<TourToExternal> {

  final _formkey = GlobalKey<FormState>();

  /// Save tour data
  saveTour() async {
    String directoryName = '/Tours/${widget.tour.name}';
    String fileName = "tour.txt";
    String tour_json = tourToJson(widget.tour);
    print(tour_json);
    String filePath = '$directoryName/$fileName';
    try {
      final directoryCreated = await WriteTourExternal().makeFolder('$directoryName');
      if (directoryCreated == true) {
        await WriteTourExternal().writeToFile(filePath, tour_json);
      }
    } catch (e) {
      print(e);
    }

    /// Now save track coords to track file as json string
    /// Always create new track file
//    if (widget.tour.track != null) {
//      List<TourCoord> tourCoords =  await DBProvider.db.getTourCoords(widget.tour.track);
//
//      var openFile = await WriteTourExternal().openFile('$directoryName/track.txt');
//      var fileLength = await openFile.length();
//      print("openFile.length: $fileLength");
//
//      var sink = openFile.openWrite();
//      //var sink = openFile.openWrite(mode: FileMode.append);
//
//      for ( var coord in tourCoords ) {
//        print(tourCoordToJson(coord));
//
//        sink.write(tourCoordToJson(coord));
//        sink.write('\n');
//      }
//      sink.close();
//    }

    /// Save track as *.gpx file im xml format
    if (widget.tour.track != null) {
      List<TourCoord> tourCoords = await DBProvider.db.getTourCoords(widget.tour.track);
      var openFile = await WriteTourExternal().openFile('$directoryName/track.gpx');
      var sink = openFile.openWrite();

      GpxWriter gpxWriter = GpxWriter();
      var xml = gpxWriter.buildGpx(tourCoords);

      sink.write(xml);
      sink.close();
    }
    
    
    /// Save tour items to items file
    if (widget.tour.items != null) {
      List<TourItem> tourItems = await DBProvider.db.getTourItems(widget.tour.items);
      if (tourItems.length > 0) {

      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save Tour"),
      ),
      body: ListView(
        children: <Widget>[
          _info,
          _form,
        ],
      )
    );
  }

  Widget get _form {
    return Form(
      key: _formkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('SAVE'),
                  onPressed: saveTour,
                ),
                RaisedButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          )
        ],
      )
    );
  }

  Widget get _info {
    return Container(
      margin: EdgeInsets.only(left: 12.0, top: 12.0),
      child: Text('Save tour \n  ${widget.tour.name}, (${widget.tour.location})\n'
          'permanent to external storage.',
        style: TextStyle(
          fontSize: 18.0,
        ),
      ),
    );
  }

}