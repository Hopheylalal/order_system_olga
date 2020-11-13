import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/services/auth_service.dart';

class UpdateOrder extends StatefulWidget {
  final orderId;

  const UpdateOrder({
    Key key,
    this.orderId,
  }) : super(key: key);

  @override
  _UpdateOrderState createState() => _UpdateOrderState();
}

class _UpdateOrderState extends State<UpdateOrder> {
  String category;
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String aboutShort;
  String aboutLong;
  bool _autoValidate = false;
  String curUsr;
  String name;
  bool buttonEnabled = true;
  bool blockedStatus = false;

  final FocusNode _shortFocusNode = FocusNode();
  final FocusNode _longFocusNode = FocusNode();

  String _chosenValue;

  String validateLong(String value) {
    if (value.length < 1)
      return 'Введите заголовок';
    else
      return null;
  }

  String validateShort(String value) {
    if (value.length < 1)
      return 'Введите описание задания';
    else
      return null;
  }

  void _shortEditingComplete() {
    final newFocus = _longFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  updateMission(BuildContext context) async {
    try {
      buttonEnabled = false;
      await Firestore.instance
          .collection('orders')
          .document('${widget.orderId}')
          .updateData({
        'title': aboutShort,
        'description': aboutLong,
      }).then((_) {
        _scaffoldKey.currentState.showSnackBar(
          new SnackBar(
            backgroundColor: Colors.green,
            content: new Text('Задание обновленно.'),
          ),
        );
      }).then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          buttonEnabled = true;
          Navigator.pop(context, 'updateDone');
        });
      });
    } catch (e) {
      print(e.toString());
      // PlatformAlertDialog(
      //   title: 'Внимание',
      //   content: 'Повоторите попытку позже.',
      //   defaultActionText: 'Ok',
      // ).show(context);
    }
  }

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    print(ggg);
    final userInfo =
        await Firestore.instance.collection('masters').document(ggg).get();
    final nameDb = userInfo.data['name'];

    setState(() {
      curUsr = ggg;
      name = nameDb;
    });
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

  @override
  void initState() {
    super.initState();
    category = '';
    getCurrentUser();
    getBlockedStatus();
  }

  @override
  void dispose() {
    _shortFocusNode.dispose();
    _longFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Обновить задание'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidate: _autoValidate,
          child: FutureBuilder(
            future: Firestore.instance
                .collection('category')
                .document('BY7oiRIc6uq14MwsJ9yV')
                .get(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData)
                return Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: LinearProgressIndicator(),
                  ),
                );
              return FutureBuilder(
                future: Firestore.instance
                    .collection('orders')
                    .document('${widget.orderId}')
                    .get(),
                builder: (BuildContext context, AsyncSnapshot snapshot2) {
                  if (!snapshot2.hasData) {
                    return Center(
                      child: LinearProgressIndicator(),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            enableSuggestions: true,
                            textCapitalization: TextCapitalization.sentences,
                            onEditingComplete: _shortEditingComplete,
                            validator: validateShort,
                            initialValue: snapshot2.data['title'],
                            keyboardType: TextInputType.text,
                            minLines: 2,
                            maxLines: 2,
                            onSaved: (val) {
                              aboutShort = val;
                            },
                            decoration: InputDecoration(
                                labelText: 'Короткое название задания'),
                          ),
                          TextFormField(
                            textCapitalization: TextCapitalization.sentences,
                            focusNode: _longFocusNode,
                            enableSuggestions: true,
                            initialValue: snapshot2.data['description'],
                            keyboardType: TextInputType.multiline,
                            validator: validateLong,
                            minLines: 4,
                            maxLines: 4,
                            onSaved: (val) {
                              aboutLong = val;
                            },
                            decoration:
                                InputDecoration(labelText: 'Описание задания'),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FutureBuilder(
                            future: Firestore.instance
                                .collection('orders')
                                .document(widget.orderId.toString())
                                .get(),
                            builder: (context, snap) {
                              if (snap.hasData) {
                                List<String> imgUrl =
                                snap.data['imgUrl'].cast<String>();
                                return Column(
                                  children: [
                                    if(imgUrl.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Фото объекта',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    Center(
                                      child: Wrap(
                                        children: imgUrl.map<Widget>((pic) {
                                          String img = pic;
                                          List phList = [];
                                          phList.add(pic);
                                          return Stack(
                                            children: [
                                              Padding(
                                                padding:
                                                const EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  height: 140,
                                                  width: 140,
                                                  child: GestureDetector(
                                                    onTap: () {},
                                                    child: CachedNetworkImage(
                                                      imageUrl: pic,
                                                      progressIndicatorBuilder: (context,
                                                          url,
                                                          downloadProgress) =>
                                                          CircularProgressIndicator(
                                                              value:
                                                              downloadProgress
                                                                  .progress),
                                                      errorWidget: (context,
                                                          url, error) =>
                                                          Icon(Icons
                                                              .image_not_supported_sharp),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    Firestore.instance
                                                        .collection('orders')
                                                        .document(
                                                      widget.orderId
                                                          .toString(),
                                                    ).updateData({
                                                      'imgUrl' : FieldValue.arrayRemove(phList)
                                                    }).whenComplete(() {
                                                      setState(() {

                                                      });
                                                    });
                                                  })
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return SizedBox();
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
                            child: ButtonTheme(
                              minWidth: double.maxFinite,
                              height: 45.0,
                              child: RaisedButton(
                                onPressed: () {
                                  if (blockedStatus == false ||
                                      blockedStatus == null) {
                                    _autoValidate = true;
                                    if (_formKey.currentState.validate()) {
                                      _formKey.currentState.save();
                                      FocusScope.of(context).unfocus();
                                      updateMission(context);
                                    }
                                  } else {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Blocked()));
                                  }
                                },
                                child: buttonEnabled
                                    ? Center(
                                        child: const Text(
                                          'Обновить',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
