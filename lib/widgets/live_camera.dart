// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:wakelock/wakelock.dart';
import 'package:location/location.dart' as locationPackage;
import 'bottom_sheet.dart';
import 'bounding_box.dart';
import 'camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveFeed extends StatefulWidget {
  final List<CameraDescription> cameras;

  LiveFeed(this.cameras, {required Key key});
  @override
  _LiveFeedState createState() {
    return _LiveFeedState();
  }
}

class _LiveFeedState extends State<LiveFeed> with WidgetsBindingObserver {
  Widget? errWidget;
  CameraController? controller;
  List<dynamic>? _recognitions;
  int inferenceTime = 0;
  int preProcessingTime = 0;
  int _imageHeight = 0;
  int _imageWidth = 0;
  initCameras() async {}
  loadTfModel() async {
    await Tflite.loadModel(
        model: "assets/potholes_IwFFQ_new.tflite", //detect_FPIwO.tflite works
        labels: "assets/potholes.txt",
        useGpuDelegate: false, //doesnt work with tflite 2.9.0
        useNnApiAndroid: true,
        // around 30 ms inference time with model trained on our dataset (INTEGER WITH FLOAT FALLBACK QUANTIZATION WITH DEFAULT OPTMIZATIONS) //potholes.tflite
        isAsset: true,
        isModelTf1: false,
        numThreads: 4);
  }

  //Ip adress of server
  var url = 'http://3.7.125.104:8000/location/addnewpothole';
  double depth = 0;
  double width = 0;
  double height = 0;

  bool detectPermission = false;
  bool isDetecting = false;

  double? potholeHeight;
  double? potholeWidth;
  double? detectionAccuracy;

  //Code for accessing location

  locationPackage.Location location = locationPackage.Location();

  bool? serviceEnabled;
  locationPackage.PermissionStatus? permissionGranted;
  locationPackage.LocationData? locationData;

