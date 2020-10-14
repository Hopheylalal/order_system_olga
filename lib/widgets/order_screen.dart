import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/screens/common_master_profile.dart';
import 'package:ordersystem/screens/toMaster_message_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/update_order.dart';
import 'package:provider/provider.dart';
import 'package:simple_connectivity/simple_connectivity.dart';
import 'package:toast/toast.dart';

class OrderScreen extends StatefulWidget {
  final orderScreenCreateDate;
  final orderScreenOwnerName;
  final orderScreenTitle;
  final orderScreenCategory;
  final orderScreenId;
  final orderScreenOwner;
  final orderScreenDescription;
  final masterUid;

  const OrderScreen(
      {@required this.orderScreenCreateDate,
      @required this.orderScreenOwnerName,
      @required this.orderScreenTitle,
      @required this.orderScreenCategory,
      @required this.orderScreenId,
      @required this.orderScreenOwner,
      @required this.orderScreenDescription,
      this.masterUid});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool buttonEnabled = true;
  String avatar;
  List existDocs;
  bool updaterChecker = false;
  bool blockedStatus = false;
  bool loading = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController textFormField = TextEditingController();

  getBlockedStatus() async {
    var ggg = await Auth().currentUser();
    var blocked =
        await Firestore.instance.collection('masters').document(ggg).get();
    var blockedStatusFuture = blocked.data['blocked'];
    print(blockedStatusFuture);
    setState(() {
      blockedStatus = blockedStatusFuture;
    });
  }

  sendMsgButton(user) async {
    try {
      setState(() {
        buttonEnabled = false;
        Timer(Duration(seconds: 4), () {
          setState(() {
            buttonEnabled = true;

          });
        });
      });
      final chatExist = await Firestore.instance
          .collection('messages')
          .where('to', isEqualTo: widget.orderScreenOwner)
          .where('from', isEqualTo: user.uid)
          .getDocuments();

      final chatExist2 = await Firestore.instance
          .collection('messages')
          .where('from', isEqualTo: widget.orderScreenOwner)
          .where('to', isEqualTo: user.uid)
          .getDocuments();

      List chatEx = chatExist.documents;
      chatEx.addAll(chatExist2.documents);

      if (chatEx.length == 0) {
        final dateUid = DateTime.now().millisecondsSinceEpoch.toString();
        await Firestore.instance
            .collection('messages')
            .document('$dateUid')
            .setData({
          'createDate': DateTime.now(),
          'messages': [],
          'to': widget.orderScreenOwner,
          'from': user.uid,
          'chatId': dateUid,
          'array': [widget.orderScreenOwner, user.uid]
//                                'userType' :
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToMasterMessageScreen(
              from: user.uid,
              to: widget.orderScreenOwner,
              chatId: dateUid,
            ),
          ),
        );
      } else {
        List docId = [];

        chatEx.forEach((element) {
          docId.add(element.documentID);
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToMasterMessageScreen(
                from: user.uid, to: widget.orderScreenOwner, chatId: docId[0]),
          ),
        );
      }
    } catch (e) {
      print(
        e.toString(),
      );
      setState(() {
        buttonEnabled = true;
      });
    }
  }

  setNewStatusFalse() async {
    if (widget.orderScreenOwner != context.read<FirebaseUser>().uid) {
      try {
        await Firestore.instance
            .collection('orders')
            .document(widget.orderScreenId.toString())
            .updateData({'newOne': false});
      } catch (e) {
        print(e);
      }
    } else {
      print('OrderUser == user');
    }
  }

  var connectivityResult;

  void getConnection() async {
    connectivityResult = await (Connectivity().checkConnectivity());
  }

  @override
  void initState() {
    getConnection();
    getBlockedStatus();
    setNewStatusFalse();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();

    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('Экран задания'),
        centerTitle: true,
        actions: [
          if (user.uid == widget.masterUid)
            FlatButton.icon(
                label: Text(
                  'Чат',
                  style: TextStyle(color: Colors.white),
                ),
                icon: buttonEnabled == true
                    ? Icon(
                        Icons.email,
                        color: Colors.white,
                      )
                    : SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      ),
                onPressed: () {
                  if (blockedStatus == false || blockedStatus == null) {
                    if (connectivityResult == ConnectivityResult.none) {
                      Toast.show("Нет сети, попробуйте позже.", context,
                          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
                    } else {
                      if (user != null) {
                        if (buttonEnabled = true) {
                          sendMsgButton(user);
                        } else {
                          return null;
                        }
                      } else {
                        showPlatformDialog(
                          context: context,
                          builder: (_) => BasicDialogAlert(
                            title: Text("Внимание"),
                            content: Text("Авторизуйтесь чтобы продолжить"),
                            actions: <Widget>[
                              BasicDialogAction(
                                title: Text("OK"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Blocked(),
                      ),
                    );
                  }
                }),
          if (user.uid == widget.orderScreenOwner)
            FutureBuilder(
                future: Firestore.instance
                    .collection('orders')
                    .document('${widget.orderScreenId}')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          try {
                            var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateOrder(
                                  orderId: widget.orderScreenId,
                                ),
                              ),
                            );
                            if (result == 'updateDone') {
                              setState(() {
                                updaterChecker = true;
                              });
                            }
                          } catch (e) {
                            print(e);
                          }
                        });
                  } else {
                    return SizedBox();
                  }
                }),
//          if(user.email == null)
        ],
      ),
      body: FutureBuilder(
          future: Firestore.instance
              .collection('orders')
              .document('${widget.orderScreenId}')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return LinearProgressIndicator();
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Категория',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: snapshot.data['category']
                            .where((element) => element != '1все')
                            .map<Widget>((val) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Text(
                                    '$val',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Text(
                    //   '${updaterChecker == true ? snapshot.data['category'] : snapshot.data['category']}',
                    //   style: TextStyle(fontSize: 16),
                    // ),
                    Divider(
                      color: Colors.grey,
                      thickness: 0.6,
                    ),
                    Text(
                      'Дата размещения',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      '${widget.orderScreenCreateDate}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 0.6,
                    ),
                    Text(
                      'Имя заказчика',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      '${widget.orderScreenOwnerName}',
                      style: TextStyle(fontSize: 16),
                    ),

                    if (widget.masterUid != user.uid)
                      Text(
                        'Поручено мастеру',
                        style: TextStyle(fontSize: 20),
                      ),
                    if (widget.masterUid != user.uid)
                      Row(
                        children: [
                          Text(
                            '${snapshot.data['masterName']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Spacer(),
                          IconButton(
                              icon: Icon(Icons.info),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommonMasterProfile(
                                      masterId: snapshot.data['toMaster'],
                                    ),
                                  ),
                                );
                              })
                        ],
                      ),
                    Divider(
                      color: Colors.grey,
                      thickness: 0.6,
                    ),
                    Text(
                      'Название',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      '${updaterChecker == true ? snapshot.data['title'] : widget.orderScreenTitle}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 0.6,
                    ),
                    Text(
                      'Описание',
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      '${updaterChecker == true ? snapshot.data['description'] : widget.orderScreenDescription}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
