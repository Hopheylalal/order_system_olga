import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/auth/sign_in.dart';
import 'package:ordersystem/screens/master_profile.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';



class AuthMAster extends StatefulWidget {
  @override
  _AuthMAsterState createState() => _AuthMAsterState();
}

class _AuthMAsterState extends State<AuthMAster> {
  String phoneNumber;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final _codeController = TextEditingController();
  bool progress = false;

  final saveToken = GetStorage();



  var maskFormatter = new MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {
      "#": RegExp(r'[0-9]'),
    },
  );

  Future loginMaster(
    BuildContext context,
    String phone,
  ) async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    setState(() {
      isLoading = true;
    });

    _auth
        .verifyPhoneNumber(
            phoneNumber: phone,
            timeout: Duration(seconds: 20),
            verificationCompleted: (AuthCredential credential) async {
              AuthResult result = await _auth.signInWithCredential(credential);

              FirebaseUser user = result.user;

              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MasterProfile(
                      status: 'reg',
                      userType: null,
                    ),
                  ),
                );
              } else {
                setState(() {
                  isLoading = false;
                });
                PlatformAlertDialog(
                  title: 'Внимание',
                  content: 'Нет сети. Попробуйте позже.',
                  defaultActionText: 'Ok',
                ).show(context);
              }

              //This callback would gets called when verification is done automatically
            },
            verificationFailed: (AuthException exception) {
              print(exception.message);
              PlatformAlertDialog(
                title: 'Внимание',
                content: 'Попробуйте позже...',
                defaultActionText: 'Ok',
              ).show(context);
              setState(() {
                isLoading = false;
              });
            },
            codeSent: (String verificationId, [int forceResendingToken]) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return FlutterEasyLoading(
                    child: AlertDialog(
                      title:  Text("Введите SMS код"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(hintText: '-  -  -  -  -  -'),
                            controller: _codeController,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                         FlatButton(
                          child: Text("ОК"),
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () async {

                            // showLoadingDialog();
                            EasyLoading.show(status: 'Загрузка...',);

                            print('MYTOKEN${context.read<DataProvider>().token}');

                            final code = _codeController.text.trim();
                            AuthCredential credential =
                                PhoneAuthProvider.getCredential(
                                    verificationId: verificationId,
                                    smsCode: code);


                            AuthResult result =
                                await _auth.signInWithCredential(credential).catchError((err){
                                  print(err);
                                  EasyLoading.dismiss();
                                  PlatformAlertDialog(
                                    title: 'Внимание',
                                    content: 'Неверный код',
                                    defaultActionText: 'Ok',
                                  ).show(context);
                                });

                            FirebaseUser user = result.user;

                            if (user != null) {
                              EasyLoading.dismiss();
                              setState(() {
                                isLoading = false;

                              });
//
                              await Firestore.instance
                                  .collection('masters')
                                  .document('${user.uid}')
                                  .updateData(
                                {'token': saveToken.read('token')},
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MasterProfile(
                                    status: 'reg',
                                    userType: null,
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                isLoading = false;
                              });
                              Navigator.of(context).pop();
                              PlatformAlertDialog(
                                title: 'Внимание',
                                content: 'Ошибка авторизации.',
                                defaultActionText: 'Ok',
                              ).show(context);
                            }
                          },
                        ),
                        FlatButton(
                          child: Text("Отмена"),
                          textColor: Colors.white,
                          color: Colors.blue,
                          onPressed: () {
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pop(context);
                          }
                        ),
                      ],
                    ),
                  );
                },
              );
              isLoading = false;
            },
            codeAutoRetrievalTimeout: null)
        .catchError((err) {
      print(err);
      isLoading = false;
    });
  }

  Future getMAsterExist(BuildContext context, String phone) async {
    final userExist = await Firestore.instance
        .collection('masters')
        .where('phoneNumber', isEqualTo: phone)
        .getDocuments();

    print(userExist.documents.length);

    if (userExist.documents.length != 0) {
      loginMaster(context, phone);
    } else {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Такой номер не зарегистрирован."),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Авторизация',
        ),
        centerTitle: true,
      ),
      body: SizedBox(height: 360, child: SignIn()),
    );
  }
}
