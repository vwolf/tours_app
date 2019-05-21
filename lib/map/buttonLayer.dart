import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';


class MapButtonLayerOptions extends LayerOptions {
  final StreamController streamController;

  MapButtonLayerOptions({this.streamController});
}



class MapButtonLayer implements MapPlugin {

  //MapButtons _mapButtons;
  LocationState lc = LocationState();

  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
      if (options is MapButtonLayerOptions) {
        return MapButtons(streamCtrl: options.streamController, lc: lc);
        //return this._mapButtons;
      }
      throw("Unkown options type for MapButtonLayer"
            "plugin $options");
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapButtonLayerOptions;
  }

  stateNotification() {
    lc.myState = true;
    print(lc.myState);
    print("MapButtonLayer.stateNotifictions");
   // _mapButtons.stateNotification();
  }

  setLcState(state) {
    lc.myState = state;
  }

  bool getLcState() {
    return lc.myState;
  }
}



class MapButtons extends StatefulWidget {
  final streamCtrl;
  final lc;

  MapButtons({this.streamCtrl, this.lc});

  @override
  _MapButtonsState createState() => _MapButtonsState();

  stateNotification() {
    print(lc.myState);
    print("MapButtons.stateNofification");
  }

}


class _MapButtonsState extends State<MapButtons> {
  Color containerColor = Colors.orange;
  Color icon_enabled = Colors.white;
  Color icon_disabled = Colors.blueGrey;

  bool _trackButtonState = false;

  trackButtonState( bool state) {
     //_trackButtonState = state;
     _trackButtonState =  widget.lc.myState;
     setState(() {

     });
  }

  updateTrackButton() {
    setState(() {
     // _trackButtonState = widget.lc.myState;
    });

  }

  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: containerColor,
              child: IconButton(
                  icon: Icon(Icons.gps_fixed),
                  iconSize: 32.0,
                  onPressed: () {
                    widget.streamCtrl.add(LocationMapEvents.centerOnLocation);
                  }),
            ),
            Container(
              color: containerColor,
              child: IconButton(
                  icon: Icon(Icons.zoom_in),
                  iconSize: 32.0,
                  onPressed: () {
                    widget.streamCtrl.add(LocationMapEvents.zoomIn);
                  }),
            ),
            Container(
              color: containerColor,
              child: IconButton(
                icon: Icon(Icons.zoom_out),
                iconSize: 32.0,
                onPressed: () {
                  widget.streamCtrl.add(LocationMapEvents.zoomOut);
                },
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              color: Colors.greenAccent,
              child: IconButton(
                  icon: Icon(Icons.autorenew),
                  iconSize: 32.0,
                  color: _trackButtonState ? icon_enabled : icon_disabled,
                  onPressed: () {
                    if (_trackButtonState == false) {
                      widget.streamCtrl.add(LocationMapEvents.trackOn);
                    } else {
                      widget.streamCtrl.add(LocationMapEvents.trackOff);
                    }
                    _trackButtonState = !_trackButtonState;
                    updateTrackButton();
                  }
                  ),

            )
          ],
        )
      ],
    );
  }

}



enum LocationMapEvents {
  centerOnLocation,
  zoomIn,
  zoomOut,
  trackOn,
  trackOff,
}

class LocationState {
  bool myState = false;
}