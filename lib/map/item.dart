import 'package:flutter/material.dart';
import '../database/models/tourItem.dart';

/// Item has
/// * name
/// * info
/// * image(s)
class Item extends StatefulWidget {
  final tourItem;

  Item(this.tourItem);

  @override
  ItemState createState() => ItemState();

}

class ItemState extends State<Item> {

  @override
  Widget build(BuildContext context) {
    _settingModalBottomSheet(context);
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                new ListTile(
                  leading: Icon(Icons.music_note),
                  title: new Text('Music'),
                  onTap: () => {},
                ),
                new ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text('Video'),
                  onTap: () => {},
                )
              ],
            )
          );
        });
  }
}