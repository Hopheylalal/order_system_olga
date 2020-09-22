import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:ordersystem/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OrderFilter extends StatefulWidget {
  final List<String> listFromFB;

  const OrderFilter({Key key, this.listFromFB}) : super(key: key);

  @override
  _OrderFilterState createState() => _OrderFilterState();
}

class _OrderFilterState extends State<OrderFilter> {
  bool _isChecked = true;
  List<String> _checked = [];

  saveOrderFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('orderFilterValue', _checked);
  }

  loadOrderFilter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _checked = prefs.getStringList('orderFilterValue');
    });
  }

  removeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Remove String
    prefs.remove("orderFilterValue");
  }

  @override
  void initState() {
    loadOrderFilter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор категории'),
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
                saveOrderFilter();
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (BuildContext context) => Home()),
                        (Route<dynamic> route) => route is Home
                );

              })
        ],
      ),
      body: CheckboxGroup(
        orientation: GroupedButtonsOrientation.VERTICAL,
        margin: const EdgeInsets.only(left: 12.0),
        onSelected: (List selected) => setState(() {
          _checked = selected;
          print(_checked);
        }),
        labels: widget.listFromFB,
        checked: _checked,
        itemBuilder: (Checkbox cb, Text txt, int i) {
          return Row(
            children: <Widget>[
              cb,
              txt,
            ],
          );
        },
      ),
    );
  }
}
