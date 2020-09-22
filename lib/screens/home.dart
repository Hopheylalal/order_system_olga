import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/screens/all_orders.dart';
import 'package:badges/badges.dart';
import 'package:ordersystem/screens/settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import 'message_cemter_screen.dart';

class Home extends StatefulWidget {
  final String fromWhere;

  const Home({Key key, this.fromWhere}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PageController _pageController;
  int pageIndex = 0;
  final saveBoxMsg1 = GetStorage();

  void changeIndex() {
    setState(() {
      pageIndex = 2;
    });
  }

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  int messageBeigeCounter;
  int respondBeigeCounter;

  List test = [];

  setBeigeMsg() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      messageBeigeCounter = (prefs.getInt('bageMessageCount'));
    });
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void statusBeigeUpdate(type) {
    if (type == 'msg') {
      context.read<DataProvider>().bageMessageCountIncr();
    }
  }

  void getMessages() {
    _firebaseMessaging.configure(onMessage: (msg) {
      String beigeType = msg['data']['type'];
      statusBeigeUpdate(beigeType);
      print(msg);
      return;
    },
//        onBackgroundMessage: myBackgroundMessageHandler,
        onLaunch: (msg) {
      String beigeType = msg['data']['type'];
      statusBeigeUpdate(beigeType);
      print(msg);
      return;
    }, onResume: (msg) {
      String beigeType = msg['data']['type'];
      statusBeigeUpdate(beigeType);
      print(msg);
      return;
    });
  }

  void getMessagesIos() {
    _firebaseMessaging.configure(onMessage: (msg) {
      context.read<DataProvider>().bageMessageCountIncr();
      if (msg.containsValue('msg')) {
        context.read<DataProvider>().bageMessageCountIncr();
      }

      print(msg);
      return;
    },
//        onBackgroundMessage: myBackgroundMessageHandler,
        onLaunch: (msg) {
      if (msg.containsValue('msg')) {
        context.read<DataProvider>().bageMessageCountIncr();
      }

      print(msg);
      return;
    }, onResume: (msg) {
      if (msg.containsValue('msg')) {
        context.read<DataProvider>().bageMessageCountIncr();
      }

      print(msg);
      return;
    });
  }

  void firebaseCloudMessagingListeners(BuildContext context) {
    _firebaseMessaging.getToken().then((deviceToken) {
      print("Firebase Device token: $deviceToken");
      context.read<DataProvider>().getToken(deviceToken);
    });
  }

  void getBlockedStatus() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    Future<DocumentSnapshot> data =
        Firestore.instance.collection('masters').document('${user.uid}').get();

    data.then((value) {
      if (value['blocked'] == true) {
        showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
            title: Text("Внимание"),
            content: Text('Ваша учетная запись удалина администрацией сервиса'),
            actions: <Widget>[
              BasicDialogAction(
                title: Text("Ок"),
                onPressed: () async {
                  Navigator.of(context).pop();
                  FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  int newMessage;

  getMessagesFromFireStore(user) async {
    final chatIds = [];
    final chatList = [];
    int msgCount;

    final msgArrFb = await Firestore.instance
        .collection('messages')
        .where('array', arrayContains: user)
        .getDocuments()
        .then((val) => val.documents);

    msgArrFb.forEach((element) {
      chatIds.add(element.documentID);
    });

    for (int i = 0; i < chatIds.length; i++) {
      Firestore.instance
          .collection("messages")
          .document(chatIds[i])
          .collection("chat")
          .getDocuments()
          .then(
            (value) => value.documents.where((element) {
              return element.data['$user'] == true;

            }),
          );
      


    }

    print(chatList.length);
  }

  @override
  void initState() {
    super.initState();
    if (widget.fromWhere == '1') {
      changeIndex();
    }
    _firebaseMessaging.requestNotificationPermissions();

    Future.delayed(Duration.zero, () {
      this.firebaseCloudMessagingListeners(context);
    });

    if (Platform.isAndroid) {
      getMessages();
    } else if (Platform.isIOS) {
      getMessagesIos();
    }

    setBeigeMsg();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  final tabs = [
    MapScreen(),
    MessageCenter(),
    AllOrders(),
    Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    int msgCount = saveBoxMsg1.read('newMsg1');

    final countBage = context.watch<DataProvider>().bageCounter;
    final user = context.watch<FirebaseUser>();
    setState(() {
      setBeigeMsg();
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          getMessagesFromFireStore(user.uid);
        },
      ),
      body: tabs[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
//                BottomNavigationBarItem(
//                  icon: const Icon(Icons.business_center),
//                  title: Text('Мои'),
//                ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            title: Text('Карта'),
          ),
          BottomNavigationBarItem(
            icon: msgCount == null || msgCount == 0
                ? Icon(Icons.email)
                : Badge(
                    badgeContent: Text(
                      '$msgCount',
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Icon(Icons.email),
                  ),
            title: Text('Уведомления'),
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder(
                stream: Firestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  return user != null
                      ? Badge(
                          badgeContent: Text(
                            '3',
                            style: TextStyle(color: Colors.white),
                          ),
                          child: const Icon(Icons.library_books),
                        )
                      : Icon(Icons.library_books);
                }),
            title: Text('Мои задания'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_box),
            title: Text('Профиль'),
          ),
        ],
      ),
    );
  }
}
