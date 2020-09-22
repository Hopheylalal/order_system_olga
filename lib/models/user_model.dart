import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String userName;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  final String status;
  final Timestamp createDate;
  final String dateOfBirth;
  final String city;
  final String country;
  final String sex;
  final String number;

  UserModel({
    this.id,
    this.userName,
    this.email,
    this.photoUrl,
    this.displayName,
    this.bio,
    this.status,
    this.createDate,
    this.dateOfBirth,
    this.city,
    this.country,
    this.sex,
    this.number
  });

  factory UserModel.fromDocument(doc) {
    return UserModel(
      id: doc['id'],
      userName: doc['userName'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      status: doc['status'],
      createDate: doc['createDate'],
      dateOfBirth: doc['dateOfBirth'],
      city: doc['city'],
      country: doc['country'],
      sex: doc['sex'],
      number: doc['number']
    );
  }
}
