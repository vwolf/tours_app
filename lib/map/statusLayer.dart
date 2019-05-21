import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';


class MapStatusLayerOptions extends LayerOptions {
  final StreamController streamController;

  MapStatusLayerOptions({this.streamController});
}


/// Display map status on a map layer
class MapStatusLayer implements MapPlugin {

  String status = "Select in menu";
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream
      ) {
    if (options is MapStatusLayerOptions) {
      return MapStatus(streamCtrl: options.streamController, status: status);
    }
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapStatusLayerOptions;
  }

  statusNotification(String newStatus) {
    print("statusLayer stateNotification $status");
    status = newStatus;
  }
}


class MapStatus extends StatefulWidget {

  final streamCtrl;
  final status;

  MapStatus({this.streamCtrl, this.status});

  @override
  _MapStatusState createState() => _MapStatusState();

}


class _MapStatusState extends State<MapStatus> {

  Color containerColor = Colors.orange;

  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 6.0, top: 4.0),
          child: Container(
            color: containerColor,
            child: Text(widget.status,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),),
          ),
        )

      ],
    );
  }

}

