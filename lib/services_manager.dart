import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/bloc/vehicle_telemetry_service.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/data/data_schemas.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';

class ServicesManager {
  static final mm = '🔴🔴🔴🔴🔴🔴 ServicesManager: 🔴🔴🔴🔴🔴🔴';

  static late TheGreatGeofencer geofencer;
  static late VehicleTelemetryService telemetryService;
  static late ListApiDog listApiDog;
  static late Prefs prefs;
  static late FCMService fcmService;

  static start(Vehicle vehicle) async {
    pp('\n\n$mm start background services ... \n');
    myPrettyJsonPrint(vehicle.toJson());

    geofencer = GetIt.instance<TheGreatGeofencer>();
    telemetryService = GetIt.instance<VehicleTelemetryService>();
    prefs  = GetIt.instance<Prefs>();
    listApiDog = GetIt.instance<ListApiDog>();
    fcmService = GetIt.instance<FCMService>();

    geofencer.setRefreshFencesTimer();
    await geofencer.buildGeofences();

    telemetryService.initializeTimer();

    await fcmService.initialize();
    await fcmService.subscribeForCar(vehicle, 'CarTelemetry');

    pp('\n$mm background services started OK 🌿🌿🌿🌿🌿🌿🌿\n');


  }
}
