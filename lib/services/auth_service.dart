import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ordersystem/provider/provider.dart';

class Auth {
  final _firebaseAuth = FirebaseAuth.instance;



  Future<String> currentUser() async {
    try {
      final result = await _firebaseAuth.currentUser();
      return result.uid;
    } catch (e) {
      print(e);
      return null;
    }
  }

   Future<String>getCurUsr()async{
    final result = await _firebaseAuth.currentUser();
    final userr = result.uid;
    return userr.toString();

  }

  Future<String> currentUserDisplayName() async {
    try {
      final result = await _firebaseAuth.currentUser();
      return result.displayName;
    } catch (e) {
      print(e);
      return null;
    }
  }

//  Future registerEmailAndPassword({
//    String email,
//    String password,
//    String name,
//    String imgUrl,
//
//  }) async {
//    AuthResult result = await _firebaseAuth.createUserWithEmailAndPassword(
//        email: email, password: password);
//
//    FirebaseUser user = result.user;
//
//    final fbm = FirebaseMessaging();
//    final tok = await fbm.getToken();
//
//
//    //Создаем нового юзера в firebase
//    Firestore.instance.collection('masters').document(user.uid).setData({
//      'token': DataProvider().token,
//      'email' : email,
//      'name' : name,
//      'createDate' : DateTime.now(),
//      'userId' : user.uid,
//      'userType' : 'user',
//      'imgUrl' : imgUrl,
//
//    });
//
//    FirebaseUser userName = await FirebaseAuth.instance.currentUser();
//    userName.reload();
//    UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
//    userUpdateInfo.displayName = name;
//    userUpdateInfo.photoUrl = imgUrl;
//
//    userName.updateProfile(userUpdateInfo);
//
//    return user;
//  }

  Future signInEmailAndPassword(String email, String password) async {
    AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);

    FirebaseUser user = result.user;
    return user;
  }
}
