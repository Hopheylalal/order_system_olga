import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:load/load.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/master_profile.dart';
import 'package:ordersystem/widgets/add_marker_master.dart';
import 'package:ordersystem/widgets/selected_list.dart';
import 'package:provider/provider.dart';

class AddMasterForm extends StatefulWidget {
  @override
  _AddMasterFormState createState() => _AddMasterFormState();
}

class _AddMasterFormState extends State<AddMasterForm> {
  String name;
  String email;
  String phoneNumber;
  String aboutShort;
  String aboutLong;
  String city;
  String imgUrl;
  bool isLoading = false;
  bool _autoValidate = false;
  bool _inProcess = false;
  File _selectedFile;
  final picker = ImagePicker();
  String userId;
  File croppedImage;
  bool pressLoadButton = false;
  List<Marker> masterPoint;

  final _codeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool catCatalogValidate = false;
  List _categories;

  var maskFormatter = new MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {
      "#": RegExp(r'[0-9]'),
    },
  );

  void trySubmit() {
    if(masterPoint == null){
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Укажите ваше месторасположение."),
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
    }else{
      FocusScope.of(context).unfocus();

      if (_formKey.currentState.validate() &&
          _selectedFile != null &&
          context.read<DataProvider>().checkedCat.length != 0) {
//    If all data are correct then save data to out variables
        _formKey.currentState.save();
        setState(() {
          colorText = Colors.black;
        });
        loginMaster(context, phoneNumber);
      } else {
//    If all data are not valid then start auto validation.
        setState(() {
          catCatalogValidate = true;

          print(_selectedFile);
          if (_selectedFile == null) {
            colorText = Colors.red;
          }

          _autoValidate = true;
        });
      }
    }

  }

  Future loginMaster(
    BuildContext context,
    String phone,
  ) async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    setState(() {
      isLoading = true;
    });

    _auth
        .verifyPhoneNumber(
            phoneNumber: phone,
            timeout: Duration(seconds: 10),
            verificationCompleted: null,
//            (AuthCredential credential) async {
//          AuthResult result = await _auth
//              .signInWithCredential(credential)
//              .catchError((e) async {
//            print(e.toString());
//            PlatformAlertDialog(
//              title: 'Внимание',
//              content: 'Неизвестная ошибка. Попробуйте позже',
//              defaultActionText: 'Ok',
//            ).show(context);
//            setState(() {
//              isLoading = true;
//            });
//          });
//
//          FirebaseUser user = result.user;
//
//          //This callback would gets called when verification is done automatically
//        },

            codeSent: (String verificationId, [int forceResendingToken]) {
              showPlatformDialog(
                context: context,
                builder: (_) => Card(
                  child: BasicDialogAlert(
                    title: Text("Введите SMS код"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(hintText: '-  -  -  -  -  -'),
                          controller: _codeController,
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      BasicDialogAction(
                        title: Text("Отмена"),
                        onPressed: () {
                          setState(() {
                            isLoading = false;
                          });

                          Navigator.pop(context);
                        },
                      ),
                      BasicDialogAction(
                        title: Text("OK"),
                        onPressed: () async {
                          if (_codeController.text.length == 6) {
                            FocusScope.of(context).unfocus();
                            if (isLoading == false) {
                              showLoadingDialog();
                              setState(() {
                                pressLoadButton = true;
                              });
                              print(pressLoadButton);
                              final code = _codeController.text.trim();
                              AuthCredential credential =
                                  PhoneAuthProvider.getCredential(
                                      verificationId: verificationId,
                                      smsCode: code);

                              AuthResult result = await _auth
                                  .signInWithCredential(credential)
                                  .catchError((e) {
                                hideLoadingDialog();
                                PlatformAlertDialog(
                                  title: 'Внимание',
                                  content: 'Ошибка авторизации. Проверьте код',
                                  defaultActionText: 'Ok',
                                ).show(context);
                              });

                              final fbm = FirebaseMessaging();
                              final token = await fbm.getToken();
                              FirebaseUser user = result.user;

                              UserUpdateInfo userUpdateInfo =
                                  new UserUpdateInfo();
                              userUpdateInfo.displayName = name;
                              user.updateProfile(userUpdateInfo);
                              userUpdateInfo.photoUrl = imgUrl;
                              user.reload();

                              if (user != null) {
                                if (result.additionalUserInfo.isNewUser) {
                                  StorageReference reference =
                                      FirebaseStorage.instance.ref().child(
                                          '/images/${DateTime.now().toIso8601String()}');
                                  StorageUploadTask uploadTask =
                                      reference.putFile(_selectedFile);

                                  StorageTaskSnapshot downloadUrl =
                                      (await uploadTask.onComplete);

                                  String url =
                                      (await downloadUrl.ref.getDownloadURL());

                                  Firestore.instance
                                      .collection('masters')
                                      .document(user.uid)
                                      .setData({
                                    'name': name,
                                    'email': email,
                                    'userId': user.uid,
                                    'imgUrl': url,
                                    'phoneNumber': phoneNumber,
                                    'aboutShort': aboutShort,
                                    'aboutLong': aboutLong,
                                    'createDate': Timestamp.now(),
                                    'userType': 'master',
                                    // 'city' : city,
                                    'category': _categories,
                                    'blocked': false,
                                    'token': context.read<DataProvider>().token,
                                    'geoPoint': GeoPoint(
                                        masterPoint.first.position.latitude,
                                        masterPoint.last.position.longitude)
                                  }).whenComplete(() {
                                    Firestore.instance
                                        .collection('markers')
                                        .document(user.uid)
                                        .setData({
                                      'master': user.uid,
                                      'geoPoint': GeoPoint(
                                          masterPoint.first.position.latitude,
                                          masterPoint.last.position.longitude)
                                    });
                                  }).then((_) {
                                    hideLoadingDialog();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MasterProfile(
                                          status: 'reg',
                                          userType: null,
                                        ),
                                      ),
                                    );
                                  }).catchError((err) {
                                    PlatformAlertDialog(
                                      title: 'Внимание',
                                      content: 'Неизвестная ошибка',
                                      defaultActionText: 'Ok',
                                    ).show(context);
                                  });
                                } else {
                                  hideLoadingDialog();
                                  print('OOOOOO');
                                  Navigator.of(context).pop();
                                  PlatformAlertDialog(
                                    title: 'Внимание',
                                    content:
                                        'Такой номер телефона уже зарегистрирован.',
                                    defaultActionText: 'Ok',
                                  ).show(context).then((_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MasterProfile(
                                          status: 'reg',
                                          userType: null,
                                        ),
                                      ),
                                    );
                                  });
//                                  setState(() {
//                                    isLoading = false;
//                                  });
                                }
                              }

                            }
                          } else {
                            PlatformAlertDialog(
                              title: 'Внимание',
                              content: 'Введите код.',
                              defaultActionText: 'Ok',
                            ).show(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );

              setState(() {
                isLoading = false;
              });
            },
            verificationFailed: (AuthException exception) {
              hideLoadingDialog();

              PlatformAlertDialog(
                title: 'Внимание',
                content: 'Неизвестная ошибка. Попробуйте позже',
                defaultActionText: 'Ok',
              ).show(context);
              setState(() {
                isLoading = false;
              });
            },
            codeAutoRetrievalTimeout: null)
        .catchError((err) {
      print(err);
      setState(() {
        isLoading = false;
      });
    });
  }

  final FocusNode _mailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _shortFocusNode = FocusNode();
  final FocusNode _longFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();

  void _nameEditingComplete() {
    final newFocus = _mailFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _mailEditingComplete() {
    final newFocus = _phoneFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }


  void _phoneEditingComplete() {
    final newFocus = _shortFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _longEditingComplete() {
    final newFocus = _longFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _shortFocusNode.dispose();
    _mailFocusNode.dispose();
    super.dispose();
  }

  String validateName(String value) {
    if (value.length < 1)
      return 'Введите ваше имя';
    else
      return null;
  }

  String validatePhone(String value) {
    if (value.length < 1)
      return 'Введите ваш номер телефона';
    else
      return null;
  }

  String validateShort(String value) {
    if (value.length > 1 && value.length > 80)
      return 'Опишите ваши навыки (80 символов)';
    else
      return null;
  }

  String validateCity(String value) {
    if (value.length > 1 && value.length > 80)
      return 'Укажите ваш город';
    else
      return null;
  }

  String validateLong(String value) {
    if (value.length < 1)
      return 'Расскажите о себе';
    else
      return null;
  }

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Введите ваш EMAIL';
    else
      return null;
  }

  Widget getImageWidget(BuildContext context) {
    if (_selectedFile != null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            child: new AlertDialog(
              content: new Text("Выберете фото"),
              actions: [
                FlatButton(
                  onPressed: () {
                    getImageFromDevise(ImageSource.camera);
                    Navigator.pop(context);
                  },
                  child: Text('Камера'),
                ),
                FlatButton(
                  onPressed: () {
                    getImageFromDevise(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                  child: Text('Галерея'),
                )
              ],
            ),
          );
        },
        child: CircleAvatar(
          radius: 65,
          child: ClipOval(
            child: Image.file(
              _selectedFile,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            child: new AlertDialog(
              content: new Text("Выберете фото"),
              actions: [
                FlatButton(
                  onPressed: () {
                    getImageFromDevise(ImageSource.camera);
                    Navigator.pop(context);
                  },
                  child: Text('Камера'),
                ),
                FlatButton(
                  onPressed: () {
                    getImageFromDevise(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                  child: Text('Галерея'),
                )
              ],
            ),
          );
        },
        child: CircleAvatar(
          radius: 50,
          child: Icon(Icons.image),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void getImageFromDevise(ImageSource source) async {
    this.setState(() {
      _inProcess = true;
    });
    final image = await picker.getImage(source: source);
    if (image != null) {
      File cropped = await ImageCropper.cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        maxWidth: 150,
        maxHeight: 150,
        compressFormat: ImageCompressFormat.jpg,
      );

      this.setState(() {
        _selectedFile = cropped;
        _inProcess = false;
        colorText = Colors.black;
      });
    } else {
      this.setState(() {
        _inProcess = false;
      });
    }
  }

  uploadImage(File image) async {
    StorageReference reference = FirebaseStorage.instance
        .ref()
        .child('/images/${DateTime.now().toIso8601String()}');
    StorageUploadTask uploadTask = reference.putFile(image);

    StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

    String url = (await downloadUrl.ref.getDownloadURL());

    setState(() {
      imgUrl = url;
    });
  }

  Color colorText = Colors.black;

  String _myActivitiesResult;

  List<String> _checked = [];

  void setFireStorCatrgory() {
    setState(() {
      _categories = context.read<DataProvider>().checkedCat;
    });
  }




  @override
  void initState() {
    List _categories = [];
    String _myActivitiesResult = '';
    setFireStorCatrgory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 40,
              ),
              onPressed: () {
                context.read<DataProvider>().clearCatAdd();
                Navigator.pop(context);
              }),
          title: Text('Стать мастером'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                FutureBuilder(
                    future: Firestore.instance
                        .collection('category')
                        .document('BY7oiRIc6uq14MwsJ9yV')
                        .get(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData)
                        return Center(
                          child: SizedBox(
                              width: double.infinity,
                              child: LinearProgressIndicator()),
                        );
                      List<dynamic> arrCats = [];
//                      arrCats = snapshot.data['cats'] as List<String>;
                      return Form(
                        key: _formKey,
                        autovalidate: _autoValidate,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            getImageWidget(context),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Загрузите фото',
                                style: TextStyle(color: colorText),
                              ),
                            ),
                            TextFormField(
                              enableSuggestions: true,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: _nameEditingComplete,
                              onSaved: (val) {
                                name = val;
                              },
                              validator: validateName,
                              decoration: InputDecoration(
                                labelText: 'ФИО',
                              ),
                            ),
                            TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              focusNode: _mailFocusNode,
                              onEditingComplete: _mailEditingComplete,
                              onSaved: (val) {
                                email = val;
                              },
                              validator: validateEmail,
                              decoration: InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                            TextFormField(
                              textInputAction: TextInputAction.next,
                              onEditingComplete: _phoneEditingComplete,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [maskFormatter],
                              onSaved: (val) {
                                phoneNumber = val;
                              },
                              validator: validatePhone,
                              decoration: InputDecoration(
                                  labelText: 'Мобильный телефон'),
                            ),
                            TextFormField(
                              enableSuggestions: true,
                              textCapitalization: TextCapitalization.sentences,
                              focusNode: _shortFocusNode,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: _longEditingComplete,
                              onSaved: (val) {
                                aboutShort = val;
                              },
                              validator: validateShort,
                              decoration:
                                  InputDecoration(labelText: 'Коротко о себе'),
                            ),
                            TextFormField(
                              enableSuggestions: true,
                              focusNode: _longFocusNode,
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              minLines: 4,
                              maxLines: 4,
                              onSaved: (val) {
                                aboutLong = val;
                              },
                              validator: validateLong,
                              decoration: InputDecoration(
                                  labelText: 'Подробнее о себе'),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            // TextFormField(
                            //   enableSuggestions: true,
                            //   textCapitalization: TextCapitalization.sentences,
                            //   focusNode: _cityFocusNode,
                            //   textInputAction: TextInputAction.next,
                            //   onSaved: (val) {
                            //     city = val;
                            //   },
                            //   validator: validateCity,
                            //   decoration:
                            //   InputDecoration(labelText: 'Ваш город'),
                            // ),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: FlatButton.icon(
                                color: Colors.blue,
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus.unfocus();
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SelectedList(
                                        listFromFB: snapshot.data['cats']
                                            .cast<String>(),
                                      ),
                                    ),
                                  ).then((value) {
                                    setState(() {
                                      // refresh state of Page1
                                    });
                                  });
                                },
                                icon: Icon(
                                  Icons.category,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Специализация',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            FlatButton.icon(
                              onPressed: () async {
                                masterPoint = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddMarker(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.location_on),
                              label: Text('Ваше местоположение'),
                            ),
//
                            SizedBox(
                              height: 20,
                            ),
                            Wrap(
                              children: context
                                  .watch<DataProvider>()
                                  .checkedCat
                                  .where((element) => element != 'все')
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Chip(
                                        label: Text(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (catCatalogValidate)
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  'Выберите ваши специализации',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 0, top: 10),
                              child: RaisedButton(
                                onPressed: !isLoading ? trySubmit : null,
                                child: !isLoading
                                    ? Text('Далее')
                                    : SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: CircularProgressIndicator(),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                (_inProcess)
                    ? Container(
                        color: Colors.white,
                        height: MediaQuery.of(context).size.height * 0.95,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Center()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
