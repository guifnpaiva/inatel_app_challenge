import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inatel_app_challenge/core/core.dart';
import 'package:inatel_app_challenge/screens/home_installer_widget.dart';
import 'package:inatel_app_challenge/screens/home_widget.dart';
import 'package:sizer/sizer.dart';


class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {

  bool mode = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1724),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            "Choose a Account \nType to Init",
            textAlign: TextAlign.center,
            style: titletoggle,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Installer",
                style: infoColPanel,
              ),
              CupertinoSwitch(
                  value: mode,
                  onChanged: (mode){
                    setState((){
                      this.mode = mode;
                    });
                  }
              ),
              Text(
                "User",
                style: infoColPanel,

              ),
            ],
          ),
          TextButton(
              style: TextButton.styleFrom(
                primary: Colors.black,
                backgroundColor: Colors.white.withOpacity(0.95),
                onSurface: Colors.black,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context){
                   return mode? const Home() : const HomeInstaller();
                  }),
                );
              },
              child: Container(
                height: 5.0.h,
                width: 80.0.w,
                child: Center(
                  child: Text(
                    "Continue",
                    style: buttonBlack,
                  ),
                ),
              )
          ),
        ],
      ),
    );
  }
}
