import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'login.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SignUp(),
      theme: ThemeData(fontFamily: 'Raleway', primaryColor: Colors.purple),
    );
  }
}

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  String email = "";
  String password = "";
  String username = "";
  late Timer timer;

  bool _passwordInVisible = true;
  String verificationNote = "";

  Future<void> checkEmailVerification() async {
    print('test\n\n\n\n');
    await FirebaseAuth.instance.currentUser!.reload();

    if (FirebaseAuth.instance.currentUser!.emailVerified) {
      timer.cancel();
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> signUp(email, password, username) async {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection("Users").get();
      if (querySnapshot.docs.isNotEmpty) {
        for (int i = 0; i < querySnapshot.docs.length; i++) {
          var a = querySnapshot.docs[i].get('username');
          if (a == username) {
            showDialog(
                context: context,
                builder: (BuildContext context) => CupertinoAlertDialog(
                        title: const Text("Authentication Failed"),
                        content: Text('"' +
                            username +
                            '" is taken. Please try another one !'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true)
                                  .pop("Discard");
                            },
                          )
                        ]));
            return;
          }
        }
      }

      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password)
            .then((value) async {
          FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .set({
                'email': email,
                'password': password,
                'username': username,
                'fcm_tokens': [],
                'blocked_users': []
              })
              .then((_) {})
              .catchError((e) {});

          User user = FirebaseAuth.instance.currentUser!;
          user.sendEmailVerification();
          showDialog(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: const Text("Email Verification"),
                    content: Text(
                        'An email verification sent to ${FirebaseAuth.instance.currentUser!.email}. Don\'t forget to check your spam folder !'),
                  ));
          timer = Timer.periodic(const Duration(seconds: 5), (timer) {
            checkEmailVerification();
          });
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
                  'Sign Up',
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
                const SizedBox(
                  height: 5,
                ),
                TextField(
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      hintStyle: TextStyle(color: Colors.grey[800]),
                      hintText: "Username",
                      fillColor: Colors.white70),
                  controller: usernameController,
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
                  "Already have an account ?",
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 15,
                  ),
                ),
                RichText(
                  text: TextSpan(
                      text: 'Log In',
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
                                  builder: (context) => const Login()));
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
                    signUp(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                        usernameController.text.trim());
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
