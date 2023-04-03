import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class StaticImage extends StatefulWidget {
  @override
  _StaticImageState createState() => _StaticImageState();
}

class _StaticImageState extends State<StaticImage> {
  File? _image;
  List<dynamic>? _recognitions;
  bool? _busy;
  double? _imageWidth, _imageHeight;
  int inferenceTime = 0;
  int preProcessingTime = 0;

  //Resource Monitor
  // Resource? _data;
  // static const double _defaultValue = 0.0;
  // double _appCpuUsagePeak = _defaultValue, _appMemoryUsagePeak = _defaultValue;
  // Timer? timer;
  final picker = ImagePicker();

  // this function loads the model
  loadTfModel() async {
    await Tflite.loadModel(
      model:
          "assets/chitholian_potholes.tflite", //detect_integerWithFloatFallbackQuantization
      labels: "assets/potholes.txt",
      isAsset: true,
      isModelTf1: true,
    );
  }

  setRecognitions(recognitions) {
    setState(() {
      _recognitions = recognitions;
      recognitions.forEach((element) {
        inferenceTime = element["inferenceTime"];
        preProcessingTime = element["preProcessingTime"];
        //print('Inference time is: $inferenceTime');
      });
    });
  }

  // this function detects the objects on the image
  detectObject(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, // required
        model: "SSDMobileNet",
        imageMean: 127.5,
        imageStd: 127.5,
        threshold: 0.4, // defaults to 0.1
        numResultsPerClass: 10, // defaults to 5
        asynch: true // defaults to true
        );
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));

    setRecognitions(recognitions);
  }

  @override
  void initState() {
    super.initState();
    _busy = true;
    loadTfModel().then((val) {
      {
        setState(() {
          _busy = false;
        });
      }
    });
  }

  // display the bounding boxes over the detected objects
  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) {
      print("Recognitions is null");
      return [];
    }
    if (_imageWidth == null || _imageHeight == null) {
      print("Image height or width is null ");
      return [];
    }

    double factorX = screen.width;
    //double factorX = _imageWidth!;
    double factorY = _imageHeight! / _imageHeight! * screen.width;

    Color blue = Colors.blue;

    return _recognitions!.map((re) {
      return Align(
        alignment: Alignment.center,
        child: Positioned(
            left: re["rect"]["x"] * factorX,
            top: re["rect"]["y"] * factorY,
            width: re["rect"]["w"] * factorX,
            height: re["rect"]["h"] * factorY,
            child: ((re["confidenceInClass"] > 0.50))
                ? Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: blue,
                      width: 3,
                    )),
                    child: Text(
                      "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        background: Paint()..color = blue,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  )
                : Container()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(Align(
      alignment: Alignment.center,
      // using ternary operator
      child: _image == null
          ? Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "Please Select an Image",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            )
          : // if not null then
          Image.file(_image!),
    ));
    if (_image != null) {
      stackChildren.add(Align(
        alignment: Alignment.topCenter,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding:
                const EdgeInsets.only(bottom: 8, right: 8, left: 10, top: 16),
            child: Text(
              'Pre-Processing Time: $preProcessingTime',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 8, top: 16),
            child: Text(
              'Inference Time: $inferenceTime',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      ));
    }

    stackChildren.addAll(renderBoxes(size));

    if (_busy!) {
      print("App is currently $_busy");
      stackChildren.add(const Center(
        child: CircularProgressIndicator(),
      ));
    }

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SpotHole"),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "Fltbtn1",
              onPressed: getImageFromGallery,
              child: const Icon(Icons.photo),
            ),
          ],
        ),
        body: Container(
          alignment: Alignment.center,
          child: Stack(
            children: stackChildren,
          ),
        ),
      ),
    );
  }

  // gets image from camera and runs detectObject
  Future getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected");
      }
    });
    detectObject(_image!);
  }

  // gets image from gallery and runs detectObject
  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No image Selected");
      }
    });
    detectObject(_image!);
  }
}
