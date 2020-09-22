import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ordersystem/common/platform_exaption_alert_dialog.dart';
import 'package:ordersystem/common/size_config.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/screens/auth/sign_in.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Registration extends StatefulWidget {
  final Function toggleView;

  Registration({this.toggleView});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _firebaseAuth = FirebaseAuth.instance;

  Future registerEmailAndPassword({
    String email,
    String password,
    String name,
    String imgUrl,
  }) async {
    AuthResult result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    FirebaseUser user = result.user;

    //Создаем нового юзера в firebase
    Firestore.instance.collection('masters').document(user.uid).setData({
      'token': context.read<DataProvider>().token,
      'email': email,
      'name': name,
      'createDate': Timestamp.now(),
      'userId': user.uid,
      'userType': 'user',
      'imgUrl': imgUrl,
      'fromWeb': false,
      'blocked': false,
    });

    FirebaseUser userName = await FirebaseAuth.instance.currentUser();
    userName.reload();
    UserUpdateInfo userUpdateInfo = new UserUpdateInfo();
    userUpdateInfo.displayName = name;
    userUpdateInfo.photoUrl = imgUrl;

    userName.updateProfile(userUpdateInfo);

    return user;
  }

  bool alreadyPress = false;
  final Auth _auth = Auth();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  String get _email => _emailController.text;

  String get _password => _passwordController.text;

  String get _name => _nameController.text;

  bool _validateMail = false;
  bool _validatePass = false;
  bool _validateName = false;

  bool buttonEnabled = true;

  String imgUrl;
  String tokenn;
  String emptyUrl =
      'https://firebasestorage.googleapis.com/v0/b/orderfinder-5e185.appspot.com/o/account.png?alt=media&token=cfc78a03-0404-4194-b7e3-60b77c374ffe';

  addUIDSF(user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('stringValue', user);
  }

  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('stringValue');
    return stringValue;
  }

  void submitButton() async {
    if (_selectedFile != null) {
      try {
        await uploadImage(_selectedFile);
        await registerEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
          name: _name.trim(),
          imgUrl: imgUrl ?? emptyUrl,
        ).then((value) {

          // addUIDSF(value.currentUser());
          print('!!!$tokenn');

          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } on PlatformException catch (e) {
        PlatformExceptionAlertDialog(
          title: 'Ошибка',
          exception: e,
        ).show(context);
        setState(() {
          buttonEnabled = true;
        });
      } catch (e) {
        print(e.toString());
      }
    } else {
      try {
        await registerEmailAndPassword(
          email: _email.trim(),
          password: _password.trim(),
          name: _name.trim(),
          imgUrl: imgUrl ?? emptyUrl,
        ).then((value) {
          // addUIDSF(value.currentUser());
        }).then(

              (_) => Navigator.popUntil(context, (route) => route.isFirst),
            );
      } on PlatformException catch (e) {
        PlatformExceptionAlertDialog(
          title: 'Ошибка',
          exception: e,
        ).show(context);
        setState(() {
          buttonEnabled = true;
        });
      } catch (e) {
        print(e.toString());
      }
    }
  }

  void _emailEditingComplete() {
    final newFocus = _email.isEmpty ? _emailFocusNode : _passwordFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _nameEditingComplete() {
    final newFocus = _emailFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  checkOnEditingComplete() {
    if (_password.isEmpty) {
      setState(() {
        _validatePass = true;
      });
    } else {
      setState(() {
        _validatePass = false;
      });
    }

    if (_email.isEmpty) {
      setState(() {
        _validateMail = true;
      });
    } else {
      setState(() {
        _validateMail = false;
      });
    }

    if (_name.isEmpty) {
      setState(() {
        _validateName = true;
      });
    } else {
      setState(() {
        _validateName = false;
      });
    }

    if (_validatePass == false &&
        _validateMail == false &&
        _validateName == false) {
      submitButton();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  final picker = ImagePicker();
  File _selectedFile;
  bool _inProcess = false;

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
              content: new Text("Выберите фото"),
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
    try {
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
    } catch (e) {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Ошибка"),
          content: Text("Повторите позже"),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("Ok"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  uploadImage(File image) async {
    try {
      StorageReference reference = FirebaseStorage.instance
          .ref()
          .child('/images/${DateTime.now().toIso8601String()}');
      StorageUploadTask uploadTask = reference.putFile(image);

      StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

      String url = (await downloadUrl.ref.getDownloadURL());

      setState(() {
        imgUrl = url;
      });
    } catch (e) {
      showPlatformDialog(
        context: context,
        builder: (_) => BasicDialogAlert(
          title: Text("Ошибка"),
          content: Text("Повторите позже"),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("Ok"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  Color colorText = Colors.black;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Регистрация заказчика'),
        centerTitle: true,
      ),
//        resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: SizeConfig.screenWidth / 20,
                            right: SizeConfig.screenWidth / 20,
                            top: SizeConfig.screenHeight / 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            getImageWidget(context),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Загрузите фото',
                                style: TextStyle(color: colorText),
                              ),
                            ),
                            nameTextField(),
                            SizedBox(
                              height: SizeConfig.screenHeight / 50,
                            ),
                            emailTextField(),
                            SizedBox(
                              height: SizeConfig.screenHeight / 50,
                            ),
                            passTextField(),
                            SizedBox(
                              height: SizeConfig.screenHeight / 50,
                            ),
                            submitButtonWidget(),
                            SizedBox(height: SizeConfig.blockSizeVertical * 2),
                            Text(
                              'или',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            SizedBox(height: SizeConfig.blockSizeVertical * 2),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignInError(BuildContext context, PlatformException exception) {
    PlatformExceptionAlertDialog(
      title: 'Sign in failed',
      exception: exception,
    ).show(context);
  }

  SizedBox submitButtonWidget() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: RaisedButton(
        onPressed: buttonEnabled
            ? () async {
                setState(
                  () {
                    _email.isEmpty
                        ? _validateMail = true
                        : _validateMail = false;
                    _password.isEmpty
                        ? _validatePass = true
                        : _validatePass = false;
                    _name.isEmpty
                        ? _validateName = true
                        : _validateName = false;
                  },
                );
                if ((_validateMail == false &&
                    _validatePass == false &&
                    _validateName == false)) {
                  setState(() {
                    buttonEnabled = false;
                  });

                  submitButton();
                }
              }
            : null,
        child: buttonEnabled
            ? Text(
                'Регистрация',
                style: TextStyle(),
              )
            : SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator()),
      ),
    );
  }

  TextField passTextField() {
    return TextField(
      style: TextStyle(
        color: Colors.black,
      ),
      obscureText: true,
      autocorrect: false,
      onEditingComplete: checkOnEditingComplete,
      cursorColor: Color(0xff000000),
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Введите пароль',
        errorText: _validatePass ? '' : null,
      ),
    );
  }

  TextField nameTextField() {
    return TextField(
      style: TextStyle(
        color: Colors.black,
      ),
      autocorrect: false,
      textCapitalization: TextCapitalization.sentences,
      onEditingComplete: _nameEditingComplete,
      cursorColor: Color(0xff000000),
      controller: _nameController,
      focusNode: _nameFocusNode,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Введите ваше Имя',
        errorText: _validateName ? '' : null,
      ),
    );
  }

  TextField emailTextField() {
    return TextField(
      style: TextStyle(
        color: Colors.black,
      ),
      cursorColor: Color(0xff000000),
      focusNode: _emailFocusNode,
      onEditingComplete: _emailEditingComplete,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Введите ваш Email',
        errorText: _validatePass ? '' : null,
      ),
    );
  }
}
