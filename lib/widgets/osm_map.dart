import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OsmMap extends StatefulWidget {
  final void Function(LatLng)? onLocationChanged; // 🧭 Step 3A: callback

  const OsmMap({super.key, this.onLocationChanged}); // 💡 accept from parent

  @override
  State<OsmMap> createState() => _OsmMapState();
}

class _OsmMapState extends State<OsmMap> {
  LatLng? currentPosition;  // 📍 User’s current location
  LatLng? markerPosition;   // 📌 Movable pin
  final MapController mapController = MapController(); // 🗺️ Controls the map

  @override
  void initState() {
    super.initState();
    _fetchLocation(); // 🔁 Get user location
  }

  // 🛰️ Step 3A: Fetch and send user location
  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    LatLng gps = LatLng(pos.latitude, pos.longitude);

    setState(() {
      currentPosition = gps;
      markerPosition = gps;
    });

    // 🚀 Move camera
    Future.delayed(const Duration(milliseconds: 300), () {
      mapController.move(gps, 17);
    });

    // 🔁 Notify parent widget about initial marker
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(gps);
    }
  }

  @override
  Widget build(BuildContext context) {
    return currentPosition == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentPosition!,
                  initialZoom: 17,
                  onTap: (tapPos, point) {
                    setState(() => markerPosition = point); // ✅ Move pin
                    if (widget.onLocationChanged != null) {
                      widget.onLocationChanged!(point); // 🔁 Update parent
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.libot_vsu1',
                  ),
                  if (markerPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: markerPosition!,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                ],
              ),

              // 👁️ Recenter to current GPS
              Positioned(
                bottom: 10,
                left: 10,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  elevation: 3,
                  onPressed: () {
                    if (currentPosition != null) {
                      mapController.move(currentPosition!, 17);
                      setState(() {
                        markerPosition = currentPosition;
                      });

                      // 🛰️ Send back updated current location
                      if (widget.onLocationChanged != null) {
                        widget.onLocationChanged!(currentPosition!);
                      }
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ],
          );
  }
}
