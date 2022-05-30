import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Installers{
  late final int id;
  late final String name;
  late final String rating;
  late final String price_per_km;
  late final LatLng coordinates;

  Installers({
    required this.id,
    required this.name,
    required this.rating,
    required this.price_per_km,
    required this.coordinates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'rating': this.rating,
      'price_per_km': this.price_per_km,
      'coordinates': this.coordinates,
    };
  }

  factory Installers.fromJson(Map<String, dynamic> json) {
    return Installers(
      id: json['id'] as int,
      name: json['name'].toString(),
      rating: json['rating'].toString(),
      price_per_km: json['price_per_km'].toString(),
      coordinates: LatLng(json['lat'] as double, json["lng"] as double),
    );
  }
}

List<Installers> parseInstallers(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Installers>((json) =>Installers.fromJson(json)).toList();
}

Future<List<Installers>> fetchInstallers(String id) async {
  String url = 'https://app-challenge-api.herokuapp.com/installers';
  if(id != ""){
    url += "?plan=$id";
  }
  var aux = Uri.parse(url);
  final response = await http.get(aux);
  if (response.statusCode == 200) {
    return parseInstallers(response.body);
  } else {
    throw Exception('Unable to fetch products from the REST API');
  }
}