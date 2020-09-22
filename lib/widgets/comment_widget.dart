import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;


class Comment extends StatelessWidget {
  final name;
  final createDate;
  final content;

  const Comment({Key key, this.name, this.createDate, this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name',style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                  SizedBox(height: 3,),
                  Text('$content'),
                  SizedBox(height: 8,),
                  Text('${timeAgo.format(createDate.toDate(), locale: 'fr')}'),



                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
