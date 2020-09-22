import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class MasterAuth extends StatefulWidget {
  @override
  _MasterAuthState createState() => _MasterAuthState();
}

class _MasterAuthState extends State<MasterAuth> {
  String phoneNumberEdit;

  var maskFormatter = new MaskTextInputFormatter(
      mask: '+# (###) ###-##-##', filter: {"#": RegExp(r'[0-9]')});

  final _formKey = GlobalKey<FormState>();

  void trySubmit() {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus();
    if (isValid) {
      _formKey.currentState.save();
//      Navigator.push(
//        context,
//        MaterialPageRoute(
//          builder: (context) => MasterAuth(
//            phoneNumber: phoneNumber,
//          ),
//        ),
//      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Авторизация мастера'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    onSaved: (val) {
                      val = phoneNumberEdit;
                    },
                    validator: (val) {
                      if (val.isEmpty) {
                        return 'Введите ваш номер телефона';
                      }
                      return null;
                    },
                    decoration:
                        InputDecoration(labelText: 'Ваш номер телефона'),
                  ),
                  RaisedButton(
                    onPressed: () {},
                    child: Text('Далее'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
