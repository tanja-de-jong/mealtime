import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mealtime/presence_list.dart';
import 'package:mealtime/sign_in_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCJvWqTR77t7lpzgajoqwS6t1aN6AWBLkQ",
      authDomain: "mealtime-fee45.firebaseapp.com",
      projectId: "mealtime-fee45",
      storageBucket: "mealtime-fee45.appspot.com",
      messagingSenderId: "945669168615",
      appId: "1:945669168615:web:dcc78118cf1e65ae54f142",
      measurementId: "G-0H08PEDWEP"
    )
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('nl', 'NL'), // Dutch
      ],
      title: 'Maaltijdplanning',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            return user == null ? const SignInPage() : const PresenceList();
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}