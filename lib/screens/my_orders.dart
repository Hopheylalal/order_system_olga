import 'dart:io';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:ordersystem/widgets/add_new_order_form.dart';
import 'package:ordersystem/widgets/order_widget.dart';

class MyOrders extends StatefulWidget {
  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  @override
  Widget build(BuildContext context) {

    final user = context.watch<FirebaseUser>();

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      floatingActionButton: !Platform.isIOS
          ? FloatingActionButton(
              onPressed: () {
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddNewOrderForm(),
                    ),
                  );
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
              },
              child: Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Мои задания'),
        actions: [
          Platform.isIOS
              ? IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNewOrderForm(),
                        ),
                      );
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
                  },
                )
              : SizedBox()
        ],
      ),
      body: StreamBuilder<Object>(
        stream: (user != null)
            ? Firestore.instance
                .collection('orders')
                .where('owner', isEqualTo: user.uid)
                .snapshots()
            : null,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }
          if (snapshot.hasData) {
            timeAgo.setLocaleMessages('fr', timeAgo.RuMessages());
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ListView(
                      children: snapshot.data.documents
                          .map<Widget>(
                            (val) => Order(
                              orderCreateDate: timeAgo.format(
                                  val['createDate'].toDate(),
                                  locale: 'fr'),
                              orderOwnerName: val['name'],
                              orderTitle: val['title'],
                              orderCategory: val['category'],
                              orderId: val['orderId'],
                              orderOwner: val['owner'],
                              orderDescription: val['description'],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
                child: Container(
              child: Text('Добавьте задание'),
            ));
          }
        },
      ),
    );
  }
}
