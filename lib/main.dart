// ignore_for_file: avoid_print

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:provider/provider.dart';
import 'package:spothole/widgets/overlay_permission_screen.dart';
import '../provider/flash_provider.dart';

List<CameraDescription>? cameras;

// getVelocityCallback(var velocity) async {
//   print('Current velocity ${await velocity}');
//   if (await velocity >= 5) {
//     FlutterForegroundTask.wakeUpScreen();
//     FlutterForegroundTask.launchApp();
//   }
// }

Future<void> main() async {
  // initialize the cameras when the app starts
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  // running the app
  runApp(MaterialApp(
    home: WillStartForegroundTask(
        onWillStart: () async {
          return true;
        },
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: 'Foreground Notification',
          channelDescription:
              'This notification appears when the foreground service is running.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 2000,
          autoRunOnBoot: true,
          allowWifiLock: false,
        ),
        notificationTitle: 'SpotHole Service is running',
        notificationText: 'Tap to return to the app',
        //callback: getVelocityCallback,
        child: MyApp()),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final FlashModeProvider model;
  bool detectPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    model = FlashModeProvider();
    checkPermission();
  }

  void checkPermission() async {
    final isIgnoringBatteryOptimizations =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    print('Is Ignoring battery opimization: $isIgnoringBatteryOptimizations');

    model.setIsIgnoringBatteryOptimizattion(isIgnoringBatteryOptimizations);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        detectPermission &&
        (model.isIgnoringBatteryOptimization == false)) {
      detectPermission = false;
      print('Detect permission $detectPermission');
      checkPermission();
    } else if (state == AppLifecycleState.paused &&
        model.isIgnoringBatteryOptimization == false) {
      detectPermission = true;
      print('Detect permission $detectPermission');
    }
  }

  @override
  void didChangeDependencies() {
    checkPermission();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // userAccelerometerEvents.listen(<num>(UserAccelerometerEvent event) {
    //   double speed = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    //   return getVelocityCallback(speed);
    // });
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<FlashModeProvider>(
        builder: (context, value, child) {
          return Scaffold(
              appBar: AppBar(
                title: const Text("SpotHole"),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: aboutDialog,
                  ),
                ],
              ),
              body: context
                      .watch<FlashModeProvider>()
                      .isIgnoringBatteryOptimization
                  ? OverlayPermissionScreen()
                  : permissionHanlderWidget());
        },
      ),
    );
  }

  Widget permissionHanlderWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please disable battery opitmization for the app otherwise it might not work properly',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          ElevatedButton(
              onPressed: () async {
                await FlutterForegroundTask
                    .openIgnoreBatteryOptimizationSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16),
              ))
        ],
      ),
    );
  }

  aboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "SpotHole",
      applicationVersion: "v1.0",
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            'Created by Nehal Choudhury',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
