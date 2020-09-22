import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:filter_list/filter_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/master_filter.dart';
import 'package:ordersystem/widgets/master_widget.dart';
import 'package:ordersystem/widgets/order_filter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Masters extends StatefulWidget {
  @override
  _MastersState createState() => _MastersState();
}

class _MastersState extends State<Masters> {
  String curUsr;
  List<String> catMasters;
  List<String> _chekedEmpty = [];
  List<String> testList = ['1','2'];

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
  }

  getMasterFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      catMasters = prefs.getStringList('masterFilterValue');
    });
  }

  getAllCategory() async {
    DocumentSnapshot catArr = await Firestore.instance
        .collection('category')
        .document('BY7oiRIc6uq14MwsJ9yV')
        .get();
    setState(() {
      _chekedEmpty = catArr.data['cats'].cast<String>();
    });
  }



  @override
  void initState() {
    getCurrentUser();
    getMasterFilter();
    getAllCategory();
    super.initState();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text('Мастера'),
        centerTitle: true,
        actions: [
          FlatButton.icon(

            label: Text('Фильтр',style: TextStyle(color: Colors.white),),
            icon: Icon(Icons.filter_list,color: Colors.white,),
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MasterFilter(
                    listFromFB: _chekedEmpty,
                  ),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('masters')
            .where('category', arrayContainsAny: catMasters)
            .where('userType', isEqualTo: 'master')
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot != null && snapshot.hasData) {
            List mstrs = snapshot.data.documents;

            List mstrs2 = mstrs
                .where((element) => element['userId'] != user?.uid)
                .toList();

            return ListView.builder(
              itemCount: mstrs2.length,
              itemBuilder: (BuildContext context, int index) {
                return MasterWidget(
                  avatar: mstrs2[index]['imgUrl'],
                  name: mstrs2[index]['name'],
                  aboutShort: mstrs2[index]['aboutShort'],
                  masterId: mstrs2[index]['userId'],
                  phoneNumber: mstrs2[index]['phoneNumber'],
                );
              },
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
