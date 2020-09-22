import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:provider/provider.dart';

class MasterCategoryEdit extends StatefulWidget {
  final List<String> listFromFB;
  final List<String> masterCat;

  const MasterCategoryEdit({Key key, this.listFromFB, this.masterCat})
      : super(key: key);

  @override
  _MasterCategoryEditState createState() => _MasterCategoryEditState();
}

class _MasterCategoryEditState extends State<MasterCategoryEdit> {
  bool _isChecked = true;
  List<String> _checked = [];

  @override
  void initState() {
    super.initState();
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
                Navigator.pop(context);
                Firestore.instance
                    .collection('masters')
                    .document(user.uid)
                    .updateData({'category': _checked});
              })
        ],
      ),
      body: FutureBuilder(
          future: Future.wait([Firestore.instance.collection('masters').document(user.uid).get(), Firestore.instance.collection('category').document('BY7oiRIc6uq14MwsJ9yV').get(),]),

          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return CheckboxGroup(
                orientation: GroupedButtonsOrientation.VERTICAL,
                margin: const EdgeInsets.only(left: 12.0),
                onSelected: (List selected) => setState(() {
                  _checked = selected;
                  print(_checked);
                }),
                labels: snapshot.data[1]['cats'].cast<String>(),
                checked: _checked.length == 0 ? snapshot.data[0]['category'] == null ? _checked :  snapshot.data[0]['category'].cast<String>() : _checked,
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
              child: CircularProgressIndicator(),
            );
          }),
    );
  }
}
