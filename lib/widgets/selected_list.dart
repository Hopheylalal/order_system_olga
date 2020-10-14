import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:grouped_buttons/grouped_buttons.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

class SelectedListAddNewMaster extends StatefulWidget {
  final List<String> listFromFB;

  const SelectedListAddNewMaster({Key key, this.listFromFB}) : super(key: key);

  @override
  _SelectedListAddNewMasterState createState() =>
      _SelectedListAddNewMasterState();
}

class _SelectedListAddNewMasterState extends State<SelectedListAddNewMaster> {
  bool _isChecked = true;
  List<String> _checked = ['1все'];

  @override
  void initState() {
    // _checked = context
    //     .read<DataProvider>()
    //     .checkedCat;
    super.initState();
  }

  String searchTextField;
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  Widget row(item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                item.toString(),
              ),
              Divider(),
              SizedBox(
                width: 10.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> added = [];
  String currentText = "";

  addCategoryToFirebase() async {
    try {
      added.add(searchTextField);

      await Firestore.instance
          .collection('category')
          .document('BY7oiRIc6uq14MwsJ9yV')
          .updateData(
        {
          'cats': FieldValue.arrayUnion(added),
        },
      );
      setState(() {
        _checked.add(searchTextField);
      });
    } catch (e) {
      print(e);
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Проверьте подключение к сети"),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("Ок"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  List<String> mainList = [];
  List<String> mainList2 = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Специальности'),
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
              onPressed: () {
                if (_checked.length != 0) {
                  context.read<DataProvider>().catAdd(_checked);
                  Navigator.pop(context, false);
                } else {
                  print('Empty checkedCat list');
                }
              })
        ],
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
            stream: Firestore.instance
                .collection('category')
                .document('BY7oiRIc6uq14MwsJ9yV')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                mainList = snapshot.data['cats']
                    .cast<String>()
                    .where((element) => element != '1все')
                    .toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 5, right: 5, top: 5, bottom: 0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(Icons.info),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                'Выберете специальность или добавьте свою.',style: TextStyle(fontSize: 12),),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        child: RaisedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) => Wrap(children: [
                                Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Align(
                                            child: Text(
                                              'Добавьте свою специализацию',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            alignment: Alignment.topCenter,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: AutoCompleteTextField(
                                            key: key,
                                            textChanged: (text) {
                                              setState(() {
                                                searchTextField = text;
                                              });
                                            },
                                            clearOnSubmit: false,
                                            textSubmitted: (text) =>
                                                setState(() {
                                              searchTextField = text;
                                            }),
                                            suggestions: widget.listFromFB
                                                .where((element) =>
                                                    element != '1все')
                                                .toList(),
                                            itemBuilder: (context, item) {
                                              return row(item);
                                            },
                                            itemSorter: (a, b) {
                                              return a
                                                  .toString()
                                                  .compareTo(b.toString());
                                            },
                                            itemFilter: (item, quary) {
                                              return item
                                                  .toString()
                                                  .toLowerCase()
                                                  .startsWith(quary
                                                      .toString()
                                                      .toLowerCase());
                                            },
                                            itemSubmitted: (item) {

                                              searchTextField = item;
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RaisedButton(
                                            onPressed: () {
                                              print(searchTextField);
                                              if (searchTextField.isNotEmpty) {
                                                addCategoryToFirebase();
                                                Navigator.pop(context);
                                              } else {
                                                showPlatformDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      BasicDialogAlert(
                                                    title: Text("Внимание"),
                                                    content: Text(
                                                        "Введите название специальности"),
                                                    actions: <Widget>[
                                                      BasicDialogAction(
                                                        title: Text("Ок"),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text('Добавить'),
                                          ),
                                        )
                                      ],
                                    )),
                              ]),
                            );
                          },
                          child: Text('Добавить свою специальность'),
                        ),
                        width: double.infinity,
                      ),
                    ),
                    CheckboxGroup(
                      orientation: GroupedButtonsOrientation.VERTICAL,
                      margin: const EdgeInsets.only(left: 12.0),
                      onSelected: (List selected) => setState(() {
                        _checked = selected;
                        print(_checked);
                      }),
                      labels: mainList
                        ..sort(
                          (String a, String b) => a.compareTo(b),
                        ),
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
                  ],
                );
              }
              return CircularProgressIndicator();
            }),
      ),
    );
  }
}
