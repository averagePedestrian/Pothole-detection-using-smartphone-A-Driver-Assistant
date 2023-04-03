import 'dart:io';
import 'package:flutter/material.dart';

class Place {
  //String id;
  //String title;
  String latitude;
  String longitude;
  String height;
  String width;
  String accuracy;

  Place(
      {//required this.id,
      required this.accuracy,
      required this.height,
      required this.latitude,
      required this.longitude,
      //required this.title,
      required this.width});
}
