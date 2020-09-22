import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/widgets/all_message_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ordersystem/widgets/respond_message_center.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';


class MessageCenter extends StatefulWidget {
  final currentUserUid;

  const MessageCenter({Key key, this.currentUserUid}) : super(key: key);

  @override
  _MessageCenterState createState() => _MessageCenterState();
}

class _MessageCenterState extends State<MessageCenter> {
  String curUsr;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final saveBoxMsg = GetStorage();

//  void getCurrentUser() async {
//    var ggg = await Auth().currentUser();
//    setState(() {
//      curUsr = ggg;
//    });
//  }
  int respondBeigeCounter;
  bool msgMode = true;



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    saveBoxMsg.remove('newMsg1');

//    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = context.watch<DataProvider>().orderId;
    final user = context.watch<FirebaseUser>();

    return Scaffold(
        backgroundColor: Color(0xFFE9E9E9),
        appBar: AppBar(
          title: Text('Сообщения'),
          centerTitle: true,
//           actions: [
//             Stack(children: <Widget>[
//               IconButton(
//                 icon: FaIcon(
//                   FontAwesomeIcons.commentDots,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => MessageCenterRespond()))
//                       .then((_) async {
//                     final SharedPreferences prefs = await _prefs;
//                     int respondBeigeCounterLoad =
//                         (prefs.getInt('bageRespondCount'));
//                     prefs.setInt(
//                         "bageRespondCount", respondBeigeCounterLoad = 0);
//                   });
//                 },
//               ),
//               respondBeigeCounter != 0 && respondBeigeCounter != null
//                   ? Positioned(
//                       top: 4,
//                       left: 22,
//                       child: new Icon(
//                         Icons.notifications,
//                         size: 20,
//                         color: Colors.red,
//                       ),
// //                  child: new Text(
// //                    '$respondBeigeCounter',
// //                    style: new TextStyle(
// //                      fontWeight: FontWeight.bold,
// //                      color: Colors.white,
// //                      fontSize: 11,
// //                    ),
// //                    textAlign: TextAlign.center,
//                     )
//                   : SizedBox(),
//             ])
//           ],
        ),
        body: user?.uid != null
            ? StreamBuilder(
                stream: Firestore.instance
                    .collection('messages')
                    .where('array', arrayContains: user.uid)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return ListView(
                      children: snapshot.data.documents
                          .map<Widget>(
                            (val) => AllMessageWidget(
                              from: val['from'],
                              to: val['to'],
                              chatId: val['chatId'],
                            ),
                          )
                          .toList(),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              )
            : Center(
                child: Text('Авторизуйтесь для отправки сообщений'),
              ));
  }
}
