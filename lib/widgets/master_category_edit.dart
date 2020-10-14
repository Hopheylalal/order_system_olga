import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:provider/provider.dart';

class MasterCategoryEdit extends StatefulWidget {
  final List<String> listFromFB;
  final List<String> masterCat;
  final String masterUid;

  const MasterCategoryEdit(
      {Key key, this.listFromFB, this.masterCat, this.masterUid})
      : super(key: key);

  @override
  _MasterCategoryEditState createState() => _MasterCategoryEditState();
}

class _MasterCategoryEditState extends State<MasterCategoryEdit> {
  bool _isChecked = true;
  List<String> _checked = [];
  List<String> oldCats = [];
  Auth _auth = Auth();

  getCats() async {
    final userId = await _auth.currentUser();
    final cats =
        await Firestore.instance.collection('masters').document(userId).get();
    oldCats = cats.data['category'].cast<String>();
  }

  @override
  void initState() {
    super.initState();
    getCats();
    print(widget.masterUid);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор категории'),
        centerTitle: true,
        leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 40,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                print(_checked);
                print(oldCats);
                Navigator.pop(context);
                Firestore.instance
                    .collection('masters')
                    .document(user.uid)
                    .updateData({
                  'category':
                      _checked == null || _checked.isEmpty ? oldCats : _checked
                });
              })
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
            future: Future.wait([
              Firestore.instance.collection('masters').document(user.uid).get(),
              Firestore.instance
                  .collection('category')
                  .document('BY7oiRIc6uq14MwsJ9yV')
                  .get(),
            ]),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return CheckboxGroup(
                  orientation: GroupedButtonsOrientation.VERTICAL,
                  margin: const EdgeInsets.only(left: 12.0),
                  onSelected: (List selected) => setState(() {
                    _checked = selected;
                    print(_checked);
                  }),
                  labels: snapshot.data[1]['cats']
                      .cast<String>()
                      .where((element) => element != '1все')
                      .toList()..sort((String a, String b) => a.compareTo(b)),
                  checked: _checked.length == 0
                      ? snapshot.data[0]['category'] == null
                          ? _checked
                          : snapshot.data[0]['category'].cast<String>()
                      : _checked,
                  itemBuilder: (Checkbox cb, Text txt, int i) {
                    return Row(
                      children: <Widget>[
                        cb,
                        txt,
                      ],
                    );
                  },
                );
              }
              return Center(
                child: LinearProgressIndicator(),
              );
            }),
      ),
    );
  }
}
