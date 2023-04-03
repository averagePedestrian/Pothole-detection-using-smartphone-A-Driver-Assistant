import 'package:flutter/material.dart';
import 'dart:math' as math;

class BoundingBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  final bool isPortrait;

  BoundingBox(this.results, this.previewH, this.previewW, this.screenH,
      this.screenW, this.isPortrait);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBox() {
      return results.map((result) {
        double _x = result["rect"]["x"];
        double _w = result["rect"]["w"];
        double _y = result["rect"]["y"];
        double _h = result["rect"]["h"];
        double scaleW, scaleH, x, y, w, h;
        double factorX = 0,
            factorY = 0,
            xpos = 0,
            ypos = 0,
            cheight = 0,
            cwidth = 0;

        factorX = screenW;
        factorY = screenH;
        w = _w * factorX;
        h = _h * factorY;
        x = _x * factorX;
        y = _y * factorY;


        if ((x >= (screenW * 0.99)) ||
            (y >= (isPortrait ? (screenH * 0.65) : (screenH * 0.95)))) {  //point of interest ouside view
          ypos = 0;
          cheight = 0;
          xpos = 0;
          cwidth = 0;
        } else {   //point of interest inside view
          xpos = math.max(0, x);
          ypos = math.max(0, y);
          if ((x + w) >= (screenW * 0.98)) {
            cwidth = (screenW * 0.98) - x;
          } else {
            cwidth = w;
          }
          if ((y + h) >= (isPortrait ? (screenH * 0.65) : (screenH * 0.95))) {
            cheight = (isPortrait ? (screenH * 0.65) : (screenH * 0.95)) - y;
          } else {
            cheight = h;
          }

        } 

        return Positioned(
          left: xpos,
          top: ypos,
          width: cwidth,
          height: cheight,
          child: Container(
            padding: const EdgeInsets.only(top: 5.0, left: 5.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(37, 213, 253, 1.0),
                width: 3.0,
              ),
            ),
            child: Text(
              "${result["detectedClass"]} ${(result["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Color.fromRGBO(37, 213, 253, 1.0),
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList();
    }

    return Stack(
      children: _renderBox(),
    );
  }
}
