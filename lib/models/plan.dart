import 'dart:convert';
import 'package:http/http.dart' as http;

class Plan {
  late final int id;
  late final String isp;
  late final String data_capacity;
  late final String download_speed;
  late final String upload_speed;
  late final String description;
  late final String price;
  late final String type_net;

  Plan({
    required this.id,
    required this.isp,
    required this.data_capacity,
    required this.download_speed,
    required this.upload_speed,
    required this.description,
    required this.price,
    required this.type_net,
  });

  // From JSON
  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'isp': this.isp,
      'data_capacity': this.data_capacity,
      'download_speed': this.download_speed,
      'upload_speed': this.upload_speed,
      'description': this.description,
      'price': this.price,
      'type_net': this.type_net,
    };
  }

  // To JSON
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as int,
      isp: json['isp'] == null ? "Unknown": json["isp"],
      data_capacity: json['data_capacity'] == null ? "Unknown" : json["data_capacity"].toString(),
      download_speed: json['download_speed'] == null ? "Unknown" : json["download_speed"].toString(),
      upload_speed: json['upload_speed'] == null ? "Unknown" : json["upload_speed"].toString(),
      description: json['description'] == null ? "No Description Avaliable": json["description"],
      price: json['price_per_month'] == null ? "Unknown" : json["price_per_month"].toString(),
      type_net: json['type_of_internet'] == null ? "Unknown": json["type_of_internet"],
    );
  }

}

List<Plan> parsePlans(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Plan>((json) =>Plan.fromJson(json)).toList();
}

Future<List<Plan>> fetchPlans(String state) async {
  String url = 'https://app-challenge-api.herokuapp.com/plans';
  if(state != ""){
    url += "?state=$state";
  }
  var aux = Uri.parse(url);
  final response = await http.get(aux);
  if (response.statusCode == 200) {
    return parsePlans(response.body);
  } else {
    throw Exception('Unable to fetch products from the REST API');
  }
}

Future<Plan> fetchPlansId(String id) async {
  String url = 'https://app-challenge-api.herokuapp.com/plans/$id';
  var aux = Uri.parse(url);
  final response = await http.get(aux);
  if (response.statusCode == 200) {
    return Plan.fromJson(json.decode(response.body));
  } else {
    throw Exception('Unable to fetch products from the REST API');
  }
}