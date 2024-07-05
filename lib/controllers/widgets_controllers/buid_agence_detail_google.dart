import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AgencyDetailsWidget extends StatelessWidget {
  final String address;
  final String agencyName;

  AgencyDetailsWidget({
    required this.address,
    required this.agencyName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Location>>(
      future: locationFromAddress(address),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Erreur lors de la récupération de la position'));
        } else {
          final location = snapshot.data!.first;
          final center = LatLng(location.latitude, location.longitude);
          print(center);

          return GoogleMap(
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: 15.5,
            ),
            markers: {
              Marker(
                markerId: MarkerId(agencyName),
                position: center,
              )
            },
          );
        }
      },
    );
  }
}
