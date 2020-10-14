import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/msg_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_connectivity/simple_connectivity.dart';
import 'package:toast/toast.dart';
import 'package:get_storage/get_storage.dart';

import 'blocked_screen.dart';
import 'common_master_profile.dart';

class ToMasterMessageScreen extends StatefulWidget {
  final String from;
  final String to;
  final String chatId;

  const ToMasterMessageScreen({Key key, this.from, this.to, this.chatId})
      : super(key: key);

  @override
  _ToMasterMessageScreenState createState() => _ToMasterMessageScreenState();
}

class _ToMasterMessageScreenState extends State<ToMasterMessageScreen> {
  TextEditingController textEditingController = TextEditingController();
  String userName;
  final _controller = ScrollController();
  final saveBox = GetStorage();
  String avatar;
  var userType;

  String currentUserTo;
  var connectivityResult;
  bool blockedStatus = false;

  void getConnection() async {
    connectivityResult = await (Connectivity().checkConnectivity());
  }

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

  @override
  void initState() {
    // getDisplayName();
    getUserNameAndAvatar(context.read<FirebaseUser>().uid);
    getConnection();
    getBlockedStatus();
    super.initState();
  }

  void delNewMsg(user) async {
    final allMessages = Firestore.instance
        .collection('messages')
        .document('${widget.chatId}')
        .collection('chat');

    final documentss =
        await allMessages.where(user, isEqualTo: true).getDocuments();
    final docs = documentss.documents;

    final getCurrentUserTo = Firestore.instance
        .collection('messages')
        .document('${widget.chatId}')
        .get();

    getCurrentUserTo.then((value) {
      currentUserTo = value.data[user];
    });
    docs.forEach(
      (element) {
        Firestore.instance
            .collection('messages')
            .document('${widget.chatId}')
            .collection('chat')
            .document(element.documentID)
            .updateData({user: false});
      },
    );
  }

  getUserNameAndAvatar(userId) async {
    try {
      if (userId == widget.from) {
        DocumentSnapshot userDataFrom = await Firestore.instance
            .collection('masters')
            .document(widget.to)
            .get();
        userName = userDataFrom.data['name'];
        userType = userDataFrom.data['userType'];
        avatar = userDataFrom.data['imgUrl'];
        saveBox.write('avatar', avatar);
        saveBox.write('userName', userName);
        saveBox.write('userType1', userType);
      } else if (userId == widget.to) {
        DocumentSnapshot userDataTo = await Firestore.instance
            .collection('masters')
            .document(widget.from)
            .get();
        userName = userDataTo.data['name'];
        userType = userDataTo.data['userType'];
        avatar = userDataTo.data['imgUrl'];
        saveBox.write('avatar', avatar);
        saveBox.write('userName', userName);
        saveBox.write('userType1', userType);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    print(saveBox.read('userName'));
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    final user = context.watch<FirebaseUser>();

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(
          userName ?? saveBox.read('userName') ?? '',
        ),
        centerTitle: true,
        leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 40,
              color: Colors.white,
            ),
            onPressed: () async{
              // context.read<DataProvider>().newMessage = 0;

              delNewMsg(user.uid);
              context.read<DataProvider>().getMessagesFromFireStore(user.uid);

              Navigator.pop(context);
            }),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              if (userType == 'master') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommonMasterProfile(
                      masterId: user.uid == widget.to ? widget.from : widget.to,
                    ),
                  ),
                );
              } else {
                print('UserType user');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: CircleAvatar(
                radius: 23,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatar ?? saveBox.read('avatar') ?? '',
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) =>
                            CircularProgressIndicator(
                                value: downloadProgress.progress),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.account_circle),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection('messages')
                    .document('${widget.chatId}')
                    .collection('chat')
                    .orderBy('createDate', descending: false)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasData) {
                    List msgList = snapshot.data.documents;

                    return ListView(
                      reverse: true,
                      controller: _controller,
                      shrinkWrap: true,
                      children: <Widget>[
                        for (var i in msgList.reversed)
                          MsgWidget(
                            author: i['sender'],
                            message: i['content'],
                            name: i['nameAdmin'],
                          )
                      ],
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 15),
                      child: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        enableSuggestions: true,
                        keyboardType: TextInputType.multiline,
                        minLines: 4,
                        maxLines: 4,
                        controller: textEditingController,
                      ),
                    ),
                  ),

                  FutureBuilder(
                      future: Firestore.instance
                          .collection('messages')
                          .document('${widget.chatId}')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.blue,
                            ),
                            onPressed: () {},
                          );
                        }
                        if (snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: IconButton(
                              icon: Icon(
                                Icons.send,
                                color: Colors.blue,
                              ),
                              onPressed: () async {
                                if (blockedStatus == false ||
                                    blockedStatus == null) {
                                  if (connectivityResult ==
                                      ConnectivityResult.none) {
                                    Toast.show(
                                        "Нет сети, попробуйте позже.", context,
                                        duration: Toast.LENGTH_SHORT,
                                        gravity: Toast.CENTER);
                                  } else {
                                    List addUserUidToArray = [
                                      widget.to,
                                      widget.from
                                    ];
                                    if (snapshot.data['array'].length == 2) {
                                      try {
                                        final name = await Firestore.instance
                                            .collection('masters')
                                            .document(user.uid)
                                            .get();

                                        if (textEditingController
                                            .text.isNotEmpty) {
                                          Firestore.instance
                                              .collection('messages')
                                              .document('${widget.chatId}')
                                              .collection('chat')
                                              .add({
                                            'nameAdmin': name.data['name'],
                                            'sender': user.uid,
                                            'createDate':
                                                FieldValue.serverTimestamp(),
                                            'to': user.uid == widget.to
                                                ? widget.from
                                                : widget.to,
                                            'content':
                                                textEditingController.text,
                                            'new': true,
                                            widget.to: true,
                                            widget.from: true,
                                            'chatId': widget.chatId
                                          });
                                          textEditingController.clear();
                                        }

                                        _controller.animateTo(
                                          0.0,
                                          curve: Curves.easeOut,
                                          duration:
                                              const Duration(milliseconds: 300),
                                        );
                                      } catch (e) {
                                        print(e.toString());
                                      }
                                    } else {
                                      final name = await Firestore.instance
                                          .collection('masters')
                                          .document(user.uid)
                                          .get();
                                      Firestore.instance
                                          .collection('messages')
                                          .document('${widget.chatId}')
                                          .updateData({
                                        'array': FieldValue.arrayUnion(
                                            addUserUidToArray)
                                      }).then((_) {
                                        if (textEditingController
                                            .text.isNotEmpty) {
                                          Firestore.instance
                                              .collection('messages')
                                              .document('${widget.chatId}')
                                              .collection('chat')
                                              .add({
                                            'nameAdmin': name.data['name'],
                                            'sender': user.uid,
                                            'createDate':
                                                FieldValue.serverTimestamp(),
                                            'to': user.uid == widget.to
                                                ? widget.from
                                                : widget.to,
                                            'content':
                                                textEditingController.text,
                                            'new': true,
                                            widget.to: true,
                                            widget.from: true,
                                          });
                                          textEditingController.clear();
                                        }
                                      });
                                    }
                                  }
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Blocked()));
                                }
                              },
                            ),
                          );
                        } else {
                          return Container();
                        }
                      })
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
