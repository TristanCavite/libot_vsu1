import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OsmMap extends StatefulWidget {
  // Callbacks for interactive mode
  final void Function(LatLng)? onPickupChanged;
  final void Function(LatLng)? onDestinationChanged;

  // Optional initial pins for readonly mode
  final LatLng? initialPickupPin;
  final LatLng? initialDestinationPin;

  // If true, disables interaction (e.g. preview only)
  final bool isReadOnly;

  const OsmMap({
    super.key,
    this.onPickupChanged,
    this.onDestinationChanged,
    this.initialPickupPin,
    this.initialDestinationPin,
    this.isReadOnly = false,
  });

  @override
  State<OsmMap> createState() => _OsmMapState();
}

class _OsmMapState extends State<OsmMap> {
  LatLng? currentPosition;
  LatLng? pickupMarker;
  LatLng? destinationMarker;
  String activeMarker = 'pickup'; // Default to pickup mode

  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    pickupMarker = widget.initialPickupPin;
    destinationMarker = widget.initialDestinationPin;
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    LatLng gps = LatLng(pos.latitude, pos.longitude);

    setState(() {
      currentPosition = gps;
      // Only auto-set pickup if not readonly and not already given
      if (!widget.isReadOnly && pickupMarker == null) {
        pickupMarker = gps;
        if (widget.onPickupChanged != null) {
          widget.onPickupChanged!(gps);
        }
      }
    });

    mapController.move(gps, 17);
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
                  onTap: widget.isReadOnly
                      ? null
                      : (_, point) {
                          setState(() {
                            if (activeMarker == 'pickup') {
                              pickupMarker = point;
                              if (widget.onPickupChanged != null) {
                                widget.onPickupChanged!(point);
                              }
                            } else {
                              destinationMarker = point;
                              if (widget.onDestinationChanged != null) {
                                widget.onDestinationChanged!(point);
                              }
                            }
                          });
                        },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.libot_vsu1',
                  ),
                  MarkerLayer(
                    markers: [
                      if (pickupMarker != null)
                        Marker(
                          point: pickupMarker!,
                          width: 50,
                          height: 50,
                          child: const Icon(Icons.location_on,
                              color: Colors.green, size: 40),
                        ),
                      if (destinationMarker != null)
                        Marker(
                          point: destinationMarker!,
                          width: 50,
                          height: 50,
                          child: const Icon(Icons.flag,
                              color: Colors.red, size: 40),
                        ),
                    ],
                  ),
                ],
              ),

              // 📍 Recenter button (only active if not readonly)
              if (!widget.isReadOnly)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    elevation: 3,
                    onPressed: () {
                      if (currentPosition != null) {
                        mapController.move(currentPosition!, 17);
                        setState(() {
                          pickupMarker = currentPosition!;
                        });
                        if (widget.onPickupChanged != null) {
                          widget.onPickupChanged!(currentPosition!);
                        }
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                ),

              // 🟢 Toggle pickup/destination mode (only shown if interactive)
              if (!widget.isReadOnly)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'pickup',
                        backgroundColor: activeMarker == 'pickup'
                            ? Colors.green
                            : Colors.grey[300],
                        onPressed: () {
                          setState(() => activeMarker = 'pickup');
                        },
                        child: const Icon(Icons.place, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'destination',
                        backgroundColor: activeMarker == 'destination'
                            ? Colors.red
                            : Colors.grey[300],
                        onPressed: () {
                          setState(() => activeMarker = 'destination');
                        },
                        child: const Icon(Icons.flag, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          );
  }
}
