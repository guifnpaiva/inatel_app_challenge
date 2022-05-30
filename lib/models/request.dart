import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestInstaller{

  late int planId;
  late int installerId;
  late int userId;
  late double lat;
  late double lng;
  String? referenceId;

  RequestInstaller({
    required this.planId,
    required this.installerId,
    required this.userId,
    required this.lat,
    required this.lng,
    this.referenceId,
  });

  factory RequestInstaller.fromSnapshot(DocumentSnapshot snapshot) {
    final Requested = RequestInstaller.fromJson(snapshot.data() as Map<String, dynamic>);
    Requested.referenceId = snapshot.reference.id;
    return Requested;
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': this.planId,
      'installerId': this.installerId,
      'userId': this.userId,
      'lat': this.lat,
      'lng': this.lng,
    };
  }

  factory RequestInstaller.fromJson(Map<String, dynamic> json) {
    return RequestInstaller(
      planId: json['planId'] as int,
      installerId: json['installerId'] as int,
      userId: json['userId'] as int,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
    );
  }
}