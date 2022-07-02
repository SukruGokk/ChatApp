import 'package:chat/home.dart';
import 'package:chat/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _mockCheckForSession().then((status) {
      if (status) {
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    });
  }

  Future<bool> _mockCheckForSession() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    if (pref.getString('email') != null && pref.getString('password') != null) {
      try {
        bool logged = false;
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: pref.getString('email')!,
                password: pref.getString('password')!)
            .then((value) {
          logged = true;
        });
        if (logged) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  void _navigateToHome() {
    print(FirebaseAuth.instance.currentUser!.uid);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => const Home()));
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Container(
        decoration: const BoxDecoration(
            color: Colors.purple,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.purpleAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )),
      ),
      Center(
        child: Image.asset(
          'assets/img/logo.png',
          scale: 2,
        ),
      )
    ]));
  }
}
