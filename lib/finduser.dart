import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/home.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindUserPage extends StatelessWidget {
  const FindUserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const FindUser(),
      theme: ThemeData(fontFamily: 'Raleway', primaryColor: Colors.purple),
    );
  }
}

class FindUser extends StatefulWidget {
  const FindUser({Key? key}) : super(key: key);

  @override
  _FindUserState createState() => _FindUserState();
}

class _FindUserState extends State<FindUser> {
  List<String> mainList = [];
  List<String> userList = [];

  // When the field's value changed, update list
  Future<void> setUserList() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("Users").get();
    if (querySnapshot.docs.isNotEmpty) {
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        if (querySnapshot.docs[i].get('email') ==
            FirebaseAuth.instance.currentUser!.email) {
          continue;
        }
        var a = querySnapshot.docs[i].get('username');
        setState(() {
          mainList.add(a);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    setUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomePage()));
                },
                child: const Icon(Icons.arrow_back),
              ),
            )
          ],
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          TextField(
            decoration: const InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search)),
            onChanged: (text) {
              setState(() {
                userList = [];
              });
              // Not sensible to capital letters
              for (var element in mainList) {
                if (element.toLowerCase().startsWith(text.toLowerCase()) &&
                    text.isNotEmpty) {
                  userList.add(element);
                }
              }
            },
          ),
          SizedBox(
            height: 600,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: userList.length,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                    child: GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userList[index],
                            style: const TextStyle(fontSize: 30),
                          ),
                        ]),
                  ),
                  onTap: () async {
                    SharedPreferences pref =
                        await SharedPreferences.getInstance();
                    pref.setString('username', userList[index]);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Chat()));
                  },
                ));
              },
            ),
          )
        ])));
  }
}
