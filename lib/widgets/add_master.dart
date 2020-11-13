import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:load/load.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/common/platform_exaption_alert_dialog.dart';
import 'package:ordersystem/common/size_config.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/master_profile.dart';
import 'package:ordersystem/widgets/add_marker_master.dart';
import 'package:ordersystem/widgets/selected_list.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:basic_utils/basic_utils.dart';

class AddMasterForm extends StatefulWidget {
  @override
  _AddMasterFormState createState() => _AddMasterFormState();
}

class _AddMasterFormState extends State<AddMasterForm> {
  String name;
  String email;
  String pass;
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

  int alreadyPress = 0;

  final saveCatList = GetStorage();

  final _codeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final saveToken = GetStorage();
  final saveStatus = GetStorage();

  bool catCatalogValidate = false;
  List _categories = ['1все'];

  var maskFormatter = new MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {
      "#": RegExp(r'[0-9]'),
    },
  );

  Future getMAsterExist() async {
    final userExist = await Firestore.instance
        .collection('masters')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .getDocuments();

    print(userExist.documents.length);

    if (userExist.documents.length == 0) {
      loginByEmail();
    } else {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Такой номер телефона уже зарегистрирован."),
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

  void trySubmit() {
    setState(() {
      alreadyPress++;
      isLoading = true;
    });
    if (masterPoint == null || context.read<DataProvider>().checkedCat.length < 1 ) {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Внимание"),
          content: Text("Укажите ваше месторасположение и специализацию."),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("OK"),
              onPressed: () {
                setState(() {
                  isLoading = false;
                  alreadyPress--;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {

      FocusScope.of(context).unfocus();

      if (_formKey.currentState.validate() &&
          _selectedFile != null &&
          context.read<DataProvider>().checkedCat.length != 0) {
//    If all data are correct then save data to out variables
        _formKey.currentState.save();
        setState(() {
          isLoading = false;
        });


        getMAsterExist();
      } else {
//    If all data are not valid then start auto validation.
        setState(() {
          alreadyPress--;
          catCatalogValidate = true;
          setState(() {
            isLoading = false;
          });

          print(_selectedFile);
          if (_selectedFile == null) {
            colorText = Colors.red;
          }
          _autoValidate = true;
        });
      }
    }
  }

  void loginByEmail() async {
    FirebaseAuth _auth = FirebaseAuth.instance;

    try{
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: pass.trim(),
      ).whenComplete(() {
        // Navigator.of(context).pop();
      });



    final fbm = FirebaseMessaging();
    final token = await fbm.getToken();

    FirebaseUser user = result.user;

    setState(() {
      isLoading = true;
    });
    UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
    userUpdateInfo.displayName = name;
    user.updateProfile(userUpdateInfo);
    userUpdateInfo.photoUrl = imgUrl;
    user.reload();

    if (user != null) {
      if (result.additionalUserInfo.isNewUser) {
        StorageReference reference = FirebaseStorage.instance
            .ref()
            .child('/images/${DateTime.now().toIso8601String()}');
        StorageUploadTask uploadTask = reference.putFile(_selectedFile);

        StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

        String url = (await downloadUrl.ref.getDownloadURL());

        Firestore.instance.collection('masters').document(user.uid).setData({
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
          'category': context.read<DataProvider>().checkedCat,
          'blocked': false,
          'token': token,
          'lastSeen' : Timestamp.now(),
          'geoPoint': GeoPoint(masterPoint.first.position.latitude,
              masterPoint.last.position.longitude)
        }).whenComplete(() {
          Firestore.instance.collection('markers').document(user.uid).setData({
            'master': user.uid,
            'geoPoint': GeoPoint(masterPoint.first.position.latitude,
                masterPoint.last.position.longitude)
          });
          //     .whenComplete(() {
          //   Firestore.instance.collection('rating').document().setData({
          //     'masterId': user.uid,
          //     // 'ownerId': '',
          //     'rating' : 0.0,
          //   });
          // });
          saveStatus.write('userType', 'master');
        }).then((_) {
          EasyLoading.dismiss();

          Navigator.of(context).pop();
        }).catchError((err) {
          print(err);
          PlatformAlertDialog(
            title: 'Внимание',
            content: 'Неизвестная ошибка',
            defaultActionText: 'Ok',
          ).show(context);
        });
      }
    }}on PlatformException catch (e) {
      PlatformExceptionAlertDialog(
        title: 'Ошибка',
        exception: e,
      ).show(context);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Future loginMaster(
  //   BuildContext context,
  //   String phone,
  // ) async {
  //   FirebaseAuth _auth = FirebaseAuth.instance;
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   _auth
  //       .verifyPhoneNumber(
  //           phoneNumber: phone,
  //           timeout: Duration(seconds: 60),
  //           verificationCompleted: null,
  //           codeSent: (String verificationId, [int forceResendingToken]) {
  //             showPlatformDialog(
  //               context: context,
  //               builder: (_) => Card(
  //                 child: FlutterEasyLoading(
  //                   child: BasicDialogAlert(
  //                     title: Text("Введите SMS код"),
  //                     content: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: <Widget>[
  //                         TextFormField(
  //                           textAlign: TextAlign.center,
  //                           maxLength: 6,
  //                           keyboardType: TextInputType.number,
  //                           decoration:
  //                               InputDecoration(hintText: '-  -  -  -  -  -'),
  //                           controller: _codeController,
  //                         ),
  //                       ],
  //                     ),
  //                     actions: <Widget>[
  //                       BasicDialogAction(
  //                         title: Text("Отмена"),
  //                         onPressed: () {
  //                           setState(() {
  //                             isLoading = false;
  //                           });
  //
  //                           Navigator.pop(context);
  //                         },
  //                       ),
  //                       BasicDialogAction(
  //                         title: Text("OK"),
  //                         onPressed: () async {
  //                           if (_codeController.text.length == 6) {
  //                             FocusScope.of(context).unfocus();
  //                             if (isLoading == false) {
  //                               EasyLoading.show(
  //                                 status: 'Загрузка...',
  //                               );
  //
  //                               setState(() {
  //                                 pressLoadButton = true;
  //                               });
  //                               final code = _codeController.text.trim();
  //                               AuthCredential credential =
  //                                   PhoneAuthProvider.getCredential(
  //                                       verificationId: verificationId,
  //                                       smsCode: code);
  //
  //                               AuthResult result = await _auth
  //                                   .signInWithCredential(credential)
  //                                   .catchError((e) {
  //                                     print(e);
  //                                 EasyLoading.dismiss();
  //                                 PlatformAlertDialog(
  //                                   title: 'Внимание',
  //                                   content:
  //                                       'Ошибка авторизации. Проверьте код',
  //                                   defaultActionText: 'Ok',
  //                                 ).show(context);
  //                               });
  //
  //                               final fbm = FirebaseMessaging();
  //                               final token = await fbm.getToken();
  //                               FirebaseUser user = result.user;
  //
  //                               UserUpdateInfo userUpdateInfo =
  //                                   new UserUpdateInfo();
  //                               userUpdateInfo.displayName = name;
  //                               user.updateProfile(userUpdateInfo);
  //                               userUpdateInfo.photoUrl = imgUrl;
  //                               user.reload();
  //
  //                               if (user != null) {
  //                                 if (result.additionalUserInfo.isNewUser) {
  //                                   StorageReference reference =
  //                                       FirebaseStorage.instance.ref().child(
  //                                           '/images/${DateTime.now().toIso8601String()}');
  //                                   StorageUploadTask uploadTask =
  //                                       reference.putFile(_selectedFile);
  //
  //                                   StorageTaskSnapshot downloadUrl =
  //                                       (await uploadTask.onComplete);
  //
  //                                   String url = (await downloadUrl.ref
  //                                       .getDownloadURL());
  //
  //                                   Firestore.instance
  //                                       .collection('masters')
  //                                       .document(user.uid)
  //                                       .setData({
  //                                     'name': name,
  //                                     'email': email,
  //                                     'userId': user.uid,
  //                                     'imgUrl': url,
  //                                     'phoneNumber': phoneNumber,
  //                                     'aboutShort': aboutShort,
  //                                     'aboutLong': aboutLong,
  //                                     'createDate': Timestamp.now(),
  //                                     'userType': 'master',
  //                                     // 'city' : city,
  //                                     'category': context
  //                                         .read<DataProvider>()
  //                                         .checkedCat,
  //                                     'blocked': false,
  //                                     'token': token,
  //                                     'geoPoint': GeoPoint(
  //                                         masterPoint.first.position.latitude,
  //                                         masterPoint.last.position.longitude)
  //                                   }).whenComplete(() {
  //                                     Firestore.instance
  //                                         .collection('markers')
  //                                         .document(user.uid)
  //                                         .setData({
  //                                       'master': user.uid,
  //                                       'geoPoint': GeoPoint(
  //                                           masterPoint.first.position.latitude,
  //                                           masterPoint.last.position.longitude)
  //                                     });
  //                                   }).then((_) {
  //                                     EasyLoading.dismiss();
  //
  //                                     Navigator.push(
  //                                       context,
  //                                       MaterialPageRoute(
  //                                         builder: (context) => MasterProfile(
  //                                           status: 'reg',
  //                                           userType: null,
  //                                         ),
  //                                       ),
  //                                     );
  //                                   }).catchError((err) {
  //                                     print(err);
  //                                     PlatformAlertDialog(
  //                                       title: 'Внимание',
  //                                       content: 'Неизвестная ошибка',
  //                                       defaultActionText: 'Ok',
  //                                     ).show(context);
  //                                   });
  //                                 } else {
  //                                   EasyLoading.dismiss();
  //                                   print('OOOOOO');
  //                                   Navigator.of(context).pop();
  //                                   PlatformAlertDialog(
  //                                     title: 'Внимание',
  //                                     content:
  //                                         'Такой номер телефона уже зарегистрирован.',
  //                                     defaultActionText: 'Ok',
  //                                   ).show(context);
  //                                 }
  //                               }
  //                             }
  //                           } else {
  //                             PlatformAlertDialog(
  //                               title: 'Внимание',
  //                               content: 'Введите код.',
  //                               defaultActionText: 'Ok',
  //                             ).show(context);
  //                           }
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //
  //             setState(() {
  //               isLoading = false;
  //             });
  //           },
  //           verificationFailed: (AuthException exception) {
  //             EasyLoading.dismiss();
  //             print(exception.message);
  //
  //             PlatformAlertDialog(
  //               title: 'Внимание',
  //               content: 'Неизвестная ошибка. Попробуйте позже',
  //               defaultActionText: 'Ok',
  //             ).show(context);
  //             setState(() {
  //               isLoading = false;
  //             });
  //           },
  //           codeAutoRetrievalTimeout: null)
  //       .catchError((err) {
  //     print(err);
  //     setState(() {
  //       isLoading = false;
  //     });
  //   });
  // }
  //

  final FocusNode _mailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _shortFocusNode = FocusNode();
  final FocusNode _longFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();

  void _nameEditingComplete() {
    final newFocus = _mailFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _mailEditingComplete() {
    final newFocus = _passFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }
  void _passEditingComplete() {
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
    _passFocusNode.dispose();
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
  String validatePass(String value) {
    if (value.length < 6)
      return 'Пароль должен содержать не менее 6ти символов';
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
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Редактор',
            toolbarWidgetColor: Colors.blue,
            hideBottomControls: true),
        iosUiSettings: IOSUiSettings(
          title: 'Редактор',
        ),
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
    SizeConfig().init(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              focusNode: _passFocusNode,
                              onEditingComplete: _passEditingComplete,
                              onSaved: (val) {
                                pass = val;
                              },
                              validator: validatePass,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
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
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                enableSuggestions: true,
                                focusNode: _longFocusNode,
                                textCapitalization:
                                    TextCapitalization.sentences,
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
                            ),
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
                                      builder: (context) =>
                                          SelectedListAddNewMaster(
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
                                  .where((element) => element != '1все')
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Chip(
                                        label: Text(StringUtils.capitalize(e)),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 0, top: 10),
                              child: RaisedButton(
                                onPressed: (){
                                  if(alreadyPress > 0){

                                  }else{
                                    if(isLoading == false){
                                      trySubmit();
                                    }else{
                                      return null;
                                    }
                                  }

                                },
                                child: isLoading == false
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

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
