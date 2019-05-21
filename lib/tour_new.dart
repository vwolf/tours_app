/// New Tour page
///
/// Make new tour from scratch or load .gpx file
///
/// tour and savedtour and then newTour???
/// Create form

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'database/database.dart';
import 'database/models/tour.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

import 'package:path/path.dart' as p;
import 'xml/read_file.dart';
import 'xml/gpx_parser.dart';
import './services/geolocation.dart';
import './tour/tour_service.dart';
import 'archive/tour_from_extern.dart';
import './database/models/tourCoord.dart';
import './database/models/tourItem.dart';


class TourNewPage extends StatefulWidget {
  final Tour tour;

  void submitTourPage(BuildContext context) {
    print("submitTour()");
    print(context);
  }

  TourNewPage(this.tour);

  @override
  _TourNewPageState createState() => _TourNewPageState(tour);
}

class _TourNewPageState extends State<TourNewPage> {
  Tour tour;
  _TourNewPageState(this.tour);

  // form key and controller
  final _formkey = GlobalKey<FormState>();
  final _formNameController = TextEditingController();
  final _formDescriptionController = TextEditingController();
  final _formLocationController = TextEditingController();
  final _formStartLatitudeController = TextEditingController();
  final _formStartLongitudeController = TextEditingController();

  Tour savedTour;
  File _image;
  bool _formsaved = false;
  String _gpxFilePath;
  String _offlineMapPath;
  bool _newTour = true;

  @override
  void initState() {
    super.initState();
    if (tour.name != null) {
      _newTour = false;
      _formsaved = true;
      _formNameController.text = tour.name;
      _formDescriptionController.text = tour.description;
      _formLocationController.text = tour.location;
      if (tour.coords != null) {
        LatLng tourCoords = GeolocationService.gls.fromLatlngJson(tour.coords);
        _formStartLatitudeController.text = tourCoords.latitude.toString();
        _formStartLongitudeController.text = tourCoords.longitude.toString();
      } else {
        _formStartLatitudeController.text = "0.0";
        _formStartLongitudeController.text = "0.0";
      }

      if (tour.options != null) {
        _gpxFilePath = tour.getOption('_gpxFilePath');
        _offlineMapPath = tour.getOption('_offlineMapPath');
      }
      savedTour = tour;
    } else {
      _formStartLatitudeController.text = "0.0";
      _formStartLongitudeController.text = "0.0";
    }
  }

  @override
  void dispose() {
    _formNameController.dispose();
    super.dispose();
  }

  void _formState() {
    _formsaved = !_formsaved;
  }

  Future getImage() async {
    if (_formsaved) {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      print('Selected image is $image.path');
      setState(() {
        _image = image;
        // Todo save image to db
        savedTour.tourImage = _image.path;
        print(savedTour);

        DBProvider.db.updateTour(savedTour);
      });
    } else {
      return null;
    }
  }

  /// Read track data from .gpx file5
  ///
  ///
  Future getTrack() async {
    // first get filePath and save in _gpxFilePath
    final fp = await ReadFile().getPath();
    print(fp);
    String fileType = p.extension(fp);
    if (fileType != '.gpx') {
      print('Wrong file type');
      return null;
    }
    _gpxFilePath = fp;

    // read file
    final fc = await ReadFile().readFile(fp);
    print(fc);

    // parse file
    //TourGpxData tourGpxData = new TourGpxData();
    GpxFileData tourGpxData = GpxFileData();
    tourGpxData = await new GpxParser(fc).parseData();
    print(tourGpxData.gpxCoords.length);
    // fill form text fields
    _formNameController.text = tourGpxData.tourName;
    _formDescriptionController.text = tourGpxData.trackName;
    _formLocationController.text = tourGpxData.tourName;

    // translate first point to an address
    GpxCoords firstPoint = tourGpxData.gpxCoords[0];

    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(
        firstPoint.lat, firstPoint.lon,
        localeIdentifier: "de_DE");
    print(placemark);
    if (placemark.isNotEmpty && placemark != null) {
      String loc = placemark[0].country + ", " + placemark[0].locality;
      _formLocationController.text = loc;
    }

    // use first point as startCoords
    _formStartLatitudeController.text = firstPoint.lat.toString();
    _formStartLongitudeController.text = firstPoint.lon.toString();
  }

