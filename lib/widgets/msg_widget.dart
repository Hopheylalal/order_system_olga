import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:provider/provider.dart';

class MsgWidget extends StatelessWidget {
  final author;
  final message;
  final createDate;
  final name;
//  final bool isMe;

  const MsgWidget(
      {Key key,
      this.author,
      this.message,
      this.createDate,
      this.name,
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    timeAgo.setLocaleMessages('fr', timeAgo.RuMessages());
    final user = context.watch<FirebaseUser>();
//    print('111${author.toString()}');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
      child: Row(
        mainAxisAlignment:
        user.uid == author ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * 80 / 100,
            decoration: BoxDecoration(
              color: user.uid == author ? Colors.grey[400] : Theme.of(context).accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: !(user.uid == author) ? Radius.circular(0) : Radius.circular(25),
                bottomRight: user.uid == author ? Radius.circular(0) : Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  SizedBox(
                    height: 5,
                  ),
                  message.toString().length > 4  ?
                  message.toString().substring(0,4) == 'http' ?
                      Container(

                        child: CachedNetworkImage(
                          imageUrl: "$message",
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ) :
                  Text(
                    '$message',
                    style: TextStyle(fontSize: 18),
                  ) : Text(
                    '$message',
                    style: TextStyle(fontSize: 18),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
