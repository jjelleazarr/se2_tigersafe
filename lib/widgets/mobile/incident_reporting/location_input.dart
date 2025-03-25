import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:se2_tigersafe/widgets/mobile/incident_reporting/map_screen.dart';
class LocationInput extends StatefulWidget {
  final Function(String locationName) onSelectPlace;

  const LocationInput({super.key, required this.onSelectPlace});

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  String? _previewImageUrl;
  LatLng? _pickedLocation;

  void _showPreview(double lat, double lng) {
    final staticMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=600x300&maptype=roadmap'
        '&markers=color:red%7Clabel:A%7C$lat,$lng&key=YOUR_GOOGLE_API_KEY';
    setState(() {
      _previewImageUrl = staticMapUrl;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locData = await loc.Location().getLocation();
      _selectPlace(locData.latitude!, locData.longitude!);
    } catch (e) {
      return;
    }
  }

  Future<void> _selectOnMap() async {
    final LatLng? selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => const MapScreen(),
      ),
    );

    if (selectedLocation == null) return;

    _selectPlace(selectedLocation.latitude, selectedLocation.longitude);
  }

  Future<void> _selectPlace(double lat, double lng) async {
    _pickedLocation = LatLng(lat, lng);
    _showPreview(lat, lng);

    final placemarks = await placemarkFromCoordinates(lat, lng);
    final place = placemarks.first;
    final address = '${place.name}, ${place.locality}, ${place.country}';

    widget.onSelectPlace(address);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey),
          ),
          child: _previewImageUrl == null
              ? const Text('No location chosen', textAlign: TextAlign.center)
              : Image.network(_previewImageUrl!, fit: BoxFit.cover, width: double.infinity),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
              onPressed: _getCurrentLocation,
            ),
            TextButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
              onPressed: _selectOnMap,
            ),
          ],
        ),
      ],
    );
  }
}