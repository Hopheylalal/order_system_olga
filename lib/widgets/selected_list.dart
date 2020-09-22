import 'package:flutter/material.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:provider/provider.dart';


class SelectedList extends StatefulWidget {
  final List<String> listFromFB;

  const SelectedList({Key key, this.listFromFB}) : super(key: key);

  @override
  _SelectedListState createState() => _SelectedListState();
}

class _SelectedListState extends State<SelectedList> {
  bool _isChecked = true;
  List<String> _checked = [];

  @override
  void initState() {
    _checked = context.read<DataProvider>().checkedCat;
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

                if(_checked.length != 0){
                  context.read<DataProvider>().catAdd(_checked);
                  Navigator.pop(context, false);
                }else{
                  print('Empty checkedCat list');
                }

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
        labels: widget.listFromFB.where((element) => element != 'все').toList(),
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
