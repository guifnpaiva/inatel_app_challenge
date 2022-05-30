import 'package:flutter/material.dart';
import '../models/plan.dart';

class PlanProvider with ChangeNotifier {
  PlanProvider();

  List<Plan> plans = [];

  void setPlan(Plan plan) {
    plans.add(plan);
    notifyListeners();
  }
}