  initLocation() async {
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled!) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled!) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  getLocation() async {
    locationData = await location.getLocation();
  }

  double _counter = 0;
  static const platform = MethodChannel('com.spothole/camera');
  Future<void> getFocalLength() async {
    double focalLength;
    try {
      focalLength = await platform.invokeMethod('getFocalLength');
      print('Focal length of rear camera is $focalLength mm');
    } on PlatformException catch (error) {
      print(error);
      focalLength = 1;
    }
    setState(() {
      _counter = focalLength;
    });
  }

  postRequest(Map<String, Object> jsonBody) async {
    //Function to add new pothole to the server
    //var url = 'http://maps.amarworks.me:8000/location/addnewpothole';
    print("PostRequest function");
    var body = jsonBody;
    var response = await http.post(Uri.parse(url),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"},
        encoding: Encoding.getByName("utf-8"));
    //print("Response code: ${response.statusCode}");
    //print("Response body: ${response.body}");
  }

  /* 
  The set recognitions function assigns the values of recognitions, imageHeight and width to the variables defined here as callback
  */
  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
      recognitions.forEach((element) {
        inferenceTime = element["inferenceTime"];
        preProcessingTime = element["preProcessingTime"];
        //print('Inference time is: $inferenceTime');
      });
    });
  }

  startDetection(CameraController controller) {
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      controller.startImageStream(onLatestImageAvailable);
    });
  }

  onLatestImageAvailable(CameraImage img) async {
    print('Is detecting');
    if (!isDetecting) {
      isDetecting = true;
      print('value: $isDetecting');
      Tflite.detectObjectOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        //For ssd
        model: "SSDMobileNet",
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 3,
        threshold: 0.5,
        //For yolo
        // model: "YOLO",
        // imageHeight: img.height,
        // imageWidth: img.width,
        // imageMean: 0,
        // imageStd: 255.0,
        // threshold: 0.2,
        // numResultsPerClass: 1,
        // //anchors:
        // //anchors, // defaults to [0.57273,0.677385,1.87446,2.06253,3.33843,5.47434,7.88282,3.52778,9.77052,9.16828]
        // blockSize: 32,
        // numBoxesPerBlock: 5,
        // asynch: true,
      ).then((recognitions) {
        // if (recognitions != null) {
        //   recognitions.forEach((element) {
        //     print('Inference time is: ${element["inferenceTime"]}');
        //     //inferenceTime = element["inferenceTime"];
        //   });
        // }
        setRecognitions(recognitions!, img.height, img.width);
        print("Recognitions: $recognitions");
        if (recognitions != null) {
          recognitions.forEach((element) {
            getLocation();
            var body = new Map<String, Object>();
            if (locationData != null) {
              width =
                  114.07 * element["rect"]["w"] + 1.18; //* (img.width / 320);
              height =
                  190.42 * element["rect"]["h"] + 3.82; // * (img.height / 320);
              depth = 9.82 * element["rect"]["w"] + 0.12;
              var longitude = locationData!.longitude;
              var latitude = locationData!.latitude;
              print("Longitude: $longitude and Latitude $latitude");
              body["longitude"] = longitude as double;
              body["latitude"] = latitude as double;
              body["height"] = height;
              body["width"] = width;
              body["accuracy"] = element["confidenceInClass"] *
                  100; //((2 * 3.14 * 180) / (width + height * 360) * 1) * 2.54
              print("Body: $body");
              postRequest(body);
            } else {
              print("Longitude and latitude are null");
            }
            print(
                'Width is: ${element["rect"]["w"]}, Height is: ${element["rect"]["h"]} and Acuracy is: ${element["confidenceInClass"] * 100} %');
            //inferenceTime = element["inferenceTime"];
          });
        }

        isDetecting = false;
      });
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = controller;
    if (oldController != null) {
      // `controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
      controller = null;
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    //try to initialize he conroller or else throw and exception
    try {
      //await cameraController.initialize();
      startDetection(cameraController);
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        log("App Resumed");
        _checkCameraPermissionStatus();

        break;
      case AppLifecycleState.inactive:
        log("App Inactive");

        break;
      case AppLifecycleState.paused:
        log("App Paused");
        break;
      case AppLifecycleState.detached:
        log("App Detached");
        break;
    }

    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.stopImageStream();
      cameraController.dispose();
      //print('Stopped image streaming');
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
    getFocalLength();
    loadTfModel();
    initLocation();
    if (widget.cameras == null || widget.cameras.length < 1) {
    } else {
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      startDetection(controller!);
    }

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Widget permissionScreen(
      Function onPressedHandler, String titleText, String buttonText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(),
        Center(
            child: Text(
          titleText,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            onPressedHandler();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _checkCameraPermissionStatus() async {
    var status = await Permission.camera.request().then((value) => value);

    switch (status) {
      case PermissionStatus.granted:
        errWidget = await _checkMicPermissionStatus();
        setState(() {});

        break;

      case PermissionStatus.denied:
        setState(() {
          errWidget = permissionScreen(_checkCameraPermissionStatus,
              'Camera permission was denied!', 'Request camera permission');
        });
        break;
      case PermissionStatus.permanentlyDenied:
        setState(() {
          errWidget = permissionScreen(
              openAppSettings,
              'Camera permission was permanently denied! Open app setings and manually grant permission',
              'Open app settings');
        });
        break;
      default:
        errWidget = await _checkMicPermissionStatus();
        setState(() {});

        break;
    }
  }

  Future<Widget> _checkMicPermissionStatus() async {
    var micStatus;
    var status = await Permission.microphone.request().then((value) {
      if (value == PermissionStatus.permanentlyDenied) {
        micStatus = 2;
      }
    });

    if (micStatus == 2) {
      return permissionScreen(
          openAppSettings,
          'Microphone permission was permanently denied! Open app setings and manually grant permission',
          'Open app settings');
    } else {
      switch (status) {
        case PermissionStatus.granted:
          return bodyWidget();

        case PermissionStatus.denied:
          return permissionScreen(
              _checkCameraPermissionStatus,
              'Microphone permission was denied!',
              'Request Microphone permission');

        default:
          return bodyWidget();
      }
    }
  }

  double getNumber(double input, {int precision = 4}) {
    //Function to truncate to n decimal places
    return double.parse(
        '$input'.substring(0, '$input'.indexOf('.') + precision + 1));
  }

  Widget bodyWidget() {
    Size screen = MediaQuery.of(context).size;
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    double latitude = 0;
    double longitude = 0;
    if (locationData != null) {
      latitude = getNumber(locationData!.latitude as double);
      longitude = getNumber(locationData!.longitude as double);
    }
    return Stack(
      children: <Widget>[
        CameraFeed(
          widget.cameras,
          setRecognitions,
          controller!,
        ),
        BoundingBox(
            _recognitions == null ? [] : _recognitions!,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
            isPortrait),
        OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return BottomSheetWidget(
                  inferenceTime, preProcessingTime, height, width, depth);
            } else {
              return Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8, right: 8, top: 8),
                          child: Container(
                              child: Text(
                            'Pre-Processing Time: $preProcessingTime',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          )),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8, right: 8, top: 8),
                          child: Container(
                              child: Text(
                            'Inference Time: $inferenceTime',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return SafeArea(
        top: false,
        child: Scaffold(
            appBar: isPortrait
                ? AppBar(
                    title: const Text("SpotHole"),
                  )
                : null,
            body: FutureBuilder(
              future: Future.wait(
                  [Permission.camera.status, Permission.microphone.status]),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PermissionStatus>> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data![0] == PermissionStatus.granted &&
                      snapshot.data![1] == PermissionStatus.granted) {
                    return bodyWidget();
                  } else {
                    if (errWidget != null) {
                      return errWidget!;
                    } else {
                      if (snapshot.data![0] != PermissionStatus.granted ||
                          snapshot.data![0] !=
                              PermissionStatus.permanentlyDenied) {
                        return permissionScreen(
                            _checkCameraPermissionStatus,
                            'Camera permission was denied!',
                            'Request camera permission');
                      } else {
                        return permissionScreen(
                            _checkCameraPermissionStatus,
                            'Microphone permission was denied!',
                            'Request Microphone permission');
                      }
                    }
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  );
                }
              },
            )));
  }
}
