import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_sliding_up_panel/sliding_up_panel_widget.dart';
import 'package:flutter_zoom_drawer/config.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:inatel_app_challenge/models/request.dart';
import 'package:sizer/sizer.dart';
import '../core/core.dart';
import '../helpers/dblogics.dart';
import 'package:inatel_app_challenge/utils/reusable_functions.dart';
import '../models/plan.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../providers/providerPlan.dart';


class HomeInstaller extends StatefulWidget {
  const HomeInstaller({Key? key}) : super(key: key);

  @override
  State<HomeInstaller> createState() => _HomeInstallerState();
}

class _HomeInstallerState extends State<HomeInstaller> {

  late GoogleMapController mapController;
  late String _mapStyle;
  late Position position;
  final DataRepository repository = DataRepository();
  SlidingUpPanelController _panelController = SlidingUpPanelController();
  List<RequestInstaller> request = [];
  late String username;
  final LatLng simulatedPos = const LatLng(-22.2521628, -45.7037394);
  bool onRequest = false;
  late RequestInstaller selected;
  late Set<Marker> markers = Set();
  late PolylinePoints polylinePoints;
  final ZoomDrawerController _drawerController = ZoomDrawerController();


  // List of coordinates to join
  List<LatLng> polylineCoordinates = [];

  // Map storing polylines created by connecting two points
  Map<PolylineId, Polyline> polylines = {};

  // Create the polylines for showing the route between two places
  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    // Initializing PolylinePoints
    polylines = {};
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for
    // drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyDZOu6KiGw3x0uOGrssuWOSpPCVaAliPzg", // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    // Defining an ID
    PolylineId id = PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.redAccent,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    polylines[id] = polyline;

    setState((){});

