import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/toMaster_message_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class AllMessageWidget extends StatefulWidget {
  final from;
  final to;
  final chatId;

  const AllMessageWidget({Key key, this.from, this.to, this.chatId})
      : super(key: key);

  @override
  _AllMessageWidgetState createState() => _AllMessageWidgetState();
}

class _AllMessageWidgetState extends State<AllMessageWidget> {
  String currentUserTo;
  bool enterToChat = false;
  String chatIdFromFb;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();



  getChatId() async {
    await Firestore.instance
        .collection('messages')
        .document('${widget.chatId}')
        .get()
        .then((value) {
      chatIdFromFb = value.data['chatId'];

    });
  }

  @override
  void initState() {
    getChatId();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final user = context.watch<FirebaseUser>();
    final userUid = user.uid;
    List arrUser = [userUid];

    return GestureDetector(
      onLongPress: () {
        showPlatformDialog(
          context: context,
          builder: (context) => BasicDialogAlert(
            title: Text("Удалить сообщение?"),
            actions: <Widget>[
              BasicDialogAction(
                title: Text("Ок"),
                onPressed: () async {
                  Firestore.instance
                      .collection('messages')
                      .document('${widget.chatId}')
                      .updateData({'array': FieldValue.arrayRemove(arrUser)});
                  print(widget.chatId);
                  Navigator.pop(context);
                },
              ),
              BasicDialogAction(
                title: Text("Отмена"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
      onTap: () async {
        setState(() {
          enterToChat = true;
        });
        final getCurrentUserTo = Firestore.instance
            .collection('messages')
            .document('${widget.chatId}')
            .get();

        getCurrentUserTo.then((value) {
          currentUserTo = value.data[userUid];
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToMasterMessageScreen(
              from: widget.from,
              to: widget.to,
              chatId: widget.chatId,
            ),
          ),
        ).then((_) async{
          setState((){
            enterToChat = false;
          });

          context.read<DataProvider>().clearMsgCounter();

        });

        final allMessages = Firestore.instance
            .collection('messages')
            .document('${widget.chatId}')
            .collection('chat');

        final documentss =
            await allMessages.where(userUid, isEqualTo: true).getDocuments();
        final docs = documentss.documents;
        docs.forEach(
          (element) {
            Firestore.instance
                .collection('messages')
                .document('${widget.chatId}')
                .collection('chat')
                .document(element.documentID)
                .updateData({userUid: false});
          },
        );
      },
      child: StreamBuilder(
          stream: (userUid == widget.to)
              ? Firestore.instance
                  .collection('masters')
                  .document(user.email != null || user.email != ''
                      ? widget.from
                      : widget.to)
                  .snapshots()
              : Firestore.instance
                  .collection('masters')
                  .document(user.email != null || user.email != ''
                      ? widget.to
                      : widget.from)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
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
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: [
                              Text(
                                '${snapshot.data['name']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          StreamBuilder(
                              stream: Firestore.instance
                                  .collection('messages')
                                  .document('${widget.chatId}')
                                  .collection('chat')
                                  .where(userUid, isEqualTo: true)
//                              .where('new', isEqualTo: true)
                                  .snapshots(),
                              builder: (context, snapshot) {

                                if (snapshot.hasData) if (snapshot
                                        .data.documents.length !=
                                    0)

                                return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: new Container(
                                      padding: EdgeInsets.all(1),
                                      decoration: new BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Center(
                                        child: new Text(
                                          '${snapshot.data.documents.length}',
                                          style: new TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                return SizedBox();
                              }),
                        ],
                      ),
                    ),
                  ),
                  if (enterToChat == true && widget.chatId == chatIdFromFb)
                    SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(),
                    )
                ],
              );
            } else {
              Text('Ошибка подключения');
            }
            return SizedBox();
          }),
    );
  }
}
