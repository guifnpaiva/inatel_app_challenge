import 'package:flutter/material.dart';
import 'package:inatel_app_challenge/screens/home_installer_widget.dart';
import 'package:sizer/sizer.dart';
import '../models/plan.dart';
import '../screens/home_widget.dart';
import '../screens/toogle_widget.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
        builder: (context, orientation, deviceType){
          return const MaterialApp(
            title: "Plantão",
            debugShowCheckedModeBanner: false,
            home: InitScreen(),
            routes: {},
          );
        }
    );
  }
}