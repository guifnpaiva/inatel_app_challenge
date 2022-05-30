import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateDistance(LatLng latlgn1, LatLng latlgn2) {
  double lat1 = latlgn1.latitude;
  double lon1 = latlgn1.longitude;
  double lat2 = latlgn2.latitude;
  double lon2 = latlgn2.longitude;

  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

String calculatePrice(LatLng latlgn1, LatLng latlgn2, String price_per_km) {
  double dist = calculateDistance(latlgn1, latlgn2);
  double price = double.parse(price_per_km);
  return (price*dist).toStringAsFixed(2);
}