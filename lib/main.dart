import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:load/load.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';


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
      user = user1?.uid;

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

        ChangeNotifierProvider.value(value: DataProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Home()


      ),
    );
  }
}
