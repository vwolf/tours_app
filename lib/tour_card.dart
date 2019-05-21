
import 'package:flutter/material.dart';
import 'tour_detail_page.dart';
import 'database/models/tour.dart';


class TourCard extends StatefulWidget {

  TourCard(this.tour);

  final Tour tour;

  @override
  _TourCardState createState() => _TourCardState(tour);
}


class _TourCardState extends State<TourCard> {
  Tour tour;

  ScrollController controller = ScrollController();
  bool isOpen = false;
  Size childSize;

  _TourCardState(this.tour);


  void initState() {
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return InkWell(

      onTap: showTourDetailPage,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            color: Colors.black87,
            height: 115.0,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 24.0,
                  child: tourCard,
                ),
                Positioned(
                    top: 20.0,
                    child: tourIcon),
              ],
            ),
          )
      ),
    );
  }

  showTourDetailPage() {
    print('showTourDetailPage');

    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return new TourDetailPage(tour);
      }));
  }


  Widget get tourIcon{
    return Icon(
      Icons.directions_walk,
      size: 48,
    );
  }

  Widget get tourCard {
    // new Container
    return Container(
      width: 290.0,
      height: 100.0,
      child: Card(
        color: Colors.black87,
        child: Padding(padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 64.0,
        ),
          // Colume is another layout widget that takes a list of widgets as children
          // and lays the widgets out from top to bottom
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(widget.tour.name,
                style: Theme.of(context).textTheme.headline),
              Text(widget.tour.location,
                style: Theme.of(context).textTheme.subhead),
            ],
          ),
        )
      )
    );
  }

}