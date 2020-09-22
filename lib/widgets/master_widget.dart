import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/screens/common_master_profile.dart';
import 'package:ordersystem/screens/toMaster_message_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:simple_connectivity/simple_connectivity.dart';
import 'package:toast/toast.dart';

class MasterWidget extends StatefulWidget {
  final String avatar;
  final String name;
  final String aboutShort;
  final String masterId;
  final List messages;
  final String phoneNumber;

  const MasterWidget(
      {Key key,
      this.avatar,
      this.name,
      this.aboutShort,
      this.masterId,
      this.messages,
      this.phoneNumber})
      : super(key: key);

  @override
  _MasterWidgetState createState() => _MasterWidgetState();
}

class _MasterWidgetState extends State<MasterWidget> {
  bool buttonEnabled = true;

  final _formKey = GlobalKey<FormState>();
  TextEditingController textFormField = TextEditingController();

  String currentName = '';
  bool blockedStatus = false;

  sendMsgButton(user) async {
    try {
      setState(() {
        buttonEnabled = false;
      });
      final chatExist = await Firestore.instance
          .collection('messages')
          .where('to', isEqualTo: widget.masterId)
          .where('from', isEqualTo: user.uid)
          .getDocuments();

      final chatExist2 = await Firestore.instance
          .collection('messages')
          .where('from', isEqualTo: widget.masterId)
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
          'to': widget.masterId,
          'from': user.uid,
          'chatId': dateUid,
          'array': [widget.masterId, user.uid]
//                                'userType' :
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToMasterMessageScreen(
              from: user.uid,
              to: widget.masterId,
              chatId: dateUid,
            ),
          ),
        );
        setState(() {
          buttonEnabled = true;
        });
      } else {
        List docId = [];

        chatEx.forEach((element) {
          docId.add(element.documentID);
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToMasterMessageScreen(
                from: user.uid, to: widget.masterId, chatId: docId[0]),
          ),
        );
        setState(() {
          buttonEnabled = true;
        });
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
    final user = context.watch<FirebaseUser>();
    final currentUserName = user?.displayName;

    return SizedBox(
      height: 120,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommonMasterProfile(
                masterId: widget.masterId,
              ),
            ),
          );
        },
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.avatar,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) =>
                                  CircularProgressIndicator(
                                      value: downloadProgress.progress),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.account_circle),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.name}',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.clip,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            '${widget.aboutShort}',
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Spacer(),
                              FlatButton.icon(
                                icon: Icon(Icons.call),
                                label: Text('Звонок'),
                                onPressed: () async {
                                  if (blockedStatus == false ||
                                      blockedStatus == null) {
                                    await FlutterPhoneDirectCaller.callNumber(
                                        "${widget.phoneNumber}");
                                  } else {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Blocked()));
                                  }
                                },
                              ),
                              FlatButton.icon(
                                  label: Text('Чат'),
                                  icon: buttonEnabled == true
                                      ? Icon(Icons.email)
                                      : SizedBox(
                                          width: 23,
                                          height: 23,
                                          child: CircularProgressIndicator(),
                                        ),
                                  onPressed: () {
                                    if (blockedStatus == false ||
                                        blockedStatus == null) {
                                      if (connectivityResult ==
                                          ConnectivityResult.none) {
                                        Toast.show(
                                            "Нет сети, попробуйте позже.",
                                            context,
                                            duration: Toast.LENGTH_SHORT,
                                            gravity: Toast.CENTER);
                                      } else {
                                        if (user != null) {
                                          if (buttonEnabled = true) {
                                            sendMsgButton(user);
                                            setState(() {
                                              buttonEnabled = false;
                                            });
                                          } else {
                                            return null;
                                          }
                                        } else {
                                          showPlatformDialog(
                                            context: context,
                                            builder: (_) => BasicDialogAlert(
                                              title: Text("Внимание"),
                                              content: Text(
                                                  "Авторизуйтесь чтобы продолжить"),
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
                                  })
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