  /// Try to get current geo position
  getStartCoord() async {
    LatLng currentPosition = await GeolocationService.gls.simpleLocation();
    print(currentPosition);
    _formStartLatitudeController.text = currentPosition.latitude.toString();
    _formStartLongitudeController.text = currentPosition.longitude.toString();
  }

  // if static function no instance member access
  Future submitEvent(int i) async {
    print("form submit event $i");
    // check if tourname is unique

    var tourExists = await DBProvider.db.tourExists(_formNameController.text);
    if (tourExists != null) {
      print("Tour with name exists - update tour");
      /// TODO implement update
      var result = await DBProvider.db.updateTour(tour);
      // check if tour name has changed - if yes, update the name track and item table
      // create new table, copy data to new table, delete old tables
      return false;
    }

    if (_formkey.currentState.validate()) {
      Tour newTour = Tour(
        name: _formNameController.text,
        description: _formDescriptionController.text,
        location: _formLocationController.text,
        open: false,
      );

      // start coordinates
      //LatLng startCoords = LatLng(double.parse(_formStartLatitudeController.text), double.parse(_formStartLongitudeController.text));
      //var latlngObj = { "lat": double.parse(_formStartLatitudeController.text), "lon": double.parse(_formStartLongitudeController.text) };
      var latlngObj = {
        "lat": _formStartLatitudeController.text,
        "lon": _formStartLongitudeController.text
      };
      var latlngJson = jsonEncode(latlngObj);
      newTour.coords = latlngJson;

      if (_gpxFilePath != null) {
        newTour.options = jsonEncode({"_gpxFilePath": _gpxFilePath});
      }

      print(newTour.location);
      newTour.timestamp = DateTime.now();

      print("Database table check");
      var result = await DBProvider.db.isTableExisting("TOUR");
      print(result);
      if (result > 0) {
        await DBProvider.db.newTour(newTour);
        savedTour = newTour;
        _formsaved = true;
        setState(() {});
        return true;
      }
    }
    return false;
    //DBProvider.db.createTourTable();
  }

