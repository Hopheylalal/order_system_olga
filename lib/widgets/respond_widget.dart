import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/screens/respond_message_screen.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:provider/provider.dart';

class OrderRespond extends StatefulWidget {
  final masterName;
  final createDate;
  final content;
  final avatar;
  final message;
  final respondId;
  final orderOwnerName;
  final masterUid;
  final orderOwnerUid;
  final orderId;

  const OrderRespond({Key key,
    this.masterName,
    this.createDate,
    this.content,
    this.avatar,
    this.message,
    this.respondId,
    this.orderOwnerName,
    this.masterUid,
    this.orderOwnerUid,
  this.orderId})
      : super(key: key);

  @override
  _OrderRespondState createState() => _OrderRespondState();
}

class _OrderRespondState extends State<OrderRespond> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();


    return GestureDetector(
      onLongPress: () {
        if (widget.masterUid == user.uid) {
          showPlatformDialog(
            context: context,
            builder: (context) =>
                BasicDialogAlert(
                  title: Text("Удалить отклик?"),
                  actions: <Widget>[
                    BasicDialogAction(
                      title: Text("Ок"),
                      onPressed: () async {
                        Firestore.instance
                            .collection('responds')
                            .document('${widget.respondId}')
                            .delete();
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
        } else {
          print('You do not owner');
        }
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RespondMessageScreen(
                  masterName: widget.masterName,
                  messages: widget.message,
                  respondId: widget.respondId,
                  orderOwnerName: widget.orderOwnerName,
                  masterUid: widget.masterUid,
                  orderOwnerUid: widget.orderOwnerUid,
                ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        child: Container(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: CircleAvatar(
                  radius: 30,
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
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 8.0, top: 8, bottom: 2),
                          child: Text(
                            '${widget.masterName}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                        StreamBuilder(
                            stream: Firestore.instance
                                .collection('responds')
                                .document('${widget.respondId}')
                                .collection('respondChat')
                                .where(user.uid, isEqualTo: true)
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

//                            IconButton(
//                                icon: Icon(
//                                  Icons.delete,
//                                  color: Colors.red,
//                                ),
//                                onPressed: () async {
//                                  showPlatformDialog(
//                                    context: context,
//                                    builder: (context) => BasicDialogAlert(
//                                      title: Text("Удалить отклик?"),
//                                      actions: <Widget>[
//                                        BasicDialogAction(
//                                          title: Text("Ок"),
//                                          onPressed: () async {
//                                            await Firestore.instance
//                                                .collection('responds')
//                                                .document('$respondId')
//                                                .delete();
//                                            Navigator.pop(context);
//                                          },
//                                        ),
//                                        BasicDialogAction(
//                                          title: Text("Отмена"),
//                                          onPressed: () {
//                                            Navigator.pop(context);
//                                          },
//                                        ),
//                                      ],
//                                    ),
//                                  );
//                                }),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '${timeAgo.format(widget.createDate.toDate(),
                            locale: 'fr')}',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 8, top: 5, bottom: 3),
                      child: Text(
                        '${widget.content}',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
//                    Padding(
//                      padding:
//                      const EdgeInsets.only(left: 8, top: 5, bottom: 1),
//                      child: Text(
//                        'Задание:',
//                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
//                        overflow: TextOverflow.ellipsis,
//                      ),
//                    ),
//                    FutureBuilder(
//                      future: Firestore.instance.collection('orders')
//                          .document('${widget.orderId}')
//                          .get(),
//                      builder: (context, snapshot) {
//                        if (snapshot.hasData) {
//                          return Padding(
//                            padding:
//                            const EdgeInsets.only(left: 8, top: 1, bottom: 8),
//                            child: Text(
//                              '${snapshot.data['title']}',
//                              style: TextStyle(fontSize: 16),
//                              overflow: TextOverflow.ellipsis,
//                            ),
//                          );
//                        } else {
//                          return SizedBox(width: double.infinity,
//                            child: LinearProgressIndicator(),);
//                        }
//                      },
//
//                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
