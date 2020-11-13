import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ordersystem/screens/auth/sign_in.dart';

import 'edit_master_profile.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String uid;
  String userType;

  Future getCurrentUser() async {
    FirebaseUser _user = await _firebaseAuth.currentUser();
    uid = _user.uid;
  }

  getUserType() async {
    final result =
        await Firestore.instance.collection('masters').document(uid).get();
    userType = result.data['userType'];
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser().whenComplete(
      () => getUserType(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
            stream: _firebaseAuth.onAuthStateChanged,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox();
              }
              if (snapshot.hasData && snapshot.data != null) {
                return Text(
                  'Ваш профиль',
                );
              }
              return Text(
                'Авторизация',
              );
            }),
        centerTitle: true,
        actions: [
          StreamBuilder(
              stream: _firebaseAuth.onAuthStateChanged,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox();
                }
                if (snapshot.hasData && snapshot.data != null) {
                  return Row(
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditMasterProfile(userType: userType,),
                              ),
                            );
                          }),
                      IconButton(
                          icon: Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            FirebaseAuth.instance.signOut();

                            // Navigator.of(context).popUntil((route) => route.isFirst);
                          }),
                    ],
                  );
                }
                return SizedBox();
              })
        ],
      ),
      body: Column(
        children: [
          Expanded(child: SignIn()),
        ],
      ),
    );
  }
}