  /// Load a saved tour
  /// User TourServices to write coords to db
  loadFromExternal() async {
    TourDirectory tourDirectory = TourDirectory();
    final tourExists = await tourDirectory.getDirectory();
    if (tourExists) {
      /// Get tour data
      Tour tourData = await tourDirectory.readTour();
      _formNameController.text = tourData.name;
      _formDescriptionController.text = tourData.description;
      _formLocationController.text = tourData.location;

      LatLng tourCoords = GeolocationService.gls.fromLatlngJson(tourData.coords);
      _formStartLatitudeController.text = tourCoords.latitude.toString();
      _formStartLongitudeController.text = tourCoords.longitude.toString();
      setState(() { });

      bool result = await submitEvent(0);
      if ( result == true) {
        print ("next step here");

        /// Save track to db, user TourServices
        TourServices tourServices = TourServices(savedTour);
        List<TourCoord> coords = await tourDirectory.readTourCoords();
        if (coords.length > 0) {
          for (var coord in coords) {
            //print(coord.id);
            await tourServices.addTourCoord(coord, tourData.track);
          }
        }
      }


      /// Save items to db
//      List<TourItem> items = await tourDirectory.readTourItems();
//      if (items.length > 0) {
//        for (var item in items) {
//          tourServices.saveItem(item, item.markerId);
//        }
//      }
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _newTour == true ? Text("New Tour") : Text("Update Tour"),
        ),
        body: ListView(
          children: <Widget>[
            _form,
            _tourImage,
            _trackinfo,
            _loadFromStorage,
          ],
        ));
  }

  Widget get _form {
    return Form(
      key: _formkey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
          Widget>[
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              controller: _formNameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: 'Enter name'),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a name.';
                }
              },
              maxLines: 1,
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextFormField(
            controller: _formDescriptionController,
            //textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: 'Enter Description'),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
            },
            maxLines: null,
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
                controller: _formLocationController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: 'Enter Location Name'),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter a loction name';
                  }
                })),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text('Start Coordinates'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: TextFormField(
                  decoration: InputDecoration(labelText: "Latitude"),
                  keyboardType: TextInputType.number,
                  controller: _formStartLatitudeController,
                ),
              ),
              new Flexible(
                child: TextFormField(
                  decoration: InputDecoration(labelText: "Longitude"),
                  keyboardType: TextInputType.number,
                  controller: _formStartLongitudeController,
                ),
              ),
              FlatButton.icon(
                icon: Icon(Icons.add),
                onPressed: getStartCoord,
                label: Text(" "),
              )
            ],
          ),
        ),
        Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SubmitBtnWithState(submitEvent, 'Processing'),
                RaisedButton(
                  child: Text('Load from GPX'),
                  onPressed: getTrack,
                ),
                FlatButton.icon(
                  onPressed: _formsaved == true ? getImage : null,
                  icon: new Icon(Icons.image),
                  label: Text('Add Image'),
                  disabledColor: Colors.black26,
                ),
              ],
            )),
      ]),
    );
  }

  Widget get _tourImage {
    if (tour.tourImage != null) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Container(
            height: 80.0,
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(
                  fit: BoxFit.fitHeight,
                  image: AssetImage(savedTour.tourImage),
                )),
          ));
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  Widget get _trackinfo {
    if (_gpxFilePath != null) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            //mainAxisSize: MainAxisSize.max,

            children: <Widget>[
              Text("File with GPS track"),
              Icon(Icons.check_box),
              Expanded(
                child: Text(_gpxFilePath),
              )
            ],
          ));
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  Widget get _loadFromStorage {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: RaisedButton(
            child: Text("Load Saved Tour"),
            onPressed: loadFromExternal
        ));
  }

  Widget get _offlineMap {
    if (_offlineMapPath != null) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: <Widget>[
              Text("Path to Offline map"),
              Expanded(
                child: Text(_offlineMapPath),
              ),
            ],
          ));
    } else {
      return Container(
        height: 0.0,
      );
    }
  }
//  Widget get _infos {
//    return Column(
//      crossAxisAlignment: CrossAxisAlignment.start,
//      children: <Widget>[
//        Padding(
//          padding: const EdgeInsets.symmetric(horizontal: 16.0),
//          child: Row(
//            children: <Widget>[
//              Text("File with GPS track"),
//              Icon(Icons.check_box),
//            ],
//          )
//        ),
//        Padding(
//          padding: const EdgeInsets.symmetric(horizontal: 16.0),
//          child: Row(
//            children: <Widget>[
//              Text("Offline Map"),
//            ],
//          ),
//        )
//      ],
//    );
//    return Padding(
//      padding: const EdgeInsets.symmetric(horizontal: 16.0),
//      child: Row(
//        children: <Widget>[
//          Text("File with GPS track"),
//          Icon(Icons.check_box),
//        ],
//      ),
//    );
//  }
}

//new IconButton(icon: new Icon(Icons.account_circle), onPressed: (){goUser();}),
/// Button which triggers a SnackBar
class SubmitBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SubmitBtn navigator =
        context.ancestorWidgetOfExactType(_TourNewPageState);

    return RaisedButton(
      child: Text('Submit'),
      onPressed: () {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Processing data"),
          duration: Duration(seconds: 3),
        ));
      },
    );
  }
}

typedef void StringCallback(String val);

/// Button which triggers a SnackBar using stateful widget
/// btnText: String
class SubmitBtnWithState extends StatefulWidget {
  final void Function(int) callback;
  //final StringCallback callback;
  final String btnText;

  SubmitBtnWithState(this.callback, this.btnText);

  @override
  _SubmitBtnWithState createState() => _SubmitBtnWithState();
}

class _SubmitBtnWithState extends State<SubmitBtnWithState> {
  void submitTour(BuildContext context) {
    print("submitTour()");
    print(context);
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('Submit'),
      onPressed: () {
        widget.callback(1);
        submitTour(context);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(widget.btnText),
          duration: Duration(seconds: 2),
        ));
      },
    );
  }
}
