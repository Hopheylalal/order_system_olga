import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/all_message_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ordersystem/widgets/respond_widget.dart';
import 'package:provider/provider.dart';

import 'order_respond_widget_msg_centr.dart';

class MessageCenterRespond extends StatefulWidget {
  final currentUserUid;

  const MessageCenterRespond({Key key, this.currentUserUid}) : super(key: key);

  @override
  _MessageCenterRespondState createState() => _MessageCenterRespondState();
}

class _MessageCenterRespondState extends State<MessageCenterRespond> {
  String curUsr;

//  void getCurrentUser() async {
//    var ggg = await Auth().currentUser();
//    setState(() {
//      curUsr = ggg;
//    });
//  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
//    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = context.watch<DataProvider>().orderId;

    final user = context.watch<FirebaseUser>();

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text('Отклики'),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: Text('Авторизуйтесь, чтобы продолжить'),
            )
          : FutureBuilder(
              future: Firestore.instance
                  .collection('masters')
                  .document(user.uid)
                  .get(),
              builder: (context, snapshotFB) {
                print(user.uid);

                List usersId = [user.uid];

                if (snapshotFB.hasData) {
                  return SingleChildScrollView(
                    child:
                    snapshotFB.data['userType'] == 'master' ?
                    StreamBuilder(
                      stream:
                      Firestore.instance
                          .collection('responds')
                          .where('array', arrayContainsAny: usersId)
                          .orderBy('createDate', descending: true)
                          .snapshots(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.none) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasData) {
                          return SizedBox(
                            child: Column(
                                children: snapshot.data.documents
                                    .map<Widget>(
                                      (val) => OrderRespondMsgCntr(
                                        avatar: val['avatar'],
                                        masterName: val['masterName'],
                                        createDate: val['createDate'],
                                        content: val['content'],
                                        message: val['conversation'],
                                        respondId: val['respondId'],
                                        orderOwnerName: val['orderOwnerName'],
                                        masterUid: val['masterUid'],
                                        orderOwnerUid: val['orderOwnerUid'],
                                        orderId: val['orderId'],
                                        orderTitle: val['orderTitle'],
                                      ),
                                    )
                                    .toList()),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ) : StreamBuilder(
                      stream: Firestore.instance
                          .collection('responds')
                          .where('orderOwnerUid', isEqualTo: user.uid)
                          .orderBy('createDate', descending: true)
                          .snapshots(),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.none) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasData) {
                          return SizedBox(
                            child: Column(
                                children: snapshot.data.documents
                                    .map<Widget>(
                                      (val) => OrderRespondMsgCntr(
                                    avatar: val['avatar'],
                                    masterName: val['masterName'],
                                    createDate: val['createDate'],
                                    content: val['content'],
                                    message: val['conversation'],
                                    respondId: val['respondId'],
                                    orderOwnerName: val['orderOwnerName'],
                                    masterUid: val['masterUid'],
                                    orderOwnerUid: val['orderOwnerUid'],
                                    orderId: val['orderId'],
                                    orderTitle: val['orderTitle'],
                                  ),
                                )
                                    .toList()),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
