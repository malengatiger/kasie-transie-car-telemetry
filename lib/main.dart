import 'package:flutter/material.dart';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as store;
import 'package:kasie_transie_car_telemetry/dashboard.dart';
import 'package:kasie_transie_car_telemetry/services_manager.dart';
import 'package:kasie_transie_library/bloc/register_services.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/widgets/splash_page.dart';
import 'package:page_transition/page_transition.dart';

import 'firebase_options.dart';

late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
late KasieThemeManager kasieThemeManager;
lib.User? me;
int themeIndex = 0;

  const mx = '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵 🐸 KasieTransie Car App 🐸 🔵🔵';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    pp('\n\n$mx '
        ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');

    fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
    if (fbAuthedUser != null) {
      pp('$mx fbAuthUser: ${fbAuthedUser!.uid}');
      pp("$mx .... fbAuthUser is cool! ........ on to the party!!");
    } else {
      pp('$mx fbAuthUser: is null. will need to authenticate the app!');
    }
    try {
      await RegisterServices.register(
          firebaseStorage: store.FirebaseStorage.instanceFor(app: firebaseApp));
    } catch (e) {
      pp('$mx Houston, we have a problem! $e');
    }

    // Set up Background message handler
    FirebaseMessaging.onBackgroundMessage(kasieFirebaseMessagingBackgroundHandler);

    runApp(const CarApp());
}

class CarApp extends StatelessWidget {
  const CarApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KasieCar',
      theme: ThemeData.light(),
      // darkTheme: kasieThemeManager.getTheme(themeIndex).darkTheme,

      themeMode: ThemeMode.system,
      // home:  const Dashboard(),
      home: AnimatedSplashScreen(
        splash: const SplashWidget(),
        animationDuration: const Duration(milliseconds: 2000),
        curve: Curves.easeInCirc,
        splashIconSize: 160.0,
        nextScreen: const Dashboard(),
        splashTransition: SplashTransition.fadeTransition,
        pageTransitionType: PageTransitionType.leftToRight,
        backgroundColor: Colors.brown.shade800,
      ),
    );
  }
}
