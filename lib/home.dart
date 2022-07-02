import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/login.dart';
import 'package:chat/finduser.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      theme: ThemeData(fontFamily: 'Raleway', primaryColor: Colors.purple),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection(
        'Users/' + FirebaseAuth.instance.currentUser!.uid + '/chat');

    double screenHeight = MediaQuery.of(context).size.height;

    // Display communicated users
    return StreamBuilder<QuerySnapshot>(
      stream: users.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    'Loading ...',
                    style: TextStyle(fontSize: 30),
                  ),
                ]),
          ));
        }

        List<QueryDocumentSnapshot<Object?>> users = snapshot.data!.docs;
        List<String> usersName = [];

        for (var element in users) {
          usersName.add(element.id);
        }

        return Scaffold(
            appBar: AppBar(
              title: const Text('Contacts'),
              backgroundColor: Theme.of(context).primaryColor,
              centerTitle: true,
              actions: [
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        FirebaseAuth.instance.signOut().then((value) async {
                          SharedPreferences pref =
                              await SharedPreferences.getInstance();
                          pref.remove('email');
                          pref.remove('password');
                          QuerySnapshot querySnapshot = await FirebaseFirestore
                              .instance
                              .collection("Users")
                              .get();

                          await FirebaseMessaging.instance
                              .getToken()
                              .then((value) async {
                            for (int i = 0;
                                i < querySnapshot.docs.length;
                                i++) {
                              for (String fcmToken in querySnapshot.docs[i]
                                  .get('fcm_tokens')
                                  .toList()) {
                                if (fcmToken == value) {
                                  List<dynamic> tokens = querySnapshot.docs[i]
                                      .get('fcm_tokens')
                                      .toList();
                                  tokens.remove(value);
                                  await FirebaseFirestore.instance
                                      .collection('Users')
                                      .doc(querySnapshot.docs[i].id)
                                      .set({
                                    'email': querySnapshot.docs[i].get('email'),
                                    'username':
                                        querySnapshot.docs[i].get('username'),
                                    'password':
                                        querySnapshot.docs[i].get('password'),
                                    'blocked_users': querySnapshot.docs[i]
                                        .get('blocked_users'),
                                    'fcm_tokens': tokens
                                  });
                                }
                              }
                            }
                          });
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()));
                        });
                      },
                      child: const Icon(Icons.logout),
                    )),
              ],
            ),
            body: Container(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: screenHeight * 0.8,
                      child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: usersName.length,
                          itemBuilder: (BuildContext context, int index) {
                            return SizedBox(
                                child: GestureDetector(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usersName[index],
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ]),
                                ),
                              ),
                              onTap: () async {
                                SharedPreferences pref =
                                    await SharedPreferences.getInstance();
                                pref.setString('username', usersName[index]);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Chat()));
                              },
                            ));
                          }),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FindUserPage()));
                      },
                      backgroundColor: Colors.purple,
                      child: const Icon(Icons.message),
                    )
                  ],
                )));
      },
    );
  }
}
