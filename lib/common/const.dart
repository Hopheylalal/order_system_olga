import 'package:flutter/material.dart';

const kTextInputDecoration = InputDecoration(
  errorStyle: TextStyle(color: Colors.amberAccent),
  focusedErrorBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
  ),
  errorBorder: UnderlineInputBorder(
    borderSide: BorderSide(color: Colors.amberAccent),
  ),
  contentPadding: EdgeInsets.symmetric(vertical: 19),
  fillColor: Color(0xffFFFFFF),
  filled: true,
  hintStyle: TextStyle(
      fontSize: 18.0, color: Color(0xff000000), fontFamily: 'FiraSansRegular'),
  enabledBorder: OutlineInputBorder(
    borderRadius: const BorderRadius.all(
      const Radius.circular(0.0),
    ),
    borderSide: BorderSide(
      color: Color(0xffcfd8dc),
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: const BorderRadius.all(
      const Radius.circular(0.0),
    ),
    borderSide: BorderSide(
      color: Color(0xffcfd8dc),
    ),
  ),
);
