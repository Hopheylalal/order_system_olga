import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/screens/home.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final blockedStatus = context.watch<bool>();
    return blockedStatus == false || blockedStatus == null ? Home() : Blocked();
  }
}

