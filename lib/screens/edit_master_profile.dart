import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multiselect_formfield/multiselect_formfield.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/provider/provider.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/add_marker_master.dart';
import 'package:ordersystem/widgets/master_category_edit.dart';
import 'package:ordersystem/widgets/order_filter.dart';
import 'package:provider/provider.dart';

class EditMasterProfile extends StatefulWidget {
  final userType;

  const EditMasterProfile({Key key, this.userType}) : super(key: key);
  @override
  _EditMasterProfileState createState() => _EditMasterProfileState();
}

class _EditMasterProfileState extends State<EditMasterProfile> {
  String name;
  String aboutShort;
  String aboutLong;
  String imgUrl;
  bool isLoading = false;
  bool _inProcess = false;
  bool loadingNewImage = false;
  File _selectedFile;
  final picker = ImagePicker();
  String userId;
  String curUsr;
  List _categories;
  List<Marker> masterPoint;

  final _formKey = GlobalKey<FormState>();
  final saveToken = GetStorage();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _longFocusNode = FocusNode();
  final FocusNode _shortFocusNode = FocusNode();

  void _nameEditingComplete() {
    final newFocus = _shortFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  void _longEditingComplete() {
    final newFocus = _longFocusNode;
    FocusScope.of(context).requestFocus(newFocus);
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _shortFocusNode.dispose();
    _longFocusNode.dispose();
    super.dispose();
  }

  Widget getImageWidget(BuildContext context, snapshot) {
    if (_selectedFile != null) {
      return GestureDetector(
        onTap: () {
          try {
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
          } catch (e) {
            print(e);
          }
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
          radius: 65,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: snapshot,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  CircularProgressIndicator(value: downloadProgress.progress),
              errorWidget: (context, url, error) => Icon(Icons.account_circle),
            ),

            // Image.network(snapshot),
          ),
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
      uploadImage(cropped);
      this.setState(() {
        _selectedFile = cropped;
        _inProcess = false;
      });
    } else {
      this.setState(() {
        _inProcess = false;
      });
    }
  }

  uploadImage(File image) async {
    setState(() {
      loadingNewImage = true;
    });
    StorageReference reference = FirebaseStorage.instance
        .ref()
        .child('/images/${DateTime.now().toIso8601String()}');
    StorageUploadTask uploadTask = reference.putFile(image);

    StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

    String url = (await downloadUrl.ref.getDownloadURL());

    if (url != null) {
      setState(() {
        imgUrl = url;
        loadingNewImage = false;
      });
    } else {
      print('still loading');
    }
  }

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
  }

  @override
  void initState() {
    getCurrentUser();

    super.initState();
  }

  void editProfile(newImg) async {
    _formKey.currentState.save();
    try {
      if(widget.userType == 'master'){
        await Firestore.instance
            .collection('masters')
            .document(curUsr)
            .updateData({
          'name': name,
          'userId': curUsr,
          'imgUrl': imgUrl == null ? imgUrl = newImg : imgUrl,
          'aboutShort': aboutShort,
          'aboutLong': aboutLong,
          'token': saveToken.read('token'),
          'geoPoint': GeoPoint(masterPoint.first.position.latitude,
              masterPoint.last.position.longitude)
        }).then(
              (_) => Navigator.pop(context),
        );
      }else{
        await Firestore.instance
            .collection('masters')
            .document(curUsr)
            .updateData({
          'name': name,
          'userId': curUsr,
          'imgUrl': imgUrl == null ? imgUrl = newImg : imgUrl,
          'token': saveToken.read('token'),
        }).then(
              (_) => Navigator.pop(context),
        );
      }

    } catch (e) {
      PlatformAlertDialog(
        title: 'Внимание',
        content: 'Обновите ваше местоположение',
        defaultActionText: 'Ok',
      ).show(context);
    }
  }

  List<String> masterCats = [];
  List<String> allCategories = [];

  getMasterCategory() async {
    DocumentSnapshot catArr =
        await Firestore.instance.collection('masters').document(curUsr).get();

    setState(() {
      masterCats = catArr.data['category'].cast<String>();
    });
  }

  getAllCategory() async {
    DocumentSnapshot catArr = await Firestore.instance
        .collection('category')
        .document('BY7oiRIc6uq14MwsJ9yV')
        .get();

    setState(() {
      allCategories = catArr.data['cats'].cast<String>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<FirebaseUser>().uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать профиль'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              FutureBuilder(
                future: Firestore.instance
                    .collection('masters')
                    .document(user)
                    .get(),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          getImageWidget(context, snapshot.data['imgUrl']),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Изменить фото',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          TextFormField(
                            initialValue: snapshot.data['name'],
                            textInputAction: TextInputAction.next,
                            onEditingComplete: _nameEditingComplete,
                            onSaved: (val) {
                              name = val;
                            },
                            decoration: InputDecoration(
                              labelText: 'ФИО',
                            ),
                          ),
                          if(widget.userType == 'master')
                          TextFormField(
                            initialValue: snapshot.data['aboutShort'],
                            focusNode: _shortFocusNode,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: _longEditingComplete,
                            onSaved: (val) {
                              aboutShort = val;
                            },
                            decoration:
                                InputDecoration(labelText: 'Коротко о себе'),
                          ),
                          if(widget.userType == 'master')
                          TextFormField(
                            initialValue: snapshot.data['aboutLong'],
                            focusNode: _longFocusNode,
                            keyboardType: TextInputType.multiline,
                            minLines: 4,
                            maxLines: 4,
                            onSaved: (val) {
                              aboutLong = val;
                            },
                            decoration:
                                InputDecoration(labelText: 'Подробнее о себе'),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          if(widget.userType == 'master')
                          SizedBox(
                            width: double.infinity,
                            child: FlatButton.icon(
                              color: Colors.blue,
                              onPressed: () async {
                                getAllCategory();
//                              getMasterCategory();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MasterCategoryEdit(
                                      listFromFB: allCategories
                                          .where((element) => element != '1все')
                                          .toList(),
                                      masterUid: userId,
                                    ),
                                  ),
                                );
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
                          if(widget.userType == 'master')
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
                          SizedBox(
                            height: 20,
                          ),
                          RaisedButton(
                            onPressed: () {
                              if (loadingNewImage) {
                                return null;
                              } else {
                                editProfile(snapshot.data['imgUrl']);
                              }
                            },
                            child: !isLoading
                                ? Text('Применить')
                                : SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(child: LinearProgressIndicator());
                },
              ),
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
    );
  }
}
