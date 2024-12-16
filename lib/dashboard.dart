import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_car_telemetry/aggregate_widget.dart';
import 'package:kasie_transie_car_telemetry/services_manager.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/bloc/vehicle_telemetry_service.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

import 'association_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Prefs prefs = GetIt.instance<Prefs>();
  lib.Vehicle? vehicle;
  lib.User? user;
  late StreamSubscription arrivalsSubscription;
  late StreamSubscription telemetrySubscription;
  TheGreatGeofencer geofencer = GetIt.instance<TheGreatGeofencer>();
  VehicleTelemetryService telemetryService =
      GetIt.instance<VehicleTelemetryService>();

  static const mm = '🦠🦠🦠🦠Dashboard 🦠';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _listen();
    _authenticate();
  }

  int arrivalsCount = 0;
  int telemetryCount = 0;

  _listen() {
    arrivalsSubscription = geofencer.vehicleArrivalStream.listen((arrival) {
      pp('$mm car arrived at landmark: ${arrival.toJson()}');
      vehicleArrivalMessage =
          'route: ${arrival.routeName}';
      landmarkName = arrival.landmarkName!;
      setState(() {
        arrivalsCount++;
      });
    });
    telemetrySubscription =
        telemetryService.telemetryStream.listen((telemetry) {
      pp('$mm telemetry arrived: ${telemetry.toJson()}');
      setState(() {
        telemetryCount++;
      });
    });
  }

  _authenticate() async {
    vehicle = prefs.getCar();
    if (vehicle == null) {
      await Future.delayed(Duration(milliseconds: 100));
      _navigateToAssociationVehicleFinder();
      return;
    }
    pp('$mm vehicle: ${vehicle!.toJson()}');
    ServicesManager.start();
  }

  lib.Association? association;

  _navigateToAssociationVehicleFinder() async {
    pp('$mm _navigateToAssociationVehicleFinder ...');

    vehicle = await NavigationUtils.navigateTo(
        context: context, widget: AssociationVehicleFinder());
    if (vehicle != null) {
      ServicesManager.start();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    arrivalsSubscription.cancel();
    telemetrySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            vehicle == null
                ? gapH4
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 8,
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                                width: 300,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${vehicle!.vehicleReg}',
                                      style: myTextStyle(
                                          fontSize: 48,
                                          weight: FontWeight.w900),
                                    ),
                                  ],
                                ))),
                      ),
                    ],
                  ),
            gapH8,
            vehicle == null
                ? gapH4
                : Text(
                    '${vehicle!.associationName}',
                    style: myTextStyle(weight: FontWeight.w900, fontSize: 20),
                  ),
            gapH32,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(landmarkName, style: myTextStyle(color: Colors.red.shade600,
                    fontSize: 24, weight: FontWeight.w900),),
                gapW16,
                Flexible(
                  child: Text(
                    vehicleArrivalMessage,
                    style:
                        myTextStyle(color: Colors.grey.shade600, fontSize: 20),
                  ),
                ),
              ],
            ),
            gapH32,
            gapH32,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AggregateWidget(
                  title: 'Arrivals',
                  number: arrivalsCount,
                  color: Colors.pink,
                ),
                AggregateWidget(
                  color: Colors.blue.shade700,
                  title: 'Telemetry',
                  number: telemetryCount,
                ),
              ],
            ),
          ]),
        ]),
      ),
    );
  }

  String landmarkName = '';

  String vehicleArrivalMessage = 'Route Landmark Messages';
}
