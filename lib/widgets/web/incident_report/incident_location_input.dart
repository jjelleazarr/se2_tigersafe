import 'package:flutter/material.dart';

class WebLocationInput extends StatefulWidget {
  final Function(String locationName, String staticMapUrl) onLocationSelected;

  const WebLocationInput({super.key, required this.onLocationSelected});

  @override
  State<WebLocationInput> createState() => _WebLocationInputState();
}

class _WebLocationInputState extends State<WebLocationInput> {
  final _locationController = TextEditingController();
  String? _staticMapUrl;

  void _generateMapSnapshot(String location) {
    // Placeholder coordinates for testing; you can replace this with a geocoding service.
    double lat = 14.6091;
    double lng = 121.0223;

    final staticUrl =
        'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=600x300&maptype=roadmap'
        '&markers=color:red%7Clabel:L%7C$lat,$lng&key=YOUR_GOOGLE_API_KEY';

    setState(() {
      _staticMapUrl = staticUrl;
    });

    widget.onLocationSelected(location, staticUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍 Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Enter location manually',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on, color: Colors.amber),
          ),
          onSubmitted: _generateMapSnapshot,
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _staticMapUrl == null
              ? const Center(child: Text('No location selected.'))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_staticMapUrl!, fit: BoxFit.cover),
                ),
        ),
      ],
    );
  }
}
