import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationService {
  DeviceLocationService._();

  static final ValueNotifier<String> cityName = ValueNotifier<String>(
    'Finding location…',
  );
  static Future<void>? _loadFuture;

  static void loadIfNeeded() {
    _loadFuture ??= _loadCityName();
  }

  static void retry() {
    if (cityName.value == 'Finding location…') return;
    cityName.value = 'Finding location…';
    _loadFuture = _loadCityName();
  }

  static Future<void> _loadCityName() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        cityName.value = 'Location unavailable';
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        cityName.value = 'Location unavailable';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        cityName.value = 'Current location';
        return;
      }

      final placemark = placemarks.first;
      cityName.value =
          [
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea,
            placemark.country,
          ].firstWhere(
            (value) => value != null && value.trim().isNotEmpty,
            orElse: () => null,
          ) ??
          'Current location';
    } catch (_) {
      cityName.value = 'Location unavailable';
    }
  }
}
