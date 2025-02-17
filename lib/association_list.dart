import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/bloc/app_auth.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/constants.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/timer_widget.dart';
import 'package:kasie_transie_library/widgets/vehicle_widgets/vehicle_search.dart';
import 'package:badges/badges.dart' as bd;
import 'package:uuid/uuid.dart';

class AssociationVehicleFinder extends StatefulWidget {
  const AssociationVehicleFinder(
      {super.key, required this.email, required this.password});

  final String email, password;

  @override
  AssociationVehicleFinderState createState() =>
      AssociationVehicleFinderState();
}

class AssociationVehicleFinderState extends State<AssociationVehicleFinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '🍀🍀🍀AssociationVehicleFinder 🦊';
  List<lib.Association> associations = [];
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();

  Prefs prefs = GetIt.instance<Prefs>();
  lib.Association? association;
  lib.User? user;
  lib.Vehicle? vehicle;

  bool busy = false;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getData();
  }

  _getData() async {
    setState(() {
      busy = true;
    });
    try {
      associations = await listApiDog.getAssociations(true);
      pp('$mm associations found: ${associations.length}');
      associations
          .sort((a, b) => a.associationName!.compareTo(b.associationName!));
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

  DataApiDog dataApiDog = GetIt.instance<DataApiDog>();

  _handleAss() async {
    pp('_handle Association and select car ${association?.toJson()}');
    prefs.saveAssociation(association!);

    vehicle = await NavigationUtils.navigateTo(
        context: context,
        widget: VehicleSearch(
          associationId: association!.associationId!, showGrid: false,
        ));
    if (vehicle != null) {
      prefs.saveCar(vehicle!);
      pp('$mm vehicle selected: ${vehicle!.toJson()}');
      lib.User user = lib.User(
          userType: Constants.VEHICLE,
          firstName: Constants.VEHICLE,
          lastName: Constants.VEHICLE,
          countryId: vehicle!.countryId!,
          associationId: vehicle!.associationId!,
          cellphone: null,
          associationName: vehicle!.associationName,
          password: widget.password,
          email: widget.email);

      var res = await dataApiDog.createVehicleUser(user);
      pp('Car user added to database: ${res.toJson()}');
      if (mounted) {
        Navigator.of(context).pop(vehicle);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasie Car Installation'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  gapH8,
                  Text(
                    'Tap to select Association',
                    style: myTextStyle(fontSize: 14),
                  ),
                  gapH32,
                  Expanded(
                      child: bd.Badge(
                    badgeContent: Text(
                      '${associations.length}',
                      style: myTextStyle(color: Colors.white),
                    ),
                    badgeStyle: bd.BadgeStyle(
                        padding: EdgeInsets.all(12), badgeColor: Colors.indigo),
                    position: bd.BadgePosition.topEnd(top: -36, end: 8),
                    child: ListView.builder(
                        itemCount: associations.length,
                        itemBuilder: (_, index) {
                          var ass = associations[index];
                          return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  association = ass;
                                });
                                _handleAss();
                              },
                              child: Card(
                                elevation: 8,
                                child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 24,
                                            child: Text(
                                              '${index + 1}',
                                              style: myTextStyle(
                                                  color: Colors.pink,
                                                  weight: FontWeight.w900),
                                            )),
                                        gapW16,
                                        Flexible(
                                          child: Text('${ass.associationName}',
                                              style: myTextStyle(
                                                  fontSize: 16,
                                                  weight: FontWeight.bold)),
                                        )
                                      ],
                                    )),
                              ));
                        }),
                  ))
                ],
              ),
            ),
            busy
                ? Positioned(
                    child: Center(
                        child: TimerWidget(
                            title: 'Loading associations ...',
                            isSmallSize: true)))
                : gapW32,
          ],
        ),
      ),
    );
  }
}
