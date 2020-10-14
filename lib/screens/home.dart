import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/map_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
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
  final saveToken = GetStorage();
  final saveStatus = GetStorage();

  void changeIndex() {
    setState(() {
      pageIndex = 2;
    });
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String userType;

  getUserType(user) async {
    var data =
        await Firestore.instance.collection('masters').document(user).get();
    var userTp = data.data['userType'];
    setState(() {
      userType = userTp;
    });
  }

  void getMessages(user) {
    _firebaseMessaging.configure(onMessage: (msg) {
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);
      print(msg);
      return;
    },
//        onBackgroundMessage: myBackgroundMessageHandler,
        onLaunch: (msg) {
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);
      print(msg);
      return;
    }, onResume: (msg) {
      String beigeType = msg['data']['type'];
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);
      print(msg);
      return;
    });
  }

  void getMessagesIos(user) {
    _firebaseMessaging.configure(onMessage: (msg) {
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);
      print(msg);
      return;
    },
//        onBackgroundMessage: myBackgroundMessageHandler,
        onLaunch: (msg) {
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);
      print(msg);
      return;
    }, onResume: (msg) {
      context
          .watch<DataProvider>()
          .getMessagesFromFireStore(context.read<FirebaseUser>().uid);

      print(msg);
      return;
    });
  }

  void firebaseCloudMessagingListeners(BuildContext context) {
    _firebaseMessaging.getToken().then((deviceToken) {
      print("Firebase Device token: $deviceToken");
      context.read<DataProvider>().getToken(deviceToken);
      saveToken.write('token', deviceToken);

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
  Auth auth = Auth();
  String userUID;

  getUserData()async{
    final user = await auth.currentUser();
    print('444$user');
    if(user != null){
     await getUserType(user);
      if (user != null) {
        context
            .read<DataProvider>()
            .getMessagesFromFireStore(user);
      }
    }



  }

  @override
  void initState() {
    super.initState();

    getUserData();

    if (widget.fromWhere == '1') {
      changeIndex();
    }
    _firebaseMessaging.requestNotificationPermissions();

    // Future.delayed(Duration.zero, () {
    //   this.firebaseCloudMessagingListeners(context);
    // });
    this.firebaseCloudMessagingListeners(context);


    if (Platform.isAndroid) {
      if (context.read<FirebaseUser>() != null)
        getMessages(context.read<FirebaseUser>().uid);
    } else if (Platform.isIOS) {
      if (context.read<FirebaseUser>() != null)
        getMessagesIos(context.read<FirebaseUser>().uid);
    }
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

    final user = context.watch<FirebaseUser>();
    if (context.watch<FirebaseUser>() != null)
      context.watch<DataProvider>().getMessagesFromFireStore(user.uid);

    return Scaffold(
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
            icon: context.watch<DataProvider>().newMessage == null ||
                    context.watch<DataProvider>().newMessage == 0
                ? Icon(Icons.email)
                : user!= null ? Badge(
              animationType: BadgeAnimationType.scale,
                    badgeContent: Text(
                      '${context.watch<DataProvider>().newMessage}',
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Icon(Icons.email),
                  ) : Icon(Icons.email),
            title: Text('Уведомления'),
          ),
          BottomNavigationBarItem(
            icon: saveStatus.read('userType') == 'master'
                ? StreamBuilder(
                    stream: Firestore.instance
                        .collection('orders')
                        .where('toMaster', isEqualTo: user?.uid)
                        .where('newOne', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if(snapshot.hasData){
                        return user != null && snapshot.data.documents.length != 0
                            ? Badge(
                          animationType: BadgeAnimationType.scale,
                          badgeContent: Text(
                            '${snapshot.data.documents.length}',
                            style: TextStyle(color: Colors.white),
                          ),
                          child: const Icon(Icons.library_books),
                        )
                            : Icon(Icons.library_books);
                      }
                      return Icon(Icons.library_books);
                    })
                : Icon(Icons.library_books),
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
