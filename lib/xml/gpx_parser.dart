/// Parser for *.gpx xml files
///
/// xml schemas
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
/// xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
/// points in <trk><trkseg><trkpt> section (trkseg is optional)
///
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3"
/// xmlns:rcxx="http://www.routeconverter.de/xmlschemas/RouteCatalogExtensions/1.0"
/// point in wpt items
///
/// ToDo parse only tour meta data for new tour
///
import 'package:xml/xml.dart' as xml;
import 'package:latlong/latlong.dart';
import 'package:tours_app/database/models/tourCoord.dart';


class GpxParser {
  String xmlData;

  GpxParser(this.xmlData);

  // TourGpxData tourGpxData = new TourGpxData();
  GpxFileData gpxFileData = new GpxFileData();

  /// start parsing
  parseData() {
    print("parseData()");
    var document = xml.parse(xmlData);
    GPXDocumentType documentType = GPXDocumentType.xsi;
    //print(document);

    // what xml schema?
    var root = document.findElements('gpx');
    root.forEach((xml.XmlElement f) {
      if (f.getAttribute("xmlns:gpxx") != null) {
        documentType = GPXDocumentType.gpxx;
      }
    });

//    var textual = document.descendants.where((node) => node is xml.XmlText && !node.text.trim().isEmpty).join('\n');
//    print(textual);

//    document.children.forEach((f) =>
//      print(f.children.asMap()),
//    );


    /// first get tour name, try <metadata><name>
    String tourName = "";
    Iterable<xml.XmlElement>metadataItems = document.findAllElements('metadata');
    metadataItems.map((xml.XmlElement metadataItem) {
      tourName = getValue(metadataItem.findElements('name'));
      if (tourName == null) {
        tourName = getValue(metadataItem.findElements('desc'));
      }
    }).toList(growable: true);



    /// add to tourGpxData
    Iterable<xml.XmlElement>items = document.findAllElements('trk');
    items.map((xml.XmlElement item) {
      // no name tag in metadata try in <trk><name>
      var name = getValue(item.findElements('name'));
      print(name);
      if ( tourName == "") {
        tourName = name;
      }
      gpxFileData.trackName = name;
      // sometimes in <cmt> is a printable version tourname
    }).toList(growable: true);


    /// list of gps coordinates
    List<GpxCoords>trkList = List();
    List<LatLng>pointsList = List();
    /// get the coordinates for points
    /// ToDo check for elevation values
    if (documentType == GPXDocumentType.gpxx) {
      Iterable<xml.XmlElement>wpt = document.findAllElements('wpt');
      trkList = parseGPXX(wpt);
    } else {
      Iterable<xml.XmlElement>trkseg = document.findAllElements('trkseg');
      trkList = parseGPX(trkseg);
    }

    gpxFileData.tourName = tourName != null ? tourName : "?";
    gpxFileData.gpxCoords = trkList;

    return gpxFileData;
  }


  List<GpxCoords> parseGPX(Iterable<xml.XmlElement> trkseg) {
    List<GpxCoords>trkList = List();
    trkseg.map((xml.XmlElement trkpt) {
      Iterable<xml.XmlElement> pts = trkpt.findElements('trkpt');
      pts.forEach((xml.XmlElement f) {
        // <ele> element?
        var ele = getValue(f.findElements('ele'));
        ele = ele == null ? "0.0" : ele;
        trkList.add(GpxCoords(
            double.parse(f.getAttribute('lat')),
            double.parse(f.getAttribute('lon')),
            double.parse(ele)
        ));
      });
    }).toList(growable: true);

    return trkList;
  }

  List<GpxCoords> parseGPXX(Iterable<xml.XmlElement> wpt) {
    List<GpxCoords>wpttrkList = List();
    wpt.forEach((xml.XmlElement f) {
      var ele = getValue(f.findElements('ele'));
      ele = ele == null ? "0.0": ele;
      wpttrkList.add(GpxCoords(
          double.parse(f.getAttribute('lat')),
          double.parse(f.getAttribute('lon')),
          double.parse(ele)
      ));
    });
    return wpttrkList;
  }


  /// extract node text
  String getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList(growable: true);
    return textValue;
  }

}

/// GpxFileTrack holds the parsed data from a *.gpx file
class GpxFileData {
  String tourName = "";
  String trackName = "";
  LatLng defaultCoord = LatLng(51.5, -0.09);
  List<GpxCoords> gpxCoords = [];
  List<LatLng> gpxLatlng = [];

  /// convert GpxCoords to LatLng
  coordsToLatlng() {
    gpxLatlng = [];
    gpxCoords.forEach((GpxCoords f) {
      gpxLatlng.add(new LatLng(f.lat, f.lon));
    });
  }
}



/// class for one tour
class TourGpxData {
  String tour_name = "";
  String tour_trackName = "";
  LatLng defaultCoords = LatLng(51.5, -0.09);
  List<GpxCoords> gpxCoords = [];
  List<LatLng> trackPoints = [];

  TourGpxData();

  /// convert GpxCoords to LatLng
  coordsToLatlng() {
    trackPoints = [];
    gpxCoords.forEach((GpxCoords f) {
      trackPoints.add(new LatLng(f.lat, f.lon));
    });
  }


  LatLng coordToLatlng(GpxCoords pos) {
    return LatLng(pos.lat, pos.lon);
  }


  /// for now: this is set at init so the first coord should be the default position
  setTrackPoints(List<TourCoord>coordsList) {
    for ( var aCoord in coordsList) {
      trackPoints.add(LatLng(aCoord.latitude, aCoord.longitude));
    }

    defaultCoords = trackPoints[0];
  }

  /// trackPoint list
  /// Always update sqlite table

  getTrackTable() {
    if (tour_name != null) {

    }
  }


  addTrackPoint(LatLng latlng) {
    trackPoints.add(latlng);

    TourCoord newTourCoord = new TourCoord();
    newTourCoord.latitude = latlng.latitude;
    newTourCoord.longitude = latlng.longitude;
    //DBProvider.db.addTourCoord(newTourCoord, tourCoordTable);
  }


  /// Get index in trackPoint for LatLng
  int getTrackPointIndex(LatLng latlng) {
    int idxForLatLng = trackPoints.indexOf(latlng);
    if (idxForLatLng >= 0) {
      print("TrackPoint found at index $idxForLatLng");
      return idxForLatLng;
    }
    return null;
  }

  /// Delete trackpoint at index
  deleteTrackPoint(int index) {
    if ( index < trackPoints.length) {
      trackPoints.removeAt(index);
    }
  }

//  if (_mapTapAction == "add_marker") {
//  TourCoord newTourCoord = new TourCoord();
//  newTourCoord.lat = streamMsg.msg.latitude;
//  newTourCoord.lon = streamMsg.msg.longitude;
//
//  DBProvider.db.addTourCoord(newTourCoord, widget.tour.track);
//  }
}


class GpxCoords {
  double lat;
  double lon;
  double evl;

  GpxCoords(this.lat, this.lon, this.evl);
}


enum GPXDocumentType {
  xsi,
  gpxx
}