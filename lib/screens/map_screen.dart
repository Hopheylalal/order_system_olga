import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/widgets/master_modal_window.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';

import 'common_master_profile.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _chosenValue;
  List _chosenValueArr = [];
  List _chosenValueArrALL = ['все'];

  Set<Marker> masters = {};
  String masterName;
  LatLng startLocation;
  LatLng locTest = LatLng(45.048656, 38.952362);

  Future<LatLng> getLocation() async {
    Position position =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    // startLocation = LatLng(position.latitude, position.longitude);
    LatLng _startTarget = LatLng(position.latitude, position.longitude);
    return _startTarget;
  }

  getIosPermission() async {
    // bool isLocationServiceEnabled  = await isLocationServiceEnabled();
    LocationPermission permission = await requestPermission();
  }

  // void showMarkers1() async {
  //   masters = {};
  //   final markersFromFirebase = await Firestore.instance
  //       .collection('masters')
  //       .getDocuments()
  //       .catchError(
  //         (error) => print(error),
  //       );
  //   if (markersFromFirebase.documents.isNotEmpty) {
  //     try {
  //       for (var n in markersFromFirebase.documents) {
  //         setState(() {
  //           masters.add(
  //             Marker(
  //               markerId: MarkerId(n.documentID),
  //               infoWindow: InfoWindow(title: '${n.data['name']}'),
  //               position: LatLng(
  //                   n.data['geoPoint'].latitude, n.data['geoPoint'].longitude),
  //               icon: BitmapDescriptor.defaultMarkerWithHue(
  //                   BitmapDescriptor.hueGreen),
  //               onTap: () {
  //                 showBottomSheet(
  //                     context: context,
  //                     builder: (context) => Container(
  //                           // height: MediaQuery.of(context).size.height * 0.70,
  //                           color: Colors.red,
  //                         ));
  //                 // setState(() {
  //                 //   masterName = n.data['name'];
  //                 // });
  //               },
  //             ),
  //           );
  //         });
  //       }
  //     } catch (e) {
  //       print(
  //         e.toString(),
  //       );
  //     }
  //   }
  // }


  List<String> catsSelector = [];
  final saveBoxCat = GetStorage();


  getCategory() async {
    try {
      DocumentSnapshot catsFurure = await Firestore.instance
          .collection('category')
          .document('BY7oiRIc6uq14MwsJ9yV')
          .get();
      List<String> cats = catsFurure.data['cats'].cast<String>();
      setState(() {
        catsSelector = cats;
      });
      saveBoxCat.write('cats', catsSelector);


    }catch(e){
      print(e);
      catsSelector = saveBoxCat.read('cats');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // showMarkers1();
    getLocation();
    getIosPermission();
    getCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.maxFinite,
            child: DropdownButton<String>(
              dropdownColor: Colors.lightBlue,
              focusColor: Colors.white,
              style: TextStyle(color: Colors.white),
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              isExpanded: true,
              hint: Text(
                'Выберите мастера',
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              value: _chosenValue,
              items: catsSelector.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (String value) {
                setState(() {
                  _chosenValue = value;
                  _chosenValueArr.clear();
                  _chosenValueArr.add(_chosenValue);

                  print('1111$_chosenValueArr');
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('masters')
            .where('category',
                arrayContainsAny:
                    _chosenValueArr == null || _chosenValueArr.isEmpty
                        ? _chosenValueArrALL
                        : _chosenValueArr)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.connectionState == ConnectionState.done)
            context.watch<DataProvider>().getUserPosition(startLocation);
          print(snapshot.data.documents.length);
          masters.clear();

          for (var n in snapshot.data.documents
              .where((element) => element['blocked'] == false)) {
            print(snapshot.data.documents.length);
            // masters.clear();
            masters.add(
              Marker(
                markerId: MarkerId(n.documentID),
                infoWindow: InfoWindow(title: '${n.data['name']}'),
                position: LatLng(
                    n.data['geoPoint'].latitude, n.data['geoPoint'].longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                onTap: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (context) => Wrap(children: [
                      Container(
                        height: MediaQuery.of(context).size.height,
                        child: SingleChildScrollView(
                          child: ModalMasterProfile(
                            masterId: n.data['userId'],
                            phoneNumber: n.data['phoneNumber'],
                            masterNameFromFb: n.data['name'],
                          ),
                        ),
                      ),
                    ]),
                  );
                  // showBottomSheet(
                  //   context: context,
                  //   builder: (context) => Container(
                  //     height: MediaQuery.of(context).size.height,
                  //     child: ModalMasterProfile(
                  //       masterId: n.data['userId'],
                  //     ),
                  //   ),
                  //
                  // );
                },
              ),
            );
          }

          return FutureBuilder(
              future: getLocation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.connectionState == ConnectionState.done)
                  context.watch<DataProvider>().getUserPosition(snapshot.data);
                return GoogleMap(
                  markers: masters,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  initialCameraPosition:
                      CameraPosition(target: snapshot.data, zoom: 12),
                  mapType: MapType.normal,
                );
                return Center(child: Container());
              });
          return Center(child: Container());
        },
      ),
    );
  }
}
