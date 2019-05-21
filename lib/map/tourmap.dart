/// Provide map view
///
/// Uses TourGpxData object for
/// - map center (first point in trackPoints list
/// _tourGpxData is inherited from tour_detail_page
///
/// tracksource can be:
///

///
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tours_app/tour_detail_page.dart';
import 'package:tours_app/services/geolocation.dart';
import './trackpoint_dialog.dart';
import './item_dialog.dart';
import '../tour/tour_service.dart';

import 'dragableMapLayer.dart';
import 'statusLayer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tours_app/database/models/tourItem.dart';

class TourMap extends StatefulWidget {
  final StreamController<StreamMsg> streamController;

  TourMap(this.streamController);

  @override
  _TourMapState createState() => _TourMapState(streamController);
}

//enum Answers{ADD,REMOVE,EDIT}

class _TourMapState extends State<TourMap> {
  StreamController<StreamMsg> streamController;
  StreamController trackerStreamController;

  _TourMapState(this.streamController);

  /// MaoController and plugin layers
  MapController mapController;
  DragableMapLayer _dragableMapLayer = DragableMapLayer();
  MapStatusLayer _mapStatusLayer = MapStatusLayer();

  MapTapAction _mapTapAction = MapTapAction.NOACTION;

  AddPointToPath _addPointToPath;

  bool _moveMarker = false;
  int _markerToMove;
  List<int> _activeMarker = [];
  bool displayGpxFileTrack = true;


  TourItem _tourItem = TourItem();

  @override
  void initState() {
    super.initState();
    mapController = new MapController();
    streamSetup();
  }

  @override
  void dispose() {
    streamController.close();
    if (trackerStreamController != null ) {
      trackerStreamController.close();
    }

    super.dispose();
  }

  LatLng get startPos => TourInherited.of(context).tourServices.getStartCoord();
  TourServices get _tourServices => TourInherited.of(context).tourServices;


  List<Marker> get markerList => makeMarkerList();
  List<GlobalKey> markerKeyList = [];

