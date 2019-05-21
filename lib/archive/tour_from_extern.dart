import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'package:tours_app/database/models/tour.dart';
import 'package:tours_app/database/models/tourCoord.dart';
import 'package:tours_app/database/models/tourItem.dart';

class TourFromExternal extends StatefulWidget {
  TourFromExternal();

  _TourFromExternalState createState() => _TourFromExternalState();
}



class _TourFromExternalState extends State<TourFromExternal> {

  @override
  Widget build(BuildContext context) {

  }
}


/// Get directory with tour data
/// Check contents
class TourDirectory {
  String tourPath;
  String _directoryPath;

  Future<bool> getDirectory() async {
    //checkServicesStatus(PermissionGroup.storage);
    await requestPermissionStatus(PermissionGroup.storage);
    try {
      String pathToTour = await FilePicker.getFilePath(type: FileType.ANY);
      if (pathToTour != "") {
        return await checkDirectory(pathToTour);
      }
    } on Platform catch (e) {
      print(e);
      return false;
    }
    return false;
  }

  Future<bool> checkDirectory(String path) async {
    // tour.txt
    //checkServicesStatus(PermissionGroup.storage);

    var dirName = p.dirname(path);
    print("dirname $dirName");
    var filePath = '$dirName/tour.txt';
    File tour = File(filePath);
    if ( tour.existsSync() == true ) {
      print("checkDirectory tour file ok");
      _directoryPath = p.dirname(path);
      tourPath = filePath;
//      await readTour(filePath);
//      return tour;
        return true;
    } else {
      print("checkDirectory tour file false");
    }
    return false;
  }


  checkServicesStatus(PermissionGroup permission ) {
    print("checkServiceStatus");
    PermissionHandler()
      .checkServiceStatus(permission)
      .then((ServiceStatus serviceStatus) {
        print("ServiceStatus: ${serviceStatus.toString()}");
    });
  }

  requestPermissionStatus(PermissionGroup permission ) async {
    PermissionStatus status = await PermissionHandler().checkPermissionStatus(permission);
    print(status.toString());
  }


    // track.txt?
//    tour = File('$dirName/track.txt');
//    if (tour.existsSync() == true) {
//      print("checkDirectory track file ok");
//    } else {
//      print("checkDirectory track file false");
//    }
//    // items.txt?
//
//    tour = File('$dirName/item.txt');
//    if (tour.existsSync() == true) {
//      print("checkDirectory item file ok");
//    } else {
//      print("checkDirectory item file false");
//    }




  Future<Tour> readTour() async {
    String contents = await File(tourPath).readAsString();
    print("tour.txt content: $contents");
    Tour tour = tourFromJson(contents);
    return tour;
  }


  Future <List<TourCoord>> readTourCoords() async {
    List<TourCoord> tourCoords = [];
    var filePath = '$_directoryPath/track.txt';
    File trackFile = File(filePath);
    if (trackFile.existsSync() == true ) {
      print("Tour track file exists");
      List contents = await trackFile.readAsLinesSync();
      for (var line in contents) {
        TourCoord tourCoord = tourCoordFromJson(line);
        tourCoords.add(tourCoord);
      }
    }
    return tourCoords;
  }


  Future <List<TourItem>> readTourItems() async {
    List<TourItem> tourItems = [];
    var filePath = '$_directoryPath/item.txt';
    File itemFile = File(filePath);
    if (itemFile.existsSync() == true ) {
      print("Tour item file exists");
      List contents = await itemFile.readAsLinesSync();
      for (var line in contents) {
        TourItem tourItem = tourItemFromJson(line);
        tourItems.add(tourItem);
      }
    }
    return tourItems;
  }
}