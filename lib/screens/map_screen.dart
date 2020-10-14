import 'package:basic_utils/basic_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
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
  List _chosenValueArrALL = ['1все'];

  Set<Marker> masters = {};
  String masterName;
  LatLng startLocation;
  LatLng startLocationError = LatLng(55.749711, 37.616806);
  final box = GetStorage();
  

  Future<LatLng> getLocation() async {
    Position position =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print('234$position');
    // startLocation = LatLng(position.latitude, position.longitude);
    LatLng _startTarget = LatLng(position.latitude, position.longitude);

    startLocation = _startTarget;

    return _startTarget;
  }

  getIosPermission() async {
    // bool isLocationServiceEnabled  = await isLocationServiceEnabled();
    LocationPermission permission = await requestPermission();
  }

  List<String> catsSelector = [];
  List<String> catsSelector2 = [];
  List<String> catsSelector3 = [];
  final saveBoxCat = GetStorage();

  getCategory() async {
    try {
      DocumentSnapshot catsFurure = await Firestore.instance
          .collection('category')
          .document('BY7oiRIc6uq14MwsJ9yV')
          .get();
      List<String> cats = catsFurure.data['cats'].cast<String>();

      setState(() {
        catsSelector = cats..sort((String a, String b) => a.compareTo(b));
      });
      saveBoxCat.write('cats', catsSelector);
    } catch (e) {
      print(e);
      catsSelector = saveBoxCat.read('cats');
    }
  }

  getMarkers() async {

    final snapshot = await Firestore.instance
        .collection('masters')
        .where('category',
            arrayContainsAny: _chosenValueArr == null || _chosenValueArr.isEmpty
                ? _chosenValueArrALL
                : _chosenValueArr)
        .getDocuments();
    masters.clear();

    setState(() {});

    for (var n
        in snapshot.documents.where((element) => element['blocked'] == false)) {
      print(snapshot.documents.length);
      // masters.clear();
      masters.add(
        Marker(
          markerId: MarkerId(n.documentID),
          infoWindow: InfoWindow(title: '${n.data['name']}'),
          position:
              LatLng(n.data['geoPoint'].latitude, n.data['geoPoint'].longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
                      masterCategoryFromFb: n.data['category'].cast<String>(),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      );
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // showMarkers1();
    getLocation().catchError((e) {
      return PlatformAlertDialog(
        title: 'Внимание',
        content: 'Не удалось получить координаты',
        defaultActionText: 'Ok',
      ).show(context);
    });
    getIosPermission();
    getCategory();
    getMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if(masters.isEmpty && startLocation != null){
      getMarkers();
    }

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
                    StringUtils.capitalize(value).replaceAll("1", ''),
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (String value) {
                setState(() {
                  _chosenValue = value;
                  _chosenValueArr.clear();
                  _chosenValueArr.add(_chosenValue);
                });
                getMarkers();
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder(
          future: getLocation().timeout(const Duration (seconds:10),onTimeout : getLocation),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              context.watch<DataProvider>().getUserPosition(snapshot.data);
              return GoogleMap(
                markers: masters,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                initialCameraPosition: CameraPosition(
                    target: snapshot.data ?? startLocationError, zoom: 12),
                mapType: MapType.normal,
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}
