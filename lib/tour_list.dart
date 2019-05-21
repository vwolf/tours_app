import 'package:flutter/material.dart';
import 'database/database.dart';
import 'tour_card.dart';
import 'tour_detail_page.dart';
import 'tour_card_swipe.dart';
import 'archive/tour_to_extern.dart';

import 'database/models/tour.dart';

/// All tours in ListView
class TourList extends StatefulWidget {

  TourList();

  @override
  _TourListState createState() => _TourListState();


}

class _TourListState extends State<TourList> {
  /// instead of returning Widgets return a method that returns widgets
  @override
  Widget build(BuildContext context) {
    return _buildFutureList(context);
    //return _buildList(context);
  }

//  _buildFutureList(context) {
//    return new FutureBuilder(
//      future: DBProvider.db.getAllTours(),
//      builder: (BuildContext context, AsyncSnapshot<List<Tour>> snapshot) {
//        if (snapshot.hasData) {
//          return ListView.builder(
//              itemCount: snapshot.data.length,
//              itemBuilder: (context, int) {
//                //return TourCard(snapshot.data[int]);
//                  return Dismissible(
//                    key: UniqueKey(),
//                    background: Container(color: Colors.red),
//                    onDismissed: (direction) {
//                      DBProvider.db.deleteTour(snapshot.data[int].id);
//                    },
//                    child: TourCard(snapshot.data[int]),
//                  );
//
//                //return TourCard(snapshot.data[int]);
//          });
//        } {
//          return Center(child: CircularProgressIndicator());
//        }
//      },
//    );
//  }
  List<Tour> _tours = [];
  //Future get _tours => DBProvider.db.getAllTours();

  Future <List<Tour>> getTours() async {
    var t = await DBProvider.db.getAllTours();
    _tours = t;
    return t;
  }

  // slideable version
  _buildFutureList(context) {
    return FutureBuilder(
      //future: DBProvider.db.getAllTours(),
      future: getTours(),
      builder: (BuildContext context, AsyncSnapshot<List<Tour>> snapshot) {
        if (snapshot.hasData) {
          //_tours = snapshot.data;
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (BuildContext context, int index) {
              return TourCardSlide(
                items: <ActionItems>[
                  ActionItems(
                      icon: new IconButton(
                        icon: new Icon(Icons.archive,
                        size: 36.0),
                        onPressed: () {},
                        color: Colors.green,
                      ),
                      onPress: () {
                        print("onPress archive");
                        archiveTour(context, snapshot.data[index]);
                      },
                      backgroundColor: Colors.white),
                  new ActionItems(
                      icon: new IconButton(
                        icon: new Icon(Icons.delete,
                        size: 36.0,),
                        onPressed: () {},
                        color: Colors.red,
                      ),
                      onPress: () {
                        deleteTour(context, index);
                      },
                      backgroundColor: Colors.white),
                ],
                child: Container(
                  padding: const EdgeInsets.only(top: 10.0),
                  //width: 200.0,
                  height: 115.0,
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        print("tap on card");
                        showTourDetailPage(snapshot.data[index]);
                      },
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.directions_walk,
                            size: 40.0,
                          ),
                          Text(snapshot.data[index].name,
                            style: Theme.of(context).textTheme.headline,)
                        ],
                      ),
                    ),
                  ),
                )
              );
            },
          );
        } else {
          return Center(child: CircularProgressIndicator());
          // return Container();
        }
      },
    );
  }

//  ListView _buildList(context) {
//    return ListView.builder(
//      // must have an item count equal to the number of items
//      itemCount: _tours.length,
//      // a callback that will return a widget
//      itemBuilder: (context, int) {
//        return TourCard(_tours[int]);
//      },
//    );
//  }

//  updateTours() {
//    this.tours[0].location = "Schweden";
//    this.tours[1].location = "Schweden";
//  }


  showTourDetailPage(Tour tour) {
    print('showTourDetailPage');
    setState(() {});
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) {
          return new TourDetailPage(tour);
        })
    );
  }


  /// Go to Save tour to external page
  archiveTour(BuildContext context, Tour tour) {

    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) {
          return new TourToExternal(tour);
        })
    );
  }

  deleteTour(BuildContext context, int index) {
    if (_tours[index].track != null) {
      DBProvider.db.deleteTable(_tours[index].track);
    }
    if (_tours[index].items != null) {
      DBProvider.db.deleteTable(_tours[index].items);
    }
    DBProvider.db.deleteTour(_tours[index].id);

    setState(() {});
  }


}
