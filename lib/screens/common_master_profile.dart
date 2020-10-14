import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/screens/edit_master_profile.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/comment_widget.dart';
import 'package:provider/provider.dart';
import 'package:load/load.dart';


import 'blocked_screen.dart';

class CommonMasterProfile extends StatefulWidget {
  final String masterId;

  const CommonMasterProfile({Key key, this.masterId}) : super(key: key);

  @override
  _CommonMasterProfileState createState() => _CommonMasterProfileState();
}

class _CommonMasterProfileState extends State<CommonMasterProfile> {
  String curUsr;
  String content;
  final _formKey = new GlobalKey<FormState>();
  bool blockedStatus = false;
  bool loading = false;

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
  }

  String validateLong(String value) {
    if (value.length < 1)
      return 'Введите отзыв';
    else
      return null;
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
    getCurrentUser();
    getBlockedStatus();
    super.initState();
  }

  void addCommentDialog(BuildContext context, user) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text("Добавить отзыв"),
        content: Card(
          color: !Platform.isIOS ? Colors.white : Color(0xffEAEAEA),
          elevation: 0,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text('${user.displayName}'),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  validator: validateLong,
                  minLines: 4,
                  maxLines: 4,
                  onChanged: (val) {
                    content = val;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          FutureBuilder(
              future: Firestore.instance
                  .collection('masters')
                  .document(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return BasicDialogAction(
                      title: Text("Добавить"),
                      onPressed: () async {

                        if (_formKey.currentState.validate()) {
                          showLoadingDialog();

                          final dateTime = DateTime.now();
                          await Firestore.instance
                              .collection('comments')
                              .document()
                              .setData({
                            'ownerName': snapshot.data['name'],
                            'content': content,
                            'createDate': dateTime,
                            'masterId': widget.masterId,
                            'ownerId': user.uid
                          }).whenComplete(() {
                            hideLoadingDialog();
                            Navigator.pop(context);
                          });

                          // setState(() {});


                        }
                      });
                } else {
                  return CircularProgressIndicator();
                }
              }),
          BasicDialogAction(
            title: Text("Отмена"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();

    return Scaffold(
        backgroundColor: Color(0xFFE9E9E9),
        appBar: AppBar(
          title: Text('Профиль мастера'),
          centerTitle: true,
          actions: [
            IconButton(
                icon: Icon(
                  Icons.comment,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (blockedStatus == false || blockedStatus == null) {
                    if (user != null) {
                      addCommentDialog(context, user);
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
                  } else {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Blocked()));
                  }
                }),
          ],
        ),
        body: SingleChildScrollView(
          child: StreamBuilder(
              stream: Firestore.instance
                  .collection('masters')
                  .document(widget.masterId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: SizedBox(
                            width: double.infinity,
                            child: Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Center(
                                      child: CircleAvatar(
                                        radius: 65,
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: snapshot.data['imgUrl'],
                                            progressIndicatorBuilder: (context,
                                                    url, downloadProgress) =>
                                                CircularProgressIndicator(
                                                    value: downloadProgress
                                                        .progress),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.account_circle),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Имя мастера',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${snapshot.data['name']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      'Email мастера',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${snapshot.data['email']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      'Номер телефона',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${snapshot.data['phoneNumber']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      'Коротко о мастере',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${snapshot.data['aboutShort']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      'Развернуто о мастере',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      '${snapshot.data['aboutLong']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Text(
                                      'Специализаци',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: snapshot.data['category']
                                            .where((element) => element != '1все')
                                            .map<Widget>((val) => Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  child: Text(
                                                      '${StringUtils.capitalize(
                                                        val.toString(),
                                                      )}',
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Отзывы',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        StreamBuilder(
                          stream: Firestore.instance
                              .collection('comments')
                              .where('masterId', isEqualTo: widget.masterId)
                              .orderBy('createDate', descending: true)
                              .snapshots(),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: LinearProgressIndicator());
                            }

                            if (snapshot.hasData) {
                              if (snapshot.data.documents.length != 0) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: SizedBox(
                                    child: Column(
                                      children: snapshot.data.documents
                                          .map<Widget>(
                                            (val) => Comment(
                                              createDate: val['createDate'],
                                              content: val['content'],
                                              name: val['ownerName'],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Center(
                                    child: Text('Пока нет отзывов'),
                                  ),
                                );
                              }
                            }
                            return Center(
                              child: LinearProgressIndicator(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }
                return Container();
              }),
        ));
  }
}
