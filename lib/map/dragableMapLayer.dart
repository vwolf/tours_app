import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import '../tour_detail_page.dart';

class DragableMapLayerOptions extends LayerOptions {
  final StreamController streamController;

  DragableMapLayerOptions( {this.streamController} );
}


class DragableMapLayer implements MapPlugin {

  DragWidget _dragWidget = DragWidget();

  @override
  Widget createLayer(
      LayerOptions options,
      MapState mapState,
      Stream<Null> stream ) {

//    if (options is DragableMapLayerOptions) {
//      return _dragWidget;
//    }
//    throw("Unkown options type for DragableMapLayer"
//        "plugin $options");


    if (options is DragableMapLayerOptions) {
      return DragWidget(streamCtrl: options.streamController,);
    }
    throw("Unkown options type for DragableMapLayer"
          "plugin $options");
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is DragableMapLayerOptions;
  }

  notification(msg) {
    print("dragableMapLayer.notification $msg");
    _dragWidget.update(msg);
  }

  updateDragWidgetOffset(Offset offset) {
    _dragWidget.update(offset);

  }
}



class DragWidget extends StatefulWidget {
  final streamCtrl;
  DragWidget({this.streamCtrl});

//  static of(BuildContext context, {bool root = false}) => root
//      ? context.rootAncestorStateOfType(const TypeMatcher<DragWidgetState>())
//      : context.ancestorStateOfType(const TypeMatcher<DragWidgetState>());

//  DragWidget();

  Offset markerOffset = Offset(0.0, 0.0);

  update(Offset offset) {
    print("set to new offset $offset");
//    markerOffset = offset;
  }

  @override
  DragWidgetState createState() => DragWidgetState(streamCtrl);
}



class DragWidgetState extends State<DragWidget> {

  final StreamController streamCtrl;

  DragWidgetState(this.streamCtrl);

  @override
  void initState() {
    super.initState();

    streamCtrl.stream.listen((event) {
      streamNotification(event);
    });
  }

  streamNotification(StreamMsg streamMsg) {
    print ("streamNotification $streamMsg");
    print (streamMsg.type );
    print (streamMsg.msg);
    if (streamMsg.type == "newOffset") {

      setState(() {
        _offset = streamMsg.msg;
      });
    }

    // _offset = Offset(185.9, 196.7);
  }

  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Draggable(
          child: Icon(
            Icons.location_on,
            size: 32.0,
            color: Colors.orangeAccent,
          ),
          feedback: Icon(
            Icons.location_on,
            size: 32.0,
            color: Colors.redAccent,
          )),
    );
//    return Draggable(
//      child: Icon(
//        Icons.location_on,
//        size: 32.0,
//      ),
//      feedback: Icon(
//        Icons.location_on,
//        size: 32.0,
//        color: Colors.redAccent,
//      ),
//    );
  }

//  double wTop = 0.0;
//  double wLeft = 0.0;
  Offset _offset = Offset(0.0, 0.0);

//  setOffset( Offset newOffset) {
//    offset = newOffset;
//    setState(() { });
//  }

//  Offset get offset {
//    widget.markerOffset;
//    setState(() {
//      print ("get offset");
//      _offset = offset;
//    });
//  }
//
//  set offset(ao) {
//    setState(() {
//      _offset = offset;
//    });
//  }

//  Widget build(BuildContext context) {
//
//    return Positioned(
//      top: _offset.dy,
//      left: _offset.dx,
//        child: Container(
//          child: Icon(Icons.location_on,
//            size: 32.0,
//          )
//        ),
//    );

//    return Container(
//
//      child: Icon(Icons.location_on,
//      size: 32.0,)
//    );
//  }
}