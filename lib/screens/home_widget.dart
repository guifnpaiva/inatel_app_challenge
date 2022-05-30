import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:inatel_app_challenge/models/request.dart';
import 'package:inatel_app_challenge/utils/reusable_functions.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/core.dart';
import '../helpers/dblogics.dart';
import '../models/plan.dart';
import 'package:geolocator/geolocator.dart';
import  '../models/installers.dart';
import 'package:geocoding/geocoding.dart';

import '../providers/permission_provider.dart';



class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late GoogleMapController mapController;
  late String _mapStyle;
  final LatLng _center = const LatLng(-21.783267, -38.321772);
  late Position position;
  final DataRepository repository = DataRepository();


  late Future<List<Plan>> plans;
  late List<Installers> installers = [];
  late Set<Marker> markes = Set();
  List<Installers> filtered = [];
  NetPanel statePanel = NetPanel.toChose;
  int selectedInstaller = -1;
  late int planId;

  Map<String, String> admArea = {
    "Acre": "AC",
    "Alagoas": "AL",
    "Amapá": "AP",
    "Amazonas": "AM",
    "Bahia": "BA",
    "Ceará": "CE",
    "Distrito Federal": "DF",
    "Espiríto Santo": "ES",
    "Goiás": "GO",
    "Maranhão": "MA",
    "Mato Grosso": "MT",
    "Mato Grosso do Sul": "MS",
    "Minas Gerais": "MG",
    "Pará": "PA",
    "Paraíba": "PB",
    "Paraná": "PR",
    "Pernambuco": "PE",
    "Piauí" : "PI",
    "Rio de Janeiro": "RJ",
    "Rio Grande do Norte": "RN",
    "Rio Grande do Sul": "RS",
    "Rondônia": "RO",
    "Roraima" : "RR",
    "Santa Catarina" : "SC",
    "Sergipe": "SE",
    "Tocantins": "TO"
  };

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    mapController.setMapStyle(_mapStyle);
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    installers = await fetchInstallers("");
    // Adiciona um Novo Instaador para simular a localização da pessoa
    // que abriu o app pelo perfil de instalador
    installers.add(
        Installers(
            id: 37,
            name: "Installer Test",
            rating: "9",
            price_per_km: "2.5",
            coordinates: LatLng(-22.2521628, -45.7037394)
        )
    );
    mapController.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16
            )
        )
    );
    // Config Marker
    BitmapDescriptor customMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48*2)),
        "assets/style/Marker.png"
    ).then((value) => value);

    Set<Marker> marksList = Set();
    installers.forEach((installer) {
      marksList.add(
          Marker(
              markerId: MarkerId(installer.id.toString()),
              position: installer.coordinates,
              icon: customMarker
          )
      );
    });
    setState((){
      markes = marksList;
    });
  }

  Future<List<Plan>>getProjectDetails(LocationProvider provider) async {
    Position pos = provider.userLocation;
    List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    var administrativeArea =
    placemarks.first.administrativeArea!.length > 2
        ? admArea[placemarks.first.administrativeArea]
        : placemarks.first.administrativeArea;
    //var administrativeArea = "MG";

    return fetchPlans(administrativeArea!);
  }

  Future<List<Installers>>getInstallers() async {
    return fetchInstallers("");
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
        body: ChangeNotifierProvider<LocationProvider>(
            create: (_) => LocationProvider(),
            builder: (context, snapshot) {
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
                return FutureBuilder<List<Plan>>(
                    future: getProjectDetails(locationProvider),
                    builder: (context, snapshot){
                      if(snapshot.hasError){
                        // Handle Error
                      }
                      return snapshot.hasData
                          ? Stack(
                        children: [
                          GoogleMap(
                            onMapCreated: _onMapCreated,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: markes,
                            initialCameraPosition: CameraPosition(
                              target: _center,
                              zoom: 15.0,
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
                                onPressed: () => print("click"),
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
                          // Panel to Choose Net Provider
                          Visibility(
                            visible: statePanel == NetPanel.Chosing,
                            child: Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: NetChoose(
                                plans: snapshot.data!,
                                onClose: (close){
                                  setState((){statePanel = NetPanel.toChose;});
                                },
                                onSelect: (idPlan) async {
                                  setState((){
                                    statePanel = NetPanel.Chosed;
                                  });
                                  // TODO Modify to Boost Perfomance
                                  List<Installers> installers = await fetchInstallers(idPlan.toString());
                                  installers.add(
                                      Installers(
                                          id: 37,
                                          name: "Installer Test",
                                          rating: "9",
                                          price_per_km: "2.5",
                                          coordinates: LatLng(-22.2521628, -45.7037394)
                                      )
                                  );
                                  BitmapDescriptor customMarker = await BitmapDescriptor.fromAssetImage(
                                      ImageConfiguration(size: Size(48, 48*2)),
                                      "assets/style/Marker.png"
                                  ).then((value) => value);
                                  Set<Marker> marksList = Set();
                                  installers.forEach((installer) {
                                    marksList.add(
                                        Marker(
                                            markerId: MarkerId(installer.id.toString()),
                                            position: installer.coordinates,
                                            icon: customMarker
                                        )
                                    );
                                  });
                                  setState((){
                                    filtered = installers;
                                    markes = marksList;
                                    planId = idPlan;
                                  });
                                },
                              ),
                            ),
                          ),
                          // Select Net Button
                          Visibility(
                            visible: statePanel == NetPanel.toChose,
                            child: Positioned(
                              bottom: 2.0.h,
                              left: 5.0.w,
                              right: 5.0.w,
                              child: TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Colors.white,
                                    backgroundColor: Colors.black.withOpacity(0.95),
                                    onSurface: Colors.grey,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(10))
                                    ),
                                  ),
                                  onPressed: () => {setState((){statePanel = NetPanel.Chosing;})},
                                  child: Container(
                                    height: 5.0.h,
                                    child: Center(
                                      child: Text(
                                        "Select a Net Provider",
                                        style: button,
                                      ),
                                    ),
                                  )
                              ),
                            ),
                          ),

                          // Select Installer
                          Visibility(
                              visible: statePanel == NetPanel.Chosed && filtered.isNotEmpty,
                              child: Positioned(
                                bottom: 2.0.h,
                                left: 5.0.w,
                                right: 5.0.w,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 25.0.h,
                                      width: 90.0.w,
                                      padding: EdgeInsets.symmetric(horizontal: 4.0.w,vertical: 1.0.h),
                                      decoration: const BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)
                                          )
                                      ),
                                      child: Column(
                                        children: [
                                          RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                                text: "${filtered.length} Found\n",
                                                style: titleExpPanel,
                                                children: [
                                                  TextSpan(
                                                      text: "Select One",
                                                      style: dataExpPanel
                                                  )
                                                ]
                                            ),
                                          ),
                                          SizedBox(height: 2.0.h,),
                                          Expanded(
                                            child: ListView.builder(
                                                itemCount: filtered.length,
                                                scrollDirection: Axis.horizontal,
                                                itemBuilder: (context,index){
                                                  return GestureDetector(
                                                    onTap: () => {
                                                      setState((){
                                                        selectedInstaller = index;
                                                      })
                                                    },
                                                    child: Container(
                                                      width: 30.0.w,
                                                      child: Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          Positioned(
                                                            top: 0,
                                                            child: Column(
                                                              children: [
                                                                Container(
                                                                  height: 20.0.w,
                                                                  width: 20.0.w,
                                                                  decoration: BoxDecoration(
                                                                      color: Colors.white.withOpacity(0.15),
                                                                      border:
                                                                      selectedInstaller == index ? Border.all(color: Colors.white): Border.all(),
                                                                      borderRadius: const BorderRadius.all(
                                                                          Radius.circular(10)
                                                                      )
                                                                  ),
                                                                ),
                                                                SizedBox(height: 1.0.h,),
                                                                RichText(
                                                                  textAlign: TextAlign.center,
                                                                  text: TextSpan(
                                                                      text: "${filtered[index].name}\n",
                                                                      style: infoColPanel,
                                                                      children: [
                                                                        TextSpan(
                                                                            text: "\$ ${calculatePrice(LatLng(position.latitude, position.longitude), filtered[index].coordinates,filtered[index].price_per_km)}",
                                                                            style: price
                                                                        )
                                                                      ]
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // Price Tag
                                                          Positioned(
                                                            top: 1.0.h,
                                                            right: 0,
                                                            child: Container(
                                                              height: 6.0.w,
                                                              width: 14.0.w,
                                                              decoration: BoxDecoration(
                                                                  color: Colors.amber,
                                                                  borderRadius: BorderRadius.all(
                                                                    Radius.circular(5),
                                                                  )
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Text(
                                                                    "${filtered[index].rating} ",
                                                                    style: rating,
                                                                  ),
                                                                  Icon(
                                                                    Icons.star,
                                                                    size: 4.0.w,
                                                                    color: Colors.white,
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 2.0.h,),
                                    Row(
                                      children: [
                                        TextButton(
                                            style: TextButton.styleFrom(
                                              primary: Colors.white,
                                              backgroundColor: Colors.red,
                                              onSurface: Colors.grey,
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(10))
                                              ),
                                            ),
                                            onPressed: () => {setState((){statePanel = NetPanel.toChose;})},
                                            child: Container(
                                              height: 5.0.h,
                                              child: const Center(
                                                child: Icon(
                                                    Icons.close
                                                ),
                                              ),
                                            )
                                        ),
                                        SizedBox(width: 5.0.w,),
                                        Expanded(
                                          child: TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Colors.white,
                                                backgroundColor: Colors.teal,
                                                onSurface: Colors.grey,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                                ),
                                              ),
                                              onPressed: () async {
                                                Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                                                RequestInstaller req = RequestInstaller(
                                                  planId: planId,
                                                  installerId: filtered[selectedInstaller].id,
                                                  userId: 1,
                                                  lat: pos.latitude,
                                                  lng: pos.longitude,
                                                );

                                                repository.addRequest(req);
                                                setState((){
                                                  statePanel = NetPanel.Send;
                                                });
                                              },
                                              child: Container(
                                                height: 5.0.h,
                                                child: Center(
                                                  child: Text(
                                                    "Confirm",
                                                    style: button,
                                                  ),
                                                ),
                                              )
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              )
                          ),

                          // Mensagem Erro ou Concluído
                          Visibility(
                            visible: statePanel == NetPanel.Send,
                            child: Positioned(
                              bottom: 2.0.h,
                              left: 5.0.w,
                              right: 5.0.w,
                              child: Container(
                                height: 25.0.h,
                                width: 90.0.w,
                                padding: EdgeInsets.symmetric(horizontal: 4.0.w,vertical: 1.0.h),
                                decoration: const BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(20)
                                    )
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 5.0.h,color: Colors.lightGreenAccent,),
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                          text: "\Successful!\n",
                                          style: titleExpPanel,
                                          children: [
                                            TextSpan(
                                                text: "The request has been sent to the installer,\n we will notify you as soon as it accepts",
                                                style: dataExpPanel
                                            )
                                          ]
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                          :  Container(
                              width: double.maxFinite,
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                Text(
                                  "Get Maps Info",
                                  style: infoColPanel,
                                ),
                              ],
                            ),
                          );
                    }
                );
              }

            }
        )
    );
  }
}

class NetChoose extends StatefulWidget {

  final List<Plan> plans;
  Function(bool)? onClose;
  Function(int idPlan)? onSelect;
  NetChoose({Key? key, required this.plans, this.onClose, this.onSelect}) : super(key: key);

  @override
  State<NetChoose> createState() => _NetChoose();
}

class _NetChoose extends State<NetChoose>{
  List<Map<String,List<Plan>>> plans = [];
  int index = 0;
  int indexPlan = 0;

  @override
  initState(){
    Map<String,List<Plan>> planFormat = {};
    widget.plans.forEach((plan){
      if(planFormat.containsKey(plan.isp)){
        planFormat.update(plan.isp, (value){
          value.add(plan);
          return value;
        });
      }
      else{
        planFormat[plan.isp] = [plan];
      }
    });
    planFormat.forEach((key, value) {
      plans.add({key:value});
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.only(left: 7.0.w, right: 7.0.w, top: 3.0.h),
      decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              topLeft: Radius.circular(25)
          )
      ),
      height: 60.0.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: "Net Provider\n",
              style: titleExpPanel,
              /*
                children: [
                  TextSpan(
                      text: "Tap to See More",
                      style: hint
                  )
                ]*/
            ),
          ),
          SizedBox(height: 2.0.h,),
          Container(
              height: 15.0.h,
              width: double.maxFinite,
              child: CarouselSlider.builder(
                //TODO Change According API
                itemCount: plans.length,
                itemBuilder: (context, index, pageIndex) {
                  return Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.contain,
                            image: AssetImage(
                                "assets/companies/${plans[index].keys.first}.png"
                            )
                        )
                    ),
                  );
                },
                options: CarouselOptions(
                  autoPlay: false,
                  enlargeCenterPage: true,
                  viewportFraction: 1,
                  onPageChanged: (ind, reason){
                    setState((){
                      indexPlan = 0;
                      index = ind;
                    });
                  },
                  //scrollPhysics: NeverScrollableScrollPhysics(),
                  aspectRatio: 1.0,
                ),
              )
          ),
          SizedBox(height: 1.0.h,),
          // Plan Widget
          Container(
            height: 5.0.h,
            child: Center(
              child: DefaultTabController(
                //TODO Change Len according API
                length: plans[index].values.first.length,
                child: ButtonsTabBar(
                  onTap: (ind){
                    setState((){indexPlan = ind;});
                  },
                  backgroundColor: Colors.teal,
                  unselectedBackgroundColor: const Color(0xFF2E3131),
                  unselectedLabelStyle: const TextStyle(
                      color: Color(0xFF7F8990)
                  ),
                  tabs: List.generate(plans[index].values.first.length, (ind)
                  => Tab(text: "Plan ${ind+1}",) ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.0.h,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plans[index].keys.first,
                style: titleExpPanel,
              ),
              Text(
                "${plans[index].values.first[indexPlan].price} \$",
                style: titleExpPanel,
              ),
            ],
          ),
          SizedBox(height: 1.5.h,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Capacity",
                style: dataExpPanel,
              ),
              Text(
                "${plans[index].values.first[indexPlan].data_capacity} GB",
                style: dataExpPanel,
              ),
            ],
          ),
          SizedBox(height: 1.5.h,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Download Speed",
                style: dataExpPanel,
              ),
              Text(
                "${plans[index].values.first[indexPlan].download_speed} GB/s",
                style: dataExpPanel,
              ),
            ],
          ),
          SizedBox(height: 1.5.h,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upload Speed",
                style: dataExpPanel,
              ),
              Text(
                "${plans[index].values.first[indexPlan].upload_speed} GB/s",
                style: dataExpPanel,
              ),
            ],
          ),
          SizedBox(height: 1.5.h,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Type",
                style: dataExpPanel,
              ),
              Text(
                plans[index].values.first[indexPlan].type_net,
                style: dataExpPanel,
              ),
            ],
          ),
          SizedBox(height: 3.0.h,),
          Row(
            children: [
              TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Colors.red,
                    onSurface: Colors.grey,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                  ),
                  onPressed: () => widget.onClose!(true),
                  child: Container(
                    height: 5.0.h,
                    child: const Center(
                      child: Icon(
                          Icons.close
                      ),
                    ),
                  )
              ),
              SizedBox(width: 5.0.w,),
              Expanded(
                child: TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.white,
                      backgroundColor: Colors.teal,
                      onSurface: Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                    ),
                    onPressed: () => widget.onSelect!(plans[index].values.first[indexPlan].id),
                    child: Container(
                      height: 5.0.h,
                      child: Center(
                        child: Text(
                          "Choose",
                          style: button,
                        ),
                      ),
                    )
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

enum NetPanel {
  toChose,
  Chosing,
  Chosed,
  Send,
}
