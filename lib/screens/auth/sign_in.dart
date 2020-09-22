import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ordersystem/common/platform_exaption_alert_dialog.dart';
import 'package:ordersystem/common/size_config.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/auth/register.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;

  SignIn({this.toggleView});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool alreadyPress = false;
  final Auth _auth = Auth();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  String get _email => _emailController.text;

  String get _password => _passwordController.text;

  bool _validateMail = false;
  bool _validatePass = false;
  bool buttonEnabled = true;

  void _emailEditingComplete() {
    final newFocus = _email.isEmpty ? _emailFocusNode : _passwordFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void submitButton() async {
    try {
      await _auth
          .signInEmailAndPassword(
        _email.trim(),
        _password.trim(),
      )
          .then(
        (value) async{
          await Firestore.instance
              .collection('masters')
              .document('${value.uid}')
              .updateData(
            {'token': context.read<DataProvider>().token},
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    } on PlatformException catch (e) {
      PlatformExceptionAlertDialog(
        title: 'Ошибка',
        exception: e,
      ).show(context);
      setState(() {
        buttonEnabled = true;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  checkOnEditingComplete() {
    if (_password.isEmpty) {
      return null;
    } else {
      submitButton();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
//        resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Вход для заказчиков',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      left: SizeConfig.screenWidth / 20,
                      right: SizeConfig.screenWidth / 20,
                      top: SizeConfig.screenHeight / 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      emailTextField(),
                      SizedBox(
                        height: SizeConfig.screenHeight / 50,
                      ),
                      passwordTextField(),
                      SizedBox(
                        height: SizeConfig.screenHeight / 50,
                      ),
                      submitButtonWidget(),
                      SizedBox(height: SizeConfig.blockSizeVertical * 2),
                      toggleReg()
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSignInError(BuildContext context, PlatformException exception) {
    PlatformExceptionAlertDialog(
      title: 'Sign in failed',
      exception: exception,
    ).show(context);
  }

  Row toggleReg() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Нет аккаунта?',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        FlatButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Registration(),
              ),
            );
          },
          child: Text(
            'Регистрация',
            style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.black,
                fontSize: 18),
          ),
        )
      ],
    );
  }

  SizedBox submitButtonWidget() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: RaisedButton(
        onPressed: buttonEnabled
            ? () async {
                setState(
                  () {
                    _email.isEmpty
                        ? _validateMail = true
                        : _validateMail = false;
                    _password.isEmpty
                        ? _validatePass = true
                        : _validatePass = false;
                  },
                );
                if ((_validateMail == false && _validatePass == false)) {
                  setState(() {
                    buttonEnabled = false;
                  });
                  submitButton();
                }
              }
            : null,
        child: buttonEnabled
            ? const Text(
                'Вход',
              )
            : SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator()),
      ),
    );
  }

  TextField passwordTextField() {
    return TextField(
      style: TextStyle(
        color: Colors.black,
      ),
      obscureText: true,
      autocorrect: false,
      cursorColor: Color(0xff000000),
      focusNode: _passwordFocusNode,
      controller: _passwordController,
      textInputAction: TextInputAction.done,
      onEditingComplete: checkOnEditingComplete,
      decoration: InputDecoration(
        labelText: 'Введите пароль',
        errorText: _validatePass ? 'Введите пароль' : null,
      ),
    );
  }

  TextField emailTextField() {
    return TextField(
      style: TextStyle(
        color: Colors.black,
      ),
      cursorColor: Color(0xff000000),
      focusNode: _emailFocusNode,
      onEditingComplete: _emailEditingComplete,
      controller: _emailController,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Введите ваш Email',
        errorText: _validatePass ? 'Введите ваш email' : null,
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
