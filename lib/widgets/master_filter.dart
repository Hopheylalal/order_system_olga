import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:ordersystem/screens/home.dart';
import 'package:ordersystem/screens/masters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_master.dart';

class MasterFilter extends StatefulWidget {
  final List<String> listFromFB;

  const MasterFilter({Key key, this.listFromFB}) : super(key: key);

  @override
  _MasterFilterState createState() => _MasterFilterState();
}

class _MasterFilterState extends State<MasterFilter> {
  bool _isChecked = true;
  List<String> _checked = [];

  saveMasterFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('masterFilterValue', _checked);
  }

  loadMasterFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _checked = prefs.getStringList('masterFilterValue');
    });
  }

  removeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Remove String
    prefs.remove("masterFilterValue");
  }

  @override
  void initState() {
    loadMasterFilter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор категории2'),
        centerTitle: true,
        leading: IconButton(
            icon: Icon(Icons.chevron_left, size: 40,),
            onPressed: () {

              Navigator.pop(context);
            }),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                removeValues();
                saveMasterFilter();
//                Navigator.pop(context,true);
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (BuildContext context) => Home(fromWhere: '1',)),
                        (Route<dynamic> route) => route is Home
                );
              })
        ],
      ),
      body: FutureBuilder(
        future: Firestore.instance.collection('category').document('BY7oiRIc6uq14MwsJ9yV').get(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return CircularProgressIndicator();
          }
          if(snapshot.hasData){
            return CheckboxGroup(
              orientation: GroupedButtonsOrientation.VERTICAL,
              margin: const EdgeInsets.only(left: 12.0),
              onSelected: (List selected) => setState(() {
                _checked = selected;
                print(widget.listFromFB);
              }),
              labels: snapshot.data['cats'],
              checked: _checked,
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
          return Container();
        }

      ),

//      ListView(
//        padding: EdgeInsets.all(8.0),
//        children: widget.catMastersWidget
//            .map(
//              (text) => CheckboxListTile(
//                title: Text(text),
//                value: _isChecked,
//                onChanged: (val) {
//                  setState(() {
//                    _isChecked = val;
//                  });
//                },
//              ),
//            )
//            .toList(),
//      ),
    );
  }
}
