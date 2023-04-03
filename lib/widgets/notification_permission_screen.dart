// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:notification_permissions/notification_permissions.dart';

import 'package:provider/provider.dart';

import '../provider/flash_provider.dart';
import 'live_camera.dart';
import 'static_image.dart';


List<CameraDescription>? cameras;

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return NotificationPermissionScreenState();
  }
}

class NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> with WidgetsBindingObserver {
  bool detectPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initStateAsync();
    checkPermission();
  }

  void initStateAsync() async {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  }

  void checkPermission() async {
    final isNotificationPermissionGranted =
        await NotificationPermissions.getNotificationPermissionStatus();
    print('Is Ignoring battery opimization: $isNotificationPermissionGranted');

    if (isNotificationPermissionGranted == PermissionStatus.granted) {
      context
          .read<FlashModeProvider>()
          .setIsNotificationPermissionGranted(true);
    } else {
      context
          .read<FlashModeProvider>()
          .setIsNotificationPermissionGranted(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        detectPermission &&
        (context.read<FlashModeProvider>().isNotificationPermissionGranted ==
            false)) {
      detectPermission = false;
      print('Detect permission $detectPermission');
      checkPermission();
    } else if (state == AppLifecycleState.paused &&
        context.read<FlashModeProvider>().isNotificationPermissionGranted ==
            false) {
      detectPermission = true;
      print('Detect permission $detectPermission');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget permissionHanlderWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please allow the app to send notifications. We need this to start a forground service so the app won\'t be automatically terminated by android',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          ElevatedButton(
              onPressed: () async {
                await NotificationPermissions.requestNotificationPermissions();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 16),
              ))
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    checkPermission();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashModeProvider>(builder: (context, value, child) {
      return context.watch<FlashModeProvider>().isNotificationPermissionGranted
          ? BodyWidget()
          : permissionHanlderWidget();
    });
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
            'Created by Nehal Choudhury, Deepak Kumar and Amar Kamalapuri',
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

class BodyWidget extends StatelessWidget {
  BodyWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ButtonTheme(
                minWidth: MediaQuery.of(context).size.width * 0.20,
                child: ElevatedButton(
                  child: const Text("Detect in Image"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => StaticImage(),
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 20,),
          ButtonTheme(
            minWidth: MediaQuery.of(context).size.width * 0.20,
            child: ElevatedButton(
              child: const Text("Start Live Detection"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (context) => FlashModeProvider(),
                      builder: (context, child) => LiveFeed(
                        cameras!,
                        key: UniqueKey(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
