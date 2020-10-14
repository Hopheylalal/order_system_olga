import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/add_new_order_form.dart';
import 'package:ordersystem/widgets/order_filter.dart';
import 'package:ordersystem/widgets/order_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:provider/provider.dart';

class AllOrders extends StatefulWidget {
  @override
  _AllOrdersState createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  String curUsr;
  List<String> catMasters;
  List catCategory;
  final userType = GetStorage();



  List _checked = [];
  List _chekedEmpty = [];


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
    // getOrderFilter();
    // getAllCategory();
//    getCategoryList();
//    getSelectedCategory();
    super.initState();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      // floatingActionButton: !Platform.isIOS
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           if (user != null) {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) => AddNewOrderForm(),
      //               ),
      //             );
      //           } else {
      //             showPlatformDialog(
      //               context: context,
      //               builder: (_) => BasicDialogAlert(
      //                 title: Text("Внимание"),
      //                 content: Text("Авторизуйтесь чтобы продолжить"),
      //                 actions: <Widget>[
      //                   BasicDialogAction(
      //                     title: Text("OK"),
      //                     onPressed: () {
      //                       Navigator.pop(context);
      //                     },
      //                   ),
      //                 ],
      //               ),
      //             );
      //           }
      //         },
      //         child: Icon(Icons.add),
      //       )
      //     : null,
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Мои задания'),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: Container(
                child: Text('Авторизуйтесь, чтобы добавить задание'),
              ),
            )
          : StreamBuilder(
              stream: userType.read('userType') == 'user'
                  ? Firestore.instance
                      .collection('orders')
                      .where('owner', isEqualTo: user.uid)
                      .orderBy('createDate', descending: true)
                      .snapshots()
                  : Firestore.instance
                      .collection('orders')
                      .where('toMaster', isEqualTo: user.uid)
                      .orderBy('createDate', descending: true)
                      .snapshots(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasError) {
                  return Text('Неизвестная ошибка...');
                }


                if (snapshot.hasData) {


                  timeAgo.setLocaleMessages('fr', timeAgo.RuMessages());
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: snapshot.data.documents
                              .map<Widget>(
                                (val) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Order(
                                    orderCreateDate: timeAgo.format(
                                        val['createDate'].toDate(),
                                        locale: 'fr'),
                                    orderOwnerName: val['name'],
                                    orderTitle: val['title'],
                                    orderCategory: val['category'],
                                    orderId: val['orderId'],
                                    orderOwner: val['owner'],
                                    orderDescription: val['description'],
                                    masterUid: val['toMaster'],

                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  );
                }

                return Center(child: CircularProgressIndicator());
              }),
    );
  }
}
