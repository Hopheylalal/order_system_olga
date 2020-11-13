import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:ordersystem/widgets/add_master.dart';
import 'package:ordersystem/widgets/auth_master_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'all_chat_screen.dart';
import 'master_profile.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('stringValue');
    return stringValue;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Ваш профиль'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),

            if (user == null)
              ListTile(
                title: Text(
                  'Стать мастером',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  'Заполните информацию о себе, что бы появится в разделе "МАСТЕРА".',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddMasterForm()));
                },
              ),
            if (user == null)
              Divider(
                color: Colors.black,
              ),
            if (user != null)
              ListTile(
                title: Text(
                  'Вы авторизованы',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  'Нажмите, чтобы перейти в профиль".',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MasterProfile(
                        status: '',
                        userType: user.email,
                      ),
                    ),
                  );
                },
              ),
            if (user == null)
              ListTile(
                title: Text(
                  'Авторизация',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  'Чтобы не потерять свои объявления, а также авторизоваться на другом устройстве.',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthMAster(),
                    ),
                  );
                },
              ),
            Divider(
              color: Colors.black,
            ),
//            ListTile(
//              onTap: () {
//                if (user != null) {
//                  Navigator.push(
//                    context,
//                    MaterialPageRoute(
//                      builder: (context) => AllChatScreen(currentUserUid: user.uid,),
//                    ),
//                  );
//                }else{
//                  showPlatformDialog(
//                    context: context,
//                    builder: (_) => BasicDialogAlert(
//                      title: Text("Внимание"),
//                      content: Text("Авторизуйтесь чтобы продолжить"),
//                      actions: <Widget>[
//                        BasicDialogAction(
//                          title: Text("OK"),
//                          onPressed: () {
//                            Navigator.pop(context);
//                          },
//                        ),
//                      ],
//                    ),
//                  );
//                }
//              },
//              title: Text(
//                'Персональные уведомления',
//                style: TextStyle(fontSize: 18),
//              ),
//              subtitle: Text(
//                'История предложений и диалогов.',
//                style: TextStyle(fontSize: 14),
//              ),
//            ),
//            Divider(
//              color: Colors.black,
//            ),
          ],
        ),
      ),
    );
  }
}
