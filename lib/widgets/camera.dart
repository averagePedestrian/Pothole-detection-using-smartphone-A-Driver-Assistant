import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import '../provider/flash_provider.dart';

typedef void Callback(List<dynamic> list, int h, int w);

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  CameraController? controller;

  // The cameraFeed Class takes the cameras list and the setRecognitions function as argument
  CameraFeed(this.cameras, this.setRecognitions, this.controller,
  );

  @override
  _CameraFeedState createState() => new _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> with WidgetsBindingObserver {

  bool isDetecting = false;

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.controller!
        .setFlashMode(context.watch<FlashModeProvider>().flashMode);
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return Container();
    }

    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    Size mediaSize = MediaQuery.of(context).size;
    return SizedBox(
      width: mediaSize.width,
      height: mediaSize.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
            width: isPortrait
                ? widget.controller!.value.previewSize!.height
                : widget.controller!.value.previewSize!.width,
            height: isPortrait
                ? widget.controller!.value.previewSize!.width
                : widget.controller!.value.previewSize!.height,
            child: CameraPreview(widget.controller!)),
      ),
    );
  }
}
