// // ignore_for_file: avoid_print

// import 'dart:async';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:math' as math;
// import 'package:flutter_tflite/flutter_tflite.dart';
// import 'package:wakelock/wakelock.dart';
// import 'package:provider/provider.dart';

// import 'lib/widgets/bottom_sheet.dart';
// import 'lib/widgets/bounding_box.dart';
// import 'lib/widgets/camera.dart';
// import 'lib/provider/flash_provider.dart';

// class LiveFeed extends StatefulWidget {
//   final List<CameraDescription> cameras;

//   LiveFeed(this.cameras, {required Key key});
//   @override
//   _LiveFeedState createState() {
//     return _LiveFeedState();
//   }
// }

// class _LiveFeedState extends State<LiveFeed> with WidgetsBindingObserver {
//   CameraController? controller;
//   List<dynamic>? _recognitions;
//   int _imageHeight = 0;
//   int _imageWidth = 0;
//   initCameras() async {}
//   loadTfModel() async {
//     await Tflite.loadModel(
//         model: "assets/potholes.tflite",
//         labels: "assets/potholes.txt",
//         numThreads: 4);
//   }

//   bool detectPermission = false;
//   bool isDetecting = false;

//   /* 
//   The set recognitions function assigns the values of recognitions, imageHeight and width to the variables defined here as callback
//   */
//   setRecognitions(recognitions, imageHeight, imageWidth) {
//     setState(() {
//       _recognitions = recognitions;
//       _imageHeight = imageHeight;
//       _imageWidth = imageWidth;
//     });
//   }

//   Future<bool> checkCameraPermission() async {
//     final cameraPermission = await Permission.camera.status;
//     //final micPermission = await Permission.microphone.status;

//     if (cameraPermission == PermissionStatus.granted) {
//       context.read<FlashModeProvider>().setIsCameraPermissionGranted(true);
//       print('Camera is granted');

//       return true;
//     } else if (cameraPermission == PermissionStatus.permanentlyDenied) {
//       context.read<FlashModeProvider>().setIsPermanentlyDenied(true);
//       print('Camera is permanently denied');
//     } else {
//       // ignore: use_build_context_synchronously
//       context.read<FlashModeProvider>().setIsCameraPermissionGranted(false);
//       print('Camera is temporarily denied');
//     }
//     print('Camera Permission: $cameraPermission');
//     return false;
//   }

//   Future<bool> checkMicPermission() async {
//     final micPermission = await Permission.microphone.status;

//     if (micPermission == PermissionStatus.granted) {
//       context.read<FlashModeProvider>().setIsMicPermissionGranted(true);
//       return true;
//     } else {
//       // ignore: use_build_context_synchronously
//       context.read<FlashModeProvider>().setIsMicPermissionGranted(false);
//     }
//     print('Mic Permission: $micPermission');
//     return false;
//   }

//   Future checkAndRequestPermission() async {
//     // return true, if already have permission
//     if (await checkCameraPermission() && await checkMicPermission()) {
//       return;
//     } else if (await checkCameraPermission() == true &&
//         await checkMicPermission() == false) {
//       print('camera granted but mic denied');
//       print('Requesting microphone permission');
//       await Permission.microphone.request().then((value) {
//         if (value == PermissionStatus.permanentlyDenied) {
//           context
//               .read<FlashModeProvider>()
//               .setIsMicPermissionPermanentlyDenied(true);
//         }
//       });
//       checkMicPermission();
//     } else if (await checkMicPermission() == true &&
//         await checkCameraPermission() == false) {
//       print('camera denied but mic granted');
//       print('Requesting camera permission');
//       await Permission.camera.request();
//       checkCameraPermission();
//     } else {
//       await Permission.camera.request();
//       checkCameraPermission();
//       print('Both denied');
//     }
//   }

//   @override
//   void initState() {
//     WidgetsBinding.instance.addObserver(this);
//     Wakelock.enable();
//     checkAndRequestPermission();
//     loadTfModel();
//     if (widget.cameras == null || widget.cameras.length < 1) {
//     } else {
//       controller = CameraController(
//         widget.cameras[0],
//         ResolutionPreset.high,
//       );
//       startDetection(controller!);
//     }

//     super.initState();
//   }

//   startDetection(CameraController controller) {
//     controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {});

//       controller.startImageStream(onLatestImageAvailable);
//     });
//   }

//   onLatestImageAvailable(CameraImage img) async {
//     print('Is detecting');
//     if (!isDetecting) {
//       isDetecting = true;
//       print('value: $isDetecting');
//       Tflite.detectObjectOnFrame(
//         bytesList: img.planes.map((plane) {
//           return plane.bytes;
//         }).toList(),
//         model: "SSDMobileNet",
//         imageHeight: img.height,
//         imageWidth: img.width,
//         imageMean: 127.5,
//         imageStd: 127.5,
//         numResultsPerClass: 3,
//         threshold: 0.4,
//       ).then((recognitions) {
//         print('Recognitions: $recognitions');
//         setRecognitions(recognitions!, img.height, img.width);
//         isDetecting = false;
//       });
//     }
//   }

