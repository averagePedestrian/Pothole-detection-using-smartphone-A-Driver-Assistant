import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../provider/flash_provider.dart';
import 'notification_permission_screen.dart';

class OverlayPermissionScreen extends StatefulWidget {
  const OverlayPermissionScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return OverlayPermissionScreenState();
  }
}

class OverlayPermissionScreenState extends State<OverlayPermissionScreen>
    with WidgetsBindingObserver {
  bool detectPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkPermission();
  }

  void checkPermission() async {
    final isOverlayPermissionGranted =
        await Permission.systemAlertWindow.status;
    print('Is Ignoring battery opimization: $isOverlayPermissionGranted');

    if (isOverlayPermissionGranted == PermissionStatus.granted) {
      context.read<FlashModeProvider>().setIsOverlayPermissionGranted(true);
    } else {
      context.read<FlashModeProvider>().setIsOverlayPermissionGranted(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        detectPermission &&
        (context.read<FlashModeProvider>().isOverlayPermissionGranted ==
            false)) {
      detectPermission = false;
      print('Detect permission $detectPermission');
      checkPermission();
    } else if (state == AppLifecycleState.paused &&
        context.read<FlashModeProvider>().isOverlayPermissionGranted == false) {
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

  Widget permissionHanlderWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Please Allow the app to draw system overlay. This is needed to automatically resume the app if it detects that the user is travelling on road',
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
                await Permission.systemAlertWindow.request();
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
  Widget build(BuildContext context) {
    return Container(
        child: context.watch<FlashModeProvider>().isOverlayPermissionGranted
            ? NotificationPermissionScreen()
            : permissionHanlderWidget());
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

