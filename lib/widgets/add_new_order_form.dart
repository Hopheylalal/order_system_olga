import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get_storage/get_storage.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/screens/blocked_screen.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';

class AddNewOrderForm extends StatefulWidget {
  final toMaster;
  final masterName;
  final masterCategoryFrpmFb;

  const AddNewOrderForm(
      {Key key, this.toMaster, this.masterName, this.masterCategoryFrpmFb})
      : super(key: key);

  @override
  _AddNewOrderFormState createState() => _AddNewOrderFormState();
}

class _AddNewOrderFormState extends State<AddNewOrderForm> {
  String category;
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String aboutShort;
  String aboutLong;
  DateTime dateTime;
  bool _autoValidate = false;
  String curUsr;
  String name;
  bool buttonEnabled = true;
  bool blockedStatus = false;

  int orderId;

  final userType = GetStorage();

  List<String> uploadUrls = [];

  File _image;
  List<File> _imageList = [];
  List<Asset> _imageListAsset = [];
  List<String> _imageUrlList = [];
  String imageUrl;

  Future saveImage(Asset asset) async {
    ByteData byteData =
        await asset.getByteData(); // requestOriginal is being deprecated
    List<int> imageData = byteData.buffer.asUint8List();
    Random random = new Random();
    int randomNumber = random.nextInt(100000);

    StorageReference ref = FirebaseStorage().ref().child(
        '$orderId/${Path.basename("$randomNumber.jpg")}'); // To be aligned with the latest firebase API(4.0)
    StorageUploadTask uploadTask =
        ref.putData(imageData, StorageMetadata(contentType: 'image/jpeg'));

    await uploadTask.onComplete.whenComplete(() {
      ref.getDownloadURL().then((fileUrl) {
        print('!!!$fileUrl');
        _imageUrlList.add(fileUrl.toString());
      });
    });
  }

  List<Asset> images = List<Asset>();
  String _error = 'No Error Dectected';

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          startInAllView: true,
          allViewTitle: 'All photos',
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    if (!mounted) return;

