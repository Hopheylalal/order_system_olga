import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ordersystem/screens/toMaster_message_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/comment_widget.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'add_new_order_form.dart';

class ModalMasterProfile extends StatefulWidget {
  final String masterId;
  final String phoneNumber;
  final String masterNameFromFb;
  final List masterCategoryFromFb;

  const ModalMasterProfile(
      {Key key,
      this.masterId,
      this.phoneNumber,
      this.masterNameFromFb,
      this.masterCategoryFromFb})
      : super(key: key);

  @override
  _ModalMasterProfileState createState() => _ModalMasterProfileState();
}

class _ModalMasterProfileState extends State<ModalMasterProfile> {
  String curUsr;
  String content;
  final _formKey = new GlobalKey<FormState>();
  final _formKey1 = new GlobalKey<FormState>();
  bool loading = false;
  bool buttonEnabled = true;

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
                          Navigator.pop(context);
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
                          }).whenComplete(() {});

                          // setState(() {});

                          Navigator.pop(context);
                        }
                      });
                } else {
                  return Center(
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(),
                    ),
                  );
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

  getStarRating() async {
    final starsDocs = await Firestore.instance
        .collection('rating')
        .where('masterId', isEqualTo: widget.masterId)
        .getDocuments();
  }

  void addStarDialog(BuildContext contextm, user) {
    double starRait = 0.0;
    showPlatformDialog(
      context: contextm,
      builder: (contextm) => BasicDialogAlert(
        title: Text("Добавить рейтинг"),
        content: Card(
          color: !Platform.isIOS ? Colors.white : Color(0xffEAEAEA),
          elevation: 0,
          child: SizedBox(
            height: 100,
            child: Center(
              child: RatingBar(
                itemSize: 30,
                initialRating: 0,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                unratedColor: Colors.white24,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  starRait = rating;
                  print(starRait);
                },
              ),
            ),
          ),
        ),
        actions: <Widget>[
          FutureBuilder(
              future: Firestore.instance
                  .collection('rating')
                  .where('ownerId', isEqualTo: user)
                  .where('masterId', isEqualTo: widget.masterId)
                  .getDocuments(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return BasicDialogAction(
                      title: Text("Добавить"),
                      onPressed: () async {
                        if (snapshot.data.documents.length == 0) {
                          Navigator.pop(contextm);
                          await Firestore.instance
                              .collection('rating')
                              .document()
                              .setData({
                            'masterId': widget.masterId,
                            'ownerId': user,
                            'rating': starRait,
                          });
                          Navigator.of(contextm).pop();
                        } else {
                          var docIdList = snapshot.data.documents.first;
                          String docId = docIdList.documentID;

                          await Firestore.instance
                              .collection('rating')
                              .document(docId)
                              .updateData(
                            {
                              'rating': starRait,
                            },
                          );
                          Navigator.of(contextm).pop();
                        }
                      });
                } else {
                  return Center(
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(),
                    ),
                  );
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

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();
    print(widget.masterId);

    return Container(
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
                                height: 10,
                              ),
                              Column(
                                children: [
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                        icon: Icon(Icons.clear),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        }),
                                  ),
                                  Center(
                                    child: StreamBuilder(
                                      stream: Firestore.instance
                                          .collection('masters')
                                          .document(widget.masterId)
                                          .snapshots(),
                                      builder: (context, snapshot) {

                                        if (snapshot.hasData) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Center(
                                              child: Text(
                                                'Заходил: ${timeago.format(snapshot.data['lastSeen'].toDate(), locale: 'fr')}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return SizedBox();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: CircleAvatar(
                                  radius: 65,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: snapshot.data['imgUrl'],
                                      progressIndicatorBuilder: (context, url,
                                              downloadProgress) =>
                                          CircularProgressIndicator(
                                              value: downloadProgress.progress),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.account_circle),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: Row(
                                  children: [
                                    FlatButton.icon(
                                      onPressed: () async {

                                          await FlutterPhoneDirectCaller
                                              .callNumber(
                                                  "${widget.phoneNumber}");

                                      },
                                      icon: Icon(Icons.call),
                                      label: Text(
                                        'Звонок',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    FlatButton.icon(
                                      label: Text(
                                        'Чат',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      icon: buttonEnabled == true
                                          ? Icon(Icons.email)
                                          : SizedBox(
                                              width: 23,
                                              height: 23,
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      onPressed: () {
                                        if(user == null){
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
                                        }else{
                                          if (snapshot.data['userId'] ==
                                              user.uid) {
                                            showPlatformDialog(
                                              context: context,
                                              builder: (_) => BasicDialogAlert(
                                                title: Text("Внимание"),
                                                content: Text(
                                                    "Вы не можете писать самому себе"),
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
                                          } else {
                                            if (user != null) {
                                              if (buttonEnabled = true) {
                                                sendMsgButton(user);
                                                setState(() {
                                                  buttonEnabled = false;
                                                });
                                              }
                                            }
                                          }
                                        }

                                      },
                                    ),
                                    FlatButton.icon(
                                      onPressed: () async {
                                        if(user == null){
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
                                        if (snapshot.data['userId'] ==
                                            user.uid) {
                                          showPlatformDialog(
                                            context: context,
                                            builder: (_) => BasicDialogAlert(
                                              title: Text("Внимание"),
                                              content: Text(
                                                  "Вы не можете дать задание самому себе"),
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
                                        } else {
                                          if (user != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddNewOrderForm(
                                                  toMaster: widget.masterId,
                                                  masterName:
                                                      widget.masterNameFromFb,
                                                  masterCategoryFrpmFb: widget
                                                      .masterCategoryFromFb,
                                                ),
                                              ),
                                            );
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
                                      },
                                      icon: Icon(Icons.add),
                                      label: Text(
                                        'Задание',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
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
                                    fontSize: 18, fontWeight: FontWeight.w600),
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
                                    fontSize: 18, fontWeight: FontWeight.w600),
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
                                    fontSize: 18, fontWeight: FontWeight.w600),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: snapshot.data['category']
                                      .where((element) => element != '1все')
                                      .map<Widget>((val) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: Text(
                                              '${StringUtils.capitalize(
                                                val.toString(),
                                              )}',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Рейтинг',
                              style: TextStyle(fontSize: 20),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.add_box),
                              onPressed: () {
                                if (user != null) {
                                  if (snapshot.data['userId'] == user.uid) {
                                    showPlatformDialog(
                                      context: context,
                                      builder: (_) => BasicDialogAlert(
                                        title: Text("Внимание"),
                                        content: Text(
                                            "Вы не можете дать рейтинг самому себе"),
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
                                  } else {
                                    addStarDialog(context, user.uid);
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
                              },
                            )
                          ],
                        ),
                        Center(
                          child: StreamBuilder(
                            stream: Firestore.instance
                                .collection('rating')
                                .where(
                                  'masterId',
                                  isEqualTo: widget.masterId,
                                )
                                .snapshots(),
                            builder: (context, snapshot) {
                              print(snapshot);
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox();
                              }
                              List err = snapshot.data.documents;

                              if (err.isEmpty) {
                                return RatingBarIndicator(
                                  rating: 0,
                                  itemBuilder: (context, index) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 30.0,
                                  direction: Axis.horizontal,
                                );
                              } else if (err.length == 0) {
                                return CircularProgressIndicator();
                              } else {
                                if (snapshot.hasData) {
                                  List listResult = snapshot.data.documents;
                                  List starResult = [];
                                  double sumStarRate = 0.0;
                                  double starMidRate = 0.0;

                                  listResult.forEach((element) {
                                    starResult.add(element['rating']);
                                  });

                                  sumStarRate =
                                      starResult.reduce((a, b) => a + b);

                                  starMidRate = sumStarRate / listResult.length;

                                  return RatingBarIndicator(
                                    rating: starMidRate,
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 30.0,
                                    direction: Axis.horizontal,
                                  );
                                } else
                                  return CircularProgressIndicator();
                              }
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Отзывы',
                              style: TextStyle(fontSize: 20),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.add_box),
                              onPressed: () {
                                if (user != null) {
                                  addCommentDialog(context, user);
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
                              },
                            )
                          ],
                        ),
                      ],
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
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: LinearProgressIndicator());
                      }

                      if (snapshot.hasData) {
                        if (snapshot.data.documents.length != 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
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
        },
      ),
    );
  }
}
