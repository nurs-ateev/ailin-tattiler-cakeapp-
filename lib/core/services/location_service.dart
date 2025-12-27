import 'package:geolocator/geolocator.dart';

class LocationService {
  // Zhetysay Coordinates
  static const double targetLat = 40.7833;
  static const double targetLng = 68.3167;
  static const double allowedRadiusKm = 20.0;

  /// Checks if the current location is within the allowed radius (Zhetysay 20km).
  /// Throws an String error if location is disabled, permission denied, or outside radius.
  /// Returns the Position if successful.
  Future<Position> verifyLocation() async {
    // 1. Check Service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'GPS выключен. Пожалуйста, включите геолокацию.';
    }

    // 2. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Нет доступа к геолокации. Разрешите доступ в настройках.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Доступ к геолокации заблокирован навсегда. Разрешите в настройках телефона.';
    }

    // 3. Get Position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, // We need good accuracy for address
      ),
    );

    // 4. Calculate Distance
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    double distanceInKm = distanceInMeters / 1000;

    if (distanceInKm > allowedRadiusKm) {
      throw 'Доставка недоступна. Вы находитесь за пределами Жетысая (${distanceInKm.toStringAsFixed(1)} км).';
    }

    return position;
  }
}
