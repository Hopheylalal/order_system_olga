import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ordersystem/common/master_blocked.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/screens/home.dart';
import 'package:ordersystem/screens/settings.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:load/load.dart';

void main() async{
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(OrderFinderApp());
}

class OrderFinderApp extends StatefulWidget {
  @override
  _OrderFinderAppState createState() => _OrderFinderAppState();
}



class _OrderFinderAppState extends State<OrderFinderApp> {
  String user;

  void getUserUid()async{
    final FirebaseAuth auth = FirebaseAuth.instance;

    final FirebaseUser user1 = await auth.currentUser();
    setState(() {
      user = user1.uid;

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserUid();
  }

  @override
  Widget build(BuildContext context) {
    print(user);
    return MultiProvider(
      providers: [
        StreamProvider.value(
          value: FirebaseAuth.instance.onAuthStateChanged,
        ),
        // StreamProvider<bool>.value(
        //   value: Firestore.instance
        //       .collection('masters')
        //       .document('$user')
        //       .snapshots()
        //       .map((event) => event.data['blocked']),
        // ),
        ChangeNotifierProvider.value(value: DataProvider())
      ],
      child: LoadingProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Home()
          // StreamBuilder(
          //     stream: Firestore.instance
          //         .collection('masters')
          //         .document('$user')
          //         .snapshots()
          //         .map((event) => event.data['blocked']),
          //     builder: (context, snapshot) {
          //       print('1110${snapshot.data}');
          //       if (snapshot.hasData) {
          //         return snapshot.data == false || snapshot.data == null ? Home() : Blocked();
          //       }
          //       return Container(
          //         color: Colors.white,
          //         child: LinearProgressIndicator(),
          //       );
          //     }),

        ),
      ),
    );
  }
}