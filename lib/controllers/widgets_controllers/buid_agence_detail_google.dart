import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connect_kasa/core/utils/app_logger.dart';
import 'package:connect_kasa/vues/widget_view/components/app_loader.dart';

class AgencyDetailsWidget extends StatelessWidget {
  final String address;
  final String agencyName;

  const AgencyDetailsWidget({super.key, 
    required this.address,
    required this.agencyName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Location>>(
      future: locationFromAddress(address),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppLoader());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text('Erreur lors de la récupération de la position'));
        } else {
          final location = snapshot.data!.first;
          final center = LatLng(location.latitude, location.longitude);
          appLog(center);

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
