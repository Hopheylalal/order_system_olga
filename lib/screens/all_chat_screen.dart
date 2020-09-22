import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/all_message_widget.dart';
import 'package:provider/provider.dart';

class AllChatScreen extends StatefulWidget {
  final currentUserUid;

  const AllChatScreen({Key key, this.currentUserUid}) : super(key: key);

  @override
  _AllChatScreenState createState() => _AllChatScreenState();
}

class _AllChatScreenState extends State<AllChatScreen> {
  String curUsr;

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }
  
  bool msgMode = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();
    print(curUsr);

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text('Уведомления'),
        centerTitle: true,
      ),
      body: curUsr != null
          ? StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .where('array', arrayContains: widget.currentUserUid)
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
            ),
    );
  }
}
