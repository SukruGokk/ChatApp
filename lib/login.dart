import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:chat/home.dart';
import 'package:chat/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Login(),
      theme: ThemeData(fontFamily: 'Raleway', primaryColor: Colors.purple),
    );
  }
}

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String email = "";
  String password = "";

  bool _passwordInVisible = true;
  bool keepMeSignedIn = false;

  @override
  Widget build(BuildContext context) {
    Future<void> logIn(email, password) async {
      try {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .then((value) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('email', email);
          prefs.setString('password', password);

          QuerySnapshot querySnapshot =
              await FirebaseFirestore.instance.collection("Users").get();
          // Remove fcm token
          await FirebaseMessaging.instance.getToken().then((value) async {
            for (int i = 0; i < querySnapshot.docs.length; i++) {
              for (String fcmToken
                  in querySnapshot.docs[i].get('fcm_tokens').toList()) {
                if (fcmToken == value) {
                  List<dynamic> tokens =
                      querySnapshot.docs[i].get('fcm_tokens').toList();
                  tokens.remove(value);
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(querySnapshot.docs[i].id)
                      .set({
                    'email': querySnapshot.docs[i].get('email'),
                    'password': querySnapshot.docs[i].get('password'),
                    'fcm_tokens': tokens
                  });
                }
              }
            }
          });

          // Add fcm token
          await FirebaseMessaging.instance.getToken().then((value) async {
            for (int i = 0; i < querySnapshot.docs.length; i++) {
              if (querySnapshot.docs[i].get('email') == email) {
                List<dynamic> tokens =
                    querySnapshot.docs[i].get('fcm_tokens').toList();
                await FirebaseMessaging.instance.getToken().then((value) {
                  tokens.add(value!);
                });
                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(querySnapshot.docs[i].id)
                    .set({
                  'email': querySnapshot.docs[i].get('email'),
                  'username': querySnapshot.docs[i].get('username'),
                  'password': querySnapshot.docs[i].get('password'),
                  'blocked_users': querySnapshot.docs[i].get('blocked_users'),
                  'fcm_tokens': tokens
                });
              }
            }
          });

          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        });
      } on FirebaseAuthException catch (error) {
        showDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
                    title: const Text("Authentication Failed"),
                    content: Text(error.message!),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text("OK"),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop("Discard");
                        },
                      )
                    ]));
      }
    }

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Log In',
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(
                  height: 50,
                ),
                TextField(
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      hintStyle: TextStyle(color: Colors.grey[800]),
                      hintText: "E-Mail",
                      fillColor: Colors.white70),
                  controller: emailController,
                ),
                const SizedBox(height: 5),
                TextFormField(
                  obscureText: _passwordInVisible,
                  onSaved: (newValue) => password = newValue!,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    hintStyle: TextStyle(color: Colors.grey[800]),
                    hintText: "Password",
                    fillColor: Colors.white70,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordInVisible
                            ? Icons.visibility_off
                            : Icons
                                .visibility, //change icon based on boolean value
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordInVisible =
                              !_passwordInVisible; //change boolean value
                        });
                      },
                    ),
                  ),
                  controller: passwordController,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Don't have an account ?",
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 15,
                  ),
                ),
                RichText(
                  text: TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUp()));
                        }),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).primaryColor),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ))),
                  onPressed: () {
                    logIn(emailController.text, passwordController.text);
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
