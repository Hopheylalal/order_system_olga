import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/screens/common_master_profile.dart';
import 'package:ordersystem/screens/respond_message_screen.dart';
import 'package:ordersystem/screens/toMaster_message_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/update_order.dart';
import 'package:provider/provider.dart';
import 'package:ordersystem/widgets/respond_widget.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
      @required this.orderScreenDescription, this.masterUid});

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

  void sendEmail(recipients, respond) async {
    FirebaseUser fu = await FirebaseAuth.instance.currentUser();

    final getMasterData =
        await Firestore.instance.collection('masters').document(fu.uid).get();
    // final getMasterRespond =
    // await Firestore.instance.collection('responds').document(fu.uid).get();

    String username = 'order.system.app2@gmail.com';
    String password = '1011678asd';

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'OrderSystem')
      ..recipients.add('$recipients')
      ..subject = 'Получен отклик от мастера'
//      ..text = 'This is the plain text.\nThis is line 2 of the text part.'
      ..html =
          "<p>На вашу заявку откликнулся мастер: </p>\n<p>Имя: ${getMasterData.data['name']} </p>\n<p>Отклик: ${respond} </p>\n<p>Телефон: ${getMasterData.data['phoneNumber']} </p>\n<p>Чтобы посмотреть подробности о мастере или начать диалог в чате, скачайте наше приложение (ссылка). </p>";
    final sendReport = await send(message, smtpServer);
    print(
      'Message sent: ' + sendReport.toString(),
    );
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



  // getDocExistRespond() async {
  //   FirebaseUser ff = await FirebaseAuth.instance.currentUser();
  //   var docs = await Firestore.instance
  //       .collection('responds')
  //       .where('orderId', isEqualTo: widget.orderScreenId)
  //       .where('masterUid', isEqualTo: ff?.uid)
  //       .getDocuments();
  //   setState(() {
  //     existDocs = docs.documents;
  //   });
  // }
  sendMsgButton(user) async {
    try {
      setState(() {
        buttonEnabled = false;
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
                from: user.uid, to: widget.orderScreenOwner, chatId: docId[0]),
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


  @override
  void initState() {
    // getDocExistRespond();
    getBlockedStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<DataProvider>().getOrderId(widget.orderScreenId);

    final user = context.watch<FirebaseUser>();
    final userName = user?.email;
    final userUid = user?.uid;

    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('Экран задания'),
        centerTitle: true,
        actions: [
          if(userUid == widget.masterUid)
            IconButton(icon: Icon(Icons.email),onPressed: (){

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

            },),
          if (userUid == widget.orderScreenOwner)
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
                                  categoryChosen: snapshot.data['category'],
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
                    return Expanded(child: LinearProgressIndicator());
                  }
                }),
//          if(user.email == null)

        ],
      ),
      body: StreamBuilder(
          stream: Firestore.instance
              .collection('orders')
              .document('${widget.orderScreenId}')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return CircularProgressIndicator();
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
                    Text(
                      '${updaterChecker == true ? snapshot.data['category'] : widget.orderScreenCategory}',
                      style: TextStyle(fontSize: 16),
                    ),
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
                    Divider(
                      color: Colors.grey,
                      thickness: 0.6,
                    ),
                    Text(
                      'Поручено мастеру',
                      style: TextStyle(fontSize: 20),
                    ),
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
                    // SizedBox(
                    //   height: 30,
                    // ),
                    // Text(
                    //   'Отклики',
                    //   style:
                    //       TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    // ),
                    // Divider(
                    //   color: Colors.grey,
                    // //   thickness: 0.6,
                    // ),
                    // StreamBuilder(
                    //   stream: Firestore.instance
                    //       .collection('responds')
                    //       .where('orderId', isEqualTo: widget.orderScreenId)
                    //       .orderBy('createDate', descending: true)
                    //       .snapshots(),
                    //   builder: (BuildContext context, AsyncSnapshot snapshot) {
                    //     if (snapshot.connectionState == ConnectionState.none) {
                    //       return Center(child: CircularProgressIndicator());
                    //     }
                    //     if (snapshot.hasData) {
                    //       return SizedBox(
                    //         child: Column(
                    //             children: snapshot.data.documents
                    //                 .where((element) =>
                    //                     element['orderId'] ==
                    //                             widget.orderScreenId &&
                    //                         element['masterUid'] == userUid ||
                    //                     element['orderOwnerUid'] == userUid)
                    //                 .map<Widget>(
                    //                   (val) => OrderRespond(
                    //                     avatar: val['avatar'],
                    //                     masterName: val['masterName'],
                    //                     createDate: val['createDate'],
                    //                     content: val['content'],
                    //                     message: val['conversation'],
                    //                     respondId: val['respondId'],
                    //                     orderOwnerName: val['orderOwnerName'],
                    //                     masterUid: val['masterUid'],
                    //                     orderOwnerUid: val['orderOwnerUid'],
                    //                     orderId: val['orderId'],
                    //                   ),
                    //                 )
                    //                 .toList()),
                    //       );
                    //     } else {
                    //       return LinearProgressIndicator();
                    //     }
                    //   },
                  ],
                ),
              ),
            );
          }),
    );
  }
}
