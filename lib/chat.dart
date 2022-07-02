import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chat/home.dart';

class Message {
  late String text;
  late String username;
  late DateTime date;

  Message(this.text, this.username, this.date);
}

void sendNotification(String token, String username, String msg) async {
  // Set a notification on firebase with api to send notification to devices which have receiver accounts logged in
  try {
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAvMXxzH0:APA91bGRdAeRPu9jqFJcVMt30zfO6ny4AAoduX-wpE55Kc3aRVKQ9rhJruOxC9DF_9_6lsVpnqPwuacgc720E8Nn4bE65QfrkVmsJqEbzSJmRdXqb7ZvCP_WXTGFkyjrTWm03rGXBZec'
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{'body': msg, 'title': username},
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          // send specific device
          'to': token
        },
      ),
    );
  } catch (e) {}
}

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  TextEditingController messageController = TextEditingController();
  final ScrollController _controller = ScrollController();

  // to scroll listview
  bool _needsScroll = true;

  List<Message> messages = [];
  String username = "";
  String currentUsername = "";
  String recvUid = "";
  List<dynamic> recvTokens = [];
  List<dynamic> blockedUsers = [];

  var menuItems = <String>['Block/Unblock User', 'Delete Messages'];

  _scrollToEnd() async {
    _controller.jumpTo(
        _controller.position.maxScrollExtent,);
  }

  // At the home page before navigating to chat page, a shared preferences created. Defining it to a variable
  Future<void> setUsername() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String usr = pref.getString('username')!;
    setState(() {
      username = usr;
    });
  }

  Future<void> sendMessage() async {
    String msgText = messageController.text;
    messageController.clear();

    // If message is empty
    if (msgText.trim() == '') {
      return;
    }

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("Users").get();
    if (querySnapshot.docs.isNotEmpty) {
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        // set currentUsername
        if (querySnapshot.docs[i].get('email') ==
            FirebaseAuth.instance.currentUser!.email) {
          currentUsername = querySnapshot.docs[i].get('username');
        }
        // set receiver's uid and receivers fcm(firebase cloud messaging) tokens
        if (querySnapshot.docs[i].get('username') == username) {
          recvUid = querySnapshot.docs[i].id;
          recvTokens = querySnapshot.docs[i].get('fcm_tokens');
        }
      }
    }

    CollectionReference senderRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('chat')
        .doc(username)
        .collection('messages');
    CollectionReference receiverRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(recvUid)
        .collection('chat')
        .doc(currentUsername)
        .collection('messages');

    // User can send a message if receiver blocked him. But receiver wont receive message.
    // But if sender blocked receiver, he can't send message
    FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) async {
      blockedUsers = value.data()!['blocked_users'];
      if (blockedUsers.contains(username)) {
        showDialog(
            context: context,
            builder: (BuildContext context) => CupertinoAlertDialog(
                    title: const Text("Blocked User"),
                    content: const Text(
                        'You has blocked this user. You can\'t send message'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text("OK"),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop("Discard");
                        },
                      )
                    ]));
        // if not blocked
      } else {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('chat')
            .doc(username)
            .set({'exists': true});

        await senderRef
            .doc(DateTime.now().millisecondsSinceEpoch.toString())
            .set({'text': msgText, 'sender': true, 'time': DateTime.now()});
      }
    });

    FirebaseFirestore.instance
        .collection('Users')
        .doc(recvUid)
        .get()
        .then((value) async {
      blockedUsers = value.data()!['blocked_users'];
      if (!blockedUsers.contains(currentUsername)) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(recvUid)
            .collection('chat')
            .doc(currentUsername)
            .set({'exists': true});

        await receiverRef
            .doc(DateTime.now().millisecondsSinceEpoch.toString())
            .set({'text': msgText, 'sender': false, 'time': DateTime.now()});

        // Send notification to single or multiple devices
        for (var token in recvTokens) {
          sendNotification(token, currentUsername, msgText);
        }
      }
    });

    _needsScroll = true;
  }

  String formatTime(int seconds) {
    return '${(Duration(seconds: seconds))}'.split('.')[0].padLeft(8, '0');
  }

  // First of all, set username
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if(_controller.position.maxScrollExtent - _controller.position.pixels > 300){
        showDialog(
            context: context,
            builder: (context) {
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pop(true);
              });
              return const AlertDialog(
                title: Text('New Message'),
              );
            });
      }else{
        Timer(const Duration(milliseconds: 100), () {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 750),
          );
        });
      }
    });
    setUsername();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        // get messages
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('chat')
            .doc(username)
            .collection('messages')
            .snapshots(),
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

          List<QueryDocumentSnapshot<Object?>> messagesData =
              snapshot.data!.docs;

          if(_needsScroll){
            WidgetsBinding.instance.addPostFrameCallback((_) async{
              _scrollToEnd();
            });
            _needsScroll = false;
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(username),
              backgroundColor: Theme.of(context).primaryColor,
              actions: [
                PopupMenuButton(
                  itemBuilder: (BuildContext context) {
                    return menuItems.map((String choice) {
                      return PopupMenuItem<String>(
                        child: Text(choice),
                        value: choice,
                        onTap: () async {
                          if(choice == menuItems[0]){
                            // If user is blocked, unblock it
                            // If user is not block, block it
                            await FirebaseFirestore.instance
                                .collection("Users")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .get()
                                .then((value) {
                              blockedUsers = value.data()!['blocked_users'];
                              if (blockedUsers.contains(username)) {
                                blockedUsers.remove(username);
                                FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .set({
                                  'email': value.data()!['email'],
                                  'password': value.data()!['password'],
                                  'username': value.data()!['username'],
                                  'fcm_tokens': value.data()!['fcm_tokens'],
                                  'blocked_users': blockedUsers
                                }).then((value) {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                              title: const Text(
                                                  "Successfully Completed"),
                                              content:
                                              const Text('Unblocked User'),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text("OK"),
                                                  onPressed: () {
                                                    Navigator.of(context,
                                                        rootNavigator: true)
                                                        .pop("Discard");
                                                  },
                                                )
                                              ]));
                                });
                              } else {
                                blockedUsers.add(username);
                                FirebaseFirestore.instance
                                    .collection("Users")
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .set({
                                  'email': value.data()!['email'],
                                  'password': value.data()!['password'],
                                  'username': value.data()!['username'],
                                  'fcm_tokens': value.data()!['fcm_tokens'],
                                  'blocked_users': blockedUsers
                                }).then((value) {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          CupertinoAlertDialog(
                                              title: const Text(
                                                  "Successfuly Completed"),
                                              content: const Text('Blocked User'),
                                              actions: [
                                                CupertinoDialogAction(
                                                  child: const Text("OK"),
                                                  onPressed: () {
                                                    Navigator.of(context,
                                                        rootNavigator: true)
                                                        .pop("Discard");
                                                  },
                                                )
                                              ]));
                                });
                              }
                            });
                          }else{
                            //delete Users/{Current User's Uid}/chat/{Receiver's Username} collection
                            await FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection('chat').doc(username).delete();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Home()));
                          }
                        },
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            body: Container(
                constraints: const BoxConstraints.expand(),
                padding: const EdgeInsets.all(5),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                          controller: _controller,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            final time = DateFormat.Hm().format(
                                messagesData[index].get('time').toDate());
                            // If sender sent the message, align it to right
                            // Else align to left
                            if (messagesData[index].get('sender')) {
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.only(
                                          right: 10,
                                          left: 10,
                                          top: 10,
                                          bottom: 10),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              messagesData[index].get('text'),
                                              style:
                                                  const TextStyle(fontSize: 20),
                                            ),
                                            Text(time)
                                          ]),
                                    ),
                                    const SizedBox(height: 10)
                                  ]);
                            } else {
                              return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.only(
                                          right: 10,
                                          left: 10,
                                          top: 10,
                                          bottom: 10),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              messagesData[index].get('text'),
                                              style:
                                                  const TextStyle(fontSize: 20),
                                            ),
                                            Text(time)
                                          ]),
                                    ),
                                    const SizedBox(height: 10)
                                  ]);
                            }
                          }),
                    ),
                    Row(children: <Widget>[
                      Flexible(
                          child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            filled: true,
                            hintText: "Mesajınız",
                            // %70 alpha white
                            fillColor: Colors.white70),
                      )),
                      FloatingActionButton(
                        onPressed: () async {
                          sendMessage();
                        },
                        // #9C27B0
                        backgroundColor: Colors.purple,
                        child: const Icon(Icons.send),
                      )
                    ])
                  ],
                )),
          );
        });

  }
}