    zoomPolyline(polylineCoordinates);
  }

  void zoomPolyline(List<LatLng> coords){
    LatLng coord = coords.elementAt(coords.length~/2);
    mapController.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
                target: coord,
                zoom: 9
            )
        )
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    mapController.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
                target: simulatedPos,
                zoom: 15
            )
        )
    );
    setState((){
      markers.add(
          Marker(
              markerId: MarkerId(simulatedPos.toString()),
              position: simulatedPos,
              icon: BitmapDescriptor.defaultMarker
          )
      );
    });
  }

  @override
  initState(){
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FullScreen.enterFullScreen(FullScreenMode.EMERSIVE_STICKY);
      rootBundle.loadString('assets/style/mapStyle.json').then((string) {
        _mapStyle = string;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF0D1724),
        body: ZoomDrawer(
          controller: _drawerController,
          openCurve: Curves.fastOutSlowIn,
          style: DrawerStyle.defaultStyle,
          showShadow: false,
          slideWidth: 65.0.w,
          angle: 0.0,
          mainScreenTapClose: true,
          disableDragGesture: true,
          mainScreen: ChangeNotifierProvider<LocationProvider>(
            create: (_) => LocationProvider(),
            builder: (context, snapshot){
              final locationProvider = Provider.of<LocationProvider>(context);
              if(locationProvider.status == LocationProviderStatus.Initial)
                locationProvider.getLocation();
              if(locationProvider.status == LocationProviderStatus.Error){
                return Center(
                  child: Text(
                    "An Error Occurs",
                    style: infoColPanel,
                  ),
                );
              }
              else if(locationProvider.status == LocationProviderStatus.Loading ||
                  locationProvider.status == LocationProviderStatus.Initial){
                return Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text(
                        "Get Location",
                        style: infoColPanel,
                      ),
                    ],
                  ),
                );
              }
              else {
                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      //Enabled on Real Application
                      //myLocationEnabled: true,
                      markers: markers,
                      polylines: Set<Polyline>.of(polylines.values),
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: simulatedPos,
                        zoom: 5.0,
                      ),
                    ),

                    // Menu Button
                    Positioned(
                      top: 5.0.h,
                      left: 5.0.w,
                      right: 80.0.w,
                      child: TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white,
                            backgroundColor: Colors.black.withOpacity(0.95),
                            onSurface: Colors.grey,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                          onPressed: () => _drawerController.open!(),
                          child: Container(
                            height: 5.0.h,
                            child: const Center(
                              child: Icon(
                                  Icons.menu
                              ),
                            ),
                          )
                      ),
                    ),

                    Positioned(
                        top: request.isNotEmpty?20.0.h:50.0.h,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SlidingUpPanelWidget(
                          panelController: _panelController,
                          controlHeight: 30.0.h,
                          anchor: 1,
                          child: Container(
                            padding: EdgeInsets.only(left: 7.0.w,top: 5.0.h),
                            decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                )
                            ),
                            child: ChangeNotifierProvider<PlanProvider>(
                              create: (_) => PlanProvider(),
                              child: Column(
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                      stream: repository.getStream(),
                                      builder: (context, snapshot){
                                        request = [];
                                        final planProvider = Provider.of<PlanProvider>(context);
                                        snapshot.data?.docChanges.forEach((obj) {
                                          if(obj.doc.get("installerId") == 37) {
                                            RequestInstaller requests = RequestInstaller.fromSnapshot(obj.doc);
                                            request.add(requests);

                                            fetchPlansId(requests.planId.toString())
                                                .then((value) => {
                                              planProvider.setPlan(value)
                                            });
                                          }
                                        });
                                        return request.isNotEmpty?
                                        ListView.separated(
                                            itemCount: request.length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index){
                                              return Row(
                                                children: [
                                                  Container(
                                                    width: 20.0.w,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        "\$ ${calculatePrice(
                                                            simulatedPos,
                                                            LatLng(request[index].lat, request[index].lng),
                                                            "2.5"
                                                        )}",
                                                        style: priceBig,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 40.0.w,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: RichText(
                                                          textAlign:TextAlign.start,
                                                          text: TextSpan(
                                                              text: "Nome do Usuario \n",
                                                              style: infoColPanel,
                                                              children: [
                                                                TextSpan(
                                                                    text:
                                                                    planProvider.plans.isNotEmpty
                                                                        ?  "${planProvider.plans[index].isp} |  ${planProvider.plans[index].data_capacity} GB"
                                                                        :   "Loading...",
                                                                    style: dataExpPanel
                                                                )
                                                              ]
                                                          )
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.0.w,),
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                            onPressed: ()=>{
                                                              setState((){
                                                                _createPolylines(simulatedPos.latitude,simulatedPos.longitude, request[index].lat,request[index].lng);
                                                                onRequest = true;
                                                                selected = request[index];
                                                                markers.add(
                                                                    Marker(
                                                                        markerId: MarkerId("Destination"),
                                                                        position: LatLng(request[index].lat,request[index].lng),
                                                                        icon: BitmapDescriptor.defaultMarker
                                                                    )
                                                                );
                                                              }),
                                                              _panelController.hide()
                                                            },
                                                            icon: Icon(Icons.check, color: Colors.teal,size: 7.0.w,)),
                                                        IconButton(
                                                            onPressed: ()=>{
                                                              setState((){
                                                                repository.deleteRequest(request[index]);
                                                              })
                                                            },
                                                            icon: Icon(Icons.close, color: Colors.red,size: 7.0.w,)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                            separatorBuilder: (context, int){
                                              return Divider(
                                                color: Colors.white.withOpacity(0.3),
                                              );
                                            }
                                        ):
                                        Center(
                                          child: Text(
                                              "Without Requests",
                                              style: infoColPanel
                                          ),
                                        );
                                      }
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                    ),

                    Visibility(
                      visible: onRequest,
                      child: Positioned(
                        bottom: 2.0.h,
                        left: 5.0.w,
                        right: 5.0.w,
                        child: TextButton(
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.black,
                              onSurface: Colors.grey,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                            ),
                            onPressed: () async {
                              _panelController.collapse();
                              setState((){
                                polylines = {};
                                onRequest = false;
                                repository.deleteRequest(selected);
                                markers.remove(markers.elementAt(1));
                                CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                        target: simulatedPos,
                                        zoom: 15
                                    )
                                );
                              });
                            },
                            child: Container(
                              height: 5.0.h,
                              child: Center(
                                child: Text(
                                  "Done",
                                  style: button,
                                ),
                              ),
                            )
                        ),
                      ),
                    )
                  ],
                );
              }
            },
          ),
          menuScreen: Padding(
            padding: EdgeInsets.only(left: 2.0.w, top: 12.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment(-0.9,0),
                  child: Container(
                    width: 25.0.w,
                    height: 25.0.w,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle
                    ),
                  ),
                ),
                SizedBox(height: 2.0.h,),
                Align(
                  alignment: Alignment(-0.8,0),
                  child: Text(
                    "Nome Installer",
                    style: infoColPanel,
                  ),
                ),
                SizedBox(height: 5.0.h,),
                TextButton(
                  onPressed: (){},
                  style: TextButton.styleFrom(
                      primary: Colors.white
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.house_alt_fill,
                      ),
                      SizedBox(width: 5.0.w,),
                      Text(
                        "Home",
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: (){},
                  style: TextButton.styleFrom(
                      primary: Colors.white
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.money_dollar,
                      ),
                      SizedBox(width: 5.0.w,),
                      Text(
                        "Balance",
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: (){},
                  style: TextButton.styleFrom(
                      primary: Colors.white
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                      ),
                      SizedBox(width: 5.0.w,),
                      Text(
                        "History",
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: (){},
                  style: TextButton.styleFrom(
                      primary: Colors.white
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.profile_circled,
                      ),
                      SizedBox(width: 5.0.w,),
                      Text(
                        "Profile",
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: (){},
                  style: TextButton.styleFrom(
                      primary: Colors.white
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.question,
                      ),
                      SizedBox(width: 5.0.w,),
                      const Text(
                        "Help",
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                      alignment: Alignment(-0.9,0),
                      child: TextButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            primary: Colors.white,
                            side: BorderSide(color: Colors.white),
                            padding: EdgeInsets.symmetric(horizontal: 5.0.w)
                        ),
                        child: const Text(
                          "Log Out",
                        ),
                      )
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
