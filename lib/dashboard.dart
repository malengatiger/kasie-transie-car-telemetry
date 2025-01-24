import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_car_telemetry/aggregate_widget.dart';
import 'package:kasie_transie_car_telemetry/services_manager.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/bloc/vehicle_telemetry_service.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'map_viewer.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.vehicle});

  final lib.Vehicle vehicle;
  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Prefs prefs = GetIt.instance<Prefs>();
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  DeviceLocationBloc dlb = GetIt.instance<DeviceLocationBloc>();
  DataApiDog dataApiDog = GetIt.instance<DataApiDog>();

  lib.User? user;
  late StreamSubscription<lib.VehicleArrival> arrivalsSubscription;
  late StreamSubscription<lib.VehicleTelemetry> telemetrySubscription;
  late StreamSubscription<lib.CommuterRequest> commuterReqSub;
  late StreamSubscription<lib.LocationRequest> locationRequestSub;
  late StreamSubscription<lib.DispatchRecord> dispatchSub;

  TheGreatGeofencer geofencer = GetIt.instance<TheGreatGeofencer>();
  FCMService fcmService = GetIt.instance<FCMService>();

  VehicleTelemetryService telemetryService =
      GetIt.instance<VehicleTelemetryService>();

  static const mm = '🦠🦠🦠🦠Dashboard 🦠';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _signIn();
    _startTimer();
  }

  void _signIn() async {
    var email = 'car_${widget.vehicle.vehicleId}@car.com';
    var userCred2 = await auth.FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: pass);
    pp('$mm ... auth user for car signed in: ${userCred2.user!.email}');
    ServicesManager.start(widget.vehicle);

    _getRoutes();
  }

  int arrivalsCount = 0;
  int telemetryCount = 0;
  List<lib.VehicleArrival> arrivals = [];
  List<lib.VehicleTelemetry> telemetries = [];

  List<lib.Route> routes = [];
  List<lib.CommuterRequest> commuterRequests = [];
  bool busy = false;
  DateFormat df = DateFormat('EEEE, dd MMMM yyyy HH:mm');
  static const tag = 'car', pass = 'pass123';

  _listen() {
    arrivalsSubscription = geofencer.vehicleArrivalStream.listen((arrival) {
      pp('$mm car arrived at landmark: ${arrival.toJson()}');
      lastUpdatedTime = df.format(DateTime.now());
      arrivals.add(arrival);
      routeName = '${arrival.routeName}';
      landmarkName = arrival.landmarkName!;
      //
      fcmService.subscribeForRouteCommuterRequests(
          routeId: arrival.routeId!, app: 'CarTelemetry');
      setState(() {
        arrivalsCount = arrivals.length;
      });
    });
    //
    telemetrySubscription =
        telemetryService.telemetryStream.listen((telemetry) {
      pp('$mm telemetry arrived: ${telemetry.toJson()}');
      telemetries.add(telemetry);
      lastUpdatedTime = df.format(DateTime.now());
      setState(() {
        telemetryCount = telemetries.length;
      });
    });
    //
    commuterReqSub = fcmService.commuterRequestStream.listen((request) {
      pp('$mm CommuterRequest arrived: ${request.toJson()}');
      commuterRequests.add(request);
      commuterRequests = _filterCommuterRequests(commuterRequests);
      lastUpdatedTime = df.format(DateTime.now());

      if (mounted) {
        setState(() {});
      }
    });
    locationRequestSub = fcmService.locationRequestStream.listen((request) {
      pp('$mm locationRequestStream delivered arrived: ${request.toJson()}');

      if (widget.vehicle.vehicleId == request.vehicleId) {
        _respondToRequest(request);
      }
      lastUpdatedTime = df.format(DateTime.now());

      if (mounted) {
        setState(() {});
      }
    });
    dispatchSub = fcmService.dispatchStream.listen((request) {
      pp('$mm dispatchStream delivered: ${request.toJson()}');

      if (widget.vehicle.vehicleId == request.vehicleId) {
        lastUpdatedTime = df.format(DateTime.now());
        if (mounted) {
          showOKToast(
              duration: const Duration(seconds: 5),
              toastGravity: ToastGravity.BOTTOM,
              message: 'Taxi has been dispatched with ${request.passengers}',
              context: context);
        }
      }
    });
  }

  void _respondToRequest(lib.LocationRequest request) async {
    var loc = await dlb.getLocation();
    var locationResponse = lib.LocationResponse(
        vehicleId: widget.vehicle.vehicleId,
        vehicleReg: widget.vehicle.vehicleReg,
        associationId: widget.vehicle.associationId,
        position: lib.Position(coordinates: [loc.longitude, loc.latitude]),
        fcmToken: request.fcmToken,
        vehicleFcmToken: widget.vehicle.fcmToken);

    await dataApiDog.addLocationResponse(locationResponse);
    pp('$mm location response has been sent');
  }

  late Timer timer;
  _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      pp('$mm _filterCommuterRequests: Timer tick #${timer.tick} ');
      if (mounted) {
        _filterCommuterRequests(commuterRequests);
      }
    });
  }

  void _getCommuterRequests(lib.Route route) async {
    var date = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    commuterRequests = await listApiDog.getRouteCommuterRequests(
        routeId: route.routeId!, startDate: date.toIso8601String());
    if (mounted) {
      setState(() {});
    }
  }

  List<lib.CommuterRequest> _filterCommuterRequests(
      List<lib.CommuterRequest> requests) {
    pp('$mm _filterCommuterRequests arrived: ${requests.length}');

    List<lib.CommuterRequest> filtered = [];
    DateTime now = DateTime.now().toUtc();
    for (var r in requests) {
      var date = DateTime.parse(r.dateRequested!);
      var difference = now.difference(date);
      pp('$mm _filterCommuterRequests difference: $difference');

      if (difference <= const Duration(hours: 1)) {
        filtered.add(r);
      }
    }
    pp('$mm _filterCommuterRequests filtered: ${filtered.length}');
    setState(() {
      commuterRequests = filtered;
    });
    return filtered;
  }

  Future<void> _getRoutes() async {
    setState(() {
      busy = true;
    });
    try {
      pp('$mm getAssociationRoutes ...');
      routes = await listApiDog.getAssociationRoutes(
          widget.vehicle.associationId!, false);
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

  lib.Association? association;
  bool _showRoutes = false;
  List<lib.Route> arrivalRoutes = [];

  _navigateToMap() {
    if (arrivals.isEmpty) {
      return;
    }
    if (arrivals.length > 1) {
      for (var arr in arrivals) {
        for (var r in routes) {
          if (r.routeId == arr.routeId) {
            arrivalRoutes.add(r);
          }
        }
      }
      setState(() {
        _showRoutes = true;
      });
      return;
    }
    lib.Route? route;
    lib.VehicleArrival? arrival = arrivals.last;

    for (var r in routes) {
      if (r.routeId == arrival.routeId) {
        route = r;
      }
    }

    if (route != null) {
      NavigationUtils.navigateTo(
          context: context,
          widget: MapViewer(
            route: route,
          ));
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            Row(
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
                                '${widget.vehicle.vehicleReg}',
                                style: myTextStyle(
                                    fontSize: 36, weight: FontWeight.w900),
                              ),
                            ],
                          ))),
                ),
              ],
            ),
            gapH8,
            Text(
              '${widget.vehicle!.associationName}',
              style: myTextStyle(weight: FontWeight.w900, fontSize: 20),
            ),
            gapH16,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  landmarkName,
                  style: myTextStyle(
                      color: Colors.red.shade600,
                      fontSize: 18,
                      weight: FontWeight.w900),
                ),
                gapW16,
                Flexible(
                  child: Text(
                    routeName,
                    style:
                        myTextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
                gapW32,
                gapW32,
                arrivals.isEmpty
                    ? gapW32
                    : IconButton(
                        onPressed: () {
                          _navigateToMap();
                        },
                        icon: FaIcon(FontAwesomeIcons.mapLocation))
              ],
            ),
            gapH32,
            gapH16,
            Expanded(
                child: SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AggregateWidget(
                    title: 'Arrivals',
                    number: arrivalsCount,
                    color: Colors.pink, isBadge: false,
                  ),
                  AggregateWidget(
                    color: Colors.blue.shade700, isBadge: false,
                    title: 'Telemetry',
                    number: telemetryCount,
                  ),
                  GestureDetector(
                    onTap: () {
                      showToast(
                          backgroundColor: Colors.pink.shade700,
                          textStyle: myTextStyle(color: Colors.white),
                          padding: 28,
                          toastGravity: ToastGravity.BOTTOM,
                          duration: const Duration(seconds: 3),
                          message:
                              'Under construction. Will show commuters on map when done!',
                          context: context);
                    },
                    child: AggregateWidget(
                      color: Colors.green.shade700, isBadge: false,
                      title: 'Commuter Requests',
                      number: _getPassengers(),
                    ),
                  )
                ],
              ),
            )),
            gapH32,
            gapH16,
            lastUpdatedTime == null
                ? gapW32
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Last Update: ',
                          style: myTextStyle(
                              fontSize: 11, weight: FontWeight.w200)),
                      gapW16,
                      Text(
                        lastUpdatedTime!,
                        style:
                            myTextStyle(fontSize: 12, weight: FontWeight.w300),
                      ),
                      gapW16,
                    ],
                  )
          ]),
          _showRoutes
              ? Positioned(
                  child: Center(
                    child: Card(
                        elevation: 8,
                        child: SingleChildScrollView(
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Select Route to see Maps ',
                                  style: myTextStyle(weight: FontWeight.w900),
                                ),
                                gapW32,
                                gapW32,
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showRoutes = false;
                                      });
                                    },
                                    icon: FaIcon(FontAwesomeIcons.xmark)),
                              ],
                            ),
                            gapH16,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 64),
                              child: ListOfRoutes(
                                  routes: routes,
                                  onSelected: (r) {
                                    setState(() {
                                      _showRoutes = false;
                                    });
                                    NavigationUtils.navigateTo(
                                        context: context,
                                        widget: MapViewer(
                                          route: r,
                                        ));
                                  }),
                            )
                          ]),
                        )),
                  ),
                )
              : gapW32,
        ]),
      ),
    );
  }

  _getPassengers() {
    var cnt = 0;
    for (var req in commuterRequests) {
      cnt += req.numberOfPassengers!;
    }
    return cnt;
  }

  String landmarkName = '';
  String? lastUpdatedTime;
  String routeName = 'Route Landmark Messages';
}

class ListOfRoutes extends StatelessWidget {
  final List<lib.Route> routes;
  final Function(lib.Route) onSelected;

  const ListOfRoutes(
      {super.key, required this.routes, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: ListView.builder(
          itemCount: routes.length,
          itemBuilder: (ctx, index) {
            var route = routes[index];
            return GestureDetector(
              onTap: () async {
                await NavigationUtils.navigateTo(
                    context: context,
                    widget: MapViewer(
                      route: route,
                    ));
              },
              child: Card(
                  elevation: 8,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () {
                          onSelected(route);
                        },
                        child: Text('${route.name}'),
                      ))),
            );
          }),
    );
  }
}
