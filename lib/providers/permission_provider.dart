import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationProviderStatus {
  Initial,
  Loading,
  Success,
  Error,
}

class LocationProvider with ChangeNotifier {
  late Position _userLocation;

  LocationProviderStatus _status = LocationProviderStatus.Initial;

  Position get userLocation => _userLocation;

  LocationProviderStatus get status => _status;

  Future<void> getLocation() async {

    await Geolocator.checkPermission().then((LocationPermission value) async {
      if(value == null || value == LocationPermission.denied || value == LocationPermission.deniedForever ) {
        _updateStatus(LocationProviderStatus.Loading);
        await Geolocator.requestPermission().then((value) async {
          if(value == LocationPermission.whileInUse || value == LocationPermission.always){
            await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
                .timeout(Duration(seconds: 20))
                .then((value) {
              _userLocation = value;
              _updateStatus(LocationProviderStatus.Success);
            }).catchError((e) => _updateStatus(LocationProviderStatus.Error));
          }
        }).catchError((e) => _updateStatus(LocationProviderStatus.Error));
      } else {
        _updateStatus(LocationProviderStatus.Loading);
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .timeout(Duration(seconds: 20))
            .then((value) {
          _userLocation = value;
          _updateStatus(LocationProviderStatus.Success);
        }).catchError((e) => _updateStatus(LocationProviderStatus.Error));
      }
    });
  }

  void _updateStatus(LocationProviderStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }
}