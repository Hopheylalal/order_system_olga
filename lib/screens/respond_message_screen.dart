import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/msg_widget.dart';
import 'package:provider/provider.dart';
import 'blocked_screen.dart';
import 'common_master_profile.dart';
import 'package:simple_connectivity/simple_connectivity.dart';
import 'package:toast/toast.dart';

class RespondMessageScreen extends StatefulWidget {
  final respondId;
  final messages;
  final masterName;
  final orderOwnerName;
  final masterUid;
  final orderOwnerUid;

  const RespondMessageScreen(
      {Key key,
      this.respondId,
      this.messages,
      this.masterName,
      this.orderOwnerName,
      this.masterUid,
      this.orderOwnerUid})
      : super(key: key);

  @override
  _RespondMessageScreenState createState() => _RespondMessageScreenState();
}

class _RespondMessageScreenState extends State<RespondMessageScreen> {
  TextEditingController textEditingController = TextEditingController();
  final _controller = ScrollController();
  String currentUserTo;
  bool blockedStatus = false;

  void delNewMsg(user) async {
    final allMessages = Firestore.instance
        .collection('responds')
        .document('${widget.respondId}')
        .collection('respondChat');

    final documentss =
        await allMessages.where(user, isEqualTo: true).getDocuments();
    final docs = documentss.documents;

    final getCurrentUserTo = Firestore.instance
        .collection('responds')
        .document('${widget.respondId}')
        .get();

    getCurrentUserTo.then((value) {
      currentUserTo = value.data[user];
    });
    docs.forEach(
      (element) {
        Firestore.instance
            .collection('responds')
            .document('${widget.respondId}')
            .collection('respondChat')
            .document(element.documentID)
            .updateData({user: false});
      },
    );
  }

  var connectivityResult;

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
    // TODO: implement initState
    super.initState();
    getConnection();
    getBlockedStatus();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {});

    final user = context.watch<FirebaseUser>();
    final userName = user.displayName;

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: user.uid != widget.masterUid
            ? Text('${widget.masterName}')
            : Text('${widget.orderOwnerName}'),
        centerTitle: true,
        actions: [
          FutureBuilder(
            future: Firestore.instance
                .collection('masters')
                .document(user.uid != widget.orderOwnerUid
                    ? widget.orderOwnerUid
                    : widget.masterUid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final userType = snapshot.data['userType'];
                return GestureDetector(
                  onTap: () {
                    if (userType == 'master') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommonMasterProfile(
                            masterId: snapshot.data['userId'],
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
                          imageUrl: snapshot.data['imgUrl'],
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
                );
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ],
        leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 40,
              color: Colors.white,
            ),
            onPressed: () {
              delNewMsg(user.uid);
              Navigator.pop(context);
            }),
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
                    .collection('responds')
                    .document('${widget.respondId}')
                    .collection('respondChat')
                    .orderBy('createDate', descending: false)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    List msgList = snapshot.data.documents;
                    return ListView(
                      reverse: true,
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
                  } else {}
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
                        controller: textEditingController,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      if (blockedStatus == false || blockedStatus == null) {
                        if (connectivityResult == ConnectivityResult.none) {
                          Toast.show("Нет сети, попробуйте позже.", context,
                              duration: Toast.LENGTH_SHORT,
                              gravity: Toast.CENTER);
                        } else {
                          if (textEditingController.text.isNotEmpty) {
                            final name = await Firestore.instance
                                .collection('masters')
                                .document(user.uid)
                                .get();
                            Firestore.instance
                                .collection('responds')
                                .document('${widget.respondId}')
                                .collection('respondChat')
                                .add({
                              'nameAdmin': name.data['name'],
                              'sender': user.uid,
                              'createDate': FieldValue.serverTimestamp(),
                              'to': user.uid == widget.orderOwnerUid
                                  ? widget.masterUid
                                  : widget.orderOwnerUid,
                              'content': textEditingController.text,
                              widget.masterUid: true,
                              widget.orderOwnerUid: true,
                              'new': true,
                            });
                            textEditingController.clear();
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
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