    for (Asset i in resultList) {
      saveImage(i).whenComplete(() => print(_imageUrlList.length));
    }
    print(_imageList);
    setState(() {
      images = resultList;
      _error = error;
    });
  }

  Future getImageFromGallery() async {
    if (Platform.isIOS) {
      final picker = ImagePicker();
      final pickedFile =
          await picker.getImage(imageQuality: 80, source: ImageSource.gallery);

      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
          _imageList.add(_image);
          _image = null;
        } else {
          print('No image selected.');
        }
      });
    } else {
      try {
        var image = await ImagePicker.pickImage(
                imageQuality: 80, source: ImageSource.gallery)
            .catchError((err) => print(err));
        setState(() {
          _image = image;
          _imageList.add(_image);
        });
      } catch (e) {
        print(e);
      }
    }
  }

  Widget buildGridView() {
    return SizedBox(
      height: 100,
      width: 200,
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(images.length, (index) {
          Asset asset = images[index];
          return AssetThumb(
            asset: asset,
            width: 200,
            height: 200,
          );
        }),
      ),
    );
  }

  _uploadImages(context, user) async {
    if (userType.read('userType') != 'master') {
      // try {
      buttonEnabled = false;
      List<String> imgUrl2 = [];
      _imageList.forEach((f) async {
        final StorageReference _ref = FirebaseStorage.instance
            .ref()
            .child('$orderId/${Path.basename(f.path)}}');
        final StorageUploadTask uploadTask = _ref.putFile(f);
        await uploadTask.onComplete.whenComplete(() {
          _ref.getDownloadURL().then((fileUrl) {
            imgUrl2.add(fileUrl.toString());
            return imgUrl2;
          }).then((value) {
            _imageUrlList = value;
          }).whenComplete(() => addNewMission(context, user));
        });
      });
    } else {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Чтобы добавить задание авторизуйтесь, как заказчик"),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  // Future uploadFile() async {
  //   StorageReference storageReference = FirebaseStorage.instance
  //       .ref()
  //       .child('images/${Path.basename(_image.path)}}');
  //   StorageUploadTask uploadTask = storageReference.putFile(_image);
  //   await uploadTask.onComplete;
  //   print('File Uploaded');
  //   ç
  //   });
  // }

  List<Widget> builtImageDisplay() {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: _imageList.length == 0
                ? new Text('Фото не загружены')
                : GridView.count(
                    shrinkWrap: true,
                    primary: false,
                    crossAxisCount: 4,
                    mainAxisSpacing: 5.0,
                    crossAxisSpacing: 5.0,
                    children: _imageList.map((File file) {
                      return GestureDetector(
                        onTap: () {},
                        child: new GridTile(
                          child: new Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      )
    ];
  }

  final FocusNode _shortFocusNode = FocusNode();
  final FocusNode _longFocusNode = FocusNode();

  String _chosenValue;

  String validateLong(String value) {
    if (value.length < 1)
      return 'Введите заголовок';
    else
      return null;
  }

  String validateShort(String value) {
    if (value.length < 1)
      return 'Введите описание задания';
    else
      return null;
  }

  void _shortEditingComplete() {
    final newFocus = _longFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  addNewMission(BuildContext context, user) async {
    setState(() {
      buttonEnabled = false;
    });
    try {
      await Firestore.instance
          .collection('orders')
          .document('$orderId')
          .setData({
        'owner': curUsr,
        'createDate': DateTime.now(),
        'name': name,
        'title': aboutShort,
        'description': aboutLong,
        'orderId': orderId,
        'category': widget.masterCategoryFrpmFb,
        'toMaster': widget.toMaster,
        'masterName': widget.masterName,
        'newOne': true,
        'startDate': dateTime == null ? "null" : Timestamp.fromDate(dateTime),
        'imgUrl': _imageUrlList,
      }).then((_) {
        _scaffoldKey.currentState.showSnackBar(
          new SnackBar(
            backgroundColor: Colors.green,
            content: new Text('Задание добавлено.'),
          ),
        );
      }).then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          buttonEnabled = true;
          Navigator.pop(context);
        });
      });
    } catch (e) {
      print(e);
      PlatformAlertDialog(
        title: 'Внимание',
        content: 'Повоторите попытку позже.',
        defaultActionText: 'Ok',
      ).show(context);
    }
  }

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    print(ggg);
    final userInfo =
        await Firestore.instance.collection('masters').document(ggg).get();
    final nameDb = userInfo.data['name'];

    setState(() {
      curUsr = ggg;
      name = nameDb;
    });
  }

  getBlockedStatus() async {
    var ggg = await Auth().currentUser();
    var blocked =
        await Firestore.instance.collection('masters').document(ggg).get();
    var blockedStatusFuture = blocked.data['blocked'];
    print(blockedStatusFuture);
    setState(() {
      blockedStatus = blockedStatusFuture;
    });
  }

  getOrderId() {
    int date = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      orderId = date;
    });
  }

  @override
  void initState() {
    super.initState();
    getOrderId();
    category = '';
    getCurrentUser();
    getBlockedStatus();
  }

  @override
  void dispose() {
    _shortFocusNode.dispose();
    _longFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Новое задание'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidate: _autoValidate,
          child: FutureBuilder(
            future: Firestore.instance
                .collection('category')
                .document('BY7oiRIc6uq14MwsJ9yV')
                .get(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData)
                return Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: LinearProgressIndicator(),
                  ),
                );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.sentences,
                      onEditingComplete: _shortEditingComplete,
                      validator: validateShort,
                      initialValue: snapshot.data['aboutShort'],
                      keyboardType: TextInputType.text,
                      minLines: 2,
                      maxLines: 2,
                      onSaved: (val) {
                        aboutShort = val;
                      },
                      decoration: InputDecoration(
                          labelText: 'Короткое название задания'),
                    ),
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      focusNode: _longFocusNode,
                      enableSuggestions: true,
                      initialValue: snapshot.data['aboutLong'],
                      keyboardType: TextInputType.multiline,
                      validator: validateLong,
                      minLines: 4,
                      maxLines: 4,
                      onSaved: (val) {
                        aboutLong = val;
                      },
                      decoration:
                          InputDecoration(labelText: 'Описание задания'),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Когда нужно начать?',
                          style: TextStyle(fontSize: 16),
                        )),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Text(
                          dateTime == null
                              ? 'Дата не выбрана'
                              : DateFormat('yyyy-MM-dd').format(dateTime),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () {
                              showDatePicker(
                                context: context,
                                initialDate: dateTime == null
                                    ? DateTime.now()
                                    : dateTime,
                                firstDate: DateTime(2001),
                                lastDate: DateTime(2100),
                              ).then((date) {
                                setState(() {
                                  dateTime = date;
                                });
                              });
                            })
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Platform.isIOS
                        ? buildGridView()
                        : Wrap(
                            children: builtImageDisplay(),
                          ),
                    SizedBox(
                      height: 20,
                    ),
                    RaisedButton(
                        child: Text('Загрузить фото'),
                        onPressed: () {
                          Platform.isIOS ? loadAssets() : getImageFromGallery();
                        }),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ButtonTheme(
                        minWidth: double.maxFinite,
                        height: 45.0,
                        child: RaisedButton(
                          onPressed: () {
                            if (blockedStatus == false ||
                                blockedStatus == null) {
                              _autoValidate = true;
                              if (_formKey.currentState.validate()) {
                                _formKey.currentState.save();
                                FocusScope.of(context).unfocus();
                                Platform.isIOS
                                    ? addNewMission(context, user)
                                    : _uploadImages(context, user);
                              }
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Blocked()));
                            }
                          },
                          child: buttonEnabled
                              ? Center(
                                  child: const Text(
                                    'Добавить',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
