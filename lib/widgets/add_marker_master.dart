import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:provider/provider.dart';

class AddMarker extends StatefulWidget {
  @override
  _AddMarkerState createState() => _AddMarkerState();
}

class _AddMarkerState extends State<AddMarker> {
  final box = GetStorage();

  LatLng ifNullPosition;
  LatLng startLocationError = LatLng(55.749711, 37.616806);


  Future<LatLng> getLocation() async {
    Position position =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    // startLocation = LatLng(position.latitude, position.longitude);
    LatLng _startTarget = LatLng(position.latitude, position.longitude) ?? startLocationError;

    return _startTarget;
  }

  LatLng _startTarget = LatLng(45.048584, 38.952727);
  List<Marker> masterMarker = [];

  _handleTap(LatLng tappedPoint) {
    setState(() {
      masterMarker = [];
      masterMarker.add(
        Marker(
          markerId: MarkerId(tappedPoint.toString()),
          position: tappedPoint,
        ),
      );
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    LatLng startUserPosProvider =
        context.watch<DataProvider>().userPositionProvider;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ваше местоположение?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, masterMarker);
            },
          ),
        ],
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: getLocation().timeout(const Duration (seconds:10),onTimeout : getLocation).catchError((e) {
          return PlatformAlertDialog(
            title: 'Внимание',
            content: 'Не удалось получить координаты',
            defaultActionText: 'Ok',
          ).show(context);
        }),
        builder: (context, snapshot) {
          
          if(snapshot.hasData){
            return GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              initialCameraPosition:
              CameraPosition(target: snapshot.data, zoom: 12),
              mapType: MapType.normal,
              markers: Set.from(masterMarker),
              onTap: _handleTap,
            );
          }


          return Center(child: CircularProgressIndicator(),);
        },
      ),
    );
  }
}
