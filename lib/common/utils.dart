import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as Path;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as Im;

class Utils {
  static Future<File> pickImage(ImageSource source, chatId) async {
    File selectedImage = await ImagePicker.pickImage(source: source);
    return compressImage(selectedImage).whenComplete(() async{
      StorageReference _ref = FirebaseStorage.instance
          .ref()
          .child('$chatId/${Path.basename(selectedImage.path)}}');
      final StorageUploadTask uploadTask = _ref.putFile(selectedImage);
      await uploadTask.onComplete.whenComplete(() {
        _ref.getDownloadURL();}).then((value) => null);
    });
  }

  static Future<File> compressImage(File imageToCompress) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    int random = Random().nextInt(1000);
    Im.Image image = Im.decodeImage(imageToCompress.readAsBytesSync());
    Im.copyResize(image, width: 500, height: 500);
    return File('$path/img_$random.jpg')
      ..writeAsBytesSync(Im.encodeJpg(image, quality: 85));
  }
}
