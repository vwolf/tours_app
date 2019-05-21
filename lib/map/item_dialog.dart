import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/models/tourCoord.dart';
import '../database/models/tourItem.dart';

/// Modal to add a item
/// Constructor get's an TourItem Object
/// Use TourItem properties to initialize
class ItemDialog extends StatefulWidget {
  final context;
  final int trackIndex;
  final ValueSetter<Map> onReflectItemDialog;
  final ValueSetter<List> onImagesInItemDialog;
  final TourItem tourItem;

  ItemDialog(this.context,
      this.trackIndex,
      this.onReflectItemDialog,
      this.onImagesInItemDialog,
      this.tourItem);

  @override
  ItemDialogState createState() => ItemDialogState();
}


class ItemDialogState extends State<ItemDialog> {
  /// layout properties
  double _edgeInsetHorz = 12.0;

  String _markerImagePath;
  AssetImage _markerImage;

  List<AssetImage> images = [];
  List<String> imagesPath = [];

  TextEditingController _textCtrlName = TextEditingController();
  TextEditingController _textCtrlInfo = TextEditingController();

  addImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery
    );

    print("Selected image: ${image.path}");
    _markerImagePath = image.path;
    AssetImage selectedImage = await AssetImage(_markerImagePath);
    images.add(selectedImage);
    imagesPath.add(_markerImagePath);

    setState((){});
  }


  _getContent() {
    return SimpleDialog(
      title: Text("Header"),
      children: <Widget>[
        Divider(height: 10.0, color: Colors.white70,),
        Padding(
          padding: EdgeInsets.only(left: _edgeInsetHorz, right: _edgeInsetHorz),
          child: TextFormField(
            controller: _textCtrlName,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: "Name",
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(left: _edgeInsetHorz, right: _edgeInsetHorz),
          child: TextField(
            controller: _textCtrlInfo,
            keyboardType: TextInputType.text,
            maxLines: null,
            decoration: InputDecoration(
              labelText: "Marker Info",
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(left: _edgeInsetHorz, right: _edgeInsetHorz),
          child: imagesRow,
        ),


        Padding(
          padding: EdgeInsets.only(left: _edgeInsetHorz, right: _edgeInsetHorz),
          child: SimpleDialogOption(
            child: RaisedButton(
              child: Text('Add Image'),
              onPressed: () {addImage(); },
            ),
          )
        ),

        Divider(height: 10.0, color: Colors.white70,),

        Row (
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SimpleDialogOption(
              child: Text("SAVE"),
              onPressed: (){
                widget.onReflectItemDialog({
                  'name': _textCtrlName.text,
                  'info': _textCtrlInfo.text
                });
                widget.onImagesInItemDialog(imagesPath);
                Navigator.pop(context, "SAVE");
                },
            ),
            SimpleDialogOption(
              child: Text("CANCEL"),
              onPressed: (){Navigator.pop(context, "CANCEL");},
            ),
          ],
        ),

      ],
    );
  }

  /// Add width property to Container ( IntrinsicWidth error)
  Widget get imagesRow {
    if (images.length > 0 ) {
      return Container(
        width: double.maxFinite,
        height: 64.0,
        color: Colors.orangeAccent,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: images.map((img) => Container(
            //height: 64.0,
            width: 64.0,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.redAccent,
              image: DecorationImage(
                  image: img,
                  fit: BoxFit.fitHeight
              )
            ),
          )).toList(),
        )
      );
    } else {
      return Container(
        height: 2.0,
        color: Colors.greenAccent,
      );
    }
  }


  Widget get markerImage {
    if ( images.length == 0) {
      return Container();
    } else {
      return Container(
        height: 50.0,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: DecorationImage(
            image: getMarkerImage(),
            fit: BoxFit.fitHeight,
          ),
        ),
      );
    }
  }

  getMarkerImage() {
    return AssetImage(_markerImagePath);
  }


  @override
  Widget build(BuildContext context) {
    return _getContent();
  }
}