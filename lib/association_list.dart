import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/bloc/app_auth.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/vehicle_widgets/vehicle_search.dart';

class AssociationVehicleFinder extends StatefulWidget {
  const AssociationVehicleFinder({super.key});

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
  AppAuth appAuth = GetIt.instance<AppAuth>();

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
      var u = auth.FirebaseAuth.instance;
      var userCred = await u.signInWithEmailAndPassword(
          email: 'admin@admin.com', password: 'pass123');
      if (userCred.user != null) {
        associations = await listApiDog.getAssociations(true);
        pp('$mm associations found: ${associations.length}');
        associations
            .sort((a, b) => a.associationName!.compareTo(b.associationName!));
      }
    } catch (e, s) {
      pp('$e $s');
    }

    setState(() {
      busy = false;
    });
  }

  _handleAss() async {
    pp('_handleAss ${association?.toJson()}');
    // user = await appAuth.signInWithEmailAndPassword(
    //     association!.carUser!.email!, 'pass${association!.associationId!}');
    // pp('$mm car user signed in: ${user!.toJson()}');
    prefs.saveAssociation(association!);
    if (mounted) {
      vehicle = await NavigationUtils.navigateTo(
          context: context, widget: VehicleSearch(associationId: association!.associationId!,));
      if (vehicle != null) {
        prefs.saveCar(vehicle!);
        pp('$mm vehicle selected: ${vehicle!.toJson()}');

        if (mounted) {
          Navigator.of(context).pop(vehicle);
        }
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
        title: const Text('Association List'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Tap to select Association'),
                  gapH32,
                  Expanded(
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
                                  child: Text('${ass.associationName}',
                                  style: myTextStyle(fontSize: 18, weight: FontWeight.bold)),
                                ),
                              ));
                        }),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
