import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/bloc/vehicle_telemetry_service.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/utils/functions.dart';

class ServicesManager {
  static final mm = '🔴🔴🔴🔴🔴🔴 TelemetryManager: 🔴🔴🔴🔴🔴🔴';

  static late TheGreatGeofencer geofencer;
  static late VehicleTelemetryService telemetryService;

  static start() async {
    pp('$mm start background services ...');
    geofencer = GetIt.instance<TheGreatGeofencer>();
    telemetryService = GetIt.instance<VehicleTelemetryService>();
    //
    await geofencer.buildGeofences();
    telemetryService.init();
    pp('$mm background services started');

  }
}
