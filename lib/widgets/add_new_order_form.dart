import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:provider/provider.dart';

class AddNewOrderForm extends StatefulWidget {
  final toMaster;
  final masterName;

  const AddNewOrderForm({Key key, this.toMaster, this.masterName}) : super(key: key);
  @override
  _AddNewOrderFormState createState() => _AddNewOrderFormState();
}

class _AddNewOrderFormState extends State<AddNewOrderForm> {
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

  addNewMission(BuildContext context, user) async {
    if(user.phoneNumber == null || user.phoneNumber == ''){
    try {
      buttonEnabled = false;
      int dateId = DateTime.now().millisecondsSinceEpoch;
      await Firestore.instance
          .collection('orders')
          .document('$dateId')
          .setData({
        'owner': curUsr,
        'createDate': DateTime.now(),
        'name': name,
        'title': aboutShort,
        'description': aboutLong,
        'orderId': dateId,
        'category': _chosenValue,
        'toMaster' : widget.toMaster,
        'masterName' : widget.masterName,
        'newOne' : true,
      }).then((_) {
        _scaffoldKey.currentState.showSnackBar(
          new SnackBar(
            backgroundColor: Colors.green,
            content: new Text('Задание добавлено.'),
          ),
        );
      }).then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          buttonEnabled = true;
          Navigator.pop(context);
        });
      });
    } catch (e) {
      PlatformAlertDialog(
        title: 'Внимание',
        content: 'Повоторите попытку позже.',
        defaultActionText: 'Ok',
      ).show(context);
    }
  }else{
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Чтобы добавить задание авторизуйтесь, как заказчик"),
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

  getBlockedStatus()async{
    var ggg = await Auth().currentUser();
    var blocked = await Firestore.instance.collection('masters').document(ggg).get();
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
    final user = context.watch<FirebaseUser>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Новое задание'),
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.maxFinite,
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Выберите специализацию',),
                        value: _chosenValue,
                        items: snapshot.data['cats']
                            .cast<String>()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String value) {
                          setState(() {
                            _chosenValue = value;
                          });
                        },
                      ),
                    ),

                    TextFormField(
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.sentences,
                      onEditingComplete: _shortEditingComplete,
                      validator: validateShort,
                      initialValue: snapshot.data['aboutShort'],
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
                      initialValue: snapshot.data['aboutLong'],
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ButtonTheme(
                        minWidth: double.maxFinite,
                        height: 45.0,
                        child: RaisedButton(
                          onPressed: () {
                            if(blockedStatus == false || blockedStatus == null){
                            _autoValidate = true;
                            if (_formKey.currentState.validate()) {
                              _formKey.currentState.save();
                              FocusScope.of(context).unfocus();
                              addNewMission(context,user);
                            }
                            }else{
                              Navigator.push(context, MaterialPageRoute(builder: (context) => Blocked()));
                            }
                          },
                          child: buttonEnabled
                              ? Center(
                                  child: const Text(
                                    'Добавить',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(backgroundColor: Colors.white,),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
