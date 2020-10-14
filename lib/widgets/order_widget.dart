import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/order_screen.dart';
import 'package:badges/badges.dart';

class Order extends StatefulWidget {
  final orderCreateDate;
  final orderOwnerName;
  final orderTitle;
  final orderCategory;
  final orderId;
  final orderOwner;
  final orderDescription;
  final masterUid;

  const Order(
      {this.orderCreateDate,
      this.orderOwnerName,
      this.orderTitle,
      this.orderCategory,
      this.orderId,
      this.orderOwner,
      this.orderDescription,
      this.masterUid});

  @override
  _OrderState createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String curUsr;
  bool newOneStatus;

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
  }



  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderScreen(
              orderScreenOwner: widget.orderOwner,
              orderScreenTitle: widget.orderTitle,
              orderScreenCreateDate: widget.orderCreateDate,
              orderScreenId: widget.orderId,
              orderScreenCategory: widget.orderCategory,
              orderScreenOwnerName: widget.orderOwnerName,
              orderScreenDescription: widget.orderDescription,
              masterUid: widget.masterUid,
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        child: Card(
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 3),
                child: Row(
                  children: [
                    Text(
                      '${widget.orderCreateDate}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Spacer(),
                      if(widget.masterUid == curUsr)
                      StreamBuilder(
                          stream: Firestore.instance
                              .collection('orders')
                              .document(widget.orderId.toString())
                              .snapshots(),
                          builder: (context, snapshot) {
                            if(snapshot.hasData){
                              if(snapshot.data['newOne'] == true){
                                return SizedBox(
                                  height: 30,
                                  width: 80,
                                  child: Chip(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.all(0),
                                    label: Text('Новое',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                );
                              }else return SizedBox();

                            }
                            return SizedBox();
                          })
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 0, bottom: 8),
                child: Text(
                  '${widget.orderTitle}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Text(
                  //     '${widget.orderCategory}',
                  //     style: TextStyle(fontSize: 16),
                  //   ),
                  // ),
                  if (curUsr == widget.orderOwner)
                    IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          showPlatformDialog(
                            context: context,
                            builder: (context) => BasicDialogAlert(
                              title: Text("Удалить задание?"),
                              actions: <Widget>[
                                BasicDialogAction(
                                  title: Text("Ок"),
                                  onPressed: () async {
                                    Firestore.instance
                                        .collection('orders')
                                        .document('${widget.orderId}')
                                        .delete();
                                    print(widget.orderId);
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
                        })
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