  List<Marker> makeMarkerList() {
    List<Marker>ml = [];
    //markerKeyList = [];
//    _tourServices.trackLatlngPoints.forEach((tpl) {
      for (var i = 0; i < _tourServices.trackLatlngPoints.length; i++ ) {
        Marker newMarker = new Marker(
          width: 40.0,
          height: 40.0,
          point: _tourServices.trackLatlngPoints[i],
          builder: (ctx) => new Container(
            //key: Key("mapmarker_${tpl.latitude}_${tpl.longitude}"),
            //key: makerKey,
            child: GestureDetector(
              onTap: () {
                _handleTapOnMarker(_tourServices.trackLatlngPoints[i]);
              },
              onLongPress: () {
                _handleLongPressOnMarker(ctx, _tourServices.trackLatlngPoints[i]);
              },
              child: new Icon(
                Icons.location_on,
                color: getIconColor(i),
                //color: _activeMarker.contains(i) ? Colors.redAccent : Colors.green,
                //color: _markerToMove != i ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
        );
        //print("tlp $tpl");
        ml.add(newMarker);
      }
//    });
    return ml;
  }

  streamSetup() {
    streamController.stream.listen((event) {
      onPageEvent(event);
    });
  }


  Color getIconColor(int trackPointIdx){
    if ( _activeMarker.contains(trackPointIdx)) {
      return Colors.redAccent;
    }

    if (_tourServices.trackPoints[trackPointIdx].item != null) {
      return Colors.orangeAccent;
    }
    return Colors.green;
  }



  trackerStreamSetup() {
    trackerStreamController = StreamController();
    trackerStreamController.stream.listen((coords) {
      onTrackerEvent(coords);
    });
  }


  onTrackerEvent(Position coords) {
    print(coords);
    _tourServices.addTrackPoint(LatLng(coords.latitude, coords.longitude));
    //_tourGpxData.trackPoints.add(LatLng(coords.latitude, coords.longitude));
  }


  onPageEvent(event) {
    //MapEvents.tapOnMap;
    print("tourmap stream event $event");
    if ( event.runtimeType == StreamMsg) {
      if (event.type == "newDefaultCoord") {
        setState(() {
          startPos;
          mapController.move(startPos, mapController.zoom);
        });
      }

      if ( event.type == "gpxFileData") {
        setState(() {});
      }

      if ( event.type == "toggleTracker" ) {
          toggleTracker(event.msg);
      }

      if (event.type == "mapTapAction") {

        switch (event.msg) {
          case MapTapAction.ADD_MARKER :
            if (_mapTapAction == MapTapAction.SELECT_MARKER || _mapTapAction == MapTapAction.ADD_PATHMARKER ) {
              _addPointToPath = null;
              _activeMarker = [];
              setState(() {});
            }
            _mapTapAction = event.msg;
            _mapStatusLayer.statusNotification("Add Marker at click");
            break;
          case MapTapAction.SELECT_MARKER :
            _addPointToPath = AddPointToPath();
            _mapTapAction = event.msg;
            _mapStatusLayer.statusNotification("Select marker to add");
            break;
          case MapTapAction.ADD_ITEM :
            _mapTapAction = event.msg;
            _mapStatusLayer.statusNotification("Add Item at click");
            break;
          case MapTapAction.NOACTION :
            _mapTapAction = event.msg;
            _mapStatusLayer.statusNotification("Select in menu");
            break;
        }


        //if (_mapTapAction == MapTapAction.SELECT_MARKER ) {}
      }

      if (event.type == "displayGpxTileTrack" ) {
        // toggleGpxFilePathDisplay
        displayGpxFileTrack = event.msg;
        setState(() {});
      }

    } else {
      print(event);
    }


  }

  /// Subscribe / Unsubscribe to PositionStream in Geolocation
  toggleTracker(bool trackState) {
    print("tourmap.toggleTracker to $trackState");
    if (trackState == true) {
      trackerStreamSetup();
      GeolocationService.gls.subscribeToPositionStream(trackerStreamController);
      //GeolocationService.gls.streamGenerator(trackerStreamController);
    } else {
      GeolocationService.gls.unsubcribeToPositionStream();
    }
  }


  List get _gpxFileTrackPoints {
    if (displayGpxFileTrack == true ) {
      return _tourServices.gpxFileData.gpxLatlng;
    } else {
      return <LatLng>[];
    }
  }


  @override
  Widget build(BuildContext context) {
    final TourInherited state = TourInherited.of(context);

    return new Flexible(
      child: new FlutterMap(
        mapController: mapController,
        options: new MapOptions(
          //center: startPos,
          center: startPos,
          zoom: 15,
          minZoom: 2,
          maxZoom: 18,
          onTap: _handleTap,
          plugins: [
            //_dragableMapLayer,
            _mapStatusLayer,
          ],
        ),
        layers: [
          new TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          new PolylineLayerOptions(
            polylines: [
              Polyline(
                points: _tourServices.trackLatlngPoints,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              )
            ]
          ),
          PolylineLayerOptions (
              polylines: [
                Polyline(
                  //points: _tourServices.gpxFileData.gpxLatlng,
                  points: _gpxFileTrackPoints,
                  strokeWidth: 4.0,
                )
              ]
          ),

          new MarkerLayerOptions(
              markers: markerList,
          ),
          new MapStatusLayerOptions(streamController: streamController),
          //new DragableMapLayerOptions(streamController: streamController),
        ]
      )
    );
  }

  PolylineLayerOptions get gpxLayer{
    if (_tourServices.gpxFileData != null ) {
      return PolylineLayerOptions (
          polylines: [
            Polyline(
              points: _tourServices.gpxFileData.gpxLatlng,
            )
          ]
      );
    }
  }


  _handleTap(LatLng latlng) {
    //streamController.add( "tapOnMap" );
    print("_handleTap at $latlng");

    if ( _mapTapAction == MapTapAction.NOACTION) { return; }

    var lobj = {
      'lat': latlng.latitude,
      'lon': latlng.longitude,
    };

    if (_moveMarker == true) {

      Marker cm = markerList[_activeMarker[0]];
      cm.point.latitude = latlng.latitude;
      cm.point.longitude = latlng.longitude;

      //_moveMarker = false;
      _activeMarker = [];
      _markerToMove = null;

      setState(() {});
    } else {
      var msg = json.encode(lobj);
      print(msg);

      if (_mapTapAction == MapTapAction.ADD_PATHMARKER ) {
        int index = _addPointToPath.getLastPathMarker();
        _tourServices.addTrackPointAtIndex(latlng, index);
        streamController.add(new StreamMsg("tapOnMap", latlng));
      } else {
        streamController.add(new StreamMsg("tapOnMap", latlng));
      }

      setState(() {});
    }

  }


  /// Tap on marker on maps.
  /// Use coords to get in marker list (_tourGpxData.trackPoints).
  _handleTapOnMarker(LatLng latlng) {
    print("_handTapOnMarker at $latlng");
    int trackpointIdx = _tourServices.getTrackPointIndex(latlng);

    if ( trackpointIdx != null ) {
      /// select marker but no marker dialog, for add marker to path
      if (_mapTapAction == MapTapAction.SELECT_MARKER) {

        /// deselect maker if already in _activMarker list
        if (_activeMarker.indexOf(trackpointIdx) >= 0) {
           _addPointToPath.removePathMarker(trackpointIdx);
           _activeMarker.remove(trackpointIdx);
           setState(() {});
           return;
        }

        int markerCount = _addPointToPath.addPathMarker(trackpointIdx);
        print ("markerCount $markerCount");
        if (markerCount < 3) {
          _activeMarker.add(trackpointIdx);
          if (markerCount == 2) {
            _mapTapAction = MapTapAction.ADD_PATHMARKER;
          }
        }
        setState(() {

        });
        return;
      }

      /// Deselect tap marker if selected
      if ( _mapTapAction == MapTapAction.ADD_PATHMARKER) {
        int markerCount =_addPointToPath.removePathMarker(trackpointIdx);
        if (markerCount < 2) {
          _activeMarker.remove(trackpointIdx);
          _mapTapAction = MapTapAction.SELECT_MARKER;
        }
        setState(() {});
        return;
      }

      /// If Item, show item
      if (_tourServices.trackPoints[trackpointIdx].item != null) {

        return;
      }

      /// Dialog
      //String latlngStr = "$latlng";
      _tourServices.selectMarker(trackPointIdx: trackpointIdx);
      _markerDialog(trackpointIdx, latlng);
//      showDialog(
//          context: context,
//          builder: (BuildContext context) {
//            return TrackPointDialog(context, trackpointIdx.toString(), latlngStr);
//          }
//      );
    }

  }

  // get marker for later actions (move marker or add marker to path)
  _handleLongPressOnMarker( BuildContext context, LatLng latlng) {
    if (_mapTapAction == MapTapAction.ADD_PATHMARKER) {
      return;
    }

    print("_handleLongPressOmMaker at $latlng");

    int trackpointIdx = _tourServices.getTrackPointIndex(latlng);

    _moveMarker = true;
     //_markerToMove = trackpointIdx;
    _activeMarker.length == 0 ? _activeMarker.add(trackpointIdx) : _activeMarker[0] = trackpointIdx;
    setState(() {

    });
    // find icon and change color

//    void visitor(Element element) {
//      if (element.widget is Icon) {
//        Icon markerIcon = element.widget;
////        markerIcon.icon = Icon()
////        markerIcon.color = Colors.redAccent;
//      }
//
//
//      element.visitChildren(visitor);
//    }
//
//    context.visitChildElements(visitor);
//    return;

//    GlobalKey mk = markerKeyList[trackpointIdx];
//    Marker am = markerList[trackpointIdx];
//    //Context amContest = am.builder;
//    Widget w = context.widget;
//    Offset mOffset = Offset(0.0, 0.0);
//
//    void markerVisitor(Element element) {
//
//      print (element.runtimeType);
//      print (element.widget.runtimeType);
//      print (element.slot.runtimeType);
//      print (element.slot);
//      print (element.slot.toString());

//      if (element.slot != null) {
//        print(element.slot);
//        print(element.slot.widget);
//        print(element.slot.widget.runtimeType);
//
//        if (element.slot.widget is Positioned) {
//          print("ok");
//
//          final Positioned mpos = element.slot.widget;
//          print("marker position: ${mpos.left}, ${mpos.top}");
//          mOffset = Offset(mpos.left, mpos.top);
//        }
//        //Positioned slot = element.slot;
//        //print(slot);
//        //print(slot);
//      }

//      final Positioned mpos = element.slot;
//      print("marker position: ${mpos.left}, ${mpos.top}");




//      if (element.widget is Positioned) {
//        final Positioned mpos = element.slot;
//        print("marker position: ${mpos.left}, ${mpos.top}");
//        mOffset = Offset(mpos.left, mpos.top);
//        //return;
//      }
//    }

//    BuildContext markerContext = mk.currentContext;
//
//    markerContext.visitChildElements(markerVisitor);
//
//    Key pointKey = Key("mapmarker_${latlng.latitude}_${latlng.longitude}");

//    WidgetTester tester;
//    findMarker(latlng, tester);

//    var a = context.ancestorWidgetOfExactType(Container);



//    void visitor(Element element) {
//
//      print ("element:");
//      print (element.runtimeType);
//      print (element.widget.runtimeType);
//      var runtimeType = element.runtimeType;
//
//      if ( runtimeType == "LeafRenderObjectElement") {
//        print ("inspect element");
//      }
//
//      if ( element.widget is Positioned ) {
//        print(element.widget);
//        final Positioned ipos = element.widget;
//        print(ipos.left);
//        mOffset = Offset(ipos.left, ipos.top);
//
//      }

//      if (element.widget is Icon) {
//        Icon i = element.widget;
//        print("icon color: ${i.color}");
//      }
//      element.visitChildren(visitor);
//    }

     //var b = context.visitChildElements(visitor);
//    var wg = context.widget;
//    var wgRenderObj = context.findRenderObject();
//    var type = context.widget.runtimeType;
    // var diagnostic = context.toDiagnosticsNode();

    // var contextBuilder = context.builder;

//    RenderBox getBox = context.findRenderObject();
//
//    var local = getBox.globalToLocal(Offset(0.0, 0.0));
//
//
//    FlexParentData parentData = getBox.parentData;
//    var local2 = getBox.globalToLocal(parentData.offset);
//    var local3 = getBox.localToGlobal(parentData.offset);


//    if (trackpointIdx != null) {
//        _dragableMapLayer.notification(mOffset);
//        streamController.add(StreamMsg("newOffset", mOffset));
//    }

  }


  findMarker(LatLng latlng, WidgetTester tester) async {
    Key pointKey = Key("mapmarker_${latlng.latitude}_${latlng.longitude}");

    var result = find.byKey(pointKey);
    print(result);
    expect(find.byKey(pointKey), findsOneWidget);
  }


  Future _markerDialog(int trackpointIdx, LatLng latlng) async {
    String coords = "${latlng.longitude.toStringAsFixed(6)}/${latlng.latitude.toStringAsFixed(6)}";
    int trackPointId = _tourServices.trackPoints[trackpointIdx].id;
    /// marker has an item?
    int itemId = _tourServices.trackPoints[trackpointIdx].item;
    switch(
    await showDialog(
      context: context,
      child: TrackPointDialog(context, trackPointId, coords, itemId),
      )
    ) {
      case "ADD":
        print("markerDialog answer: ADD");
        _itemDialog(trackPointId, coords);
        break;
      case "REMOVE" :
        print("markerDialog answer: REMOVE");
        _tourServices.deleteTrackPoint(trackpointIdx);
        setState(() {});

        break;
      case "EDIT" :
        print("markerDialog anwser: EDIT");
        break;
    }
  }

  /// Clousure to get values from ItemDialog
  onReflectItemDialog( Map item ) {
    print(item);
    print(item['name']);
    print(item['info']);
    _tourItem.name = item['name'];
    _tourItem.info = item['info'];
  }

  onImagesInItemDialog( List images ) {
    for (int i = 0; i < images.length; i++) {
      print(images[i]);
    }
    _tourItem.images = images;
  }

  /// show modal to enter item data
  /// new empty info object for modal data
  Future _itemDialog(int trackpointIdx, String latlng) async {
    if (_tourServices.markerSelected.item != null) {
      _tourItem = await _tourServices.getItem(trackpointIdx);
    } else {
      _tourItem = TourItem();

    }
    switch (
    await showDialog(
        context: context,
        builder: (context) {
          if (_tourServices.markerSelected.item != null ) {

          } else {
            return ItemDialog(context, trackpointIdx,
                onReflectItemDialog, onImagesInItemDialog, _tourItem);
          }
        },
        //child: ItemDialog(context, trackpointIdx),
        )
    ) {
      case "SAVE" :
        print("SAVE item");
        _tourItem.markerId = trackpointIdx;
        _tourServices.saveItem(_tourItem, trackpointIdx);
        break;
      case "CANCEL":
        break;
    }
  }



//  @override
//  BuildContext get context => super.context;

  // trigger update of widget
//  @override
//  void didChangeDependencies() {
//    // TODO: implement didChangeDependencies
//    print('didChangeDependencies');

    //var page = TourDetailPage.of(context);

    // test to update map center
//    if (mapController != null ) {
//      try {
//        var current = mapController.center;
//        mapController.move(startPos, 12.0);
//
//      } catch(Exception) {
//        print (Exception);
//      }
//
//    }

//  }

}

enum MapEvents {
  tapOnMap,
  centerOnLocation,
  zoomIn,
  zoomOut,
  trackOn,
  trackOff,
}


enum MapTapAction {
  NOACTION,
  ADD_MARKER,
  ADD_ITEM,
  SELECT_MARKER,
  ADD_PATHMARKER,
  MOVE_MARKER,
}