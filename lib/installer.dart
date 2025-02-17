import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/timer_widget.dart';

import 'dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fbm;
class Installer extends StatefulWidget {
  const Installer({super.key});

  @override
  InstallerState createState() => InstallerState();
}

class InstallerState extends State<Installer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Prefs prefs = GetIt.instance<Prefs>();
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  lib.Vehicle? vehicle;
  List<lib.Association> associations = [];
  List<lib.Vehicle> cars = [];

  bool busy = false;
  static const mm = '😝😝😝😝 Installer 🦠';
  static const tag = 'admin@kasie.com', pass = 'pass123';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _checkVehicle();
  }

  void _checkVehicle() async {
    vehicle = prefs.getCar();
    if (vehicle != null) {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        NavigationUtils.navigateTo(
            context: context,
            widget: Dashboard(
              vehicle: vehicle!,
            ));
      }
      return;
    }
    _signInForAssociationsQuery();
  }

  _signInForAssociationsQuery() async {
    setState(() {
      busy = true;
    });
    try {
      var userCred2 = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: tag, password: pass);
      pp('$mm ... admin user signed in: ${userCred2.user!.email}');
      associations = await listApiDog.getAssociations(true);
      associations
          .sort((a, b) => a.associationName!.compareTo(b.associationName!));
      for (var ass in associations) {
        pp('$mm ... ass: ${ass.associationName}');
      }
    } catch (e, s) {
      pp('$e $s');
      if (mounted) {
        showErrorToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _getCars(lib.Association ass) async {
    setState(() {
      busy = true;
    });
    pp('$mm _getCars: for association: ${ass.toJson()}');

    cars = await listApiDog.getAssociationCars(ass.associationId!, true);
    setState(() {
      busy = false;
    });
  }

  FCMService fcmService = GetIt.instance<FCMService>();
  DataApiDog dataApiDog = GetIt.instance<DataApiDog>();
  fbm.FirebaseMessaging messaging = fbm.FirebaseMessaging.instance;

  void _processCar(lib.Vehicle vehicle) async {
    try {
      setState(() {
        busy = true;
      });
      var token = await fcmService.getFCMToken();
      if (token != null) {
        vehicle.fcmToken = token;
      }
      pp('$mm _processCar: vehicle selected: ${vehicle.toJson()}');
      //create auth user
      var email = 'car_${vehicle.vehicleId}@car.com';
      await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      var userCred2 = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      pp('$mm ... auth user for car created and signed in: ${userCred2.user!.email}');

      await dataApiDog.updateVehicle(vehicle);
      pp('$mm ... vehicle updated, see fcmToken: ${vehicle.toJson()}');
      prefs.saveCar(vehicle);
      var ass = await listApiDog.getAssociationById(vehicle.associationId!);
      prefs.saveAssociation(ass!);
      var sets = await listApiDog.getSettings(vehicle.associationId!, true);
      if (sets.isNotEmpty) {
        prefs.saveSettings(sets.last);
      }

      if (mounted) {
        Navigator.of(context).pop(vehicle);
        NavigationUtils.navigateTo(
            context: context, widget: Dashboard(vehicle: vehicle));
      }
    } catch (e, s) {
      pp('$e $s');
      if (mounted) {
        showErrorToast(message: '$e', context: context);
      }
    }
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasie Installer'),
      ),
      body: SafeArea(
        child: Stack(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(cars.isEmpty ? 'Associations' : "Vehicles"),
              Text(cars.isEmpty
                  ? 'Select Association that the Vehicle belongs to'
                  : 'Select Vehicle'),
              cars.isEmpty
                  ? Expanded(
                      child: ListView.builder(
                          itemCount: associations.length,
                          itemBuilder: (_, index) {
                            var ass = associations[index];
                            return Card(
                                elevation: 4,
                                child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: InkWell(
                                      onTap: () async {
                                        prefs.saveAssociation(ass);
                                        _getCars(ass);
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(
                                              width: 24,
                                              child: Text(
                                                '${index + 1}',
                                                style: myTextStyle(
                                                    weight: FontWeight.w900,
                                                    color: Colors.blue),
                                              )),
                                          Text(
                                            '${ass.associationName}',
                                            style: myTextStyle(fontSize: 18),
                                          )
                                        ],
                                      ),
                                    )));
                          }),
                    )
                  : Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3),
                            itemCount: cars.length,
                            itemBuilder: (_, index) {
                              var car = cars[index];
                              return Card(
                                elevation: 4,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: InkWell(
                                    onTap: () async {
                                      _processCar(car);
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          '${car.vehicleReg}',
                                          style: myTextStyle(fontSize: 14,
                                              weight: FontWeight.w900),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ),
            ],
          ),
          busy
              ? Positioned(
                  child: Center(
                      child: TimerWidget(
                  title: 'Loading data ...',
                  isSmallSize: true,
                )))
              : gapW32,
        ]),
      ),
    );
  }
}
