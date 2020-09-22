import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:provider/provider.dart';


class AddMarker extends StatefulWidget {
  @override
  _AddMarkerState createState() => _AddMarkerState();
}

class _AddMarkerState extends State<AddMarker> {

  Future<LatLng> getLocation() async {
    Position position =
    await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);

    LatLng _startTarget = LatLng(position.latitude, position.longitude);

    return _startTarget;
  }

  LatLng _startTarget = LatLng(45.048584, 38.952727);
  List<Marker> masterMarker = [];

  _handleTap(LatLng tappedPoint){
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
  Widget build(BuildContext context) {
    LatLng startUserPosProvider = context.watch<DataProvider>().userPositionProvider;
    return Scaffold(
      appBar: AppBar(
        title: Text('Укажите ваше местоположение'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context,masterMarker);
            },
          ),
        ],
        centerTitle: true,
      ),
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: CameraPosition(target: startUserPosProvider, zoom: 12),
        mapType: MapType.normal,
        markers: Set.from(masterMarker),
        onTap: _handleTap,
      ),
    );
  }
}
