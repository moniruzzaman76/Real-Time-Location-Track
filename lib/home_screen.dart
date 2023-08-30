import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? googleMapController;
  LocationData? _myCurrentLocation;
  final List<Polyline> _polylines = [];
  StreamSubscription? _streamSubscription;


  @override
  void initState() {
    super.initState();
    getMyLocation();
  }

  void initial() {
    Location.instance.changeSettings(
      distanceFilter: 10,
      accuracy: LocationAccuracy.high,
      interval: 100000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Real Time Location Tracker"),
      ),
      body: _myCurrentLocation != null
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                //LatLng(24.85304258478126, 89.87674898597133),
                //LatLng(myCurrentLocation!.latitude!,myCurrentLocation!.latitude!)
                target: LatLng(_myCurrentLocation!.latitude!,
                    _myCurrentLocation!.latitude!),
                tilt: 10,
                zoom: 15,
                bearing: 30,
              ),
              myLocationEnabled: true,
              onMapCreated: (GoogleMapController mapController) {
                googleMapController = mapController;
                getMyLocation();
                listenToMyLocation();
              },
              onTap: (LatLng latLng) {
                print(latLng.toString());
              },
              mapType: MapType.normal,
              markers: <Marker>{
                Marker(
                  markerId: const MarkerId("point_1"),
                  position: LatLng(
                    _myCurrentLocation?.latitude ?? 0,
                    _myCurrentLocation?.longitude ?? 0,
                  ),
                  infoWindow: InfoWindow(
                    title: "My Current Location",
                    snippet:
                        "${_myCurrentLocation?.latitude ?? ""}  ${_myCurrentLocation?.longitude ?? ""}",
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              },
        polylines: Set<Polyline>.of(_polylines),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              getMyLocation();
              listenToMyLocation();
            },
            child: const Icon(Icons.location_on),
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton(
            onPressed: () {
              stopListenLocation();
            },
            child: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> getMyLocation() async {
    await Location.instance.requestPermission();
    await Location.instance.hasPermission();

    _myCurrentLocation = await Location.instance.getLocation();
    print(_myCurrentLocation);
    if (mounted) {
      setState(() {});
    }
    googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(_myCurrentLocation!.latitude!, _myCurrentLocation!.longitude!,),
        15)
    );

    // if(_myCurrentLocation != null && googleMapController != null){
    //   googleMapController?.animateCamera(CameraUpdate.newLatLngZoom(
    //       LatLng(_myCurrentLocation!.latitude!, _myCurrentLocation!.longitude!,),
    //       15
    //   ));
    // }

  }

  void listenToMyLocation() {
    _streamSubscription = Location.instance.onLocationChanged.listen((LocationData location) {
      if (location != _myCurrentLocation) {
        if (_myCurrentLocation != null) {
          final newPolyline = Polyline(
            polylineId: PolylineId('polyline_id_${_polylines.length}'),
            color: Colors.blue,
            points: [
              LatLng(_myCurrentLocation!.latitude!, _myCurrentLocation!.longitude!),
              LatLng(location.latitude!, location.longitude!),
            ],
          );
          _polylines.add(newPolyline);
          setState(() {});
        }
        _myCurrentLocation = location;
      }
    });
  }


  void stopListenLocation() {
    _streamSubscription?.cancel();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

}
