import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class DataProvider with ChangeNotifier {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String token;

  void getToken(newToken) {
    token = newToken;
    notifyListeners();
  }

  List allOrdersList = [];

  List<String> checkedCat = ['1все'];

  String _userType;

  String get userType => _userType;

  int bageCounter = 0;
  int bageRespondCount = 0;
  LatLng userPositionProvider;

  int newMessage;

  getMessagesFromFireStore(user) async {
    final chatIds = [];
    final chatList = [];

    final msgArrFb = await Firestore.instance
        .collection('messages')
        .where('array', arrayContains: user)
        .getDocuments()
        .then((val) => val.documents);

    msgArrFb.forEach((element) {
      chatIds.add(element.documentID);
    });

    for (int i = 0; i < chatIds.length; i++) {
      var ff = await Firestore.instance
          .collection("messages")
          .document(chatIds[i])
          .collection("chat")
          .getDocuments();
      var fff = ff.documents.where((element) => element.data['$user'] == true);
      chatList.addAll(fff.toList());

      notifyListeners();
    }

    newMessage = chatList.length;
  }

  void getUserPosition(userPos) {
    userPositionProvider = userPos;
  }

  final saveBoxMsg1 = GetStorage();

  void bageMessageCountIncr() async {
    int msg = saveBoxMsg1.read('newMsg1');
    saveBoxMsg1.write('newMsg1', msg == null ? msg = 1 : msg + 1);
    print(saveBoxMsg1.read('newMsg1'));
    notifyListeners();
  }

  void clearMsgCounter() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setInt("bageMessageCount", 0);
    notifyListeners();
  }

  int orderId;

  void getOrderId(putOrderId) {
    orderId = putOrderId;
  }

  void addAllOrdersList(List ordersFilter) {
    allOrdersList.addAll(ordersFilter);
  }

  void addBageToBottomBar(int count) {
    bageCounter = count;
    notifyListeners();
  }

  void catAdd(List<String> cat) {
    if (checkedCat.length == 0) {
      checkedCat.addAll(cat);
    } else {
      checkedCat.clear();
      checkedCat.addAll(cat);
    }
  }

  void clearCatAdd() {
    checkedCat.clear();
  }

  void bageCounerIncr() {
    bageCounter++;
    notifyListeners();
  }

  void bageCounerClear() {
    bageCounter = 0;
    notifyListeners();
  }

  void bageRespondCounerClear() {
    bageRespondCount = 0;
    notifyListeners();
  }

  void getUserType() async {
    final currentUsr = await FirebaseAuth.instance.currentUser();
    final cU = currentUsr.uid;
    final user =
        await Firestore.instance.collection('masters').document(cU).get();
    final userType = user.data['userType'];
    _userType = userType;

    notifyListeners();
  }
}
