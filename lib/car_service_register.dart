import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/bloc/sem_cache.dart';
import 'package:kasie_transie_library/bloc/the_great_geofencer.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/bloc/vehicle_telemetry_service.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';

import 'package:kasie_transie_library/messaging/telemetry_manager.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/error_handler.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/utils/route_distance_calculator.dart';
import 'package:kasie_transie_library/utils/route_update_listener.dart';

import 'package:sembast_web/sembast_web.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RegisterCarService {
  static const mm = '🅿️🅿️🅿️🅿️ RegisterCarService  🅿️🅿️';
  static String dbPath = 'kasie.db';
  static DatabaseFactory dbFactoryWeb = databaseFactoryWeb;

  static Future<String> register() async {
    pp('\n\n$mm  ... initialize service singletons with GetIt .... 🍎🍎🍎');
    final http.Client client = http.Client();
    pp('$mm .... http.Client: 🦠client initialized');

    final DeviceLocationBloc deviceLocationBloc = DeviceLocationBloc();
    pp('$mm .... DeviceLocationBloc: 🦠deviceLocationBloc initialized');

    final Prefs prefs = Prefs(await SharedPreferences.getInstance());
    pp('$mm .... Prefs: 🦠prefs initialized');
    final ErrorHandler errorHandler = ErrorHandler(DeviceLocationBloc(), prefs);
    pp('$mm .... ErrorHandler: 🦠errorHandler initialized');
    final SemCache semCache = SemCache();
    pp('$mm .... SemCache: 🦠cache initialized');

    FCMService fcmService = FCMService(FirebaseMessaging.instance);
    pp('$mm .... FCMService: 🦠 FCMService initialized');

    final VehicleTelemetryService telemetryService = VehicleTelemetryService();
    pp('$mm .... VehicleTelemetryService: 🦠telemetryService initialized');

    final listApi =
    ListApiDog(client,);
    pp('$mm .... ListApiDog: 🦠listApiDog initialized');

    DataApiDog dataApiDog = DataApiDog();
    pp('\n\n$mm ..... 🦠🦠🦠🦠🦠registerLazySingletons ...');

    final GetIt instance = GetIt.instance;
    instance.registerLazySingleton<Prefs>(() => prefs);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... Prefs');

    instance.registerLazySingleton<FCMService>(() => fcmService);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... FCMService');

    instance.registerLazySingleton<KasieThemeManager>(
            () => KasieThemeManager(prefs));
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... KasieThemeManager');

    instance.registerLazySingleton<RouteUpdateListener>(
            () => RouteUpdateListener());
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... RouteUpdateListener');

    instance
        .registerLazySingleton<DeviceLocationBloc>(() => deviceLocationBloc);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... DeviceLocationBloc');

    instance.registerLazySingleton<SemCache>(() => semCache);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... SemCache');


    instance.registerLazySingleton<RouteDistanceCalculator>(
            () => RouteDistanceCalculator(prefs, listApi, DataApiDog()));
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... RouteDistanceCalculator');

    instance.registerLazySingleton<TheGreatGeofencer>(
            () => TheGreatGeofencer(DataApiDog(), listApi, prefs));
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... TheGreatGeofencer');

    instance.registerLazySingleton<ListApiDog>(() => listApi);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... ListApiDog');

    instance.registerLazySingleton<DataApiDog>(() => dataApiDog);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... DataApiDog');

    instance.registerLazySingleton<ErrorHandler>(() => errorHandler);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... ErrorHandler');

    instance.registerLazySingleton<TelemetryManager>(() => TelemetryManager());
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... TelemetryManager');

    instance
        .registerLazySingleton<VehicleTelemetryService>(() => telemetryService);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... VehicleTelemetryService');

    instance
        .registerLazySingleton<http.Client>(() => client);
    pp('$mm 🦠🦠🦠🦠🦠registerLazySingletons ... http.Client');

    pp('\n\n$mm  returning message form RegisterService  🍎🍎🍎\n\n');
    return '\n🍎🍎🍎 RegisterCarService: 16 Service singletons registered!';
  }
}