//   Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
//     final CameraController? oldController = controller;
//     if (oldController != null) {
//       // `controller` needs to be set to null before getting disposed,
//       // to avoid a race condition when we use the controller that is being
//       // disposed. This happens when camera permission dialog shows up,
//       // which triggers `didChangeAppLifecycleState`, which disposes and
//       // re-creates the controller.
//       controller = null;
//       await oldController.dispose();
//     }

//     final CameraController cameraController = CameraController(
//       cameraDescription,
//       ResolutionPreset.high,
//       enableAudio: false,
//     );

//     controller = cameraController;

//     // If the controller is updated then update the UI.
//     cameraController.addListener(() {
//       if (mounted) {
//         setState(() {});
//       }
//     });

//     //try to initialize he conroller or else throw and exception
//     try {
//       //await cameraController.initialize();
//       startDetection(cameraController);
//     } on CameraException catch (e) {
//       print('Error initializing camera: $e');
//     }

//     if (mounted) {
//       setState(() {});
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed &&
//         detectPermission &&
//         (context.read<FlashModeProvider>().isPermanentlyDenied == true ||
//             context
//                     .read<FlashModeProvider>()
//                     .isMicPermissionPermanentlyDenied ==
//                 true)) {
//       detectPermission = false;
//       print('Detect permission $detectPermission');
//       checkCameraPermission();
//       checkMicPermission();
//     } else if (state == AppLifecycleState.paused &&
//         (context.read<FlashModeProvider>().isPermanentlyDenied == true ||
//             context
//                     .read<FlashModeProvider>()
//                     .isMicPermissionPermanentlyDenied ==
//                 true)) {
//       detectPermission = true;
//       print('Detect permission $detectPermission');
//     }

//     final CameraController? cameraController = controller;

//     // App state changed before we got the chance to initialize.
//     if (cameraController == null || !cameraController.value.isInitialized) {
//       return;
//     }

//     if (state == AppLifecycleState.inactive) {
//       cameraController.stopImageStream();
//       cameraController.dispose();
//       //print('Stopped image streaming');
//     } else if (state == AppLifecycleState.resumed) {
//       //print('App resumed');
//       onNewCameraSelected(cameraController.description);
//     }
//   }

//   // @override
//   // void didChangeDependencies() {
//   //   checkCameraPermission();
//   //   checkMicPermission();
//   //   super.didChangeDependencies();
//   // }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Widget bodyWidget(Size screen, var isPortrait) {
//     return Stack(
//       children: <Widget>[
//         CameraFeed(
//           widget.cameras,
//           setRecognitions,
//           controller!,
//         ),
//         BoundingBox(
//             _recognitions == null ? [] : _recognitions!,
//             math.max(_imageHeight, _imageWidth),
//             math.min(_imageHeight, _imageWidth),
//             screen.height,
//             screen.width,
//             isPortrait),
//         OrientationBuilder(
//           builder: (context, orientation) {
//             if (orientation == Orientation.portrait) {
//               return BottomSheetWidget();
//             } else {
//               return Container();
//             }
//           },
//         )
//       ],
//     );
//   }
//   //context.watch<FlashModeProvider>()

//   @override
//   Widget build(BuildContext context) {
//     print('Live camera build method called');
//     //print(_recognitions);
//     Size screen = MediaQuery.of(context).size;
//     var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

//     return SafeArea(
//         top: false,
//         child: Scaffold(
//           appBar: isPortrait
//               ? AppBar(
//                   title: const Text("SpotHole"),
//                 )
//               : null,
//           body: (context.watch<FlashModeProvider>().isCameraPermissionGranted &&
//                   context.watch<FlashModeProvider>().isMicPermissionGranted)
//               ? bodyWidget(screen, isPortrait)
//               : PermissionScreenWidget(checkAndRequestPermission),
//         ));
//   }
// }

// class PermissionScreenWidget extends StatelessWidget {
//   Function checkAndRequestPermission;

//   PermissionScreenWidget(this.checkAndRequestPermission);

//   Widget permissionScreen(
//       Function onPressedHandler, String titleText, String buttonText) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Row(),
//         Center(
//             child: Text(
//           titleText,
//           maxLines: 4,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(fontSize: 20),
//           textAlign: TextAlign.center,
//         )),
//         const SizedBox(height: 24),
//         ElevatedButton(
//           onPressed: () {
//             onPressedHandler();
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               buttonText,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ((context.watch<FlashModeProvider>().isPermanentlyDenied == false) &&
//             (context
//                     .watch<FlashModeProvider>()
//                     .isMicPermissionPermanentlyDenied ==
//                 false))
//         ? permissionScreen(checkAndRequestPermission,
//             'Camera permission was denied!', 'Request camera permission')
//         : permissionScreen(
//             openAppSettings,
//             'Camera permission was permanently denied! Open app setings and manually grant permission',
//             'Open app settings');
//   }
// }
