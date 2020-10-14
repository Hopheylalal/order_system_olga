import 'dart:io';
import 'dart:ui';
import 'package:basic_utils/basic_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:ordersystem/screens/edit_master_profile.dart';
import 'package:ordersystem/services/auth_service.dart';
import 'package:ordersystem/widgets/comment_widget.dart';
import 'package:provider/provider.dart';

class MasterProfile extends StatefulWidget {
  final String status;
  final String userType;

  const MasterProfile({Key key, this.status, @required this.userType})
      : super(key: key);

  @override
  _MasterProfileState createState() => _MasterProfileState();
}

class _MasterProfileState extends State<MasterProfile> {
  String curUsr;

  bool loadingNewImage = false;
  File _selectedFile;
  final picker = ImagePicker();
  String imgUrl;
  bool isLoading = false;
  bool _inProcess = false;
  String usrStatus = '';

  final userType = GetStorage();

  void getCurrentUser() async {
    var ggg = await Auth().currentUser();
    setState(() {
      curUsr = ggg;
    });
    final userStatus = await Firestore.instance.collection('masters').document(ggg).get();
    final userStatus1 = userStatus.data['userType'];
    // box.write('userType', userStatus1);
    // setState(() {
    //   usrStatus = userStatus1;
    // });
    

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
      editProfile();
    } else {
      print('still loading');
    }
  }

  void editProfile() async {
    try {
      await Firestore.instance
          .collection('masters')
          .document(curUsr)
          .updateData({
        'imgUrl': imgUrl,
      }).then(
        (_) => Navigator.pop(context),
      );
    } catch (e) {
      PlatformAlertDialog(
        title: 'Внимание',
        content: 'Неизвестная ошибка',
        defaultActionText: 'Ok',
      ).show(context);
    }
  }

  List<Widget> catNull = [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text('Нет выбранных специализаций.'),
    )
  ];

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final user = context.watch<FirebaseUser>()?.email;

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.status == 'reg') {
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.pop(context);
              }
            }),
        title: Text('Ваш профиль'),
        centerTitle: true,
        actions: [
          if (userType.read('userType') == 'master')
            IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMasterProfile(),
                    ),
                  );
                }),
          IconButton(
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();

                Navigator.of(context).popUntil((route) => route.isFirst);
              })
        ],
      ),
      body: (userType.read('userType') == 'master')
          ? SingleChildScrollView(
              child: StreamBuilder(
                  stream: Firestore.instance
                      .collection('masters')
                      .document(curUsr)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return LinearProgressIndicator();
                    }

                    if (snapshot.hasData) {
                      return Center(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: SizedBox(
                                width: double.infinity,
                                child: Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                        ),
                                        Center(
                                          child: CircleAvatar(
                                            radius: 65,
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    snapshot.data['imgUrl'],
                                                progressIndicatorBuilder:
                                                    (context, url,
                                                            downloadProgress) =>
                                                        CircularProgressIndicator(
                                                            value:
                                                                downloadProgress
                                                                    .progress),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    Icon(Icons.account_circle),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'Ваше имя',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '${snapshot.data['name']}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          'Ваш Email',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '${snapshot.data['email']}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          'Номер телефона',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '${snapshot.data['phoneNumber']}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          'Коротко о себе',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '${snapshot.data['aboutShort']}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          'Развернуто о себе',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          '${snapshot.data['aboutLong']}',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          'Ваши специализаци',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                snapshot.data['category'] !=
                                                        null
                                                    ? snapshot.data['category']
                                                    .where((element) => element != '1все')
                                                        .map<Widget>(
                                                            (val) => Padding(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      vertical:
                                                                          5),
                                                                  child: Text(
                                                                      '${StringUtils.capitalize(
                                                                        val.toString(),
                                                                      )}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                ))
                                                        .toList()
                                                    : catNull,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Отзывы',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            FutureBuilder(
                              future: Firestore.instance
                                  .collection('comments')
                                  .where('masterId', isEqualTo: curUsr)
                                  .orderBy('createDate', descending: true)
                                  .getDocuments(),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return LinearProgressIndicator();
                                }

                                if (snapshot.hasData) {
                                  if (snapshot.data.documents.length != 0) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: SizedBox(
                                        child: Column(
                                          children: snapshot.data.documents
                                              .map<Widget>(
                                                (val) => Comment(
                                                  createDate: val['createDate'],
                                                  content: val['content'],
                                                  name: val['ownerName'],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
                                      child: Center(
                                          child: Text('Пока нет отзывов')),
                                    );
                                  }
                                }
                                return Center(
                                  child: LinearProgressIndicator(),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return Container();
                  }),
            )
          : SingleChildScrollView(
              child: StreamBuilder(
                  stream: Firestore.instance
                      .collection('masters')
                      .document(curUsr)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.waiting){
                      return LinearProgressIndicator();
                    }
                    if (snapshot.hasData) {
                      return Container(
                        height: MediaQuery.of(context).size.height,
                        child: Card(
                          elevation: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      child: new AlertDialog(
                                        content: new Text("Выберете фото"),
                                        actions: [
                                          FlatButton(
                                            onPressed: () {
                                              getImageFromDevise(
                                                  ImageSource.camera);
                                              Navigator.pop(context);
                                            },
                                            child: Text('Камера'),
                                          ),
                                          FlatButton(
                                            onPressed: () {
                                              getImageFromDevise(
                                                  ImageSource.gallery);
                                              Navigator.pop(context);
                                            },
                                            child: Text('Галерея'),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    radius: 50,
                                    child: CircleAvatar(
                                      radius: 50,
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: snapshot.data['imgUrl'],
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Center(
                                                child: CircularProgressIndicator(
                                                    value: downloadProgress
                                                        .progress),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.account_circle),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Изменить фото',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  'Ваше имя',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  '${snapshot.data['name']}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  'Ваш Email',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Text(
                                  '${snapshot.data['email']}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container();
                  }),
            ),
    );
  }
}
