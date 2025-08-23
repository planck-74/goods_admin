import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:goods_admin/business%20logic/routes.dart';
import 'package:goods_admin/business%20logic/providers.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';
import 'package:goods_admin/firebase_options.dart';
import 'package:goods_admin/presentation/screens/auth_screens/sign_in.dart';
import 'package:goods_admin/presentation/screens/home.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!Platform.isWindows && !kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  runApp(const GoodsAdmin());
}

class GoodsAdmin extends StatelessWidget {
  const GoodsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: buildProviders(),
      child: MaterialApp(
        routes: routes,
        debugShowCheckedModeBanner: false,
        theme: getThemeData(),
        title: 'إدارة جودز',
        supportedLocales: const [Locale('ar', 'EG')],
        locale: const Locale('ar', 'EG'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthCheck(),
      ),
    ); 
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return const Home();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return _buildAuthState(snapshot);
      },
    );
  }

  Widget _buildAuthState(AsyncSnapshot<User?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasData) {
      return const Home();
    } else {
      return const SignIn();
    }
  }
}
